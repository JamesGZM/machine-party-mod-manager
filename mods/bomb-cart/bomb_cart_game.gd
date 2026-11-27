extends Node3D

## ============================================================================
## Bomb Cart / 炸彈推車 — Server-Authoritative 2-4 Team Adaptive Rail Assault
## ============================================================================

signal round_finished(scores: Dictionary)

const CONFIG_RES := "res://mods_bomb_cart/config.gd"
const MESHES_RES := "res://mods_bomb_cart/arena_meshes.gd"
const TEAM_RES := "res://mods_bomb_cart/team_support.gd"
const FX_POOL_RES := "res://mods_bomb_cart/fx_pool.gd"
const HUD_RES := "res://mods_bomb_cart/hud_ui.gd"
const AI_RES := "res://mods_bomb_cart/ai_controller.gd"
const SELF_TEST_RES := "res://mods_bomb_cart/self_test.gd"

const PH_PREP := 0
const PH_LIVE := 1
const PH_ENDED := 2
const INPUT_SEND_INTERVAL := 0.033

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
var _cli_teams: int = 2
var _cli_per_team: int = 2
var _is_server_sim: bool = true
var _local_net_id: int = 1

var _phase: int = PH_PREP
var _match_phase: int = 1
var _srv_time: float = 0.0
var _prep_remaining: float = 0.0
var _elapsed_time: float = 0.0
var _time_remaining: float = 75.0
var _overtime: bool = false
var _last_countdown_sec: int = 4
var _you_marker_timer: float = 0.0
var _map_seed: int = 20261123
var _sync_accum: float = 0.0
var _fx_warmed_up: bool = false

var _active_team_ids: Array = [1, 2]
var _door_dirs: Dictionary = {}
var _door_alive: Dictionary = {}
var _team_breaches: Dictionary = {}
var _team_elim_order: Array = []
var _team_scores: Dictionary = {}
var _winner_team: int = 0
var _last_attacker_team: int = 0

var _cart_x: float = 0.0
var _cart_vel: float = 0.0
var _cart_pos: Vector2 = Vector2.ZERO
var _cart_vel_2d: Vector2 = Vector2.ZERO
var _cart_branch_team: int = 0
var _cart_branch_dist: float = 0.0
var _cart_angle: float = 0.0
var _cart_reset_pause: float = 0.0
var _cart_owner: int = 0
var _max_abs_push: float = 0.0
var _max_abs_push_team: int = 0

var _surge_team: int = 0
var _surge_target_team: int = 0
var _surge_timer: float = 0.0

var _pulse_active: bool = false
var _pulse_remaining: float = 0.0
var _pulse_cooldown: float = 8.0

var _valves: Array = []
var _valve_cycle_timer: float = 14.0
var _next_valve_idx: int = 0

var _players: Dictionary = {}
var _client_inputs: Dictionary = {}
var _flanker_assignments: Dictionary = {}
var _ai_state_cache: Dictionary = {}
var _ai_players_cache: Dictionary = {}
var _hud_state_cache: Dictionary = {}
var _team_alive_cache: Dictionary = {}

var _arena_root: Node3D = null
var _fx_root: Node3D = null
var _player_root: Node3D = null
var _shader_layer: CanvasLayer = null
var _camera: Camera3D = null
var _cam_base_pos: Vector3 = Vector3.ZERO
var _cam_shake: float = 0.0

var _cart_root: Node3D = null
var _cart_wheels: Array = []
var _cart_warhead_mat: StandardMaterial3D = null
var _push_aura_mesh: MeshInstance3D = null
var _push_aura_mat: StandardMaterial3D = null
var _pulse_ring_mesh: MeshInstance3D = null
var _pulse_ring_mat: StandardMaterial3D = null
var _valve_nodes: Dictionary = {}
var _door_lights: Dictionary = {}
var _door_nodes: Dictionary = {}
var _track_leds: Array = []
var _turntable_node: Node3D = null
var _monitor_timer_label: Label3D = null
var _monitor_phase_label: Label3D = null
var _mon_timer_text: String = ""
var _mon_timer_col: Color = Color(-1.0, -1.0, -1.0, -1.0)
var _mon_phase_text: String = ""
var _mon_phase_col: Color = Color(-1.0, -1.0, -1.0, -1.0)

var _prev_action_pressed: bool = false
var _input_send_accum: float = 0.0
var _pending_client_action: bool = false
var _pck_mounted: bool = false

var _sfx_push: AudioStreamPlayer = null
var _sfx_ding: AudioStreamPlayer = null
var _sfx_beep: AudioStreamPlayer = null
var _sfx_warn: AudioStreamPlayer = null
var _ambience: AudioStreamPlayer = null


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
	var m_cls = _load_script_res(MESHES_RES, "arena_meshes.gd")
	if m_cls != null:
		M = m_cls.new()
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
	var teams_specified: bool = false
	var per_team_specified: bool = false
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
		elif arg.begins_with("--teams="):
			_cli_teams = clampi(int(arg.substr("--teams=".length())), 2, 4)
			teams_specified = true
		elif arg.begins_with("--per-team="):
			_cli_per_team = clampi(int(arg.substr("--per-team=".length())), 1, 4)
			per_team_specified = true

	if smoke_test:
		_is_self_test = true
		_standalone_mode = true
		_is_server_sim = true
		_setup_match_local(0, 20261123, _build_standalone_roster(_cli_per_team, _cli_teams), true)
		for _i in range(180):
			step_headless(1.0 / 60.0)
		print("SMOKE_TEST_PASSED teams=%d per_team=%d" % [_cli_teams, _cli_per_team])
		get_tree().quit(0)
		return

	if not _screenshot_path.is_empty():
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var sc_teams: int = _cli_teams if teams_specified else 2
		var sc_per_team: int = _cli_per_team if per_team_specified else (3 if sc_teams == 2 else 2)
		var demo_roster: Array = _build_screenshot_roster(sc_per_team, sc_teams)
		_setup_match_local(0, 20261123, demo_roster, true)
		var st_cls2 = _load_script_res(SELF_TEST_RES, "self_test.gd")
		if st_cls2 != null and st_cls2.has_method("stage_screenshot_action"):
			_self_test_runner = st_cls2.new()
			_self_test_runner.stage_screenshot_action(self)
		else:
			_stage_default_screenshot()
		call_deferred("_capture_and_quit")
		return

	if get_parent() == get_tree().root:
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var roster: Array = _build_standalone_roster(_cli_per_team, _cli_teams)
		_setup_match_local(0, 20261123, roster, false)


func _stage_default_screenshot() -> void:
	_phase = PH_LIVE
	_match_phase = 2
	_prep_remaining = 0.0
	_elapsed_time = 46.0
	_time_remaining = 29.0
	_you_marker_timer = 0.0
	var is_multi: bool = _active_team_ids.size() >= 3

	if not is_multi:
		var left_tid: int = int(_active_team_ids[0])
		var right_tid: int = int(_active_team_ids[1])
		_cart_x = 1.5
		_cart_pos = Vector2(_cart_x, 0.0)
		_cart_vel = 2.6
		_cart_vel_2d = Vector2(2.6, 0.0)
		_cart_branch_team = right_tid
		_cart_branch_dist = absf(_cart_x)
		_cart_angle = 0.0
		_cart_owner = left_tid
		_surge_team = left_tid
		_surge_timer = 1.6
		_pulse_active = true
		_pulse_remaining = 0.65
		if _valves.size() >= 2:
			(_valves[0] as Dictionary)["active"] = true
			(_valves[1] as Dictionary)["active"] = false

		var left_spots: Array = [
			{"pos": Vector3(-1.55, 0.0, 1.50), "facing": Vector2(1.0, -0.25), "shove": true},
			{"pos": Vector3(-2.35, 0.0, -1.65), "facing": Vector2(1.0, 0.25), "shove": false},
			{"pos": Vector3(-0.15, 0.0, -5.65), "facing": Vector2(0.22, 1.0), "shove": false},
			{"pos": Vector3(-5.80, 0.0, 0.85), "facing": Vector2(1.0, -0.10), "shove": false},
		]
		var right_spots: Array = [
			{"pos": Vector3(4.25, 0.0, 1.50), "facing": Vector2(-1.0, -0.25), "shove": false},
			{"pos": Vector3(4.55, 0.0, -1.65), "facing": Vector2(-1.0, 0.25), "shove": false},
			{"pos": Vector3(2.10, 0.0, 4.55), "facing": Vector2(-0.35, -1.0), "shove": false},
			{"pos": Vector3(7.60, 0.0, -0.85), "facing": Vector2(-1.0, 0.12), "shove": false},
		]
		var l_idx: int = 0
		var r_idx: int = 0
		var nids: Array = _players.keys()
		nids.sort()
		for raw_nid in nids:
			var p: Dictionary = _players[raw_nid] as Dictionary
			var tid: int = int(p["team_id"])
			var spot: Dictionary = left_spots[l_idx % left_spots.size()] as Dictionary if tid == left_tid else right_spots[r_idx % right_spots.size()] as Dictionary
			if tid == left_tid:
				l_idx += 1
			else:
				r_idx += 1
			var sp: Vector3 = spot["pos"] as Vector3
			var res2: Vector2 = C.resolve_arena_obstacles(Vector2(sp.x, sp.z), float(C.PLAYER_RADIUS), _cart_pos, _cart_angle, _active_team_ids.size())
			p["pos"] = Vector3(res2.x, 0.0, res2.y)
			p["render_pos"] = p["pos"]
			p["facing"] = spot["facing"] as Vector2
			if bool(spot.get("shove", false)):
				p["shove_anim_timer"] = 0.16
		if _fx_pool != null:
			var col1: Color = C.TEAM_COLORS.get(left_tid, Color.WHITE) as Color
			_fx_pool.spawn_ram_sparks(Vector3(_cart_pos.x, 0.85, _cart_pos.y), col1)
			_fx_pool.spawn_steam_surge(Vector3(0.0, 0.35, -6.0), Vector3(_cart_pos.x, 0.65, _cart_pos.y), col1)
			_fx_pool.tick(0.10)
	else:
		# Multi-team active turntable/branch brawl staging (zero overlap, clear sightlines)
		var target_tid: int = int(_active_team_ids[1])
		var atk_tid: int = int(_active_team_ids[0])
		var bdir: Vector2 = _door_dirs.get(target_tid, Vector2(1.0, 0.0)) as Vector2
		_cart_branch_team = target_tid
		_cart_branch_dist = 3.8
		_cart_pos = bdir * _cart_branch_dist
		_cart_x = _cart_pos.x
		_cart_vel = 3.2
		_cart_vel_2d = bdir * _cart_vel
		_cart_angle = float(C.branch_yaw_from_dir(bdir))
		_cart_owner = atk_tid
		_surge_team = atk_tid
		_surge_target_team = target_tid
		_surge_timer = 1.5
		_pulse_active = true
		_pulse_remaining = 0.62
		for vi in range(_valves.size()):
			(_valves[vi] as Dictionary)["active"] = (vi == 0)
			(_valves[vi] as Dictionary)["charge"] = 0.55 if vi == 0 else 0.0

		var team_spots_4: Dictionary = {
			int(_active_team_ids[0]): [
				{"pos": Vector2(1.15, 1.45), "facing": Vector2(1.0, -0.35), "shove": true},
				{"pos": Vector2(-7.35, -7.15), "facing": Vector2(0.82, 0.57), "shove": false},
			],
			int(_active_team_ids[1]): [
				{"pos": Vector2(6.55, 1.50), "facing": Vector2(-1.0, -0.25), "shove": false},
				{"pos": Vector2(6.75, -1.75), "facing": Vector2(-1.0, 0.30), "shove": false},
			],
		}
		if _active_team_ids.size() >= 3:
			team_spots_4[int(_active_team_ids[2])] = [
				{"pos": Vector2(1.95, -4.15), "facing": Vector2(0.45, 0.89), "shove": false},
				{"pos": Vector2(3.85, -6.55), "facing": Vector2(-0.08, 0.99), "shove": false},
			]
		if _active_team_ids.size() >= 4:
			team_spots_4[int(_active_team_ids[3])] = [
				{"pos": Vector2(-1.65, 4.75), "facing": Vector2(0.72, -0.68), "shove": false},
				{"pos": Vector2(2.45, 7.25), "facing": Vector2(0.18, -0.98), "shove": false},
			]

		var per_team_idx: Dictionary = {}
		var nids: Array = _players.keys()
		nids.sort()
		for raw_nid in nids:
			var p: Dictionary = _players[raw_nid] as Dictionary
			var tid: int = int(p["team_id"])
			var idx_in_team: int = int(per_team_idx.get(tid, 0))
			per_team_idx[tid] = idx_in_team + 1
			var raw2: Vector2 = Vector2.ZERO
			var face2: Vector2 = Vector2(1.0, 0.0)
			if _active_team_ids.size() == 4 and team_spots_4.has(tid) and idx_in_team < (team_spots_4[tid] as Array).size():
				var st: Dictionary = (team_spots_4[tid] as Array)[idx_in_team] as Dictionary
				raw2 = st["pos"] as Vector2
				face2 = st["facing"] as Vector2
				if bool(st.get("shove", false)):
					p["shove_anim_timer"] = 0.16
			else:
				var tdir: Vector2 = _door_dirs.get(tid, Vector2(-1.0, 0.0)) as Vector2
				var perp := Vector2(-tdir.y, tdir.x)
				if tid == atk_tid:
					if idx_in_team == 0:
						raw2 = _cart_pos - bdir * 2.45 + Vector2(-bdir.y, bdir.x) * 1.15
						face2 = bdir
						p["shove_anim_timer"] = 0.16
					else:
						raw2 = ((_valves[0] as Dictionary)["pos"] as Vector2) + Vector2(0.6, 0.8)
						face2 = (_cart_pos - raw2).normalized()
				elif tid == target_tid:
					raw2 = _cart_pos + bdir * 2.65 + Vector2(-bdir.y, bdir.x) * (1.45 if idx_in_team == 0 else -1.55)
					face2 = -bdir
				else:
					raw2 = tdir * (3.4 if idx_in_team == 0 else 6.6) + perp * (1.4 if idx_in_team == 0 else -1.8)
					face2 = (_cart_pos - raw2).normalized()
			var res2: Vector2 = C.resolve_arena_obstacles(raw2, float(C.PLAYER_RADIUS), _cart_pos, _cart_angle, _active_team_ids.size())
			p["pos"] = Vector3(res2.x, 0.0, res2.y)
			p["render_pos"] = p["pos"]
			p["facing"] = face2

		if _fx_pool != null and not _valves.is_empty():
			var col_atk: Color = C.TEAM_COLORS.get(atk_tid, Color.WHITE) as Color
			var vp0: Vector2 = (_valves[0] as Dictionary)["pos"] as Vector2
			_fx_pool.spawn_ram_sparks(Vector3(_cart_pos.x, 0.85, _cart_pos.y), col_atk)
			_fx_pool.spawn_steam_surge(Vector3(vp0.x, 0.35, vp0.y), Vector3(_cart_pos.x, 0.65, _cart_pos.y), col_atk)
			_fx_pool.tick(0.10)

	if _cart_root != null and is_instance_valid(_cart_root):
		_cart_root.position = Vector3(_cart_pos.x, 0.0, _cart_pos.y)
		_cart_root.rotation.y = _cart_angle
	if _turntable_node != null and is_instance_valid(_turntable_node):
		_turntable_node.rotation.y = _cart_angle
	_animate_visuals(0.016)


