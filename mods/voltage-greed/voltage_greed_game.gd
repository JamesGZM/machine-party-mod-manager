extends Node3D

## ============================================================================
## Voltage Greed / 電刑貪婪 — Host-Authoritative 3-Round High-Voltage Stage
## ============================================================================

signal round_finished(scores: Dictionary)

const CONFIG_RES := "res://mods_voltage_greed/config.gd"
const MESHES_RES := "res://mods_voltage_greed/arena_meshes.gd"
const TEAM_RES := "res://mods_voltage_greed/team_support.gd"
const FX_POOL_RES := "res://mods_voltage_greed/fx_pool.gd"
const HUD_RES := "res://mods_voltage_greed/hud_ui.gd"
const AI_RES := "res://mods_voltage_greed/ai_controller.gd"
const SELF_TEST_RES := "res://mods_voltage_greed/self_test.gd"

const PH_PREP := 0
const PH_LIVE := 1
const PH_INTER_ROUND := 2
const PH_ENDED := 3

var C = null
var M = null
var _team = null
var _fx_pool = null
var _hud = null
var _ai_ctrl = null
var _self_test_runner = null

var _standalone_mode: bool = false
var _is_self_test: bool = false
var _screenshot_path: String = ""
var _cli_players: int = 4
var _cli_teams: int = 2
var _cli_per_team: int = 2
var _cli_use_teams: bool = false
var _is_server_sim: bool = true
var _local_net_id: int = 1
var _pck_mounted: bool = false

var _phase: int = PH_PREP
var _round_idx: int = 0
var _srv_time: float = 0.0
var _prep_remaining: float = 0.0
var _round_elapsed: float = 0.0
var _round_remaining: float = 16.0
var _inter_round_timer: float = 0.0
var _last_countdown_sec: int = 4
var _you_marker_timer: float = 0.0
var _map_seed: int = 20261127
var _sync_accum: float = 0.0
var _fx_warmed_up: bool = false
var _rng := RandomNumberGenerator.new()

var _public_voltage: float = 0.0
var _display_voltage: float = 0.0
var _hidden_threshold: float = 85.0
var _forced_threshold: float = -1.0
var _detonated: bool = false
var _slacker_nid: int = 0
var _early_victory: bool = false

var _event_id: int = 0
var _event_timer: float = 0.0
var _event_triggered_this_round: bool = false
var _scheduled_event_id: int = 0
var _scheduled_event_time: float = 5.5
var _last_round_event_id: int = 0
var _forced_event_id: int = -1
var _forced_event_time: float = -1.0
var _banner_timer: float = 0.0
var _banner_text: String = ""
var _banner_color: Color = Color.WHITE

var _players: Dictionary = {}
var _player_order: Array = []
var _seat_layout: Array = []
var _chair_rigs: Dictionary = {}
var _final_scores: Dictionary = {}
var _summary_rows: Array = []
var _parallel_arc_pairs: Array = []

var _arena_root: Node3D = null
var _fx_root: Node3D = null
var _chairs_root: Node3D = null
var _shader_layer: CanvasLayer = null
var _camera: Camera3D = null
var _cam_base_pos: Vector3 = Vector3.ZERO
var _cam_look_at: Vector3 = Vector3.ZERO
var _cam_shake: float = 0.0

var _stage_handles: Dictionary = {}
var _needle_pivot: Node3D = null
var _gauge_glow_mat: StandardMaterial3D = null
var _beacon_light: OmniLight3D = null
var _beacon_mat: StandardMaterial3D = null
var _crt_label: Label3D = null
var _crt_sub_label: Label3D = null
var _transformer_top: Vector3 = Vector3(0.0, 4.35, -3.35)
var _penalty_emitter_pos: Vector3 = Vector3(3.35, 3.25, -3.65)
var _penalty_flash_timer: float = 0.0
var _fluorescent_mats: Array = []

var _prev_hold_input: bool = false
var _prev_kick_input: bool = false
var _sfx_buzz: AudioStreamPlayer = null
var _sfx_ding: AudioStreamPlayer = null
var _sfx_warn: AudioStreamPlayer = null
var _sfx_blast: AudioStreamPlayer = null


static func _pick_loc(en: String, cn: String, tw: String) -> String:
	var low: String = TranslationServer.get_locale().to_lower()
	if low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo"):
		return tw
	if low.begins_with("zh") or low == "zhs":
		return cn
	return en


func _load_script_res(reg_path: String, local_file: String):
	if ResourceLoader.exists(reg_path):
		var res = ResourceLoader.load(reg_path)
		if res != null:
			return res
	var fallback_path: String = "res://" + local_file
	if ResourceLoader.exists(fallback_path):
		return ResourceLoader.load(fallback_path)
	return null


func _load_helpers() -> void:
	if C != null:
		return
	C = _load_script_res(CONFIG_RES, "config.gd")
	M = _load_script_res(MESHES_RES, "arena_meshes.gd")
	var t_cls = _load_script_res(TEAM_RES, "team_support.gd")
	if t_cls != null:
		_team = t_cls.new()
	var fx_cls = _load_script_res(FX_POOL_RES, "fx_pool.gd")
	if fx_cls != null:
		_fx_pool = fx_cls.new()
	var hud_cls = _load_script_res(HUD_RES, "hud_ui.gd")
	if hud_cls != null:
		_hud = hud_cls.new()
	var ai_cls = _load_script_res(AI_RES, "ai_controller.gd")
	if ai_cls != null:
		_ai_ctrl = ai_cls.new()


func _ready() -> void:
	_load_helpers()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var smoke_test: bool = false
	for arg in args:
		if arg == "--self-test":
			_is_self_test = true
			var st_cls = _load_script_res(SELF_TEST_RES, "self_test.gd")
			if st_cls != null:
				_self_test_runner = st_cls.new()
				_self_test_runner.run_self_tests(self)
			return
		elif arg == "--smoke-test":
			smoke_test = true
		elif arg.begins_with("--screenshot="):
			_screenshot_path = arg.substr("--screenshot=".length())
		elif arg.begins_with("--capture-screenshot="):
			_screenshot_path = arg.substr("--capture-screenshot=".length())
		elif arg.begins_with("--players="):
			_cli_players = clampi(int(arg.substr("--players=".length())), 2, 12)
			_cli_use_teams = false
		elif arg.begins_with("--teams="):
			_cli_teams = clampi(int(arg.substr("--teams=".length())), 2, 4)
			_cli_use_teams = true
		elif arg.begins_with("--per-team="):
			_cli_per_team = clampi(int(arg.substr("--per-team=".length())), 1, 4)
			_cli_use_teams = true

	if smoke_test:
		_is_self_test = true
		_standalone_mode = true
		_is_server_sim = true
		var smoke_roster: Array = _build_standalone_roster(true)
		_setup_match_local(0, _map_seed, smoke_roster, true)
		for _i in range(180):
			step_simulation(1.0 / 60.0)
		print("SMOKE_TEST_PASSED players=%d teams=%s" % [smoke_roster.size(), str(_cli_use_teams)])
		get_tree().quit(0)
		return

	if not _screenshot_path.is_empty():
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var demo_roster: Array = _build_screenshot_roster()
		_setup_match_local(0, _map_seed, demo_roster, true)
		var st_cls2 = _load_script_res(SELF_TEST_RES, "self_test.gd")
		if st_cls2 != null:
			_self_test_runner = st_cls2.new()
			if _self_test_runner.has_method("stage_screenshot_action"):
				_self_test_runner.stage_screenshot_action(self)
			else:
				stage_screenshot_scene(_cli_use_teams)
		else:
			stage_screenshot_scene(_cli_use_teams)
		call_deferred("_capture_and_quit")
		return

	if get_parent() == get_tree().root:
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var roster: Array = _build_standalone_roster(false)
		_setup_match_local(0, _map_seed, roster, false)


func _mount_preview_pck() -> void:
	if _pck_mounted or _is_self_test:
		return
	_pck_mounted = true
	if ResourceLoader.exists("res://shaders/vignette.gdshader"):
		return
	var pck_path: String = OS.get_environment("MP_PCK_PATH")
	if not pck_path.is_empty() and FileAccess.file_exists(pck_path):
		ProjectSettings.load_resource_pack(pck_path, false)


func _unhandled_input(event: InputEvent) -> void:
	if not _standalone_mode or _is_self_test or not _screenshot_path.is_empty():
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var kc: Key = (event as InputEventKey).keycode
		if kc == KEY_R:
			_map_seed += 1
			_setup_match_local(0, _map_seed, _build_standalone_roster(false), false)
		elif kc == KEY_F2:
			_cli_use_teams = false
			_cli_players = 4
			_map_seed += 1
			_setup_match_local(0, _map_seed, _build_standalone_roster(false), false)
		elif kc == KEY_F3:
			_cli_use_teams = true
			_cli_teams = 2
			_cli_per_team = 2
			_map_seed += 1
			_setup_match_local(0, _map_seed, _build_standalone_roster(false), false)
		elif kc == KEY_F4:
			_cli_use_teams = true
			_cli_teams = 4
			_cli_per_team = 2
			_map_seed += 1
			_setup_match_local(0, _map_seed, _build_standalone_roster(false), false)
		elif kc == KEY_F5:
			_cli_use_teams = false
			_cli_players = 8
			_map_seed += 1
			_setup_match_local(0, _map_seed, _build_standalone_roster(false), false)


