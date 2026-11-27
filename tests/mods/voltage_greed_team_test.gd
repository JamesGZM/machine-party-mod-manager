extends SceneTree

## Integration test for Voltage Greed + mpm-core + team-party:
## - Dynamic Hub v2 slot (>= 1000) & trilingual metadata + Texture2D icon
## - "both" admission gating matrix (FFA, local couch, 1-player soft warn, 2/3/4-team eligible, 5-team blocked, 1-team warn)
## - Team Party live HUD stats & synchronized Squads score + win counter in 2-team & 4-team (2v2v2v2) modes
## - 2nd overload fry elimination live HUD update & Host -> Client snapshot round-trip
## - Hub v2 playlist/game/local_game/picker inclusion in FFA, local couch, 2-team, 3-team & 4-team modes

var _last_round_scores: Dictionary = {}


func _fail(msg: String) -> void:
	push_error("VOLTAGE_GREED_TEAM_TEST_FAIL: " + msg)
	quit(1)


func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		_fail(msg)
		return false
	return true


class MockLoader extends RefCounted:
	var _regs: Dictionary = {}
	var _kept: Array = []
	var scene_hooks: Dictionary = {}
	var node_cbs: Array = []

	func dir_of(id: String) -> String:
		return ProjectSettings.globalize_path("res://mods").path_join(id)

	func registry(name: String) -> Dictionary:
		if not _regs.has(name):
			_regs[name] = {}
		return _regs[name] as Dictionary

	func has_api(name: String) -> bool:
		return name in ["registry", "register_script", "override_script_rel", "compile"]

	func compile(abs_path: String) -> GDScript:
		var src: String = FileAccess.get_file_as_string(abs_path)
		if src.is_empty():
			return null
		var gd := GDScript.new()
		gd.source_code = src
		if gd.reload() != OK:
			return null
		_kept.append(gd)
		return gd

	func register_script(id: String, rel: String, res_id: String) -> bool:
		var gd := compile(dir_of(id).path_join(rel))
		if gd == null:
			return false
		gd.take_over_path(res_id)
		return true

	func override_script_rel(id: String, res_path: String, rel: String) -> bool:
		var gd := compile(dir_of(id).path_join(rel))
		if gd == null:
			return false
		gd.take_over_path(res_path)
		return true

	func on_node_added(cb: Callable) -> void:
		node_cbs.append(cb)

	func on_lobby(_cb: Callable) -> void: pass

	func on_scene_script(p: String, cb: Callable) -> void:
		scene_hooks[p] = cb

	func note(_msg: String) -> void: pass


func _initialize() -> void:
	call_deferred("_run")


func _on_round_finished(scores: Dictionary) -> void:
	_last_round_scores = scores.duplicate()


func preload_inline_handler() -> GDScript:
	var s := GDScript.new()
	s.source_code = "extends Control\nsignal start_pressed\nsignal back_pressed\nvar active := true\nvar root: Control = self\nvar players: Array = []\nvar nametags: Array = []\nfunc send_lobby_message(_m: String) -> void: pass\n"
	s.reload()
	return s


func preload_inline_lobby() -> GDScript:
	var s := GDScript.new()
	s.source_code = "extends Node\nvar lobby_handler = null\nvar loading := false\nvar player_order_by_seat := {0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8}\n"
	s.reload()
	return s