func _mount_preview_pck() -> void:
	if _pck_mounted or _is_self_test:
		return
	_pck_mounted = true
	var pck_path: String = OS.get_environment("MP_PCK_PATH")
	if not pck_path.is_empty() and FileAccess.file_exists(pck_path):
		ProjectSettings.load_resource_pack(pck_path, false)


func _unhandled_input(event: InputEvent) -> void:
	if not _standalone_mode or _is_self_test or not _screenshot_path.is_empty():
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var kc: Key = (event as InputEventKey).keycode
		if kc == KEY_R:
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(_cli_per_team, _cli_teams), false)
		elif kc == KEY_F2:
			_cli_teams = 2
			_cli_per_team = 2
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(2, 2), false)
		elif kc == KEY_F3:
			_cli_teams = 3
			_cli_per_team = 2
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(2, 3), false)
		elif kc == KEY_F4:
			_cli_teams = 4
			_cli_per_team = 2
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(2, 4), false)
		elif kc == KEY_F5:
			_cli_teams = 2
			_cli_per_team = 4
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(4, 2), false)


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


func _build_standalone_roster(per_team: int, team_count: int = 2) -> Array:
	var roster: Array = []
	var idx: int = 0
	var count: int = clampi(team_count, 2, 4)
	for t in range(1, count + 1):
		for _m in range(per_team):
			var nid: int = idx + 1
			roster.append({
				"id": idx,
				"network_id": nid,
				"nickname": "Bot%d" % nid if idx > 0 else "Player1",
				"team_id": t,
				"is_ai": idx > 0,
				"customization": [],
			})
			idx += 1
	return roster


func _build_screenshot_roster(per_team: int, team_count: int = 2) -> Array:
	var names_by_team: Dictionary = {
		1: [
			_pick_loc("RailRed", "铁轨红哥", "鐵軌紅哥"),
			_pick_loc("SteamRed", "蒸汽小红", "蒸汽小紅"),
			_pick_loc("Furnace", "火炉阿红", "火爐阿紅"),
			_pick_loc("RedRam", "冲撞红星", "衝撞紅星"),
		],
		2: [
			_pick_loc("BrakeBlu", "刹车蓝宝", "煞車藍寶"),
			_pick_loc("GearKing", "齿轮蓝王", "齒輪藍王"),
			_pick_loc("Wrench", "扳手阿蓝", "扳手阿藍"),
			_pick_loc("BlueBolt", "冷钢蓝侠", "冷鋼藍俠"),
		],
		3: [
			_pick_loc("ValveGrn", "阀门绿豆", "閥門綠豆"),
			_pick_loc("Boiler", "锅炉绿匠", "鍋爐綠匠"),
			_pick_loc("Piston", "压缸小绿", "壓缸小綠"),
			_pick_loc("PipePro", "管线绿哥", "管線綠哥"),
		],
		4: [
			_pick_loc("FuseYel", "引信黄仔", "引信黃仔"),
			_pick_loc("Foundry", "重工阿黄", "重工阿黃"),
			_pick_loc("Rivet", "铆钉黄星", "鉚釘黃星"),
			_pick_loc("Sparky", "电弧小黄", "電弧小黃"),
		],
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
	var idx: int = 0
	var count: int = clampi(team_count, 2, 4)
	for t in range(1, count + 1):
		var t_names: Array = names_by_team.get(t, ["P1", "P2", "P3", "P4"]) as Array
		for m in range(per_team):
			var nid: int = idx + 1
			var nick: String = str(t_names[m % t_names.size()])
			var cust: Array = (cosmetics_pool[idx % cosmetics_pool.size()] as Array).duplicate()
			roster.append({
				"id": idx,
				"network_id": nid,
				"nickname": nick,
				"team_id": t,
				"is_ai": true,
				"customization": cust,
			})
			idx += 1
	return roster


## Public headless simulation hooks for self_test.gd
func setup_headless_match(roster: Array, all_ai: bool = false) -> void:
	_is_self_test = true
	_standalone_mode = true
	_is_server_sim = true
	_setup_match_local(0, 20261123, roster, all_ai)


func step_headless(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	_srv_time += dt
	if _phase == PH_PREP:
		_step_prep(dt)
	elif _phase == PH_LIVE:
		_step_simulation(dt)


func set_player_input(network_id: int, move_dir: Vector2, action_pressed: bool) -> void:
	var existing: Dictionary = _client_inputs.get(network_id, {"move": Vector2.ZERO, "action": false}) as Dictionary
	var kept_action: bool = bool(existing.get("action", false)) or action_pressed
	_client_inputs[network_id] = {
		"move": move_dir.limit_length(1.0),
		"action": kept_action,
	}


func get_state_snapshot() -> Dictionary:
	return _build_snapshot()


@rpc("authority", "call_local", "reliable")
func start_round(roster: Array) -> void:
	_load_helpers()
	_is_server_sim = multiplayer.is_server()
	_local_net_id = multiplayer.get_unique_id() if not _standalone_mode else 1
	var round_num: int = 0
	if not roster.is_empty() and roster[0] is Dictionary:
		round_num = int((roster[0] as Dictionary).get("round_number", 0))
	_setup_match_local(round_num, 20261123 + round_num * 97, roster, false)


func _clear_scene_children() -> void:
	if _fx_pool != null and _fx_pool.has_method("clear"):
		_fx_pool.clear()
	for child_node in [_arena_root, _fx_root, _player_root]:
		if child_node != null and is_instance_valid(child_node):
			child_node.queue_free()
	_arena_root = null
	_fx_root = null
	_player_root = null
	_cart_root = null
	_cart_wheels.clear()
	_cart_warhead_mat = null
	_push_aura_mesh = null
	_push_aura_mat = null
	_pulse_ring_mesh = null
	_pulse_ring_mat = null
	_valve_nodes.clear()
	_door_lights.clear()
	_door_nodes.clear()
	_track_leds.clear()
	_turntable_node = null
	_monitor_timer_label = null
	_monitor_phase_label = null
	_mon_timer_text = ""
	_mon_timer_col = Color(-1.0, -1.0, -1.0, -1.0)
	_mon_phase_text = ""
	_mon_phase_col = Color(-1.0, -1.0, -1.0, -1.0)


func _detect_active_team_ids(roster: Array) -> Array:
	var seen: Dictionary = {}
	for raw_r in roster:
		if not (raw_r is Dictionary):
			continue
		var r: Dictionary = raw_r as Dictionary
		var nid: int = int(r.get("network_id", 0))
		var tid: int = int(r.get("team_id", 0))
		if tid <= 0 and _team != null:
			tid = int(_team.player_team(nid))
		if tid > 0:
			seen[tid] = true
	var ids: Array = seen.keys()
	ids.sort()
	if ids.size() < 2:
		return [1, 2]
	if ids.size() > 4:
		ids = ids.slice(0, 4)
	return ids


func _setup_match_local(round_idx: int, seed_val: int, roster: Array, all_ai: bool = false) -> void:
	_load_helpers()
	_clear_scene_children()
	_map_seed = seed_val + round_idx * 31

	if _team != null:
		_team.begin_match(self, roster)

	_active_team_ids = _detect_active_team_ids(roster)
	var team_count: int = _active_team_ids.size()
	_door_dirs = C.door_directions(_active_team_ids) as Dictionary
	_door_alive.clear()
	_team_breaches.clear()
	_team_scores.clear()
	_team_elim_order.clear()
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		_door_alive[tid] = true
		_team_breaches[tid] = 0
		_team_scores[tid] = 0

	_phase = PH_PREP
	_match_phase = 1
	_srv_time = 0.0
	_prep_remaining = float(C.PREP_DURATION)
	_elapsed_time = 0.0
	_time_remaining = float(C.MATCH_DURATION)
	_overtime = false
	_last_countdown_sec = 4
	_you_marker_timer = float(C.PREP_DURATION) + 2.5
	_sync_accum = 0.0
	_fx_warmed_up = false

	_winner_team = 0
	_last_attacker_team = 0

	_cart_x = 0.0
	_cart_vel = 0.0
	_cart_pos = Vector2.ZERO
	_cart_vel_2d = Vector2.ZERO
	_cart_branch_team = 0
	_cart_branch_dist = 0.0
	_cart_angle = 0.0
	_cart_reset_pause = 0.0
	_cart_owner = 0
	_max_abs_push = 0.0
	_max_abs_push_team = 0

	_surge_team = 0
	_surge_target_team = 0
	_surge_timer = 0.0

	_pulse_active = false
	_pulse_remaining = 0.0
	_pulse_cooldown = float(C.PULSE_INTERVAL)

	_valves.clear()
	var v_positions: Array = C.valve_positions_for_teams(team_count)
	for raw_vp in v_positions:
		_valves.append({
			"pos": raw_vp as Vector2,
			"active": false,
			"charge": 0.0,
			"charging_team": 0,
		})
	_valve_cycle_timer = float(C.VALVE_INTERVAL_P1)
	_next_valve_idx = 0

	_players.clear()
	_client_inputs.clear()
	_flanker_assignments.clear()
	_cam_shake = 0.0

	_arena_root = Node3D.new()
	_arena_root.name = "ArenaRoot"
	add_child(_arena_root)
	_fx_root = Node3D.new()
	_fx_root.name = "FxRoot"
	add_child(_fx_root)
	_player_root = Node3D.new()
	_player_root.name = "PlayerRoot"
	add_child(_player_root)

	if not _is_self_test:
		_ensure_environment_and_camera(team_count)
		if M != null and M.has_method("ensure_game_pck_mounted"):
			M.ensure_game_pck_mounted()
		_setup_post_fx()
		_init_audio()
		if M != null:
			var arena_info: Dictionary = M.build_arena(_arena_root, C, _active_team_ids)
			_cart_root = arena_info.get("cart_root", null) as Node3D
			_cart_wheels = arena_info.get("cart_wheels", []) as Array
			_cart_warhead_mat = arena_info.get("cart_warhead_mat", null) as StandardMaterial3D
			_push_aura_mesh = arena_info.get("push_aura_mesh", null) as MeshInstance3D
			_push_aura_mat = arena_info.get("push_aura_mat", null) as StandardMaterial3D
			_pulse_ring_mesh = arena_info.get("pulse_ring_mesh", null) as MeshInstance3D
			_pulse_ring_mat = arena_info.get("pulse_ring_mat", null) as StandardMaterial3D
			_valve_nodes = arena_info.get("valve_nodes", {}) as Dictionary
			_door_lights = arena_info.get("door_lights", {}) as Dictionary
			_door_nodes = arena_info.get("door_nodes", {}) as Dictionary
			_track_leds = arena_info.get("track_leds", []) as Array
			_turntable_node = arena_info.get("turntable_node", null) as Node3D
			_monitor_timer_label = arena_info.get("monitor_timer_label", null) as Label3D
			_monitor_phase_label = arena_info.get("monitor_phase_label", null) as Label3D
		if _fx_pool != null:
			_fx_pool.setup(_fx_root)
		if _hud != null:
			_hud.setup(self, Callable(self, "_pick_loc"), _team)

	_spawn_players(roster, all_ai)


func _ensure_environment_and_camera(team_count: int = 2) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.name = "ArenaCamera"
		_camera.current = true
		add_child(_camera)

	if team_count >= 3:
		_camera.fov = 45.0
		_camera.position = Vector3(0.0, 27.2, 27.8)
		_camera.look_at(Vector3(0.0, 0.4, 0.9), Vector3.UP)
	else:
		_camera.fov = 43.0
		_camera.position = Vector3(0.0, 20.2, 20.2)
		_camera.look_at(Vector3(0.0, 0.5, 0.2), Vector3.UP)
	_cam_base_pos = _camera.position

	# Authentic Machine Party warm heavy-foundry / steel-railyard atmosphere
	if get_node_or_null("WorldEnv") == null:
		var env_node := WorldEnvironment.new()
		env_node.name = "WorldEnv"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.025, 0.022, 0.022)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.38, 0.36, 0.40)
		env.ambient_light_energy = 0.26
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.01
		env.adjustment_contrast = 1.18
		env.adjustment_saturation = 0.74
		env.glow_enabled = true
		env.glow_intensity = 0.36
		env.glow_bloom = 0.12
		env_node.environment = env
		add_child(env_node)

	if get_node_or_null("SunLight") == null:
		var sun := DirectionalLight3D.new()
		sun.name = "SunLight"
		sun.rotation_degrees = Vector3(-50.0, 28.0, 0.0)
		sun.light_color = Color(0.98, 0.88, 0.74)
		sun.light_energy = 1.50
		sun.shadow_enabled = true
		sun.shadow_bias = 0.05
		sun.shadow_blur = 1.2
		add_child(sun)

	if get_node_or_null("FillLight") == null:
		var fill := DirectionalLight3D.new()
		fill.name = "FillLight"
		fill.rotation_degrees = Vector3(-34.0, -148.0, 0.0)
		fill.light_color = Color(0.56, 0.66, 0.82)
		fill.light_energy = 0.12
		add_child(fill)