func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var dir_path: String = _screenshot_path.get_base_dir()
		if not dir_path.is_empty():
			DirAccess.make_dir_recursive_absolute(dir_path)
		img.save_png(_screenshot_path)
		print("SCREENSHOT_SAVED:" + _screenshot_path)
	get_tree().quit(0)


func _build_standalone_roster(all_ai: bool) -> Array:
	var roster: Array = []
	if not _cli_use_teams:
		var n: int = clampi(_cli_players, 2, 12)
		for i in range(n):
			var nid: int = i + 1
			roster.append({
				"id": i,
				"network_id": nid,
				"nickname": "Player1" if (i == 0 and not all_ai) else ("Bot%d" % nid),
				"team_id": 0,
				"is_ai": all_ai or i > 0,
				"customization": [],
			})
		return roster

	var idx: int = 0
	var t_count: int = clampi(_cli_teams, 2, 4)
	for t in range(1, t_count + 1):
		for _m in range(_cli_per_team):
			var nid: int = idx + 1
			roster.append({
				"id": idx,
				"network_id": nid,
				"nickname": "Player1" if (idx == 0 and not all_ai) else ("Bot%d" % nid),
				"team_id": t,
				"is_ai": all_ai or idx > 0,
				"customization": [],
			})
			idx += 1
	return roster


func _build_screenshot_roster() -> Array:
	var ffa_names: Array = [
		_pick_loc("VoltVex", "高压老六", "高壓老六"),
		_pick_loc("AmpAnnie", "电弧安妮", "電弧安妮"),
		_pick_loc("SparkSam", "火花山姆", "火花山姆"),
		_pick_loc("FuseFred", "保险丝哥", "保險絲哥"),
		_pick_loc("OhmOllie", "欧姆奥利", "歐姆奧利"),
		_pick_loc("WattWill", "瓦特威尔", "瓦特威爾"),
		_pick_loc("CoilCarl", "线圈卡尔", "線圈卡爾"),
		_pick_loc("SurgeSue", "浪涌苏珊", "浪湧蘇珊"),
	]
	var names_by_team: Dictionary = {
		1: [_pick_loc("RedVolt", "红电一号", "紅電一號"), _pick_loc("RedFuse", "红丝二号", "紅絲二號"), _pick_loc("RedAmp", "红流三号", "紅流三號"), _pick_loc("RedArc", "红弧四号", "紅弧四號")],
		2: [_pick_loc("BluCoil", "蓝圈一号", "藍圈一號"), _pick_loc("BluWatt", "蓝瓦二号", "藍瓦二號"), _pick_loc("BluGrid", "蓝网三号", "藍網三號"), _pick_loc("BluZap", "蓝击四号", "藍擊四號")],
		3: [_pick_loc("GrnOhm", "绿欧一号", "綠歐一號"), _pick_loc("GrnCell", "绿芯二号", "綠芯二號"), _pick_loc("GrnLoad", "绿载三号", "綠載三號"), _pick_loc("GrnSpk", "绿花四号", "綠花四號")],
		4: [_pick_loc("YelJolt", "黄震一号", "黃震一號"), _pick_loc("YelCore", "黄核二号", "黃核二號"), _pick_loc("YelWire", "黄线三号", "黃線三號"), _pick_loc("YelBuzz", "黄蜂四号", "黃蜂四號")],
	}
	var cosmetics_pool: Array = [
		["hard_hat", "sunglasses"],
		["tophat", ""],
		["traffic_cone", "reading_glasses"],
		["drill_sgt_hat", "sunglasses"],
		["maska_helmet", ""],
		["beer_hat", "sunglasses"],
		["cap_blade", "reading_glasses"],
		["rubiks_cube", ""],
	]
	var roster: Array = []
	if not _cli_use_teams:
		var n: int = clampi(_cli_players, 2, 12)
		for i in range(n):
			roster.append({
				"id": i,
				"network_id": i + 1,
				"nickname": str(ffa_names[i % ffa_names.size()]),
				"team_id": 0,
				"is_ai": true,
				"customization": (cosmetics_pool[i % cosmetics_pool.size()] as Array).duplicate(),
			})
		return roster

	var idx: int = 0
	var t_count: int = clampi(_cli_teams, 2, 4)
	for t in range(1, t_count + 1):
		var t_names: Array = names_by_team.get(t, ["P1", "P2"]) as Array
		for m in range(_cli_per_team):
			roster.append({
				"id": idx,
				"network_id": idx + 1,
				"nickname": str(t_names[m % t_names.size()]),
				"team_id": t,
				"is_ai": true,
				"customization": (cosmetics_pool[idx % cosmetics_pool.size()] as Array).duplicate(),
			})
			idx += 1
	return roster


## ============================================================================
## Public / Headless Test Hooks (for self_test.gd & integration-qa)
## ============================================================================

func setup_headless_match(roster: Array, all_ai: bool = false, seed_val: int = 20261127, start_immediately: bool = false) -> void:
	_is_self_test = true
	_standalone_mode = true
	_is_server_sim = true
	_setup_match_local(0, seed_val, roster, all_ai)
	if start_immediately:
		begin_round_for_test(0)


func begin_round_for_test(round_idx: int = 0, hidden_threshold: float = -1.0, forced_event: int = -1, event_trigger_time: float = -1.0) -> void:
	_forced_threshold = hidden_threshold
	_forced_event_id = forced_event
	_forced_event_time = event_trigger_time
	_begin_round(clampi(round_idx, 0, int(C.TOTAL_ROUNDS) - 1))


func set_hidden_threshold(threshold: float) -> void:
	_forced_threshold = threshold
	_hidden_threshold = threshold


func set_forced_event(event_id: int, trigger_time: float = 0.5) -> void:
	_forced_event_id = event_id
	_forced_event_time = trigger_time
	_scheduled_event_id = event_id
	_scheduled_event_time = trigger_time
	_event_triggered_this_round = false


func set_player_holding(network_id: int, holding: bool) -> bool:
	if not _is_server_sim or _phase != PH_LIVE:
		return false
	if not _players.has(network_id):
		return false
	var p: Dictionary = _players[network_id] as Dictionary
	if not bool(p["alive"]) or not bool(p["connected"]) or bool(p["bailed"]):
		return false
	if holding:
		if bool(p["holding"]):
			return false
		p["holding"] = true
		p["has_held"] = true
		return true
	else:
		if bool(p["holding"]):
			_bank_player(network_id)
			return true
		return false


func trigger_player_kick(network_id: int) -> bool:
	if not _is_server_sim or _phase != PH_LIVE:
		return false
	if not _players.has(network_id):
		return false
	var p: Dictionary = _players[network_id] as Dictionary
	if not bool(p["alive"]) or not bool(p["connected"]):
		return false
	# Strictly LIVE-ONLY: disabled once bailed or when not actively holding lever
	if bool(p["bailed"]) or not bool(p["holding"]) or bool(p["kick_used"]):
		return false

	p["kick_used"] = true
	p["surge_timer"] = float(C.KICK_SURGE_DURATION)
	p["kick_anim_timer"] = 0.36
	_public_voltage += float(C.KICK_VOLTAGE_DELTA)
	if _event_id != int(C.EVENT_GLITCH_METER):
		_display_voltage = _public_voltage

	if _ai_ctrl != null:
		_ai_ctrl.notify_kick_witnessed(network_id, _round_elapsed, _players)

	_play_kick_fx(network_id)
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_kick_arc.rpc(network_id, _display_voltage)

	if _public_voltage >= _hidden_threshold:
		_trigger_overload_detonation()
	return true


