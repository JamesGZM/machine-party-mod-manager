extends SceneTree

## Integration test for Core Heist + mpm-core + team-party:
## - Dynamic Hub v2 slot (>= 1000) & coexistence
## - Admission gating matrix (FFA, local couch, 1v1, 1v2, 2v2v2, 2v2v2v2, 1-team, >4 teams)
## - Team Party live HUD stats & score synchronization (no spurious +1 survival bonus)
## - Host -> Client snapshot round-trip

var _failed: bool = false
var _last_round_scores: Dictionary = {}


func _fail(msg: String) -> void:
	_failed = true
	push_error("CORE_HEIST_TEAM_TEST_FAIL: " + msg)
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


func preload_inline_lobby(h: Control) -> GDScript:
	var s := GDScript.new()
	s.source_code = "extends Node\nvar lobby_handler = null\nvar loading := false\nvar player_order_by_seat := {0: 1, 1: 2, 2: 3, 3: 4}\n"
	s.reload()
	return s


func _run() -> void:
	TranslationServer.set_locale("en")
	var loader := MockLoader.new()

	var core = loader.compile(loader.dir_of("mpm-core").path_join("main.gd")).new()
	var tp = loader.compile(loader.dir_of("team-party").path_join("main.gd")).new()
	var ch = loader.compile(loader.dir_of("core-heist").path_join("main.gd")).new()
	root.add_child(core)
	root.add_child(tp)
	root.add_child(ch)

	core._mod_init(loader)
	tp._mod_init(loader)
	ch._mod_init(loader)
	core._mod_ready(loader)
	tp._mod_ready(loader)
	ch._mod_ready(loader)

	# 1. Dynamic Hub v2 slot >= 1000
	var custom_map: Dictionary = loader.registry("custom_minigames")
	var ch_slot: int = -1
	var ch_spec: Dictionary = {}
	for k in custom_map.keys():
		var sp = custom_map[k]
		if sp is Dictionary and str((sp as Dictionary).get("mod_id", "")) == "core-heist":
			ch_slot = int(k)
			ch_spec = sp as Dictionary
			break
	if not _expect(ch_slot >= 1000, "core-heist must receive dynamic Hub v2 slot >= 1000, got %d" % ch_slot):
		return
	if not _expect(ch_spec.get("icon_texture", null) is Texture2D, "core-heist must register a non-null Texture2D icon_texture"):
		return

	# 2. Full admission gating matrix via mpm-core minigame_sdk
	var sdk = (Engine.get_meta(&"mpm_core") as Dictionary)["minigame_sdk"]
	var res_ffa: Dictionary = sdk.evaluate_minigame_eligibility(ch_spec, {"is_local": false, "team_enabled": false, "team_count": 2, "total_players": 4})
	if not _expect(not bool(res_ffa["eligible"]) and bool(res_ffa["hard_blocked"]) and str(res_ffa["reason_key"]) == "needs_team_mode", "FFA must hard-block core-heist"):
		return

	var res_local: Dictionary = sdk.evaluate_minigame_eligibility(ch_spec, {"is_local": true, "team_enabled": true, "team_count": 2, "total_players": 4})
	if not _expect(not bool(res_local["eligible"]) and bool(res_local["hard_blocked"]) and str(res_local["reason_key"]) == "local_unsupported", "local couch must hard-block core-heist"):
		return

	var res_5teams: Dictionary = sdk.evaluate_minigame_eligibility(ch_spec, {"is_local": false, "team_enabled": true, "team_count": 5, "total_players": 5})
	if not _expect(not bool(res_5teams["eligible"]) and bool(res_5teams["hard_blocked"]) and str(res_5teams["reason_key"]) == "team_count_out_of_range", "5 teams must hard-block core-heist"):
		return

	var res_1p: Dictionary = sdk.evaluate_minigame_eligibility(ch_spec, {"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 1, "teams": {1: 1}})
	if not _expect(not bool(res_1p["eligible"]) and bool(res_1p["soft_warning"]) and str(res_1p["reason_key"]) == "needs_more_players", "1 player must soft-warn needs_more_players"):
		return

	var res_1team: Dictionary = sdk.evaluate_minigame_eligibility(ch_spec, {"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 3, "teams": {1: 1, 2: 1, 3: 1}})
	if not _expect(not bool(res_1team["eligible"]) and bool(res_1team["soft_warning"]) and str(res_1team["reason_key"]) == "needs_more_teams", "all players on 1 team must soft-warn needs_more_teams"):
		return

	for ok_ctx in [
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 2, "teams": {1: 1, 2: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 3, "teams": {1: 1, 2: 2, 3: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 2, "total_players": 8, "teams": {1: 1, 2: 1, 3: 1, 4: 1, 5: 2, 6: 2, 7: 2, 8: 2}},
		{"is_local": false, "team_enabled": true, "team_count": 3, "total_players": 6, "teams": {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3}},
		{"is_local": false, "team_enabled": true, "team_count": 4, "total_players": 8, "teams": {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4, 8: 4}},
	]:
		var res_ok: Dictionary = sdk.evaluate_minigame_eligibility(ch_spec, ok_ctx)
		if not _expect(bool(res_ok["eligible"]), "valid team config must be eligible: " + str(ok_ctx)):
			return

	# 3. Team Party state + Core Heist Stage live HUD & score sync
	var lobby := Node.new()
	var handler := Control.new()
	handler.set_script(preload_inline_handler())
	lobby.add_child(handler)
	lobby.set_script(preload_inline_lobby(handler))
	lobby.set("lobby_handler", handler)
	root.add_child(lobby)
	if loader.scene_hooks.has("res://scenes/lobby/scripts/lobby_scene.gd"):
		(loader.scene_hooks["res://scenes/lobby/scripts/lobby_scene.gd"] as Callable).call(lobby)
	tp.set_team_mode(2)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 1)
	tp.assign_player_team(3, 2)
	tp.assign_player_team(4, 2)

	var packed: PackedScene = ch_spec["packed_scene"] as PackedScene
	var minigame_inst: Node = packed.instantiate()
	root.add_child(minigame_inst)
	var stage: Node3D = minigame_inst.get_node("Stage") as Node3D
	stage._is_self_test = true
	stage._standalone_mode = true
	stage._is_server_sim = true
	stage.round_finished.connect(Callable(self, "_on_round_finished"))

	var roster := [
		{"id": 0, "network_id": 1, "nickname": "A1", "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "A2", "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "B1", "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "B2", "is_ai": false, "customization": []},
	]
	stage._setup_match_local(0, 505, roster, false)
	stage._phase = stage.PH_LIVE

	if not _expect(bool(minigame_inst.get_meta(&"mpm_custom_team_game", false)), "mpm_custom_team_game meta must be set on parent"):
		return
	var hud_stats: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(int((hud_stats.get(1, {}) as Dictionary).get("alive", 0)) == 2 and int((hud_stats.get(2, {}) as Dictionary).get("alive", 0)) == 2, "team-party HUD must see 2 alive per team"):
		return

	# Deposit +5 Core for Team 1 and +1 Standard for Team 2
	var b_core: int = stage._spawn_battery(int(stage.C.CELL_CORE), Vector3.ZERO)
	var b_std: int = stage._spawn_battery(int(stage.C.CELL_STANDARD), Vector3.ZERO)
	stage._deposit_battery(b_core, 1)
	stage._deposit_battery(b_std, 2)
	stage._recompute_team_scores()

	# 4. Host -> Client snapshot round-trip (including core warning beacon & derived elapsed time)
	stage._core1_warn_timer = 1.5
	stage._time_remaining = 65.0
	stage._elapsed_time = 10.0
	var snap: Dictionary = stage._build_snapshot()
	var client_stage_script: GDScript = ResourceLoader.load("res://mods_core_heist/core_heist_game.gd") as GDScript
	var client_stage: Node3D = client_stage_script.new()
	client_stage._is_self_test = true
	client_stage._standalone_mode = true
	client_stage._is_server_sim = false
	root.add_child(client_stage)
	client_stage._setup_match_local(0, 505, roster, false)
	client_stage._apply_snapshot(snap)
	if not _expect(int(client_stage._team_scores.get(1, 0)) == 5 and int(client_stage._team_scores.get(2, 0)) == 1, "client snapshot must sync team scores (5 vs 1)"):
		return
	if not _expect(is_equal_approx(float(client_stage._elapsed_time), 10.0), "client snapshot must derive _elapsed_time (10.0) so YOU marker auto-hides"):
		return
	if not _expect(bool(client_stage._client_core_warn) and is_equal_approx(float(client_stage._client_core_warn_z), 3.0), "client snapshot must sync core warning beacon state"):
		return
	client_stage.queue_free()

	# 5. Finish match -> synchronized teammate scores (exact 5 and 1, no +1 bonus) & win counter
	stage._finish_match()
	if not _expect(int(_last_round_scores.get(1, -1)) == 5 and int(_last_round_scores.get(2, -1)) == 5, "Team 1 members must both get exact score 5"):
		return
	if not _expect(int(_last_round_scores.get(3, -1)) == 1 and int(_last_round_scores.get(4, -1)) == 1, "Team 2 members must both get exact score 1"):
		return
	if not _expect(int(tp._hud_wins.get(1, 0)) == 1, "team-party win counter must increment for Team 1"):
		return
	minigame_inst.queue_free()

	# 5b. 4v4 (2x4) and 2v2v2v2 (4x2) 8-player scaling + non-standalone results panel suppression
	tp.set_team_mode(2)
	for pid in range(1, 5):
		tp.assign_player_team(pid, 1)
	for pid in range(5, 9):
		tp.assign_player_team(pid, 2)
	var mg_4v4: Node = packed.instantiate()
	root.add_child(mg_4v4)
	var stage_4v4: Node3D = mg_4v4.get_node("Stage") as Node3D
	stage_4v4._is_self_test = true
	stage_4v4._standalone_mode = false
	stage_4v4._is_server_sim = true
	stage_4v4.round_finished.connect(Callable(self, "_on_round_finished"))
	var roster_4v4: Array = []
	for pid in range(1, 9):
		roster_4v4.append({"id": pid - 1, "network_id": pid, "nickname": "P%d" % pid, "is_ai": false, "customization": []})
	stage_4v4._setup_match_local(0, 606, roster_4v4, false)
	if not _expect(stage_4v4._batteries.size() == 32 and int(stage_4v4.C.max_loose_standard(2, 8)) == 14, "4v4 must use 32-battery pool and scaled loose cap (14)"):
		return
	var hud_4v4: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(int((hud_4v4.get(1, {}) as Dictionary).get("alive", 0)) == 4 and int((hud_4v4.get(2, {}) as Dictionary).get("alive", 0)) == 4, "4v4 team-party HUD must see 4 alive per team"):
		return
	# Build HUD in hosted (non-standalone) mode and verify results panel is suppressed on finish
	stage_4v4._hud.build_hud(stage_4v4, stage_4v4._team, false)
	stage_4v4._is_self_test = false
	var b_4v4_gold: int = stage_4v4._spawn_battery(int(stage_4v4.C.CELL_GOLD), Vector3.ZERO)
	stage_4v4._deposit_battery(b_4v4_gold, 2)
	stage_4v4._finish_match()
	var hosted_res_visible: bool = stage_4v4._hud._results_panel != null and is_instance_valid(stage_4v4._hud._results_panel) and bool(stage_4v4._hud._results_panel.visible)
	if not _expect(not hosted_res_visible, "non-standalone hosted match must suppress custom _results_panel"):
		return
	if not _expect(int(_last_round_scores.get(5, -1)) == 3 and int(_last_round_scores.get(8, -1)) == 3, "4v4 Team 2 all 4 members must sync exact score 3"):
		return
	if stage_4v4._hud._layer != null and is_instance_valid(stage_4v4._hud._layer):
		stage_4v4._hud._layer.queue_free()
	mg_4v4.queue_free()

	tp.set_team_mode(4)
	for pid in range(1, 9):
		tp.assign_player_team(pid, ((pid - 1) / 2) + 1)
	var mg_4x2: Node = packed.instantiate()
	root.add_child(mg_4x2)
	var stage_4x2: Node3D = mg_4x2.get_node("Stage") as Node3D
	stage_4x2._is_self_test = true
	stage_4x2._standalone_mode = false
	stage_4x2._is_server_sim = true
	stage_4x2.round_finished.connect(Callable(self, "_on_round_finished"))
	stage_4x2._setup_match_local(0, 707, roster_4v4, false)
	if not _expect(stage_4x2._active_team_ids == [1, 2, 3, 4] and int(stage_4x2.C.max_loose_standard(4, 8)) == 18 and int(stage_4x2.C.max_loose_gold(4, 8)) == 6, "2v2v2v2 must scale 4 teams with 18 std / 6 gold loose caps"):
		return
	var hud_4x2: Dictionary = tp._hud._gather_hud_teams()
	if not _expect(hud_4x2.size() == 4 and int((hud_4x2.get(4, {}) as Dictionary).get("alive", 0)) == 2, "2v2v2v2 team-party HUD must see 4 teams x 2 alive"):
		return
	var b_4x2_core: int = stage_4x2._spawn_battery(int(stage_4x2.C.CELL_CORE), Vector3.ZERO)
	stage_4x2._deposit_battery(b_4x2_core, 4)
	stage_4x2._finish_match()
	if not _expect(int(_last_round_scores.get(7, -1)) == 5 and int(_last_round_scores.get(8, -1)) == 5, "2v2v2v2 Team 4 members must sync exact score 5"):
		return
	mg_4x2.queue_free()

	# 6. Hub v2 end-to-end: override_playlist, override_game, and override_picker on dynamic slot >= 1000
	tp.set_team_mode(0) # FFA
	var game_script := ResourceLoader.load("res://scripts/scenes/game/game.gd") as GDScript
	var game_node = game_script.new()
	var mp := Node.new()
	game_node.minigame_parent = mp
	root.add_child(mp)
	root.add_child(game_node)
	game_node.generate_session_playlist()
	if not _expect(not game_node.session_minigame_list.has(ch_slot), "FFA playlist must exclude team_only core-heist"):
		return

	var pl_script := ResourceLoader.load("res://scenes/lobby/components/playlist_handler.gd") as GDScript
	var pl_node = pl_script.new()
	var item_ch := MinigameListItem.new()
	item_ch.minigame_identifier = ch_slot
	pl_node.all_minigames_list_items.append(item_ch)
	root.add_child(pl_node)
	if not _expect(bool(item_ch.get_meta(&"_mpm_hard_blocked", false)), "playlist item must be hard-blocked in FFA"):
		return

	# Enable Team Party -> playlist item unlocks & game.gd includes & loads dynamic slot
	tp.set_team_mode(2)
	tp.assign_player_team(1, 1)
	tp.assign_player_team(2, 2)
	if not _expect(not bool(item_ch.get_meta(&"_mpm_hard_blocked", false)), "playlist item must unlock live when Team Party enables"):
		return
	game_node.generate_session_playlist()
	if not _expect(game_node.session_minigame_list.has(ch_slot), "Team Party playlist must include core-heist"):
		return
	game_node.load_minigame(ch_slot, false, 1)
	if not _expect(game_node.minigame != null and game_node.minigame.has_node("Stage"), "override_game.load_minigame must instantiate dynamic core-heist slot with Stage"):
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
		if int(res.identifier) == ch_slot:
			found_icon_res = true
			break
	if not _expect(found_icon_res, "override_picker must register Intermission_IconResource for dynamic slot"):
		return

	print("CORE_HEIST_TEAM_INTEGRATION_PASSED slot=%d" % ch_slot)
	item_ch.name_label.free()
	item_ch.minigame_icon.free()
	item_ch.free()
	picker_node.free()
	im_mgr.free()
	pl_node.free()
	game_node.free()
	mp.free()
	lobby.free()
	ch.free()
	tp.free()
	core.free()
	for meta_key in ["_mpm_custom_minigames", "_mpm_custom_minigames_hub", "mpm_core", "mpm_team_party", "mpm_lobby_ui_coordinator_v2"]:
		if Engine.has_meta(meta_key):
			Engine.remove_meta(meta_key)
	loader._regs.clear()
	loader._kept.clear()
	quit(0)