func _setup_post_fx() -> void:
	if _shader_layer != null and is_instance_valid(_shader_layer):
		return
	if M == null or not M.has_method("load_optional"):
		return
	var post_shader = M.load_optional("res://shaders/posterization.gdshader")
	var vig_shader = M.load_optional("res://shaders/vignette.gdshader")
	if not (post_shader is Shader or vig_shader is Shader):
		return

	_shader_layer = CanvasLayer.new()
	_shader_layer.name = "PostFXLayer"
	_shader_layer.layer = 1
	add_child(_shader_layer)

	var fx_root := Control.new()
	fx_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_layer.add_child(fx_root)

	if vig_shader is Shader:
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
		vm.shader = vig_shader as Shader
		vm.set_shader_parameter("radius", 0.91)
		vm.set_shader_parameter("softness", 0.38)
		vm.set_shader_parameter("intensity", 1.88)
		vm.set_shader_parameter("contrast", 1.55)
		vm.set_shader_parameter("vignette_color", Color(0.0, 0.0, 0.0, 1.0))
		vig_rect.material = vm
		vig_holder.add_child(vig_rect)

	if post_shader is Shader:
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
		pm.shader = post_shader as Shader
		pm.set_shader_parameter("SCREEN_WIDTH", 1920.0)
		pm.set_shader_parameter("RED_COMPONENT", 8.0)
		pm.set_shader_parameter("GREEN_COMPONENT", 8.0)
		pm.set_shader_parameter("BLUE_COMPONENT", 8.0)
		post_rect.material = pm
		post_holder.add_child(post_rect)


func _make_audio_player(res_path: String, vol_db: float) -> AudioStreamPlayer:
	if not ResourceLoader.exists(res_path):
		return null
	var stream = ResourceLoader.load(res_path)
	if not (stream is AudioStream):
		return null
	var ap := AudioStreamPlayer.new()
	ap.stream = stream as AudioStream
	ap.volume_db = vol_db
	add_child(ap)
	return ap


func _init_audio() -> void:
	if not _screenshot_path.is_empty():
		return
	if _sfx_push == null:
		_sfx_push = _make_audio_player("res://audio/unique/disco dodge/dd shove.ogg", -4.0)
	if _sfx_ding == null:
		_sfx_ding = _make_audio_player("res://audio/sfx/airplane ding.ogg", -2.0)
	if _sfx_beep == null:
		_sfx_beep = _make_audio_player("res://audio/sfx/ekg_beep.ogg", -5.0)
	if _sfx_warn == null:
		_sfx_warn = _make_audio_player("res://audio/unique/exploding collar race/mine_detected.ogg", -5.0)
	if _ambience == null:
		_ambience = _make_audio_player("res://audio/unique/dvd roomba/dvd roomba ambience.ogg", -16.0)
		if _ambience != null and not _ambience.playing:
			_ambience.play()


func _spawn_players(roster: Array, all_ai: bool) -> void:
	var team_members: Dictionary = {}
	for raw_tid in _active_team_ids:
		team_members[int(raw_tid)] = []

	var fallback_idx: int = 0
	for raw_r in roster:
		if not (raw_r is Dictionary):
			continue
		var r: Dictionary = raw_r as Dictionary
		var nid: int = int(r.get("network_id", 0))
		var tid: int = int(r.get("team_id", 0))
		if tid <= 0 and _team != null:
			tid = int(_team.player_team(nid))
		if not team_members.has(tid):
			tid = int(_active_team_ids[fallback_idx % _active_team_ids.size()])
			fallback_idx += 1
		(team_members[tid] as Array).append(r)

	var team_count: int = _active_team_ids.size()
	var is_multi: bool = team_count >= 3
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		var members: Array = team_members[tid] as Array
		var ddir: Vector2 = _door_dirs.get(tid, Vector2(-1.0, 0.0)) as Vector2
		var facing: Vector2 = -ddir
		var perp := Vector2(-ddir.y, ddir.x)
		var spawn_dist: float = 7.6 if is_multi else 8.5
		var spacing: float = 1.45 if is_multi else 1.65

		for m_idx in range(members.size()):
			var r: Dictionary = members[m_idx] as Dictionary
			var nid: int = int(r.get("network_id", 0))
			var side_offset: float = (float(m_idx) - float(members.size() - 1) * 0.5) * spacing
			var raw_spawn2: Vector2 = ddir * spawn_dist + perp * side_offset
			var spawn2: Vector2 = C.resolve_arena_obstacles(raw_spawn2, float(C.PLAYER_RADIUS), _cart_pos, _cart_angle, team_count)
			var spawn3 := Vector3(spawn2.x, 0.0, spawn2.y)
			var is_ai: bool = all_ai or bool(r.get("is_ai", nid < 0))
			var nick: String = str(r.get("nickname", "P%d" % nid))
			var cust: Array = r.get("customization", []) as Array
			var pnode: Node3D = null
			var rig: Node3D = null
			var body_mat: StandardMaterial3D = null
			var ring_mat: StandardMaterial3D = null
			var anim_player: AnimationPlayer = null
			if not _is_self_test and M != null and _player_root != null:
				var is_local: bool = (not is_ai) and (nid == _local_net_id)
				var vis: Dictionary = M.build_player_mesh(tid, is_local, nick, C, nid, cust)
				pnode = vis.get("root", null) as Node3D
				rig = vis.get("rig", null) as Node3D
				body_mat = vis.get("body_mat", null) as StandardMaterial3D
				ring_mat = vis.get("ring_mat", null) as StandardMaterial3D
				anim_player = vis.get("anim_player", null) as AnimationPlayer
				var lbl := vis.get("label", null) as Label3D
				if lbl != null and _team != null:
					_team.apply_nameplate(lbl, nick, tid, 10)
				if pnode != null:
					pnode.position = spawn3
					_player_root.add_child(pnode)
					if is_local:
						pnode.set_meta(&"mpm_local_player", true)

			_players[nid] = {
				"network_id": nid,
				"nickname": nick,
				"team_id": tid,
				"is_ai": is_ai,
				"connected": true,
				"alive": true,
				"pos": spawn3,
				"render_pos": spawn3,
				"facing": facing,
				"stun_timer": 0.0,
				"action_cd": 0.0,
				"shove_anim_timer": 0.0,
				"knockback_vel": Vector2.ZERO,
				"node": pnode,
				"rig": rig,
				"body_mat": body_mat,
				"ring_mat": ring_mat,
				"anim_player": anim_player,
			}


func _process(delta: float) -> void:
	if _is_self_test or not _screenshot_path.is_empty():
		return
	if not _fx_warmed_up and _fx_pool != null and _camera != null:
		_fx_warmed_up = true
		_fx_pool.warmup_in_frustum(_camera)

	var dt: float = minf(delta, 0.05)
	if _you_marker_timer > 0.0:
		_you_marker_timer = maxf(0.0, _you_marker_timer - dt)

	if _is_server_sim:
		_srv_time += dt
		if _phase == PH_PREP:
			_step_prep(dt)
		elif _phase == PH_LIVE:
			_step_simulation(dt)
		if not _standalone_mode and multiplayer.has_multiplayer_peer():
			_sync_accum += dt
			if _sync_accum >= float(C.SNAPSHOT_INTERVAL):
				_sync_accum = 0.0
				_rpc_state_snapshot.rpc(_build_snapshot())
	else:
		_srv_time += dt
		_send_local_input(dt)

	_animate_visuals(dt)