func step_simulation(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	_srv_time += dt
	if _banner_timer > 0.0:
		_banner_timer = maxf(0.0, _banner_timer - dt)
	if _phase == PH_PREP:
		_step_prep(dt)
	elif _phase == PH_LIVE:
		_step_live(dt)
	elif _phase == PH_INTER_ROUND:
		_step_inter_round(dt)


func step_headless(delta: float) -> void:
	step_simulation(delta)


func get_player_state(network_id: int) -> Dictionary:
	if not _players.has(network_id):
		return {}
	return (_players[network_id] as Dictionary).duplicate(false)


func get_state_snapshot() -> Dictionary:
	var snap: Dictionary = _build_snapshot()
	snap["hidden_threshold"] = _hidden_threshold
	snap["round_elapsed"] = _round_elapsed
	snap["detonated"] = _detonated
	snap["slacker_nid"] = _slacker_nid
	snap["early_victory"] = _early_victory
	snap["final_scores"] = _final_scores.duplicate()
	snap["seat_layout"] = _seat_layout.duplicate(true)
	snap["camera_pose"] = C.camera_pose_for_count(_players.size()) if C != null else {}
	return snap


func stage_screenshot_scene(team_mode: bool = false) -> void:
	_phase = PH_LIVE
	_round_idx = 1
	_prep_remaining = 0.0
	_round_elapsed = 8.5
	_round_remaining = 7.5
	_you_marker_timer = 2.0
	_public_voltage = 78.0
	_display_voltage = 78.0
	_hidden_threshold = 94.0
	_event_id = int(C.EVENT_DOUBLE_OVERTIME) if not team_mode else int(C.EVENT_NONE)
	_event_timer = 1.8 if not team_mode else 0.0

	for i in range(_player_order.size()):
		var nid: int = int(_player_order[i])
		var p: Dictionary = _players[nid] as Dictionary
		p["lives"] = 1 if i == 1 else 2
		p["charred"] = (i == 1)
		p["fried_round"] = 1 if i == 1 else 0
		p["alive"] = true
		p["bailed"] = (i == 2)
		p["holding"] = not bool(p["bailed"])
		p["has_held"] = true
		p["kick_used"] = (i == 0)
		p["surge_timer"] = 1.4 if i == 0 else 0.0
		p["kick_anim_timer"] = 0.25 if i == 0 else 0.0
		p["round_kpi"] = 190.0 + float(i) * 42.0 if bool(p["holding"]) else 0.0
		p["round_banked"] = 245 if bool(p["bailed"]) else 0
		p["total_kpi"] = 310 + i * 65

	if not _player_order.is_empty():
		var kicker_id: int = int(_player_order[0])
		_play_kick_fx(kicker_id)
	_update_parallel_arcs_fx()
	if _fx_pool != null:
		_fx_pool.tick(0.08)
	var btxt: String = _pick_loc("DOUBLE OVERTIME x2.0!", "双倍加班 x2.0!", "雙倍加班 x2.0!") if not team_mode else _pick_loc("PARALLEL CIRCUIT +20%!", "并联电路 +20%!", "並聯電路 +20%!")
	if _hud != null:
		_hud.set_countdown("", false)
		_hud.set_banner(btxt, Color(1.0, 0.78, 0.22), true)
	_animate_visuals(1.0)


## ============================================================================
## Match Setup & Official Minigame Entry
## ============================================================================

@rpc("authority", "call_local", "reliable")
func start_round(roster: Array) -> void:
	_load_helpers()
	_is_server_sim = multiplayer.is_server()
	_local_net_id = multiplayer.get_unique_id() if not _standalone_mode else 1
	var round_num: int = 0
	if not roster.is_empty() and roster[0] is Dictionary:
		round_num = int((roster[0] as Dictionary).get("round_number", 0))
	_setup_match_local(round_num, 20261127 + round_num * 97, roster, false)


func player_disconnected(network_id: int) -> void:
	if not _is_server_sim or not _players.has(network_id):
		return
	var p: Dictionary = _players[network_id] as Dictionary
	p["connected"] = false
	if bool(p["holding"]):
		_bank_player(network_id)
	p["alive"] = false


func _clear_scene_children() -> void:
	if _fx_pool != null and _fx_pool.has_method("clear_all"):
		_fx_pool.clear_all()
	for child_node in [_arena_root, _fx_root, _chairs_root]:
		if child_node != null and is_instance_valid(child_node):
			child_node.queue_free()
	_arena_root = null
	_fx_root = null
	_chairs_root = null
	_stage_handles.clear()
	_chair_rigs.clear()
	_needle_pivot = null
	_gauge_glow_mat = null
	_beacon_light = null
	_beacon_mat = null
	_crt_label = null
	_crt_sub_label = null
	_fluorescent_mats.clear()


func _setup_match_local(round_idx: int, seed_val: int, roster: Array, all_ai: bool = false) -> void:
	_load_helpers()
	_clear_scene_children()
	_map_seed = seed_val + round_idx * 31
	_rng.seed = _map_seed

	if _team != null:
		_team.begin_match(self, roster)

	_phase = PH_PREP
	_round_idx = 0
	_srv_time = 0.0
	_prep_remaining = float(C.PREP_DURATION)
	_round_elapsed = 0.0
	_round_remaining = float(C.ROUND_DURATION)
	_inter_round_timer = 0.0
	_last_countdown_sec = 4
	_you_marker_timer = float(C.PREP_DURATION) + 2.5
	_sync_accum = 0.0
	_fx_warmed_up = false

	_public_voltage = 0.0
	_display_voltage = 0.0
	_hidden_threshold = 85.0
	_forced_threshold = -1.0
	_detonated = false
	_slacker_nid = 0
	_early_victory = false
	_event_id = int(C.EVENT_NONE)
	_event_timer = 0.0
	_event_triggered_this_round = false
	_last_round_event_id = int(C.EVENT_NONE)
	_forced_event_id = -1
	_forced_event_time = -1.0
	_penalty_flash_timer = 0.0
	_banner_timer = 0.0
	_banner_text = ""
	_final_scores.clear()
	_summary_rows.clear()
	_parallel_arc_pairs.clear()

	_players.clear()
	_player_order.clear()
	_cam_shake = 0.0
	_prev_hold_input = false
	_prev_kick_input = false

	var sorted_roster: Array = _prepare_sorted_roster(roster)
	_seat_layout = C.compute_seat_layout(sorted_roster.size()) as Array

	_arena_root = Node3D.new()
	_arena_root.name = "ArenaRoot"
	add_child(_arena_root)
	_chairs_root = Node3D.new()
	_chairs_root.name = "ChairsRoot"
	add_child(_chairs_root)
	_fx_root = Node3D.new()
	_fx_root.name = "FxRoot"
	add_child(_fx_root)

	if not _is_self_test:
		_ensure_environment_and_camera(sorted_roster.size())
		_setup_post_fx()
		_init_audio()
		if M != null and M.has_method("build_stage"):
			_stage_handles = M.build_stage(_arena_root, C) as Dictionary
			_needle_pivot = _stage_handles.get("needle_pivot", null) as Node3D
			_gauge_glow_mat = _stage_handles.get("gauge_glow_mat", null) as StandardMaterial3D
			_beacon_light = _stage_handles.get("beacon_light", null) as OmniLight3D
			_beacon_mat = _stage_handles.get("beacon_mat", null) as StandardMaterial3D
			_crt_label = _stage_handles.get("crt_label", null) as Label3D
			_crt_sub_label = _stage_handles.get("crt_sub_label", null) as Label3D
			var t_top = _stage_handles.get("transformer_top", null)
			if t_top is Vector3:
				_transformer_top = t_top as Vector3
			var p_emit = _stage_handles.get("penalty_emitter_pos", null)
			if p_emit is Vector3:
				_penalty_emitter_pos = p_emit as Vector3
			var fl_raw = _stage_handles.get("fluorescent_mats", [])
			if fl_raw is Array:
				_fluorescent_mats = fl_raw as Array
		if _fx_pool != null and _fx_pool.has_method("setup"):
			_fx_pool.setup(_fx_root)
		if _hud != null and _hud.has_method("setup"):
			_hud.setup(self)
			_hud.show_summary("", [], false)
			_hud.set_banner("", Color.WHITE, false)
			_hud.set_countdown("3", true)

	_spawn_players(sorted_roster, all_ai)
	if _ai_ctrl != null:
		_ai_ctrl.reset_match(_players, _map_seed)

	if not _is_self_test:
		_animate_visuals(0.0)


func _prepare_sorted_roster(roster: Array) -> Array:
	var team_active: bool = _team != null and _team.is_active()
	var list: Array = []
	for raw_r in roster:
		if raw_r is Dictionary:
			list.append((raw_r as Dictionary).duplicate(false))
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if team_active:
			var ta: int = int(a.get("team_id", 0))
			if ta <= 0 and _team != null:
				ta = _team.player_team(int(a.get("network_id", 0)))
			var tb: int = int(b.get("team_id", 0))
			if tb <= 0 and _team != null:
				tb = _team.player_team(int(b.get("network_id", 0)))
			var ka: int = ta if ta > 0 else 999
			var kb: int = tb if tb > 0 else 999
			if ka != kb:
				return ka < kb
		return int(a.get("network_id", 0)) < int(b.get("network_id", 0))
	)
	return list


func _spawn_players(sorted_roster: Array, all_ai: bool) -> void:
	var team_active: bool = _team != null and _team.is_active()
	for i in range(sorted_roster.size()):
		var r: Dictionary = sorted_roster[i] as Dictionary
		var nid: int = int(r.get("network_id", i + 1))
		var tid: int = int(r.get("team_id", 0))
		if tid <= 0 and _team != null:
			tid = _team.player_team(nid)
		if not team_active:
			tid = 0
		var is_ai: bool = all_ai or bool(r.get("is_ai", nid < 0))
		var nick: String = str(r.get("nickname", "P%d" % nid))
		var cust: Array = r.get("customization", []) as Array
		var seat: Dictionary = _seat_layout[i] as Dictionary if i < _seat_layout.size() else {"pos": Vector3.ZERO, "yaw": PI, "row": 0}
		var seat_pos: Vector3 = seat.get("pos", Vector3.ZERO) as Vector3
		var seat_yaw: float = float(seat.get("yaw", PI))
		var accent: Color = C.team_color(tid) as Color if (team_active and tid > 0) else (C.player_fallback_color(i) as Color)
		var t_tag: String = _team.team_tag(tid) if (team_active and _team != null and tid > 0) else ""

		var rig: Dictionary = {}
		var cable_anchor: Vector3 = seat_pos + Vector3(0.0, 2.0, 0.0)
		var body_root: Node3D = null
		if not _is_self_test and M != null and M.has_method("build_chair_rig") and _chairs_root != null:
			rig = M.build_chair_rig(_chairs_root, i, seat_pos, seat_yaw, accent, nick, cust, t_tag) as Dictionary
			_chair_rigs[nid] = rig
			var ca = rig.get("cable_anchor", null)
			if ca is Vector3:
				cable_anchor = ca as Vector3
			body_root = rig.get("body_root", null) as Node3D
			var is_local: bool = (not is_ai) and (nid == _local_net_id)
			if is_local and body_root != null and is_instance_valid(body_root):
				body_root.add_to_group(&"mpm_local_player")
				body_root.set_meta(&"mpm_local_player", true)

		_player_order.append(nid)
		_players[nid] = {
			"network_id": nid,
			"slot_index": i,
			"nickname": nick,
			"team_id": tid,
			"team_tag": t_tag,
			"is_ai": is_ai,
			"connected": true,
			"lives": int(C.START_LIVES),
			"alive": true,
			"holding": false,
			"has_held": false,
			"bailed": false,
			"kick_used": false,
			"surge_timer": 0.0,
			"round_kpi": 0.0,
			"round_banked": 0,
			"total_kpi": 0,
			"bail_time": -1.0,
			"fried_round": 0,
			"charred": false,
			"kick_anim_timer": 0.0,
			"slacker_jolt_timer": 0.0,
			"seat_pos": seat_pos,
			"seat_yaw": seat_yaw,
			"cable_anchor": cable_anchor,
			"accent_color": accent,
		}