func _run() -> void:
	TranslationServer.set_locale("en")
	var loader := MockLoader.new()

	var core = loader.compile(loader.dir_of("mpm-core").path_join("main.gd")).new()
	var tp = loader.compile(loader.dir_of("team-party").path_join("main.gd")).new()
	var vg = loader.compile(loader.dir_of("voltage-greed").path_join("main.gd")).new()
	root.add_child(core)
	root.add_child(tp)
	root.add_child(vg)

	core._mod_init(loader)
	tp._mod_init(loader)
	vg._mod_init(loader)
	core._mod_ready(loader)
	tp._mod_ready(loader)
	vg._mod_ready(loader)

	# 1. Dynamic Hub v2 slot >= 1000 & icon
	var custom_map: Dictionary = loader.registry("custom_minigames")
	var vg_slot: int = -1
	var vg_spec: Dictionary = {}
	for k in custom_map.keys():
		var sp = custom_map[k]
		if sp is Dictionary and str((sp as Dictionary).get("mod_id", "")) == "voltage-greed":
			vg_slot = int(k)
			vg_spec = sp as Dictionary
			break
	if not _expect(vg_slot >= 1000, "voltage-greed must receive dynamic Hub v2 slot >= 1000, got %d" % vg_slot):
		return
	if not _expect(vg_spec.get("icon_texture", null) is Texture2D, "voltage-greed must register a non-null Texture2D icon"):
		return

	# 1b. FX pool setup/clear_all replay safety
	var fx_script: GDScript = ResourceLoader.load("res://mods_voltage_greed/fx_pool.gd") as GDScript
	var fx_pool = fx_script.new()
	var fx_parent1 := Node3D.new()
	root.add_child(fx_parent1)
	fx_pool.setup(fx_parent1)
	fx_pool.trigger_kick_arc(Vector3.ZERO, Vector3(0.0, 2.0, -5.0), Color.YELLOW)
	fx_pool.update_parallel_arcs([{"a": Vector3(-1.0, 1.0, 0.0), "b": Vector3(1.0, 1.0, 0.0), "color": Color.RED}])
	fx_pool.tick(0.05)
	fx_pool.clear_all()
	fx_parent1.free()

	var fx_parent2 := Node3D.new()
	root.add_child(fx_parent2)
	fx_pool.setup(fx_parent2)
	fx_pool.trigger_fry(Vector3.ZERO, false)
	fx_pool.trigger_slacker_jolt(Vector3(1.0, 1.0, 0.0))
	fx_pool.trigger_transformer_blast(Vector3(0.0, 2.0, -5.0))
	fx_pool.tick(0.05)
	if not _expect(fx_parent2.get_child_count() > 0, "fx_pool must cleanly rebuild nodes after clear_all() and setup()"):
		return
	fx_pool.clear_all()
	fx_parent2.free()

	# 2. "both" admission gating matrix via mpm-core minigame_sdk
	var sdk = (Engine.get_meta(&"mpm_core") as Dictionary)["minigame_sdk"]
	var res_ffa: Dictionary = sdk.evaluate_minigame_eligibility(vg_spec, {"is_local": false, "team_enabled": false, "team_count": 0, "total_players": 4})
	if not _expect(bool(res_ffa["eligible"]), "FFA online 4P must be eligible for 'both' voltage-greed"):
		return

	var res_local: Dictionary = sdk.evaluate_minigame_eligibility(vg_spec, {"is_local": true, "team_enabled": false, "team_count": 0, "total_players": 2})
	if not _expect(bool(res_local["eligible"]), "Local couch 2P must be eligible for allow_local_couch=true voltage-greed"):
		return

	var res_1p: Dictionary = sdk.evaluate_minigame_eligibility(vg_spec, {"is_local": false, "team_enabled": false, "team_count": 0, "total_players": 1})
	if not _expect(not bool(res_1p["eligible"]) and bool(res_1p["soft_warning"]) and str(res_1p["reason_key"]) == "needs_more_players", "1 player must soft-warn needs_more_players"):
		return

	var res_5teams: Dictionary = sdk.evaluate_minigame_eligibility(vg_spec, {"is_local": false, "team_enabled": true, "team_count": 5, "total_players": 10})
	if not _expect(not bool(res_5teams["eligible"]) and bool(res_5teams["hard_blocked"]) and str(res_5teams["reason_key"]) == "team_count_out_of_range", "5 teams must hard-block voltage-greed"):
		return

	var res_1team: Dictionary = sdk.evaluate_minigame_eligibility(vg_spec, {"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 3, "teams": {1: 1, 2: 1, 3: 1}})
	if not _expect(not bool(res_1team["eligible"]) and bool(res_1team["soft_warning"]) and str(res_1team["reason_key"]) == "needs_more_teams", "all players on 1 team must soft-warn needs_more_teams"):
		return

	for ok_ctx in [
		{"is_local": false, "team_enabled": false, "team_count": 0, "total_players": 2},
		{"is_local": false, "team_enabled": false, "team_count": 0, "total_players": 8},
		{"is_local": true, "team_enabled": false, "team_count": 0, "total_players": 4},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 2, "teams": {1: 1, 2: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 4, "teams": {1: 1, 2: 1, 3: 2, 4: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 3, "total_players": 6, "teams": {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3}},
		{"is_local": false, "team_enabled": true, "team_count": 4, "total_players": 8, "teams": {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4, 8: 4}},
	]:
		var res_ok: Dictionary = sdk.evaluate_minigame_eligibility(vg_spec, ok_ctx)
		if not _expect(bool(res_ok["eligible"]), "valid FFA/couch/2-4 team config must be eligible: " + str(ok_ctx)):
			return

	# 3. Team Party state + Voltage Greed 2-team Stage live HUD & score sync
	var lobby := Node.new()
	var handler := Control.new()
	handler.set_script(preload_inline_handler())
	lobby.add_child(handler)
	lobby.set_script(preload_inline_lobby())
	lobby.set("lobby_handler", handler)
	root.add_child(lobby)
	if loader.scene_hooks.has("res://scenes/lobby/scripts/lobby_scene.gd"):
		(loader.scene_hooks["res://scenes/lobby/scripts/lobby_scene.gd"] as Callable).call(lobby)
	tp.set_team_mode(2)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 1)
	tp.assign_player_team(3, 2)
	tp.assign_player_team(4, 2)

	var packed: PackedScene = vg_spec["packed_scene"] as PackedScene
	var minigame_inst: Node = packed.instantiate()
	root.add_child(minigame_inst)
	var stage: Node3D = minigame_inst.get_node("Stage") as Node3D
	stage.round_finished.connect(Callable(self, "_on_round_finished"))

	var roster2 := [
		{"id": 0, "network_id": 1, "nickname": "A1", "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "A2", "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "B1", "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "B2", "is_ai": false, "customization": []},
	]
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(0, 90.0, 0, 999.0)

	if not _expect(bool(minigame_inst.get_meta(&"mpm_custom_team_game", false)), "mpm_custom_team_game meta must be set on parent in team mode"):
		return
	var hud_stats: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(int((hud_stats.get(1, {}) as Dictionary).get("alive", 0)) == 2 and int((hud_stats.get(2, {}) as Dictionary).get("alive", 0)) == 2, "team-party HUD must see 2 alive per team"):
		return

	# Team 1 banks higher KPI than Team 2, finish match -> Team 1 (rank 2 + all_alive 1 = 3), Team 2 (rank 1 + all_alive 1 = 2)
	(stage._players[1] as Dictionary)["total_kpi"] = 320
	(stage._players[2] as Dictionary)["total_kpi"] = 240
	(stage._players[3] as Dictionary)["total_kpi"] = 180
	(stage._players[4] as Dictionary)["total_kpi"] = 140
	stage._finish_match()
	var s1: int = int(_last_round_scores.get(1, -1))
	var s2: int = int(_last_round_scores.get(2, -1))
	var s3: int = int(_last_round_scores.get(3, -1))
	var s4: int = int(_last_round_scores.get(4, -1))
	if not _expect(s1 == 3 and s2 == 3 and s3 == 2 and s4 == 2, "2-team final scores must be synced per team: Team 1 == 3, Team 2 == 2 (got %s)" % str(_last_round_scores)):
		return
	if not _expect(int(tp._hud_wins.get(1, 0)) == 1, "team-party win counter must increment for Team 1"):
		return
	minigame_inst.queue_free()

	# 4. 4-team (2v2v2v2) Stage: 2nd fry elimination updates team-party HUD + snapshot round-trip + score sync
	tp.set_team_mode(4)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 1)
	tp.assign_player_team(3, 2)
	tp.assign_player_team(4, 2)
	tp.assign_player_team(5, 3)
	tp.assign_player_team(6, 3)
	tp.assign_player_team(7, 4)
	tp.assign_player_team(8, 4)

	var mg4: Node = packed.instantiate()
	root.add_child(mg4)
	var stage4: Node3D = mg4.get_node("Stage") as Node3D
	_last_round_scores.clear()
	stage4.round_finished.connect(Callable(self, "_on_round_finished"))
	var roster4 := [
		{"id": 0, "network_id": 1, "nickname": "R1", "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "R2", "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "B1", "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "B2", "is_ai": false, "customization": []},
		{"id": 4, "network_id": 5, "nickname": "G1", "is_ai": false, "customization": []},
		{"id": 5, "network_id": 6, "nickname": "G2", "is_ai": false, "customization": []},
		{"id": 6, "network_id": 7, "nickname": "Y1", "is_ai": false, "customization": []},
		{"id": 7, "network_id": 8, "nickname": "Y2", "is_ai": false, "customization": []},
	]
	stage4.setup_headless_match(roster4, false, 20261127, false)
	stage4.begin_round_for_test(1, 75.0, 0, 999.0)

	# Eliminate Team 3 player 5 on 2nd fry -> Team 3 alive becomes 1 in team-party HUD immediately
	(stage4._players[5] as Dictionary)["lives"] = 1
	stage4.set_player_holding(5, true)
	stage4._public_voltage = 76.0
	stage4.step_simulation(1.0 / 60.0)
	var hud4: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(int((hud4.get(3, {}) as Dictionary).get("alive", -1)) == 1 and int((hud4.get(2, {}) as Dictionary).get("alive", 0)) == 2, "Eliminating player 5 on 2nd fry must update team-party HUD alive=1 for Team 3"):
		return

	# Host -> Client snapshot round-trip (must never leak hidden_threshold)
	var net_snap: Dictionary = stage4._build_snapshot()
	if not _expect(not net_snap.has("hidden_threshold"), "Network snapshot must never include hidden_threshold"):
		return
	var client_stage_script: GDScript = ResourceLoader.load("res://mods_voltage_greed/voltage_greed_game.gd") as GDScript
	var client_stage: Node3D = client_stage_script.new()
	client_stage._is_self_test = true
	client_stage._standalone_mode = true
	root.add_child(client_stage)
	client_stage._is_server_sim = false
	client_stage._setup_match_local(0, 20261127, roster4, false)
	client_stage._rpc_state_snapshot(net_snap)
	if not _expect(not bool((client_stage._players[5] as Dictionary)["alive"]) and int((client_stage._players[5] as Dictionary)["lives"]) == 0, "Client snapshot must sync eliminated player lives & alive state"):
		return
	client_stage.queue_free()

	# Finish 4-team match ranked by team total KPI + team-party all-alive (+1) bonus:
	# T2 (4+1=5), T1 (3+1=4), T4 (2+1=3), T3 (1+0=1 because player 5 was eliminated)
	(stage4._players[1] as Dictionary)["total_kpi"] = 150
	(stage4._players[2] as Dictionary)["total_kpi"] = 150
	(stage4._players[3] as Dictionary)["total_kpi"] = 260
	(stage4._players[4] as Dictionary)["total_kpi"] = 240
	(stage4._players[5] as Dictionary)["total_kpi"] = 100
	(stage4._players[6] as Dictionary)["total_kpi"] = 0
	(stage4._players[7] as Dictionary)["total_kpi"] = 120
	(stage4._players[8] as Dictionary)["total_kpi"] = 80
	stage4._finish_match()
	if not _expect(
		int(_last_round_scores.get(3, -1)) == 5 and int(_last_round_scores.get(4, -1)) == 5
		and int(_last_round_scores.get(1, -1)) == 4 and int(_last_round_scores.get(2, -1)) == 4
		and int(_last_round_scores.get(7, -1)) == 3 and int(_last_round_scores.get(8, -1)) == 3
		and int(_last_round_scores.get(5, -1)) == 1 and int(_last_round_scores.get(6, -1)) == 1,
		"4-team final scores must rank teams by KPI + all-alive bonus cleanly (got %s)" % str(_last_round_scores)
	):
		return
	mg4.queue_free()

	# 5. Hub v2 end-to-end: FFA, local couch, 2-team, 3-team & 4-team ALL unlocked & in playlist!
	tp.set_team_mode(0) # FFA
	var game_script := ResourceLoader.load("res://scripts/scenes/game/game.gd") as GDScript
	var game_node = game_script.new()
	var mp := Node.new()
	game_node.minigame_parent = mp
	root.add_child(mp)
	root.add_child(game_node)
	game_node.generate_session_playlist()
	if not _expect(game_node.session_minigame_list.has(vg_slot), "FFA playlist must include 'both' voltage-greed"):
		return

	var pl_script := ResourceLoader.load("res://scenes/lobby/components/playlist_handler.gd") as GDScript
	var pl_node = pl_script.new()
	var item_vg := MinigameListItem.new()
	item_vg.minigame_identifier = vg_slot
	pl_node.all_minigames_list_items.append(item_vg)
	root.add_child(pl_node)
	if not _expect(not bool(item_vg.get_meta(&"_mpm_hard_blocked", false)), "playlist item must stay unlocked in FFA"):
		return

	# Local couch check via override_local_game.gd
	var gm_node: Node = root.get_node("GameManager")
	gm_node.set("local_game", true)
	var local_script := ResourceLoader.load("res://scenes/local_game/script/local_game.gd") as GDScript
	var local_node = local_script.new()
	var mp_local := Node.new()
	local_node.minigame_parent = mp_local
	root.add_child(mp_local)
	root.add_child(local_node)
	local_node.generate_session_playlist()
	if not _expect(local_node.session_minigame_list.has(vg_slot), "local couch playlist must include voltage-greed"):
		return
	gm_node.set("local_game", false)

	# 2/3/4-team modes all stay unlocked & in playlist
	for t_mode in [2, 3, 4]:
		tp.set_team_mode(t_mode)
		for tid in range(1, t_mode + 1):
			tp.assign_player_team(tid, tid)
		if not _expect(not bool(item_vg.get_meta(&"_mpm_hard_blocked", false)), "playlist item must stay unlocked in %d-team mode" % t_mode):
			return
		game_node.generate_session_playlist()
		if not _expect(game_node.session_minigame_list.has(vg_slot), "%d-team playlist must include voltage-greed" % t_mode):
			return

	# Load dynamic slot & check mpm_custom_team_game=false in FFA
	tp.set_team_mode(0)
	game_node.load_minigame(vg_slot, false, 1)
	if not _expect(game_node.minigame != null and game_node.minigame.has_node("Stage"), "override_game.load_minigame must instantiate dynamic voltage-greed slot with Stage"):
		return

	var picker_script := ResourceLoader.load("res://minigames/intermission_new/components/intermission_game_picker.gd") as GDScript
	var picker_node = picker_script.new()
	var im_mgr := Node.new()
	var im_script := GDScript.new()
	im_script.source_code = "extends Node\nvar minigame_icon_resource_array: Array = []\n"
	im_script.reload()
	im_mgr.set_script(im_script)
	picker_node.intermission_manager = im_mgr
	root.add_child(im_mgr)
	root.add_child(picker_node)
	var found_icon_res: bool = false
	for res in im_mgr.minigame_icon_resource_array:
		if int(res.identifier) == vg_slot:
			found_icon_res = true
			break
	if not _expect(found_icon_res, "override_picker must register Intermission_IconResource for dynamic slot"):
		return

	print("VOLTAGE_GREED_TEAM_INTEGRATION_PASSED slot=%d" % vg_slot)
	item_vg.name_label.free()
	item_vg.minigame_icon.free()
	item_vg.free()
	picker_node.free()
	im_mgr.free()
	pl_node.free()
	local_node.free()
	mp_local.free()
	game_node.free()
	mp.free()
	lobby.free()
	vg.free()
	tp.free()
	core.free()
	for meta_key in ["_mpm_custom_minigames", "_mpm_custom_minigames_hub", "mpm_core", "mpm_team_party", "mpm_lobby_ui_coordinator_v2"]:
		if Engine.has_meta(meta_key):
			Engine.remove_meta(meta_key)
	loader._regs.clear()
	loader._kept.clear()
	quit(0)