func _send_local_input(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	var inp: Dictionary = _read_local_input()
	if bool(inp["action"]):
		_pending_client_action = true
		_rpc_client_action.rpc_id(1)
	_input_send_accum += delta
	if _input_send_accum >= INPUT_SEND_INTERVAL or _pending_client_action:
		_input_send_accum = 0.0
		_rpc_client_input.rpc_id(1, inp["move"], false)
		_pending_client_action = false


@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_action() -> void:
	if not _is_server_sim:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		sender = 1
	var existing: Dictionary = _client_inputs.get(sender, {"move": Vector2.ZERO, "action": false}) as Dictionary
	_client_inputs[sender] = {
		"move": existing.get("move", Vector2.ZERO),
		"action": true,
	}


func _exit_tree() -> void:
	if _ambience != null and is_instance_valid(_ambience):
		_ambience.stop()


func _read_local_input() -> Dictionary:
	var mv := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		mv.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		mv.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		mv.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		mv.y += 1.0
	if mv.length() > 1.0:
		mv = mv.normalized()
	var down: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept")
	var pressed: bool = down and not _prev_action_pressed
	_prev_action_pressed = down
	return {"move": mv, "action": pressed}


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_client_input(move_dir: Vector2, action_pressed: bool) -> void:
	if not _is_server_sim:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		sender = 1
	var existing: Dictionary = _client_inputs.get(sender, {"move": Vector2.ZERO, "action": false}) as Dictionary
	var kept_action: bool = bool(existing.get("action", false)) or action_pressed
	_client_inputs[sender] = {
		"move": move_dir.limit_length(1.0),
		"action": kept_action,
	}


func _team_display_name(tid: int) -> String:
	match tid:
		1: return _pick_loc("RED", "红队", "紅隊")
		2: return _pick_loc("BLUE", "蓝队", "藍隊")
		3: return _pick_loc("GREEN", "绿队", "綠隊")
		4: return _pick_loc("YELLOW", "黄队", "黃隊")
		_: return "TEAM %d" % tid


func _emit_banner(key: String, arg: int = 0) -> void:
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_banner_event.rpc(key, arg)
	else:
		_rpc_banner_event(key, arg)


@rpc("authority", "call_local", "reliable")
func _rpc_banner_event(key: String, arg: int = 0) -> void:
	if _is_self_test:
		return
	match key:
		"prep":
			if _hud != null:
				_hud.show_countdown(arg)
			if arg > 0 and _sfx_beep != null:
				_sfx_beep.play()
			elif arg <= 0 and _sfx_ding != null:
				_sfx_ding.play()
		"phase2":
			if _hud != null:
				_hud.show_banner(_pick_loc("FUSE IGNITED! 1.35x SPEED & SHOCKWAVE", "引信点燃! 1.35x 推速与震荡脉冲", "引信點燃! 1.35x 推速與震盪脈衝"), Color(1.0, 0.68, 0.18), 2.4)
			if _sfx_warn != null:
				_sfx_warn.play()
		"phase3":
			if _hud != null:
				_hud.show_banner(_pick_loc("CRITICAL OVERLOAD! ALL VALVES ACTIVE", "临界过载! 全部蒸汽阀激活", "臨界過載! 全部蒸氣閥激活"), Color(1.0, 0.28, 0.18), 2.5)
			if _sfx_warn != null:
				_sfx_warn.play()
		"overtime":
			if _hud != null:
				var ot_msg: String = _pick_loc("SUDDEN DEATH! PUSH ONTO RIVAL RAIL TO WIN", "突然死亡加时! 推入敌方轨道即胜", "突然死亡加時! 推入敵方軌道即勝") if _active_team_ids.size() >= 3 else _pick_loc("SUDDEN DEATH! PUSH +/- 0.6m TO WIN", "突然死亡加时! 推进 +/- 0.6m 即胜", "突然死亡加時! 推進 +/- 0.6m 即勝")
				_hud.show_banner(ot_msg, Color(1.0, 0.84, 0.22), 2.5)
			if _sfx_warn != null:
				_sfx_warn.play()
		"surge":
			if _hud != null:
				var tcol: Color = C.TEAM_COLORS.get(arg, Color.WHITE) as Color
				var msg: String = "%s %s" % [_team_display_name(arg), _pick_loc("ROCKET SURGE!", "火箭助推!", "火箭助推!")]
				_hud.show_banner(msg, tcol, 2.0)
			if _sfx_ding != null:
				_sfx_ding.play()
		"breach_elim":
			if _hud != null:
				var tcol: Color = C.TEAM_COLORS.get(arg, Color.WHITE) as Color
				var msg: String = "%s %s" % [_team_display_name(arg), _pick_loc("BLAST DOOR BREACHED!", "防爆门已炸毁!", "防爆門已炸毀!")]
				_hud.show_banner(msg, tcol, 2.2)
			if _sfx_warn != null:
				_sfx_warn.play()
		"win":
			if _hud != null and _team != null:
				_hud.show_banner(_team.team_win_banner(arg), C.TEAM_COLORS.get(arg, Color.WHITE) as Color, 4.0)
			if _sfx_ding != null:
				_sfx_ding.play()
		"draw":
			if _hud != null:
				_hud.show_banner(_pick_loc("DRAW!", "平局!", "平手!"), Color(0.92, 0.88, 0.78), 4.0)
			if _sfx_ding != null:
				_sfx_ding.play()


func _emit_fx(kind: String, pos: Vector3, aux: Vector3, team_id: int) -> void:
	if _is_self_test:
		return
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_fx_event.rpc(kind, pos, aux, team_id)
	else:
		_rpc_fx_event(kind, pos, aux, team_id)


@rpc("authority", "call_local", "reliable")
func _rpc_fx_event(kind: String, pos: Vector3, aux: Vector3, team_id: int) -> void:
	if _is_self_test:
		return
	var col: Color = C.TEAM_COLORS.get(team_id, Color.WHITE) as Color
	if _fx_pool != null:
		match kind:
			"shove":
				_fx_pool.spawn_shove_burst(pos, col)
			"ram":
				_fx_pool.spawn_ram_sparks(pos, col)
			"surge":
				_fx_pool.spawn_steam_surge(pos, aux, col)
			"shockwave":
				_fx_pool.spawn_shockwave(pos)
			"breach":
				_fx_pool.spawn_door_explosion(pos, col)
	if kind == "shove" or kind == "ram":
		if _sfx_push != null:
			_sfx_push.play()
		_cam_shake = maxf(_cam_shake, 0.14)
	elif kind == "shockwave" or kind == "breach":
		if _sfx_warn != null:
			_sfx_warn.play()
		_cam_shake = maxf(_cam_shake, 0.30)


func _step_prep(delta: float) -> void:
	_prep_remaining = maxf(0.0, _prep_remaining - delta)
	var sec: int = ceili(_prep_remaining)
	if sec != _last_countdown_sec:
		_last_countdown_sec = sec
		_emit_banner("prep", sec)
	if _prep_remaining <= 0.0:
		_phase = PH_LIVE


func _intact_team_ids() -> Array:
	var out: Array = []
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		if bool(_door_alive.get(tid, false)) and _active_members_in_team(tid) > 0:
			out.append(tid)
	return out


func _pick_rival_branch(from_team: int, prefer_dir: Vector2) -> int:
	var best_tid: int = 0
	var best_dot: float = -999.0
	var pdir: Vector2 = prefer_dir.normalized() if prefer_dir.length_squared() > 0.001 else Vector2(1.0, 0.0)
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		if tid == from_team or not bool(_door_alive.get(tid, false)):
			continue
		var ddir: Vector2 = _door_dirs.get(tid, Vector2.RIGHT) as Vector2
		var sc: float = ddir.dot(pdir)
		if sc > best_dot:
			best_dot = sc
			best_tid = tid
	return best_tid


func _breach_door_multi(breached_tid: int) -> void:
	if not bool(_door_alive.get(breached_tid, false)):
		return
	var bdir: Vector2 = _door_dirs.get(breached_tid, Vector2(1.0, 0.0)) as Vector2
	var door_pos2: Vector2 = bdir * float(C.TRACK_LEN_MULTI)

	# Credit attacking team
	var attacker: int = _last_attacker_team
	if attacker <= 0 or attacker == breached_tid or not bool(_door_alive.get(attacker, false)):
		attacker = _surge_team if (_surge_team > 0 and _surge_team != breached_tid and bool(_door_alive.get(_surge_team, false))) else 0
	if attacker <= 0:
		for raw_p in _players.values():
			var p: Dictionary = raw_p as Dictionary
			var ptid: int = int(p["team_id"])
			if ptid != breached_tid and bool(p["alive"]) and bool(p["connected"]) and bool(_door_alive.get(ptid, false)):
				var p3: Vector3 = p["pos"] as Vector3
				if Vector2(p3.x, p3.z).distance_to(_cart_pos) <= float(C.PUSH_AURA_RADIUS) + 1.5:
					attacker = ptid
					break
	if attacker > 0:
		_team_breaches[attacker] = int(_team_breaches.get(attacker, 0)) + 1

	_emit_fx("breach", Vector3(door_pos2.x, 1.0, door_pos2.y), Vector3.ZERO, attacker if attacker > 0 else breached_tid)

	# Eliminate breached team immediately (updates team-party top-right HUD live!)
	_door_alive[breached_tid] = false
	_team_elim_order.append(breached_tid)
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if int(p["team_id"]) == breached_tid:
			p["alive"] = false
			p["stun_timer"] = 0.0
			p["knockback_vel"] = Vector2.ZERO

	var intact: Array = _intact_team_ids()
	if intact.size() <= 1:
		var winner: int = int(intact[0]) if not intact.is_empty() else (attacker if attacker > 0 else 0)
		_finish_match(winner)
		return

	# >= 2 intact teams remain: reset cart cleanly to central turntable with brief pause
	_cart_pos = Vector2.ZERO
	_cart_x = 0.0
	_cart_vel = 0.0
	_cart_vel_2d = Vector2.ZERO
	_cart_branch_team = 0
	_cart_branch_dist = 0.0
	_cart_owner = 0
	_surge_team = 0
	_surge_target_team = 0
	_surge_timer = 0.0
	_cart_reset_pause = float(C.BREACH_RESET_PAUSE)
	_emit_banner("breach_elim", breached_tid)


func _resolve_multi_timeout(force_finish: bool) -> bool:
	var intact: Array = _intact_team_ids()
	if intact.size() <= 1:
		_finish_match(int(intact[0]) if not intact.is_empty() else 0)
		return true

	# Score each intact team: non-threatened beats threatened, more breaches beats fewer
	var threatened_tid: int = _cart_branch_team if (_cart_branch_team > 0 and _cart_branch_dist > float(C.HUB_RADIUS) and bool(_door_alive.get(_cart_branch_team, false))) else 0
	var ranked: Array = []
	for raw_tid in intact:
		var tid: int = int(raw_tid)
		var safe_bonus: int = 0 if tid == threatened_tid else 1
		var breaches: int = int(_team_breaches.get(tid, 0))
		ranked.append({"tid": tid, "safe": safe_bonus, "breaches": breaches})

	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["safe"]) != int(b["safe"]):
			return int(a["safe"]) > int(b["safe"])
		if int(a["breaches"]) != int(b["breaches"]):
			return int(a["breaches"]) > int(b["breaches"])
		return int(a["tid"]) < int(b["tid"])
	)

	var top0: Dictionary = ranked[0] as Dictionary
	var top1: Dictionary = ranked[1] as Dictionary
	var tied_at_top: bool = (int(top0["safe"]) == int(top1["safe"]) and int(top0["breaches"]) == int(top1["breaches"]))

	# If cart is dead center with tied intact teams and not yet in overtime -> Sudden Death!
	if not force_finish and tied_at_top and threatened_tid == 0:
		_overtime = true
		_time_remaining = float(C.OVERTIME_DURATION)
		_emit_banner("overtime", 0)
		return false

	# Decide final ranked scores for all teams
	var winner_tid: int = 0 if (tied_at_top and _last_attacker_team <= 0) else (int(top0["tid"]) if not tied_at_top else (_last_attacker_team if intact.has(_last_attacker_team) else int(top0["tid"])))
	_finish_match_ranked(winner_tid, ranked, threatened_tid)
	return true


func _step_simulation(delta: float) -> void:
	if not _overtime:
		_elapsed_time += delta
		_time_remaining = maxf(0.0, float(C.MATCH_DURATION) - _elapsed_time)
	else:
		_time_remaining = maxf(0.0, _time_remaining - delta)

	_step_phase_events(delta)
	_step_valves(delta)
	_step_players(delta)
	_step_cart(delta)

	var is_multi: bool = _active_team_ids.size() >= 3
	if not is_multi:
		var left_tid: int = int(_active_team_ids[0])
		var right_tid: int = int(_active_team_ids[1])
		if absf(_cart_x) > _max_abs_push:
			_max_abs_push = absf(_cart_x)
			_max_abs_push_team = left_tid if _cart_x > 0.0 else right_tid

		# Check Blast Door Breach (Instant KO)
		if _cart_x >= float(C.TRACK_HALF_LEN):
			_emit_fx("breach", Vector3(float(C.TRACK_HALF_LEN), 1.0, 0.0), Vector3.ZERO, left_tid)
			_finish_match(left_tid)
			return
		if _cart_x <= -float(C.TRACK_HALF_LEN):
			_emit_fx("breach", Vector3(-float(C.TRACK_HALF_LEN), 1.0, 0.0), Vector3.ZERO, right_tid)
			_finish_match(right_tid)
			return

		# Check disconnect fallback
		if _active_team_count() <= 1:
			_finish_match(_first_active_team())
			return

		# Check Overtime win or expiration
		if _overtime:
			if _cart_x >= float(C.OVERTIME_WIN_X):
				_finish_match(left_tid)
				return
			if _cart_x <= -float(C.OVERTIME_WIN_X):
				_finish_match(right_tid)
				return
			if _time_remaining <= 0.0:
				if _cart_x > float(C.TIE_DEADZONE_X):
					_finish_match(left_tid)
				elif _cart_x < -float(C.TIE_DEADZONE_X):
					_finish_match(right_tid)
				else:
					_finish_match(_max_abs_push_team)
				return
		elif _time_remaining <= 0.0:
			if _cart_x > float(C.TIE_DEADZONE_X):
				_finish_match(left_tid)
				return
			if _cart_x < -float(C.TIE_DEADZONE_X):
				_finish_match(right_tid)
				return
			_overtime = true
			_time_remaining = float(C.OVERTIME_DURATION)
			_emit_banner("overtime", 0)
	else:
		# 3-4 Team Door Breach Elimination
		if _cart_branch_team > 0 and bool(_door_alive.get(_cart_branch_team, false)) and _cart_branch_dist >= float(C.TRACK_LEN_MULTI):
			_breach_door_multi(_cart_branch_team)
			if _phase == PH_ENDED:
				return

		# Disconnect / Last-Door-Standing fallback
		var intact: Array = _intact_team_ids()
		if intact.size() <= 1:
			_finish_match(int(intact[0]) if not intact.is_empty() else 0)
			return

		# Overtime or Timeout resolution
		if _overtime:
			if _cart_branch_team > 0 and bool(_door_alive.get(_cart_branch_team, false)) and _cart_branch_dist >= float(C.OVERTIME_WIN_MULTI):
				var ot_winner: int = _last_attacker_team
				if ot_winner <= 0 or ot_winner == _cart_branch_team or not intact.has(ot_winner):
					for raw_t in intact:
						if int(raw_t) != _cart_branch_team:
							ot_winner = int(raw_t)
							break
				_finish_match(ot_winner)
				return
			if _time_remaining <= 0.0:
				_resolve_multi_timeout(true)
				return
		elif _time_remaining <= 0.0:
			_resolve_multi_timeout(false)


func _step_phase_events(delta: float) -> void:
	if _match_phase < 2 and _elapsed_time >= float(C.PHASE2_START):
		_match_phase = 2
		_pulse_cooldown = 2.0
		_emit_banner("phase2", 0)

	if _match_phase < 3 and _elapsed_time >= float(C.PHASE3_START):
		_match_phase = 3
		_emit_banner("phase3", 0)
		for v_raw in _valves:
			var v: Dictionary = v_raw as Dictionary
			v["active"] = true
			v["charge"] = 0.0
		_valve_cycle_timer = float(C.VALVE_INTERVAL_P3)

	if _surge_timer > 0.0:
		_surge_timer = maxf(0.0, _surge_timer - delta)
		if _surge_timer <= 0.0:
			_surge_team = 0
			_surge_target_team = 0

	if _match_phase >= 2:
		if _pulse_active:
			_pulse_remaining -= delta
			if _pulse_remaining <= 0.0:
				_detonate_shockwave()
				_pulse_active = false
				_pulse_remaining = 0.0
				_pulse_cooldown = float(C.PULSE_INTERVAL)
		else:
			_pulse_cooldown -= delta
			if _pulse_cooldown <= 0.0:
				_pulse_active = true
				_pulse_remaining = float(C.PULSE_WARN_TIME)