func _ensure_environment_and_camera(player_count: int) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.name = "StageCamera"
		_camera.current = true
		add_child(_camera)

	var pose: Dictionary = C.camera_pose_for_count(player_count) as Dictionary
	_cam_base_pos = pose.get("pos", Vector3(0.0, 2.75, 4.55)) as Vector3
	_cam_look_at = pose.get("look_at", Vector3(0.0, 1.52, -1.55)) as Vector3
	_camera.fov = float(pose.get("fov", 44.0))
	_camera.position = _cam_base_pos
	_camera.look_at(_cam_look_at, Vector3.UP)

	if get_node_or_null("WorldEnv") == null:
		var env_node := WorldEnvironment.new()
		env_node.name = "WorldEnv"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.02, 0.022, 0.025)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.70, 0.70, 0.70)
		env.ambient_light_energy = 0.15
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.12
		env.adjustment_saturation = 0.65
		env.glow_enabled = true
		env.glow_intensity = 0.28
		env.glow_bloom = 0.06
		env_node.environment = env
		add_child(env_node)


func _setup_post_fx() -> void:
	if _shader_layer != null and is_instance_valid(_shader_layer):
		return
	var post_shader: Shader = null
	var vig_shader: Shader = null
	if ResourceLoader.exists("res://shaders/posterization.gdshader"):
		post_shader = ResourceLoader.load("res://shaders/posterization.gdshader") as Shader
	if ResourceLoader.exists("res://shaders/vignette.gdshader"):
		vig_shader = ResourceLoader.load("res://shaders/vignette.gdshader") as Shader
	if post_shader == null and vig_shader == null:
		return

	_shader_layer = CanvasLayer.new()
	_shader_layer.name = "PostFXLayer"
	_shader_layer.layer = 1
	add_child(_shader_layer)

	var fx_root := Control.new()
	fx_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_layer.add_child(fx_root)

	if vig_shader != null:
		var vig_holder := Control.new()
		vig_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vig_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_root.add_child(vig_holder)
		var vig_copy := BackBufferCopy.new()
		vig_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		vig_holder.add_child(vig_copy)
		var vig_rect := ColorRect.new()
		vig_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vig_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vm := ShaderMaterial.new()
		vm.shader = vig_shader
		vm.set_shader_parameter("radius", 0.922)
		vm.set_shader_parameter("softness", 0.367)
		vm.set_shader_parameter("intensity", 2.0)
		vm.set_shader_parameter("contrast", 1.572)
		vm.set_shader_parameter("vignette_color", Color(0.0, 0.0, 0.0, 1.0))
		vig_rect.material = vm
		vig_holder.add_child(vig_rect)

	if post_shader != null:
		var post_holder := Control.new()
		post_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		post_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_root.add_child(post_holder)
		var post_copy := BackBufferCopy.new()
		post_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		post_holder.add_child(post_copy)
		var post_rect := ColorRect.new()
		post_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pm := ShaderMaterial.new()
		pm.shader = post_shader
		pm.set_shader_parameter("SCREEN_WIDTH", 320.0)
		pm.set_shader_parameter("RED_COMPONENT", 12.0)
		pm.set_shader_parameter("GREEN_COMPONENT", 12.0)
		pm.set_shader_parameter("BLUE_COMPONENT", 12.0)
		post_rect.material = pm
		post_holder.add_child(post_rect)


func _make_audio_player(res_path: String, vol_db: float) -> AudioStreamPlayer:
	if not ResourceLoader.exists(res_path):
		return null
	var st = ResourceLoader.load(res_path)
	if not (st is AudioStream):
		return null
	var ap := AudioStreamPlayer.new()
	ap.stream = st as AudioStream
	ap.volume_db = vol_db
	add_child(ap)
	return ap


func _init_audio() -> void:
	if _sfx_ding != null:
		return
	_sfx_ding = _make_audio_player("res://audio/sfx/ding.wav", -6.0)
	_sfx_warn = _make_audio_player("res://audio/sfx/beep.wav", -5.0)
	_sfx_buzz = _make_audio_player("res://audio/sfx/buzz.wav", -8.0)
	_sfx_blast = _make_audio_player("res://audio/sfx/explosion.wav", -4.0)


func _play_sfx(ap: AudioStreamPlayer) -> void:
	if ap != null and is_instance_valid(ap) and not _is_self_test:
		ap.play()


## ============================================================================
## Simulation Loop (Host Authoritative)
## ============================================================================

func _process(delta: float) -> void:
	if _is_self_test or not _screenshot_path.is_empty():
		return
	if not _fx_warmed_up and _fx_pool != null and _camera != null:
		_fx_warmed_up = true
		if _fx_pool.has_method("warmup_in_frustum"):
			_fx_pool.warmup_in_frustum(_camera)

	var dt: float = minf(delta, 0.05)
	if _you_marker_timer > 0.0:
		_you_marker_timer = maxf(0.0, _you_marker_timer - dt)

	_poll_local_input()

	if _is_server_sim:
		step_simulation(dt)
		if not _standalone_mode and multiplayer.has_multiplayer_peer():
			_sync_accum += dt
			if _sync_accum >= float(C.SNAPSHOT_INTERVAL):
				_sync_accum = 0.0
				_rpc_state_snapshot.rpc(_build_snapshot())
	else:
		_srv_time += dt
		if _banner_timer > 0.0:
			_banner_timer = maxf(0.0, _banner_timer - dt)

	_animate_visuals(dt)


func _poll_local_input() -> void:
	if _phase != PH_LIVE or not _players.has(_local_net_id):
		_prev_hold_input = false
		_prev_kick_input = false
		return
	var p: Dictionary = _players[_local_net_id] as Dictionary
	if bool(p.get("is_ai", false)) or not bool(p.get("alive", true)) or bool(p.get("bailed", false)):
		_prev_hold_input = false
		_prev_kick_input = false
		return

	var hold_now: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	if InputMap.has_action("action_1"):
		hold_now = hold_now or Input.is_action_pressed("action_1")
	if Input.get_connected_joypads().size() > 0:
		hold_now = hold_now or Input.is_joy_button_pressed(0, JOY_BUTTON_A)

	var kick_down: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	if InputMap.has_action("action_2"):
		kick_down = kick_down or Input.is_action_pressed("action_2")
	if Input.get_connected_joypads().size() > 0:
		kick_down = kick_down or Input.is_joy_button_pressed(0, JOY_BUTTON_X) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)

	if hold_now != _prev_hold_input:
		_prev_hold_input = hold_now
		if _is_server_sim:
			set_player_holding(_local_net_id, hold_now)
		elif multiplayer.has_multiplayer_peer():
			_rpc_set_holding.rpc_id(1, hold_now)

	var kick_edge: bool = kick_down and not _prev_kick_input
	_prev_kick_input = kick_down
	if kick_edge:
		if _is_server_sim:
			trigger_player_kick(_local_net_id)
		elif multiplayer.has_multiplayer_peer():
			_rpc_trigger_kick.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_set_holding(holding: bool) -> void:
	if not _is_server_sim:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		sender = 1
	set_player_holding(sender, holding)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_trigger_kick() -> void:
	if not _is_server_sim:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		sender = 1
	trigger_player_kick(sender)


func _step_prep(dt: float) -> void:
	_prep_remaining = maxf(0.0, _prep_remaining - dt)
	var sec: int = ceili(_prep_remaining)
	if sec != _last_countdown_sec and _hud != null and not _is_self_test:
		_last_countdown_sec = sec
		if sec > 0:
			_hud.set_countdown(str(sec), true)
			_play_sfx(_sfx_warn)
		else:
			_hud.set_countdown(_pick_loc("GO!", "开始!", "開始!"), true)
			_play_sfx(_sfx_ding)
	if _prep_remaining <= 0.0:
		_begin_round(0)


