extends SceneTree

## Integration test for Bomb Cart + mpm-core + team-party:
## - Dynamic Hub v2 slot (>= 1000)
## - 2-4 team admission gating matrix (FFA, local couch, 5-team blocked, 1-player, 1-team, 2/3/4-team eligible)
## - Team Party live HUD stats & synchronized Squads score + win counter in 2-team & 4-team (2v2v2v2) modes
## - Door breach elimination live HUD update & Host -> Client multi-branch snapshot round-trip
## - Hub v2 playlist/game/picker gating in FFA, 2-team, 3-team, and 4-team modes

var _failed: bool = false
var _last_round_scores: Dictionary = {}


func _fail(msg: String) -> void:
	_failed = true
	push_error("BOMB_CART_TEAM_TEST_FAIL: " + msg)
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
	var bc = loader.compile(loader.dir_of("bomb-cart").path_join("main.gd")).new()
	root.add_child(core)
	root.add_child(tp)
	root.add_child(bc)

	core._mod_init(loader)
	tp._mod_init(loader)
	bc._mod_init(loader)
	core._mod_ready(loader)
	tp._mod_ready(loader)
	bc._mod_ready(loader)

	# 1. Dynamic Hub v2 slot >= 1000
	var custom_map: Dictionary = loader.registry("custom_minigames")
	var bc_slot: int = -1
	var bc_spec: Dictionary = {}
	for k in custom_map.keys():
		var sp = custom_map[k]
		if sp is Dictionary and str((sp as Dictionary).get("mod_id", "")) == "bomb-cart":
			bc_slot = int(k)
			bc_spec = sp as Dictionary
			break
	if not _expect(bc_slot >= 1000, "bomb-cart must receive dynamic Hub v2 slot >= 1000, got %d" % bc_slot):
		return
	if not _expect(bc_spec.get("icon_texture", null) is Texture2D, "bomb-cart must register a non-null Texture2D icon"):
		return

	# 1b. FX pool reset / replay safety (simulates [R]/[F2-F5] or multi-round rebuild)
	var fx_script: GDScript = ResourceLoader.load("res://mods_bomb_cart/fx_pool.gd") as GDScript
	var fx_pool = fx_script.new()
	var fx_parent1 := Node3D.new()
	root.add_child(fx_parent1)
	fx_pool.setup(fx_parent1)
	fx_pool.spawn_shove_burst(Vector3.ZERO, Color.WHITE)
	fx_pool.tick(0.05)
	fx_pool.clear()
	fx_parent1.free()
	var fx_parent2 := Node3D.new()
	root.add_child(fx_parent2)
	fx_pool.setup(fx_parent2)
	fx_pool.spawn_ram_sparks(Vector3.ZERO, Color.YELLOW)
	fx_pool.spawn_steam_surge(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), Color.RED)
	fx_pool.tick(0.05)
	if not _expect(fx_parent2.get_child_count() > 0, "fx_pool must cleanly rebuild nodes after clear() and setup()"):
		return
	fx_pool.clear()
	fx_parent2.free()

	# 2. 2-4 team admission gating matrix via mpm-core minigame_sdk
	var sdk = (Engine.get_meta(&"mpm_core") as Dictionary)["minigame_sdk"]
	var res_ffa: Dictionary = sdk.evaluate_minigame_eligibility(bc_spec, {"is_local": false, "team_enabled": false, "team_count": 2, "total_players": 4})
	if not _expect(not bool(res_ffa["eligible"]) and bool(res_ffa["hard_blocked"]) and str(res_ffa["reason_key"]) == "needs_team_mode", "FFA must hard-block bomb-cart"):
		return

	var res_local: Dictionary = sdk.evaluate_minigame_eligibility(bc_spec, {"is_local": true, "team_enabled": true, "team_count": 2, "total_players": 4})
	if not _expect(not bool(res_local["eligible"]) and bool(res_local["hard_blocked"]) and str(res_local["reason_key"]) == "local_unsupported", "local couch must hard-block bomb-cart"):
		return

	var res_5teams: Dictionary = sdk.evaluate_minigame_eligibility(bc_spec, {"is_local": false, "team_enabled": true, "team_count": 5, "total_players": 10})
	if not _expect(not bool(res_5teams["eligible"]) and bool(res_5teams["hard_blocked"]) and str(res_5teams["reason_key"]) == "team_count_out_of_range", "5 teams must hard-block bomb-cart"):
		return

	var res_1p: Dictionary = sdk.evaluate_minigame_eligibility(bc_spec, {"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 1, "teams": {1: 1}})
	if not _expect(not bool(res_1p["eligible"]) and bool(res_1p["soft_warning"]) and str(res_1p["reason_key"]) == "needs_more_players", "1 player must soft-warn needs_more_players"):
		return

	var res_1team: Dictionary = sdk.evaluate_minigame_eligibility(bc_spec, {"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 3, "teams": {1: 1, 2: 1, 3: 1}})
	if not _expect(not bool(res_1team["eligible"]) and bool(res_1team["soft_warning"]) and str(res_1team["reason_key"]) == "needs_more_teams", "all players on 1 team must soft-warn needs_more_teams"):
		return

	for ok_ctx in [
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 2, "teams": {1: 1, 2: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 3, "teams": {1: 1, 2: 2, 3: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 4, "teams": {1: 1, 2: 1, 3: 2, 4: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 8, "teams": {1: 1, 2: 1, 3: 1, 4: 1, 5: 2, 6: 2, 7: 2, 8: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 3, "total_players": 6, "teams": {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3}},
		{"is_local": false, "team_enabled": true, "team_count": 4, "total_players": 8, "teams": {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4, 8: 4}},
	]:
		var res_ok: Dictionary = sdk.evaluate_minigame_eligibility(bc_spec, ok_ctx)
		if not _expect(bool(res_ok["eligible"]), "valid 2-4 team config must be eligible: " + str(ok_ctx)):
			return

	# 3. Team Party state + Bomb Cart 2-team Stage live HUD & score sync
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

	var packed: PackedScene = bc_spec["packed_scene"] as PackedScene
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
	stage.setup_headless_match(roster2, false)
	stage._phase = stage.PH_LIVE

	if not _expect(bool(minigame_inst.get_meta(&"mpm_custom_team_game", false)), "mpm_custom_team_game meta must be set on parent"):
		return
	var hud_stats: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(int((hud_stats.get(1, {}) as Dictionary).get("alive", 0)) == 2 and int((hud_stats.get(2, {}) as Dictionary).get("alive", 0)) == 2, "team-party HUD must see 2 alive per team"):
		return

	stage._finish_match(1)
	var s1: int = int(_last_round_scores.get(1, -1))
	var s2: int = int(_last_round_scores.get(2, -1))
	var s3: int = int(_last_round_scores.get(3, -1))
	var s4: int = int(_last_round_scores.get(4, -1))
	if not _expect(s1 == 1 and s2 == 1 and s3 == 0 and s4 == 0, "2-team final scores must be exact: Team 1 == 1, Team 2 == 0 (got %s)" % str(_last_round_scores)):
		return
	if not _expect(int(tp._hud_wins.get(1, 0)) == 1, "team-party win counter must increment for Team 1"):
		return
	minigame_inst.queue_free()

	# 4. 4-team (2v2v2v2) Stage: breach elimination updates team-party HUD + multi-branch snapshot round-trip + score sync
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
	stage4.setup_headless_match(roster4, false)
	stage4._phase = stage4.PH_LIVE
	if not _expect((stage4._active_team_ids as Array) == [1, 2, 3, 4], "4-team stage must detect [1, 2, 3, 4]"):
		return

	# Breach Team 3 -> Team 3 alive becomes 0 in team-party HUD immediately
	stage4._cart_branch_team = 3
	stage4._cart_branch_dist = 10.5
	stage4._last_attacker_team = 2
	stage4.step_headless(1.0 / 60.0)
	var hud4: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(int((hud4.get(3, {}) as Dictionary).get("alive", -1)) == 0 and int((hud4.get(2, {}) as Dictionary).get("alive", 0)) == 2, "Breaching Team 3 must update team-party HUD alive=0 for Team 3"):
		return

	# Host -> Client multi-branch snapshot round-trip
	stage4._cart_reset_pause = 0.0
	stage4._cart_branch_team = 4
	stage4._cart_branch_dist = 4.2
	stage4._cart_pos = Vector2(0.0, 4.2)
	stage4._surge_team = 2
	stage4._surge_timer = 1.7
	var snap4: Dictionary = stage4.get_state_snapshot()
	var client_stage_script: GDScript = ResourceLoader.load("res://mods_bomb_cart/bomb_cart_game.gd") as GDScript
	var client_stage: Node3D = client_stage_script.new()
	client_stage._is_self_test = true
	client_stage._standalone_mode = true
	client_stage._is_server_sim = false
	root.add_child(client_stage)
	client_stage._setup_match_local(0, 20261123, roster4, false)
	client_stage._apply_snapshot(snap4)
	if not _expect(int(client_stage._cart_branch_team) == 4 and is_equal_approx(float(client_stage._cart_branch_dist), 4.2) and not bool((client_stage._door_alive as Dictionary)[3]) and not bool((client_stage._players[5] as Dictionary)["alive"]), "client snapshot must sync multi-branch cart, door_alive, and eliminated players"):
		return
	client_stage.queue_free()

	# Finish 4-team match -> Team 2 wins (3), intact non-winners Team 1 & Team 4 (2), breached Team 3 (0)
	stage4._finish_match(2)
	var f_t1_a: int = int(_last_round_scores.get(1, -1))
	var f_t1_b: int = int(_last_round_scores.get(2, -1))
	var f_t2_a: int = int(_last_round_scores.get(3, -1))
	var f_t2_b: int = int(_last_round_scores.get(4, -1))
	var f_t3_a: int = int(_last_round_scores.get(5, -1))
	var f_t3_b: int = int(_last_round_scores.get(6, -1))
	var f_t4_a: int = int(_last_round_scores.get(7, -1))
	var f_t4_b: int = int(_last_round_scores.get(8, -1))
	if not _expect(
		f_t2_a == 3 and f_t2_b == 3 and f_t1_a == 2 and f_t1_b == 2 and f_t4_a == 2 and f_t4_b == 2 and f_t3_a == 0 and f_t3_b == 0,
		"4-team final scores must be exact: winner Team 2 == 3, intact Teams 1&4 == 2, breached Team 3 == 0 (got %s)" % str(_last_round_scores)
	):
		return
	mg4.queue_free()

	# 5. Hub v2 end-to-end: FFA blocked, 2-team / 3-team / 4-team ALL unlocked & in playlist!
	tp.set_team_mode(0) # FFA
	var game_script := ResourceLoader.load("res://scripts/scenes/game/game.gd") as GDScript
	var game_node = game_script.new()
	var mp := Node.new()
	game_node.minigame_parent = mp
	root.add_child(mp)
	root.add_child(game_node)
	game_node.generate_session_playlist()
	if not _expect(not game_node.session_minigame_list.has(bc_slot), "FFA playlist must exclude team_only bomb-cart"):
		return

	var pl_script := ResourceLoader.load("res://scenes/lobby/components/playlist_handler.gd") as GDScript
	var pl_node = pl_script.new()
	var item_bc := MinigameListItem.new()
	item_bc.minigame_identifier = bc_slot
	pl_node.all_minigames_list_items.append(item_bc)
	root.add_child(pl_node)
	if not _expect(bool(item_bc.get_meta(&"_mpm_hard_blocked", false)), "playlist item must be hard-blocked in FFA"):
		return

	# Switch to 3-team mode -> MUST unlock and enter playlist!
	tp.set_team_mode(3)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 2)
	tp.assign_player_team(3, 3)
	if not _expect(not bool(item_bc.get_meta(&"_mpm_hard_blocked", false)), "playlist item must unlock in 3-team mode"):
		return
	game_node.generate_session_playlist()
	if not _expect(game_node.session_minigame_list.has(bc_slot), "3-team playlist must include bomb-cart"):
		return

	# Switch to 4-team mode -> MUST unlock and enter playlist!
	tp.set_team_mode(4)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 2)
	tp.assign_player_team(3, 3)
	tp.assign_player_team(4, 4)
	if not _expect(not bool(item_bc.get_meta(&"_mpm_hard_blocked", false)), "playlist item must unlock in 4-team mode"):
		return
	game_node.generate_session_playlist()
	if not _expect(game_node.session_minigame_list.has(bc_slot), "4-team playlist must include bomb-cart"):
		return

	# Switch to 2-team mode -> MUST unlock, enter playlist & load dynamic slot!
	tp.set_team_mode(2)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 2)
	if not _expect(not bool(item_bc.get_meta(&"_mpm_hard_blocked", false)), "playlist item must unlock live in 2-team mode"):
		return
	game_node.generate_session_playlist()
	if not _expect(game_node.session_minigame_list.has(bc_slot), "2-team playlist must include bomb-cart"):
		return
	game_node.load_minigame(bc_slot, false, 1)
	if not _expect(game_node.minigame != null and game_node.minigame.has_node("Stage"), "override_game.load_minigame must instantiate dynamic bomb-cart slot with Stage"):
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
		if int(res.identifier) == bc_slot:
			found_icon_res = true
			break
	if not _expect(found_icon_res, "override_picker must register Intermission_IconResource for dynamic slot"):
		return

	print("BOMB_CART_TEAM_INTEGRATION_PASSED slot=%d" % bc_slot)
	item_bc.name_label.free()
	item_bc.minigame_icon.free()
	item_bc.free()
	picker_node.free()
	im_mgr.free()
	pl_node.free()
	game_node.free()
	mp.free()
	lobby.free()
	bc.free()
	tp.free()
	core.free()
	for meta_key in ["_mpm_custom_minigames", "_mpm_custom_minigames_hub", "mpm_core", "mpm_team_party", "mpm_lobby_ui_coordinator_v2"]:
		if Engine.has_meta(meta_key):
			Engine.remove_meta(meta_key)
	loader._regs.clear()
	loader._kept.clear()
	quit(0)