func _detonate_shockwave() -> void:
	var cart_pos2: Vector2 = _cart_pos
	var pulse_r: float = float(C.PULSE_RADIUS)
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if not bool(p["alive"]) or not bool(p["connected"]):
			continue
		var p3: Vector3 = p["pos"] as Vector3
		var p2 := Vector2(p3.x, p3.z)
		var diff: Vector2 = p2 - cart_pos2
		var dist: float = diff.length()
		if dist <= pulse_r:
			var dir: Vector2 = diff.normalized() if dist > 0.01 else Vector2(0.0, 1.0)
			p["stun_timer"] = maxf(float(p["stun_timer"]), float(C.PULSE_STUN))
			p["knockback_vel"] = (p["knockback_vel"] as Vector2) + dir * float(C.PULSE_IMPULSE)
	_emit_fx("shockwave", Vector3(_cart_pos.x, 0.1, _cart_pos.y), Vector3.ZERO, 0)


func _step_valves(delta: float) -> void:
	_valve_cycle_timer -= delta
	if _valve_cycle_timer <= 0.0:
		if _match_phase >= 3:
			_valve_cycle_timer = float(C.VALVE_INTERVAL_P3)
			for v_raw in _valves:
				(v_raw as Dictionary)["active"] = true
		else:
			_valve_cycle_timer = float(C.VALVE_INTERVAL_P1)
			if not _valves.is_empty():
				var num_to_open: int = 2 if _valves.size() >= 4 else 1
				for _k in range(num_to_open):
					var v: Dictionary = _valves[_next_valve_idx % _valves.size()] as Dictionary
					v["active"] = true
					_next_valve_idx = (_next_valve_idx + 1) % _valves.size()

	for v_idx in range(_valves.size()):
		var v: Dictionary = _valves[v_idx] as Dictionary
		if not bool(v["active"]):
			v["charge"] = 0.0
			v["charging_team"] = 0
			continue
		var vpos: Vector2 = v["pos"] as Vector2
		var sole_team: int = 0
		var contested: bool = false
		for raw_p in _players.values():
			var p: Dictionary = raw_p as Dictionary
			if not bool(p["alive"]) or not bool(p["connected"]) or float(p["stun_timer"]) > 0.0:
				continue
			var p3: Vector3 = p["pos"] as Vector3
			if Vector2(p3.x, p3.z).distance_to(vpos) <= float(C.VALVE_RADIUS):
				var ptid: int = int(p["team_id"])
				if sole_team == 0:
					sole_team = ptid
				elif sole_team != ptid:
					contested = true
					break
		if sole_team > 0 and not contested:
			if int(v["charging_team"]) != sole_team:
				v["charge"] = 0.0
			v["charging_team"] = sole_team
			v["charge"] = float(v["charge"]) + delta / float(C.VALVE_HOLD_TIME)
			if float(v["charge"]) >= 1.0:
				_trigger_valve(v_idx, sole_team)
		elif sole_team == 0:
			v["charging_team"] = 0
			v["charge"] = maxf(0.0, float(v["charge"]) - delta * 0.8)


func _trigger_valve(v_idx: int, team_id: int) -> void:
	if v_idx < 0 or v_idx >= _valves.size():
		return
	var v: Dictionary = _valves[v_idx] as Dictionary
	v["active"] = false
	v["charge"] = 0.0
	v["charging_team"] = 0
	_surge_team = team_id
	_surge_timer = float(C.SURGE_DURATION)
	_last_attacker_team = team_id

	if _active_team_ids.size() >= 3:
		if _cart_branch_team > 0 and _cart_branch_team != team_id and bool(_door_alive.get(_cart_branch_team, false)):
			_surge_target_team = _cart_branch_team
		else:
			var own_dir: Vector2 = _door_dirs.get(team_id, Vector2(-1.0, 0.0)) as Vector2
			_surge_target_team = _pick_rival_branch(team_id, -own_dir)

	var cart_pos2: Vector2 = _cart_pos
	var knock_r: float = float(C.SURGE_KNOCK_RADIUS)
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if not bool(p["alive"]) or not bool(p["connected"]) or int(p["team_id"]) == team_id:
			continue
		var p3: Vector3 = p["pos"] as Vector3
		var p2 := Vector2(p3.x, p3.z)
		var diff: Vector2 = p2 - cart_pos2
		var dist: float = diff.length()
		if dist <= knock_r:
			var dir: Vector2 = diff.normalized() if dist > 0.01 else Vector2(0.0, 1.0)
			p["stun_timer"] = maxf(float(p["stun_timer"]), 0.35)
			p["knockback_vel"] = (p["knockback_vel"] as Vector2) + dir * (float(C.SHOVE_IMPULSE) * 0.85)

	var vpos: Vector2 = v["pos"] as Vector2
	_emit_fx("surge", Vector3(vpos.x, 0.2, vpos.y), Vector3(_cart_pos.x, 0.6, _cart_pos.y), team_id)
	_emit_banner("surge", team_id)


func _active_members_in_team(tid: int) -> int:
	var c: int = 0
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if int(p["team_id"]) == tid and bool(p["connected"]) and bool(p["alive"]):
			c += 1
	return c


func _active_team_count() -> int:
	var c: int = 0
	for tid in _active_team_ids:
		if _active_members_in_team(int(tid)) > 0:
			c += 1
	return c


func _first_active_team() -> int:
	for tid in _active_team_ids:
		if _active_members_in_team(int(tid)) > 0:
			return int(tid)
	return int(_active_team_ids[0]) if not _active_team_ids.is_empty() else 1


func _update_flanker_assignments() -> void:
	_flanker_assignments.clear()
	var active_valves: Array = []
	for v_raw in _valves:
		var v: Dictionary = v_raw as Dictionary
		if bool(v["active"]):
			active_valves.append(v["pos"] as Vector2)
	if active_valves.is_empty():
		return
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		var best_id: int = 0
		var best_dist: float = 99999.0
		for raw_nid in _players.keys():
			var nid: int = int(raw_nid)
			var p: Dictionary = _players[raw_nid] as Dictionary
			if int(p["team_id"]) != tid or not bool(p["is_ai"]) or not bool(p["alive"]) or not bool(p["connected"]):
				continue
			var p3: Vector3 = p["pos"] as Vector3
			var p2 := Vector2(p3.x, p3.z)
			for raw_vp in active_valves:
				var d: float = p2.distance_to(raw_vp as Vector2)
				if d < best_dist:
					best_dist = d
					best_id = nid
		if best_id != 0:
			_flanker_assignments[tid] = best_id


func _build_ai_state() -> Dictionary:
	_ai_players_cache.clear()
	for raw_nid in _players.keys():
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[raw_nid] as Dictionary
		var p3: Vector3 = p["pos"] as Vector3
		var f: Vector2 = p["facing"] as Vector2
		_ai_players_cache[nid] = {
			"id": nid,
			"team_id": int(p["team_id"]),
			"pos": Vector2(p3.x, p3.z),
			"yaw": atan2(f.x, f.y),
			"stun": float(p["stun_timer"]),
			"action_cd": float(p["action_cd"]),
			"alive": bool(p["alive"]) and bool(p["connected"]),
		}
	_ai_state_cache["players"] = _ai_players_cache
	_ai_state_cache["cart_x"] = _cart_x
	_ai_state_cache["cart_pos"] = _cart_pos
	_ai_state_cache["cart_vel"] = _cart_vel
	_ai_state_cache["cart_branch_team"] = _cart_branch_team
	_ai_state_cache["cart_branch_dist"] = _cart_branch_dist
	_ai_state_cache["active_team_ids"] = _active_team_ids
	_ai_state_cache["door_dirs"] = _door_dirs
	_ai_state_cache["door_alive"] = _door_alive
	_ai_state_cache["valves"] = _valves
	_ai_state_cache["pulse_active"] = _pulse_active
	_ai_state_cache["pulse_remaining"] = _pulse_remaining
	_ai_state_cache["flanker_assignments"] = _flanker_assignments
	return _ai_state_cache


func _step_players(delta: float) -> void:
	_update_flanker_assignments()
	var has_ai := false
	for raw_p in _players.values():
		if bool((raw_p as Dictionary)["is_ai"]):
			has_ai = true
			break
	var ai_state: Dictionary = _build_ai_state() if (has_ai and _ai_ctrl != null) else {}
	var team_count: int = _active_team_ids.size()

	for raw_nid in _players.keys():
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[raw_nid] as Dictionary
		if not bool(p["connected"]) or not bool(p["alive"]):
			continue

		p["stun_timer"] = maxf(0.0, float(p["stun_timer"]) - delta)
		p["action_cd"] = maxf(0.0, float(p["action_cd"]) - delta)
		p["shove_anim_timer"] = maxf(0.0, float(p["shove_anim_timer"]) - delta)

		var move_dir := Vector2.ZERO
		var want_action := false
		if bool(p["is_ai"]) and _ai_ctrl != null:
			var bot_inp: Dictionary = _ai_ctrl.compute_bot_input(nid, ai_state, C)
			move_dir = bot_inp.get("move", Vector2.ZERO) as Vector2
			want_action = bool(bot_inp.get("action", false))
		elif _client_inputs.has(nid):
			var cinp: Dictionary = _client_inputs[nid] as Dictionary
			move_dir = cinp.get("move", Vector2.ZERO) as Vector2
			want_action = bool(cinp.get("action", false))
			cinp["action"] = false
		elif not _is_self_test and nid == _local_net_id:
			var local_inp: Dictionary = _read_local_input()
			move_dir = local_inp["move"] as Vector2
			want_action = bool(local_inp["action"])

		if float(p["stun_timer"]) > 0.0:
			move_dir = Vector2.ZERO
			want_action = false
		elif move_dir.length_squared() > 0.01:
			p["facing"] = move_dir.normalized()

		var kb: Vector2 = p["knockback_vel"] as Vector2
		var pos3: Vector3 = p["pos"] as Vector3
		var pos2 := Vector2(pos3.x, pos3.z)
		pos2 += (move_dir.limit_length(1.0) * float(C.BASE_MOVE_SPEED) + kb) * delta
		p["knockback_vel"] = kb.move_toward(Vector2.ZERO, 24.0 * delta)
		pos2 = C.resolve_arena_obstacles(pos2, float(C.PLAYER_RADIUS), _cart_pos, _cart_angle, team_count)
		p["pos"] = Vector3(pos2.x, 0.0, pos2.y)

		if want_action and float(p["action_cd"]) <= 0.0:
			_perform_action(nid)

	# Pairwise player-vs-player separation pass + re-clamp against cart & arena obstacles
	var min_sep: float = float(C.PLAYER_RADIUS) * 2.2
	var p_ids: Array = _players.keys()
	p_ids.sort()
	for _iter in range(2):
		for i in range(p_ids.size()):
			var pa: Dictionary = _players[p_ids[i]] as Dictionary
			if not bool(pa["connected"]) or not bool(pa["alive"]):
				continue
			for j in range(i + 1, p_ids.size()):
				var pb: Dictionary = _players[p_ids[j]] as Dictionary
				if not bool(pb["connected"]) or not bool(pb["alive"]):
					continue
				var a3: Vector3 = pa["pos"] as Vector3
				var b3: Vector3 = pb["pos"] as Vector3
				var a2 := Vector2(a3.x, a3.z)
				var b2 := Vector2(b3.x, b3.z)
				var diff: Vector2 = b2 - a2
				var dist: float = diff.length()
				if dist < min_sep:
					var dir: Vector2 = (diff / dist) if dist >= 0.001 else Vector2(0.0, 1.0 if (i % 2 == 0) else -1.0)
					var push: Vector2 = dir * ((min_sep - dist) * 0.5)
					a2 -= push
					b2 += push
					pa["pos"] = Vector3(a2.x, 0.0, a2.y)
					pb["pos"] = Vector3(b2.x, 0.0, b2.y)

	for raw_nid in p_ids:
		var p: Dictionary = _players[raw_nid] as Dictionary
		if not bool(p["connected"]) or not bool(p["alive"]):
			continue
		var p3: Vector3 = p["pos"] as Vector3
		var resolved2: Vector2 = C.resolve_arena_obstacles(Vector2(p3.x, p3.z), float(C.PLAYER_RADIUS), _cart_pos, _cart_angle, team_count)
		p["pos"] = Vector3(resolved2.x, 0.0, resolved2.y)