func _begin_round(round_idx: int) -> void:
	_round_idx = round_idx
	_phase = PH_LIVE
	_round_elapsed = 0.0
	_round_remaining = float(C.ROUND_DURATION)
	_public_voltage = 0.0
	_display_voltage = 0.0
	_detonated = false
	_slacker_nid = 0
	_event_id = int(C.EVENT_NONE)
	_event_timer = 0.0
	_event_triggered_this_round = false
	_prev_hold_input = false
	_prev_kick_input = false

	if _forced_threshold >= 0.0:
		_hidden_threshold = _forced_threshold
	else:
		_rng.seed = _map_seed + (_round_idx + 1) * 4099
		_hidden_threshold = _rng.randf_range(float(C.THRESHOLD_MIN), float(C.THRESHOLD_MAX))

	# Rounds 2 & 3 introduce 1 mid-round Coach Industrial Event
	if _forced_event_id >= 0:
		_scheduled_event_id = _forced_event_id
		_scheduled_event_time = _forced_event_time if _forced_event_time >= 0.0 else 4.5
	elif _round_idx >= 1:
		var pool: Array = [int(C.EVENT_FALSE_ALARM), int(C.EVENT_GLITCH_METER), int(C.EVENT_DOUBLE_OVERTIME)]
		if _last_round_event_id > 0:
			pool.erase(_last_round_event_id)
		_scheduled_event_id = int(pool[_rng.randi_range(0, pool.size() - 1)])
		_scheduled_event_time = _rng.randf_range(4.0, 7.8)
	else:
		_scheduled_event_id = int(C.EVENT_NONE)
		_scheduled_event_time = 999.0

	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		p["holding"] = false
		p["has_held"] = false
		p["bailed"] = false
		p["kick_used"] = false
		p["surge_timer"] = 0.0
		p["round_kpi"] = 0.0
		p["round_banked"] = 0
		p["bail_time"] = -1.0
		p["kick_anim_timer"] = 0.0
		p["slacker_jolt_timer"] = 0.0

	if _ai_ctrl != null:
		_ai_ctrl.reset_round(_round_idx, _players, _map_seed + _round_idx * 911)

	var r_txt: String = _pick_loc("ROUND %d/%d", "第 %d/%d 回合", "第 %d/%d 回合") % [_round_idx + 1, int(C.TOTAL_ROUNDS)]
	_set_banner_local(r_txt, Color(1.0, 0.82, 0.28), 1.4)
	if _hud != null and not _is_self_test:
		_hud.set_countdown("", false)


func _step_live(dt: float) -> void:
	_round_elapsed += dt
	_round_remaining = maxf(0.0, _round_remaining - dt)

	# Trigger scheduled Coach Industrial Event in Round 2/3
	if not _event_triggered_this_round and _scheduled_event_id != int(C.EVENT_NONE):
		if _round_elapsed >= _scheduled_event_time or _public_voltage >= 56.0:
			_activate_coach_event(_scheduled_event_id)

	if _event_timer > 0.0:
		_event_timer = maxf(0.0, _event_timer - dt)
		if _event_timer <= 0.0:
			_event_id = int(C.EVENT_NONE)

	# Decay per-player timers
	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if float(p["surge_timer"]) > 0.0:
			p["surge_timer"] = maxf(0.0, float(p["surge_timer"]) - dt)
		if float(p["kick_anim_timer"]) > 0.0:
			p["kick_anim_timer"] = maxf(0.0, float(p["kick_anim_timer"]) - dt)
		if float(p["slacker_jolt_timer"]) > 0.0:
			p["slacker_jolt_timer"] = maxf(0.0, float(p["slacker_jolt_timer"]) - dt)

	# Bot AI decisions
	if _ai_ctrl != null:
		var team_active: bool = _team != null and _team.is_active()
		var ai_state := {
			"players": _players,
			"public_voltage": _public_voltage,
			"round_elapsed": _round_elapsed,
			"event_id": _event_id,
			"round_idx": _round_idx,
			"team_active": team_active,
		}
		for raw_nid in _player_order:
			var nid: int = int(raw_nid)
			var p: Dictionary = _players[nid] as Dictionary
			if not bool(p["is_ai"]) or not bool(p["alive"]) or not bool(p["connected"]) or bool(p["bailed"]):
				continue
			var dec: Dictionary = _ai_ctrl.compute_bot_decision(nid, ai_state, C) as Dictionary
			var want_hold: bool = bool(dec.get("holding", false))
			var want_kick: bool = bool(dec.get("kick", false))
			if want_hold and not bool(p["holding"]):
				set_player_holding(nid, true)
			elif not want_hold and bool(p["holding"]):
				set_player_holding(nid, false)
			if want_kick and bool(p["holding"]) and not bool(p["bailed"]):
				trigger_player_kick(nid)
				if _phase != PH_LIVE:
					return

	# Count active holders & team living counts
	var holders: int = 0
	var living_count: int = 0
	var bailed_count: int = 0
	var team_live_holders: Dictionary = {}
	var team_living_counts: Dictionary = {}
	var team_active: bool = _team != null and _team.is_active()

	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if not bool(p["alive"]) or not bool(p["connected"]):
			continue
		living_count += 1
		var tid: int = int(p["team_id"])
		if team_active and tid > 0:
			team_living_counts[tid] = int(team_living_counts.get(tid, 0)) + 1
		if bool(p["bailed"]):
			bailed_count += 1
		if bool(p["holding"]):
			holders += 1
			if team_active and tid > 0:
				team_live_holders[tid] = int(team_live_holders.get(tid, 0)) + 1

	# Advance public transformer voltage (False Alarm pauses actual rise!)
	if holders > 0 and _event_id != int(C.EVENT_FALSE_ALARM):
		var round_volt_scale: float = 1.0 + 0.14 * float(_round_idx)
		var volt_rate: float = (4.5 + sqrt(float(holders)) * 3.0) * round_volt_scale
		_public_voltage += volt_rate * dt

	if _event_id == int(C.EVENT_GLITCH_METER):
		_display_voltage = clampf(fmod(_srv_time * 317.0, 99.0), 5.0, 99.0)
	else:
		_display_voltage = _public_voltage

	# Accumulate accelerating KPI for live holders
	var v_norm: float = clampf(_public_voltage / 100.0, 0.0, 1.2)
	var curve_mult: float = 0.65 + 1.85 * (v_norm * v_norm) + 0.55 * v_norm
	var round_mults: Array = C.ROUND_MULTIPLIERS as Array
	var round_mult: float = float(round_mults[clampi(_round_idx, 0, round_mults.size() - 1)])
	var overtime_mult: float = float(C.DOUBLE_OVERTIME_MULT) if (_event_id == int(C.EVENT_DOUBLE_OVERTIME) and _event_timer > 0.0) else 1.0

	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if not bool(p["alive"]) or not bool(p["holding"]) or bool(p["bailed"]):
			continue
		var surge_mult: float = float(C.KICK_SURGE_MULT) if float(p["surge_timer"]) > 0.0 else 1.0
		var team_mult: float = 1.0
		if team_active:
			var tid: int = int(p["team_id"])
			if int(team_live_holders.get(tid, 0)) >= 2:
				team_mult = float(C.TEAM_PARALLEL_MULT)
			elif int(team_living_counts.get(tid, 0)) == 1:
				team_mult = float(C.SOLO_TEAM_MULT)
		p["round_kpi"] = float(p["round_kpi"]) + float(C.BASE_KPI_RATE) * curve_mult * round_mult * surge_mult * overtime_mult * team_mult * dt

	# Check Overload Detonation
	if _public_voltage >= _hidden_threshold:
		_trigger_overload_detonation()
		return

	# Check Safe Round End (all living players bailed, or timer expired)
	if (living_count > 0 and bailed_count >= living_count) or _round_remaining <= 0.0:
		_resolve_safe_round_end()


func _activate_coach_event(ev_id: int) -> void:
	_event_triggered_this_round = true
	_event_id = ev_id
	_last_round_event_id = ev_id
	if ev_id == int(C.EVENT_FALSE_ALARM):
		_event_timer = float(C.FALSE_ALARM_DURATION)
		_set_banner_local(_pick_loc("FALSE ALARM!", "误报警铃!", "誤報警鈴!"), Color(1.0, 0.28, 0.24), float(C.FALSE_ALARM_DURATION))
		_play_sfx(_sfx_warn)
	elif ev_id == int(C.EVENT_GLITCH_METER):
		_event_timer = float(C.GLITCH_METER_DURATION)
		_set_banner_local(_pick_loc("GLITCHING METER!", "电表乱码!", "電錶亂碼!"), Color(0.98, 0.62, 0.22), float(C.GLITCH_METER_DURATION))
		_play_sfx(_sfx_buzz)
	elif ev_id == int(C.EVENT_DOUBLE_OVERTIME):
		_event_timer = float(C.DOUBLE_OVERTIME_DURATION)
		_set_banner_local(_pick_loc("DOUBLE OVERTIME x2.0!", "双倍加班 x2.0!", "雙倍加班 x2.0!"), Color(1.0, 0.86, 0.24), float(C.DOUBLE_OVERTIME_DURATION))
		_play_sfx(_sfx_ding)
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_coach_event.rpc(ev_id)


func _bank_player(network_id: int) -> void:
	var p: Dictionary = _players[network_id] as Dictionary
	var banked: int = int(roundf(float(p["round_kpi"])))
	p["holding"] = false
	p["bailed"] = true
	p["bail_time"] = _round_elapsed
	p["round_banked"] = banked
	p["round_kpi"] = 0.0
	p["total_kpi"] = int(p["total_kpi"]) + banked


func _trigger_overload_detonation() -> void:
	_detonated = true
	_phase = PH_INTER_ROUND
	_inter_round_timer = float(C.INTER_ROUND_DURATION)
	_display_voltage = _public_voltage

	var fried_nids: Array = []
	var elim_nids: Array = []
	for raw_nid in _player_order:
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[nid] as Dictionary
		if not bool(p["alive"]):
			continue
		if bool(p["holding"]):
			p["holding"] = false
			p["round_kpi"] = 0.0
			p["round_banked"] = 0
			p["lives"] = maxi(0, int(p["lives"]) - 1)
			p["fried_round"] = _round_idx + 1
			p["charred"] = true
			var lethal: bool = int(p["lives"]) <= 0
			if lethal:
				p["alive"] = false
				elim_nids.append(nid)
			fried_nids.append(nid)
			if _fx_pool != null and _fx_pool.has_method("trigger_fry") and not _is_self_test:
				_fx_pool.trigger_fry((p["seat_pos"] as Vector3) + Vector3(0.0, 0.9, 0.0), lethal)

	if _fx_pool != null and _fx_pool.has_method("trigger_transformer_blast") and not _is_self_test:
		_fx_pool.trigger_transformer_blast(_transformer_top)
	_cam_shake = 0.45
	_play_sfx(_sfx_blast)
	_set_banner_local(
		_pick_loc("OVERLOAD AT %d%%! (%d FRIED)", "%d%% 过载爆表! (%d 人触电)", "%d%% 過載爆表! (%d 人觸電)") % [int(roundf(_hidden_threshold)), fried_nids.size()],
		Color(1.0, 0.26, 0.22),
		float(C.INTER_ROUND_DURATION)
	)
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_detonation.rpc(fried_nids, elim_nids, _hidden_threshold)


func _resolve_safe_round_end() -> void:
	# Anyone still holding when the 16s timer ends banks safely
	for raw_nid in _player_order:
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[nid] as Dictionary
		if bool(p["alive"]) and bool(p["holding"]):
			_bank_player(nid)

	_phase = PH_INTER_ROUND
	_inter_round_timer = float(C.INTER_ROUND_DURATION)

	# Coach Anti-Slacker Callout: lowest round_banked among living players gets -50%
	var living: Array = []
	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if bool(p["alive"]) and bool(p["connected"]):
			living.append(p)
	if living.size() >= 2:
		living.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ka: int = int(a["round_banked"])
			var kb: int = int(b["round_banked"])
			if ka != kb:
				return ka < kb
			var ba: float = float(a["bail_time"]) if float(a["bail_time"]) >= 0.0 else 0.0
			var bb: float = float(b["bail_time"]) if float(b["bail_time"]) >= 0.0 else 0.0
			if not is_equal_approx(ba, bb):
				return ba < bb
			return int(a["network_id"]) < int(b["network_id"])
		)
		var slacker: Dictionary = living[0] as Dictionary
		var slacker_id: int = int(slacker["network_id"])
		var penalty: int = int(roundf(float(slacker["round_banked"]) * float(C.SLACKER_PENALTY_RATIO)))
		slacker["round_banked"] = maxi(0, int(slacker["round_banked"]) - penalty)
		slacker["total_kpi"] = maxi(0, int(slacker["total_kpi"]) - penalty)
		slacker["slacker_jolt_timer"] = 0.65
		_slacker_nid = slacker_id
		_penalty_flash_timer = 1.0
		if _fx_pool != null and not _is_self_test:
			var target_pos: Vector3 = (slacker["seat_pos"] as Vector3) + Vector3(0.0, 1.0, 0.0)
			if _fx_pool.has_method("trigger_kick_arc"):
				_fx_pool.trigger_kick_arc(_penalty_emitter_pos, target_pos, Color(1.0, 0.35, 0.14))
			if _fx_pool.has_method("trigger_slacker_jolt"):
				_fx_pool.trigger_slacker_jolt(target_pos)
		_play_sfx(_sfx_warn)
		_set_banner_local(
			_pick_loc("SLACKER PENALTY -50%%! %s (-%d KPI)", "绩效垫底电罚 -50%%! %s (-%d KPI)", "績效墊底電罰 -50%%! %s (-%d KPI)") % [str(slacker["nickname"]), penalty],
			Color(1.0, 0.56, 0.18),
			float(C.INTER_ROUND_DURATION)
		)
		if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			_rpc_slacker_callout.rpc(slacker_id, penalty)


func _step_inter_round(dt: float) -> void:
	_inter_round_timer = maxf(0.0, _inter_round_timer - dt)
	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if float(p["slacker_jolt_timer"]) > 0.0:
			p["slacker_jolt_timer"] = maxf(0.0, float(p["slacker_jolt_timer"]) - dt)

	if _inter_round_timer <= 0.0:
		if _check_early_victory() or _round_idx >= int(C.TOTAL_ROUNDS) - 1:
			_finish_match()
		else:
			_begin_round(_round_idx + 1)


func _check_early_victory() -> bool:
	var team_active: bool = _team != null and _team.is_active()
	if team_active:
		var alive_teams: Dictionary = {}
		for raw_nid in _player_order:
			var p: Dictionary = _players[raw_nid] as Dictionary
			if bool(p["alive"]) and bool(p["connected"]) and int(p["team_id"]) > 0:
				alive_teams[int(p["team_id"])] = true
		if alive_teams.size() <= 1:
			_early_victory = true
			return true
		return false

	var alive_players: int = 0
	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if bool(p["alive"]) and bool(p["connected"]):
			alive_players += 1
	if alive_players <= 1:
		_early_victory = true
		return true
	return false


func _finish_match() -> void:
	if _phase == PH_ENDED:
		return
	_phase = PH_ENDED

	var team_active: bool = _team != null and _team.is_active()
	var alive_ids: Array = []
	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if bool(p["alive"]):
			alive_ids.append(int(raw_nid))

	var entries: Array = []
	for raw_nid in _player_order:
		var p: Dictionary = _players[raw_nid] as Dictionary
		entries.append({
			"network_id": int(p["network_id"]),
			"nickname": str(p["nickname"]),
			"team_id": int(p["team_id"]),
			"team_tag": str(p["team_tag"]),
			"kpi": int(p["total_kpi"]),
			"lives": int(p["lives"]),
			"alive": bool(p["alive"]),
			"is_local": (not bool(p["is_ai"])) and (int(p["network_id"]) == _local_net_id),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["kpi"]) != int(b["kpi"]):
			return int(a["kpi"]) > int(b["kpi"])
		if bool(a["alive"]) != bool(b["alive"]):
			return bool(a["alive"])
		if int(a["lives"]) != int(b["lives"]):
			return int(a["lives"]) > int(b["lives"])
		return int(a["network_id"]) < int(b["network_id"])
	)

	_summary_rows.clear()
	for i in range(entries.size()):
		var row: Dictionary = (entries[i] as Dictionary).duplicate(false)
		row["rank"] = i + 1
		_summary_rows.append(row)

	var raw_scores: Dictionary = {}
	var winner_tid: int = 0

	if team_active:
		var team_kpis: Dictionary = {}
		var team_alive: Dictionary = {}
		for raw_e in entries:
			var e: Dictionary = raw_e as Dictionary
			var tid: int = int(e["team_id"])
			if tid <= 0:
				continue
			team_kpis[tid] = int(team_kpis.get(tid, 0)) + int(e["kpi"])
			if bool(e["alive"]):
				team_alive[tid] = true
		var ranked_teams: Array = []
		for raw_tid in team_kpis.keys():
			var tid: int = int(raw_tid)
			ranked_teams.append({
				"tid": tid,
				"kpi": int(team_kpis[tid]),
				"alive": bool(team_alive.get(tid, false)),
			})
		ranked_teams.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if _early_victory and bool(a["alive"]) != bool(b["alive"]):
				return bool(a["alive"])
			if int(a["kpi"]) != int(b["kpi"]):
				return int(a["kpi"]) > int(b["kpi"])
			return int(a["tid"]) < int(b["tid"])
		)
		var team_pts: Dictionary = {}
		var t_total: int = ranked_teams.size()
		for ti in range(t_total):
			var rt: Dictionary = ranked_teams[ti] as Dictionary
			team_pts[int(rt["tid"])] = maxi(1, t_total - ti)
		if not ranked_teams.is_empty():
			winner_tid = int((ranked_teams[0] as Dictionary)["tid"])
		for raw_e in entries:
			var e: Dictionary = raw_e as Dictionary
			var nid: int = int(e["network_id"])
			var tid: int = int(e["team_id"])
			raw_scores[nid] = int(team_pts.get(tid, 1))
		_final_scores = _team.sync_scores(raw_scores, alive_ids) as Dictionary
		_team.notify_round_win(_final_scores, self)
		if not _standalone_mode:
			_team.mark_scores_applied(self)
	else:
		var total_p: int = _summary_rows.size()
		for raw_row in _summary_rows:
			var row: Dictionary = raw_row as Dictionary
			raw_scores[int(row["network_id"])] = maxi(1, total_p - int(row["rank"]) + 1)
		_final_scores = raw_scores

	var title: String = _pick_loc("FINAL RESULTS", "最终结算", "最終結算")
	if team_active and winner_tid > 0 and _team != null:
		title = _team.team_win_banner(winner_tid)
	elif not _summary_rows.is_empty():
		title = _pick_loc("%s WINS!", "%s 获胜!", "%s 獲勝!") % [str((_summary_rows[0] as Dictionary)["nickname"])]

	if _hud != null and not _is_self_test:
		_hud.set_banner(title, Color(1.0, 0.86, 0.28), true)
		if _standalone_mode:
			_hud.show_summary(title, _summary_rows, true)

	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_round_end.rpc(_final_scores, _summary_rows, winner_tid)

	round_finished.emit(_final_scores)


func _set_banner_local(text: String, color: Color, duration: float) -> void:
	_banner_text = text
	_banner_color = color
	_banner_timer = duration
	if _hud != null and not _is_self_test:
		_hud.set_banner(text, color, not text.is_empty())