func _perform_action(actor_id: int) -> void:
	if not _players.has(actor_id):
		return
	var actor: Dictionary = _players[actor_id] as Dictionary
	if not bool(actor["alive"]) or float(actor["stun_timer"]) > 0.0 or float(actor["action_cd"]) > 0.0:
		return
	actor["action_cd"] = float(C.ACTION_COOLDOWN)
	actor["shove_anim_timer"] = 0.22

	var a3: Vector3 = actor["pos"] as Vector3
	var a2 := Vector2(a3.x, a3.z)
	var facing: Vector2 = (actor["facing"] as Vector2).normalized()
	if facing.length_squared() < 0.01:
		facing = Vector2(1.0, 0.0)
	var actor_tid: int = int(actor["team_id"])

	# Priority 1: Industrial Shove (enemies in front cone, zero friendly fire)
	var shoved_any := false
	for raw_other_id in _players.keys():
		var other_id: int = int(raw_other_id)
		if other_id == actor_id:
			continue
		var other: Dictionary = _players[raw_other_id] as Dictionary
		if not bool(other["connected"]) or not bool(other["alive"]):
			continue
		if int(other["team_id"]) == actor_tid:
			continue
		if _team != null and _team.are_teammates(actor_id, other_id):
			continue
		var o3: Vector3 = other["pos"] as Vector3
		var diff: Vector2 = Vector2(o3.x, o3.z) - a2
		var dist: float = diff.length()
		if dist <= float(C.SHOVE_RANGE) and dist > 0.001:
			var dir: Vector2 = diff / dist
			if dir.dot(facing) >= float(C.SHOVE_COS_HALF):
				other["stun_timer"] = float(C.STUN_DURATION)
				other["knockback_vel"] = (other["knockback_vel"] as Vector2) + dir * float(C.SHOVE_IMPULSE)
				shoved_any = true

	if shoved_any:
		_emit_fx("shove", a3 + Vector3(facing.x * 0.8, 0.8, facing.y * 0.8), Vector3.ZERO, actor_tid)
		return

	# Priority 2: Power Ram on Bomb Cart
	if a2.distance_to(_cart_pos) <= float(C.RAM_RANGE):
		if _active_team_ids.size() <= 2:
			var left_tid: int = int(_active_team_ids[0])
			var ram_dir: float = 1.0 if actor_tid == left_tid else -1.0
			_cart_vel += ram_dir * float(C.RAM_IMPULSE)
			_cart_vel_2d = Vector2(_cart_vel, 0.0)
		elif _cart_reset_pause <= 0.0:
			if _cart_branch_team > 0 and _cart_branch_dist > float(C.HUB_RADIUS):
				if actor_tid == _cart_branch_team:
					_cart_vel -= float(C.RAM_IMPULSE)
				else:
					_cart_vel += float(C.RAM_IMPULSE)
					_last_attacker_team = actor_tid
				var bdir: Vector2 = _door_dirs.get(_cart_branch_team, Vector2.RIGHT) as Vector2
				_cart_vel_2d = bdir * _cart_vel
			else:
				var own_dir: Vector2 = _door_dirs.get(actor_tid, Vector2(-1.0, 0.0)) as Vector2
				var aim_dir: Vector2 = (facing * 0.6 + (-own_dir) * 0.4).normalized()
				var tgt: int = _pick_rival_branch(actor_tid, aim_dir)
				if tgt > 0:
					if tgt != _cart_branch_team:
						_cart_branch_dist = 0.0
					_cart_branch_team = tgt
					_cart_vel = maxf(_cart_vel, 0.0) + float(C.RAM_IMPULSE)
					var bdir2: Vector2 = _door_dirs.get(tgt, Vector2.RIGHT) as Vector2
					_cart_vel_2d = bdir2 * _cart_vel
					_cart_angle = float(C.branch_yaw_from_dir(bdir2))
					_last_attacker_team = actor_tid
		_emit_fx("ram", Vector3(_cart_pos.x, 0.8, _cart_pos.y), Vector3.ZERO, actor_tid)
		return

	# Priority 3: Quick Valve Slam
	for v_idx in range(_valves.size()):
		var v: Dictionary = _valves[v_idx] as Dictionary
		if bool(v["active"]) and a2.distance_to(v["pos"] as Vector2) <= float(C.VALVE_RADIUS):
			_trigger_valve(v_idx, actor_tid)
			return


func _step_cart(delta: float) -> void:
	if _active_team_ids.size() <= 2:
		_step_cart_2team(delta)
	else:
		_step_cart_multi(delta)


func _step_cart_2team(delta: float) -> void:
	var left_tid: int = int(_active_team_ids[0])
	var right_tid: int = int(_active_team_ids[1])
	var cart_pos2 := Vector2(_cart_x, 0.0)
	var left_push: int = 0
	var right_push: int = 0
	var push_r: float = float(C.PUSH_AURA_RADIUS)

	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if not bool(p["connected"]) or not bool(p["alive"]) or float(p["stun_timer"]) > 0.0:
			continue
		var p3: Vector3 = p["pos"] as Vector3
		if Vector2(p3.x, p3.z).distance_to(cart_pos2) <= push_r:
			var ptid: int = int(p["team_id"])
			if ptid == left_tid:
				left_push += 1
			elif ptid == right_tid:
				right_push += 1

	var left_alive: int = _active_members_in_team(left_tid)
	var right_alive: int = _active_members_in_team(right_tid)
	var left_w: float = float(C.underdog_weight(left_alive, right_alive))
	var right_w: float = float(C.underdog_weight(right_alive, left_alive))

	var net_adv: float = float(left_push) * left_w - float(right_push) * right_w
	var eff_adv: float = float(C.push_advantage_factor(net_adv))
	var target_vel: float = eff_adv * float(C.BASE_PUSH_SPEED) * float(C.phase_speed_mult(_match_phase))

	if _surge_team == left_tid and _surge_timer > 0.0:
		target_vel += float(C.SURGE_SPEED)
	elif _surge_team == right_tid and _surge_timer > 0.0:
		target_vel -= float(C.SURGE_SPEED)

	if left_push > 0 and right_push > 0:
		_cart_owner = 0
	elif eff_adv > 0.05 or _surge_team == left_tid:
		_cart_owner = left_tid
	elif eff_adv < -0.05 or _surge_team == right_tid:
		_cart_owner = right_tid
	else:
		_cart_owner = 0

	_cart_vel = lerpf(_cart_vel, target_vel, clampf(delta * 10.0, 0.0, 1.0))
	_cart_x = clampf(_cart_x + _cart_vel * delta, -float(C.TRACK_HALF_LEN), float(C.TRACK_HALF_LEN))
	_cart_pos = Vector2(_cart_x, 0.0)
	_cart_vel_2d = Vector2(_cart_vel, 0.0)
	_cart_branch_team = right_tid if _cart_x > 0.05 else (left_tid if _cart_x < -0.05 else 0)
	_cart_branch_dist = absf(_cart_x)
	_cart_angle = 0.0