func _play_kick_fx(kicker_nid: int) -> void:
	if _is_self_test or _fx_pool == null or not _players.has(kicker_nid):
		return
	var p: Dictionary = _players[kicker_nid] as Dictionary
	var from_pos: Vector3 = p.get("cable_anchor", Vector3.ZERO) as Vector3
	var col: Color = p.get("accent_color", Color(1.0, 0.45, 0.20)) as Color
	if _fx_pool.has_method("trigger_kick_arc"):
		_fx_pool.trigger_kick_arc(from_pos, _transformer_top, col)
	_cam_shake = maxf(_cam_shake, 0.22)
	_play_sfx(_sfx_buzz)


func _update_parallel_arcs_fx() -> void:
	if _fx_pool == null or not _fx_pool.has_method("update_parallel_arcs"):
		return
	_parallel_arc_pairs.clear()
	if _team != null and _team.is_active() and _phase == PH_LIVE:
		var by_team: Dictionary = {}
		for raw_nid in _player_order:
			var p: Dictionary = _players[raw_nid] as Dictionary
			if bool(p["alive"]) and bool(p["holding"]) and not bool(p["bailed"]):
				var tid: int = int(p["team_id"])
				if tid > 0:
					if not by_team.has(tid):
						by_team[tid] = []
					(by_team[tid] as Array).append(p["cable_anchor"])
		for raw_tid in by_team.keys():
			var tid: int = int(raw_tid)
			var anchors: Array = by_team[tid] as Array
			if anchors.size() >= 2:
				var col: Color = C.team_color(tid) as Color
				for i in range(anchors.size() - 1):
					_parallel_arc_pairs.append({
						"a": anchors[i],
						"b": anchors[i + 1],
						"color": col,
					})
	_fx_pool.update_parallel_arcs(_parallel_arc_pairs)


## ============================================================================
## 20 Hz Network Snapshots & Reliable Event RPCs
## ============================================================================

func _build_snapshot() -> Dictionary:
	# Strictly NEVER includes _hidden_threshold!
	var p_snaps: Dictionary = {}
	for raw_nid in _player_order:
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[nid] as Dictionary
		p_snaps[nid] = {
			"h": bool(p["holding"]),
			"b": bool(p["bailed"]),
			"a": bool(p["alive"]),
			"l": int(p["lives"]),
			"rk": int(roundf(float(p["round_kpi"]))),
			"tk": int(p["total_kpi"]),
			"ku": bool(p["kick_used"]),
			"fr": int(p["fried_round"]),
			"ch": bool(p["charred"]),
			"st": float(p["surge_timer"]),
		}
	return {
		"ri": _round_idx,
		"ph": _phase,
		"pt": _prep_remaining if _phase == PH_PREP else (_inter_round_timer if _phase == PH_INTER_ROUND else _round_remaining),
		"dv": _display_voltage,
		"ei": _event_id,
		"et": _event_timer,
		"pl": p_snaps,
	}


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_state_snapshot(snap: Dictionary) -> void:
	if _is_server_sim:
		return
	_round_idx = int(snap.get("ri", _round_idx))
	_phase = int(snap.get("ph", _phase))
	var pt: float = float(snap.get("pt", 0.0))
	if _phase == PH_PREP:
		_prep_remaining = pt
	elif _phase == PH_INTER_ROUND:
		_inter_round_timer = pt
	else:
		_round_remaining = pt
	_display_voltage = float(snap.get("dv", _display_voltage))
	_public_voltage = _display_voltage
	_event_id = int(snap.get("ei", _event_id))
	_event_timer = float(snap.get("et", _event_timer))

	var pl_raw = snap.get("pl", {})
	if pl_raw is Dictionary:
		for raw_nid in (pl_raw as Dictionary).keys():
			var nid: int = int(raw_nid)
			if not _players.has(nid):
				continue
			var ps: Dictionary = (pl_raw as Dictionary)[raw_nid] as Dictionary
			var p: Dictionary = _players[nid] as Dictionary
			p["holding"] = bool(ps.get("h", false))
			p["bailed"] = bool(ps.get("b", false))
			p["alive"] = bool(ps.get("a", true))
			p["lives"] = int(ps.get("l", 2))
			p["round_kpi"] = float(ps.get("rk", 0))
			p["total_kpi"] = int(ps.get("tk", 0))
			p["kick_used"] = bool(ps.get("ku", false))
			p["fried_round"] = int(ps.get("fr", 0))
			p["charred"] = bool(ps.get("ch", false))
			p["surge_timer"] = float(ps.get("st", 0.0))


@rpc("authority", "call_remote", "reliable")
func _rpc_kick_arc(kicker_nid: int, new_display_volt: float) -> void:
	if _is_server_sim:
		return
	_display_voltage = new_display_volt
	if _players.has(kicker_nid):
		(_players[kicker_nid] as Dictionary)["kick_anim_timer"] = 0.36
	_play_kick_fx(kicker_nid)