func _step_cart_multi(delta: float) -> void:
	if _cart_reset_pause > 0.0:
		_cart_reset_pause = maxf(0.0, _cart_reset_pause - delta)
		_cart_pos = Vector2.ZERO
		_cart_x = 0.0
		_cart_vel = 0.0
		_cart_vel_2d = Vector2.ZERO
		_cart_branch_team = 0
		_cart_branch_dist = 0.0
		_cart_owner = 0
		return

	var push_r: float = float(C.PUSH_AURA_RADIUS)
	var hub_r: float = float(C.HUB_RADIUS)
	var track_len: float = float(C.TRACK_LEN_MULTI)
	var speed_mult: float = float(C.phase_speed_mult(_match_phase))

	# Compute max alive size among intact teams for proportional underdog weight
	var max_team_alive: int = 1
	var team_alive_map: Dictionary = {}
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		if bool(_door_alive.get(tid, false)):
			var cnt: int = _active_members_in_team(tid)
			team_alive_map[tid] = cnt
			max_team_alive = maxi(max_team_alive, cnt)

	var push_by_team: Dictionary = {}
	var pushing_players: Array = []
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if not bool(p["connected"]) or not bool(p["alive"]) or float(p["stun_timer"]) > 0.0:
			continue
		var p3: Vector3 = p["pos"] as Vector3
		if Vector2(p3.x, p3.z).distance_to(_cart_pos) <= push_r:
			var ptid: int = int(p["team_id"])
			push_by_team[ptid] = int(push_by_team.get(ptid, 0)) + 1
			pushing_players.append(p)

	# Case A: Cart is currently riding on intact branch T
	if _cart_branch_team > 0 and bool(_door_alive.get(_cart_branch_team, false)) and _cart_branch_dist > hub_r:
		var branch_tid: int = _cart_branch_team
		var branch_dir: Vector2 = _door_dirs.get(branch_tid, Vector2.RIGHT) as Vector2
		var defend_force: float = 0.0
		var attack_force: float = 0.0
		var dom_atk_tid: int = 0
		var dom_atk_w: float = 0.0

		for raw_tid in push_by_team.keys():
			var tid: int = int(raw_tid)
			var cnt: int = int(push_by_team[raw_tid])
			var w: float = float(C.underdog_weight(int(team_alive_map.get(tid, 1)), max_team_alive))
			var force: float = float(cnt) * w
			if tid == branch_tid:
				defend_force += force
			else:
				attack_force += force
				if force > dom_atk_w:
					dom_atk_w = force
					dom_atk_tid = tid

		var net_adv: float = attack_force - defend_force
		var eff_adv: float = float(C.push_advantage_factor(net_adv))
		var target_speed: float = eff_adv * float(C.BASE_PUSH_SPEED) * speed_mult

		if _surge_timer > 0.0 and _surge_team > 0:
			if _surge_team == branch_tid:
				target_speed -= float(C.SURGE_SPEED)
			else:
				target_speed += float(C.SURGE_SPEED)
				dom_atk_tid = _surge_team

		if attack_force > 0.01 and defend_force > 0.01:
			_cart_owner = 0
		elif _surge_timer > 0.0 and _surge_team > 0:
			_cart_owner = _surge_team
		elif eff_adv > 0.05 and dom_atk_tid > 0:
			_cart_owner = dom_atk_tid
		elif eff_adv < -0.05:
			_cart_owner = branch_tid
		else:
			_cart_owner = 0

		if dom_atk_tid > 0 and (eff_adv > 0.05 or (_surge_timer > 0.0 and _surge_team != branch_tid)):
			_last_attacker_team = dom_atk_tid

		_cart_vel = lerpf(_cart_vel, target_speed, clampf(delta * 10.0, 0.0, 1.0))
		_cart_branch_dist += _cart_vel * delta

		# Returned to central turntable hub
		if _cart_branch_dist <= hub_r and _cart_vel < 0.0:
			if _surge_timer > 0.0 and _surge_team == branch_tid:
				var next_tgt: int = _surge_target_team
				if next_tgt <= 0 or next_tgt == branch_tid or not bool(_door_alive.get(next_tgt, false)):
					next_tgt = _pick_rival_branch(_surge_team, -branch_dir)
				if next_tgt > 0:
					_cart_branch_team = next_tgt
					_cart_branch_dist = hub_r + 0.08
					_cart_vel = maxf(absf(_cart_vel), float(C.SURGE_SPEED) * 0.85)
					var next_dir: Vector2 = _door_dirs.get(next_tgt, Vector2.RIGHT) as Vector2
					_cart_pos = next_dir * _cart_branch_dist
					_cart_vel_2d = next_dir * _cart_vel
					_cart_x = _cart_pos.x
					_cart_angle = float(C.branch_yaw_from_dir(next_dir))
					return
			if _cart_branch_dist <= 0.0:
				_cart_branch_dist = 0.0
				_cart_branch_team = 0
				_cart_pos = Vector2.ZERO
				_cart_vel = 0.0
				_cart_vel_2d = Vector2.ZERO
				_cart_x = 0.0
				return

		_cart_branch_dist = clampf(_cart_branch_dist, 0.0, track_len)
		_cart_pos = branch_dir * _cart_branch_dist
		_cart_vel_2d = branch_dir * _cart_vel
		_cart_x = _cart_pos.x
		_cart_angle = float(C.branch_yaw_from_dir(branch_dir))
		return

	# Case B: Cart is on the Central Turntable Hub (branch_dist <= HUB_RADIUS)
	var net_vec := Vector2.ZERO
	var dom_tid: int = 0
	var dom_cnt: float = 0.0
	var team_force_sum: Dictionary = {}

	for raw_p in pushing_players:
		var p: Dictionary = raw_p as Dictionary
		var tid: int = int(p["team_id"])
		var own_dir: Vector2 = _door_dirs.get(tid, Vector2(-1.0, 0.0)) as Vector2
		var p_face: Vector2 = (p["facing"] as Vector2).normalized()
		var desire: Vector2 = (-own_dir * 0.60 + p_face * 0.40)
		if desire.length_squared() < 0.01 or desire.dot(own_dir) > 0.35:
			desire = -own_dir
		else:
			desire = desire.normalized()
		var w: float = float(C.underdog_weight(int(team_alive_map.get(tid, 1)), max_team_alive))
		net_vec += desire * w
		team_force_sum[tid] = float(team_force_sum.get(tid, 0.0)) + w

	for raw_tid in team_force_sum.keys():
		var fval: float = float(team_force_sum[raw_tid])
		if fval > dom_cnt:
			dom_cnt = fval
			dom_tid = int(raw_tid)

	if _surge_timer > 0.0 and _surge_team > 0:
		if _surge_target_team <= 0 or _surge_target_team == _surge_team or not bool(_door_alive.get(_surge_target_team, false)):
			var s_own: Vector2 = _door_dirs.get(_surge_team, Vector2(-1.0, 0.0)) as Vector2
			_surge_target_team = _pick_rival_branch(_surge_team, -s_own)
		if _surge_target_team > 0:
			var sdir: Vector2 = _door_dirs.get(_surge_target_team, Vector2.RIGHT) as Vector2
			net_vec += sdir * 3.5
			dom_tid = _surge_team

	if _cart_vel_2d.length() > 0.2:
		net_vec += _cart_vel_2d * 0.35

	# Pick the intact enemy branch most aligned with net_vec (never route sole pusher onto its own branch)
	var sole_pusher_tid: int = int(push_by_team.keys()[0]) if (push_by_team.size() == 1 and _surge_team == 0) else (_surge_team if (_surge_timer > 0.0 and _surge_team > 0) else 0)
	var best_tid: int = 0
	var best_dot: float = -999.0
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		if not bool(_door_alive.get(tid, false)):
			continue
		if sole_pusher_tid > 0 and tid == sole_pusher_tid:
			continue
		var ddir: Vector2 = _door_dirs.get(tid, Vector2.RIGHT) as Vector2
		var proj: float = net_vec.dot(ddir)
		if proj > best_dot:
			best_dot = proj
			best_tid = tid

	if best_tid > 0 and best_dot > 0.18:
		if best_tid != _cart_branch_team:
			_cart_branch_dist = 0.0
		_cart_branch_team = best_tid
		var bdir: Vector2 = _door_dirs.get(best_tid, Vector2.RIGHT) as Vector2
		var eff_mag: float = float(C.push_advantage_factor(best_dot))
		var target_speed: float = eff_mag * float(C.BASE_PUSH_SPEED) * speed_mult
		if _surge_timer > 0.0 and _surge_team > 0 and _surge_team != best_tid:
			target_speed += float(C.SURGE_SPEED)
		_cart_vel = lerpf(maxf(0.0, _cart_vel), target_speed, clampf(delta * 10.0, 0.0, 1.0))
		_cart_branch_dist = clampf(_cart_branch_dist + _cart_vel * delta, 0.0, track_len)
		_cart_pos = bdir * _cart_branch_dist
		_cart_vel_2d = bdir * _cart_vel
		_cart_x = _cart_pos.x
		_cart_angle = float(C.branch_yaw_from_dir(bdir))
		_cart_owner = 0 if push_by_team.size() >= 2 and _surge_timer <= 0.0 else dom_tid
		if dom_tid > 0 and dom_tid != best_tid:
			_last_attacker_team = dom_tid
	else:
		_cart_vel = lerpf(_cart_vel, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		_cart_vel_2d = _cart_vel_2d.lerp(Vector2.ZERO, clampf(delta * 10.0, 0.0, 1.0))
		_cart_branch_dist = maxf(0.0, _cart_branch_dist - delta * 1.5)
		if _cart_branch_dist <= 0.02:
			_cart_branch_dist = 0.0
			_cart_branch_team = 0
			_cart_pos = Vector2.ZERO
		elif _cart_branch_team > 0:
			var cur_dir: Vector2 = _door_dirs.get(_cart_branch_team, Vector2.RIGHT) as Vector2
			_cart_pos = cur_dir * _cart_branch_dist
		_cart_x = _cart_pos.x
		_cart_owner = 0


func player_disconnected(network_id: int) -> void:
	if not _players.has(network_id):
		return
	var p: Dictionary = _players[network_id] as Dictionary
	p["connected"] = false
	p["alive"] = false
	if _is_server_sim and _phase != PH_ENDED:
		if _active_team_ids.size() <= 2:
			if _active_team_count() <= 1:
				_finish_match(_first_active_team())
		else:
			var ptid: int = int(p["team_id"])
			if _active_members_in_team(ptid) <= 0 and bool(_door_alive.get(ptid, false)):
				_door_alive[ptid] = false
				_team_elim_order.append(ptid)
			var intact: Array = _intact_team_ids()
			if intact.size() <= 1:
				_finish_match(int(intact[0]) if not intact.is_empty() else 0)


func _finish_match_ranked(winner_tid: int, ranked_intact: Array, threatened_tid: int) -> void:
	if _phase == PH_ENDED:
		return
	_phase = PH_ENDED
	_winner_team = winner_tid

	var team_rank_points: Dictionary = {}
	for raw_tid in _active_team_ids:
		team_rank_points[int(raw_tid)] = 0
	# Breached teams earn points by survival order (later elimination = higher)
	for e_idx in range(_team_elim_order.size()):
		team_rank_points[int(_team_elim_order[e_idx])] = e_idx
	# Intact teams strictly outrank breached teams
	var base_intact_pts: int = _team_elim_order.size() + 1
	for r_raw in ranked_intact:
		var r: Dictionary = r_raw as Dictionary
		var tid: int = int(r["tid"])
		var pts: int = base_intact_pts + int(r["breaches"]) * 2 + (0 if tid == threatened_tid else 1)
		if winner_tid > 0 and tid == winner_tid:
			pts += 2
		team_rank_points[tid] = pts
		_team_scores[tid] = pts

	var raw_scores: Dictionary = {}
	for raw_nid in _players.keys():
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[raw_nid] as Dictionary
		var tid: int = int(p.get("team_id", 0))
		raw_scores[nid] = int(team_rank_points.get(tid, 0))

	var final_scores: Dictionary = raw_scores
	if _team != null:
		final_scores = _team.sync_scores(raw_scores, []) as Dictionary
		_team.notify_round_win(final_scores, self)
		_team.mark_scores_applied(self)

	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_round_end.rpc(final_scores, _team_scores, winner_tid)

	if winner_tid > 0:
		_emit_banner("win", winner_tid)
	else:
		_emit_banner("draw", 0)
	round_finished.emit(final_scores)


func _finish_match(winner_tid: int) -> void:
	if _phase == PH_ENDED:
		return
	_phase = PH_ENDED
	_winner_team = winner_tid
	var is_multi: bool = _active_team_ids.size() >= 3
	if winner_tid > 0:
		_team_scores[winner_tid] = 3 if is_multi else 1

	var raw_scores: Dictionary = {}
	for raw_nid in _players.keys():
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[raw_nid] as Dictionary
		var tid: int = int(p.get("team_id", 0))
		var sc: int = 0
		if not is_multi:
			sc = 1 if (winner_tid > 0 and tid == winner_tid) else 0
		else:
			if winner_tid > 0 and tid == winner_tid:
				sc = 3
			elif bool(_door_alive.get(tid, false)):
				sc = 2
			else:
				var elim_pos: int = _team_elim_order.find(tid)
				sc = maxi(0, elim_pos)
		raw_scores[nid] = sc
		_team_scores[tid] = sc

	var final_scores: Dictionary = raw_scores
	if _team != null:
		final_scores = _team.sync_scores(raw_scores, []) as Dictionary
		_team.notify_round_win(final_scores, self)
		_team.mark_scores_applied(self)

	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_round_end.rpc(final_scores, _team_scores, winner_tid)

	if winner_tid > 0:
		_emit_banner("win", winner_tid)
	else:
		_emit_banner("draw", 0)
	round_finished.emit(final_scores)


func _build_snapshot() -> Dictionary:
	var p_snaps: Dictionary = {}
	for raw_nid in _players.keys():
		var p: Dictionary = _players[raw_nid] as Dictionary
		p_snaps[int(raw_nid)] = {
			"p": p["pos"],
			"f": p["facing"],
			"s": float(p["stun_timer"]),
			"cd": float(p["action_cd"]),
			"sa": float(p.get("shove_anim_timer", 0.0)) > 0.0,
			"on": bool(p["connected"]),
			"al": bool(p["alive"]),
		}
	var v_snaps: Array = []
	for v_raw in _valves:
		var v: Dictionary = v_raw as Dictionary
		v_snaps.append({
			"a": bool(v["active"]),
			"c": float(v["charge"]),
			"t": int(v["charging_team"]),
		})
	return {
		"ph": _phase,
		"mp": _match_phase,
		"prep": _prep_remaining,
		"rem": _time_remaining,
		"ot": _overtime,
		"cx": _cart_x,
		"cv": _cart_vel,
		"cp": _cart_pos,
		"cv2": _cart_vel_2d,
		"cb": _cart_branch_team,
		"cd": _cart_branch_dist,
		"ca": _cart_angle,
		"rp": _cart_reset_pause,
		"co": _cart_owner,
		"st": _surge_team,
		"sr": _surge_timer,
		"pa": _pulse_active,
		"pr": _pulse_remaining,
		"da": _door_alive.duplicate(),
		"tb": _team_breaches.duplicate(),
		"at": _active_team_ids.duplicate(),
		"vs": v_snaps,
		"pl": p_snaps,
	}


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_state_snapshot(snap: Dictionary) -> void:
	if _is_server_sim:
		return
	_apply_snapshot(snap)


func _apply_snapshot(snap: Dictionary) -> void:
	_phase = int(snap.get("ph", _phase))
	_match_phase = int(snap.get("mp", _match_phase))
	_prep_remaining = float(snap.get("prep", _prep_remaining))
	_time_remaining = float(snap.get("rem", _time_remaining))
	_overtime = bool(snap.get("ot", _overtime))
	_cart_x = float(snap.get("cx", _cart_x))
	_cart_vel = float(snap.get("cv", _cart_vel))
	var raw_cp = snap.get("cp", null)
	if raw_cp is Vector2:
		_cart_pos = raw_cp as Vector2
	else:
		_cart_pos = Vector2(_cart_x, 0.0)
	var raw_cv2 = snap.get("cv2", null)
	if raw_cv2 is Vector2:
		_cart_vel_2d = raw_cv2 as Vector2
	_cart_branch_team = int(snap.get("cb", _cart_branch_team))
	_cart_branch_dist = float(snap.get("cd", _cart_branch_dist))
	_cart_angle = float(snap.get("ca", _cart_angle))
	_cart_reset_pause = float(snap.get("rp", _cart_reset_pause))
	_cart_owner = int(snap.get("co", _cart_owner))
	_surge_team = int(snap.get("st", _surge_team))
	_surge_timer = float(snap.get("sr", _surge_timer))
	_pulse_active = bool(snap.get("pa", _pulse_active))
	_pulse_remaining = float(snap.get("pr", _pulse_remaining))

	var da = snap.get("da", null)
	if da is Dictionary:
		for raw_k in (da as Dictionary).keys():
			_door_alive[int(raw_k)] = bool((da as Dictionary)[raw_k])
	var tb = snap.get("tb", null)
	if tb is Dictionary:
		for raw_k in (tb as Dictionary).keys():
			_team_breaches[int(raw_k)] = int((tb as Dictionary)[raw_k])
	var at = snap.get("at", null)
	if at is Array and not (at as Array).is_empty():
		var at_arr: Array = at as Array
		var teams_changed: bool = at_arr.size() != _active_team_ids.size()
		if not teams_changed:
			for ti in range(at_arr.size()):
				if int(at_arr[ti]) != int(_active_team_ids[ti]):
					teams_changed = true
					break
		if teams_changed:
			_active_team_ids.clear()
			for raw_t in at_arr:
				_active_team_ids.append(int(raw_t))
			_door_dirs = C.door_directions(_active_team_ids) as Dictionary

	var vs = snap.get("vs", [])
	if vs is Array:
		var vs_arr: Array = vs as Array
		for i in range(mini(vs_arr.size(), _valves.size())):
			var s: Dictionary = vs_arr[i] as Dictionary
			var v: Dictionary = _valves[i] as Dictionary
			v["active"] = bool(s.get("a", false))
			v["charge"] = float(s.get("c", 0.0))
			v["charging_team"] = int(s.get("t", 0))

	var pl_map = snap.get("pl", {})
	if pl_map is Dictionary:
		for raw_nid in (pl_map as Dictionary).keys():
			var nid: int = int(raw_nid)
			if _players.has(nid):
				var ps: Dictionary = (pl_map as Dictionary)[raw_nid] as Dictionary
				var p: Dictionary = _players[nid] as Dictionary
				p["pos"] = ps.get("p", p["pos"])
				p["facing"] = ps.get("f", p["facing"])
				p["stun_timer"] = float(ps.get("s", 0.0))
				p["action_cd"] = float(ps.get("cd", 0.0))
				p["shove_anim_timer"] = 0.20 if bool(ps.get("sa", false)) else 0.0
				p["connected"] = bool(ps.get("on", true))
				p["alive"] = bool(ps.get("al", p["connected"]))


@rpc("authority", "call_remote", "reliable")
func _rpc_round_end(final_scores: Dictionary, team_scores_snap: Dictionary = {}, winner_tid: int = 0) -> void:
	if _is_server_sim:
		return
	_phase = PH_ENDED
	_winner_team = winner_tid
	if not team_scores_snap.is_empty():
		_team_scores = team_scores_snap.duplicate()
	round_finished.emit(final_scores)


func _update_diegetic_monitor() -> void:
	if _monitor_timer_label != null and is_instance_valid(_monitor_timer_label):
		var t_txt: String = ""
		var t_col: Color = Color(1.0, 0.78, 0.24)
		if _prep_remaining > 0.0:
			t_txt = "00:0%d" % clampi(ceili(_prep_remaining), 0, 9)
			t_col = Color(1.0, 0.86, 0.36)
		elif _overtime:
			var ot_s: int = ceili(maxf(0.0, _time_remaining))
			t_txt = "%s %02d" % [_pick_loc("OT", "加时", "加時"), ot_s]
			t_col = Color(1.0, 0.30, 0.18)
		else:
			var s: int = ceili(maxf(0.0, _time_remaining))
			t_txt = "%02d:%02d" % [s / 60, s % 60]
			t_col = Color(1.0, 0.34, 0.20) if s <= 15 else Color(1.0, 0.78, 0.24)
		if t_txt != _mon_timer_text:
			_mon_timer_text = t_txt
			_monitor_timer_label.text = t_txt
		if not t_col.is_equal_approx(_mon_timer_col):
			_mon_timer_col = t_col
			_monitor_timer_label.modulate = t_col
	if _monitor_phase_label != null and is_instance_valid(_monitor_phase_label):
		var p_txt: String = ""
		var p_col: Color = Color(0.96, 0.72, 0.24)
		if _prep_remaining > 0.0:
			p_txt = _pick_loc("PREP", "准备", "準備")
			p_col = Color(0.95, 0.80, 0.36)
		elif _cart_reset_pause > 0.0:
			p_txt = _pick_loc("RESET", "转盘复位", "轉盤復位")
			p_col = Color(1.0, 0.56, 0.18)
		elif _overtime:
			p_txt = _pick_loc("OT", "加时", "加時")
			p_col = Color(1.0, 0.28, 0.18)
		elif _match_phase >= 3:
			p_txt = _pick_loc("OVERLOAD", "过载", "過載")
			p_col = Color(1.0, 0.28, 0.18)
		elif _match_phase == 2:
			p_txt = _pick_loc("FUSE", "引信", "引信")
			p_col = Color(1.0, 0.66, 0.18)
		else:
			p_txt = _pick_loc("PUSH", "推进", "推進")
			p_col = Color(0.96, 0.72, 0.24)
		if p_txt != _mon_phase_text:
			_mon_phase_text = p_txt
			_monitor_phase_label.text = p_txt
		if not p_col.is_equal_approx(_mon_phase_col):
			_mon_phase_col = p_col
			_monitor_phase_label.modulate = p_col


func _animate_visuals(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.tick(delta)

	_update_diegetic_monitor()

	if _camera != null and is_instance_valid(_camera) and _cam_base_pos != Vector3.ZERO:
		if _cam_shake > 0.001:
			_cam_shake = maxf(0.0, _cam_shake - delta * 1.4)
			var ox: float = sin(_srv_time * 57.0) * _cam_shake
			var oy: float = cos(_srv_time * 63.0) * _cam_shake * 0.7
			_camera.position = _cam_base_pos + Vector3(ox, oy, 0.0)
		elif _camera.position != _cam_base_pos:
			_camera.position = _cam_base_pos

	if _cart_root != null and is_instance_valid(_cart_root):
		var target_c := Vector3(_cart_pos.x, 0.0, _cart_pos.y)
		_cart_root.position = _cart_root.position.lerp(target_c, clampf(delta * 20.0, 0.0, 1.0))
		_cart_root.rotation.y = lerp_angle(_cart_root.rotation.y, _cart_angle, clampf(delta * 14.0, 0.0, 1.0))
		for raw_w in _cart_wheels:
			var w := raw_w as Node3D
			if w != null and is_instance_valid(w):
				w.rotate_z(-_cart_vel * delta * 1.8)

	if _turntable_node != null and is_instance_valid(_turntable_node):
		_turntable_node.rotation.y = lerp_angle(_turntable_node.rotation.y, _cart_angle, clampf(delta * 10.0, 0.0, 1.0))

	if _cart_warhead_mat != null:
		var pulse_blink: float = 0.5 + 0.5 * sin(_srv_time * (14.0 if _match_phase >= 3 else 5.0))
		if _match_phase >= 3:
			_cart_warhead_mat.emission = Color(1.0, 0.20, 0.10)
			_cart_warhead_mat.emission_energy_multiplier = 1.2 + pulse_blink * 2.2
		elif _match_phase == 2:
			_cart_warhead_mat.emission = Color(1.0, 0.48, 0.12)
			_cart_warhead_mat.emission_energy_multiplier = 0.85 + pulse_blink * 1.0
		else:
			_cart_warhead_mat.emission = Color(0.95, 0.34, 0.12)
			_cart_warhead_mat.emission_energy_multiplier = 0.52

	if _push_aura_mat != null:
		if _cart_owner > 0 and C.TEAM_COLORS.has(_cart_owner):
			var oc: Color = C.TEAM_COLORS[_cart_owner] as Color
			_push_aura_mat.albedo_color = Color(oc.r, oc.g, oc.b, 0.38)
			_push_aura_mat.emission = oc
		else:
			_push_aura_mat.albedo_color = Color(1.0, 0.80, 0.22, 0.30)
			_push_aura_mat.emission = Color(1.0, 0.78, 0.20)

	if _pulse_ring_mesh != null and is_instance_valid(_pulse_ring_mesh):
		_pulse_ring_mesh.visible = _pulse_active
		if _pulse_active and _pulse_ring_mat != null:
			var t_prog: float = 1.0 - clampf(_pulse_remaining / maxf(0.01, float(C.PULSE_WARN_TIME)), 0.0, 1.0)
			var sc: float = lerpf(0.4, 1.0, t_prog)
			_pulse_ring_mesh.scale = Vector3(sc, 1.0, sc)
			_pulse_ring_mat.albedo_color = Color(1.0, 0.24, 0.14, 0.25 + t_prog * 0.55)

	for v_idx in range(_valves.size()):
		if not _valve_nodes.has(v_idx):
			continue
		var v: Dictionary = _valves[v_idx] as Dictionary
		var vn: Dictionary = _valve_nodes[v_idx] as Dictionary
		var rmat := vn.get("ring_mat", null) as StandardMaterial3D
		var pmat := vn.get("pipe_mat", null) as StandardMaterial3D
		var is_act: bool = bool(v["active"])
		var c_tid: int = int(v.get("charging_team", 0))
		if rmat != null:
			if is_act and c_tid > 0 and C.TEAM_COLORS.has(c_tid):
				var cc: Color = C.TEAM_COLORS[c_tid] as Color
				rmat.albedo_color = Color(cc.r, cc.g, cc.b, 0.90)
				rmat.emission = cc
			elif is_act:
				rmat.albedo_color = Color(1.0, 0.76, 0.22, 0.85)
				rmat.emission = Color(1.0, 0.72, 0.18)
			else:
				rmat.albedo_color = Color(0.42, 0.36, 0.30, 0.28)
				rmat.emission = Color(0.35, 0.28, 0.22)
		if pmat != null:
			pmat.emission_energy_multiplier = 1.45 if is_act else 0.14

	var is_multi: bool = _active_team_ids.size() >= 3
	var left_tid: int = int(_active_team_ids[0])
	var right_tid: int = int(_active_team_ids[1])
	var left_col: Color = C.TEAM_COLORS.get(left_tid, Color.WHITE) as Color
	var right_col: Color = C.TEAM_COLORS.get(right_tid, Color.WHITE) as Color
	for raw_led in _track_leds:
		var led: Dictionary = raw_led as Dictionary
		var lmat := led.get("mat", null) as StandardMaterial3D
		if lmat == null:
			continue
		if int(led.get("mode", 2)) == 2:
			var lx: float = float(led.get("x", 0.0))
			if lx <= _cart_x - 0.3:
				lmat.albedo_color = left_col
				lmat.emission = left_col
			elif lx >= _cart_x + 0.3:
				lmat.albedo_color = right_col
				lmat.emission = right_col
			else:
				lmat.albedo_color = Color(1.0, 0.82, 0.22)
				lmat.emission = Color(1.0, 0.82, 0.22)
		else:
			var b_tid: int = int(led.get("team_id", 0))
			var ldist: float = float(led.get("dist", 0.0))
			if not bool(_door_alive.get(b_tid, true)):
				lmat.albedo_color = Color(0.18, 0.15, 0.14)
				lmat.emission = Color(0.10, 0.08, 0.07)
			elif _cart_branch_team == b_tid and ldist <= _cart_branch_dist + 0.4:
				lmat.albedo_color = Color(1.0, 0.30, 0.14)
				lmat.emission = Color(1.0, 0.30, 0.14)
			else:
				var bc: Color = C.TEAM_COLORS.get(b_tid, Color.WHITE) as Color
				lmat.albedo_color = bc
				lmat.emission = bc

	var track_len: float = float(C.track_length(_active_team_ids.size()))
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		var intact: bool = bool(_door_alive.get(tid, true))
		var dmat := _door_lights.get(tid, null) as StandardMaterial3D
		var dinfo: Dictionary = _door_nodes.get(tid, {}) as Dictionary
		var gate := dinfo.get("gate", null) as MeshInstance3D
		var gate_mat := dinfo.get("gate_mat", null) as StandardMaterial3D
		var band_mat := dinfo.get("band_mat", null) as StandardMaterial3D
		var zone_mat := dinfo.get("zone_mat", null) as StandardMaterial3D
		var door_omni := dinfo.get("omni", null) as OmniLight3D

		if not intact:
			if gate != null and is_instance_valid(gate):
				gate.position.y = lerpf(gate.position.y, -1.25, clampf(delta * 8.0, 0.0, 1.0))
			if gate_mat != null:
				gate_mat.emission_energy_multiplier = 0.02
			if dmat != null:
				dmat.emission_energy_multiplier = 0.05
				dmat.albedo_color = Color(0.22, 0.16, 0.14)
			if band_mat != null:
				band_mat.emission_energy_multiplier = 0.05
			if zone_mat != null:
				zone_mat.albedo_color = Color(0.15, 0.12, 0.11, 0.16)
				zone_mat.emission_energy_multiplier = 0.0
			if door_omni != null and is_instance_valid(door_omni):
				door_omni.light_energy = 0.0
		else:
			var ddir: Vector2 = _door_dirs.get(tid, Vector2(-1.0, 0.0)) as Vector2
			var dpos2: Vector2 = ddir * track_len
			var near_door: bool = _cart_pos.distance_to(dpos2) <= 3.8
			if dmat != null:
				var flash_freq: float = 14.0 if near_door else 3.0
				dmat.emission_energy_multiplier = 1.45 + (1.85 if near_door else 0.55) * (0.5 + 0.5 * sin(_srv_time * flash_freq))

	var local_pos := Vector3.ZERO
	var local_alive: bool = false
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		var pnode: Node3D = p.get("node", null) as Node3D
		var is_vis: bool = bool(p.get("connected", true)) and bool(p.get("alive", true))
		if int(p.get("network_id", -1)) == _local_net_id:
			local_pos = p.get("render_pos", p["pos"]) as Vector3
			local_alive = is_vis
		if pnode == null or not is_instance_valid(pnode):
			continue
		pnode.visible = is_vis
		if not is_vis:
			continue
		var target_pos: Vector3 = p["pos"] as Vector3
		var cur_rp: Vector3 = p.get("render_pos", target_pos) as Vector3
		var move_speed: float = cur_rp.distance_to(target_pos) / maxf(delta, 0.001)
		var next_rp: Vector3 = cur_rp.lerp(target_pos, clampf(delta * 18.0, 0.0, 1.0))
		p["render_pos"] = next_rp
		pnode.position = next_rp
		if int(p.get("network_id", -1)) == _local_net_id:
			local_pos = next_rp
		var f: Vector2 = p.get("facing", Vector2(1.0, 0.0)) as Vector2
		if f.length_squared() > 0.01:
			pnode.rotation.y = atan2(f.x, f.y)
		var stunned: bool = float(p.get("stun_timer", 0.0)) > 0.0
		var shoving: bool = float(p.get("shove_anim_timer", 0.0)) > 0.0
		var rig := p.get("rig", null) as Node3D
		if rig != null and is_instance_valid(rig):
			rig.rotation.z = lerpf(rig.rotation.z, 0.45 if stunned else 0.0, clampf(delta * 16.0, 0.0, 1.0))
		else:
			pnode.rotation.z = lerpf(pnode.rotation.z, 0.42 if stunned else 0.0, clampf(delta * 16.0, 0.0, 1.0))
		var ap := p.get("anim_player", null) as AnimationPlayer
		if ap != null and is_instance_valid(ap):
			var desired_anim: StringName = &"mp_mod/idle"
			var desired_speed: float = 1.0
			if stunned:
				desired_anim = &"mp_mod/shoved"
			elif shoving and ap.has_animation(&"mp_mod/shove"):
				desired_anim = &"mp_mod/shove"
				desired_speed = 1.35
			elif move_speed > 0.45:
				desired_anim = &"mp_mod/run"
				desired_speed = clampf(move_speed / float(C.BASE_MOVE_SPEED), 0.55, 1.35)
			ap.speed_scale = desired_speed
			if ap.has_animation(desired_anim) and ap.current_animation != desired_anim:
				ap.play(desired_anim, 0.08)

	if _hud != null:
		var show_you: bool = _you_marker_timer > 0.0 and _phase != PH_ENDED and _screenshot_path.is_empty()
		_hud.update_you_marker(_camera, local_pos, local_alive, _srv_time, show_you)

		_team_alive_cache.clear()
		for raw_tid in _active_team_ids:
			var tid: int = int(raw_tid)
			_team_alive_cache[tid] = _active_members_in_team(tid)

		_hud_state_cache["active_team_ids"] = _active_team_ids
		_hud_state_cache["cart_x"] = _cart_x
		_hud_state_cache["track_len"] = track_len
		_hud_state_cache["cart_branch_team"] = _cart_branch_team
		_hud_state_cache["cart_branch_dist"] = _cart_branch_dist
		_hud_state_cache["door_alive"] = _door_alive
		_hud_state_cache["team_alive_counts"] = _team_alive_cache
		_hud_state_cache["time_left"] = _time_remaining
		_hud_state_cache["phase"] = _match_phase
		_hud_state_cache["overtime"] = _overtime
		_hud_state_cache["surge_team"] = _surge_team
		_hud_state_cache["surge_timer"] = _surge_timer
		_hud_state_cache["prep_left"] = _prep_remaining
		_hud_state_cache["banner_text"] = ""
		_hud_state_cache["winner_team"] = _winner_team
		_hud_state_cache["standalone_mode"] = _standalone_mode
		_hud_state_cache["screenshot_mode"] = not _screenshot_path.is_empty()
		_hud.update_hud(_hud_state_cache)