@rpc("authority", "call_remote", "reliable")
func _rpc_coach_event(ev_id: int) -> void:
	if _is_server_sim:
		return
	_activate_coach_event(ev_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_detonation(fried_nids: Array, elim_nids: Array, reveal_threshold: float) -> void:
	if _is_server_sim:
		return
	_display_voltage = reveal_threshold
	_public_voltage = reveal_threshold
	for raw_nid in fried_nids:
		var nid: int = int(raw_nid)
		if _players.has(nid):
			var p: Dictionary = _players[nid] as Dictionary
			var lethal: bool = elim_nids.has(nid)
			p["charred"] = true
			if lethal:
				p["alive"] = false
			if _fx_pool != null and _fx_pool.has_method("trigger_fry"):
				_fx_pool.trigger_fry((p["seat_pos"] as Vector3) + Vector3(0.0, 0.9, 0.0), lethal)
	if _fx_pool != null and _fx_pool.has_method("trigger_transformer_blast"):
		_fx_pool.trigger_transformer_blast(_transformer_top)
	_cam_shake = 0.45
	_play_sfx(_sfx_blast)
	_set_banner_local(
		_pick_loc("OVERLOAD AT %d%%! (%d FRIED)", "%d%% 过载爆表! (%d 人触电)", "%d%% 過載爆表! (%d 人觸電)") % [int(roundf(reveal_threshold)), fried_nids.size()],
		Color(1.0, 0.26, 0.22),
		float(C.INTER_ROUND_DURATION)
	)


@rpc("authority", "call_remote", "reliable")
func _rpc_slacker_callout(slacker_id: int, penalty: int) -> void:
	if _is_server_sim:
		return
	if _players.has(slacker_id):
		var p: Dictionary = _players[slacker_id] as Dictionary
		p["slacker_jolt_timer"] = 0.65
		_penalty_flash_timer = 1.0
		if _fx_pool != null:
			var target_pos: Vector3 = (p["seat_pos"] as Vector3) + Vector3(0.0, 1.0, 0.0)
			if _fx_pool.has_method("trigger_kick_arc"):
				_fx_pool.trigger_kick_arc(_penalty_emitter_pos, target_pos, Color(1.0, 0.35, 0.14))
			if _fx_pool.has_method("trigger_slacker_jolt"):
				_fx_pool.trigger_slacker_jolt(target_pos)
		_play_sfx(_sfx_warn)
		_set_banner_local(
			_pick_loc("SLACKER PENALTY -50%%! %s (-%d KPI)", "绩效垫底电罚 -50%%! %s (-%d KPI)", "績效墊底電罰 -50%%! %s (-%d KPI)") % [str(p["nickname"]), penalty],
			Color(1.0, 0.56, 0.18),
			float(C.INTER_ROUND_DURATION)
		)


@rpc("authority", "call_remote", "reliable")
func _rpc_round_end(final_scores: Dictionary, rows: Array, winner_tid: int) -> void:
	if _is_server_sim:
		return
	_phase = PH_ENDED
	_final_scores = final_scores.duplicate()
	_summary_rows = rows.duplicate(true)
	var title: String = _pick_loc("FINAL RESULTS", "最终结算", "最終結算")
	if winner_tid > 0 and _team != null:
		title = _team.team_win_banner(winner_tid)
	elif not _summary_rows.is_empty():
		title = _pick_loc("%s WINS!", "%s 获胜!", "%s 獲勝!") % [str((_summary_rows[0] as Dictionary)["nickname"])]
	if _hud != null and not _is_self_test:
		_hud.set_banner(title, Color(1.0, 0.86, 0.28), true)
	round_finished.emit(_final_scores)


## ============================================================================
## Visual Sync (Zero Allocations)
## ============================================================================

func _animate_visuals(dt: float) -> void:
	if _is_self_test:
		return

	if _penalty_flash_timer > 0.0:
		_penalty_flash_timer = maxf(0.0, _penalty_flash_timer - dt)

	if _camera != null and is_instance_valid(_camera):
		var sway_offset := Vector3.ZERO
		var sway_rot_deg := Vector3.ZERO
		if _screenshot_path.is_empty():
			sway_offset = Vector3(sin(_srv_time * 0.55) * 0.025, cos(_srv_time * 0.72) * 0.018, 0.0)
			sway_rot_deg = Vector3(sin(_srv_time * 0.48) * 0.22, cos(_srv_time * 0.37) * 0.28, 0.0)
		var shake_offset := Vector3.ZERO
		if _cam_shake > 0.0:
			_cam_shake = maxf(0.0, _cam_shake - dt * 1.6)
			shake_offset = Vector3(sin(_srv_time * 53.0) * _cam_shake * 0.14, cos(_srv_time * 61.0) * _cam_shake * 0.10, 0.0)
		_camera.position = _cam_base_pos + sway_offset + shake_offset
		_camera.look_at(_cam_look_at, Vector3.UP)
		if sway_rot_deg != Vector3.ZERO:
			_camera.rotation_degrees += sway_rot_deg

	# Transformer needle & gauge glow
	var v_ratio: float = clampf(_display_voltage / 100.0, 0.0, 1.15)
	if _needle_pivot != null and is_instance_valid(_needle_pivot):
		var jitter: float = 0.0
		if _event_id == int(C.EVENT_GLITCH_METER):
			jitter = sin(_srv_time * 47.0) * 0.45
		elif _display_voltage >= 50.0:
			var amp: float = 0.03 if _display_voltage < 70.0 else (0.07 if _display_voltage < 85.0 else 0.13)
			jitter = sin(_srv_time * 38.0) * amp
		var target_z: float = lerpf(0.95, -0.95, clampf(v_ratio, 0.0, 1.0)) + jitter
		_needle_pivot.rotation.z = target_z

	if _gauge_glow_mat != null:
		var gcol: Color = Color(0.25, 0.92, 0.45)
		if _display_voltage >= 85.0 or _event_id == int(C.EVENT_FALSE_ALARM):
			gcol = Color(1.0, 0.22, 0.18)
		elif _display_voltage >= 50.0:
			gcol = Color(1.0, 0.72, 0.18)
		_gauge_glow_mat.emission = gcol

	if _beacon_light != null and is_instance_valid(_beacon_light):
		var strobe: bool = (_event_id == int(C.EVENT_FALSE_ALARM)) or (_penalty_flash_timer > 0.0) or (_display_voltage >= 70.0 and _phase == PH_LIVE)
		if _event_id == int(C.EVENT_DOUBLE_OVERTIME):
			_beacon_light.light_color = Color(1.0, 0.85, 0.22)
			_beacon_light.light_energy = 2.8 + sin(_srv_time * 14.0) * 1.2
		elif strobe:
			_beacon_light.light_color = Color(1.0, 0.20, 0.15)
			_beacon_light.light_energy = 3.6 if (_penalty_flash_timer > 0.0 or sin(_srv_time * 18.0) > 0.0) else 0.3
		else:
			_beacon_light.light_color = Color(1.0, 0.58, 0.20)
			_beacon_light.light_energy = 0.4 + v_ratio * 0.8
	if _beacon_mat != null and _beacon_light != null:
		_beacon_mat.emission = _beacon_light.light_color
		_beacon_mat.emission_energy_multiplier = 0.6 + _beacon_light.light_energy * 0.8

	# Fluorescent flicker above 70% or during Glitching Meter
	for raw_fm in _fluorescent_mats:
		var fm: StandardMaterial3D = raw_fm as StandardMaterial3D
		if fm == null:
			continue
		if _event_id == int(C.EVENT_GLITCH_METER) or _display_voltage >= 70.0:
			var flk: float = 0.45 if sin(_srv_time * 43.0 + float(fm.get_instance_id() % 7)) < -0.55 else 1.5
			fm.emission_energy_multiplier = flk
		else:
			fm.emission_energy_multiplier = 1.35

	# Overhead CRT monitor
	if _crt_label != null and is_instance_valid(_crt_label):
		if _phase == PH_PREP:
			_crt_label.text = "R%d/%d" % [_round_idx + 1, int(C.TOTAL_ROUNDS)]
			_crt_label.modulate = Color(1.0, 0.82, 0.28)
		elif _event_id == int(C.EVENT_GLITCH_METER):
			_crt_label.text = "ERR // ???"
			_crt_label.modulate = Color(1.0, 0.36, 0.22)
		else:
			_crt_label.text = "%d%%" % int(roundf(_display_voltage))
			_crt_label.modulate = Color(1.0, 0.28, 0.22) if _display_voltage >= 70.0 else Color(0.38, 0.96, 0.54)
	if _crt_sub_label != null and is_instance_valid(_crt_sub_label):
		if _phase == PH_PREP:
			_crt_sub_label.text = _pick_loc("GET READY", "准备拉闸", "準備拉閘")
		elif _phase == PH_INTER_ROUND:
			_crt_sub_label.text = _pick_loc("ROUND %d END", "第 %d 回合结束", "第 %d 回合結束") % (_round_idx + 1)
		elif _phase == PH_ENDED:
			_crt_sub_label.text = _pick_loc("MATCH OVER", "比赛结束", "比賽結束")
		else:
			_crt_sub_label.text = "R%d/%d  %.1fs" % [_round_idx + 1, int(C.TOTAL_ROUNDS), _round_remaining]

	# Update per-chair visuals
	for raw_nid in _player_order:
		var nid: int = int(raw_nid)
		if not _chair_rigs.has(nid) or not _players.has(nid):
			continue
		var p: Dictionary = _players[nid] as Dictionary
		var rig: Dictionary = _chair_rigs[nid] as Dictionary

		var lever := rig.get("lever_pivot", null) as Node3D
		if lever != null and is_instance_valid(lever):
			var target_lx: float = 0.75 if bool(p["holding"]) else -0.25
			lever.rotation.x = lerpf(lever.rotation.x, target_lx, clampf(dt * 18.0, 0.0, 1.0))

		var visor := rig.get("visor_pivot", null) as Node3D
		if visor != null and is_instance_valid(visor):
			var target_vx: float = 0.0 if bool(p["bailed"]) else -1.05
			visor.rotation.x = lerpf(visor.rotation.x, target_vx, clampf(dt * 18.0, 0.0, 1.0))

		var fuse_mats: Array = rig.get("fuse_mats", []) as Array
		var lives: int = int(p["lives"])
		for fi in range(fuse_mats.size()):
			var fmat := fuse_mats[fi] as StandardMaterial3D
			if fmat != null:
				var lit: bool = fi < lives
				fmat.emission_enabled = lit
				fmat.albedo_color = Color(1.0, 0.78, 0.25) if lit else Color(0.16, 0.14, 0.14)

		var kick_mat := rig.get("kick_btn_mat", null) as StandardMaterial3D
		if kick_mat != null:
			var can_kick: bool = _phase == PH_LIVE and bool(p["alive"]) and bool(p["holding"]) and not bool(p["bailed"]) and not bool(p["kick_used"])
			kick_mat.emission_enabled = can_kick
			kick_mat.albedo_color = Color(1.0, 0.20, 0.16) if can_kick else Color(0.28, 0.16, 0.16)

		var lcd := rig.get("lcd_label", null) as Label3D
		if lcd != null and is_instance_valid(lcd):
			if not bool(p["alive"]):
				lcd.text = "OUT\n[%d]" % int(p["total_kpi"])
				lcd.modulate = Color(1.0, 0.28, 0.24)
			elif bool(p["bailed"]):
				lcd.text = "SAFE +%d\n[%d]" % [int(p["round_banked"]), int(p["total_kpi"])]
				lcd.modulate = Color(0.38, 0.95, 0.56)
			else:
				lcd.text = "%d\n[%d]" % [int(roundf(float(p["round_kpi"]))), int(p["total_kpi"])]
				lcd.modulate = Color(1.0, 0.86, 0.30) if float(p["surge_timer"]) > 0.0 else Color(0.95, 0.92, 0.84)

		var body_root := rig.get("body_root", null) as Node3D
		if body_root != null and is_instance_valid(body_root):
			if not bool(p["alive"]):
				body_root.rotation.z = 0.28
				body_root.position.y = -0.06
			elif (bool(p["holding"]) and _display_voltage >= 50.0) or float(p["slacker_jolt_timer"]) > 0.0:
				var tremble: float = 0.04 if _display_voltage < 80.0 else 0.075
				body_root.rotation.z = sin(_srv_time * 42.0 + float(nid)) * tremble
				body_root.position.y = absf(cos(_srv_time * 36.0)) * 0.025
			else:
				body_root.rotation.z = lerpf(body_root.rotation.z, 0.0, clampf(dt * 10.0, 0.0, 1.0))
				body_root.position.y = 0.0

		var overlay_mats: Array = rig.get("char_overlay_mats", []) as Array
		for raw_om in overlay_mats:
			var om := raw_om as StandardMaterial3D
			if om != null:
				if not bool(p["alive"]):
					om.albedo_color = Color(0.18, 0.16, 0.16)
				elif bool(p["charred"]):
					om.albedo_color = Color(0.38, 0.34, 0.32)

	# Parallel team arcs & FX pool tick
	_update_parallel_arcs_fx()
	if _fx_pool != null and _fx_pool.has_method("tick"):
		_fx_pool.tick(dt)

	# HUD updates
	if _hud != null:
		if _banner_timer <= 0.0 and _phase == PH_LIVE:
			_hud.set_banner("", Color.WHITE, false)
		if _players.has(_local_net_id):
			var lp: Dictionary = _players[_local_net_id] as Dictionary
			var head_pos: Vector3 = (lp["seat_pos"] as Vector3) + Vector3(0.0, 1.55, 0.0)
			_hud.set_you_marker(_camera, head_pos, _you_marker_timer > 0.0 and not bool(lp["is_ai"]))
			_hud.set_key_legend(bool(lp["holding"]), bool(lp["bailed"]), bool(lp["kick_used"]), bool(lp["alive"]))
		else:
			_hud.set_you_marker(_camera, Vector3.ZERO, false)
