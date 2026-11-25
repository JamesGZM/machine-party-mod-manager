extends Node3D

## ============================================================================
## Bomb Cart / 炸彈推車 — Server-Authoritative 2-Team Tug-of-War Minigame Stage
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
var _map_seed: int = 20261123
var _sync_accum: float = 0.0
var _fx_warmed_up: bool = false

var _active_team_ids: Array = [1, 2]
var _team_scores: Dictionary = {1: 0, 2: 0}
var _winner_team: int = 0

var _cart_x: float = 0.0
var _cart_vel: float = 0.0
var _cart_owner: int = 0
var _max_abs_push: float = 0.0
var _max_abs_push_team: int = 0

var _surge_team: int = 0
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

var _arena_root: Node3D = null
var _fx_root: Node3D = null
var _player_root: Node3D = null
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
var _track_leds: Array = []

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
	for arg in args:
		if arg == "--self-test":
			_is_self_test = true
			var st_cls = _load_script_res(SELF_TEST_RES, "self_test.gd")
			if st_cls != null:
				_self_test_runner = st_cls.new()
				_self_test_runner.run_self_tests(self)
			return
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.substr("--screenshot=".length())
		elif arg.begins_with("--capture-screenshot="):
			_screenshot_path = arg.substr("--capture-screenshot=".length())

	if not _screenshot_path.is_empty():
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var demo_roster: Array = _build_standalone_roster(3)
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
		var roster: Array = _build_standalone_roster(2)
		_setup_match_local(0, 20261123, roster, false)


func _stage_default_screenshot() -> void:
	_phase = PH_LIVE
	_match_phase = 2
	_prep_remaining = 0.0
	_elapsed_time = 46.0
	_time_remaining = 29.0
	_cart_x = 1.2
	_cart_vel = 2.6
	_cart_owner = 1
	_surge_team = 1
	_surge_timer = 1.6
	_pulse_active = true
	_pulse_remaining = 0.65
	if _valves.size() >= 2:
		(_valves[0] as Dictionary)["active"] = true

	var red_spots: Array = [
		{"pos": Vector3(-1.8, 0.0, 1.4), "facing": Vector2(1.0, -0.25), "shove": true},
		{"pos": Vector3(-2.4, 0.0, -1.2), "facing": Vector2(1.0, 0.25), "shove": false},
		{"pos": Vector3(0.0, 0.0, -5.8), "facing": Vector2(0.0, 1.0), "shove": false},
	]
	var blue_spots: Array = [
		{"pos": Vector3(3.6, 0.0, 1.4), "facing": Vector2(-1.0, -0.25), "shove": false},
		{"pos": Vector3(3.9, 0.0, -1.2), "facing": Vector2(-1.0, 0.25), "shove": false},
		{"pos": Vector3(3.5, 0.0, 4.2), "facing": Vector2(-0.8, -0.6), "shove": false},
	]
	var r_idx: int = 0
	var b_idx: int = 0
	var nids: Array = _players.keys()
	nids.sort()
	for raw_nid in nids:
		var p: Dictionary = _players[raw_nid] as Dictionary
		var tid: int = int(p["team_id"])
		var spot: Dictionary = {}
		if tid == 1 and r_idx < red_spots.size():
			spot = red_spots[r_idx] as Dictionary
			r_idx += 1
		elif tid == 2 and b_idx < blue_spots.size():
			spot = blue_spots[b_idx] as Dictionary
			b_idx += 1
		if not spot.is_empty():
			var sp: Vector3 = spot["pos"] as Vector3
			p["pos"] = sp
			p["render_pos"] = sp
			p["facing"] = spot["facing"] as Vector2
			if bool(spot.get("shove", false)):
				p["shove_anim_timer"] = 0.16

	if _fx_pool != null:
		_fx_pool.spawn_ram_sparks(Vector3(_cart_x, 0.85, 0.0), C.TEAM_COLORS[1] as Color)
		_fx_pool.spawn_steam_surge(Vector3(0.0, 0.25, -6.0), Vector3(_cart_x, 0.6, 0.0), C.TEAM_COLORS[1] as Color)
		_fx_pool.tick(0.08)

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
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(2), false)


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


func _build_standalone_roster(per_team: int) -> Array:
	var roster: Array = []
	var idx: int = 0
	for t in [1, 2]:
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
	_track_leds.clear()


func _setup_match_local(round_idx: int, seed_val: int, roster: Array, all_ai: bool = false) -> void:
	_load_helpers()
	_clear_scene_children()
	_map_seed = seed_val + round_idx * 31

	_phase = PH_PREP
	_match_phase = 1
	_srv_time = 0.0
	_prep_remaining = float(C.PREP_DURATION)
	_elapsed_time = 0.0
	_time_remaining = float(C.MATCH_DURATION)
	_overtime = false
	_last_countdown_sec = 4
	_sync_accum = 0.0
	_fx_warmed_up = false

	_active_team_ids = [1, 2]
	_team_scores = {1: 0, 2: 0}
	_winner_team = 0

	_cart_x = 0.0
	_cart_vel = 0.0
	_cart_owner = 0
	_max_abs_push = 0.0
	_max_abs_push_team = 0

	_surge_team = 0
	_surge_timer = 0.0

	_pulse_active = false
	_pulse_remaining = 0.0
	_pulse_cooldown = float(C.PULSE_INTERVAL)

	_valves = [
		{"pos": C.VALVE_POS_NORTH, "active": false, "charge": 0.0, "charging_team": 0},
		{"pos": C.VALVE_POS_SOUTH, "active": false, "charge": 0.0, "charging_team": 0},
	]
	_valve_cycle_timer = float(C.VALVE_INTERVAL_P1)
	_next_valve_idx = 0

	_players.clear()
	_client_inputs.clear()
	_flanker_assignments.clear()
	_cam_shake = 0.0

	if _team != null:
		_team.begin_match(self, roster)

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
		_ensure_environment_and_camera()
		if M != null and M.has_method("ensure_game_pck_mounted"):
			M.ensure_game_pck_mounted()
		_init_audio()
		if M != null:
			var arena_info: Dictionary = M.build_arena(_arena_root, C)
			_cart_root = arena_info.get("cart_root", null) as Node3D
			_cart_wheels = arena_info.get("cart_wheels", []) as Array
			_cart_warhead_mat = arena_info.get("cart_warhead_mat", null) as StandardMaterial3D
			_push_aura_mesh = arena_info.get("push_aura_mesh", null) as MeshInstance3D
			_push_aura_mat = arena_info.get("push_aura_mat", null) as StandardMaterial3D
			_pulse_ring_mesh = arena_info.get("pulse_ring_mesh", null) as MeshInstance3D
			_pulse_ring_mat = arena_info.get("pulse_ring_mat", null) as StandardMaterial3D
			_valve_nodes = arena_info.get("valve_nodes", {}) as Dictionary
			_door_lights = arena_info.get("door_lights", {}) as Dictionary
			_track_leds = arena_info.get("track_leds", []) as Array
		if _fx_pool != null:
			_fx_pool.setup(_fx_root)
		if _hud != null:
			_hud.setup(self, Callable(self, "_pick_loc"))

	_spawn_players(roster, all_ai)


func _ensure_environment_and_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.name = "ArenaCamera"
		_camera.fov = 42.0
		_camera.current = true
		add_child(_camera)
	_camera.position = Vector3(0.0, 16.5, 14.5)
	_camera.look_at(Vector3(0.0, 0.4, 0.0), Vector3.UP)
	_cam_base_pos = _camera.position

	if get_node_or_null("WorldEnv") == null:
		var env_node := WorldEnvironment.new()
		env_node.name = "WorldEnv"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.06, 0.08, 0.11)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.48, 0.52, 0.62)
		env.ambient_light_energy = 0.90
		env_node.environment = env
		add_child(env_node)

	if get_node_or_null("SunLight") == null:
		var sun := DirectionalLight3D.new()
		sun.name = "SunLight"
		sun.rotation_degrees = Vector3(-50.0, 32.0, 0.0)
		sun.light_color = Color(1.0, 0.97, 0.92)
		sun.light_energy = 1.25
		sun.shadow_enabled = true
		add_child(sun)

	if get_node_or_null("RimLight") == null:
		var rim := DirectionalLight3D.new()
		rim.name = "RimLight"
		rim.rotation_degrees = Vector3(-35.0, -145.0, 0.0)
		rim.light_color = Color(0.45, 0.78, 1.0)
		rim.light_energy = 0.45
		add_child(rim)


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
	var team_members: Dictionary = {1: [], 2: []}
	for raw_r in roster:
		if not (raw_r is Dictionary):
			continue
		var r: Dictionary = raw_r as Dictionary
		var nid: int = int(r.get("network_id", 0))
		var tid: int = int(r.get("team_id", 0))
		if tid <= 0 and _team != null:
			tid = int(_team.player_team(nid))
		if tid != 1 and tid != 2:
			tid = 1 if (absi(nid) % 2 == 1) else 2
		(team_members[tid] as Array).append(r)

	for tid in [1, 2]:
		var members: Array = team_members[tid] as Array
		var spawn_x: float = -8.5 if tid == 1 else 8.5
		var facing := Vector2(1.0, 0.0) if tid == 1 else Vector2(-1.0, 0.0)
		for m_idx in range(members.size()):
			var r: Dictionary = members[m_idx] as Dictionary
			var nid: int = int(r.get("network_id", 0))
			var z_offset: float = (float(m_idx) - float(members.size() - 1) * 0.5) * 1.65
			var spawn2: Vector2 = C.resolve_arena_obstacles(Vector2(spawn_x, z_offset), float(C.PLAYER_RADIUS), _cart_x)
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
				_hud.show_banner(str(arg) if arg > 0 else "GO!", Color(0.45, 0.95, 1.0), 0.9)
			if arg > 0 and _sfx_beep != null:
				_sfx_beep.play()
			elif arg <= 0 and _sfx_ding != null:
				_sfx_ding.play()
		"phase2":
			if _hud != null:
				_hud.show_banner(_pick_loc("FUSE IGNITED! 1.35x SPEED & SHOCKWAVE", "引信点燃! 1.35x 推速与震荡脉冲", "引信點燃! 1.35x 推速與震盪脈衝"), Color(1.0, 0.62, 0.18), 2.4)
			if _sfx_warn != null:
				_sfx_warn.play()
		"phase3":
			if _hud != null:
				_hud.show_banner(_pick_loc("CRITICAL OVERLOAD! BOTH VALVES ACTIVE", "临界过载! 双阀门同时激活", "臨界過載! 雙閥門同時激活"), Color(1.0, 0.25, 0.22), 2.5)
			if _sfx_warn != null:
				_sfx_warn.play()
		"overtime":
			if _hud != null:
				_hud.show_banner(_pick_loc("SUDDEN DEATH! PUSH +/- 0.6m TO WIN", "突然死亡加时! 推进 +/- 0.6m 即胜", "突然死亡加時! 推進 +/- 0.6m 即勝"), Color(1.0, 0.86, 0.24), 2.5)
			if _sfx_warn != null:
				_sfx_warn.play()
		"surge":
			if _hud != null:
				var tcol: Color = C.TEAM_COLORS.get(arg, Color.WHITE) as Color
				var msg: String = _pick_loc("RED ROCKET SURGE!", "红队火箭助推!", "紅隊火箭助推!") if arg == 1 else _pick_loc("BLUE ROCKET SURGE!", "蓝队火箭助推!", "藍隊火箭助推!")
				_hud.show_banner(msg, tcol, 2.0)
			if _sfx_ding != null:
				_sfx_ding.play()
		"win":
			if _hud != null and _team != null:
				_hud.show_banner(_team.team_win_banner(arg), C.TEAM_COLORS.get(arg, Color.WHITE) as Color, 4.0)
			if _sfx_ding != null:
				_sfx_ding.play()
		"draw":
			if _hud != null:
				_hud.show_banner(_pick_loc("DRAW!", "平局!", "平局!"), Color(0.92, 0.92, 0.96), 4.0)
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
		_cam_shake = maxf(_cam_shake, 0.28)


func _step_prep(delta: float) -> void:
	_prep_remaining = maxf(0.0, _prep_remaining - delta)
	var sec: int = ceili(_prep_remaining)
	if sec != _last_countdown_sec:
		_last_countdown_sec = sec
		_emit_banner("prep", sec)
	if _prep_remaining <= 0.0:
		_phase = PH_LIVE


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

	if absf(_cart_x) > _max_abs_push:
		_max_abs_push = absf(_cart_x)
		_max_abs_push_team = 1 if _cart_x > 0.0 else 2

	# Check Blast Door Breach (Instant KO)
	if _cart_x >= float(C.TRACK_HALF_LEN):
		_emit_fx("breach", Vector3(float(C.TRACK_HALF_LEN), 1.0, 0.0), Vector3.ZERO, 1)
		_finish_match(1)
		return
	if _cart_x <= -float(C.TRACK_HALF_LEN):
		_emit_fx("breach", Vector3(-float(C.TRACK_HALF_LEN), 1.0, 0.0), Vector3.ZERO, 2)
		_finish_match(2)
		return

	# Check disconnect fallback
	if _active_team_count() <= 1:
		var survivor: int = _first_active_team()
		_finish_match(survivor)
		return

	# Check Overtime win or expiration
	if _overtime:
		if _cart_x >= float(C.OVERTIME_WIN_X):
			_finish_match(1)
			return
		if _cart_x <= -float(C.OVERTIME_WIN_X):
			_finish_match(2)
			return
		if _time_remaining <= 0.0:
			if _cart_x > float(C.TIE_DEADZONE_X):
				_finish_match(1)
			elif _cart_x < -float(C.TIE_DEADZONE_X):
				_finish_match(2)
			else:
				_finish_match(_max_abs_push_team)
			return
	elif _time_remaining <= 0.0:
		if _cart_x > float(C.TIE_DEADZONE_X):
			_finish_match(1)
			return
		if _cart_x < -float(C.TIE_DEADZONE_X):
			_finish_match(2)
			return
		# Tied within deadzone -> 10s Sudden Death Overtime
		_overtime = true
		_time_remaining = float(C.OVERTIME_DURATION)
		_emit_banner("overtime", 0)


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
	var cart_pos2 := Vector2(_cart_x, 0.0)
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
	_emit_fx("shockwave", Vector3(_cart_x, 0.1, 0.0), Vector3.ZERO, 0)


func _step_valves(delta: float) -> void:
	_valve_cycle_timer -= delta
	if _valve_cycle_timer <= 0.0:
		if _match_phase >= 3:
			_valve_cycle_timer = float(C.VALVE_INTERVAL_P3)
			for v_raw in _valves:
				(v_raw as Dictionary)["active"] = true
		else:
			_valve_cycle_timer = float(C.VALVE_INTERVAL_P1)
			if _valves.size() >= 2:
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
		var red_on: bool = false
		var blue_on: bool = false
		for raw_p in _players.values():
			var p: Dictionary = raw_p as Dictionary
			if not bool(p["alive"]) or not bool(p["connected"]) or float(p["stun_timer"]) > 0.0:
				continue
			var p3: Vector3 = p["pos"] as Vector3
			if Vector2(p3.x, p3.z).distance_to(vpos) <= float(C.VALVE_RADIUS):
				if int(p["team_id"]) == 1:
					red_on = true
				elif int(p["team_id"]) == 2:
					blue_on = true
		if red_on and not blue_on:
			v["charging_team"] = 1
			v["charge"] = float(v["charge"]) + delta / float(C.VALVE_HOLD_TIME)
			if float(v["charge"]) >= 1.0:
				_trigger_valve(v_idx, 1)
		elif blue_on and not red_on:
			v["charging_team"] = 2
			v["charge"] = float(v["charge"]) + delta / float(C.VALVE_HOLD_TIME)
			if float(v["charge"]) >= 1.0:
				_trigger_valve(v_idx, 2)
		elif not red_on and not blue_on:
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

	var cart_pos2 := Vector2(_cart_x, 0.0)
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
	_emit_fx("surge", Vector3(vpos.x, 0.2, vpos.y), Vector3(_cart_x, 0.6, 0.0), team_id)
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
	return 1


func _update_flanker_assignments() -> void:
	_flanker_assignments.clear()
	var active_valve_pos := Vector2.ZERO
	var has_active := false
	for v_raw in _valves:
		var v: Dictionary = v_raw as Dictionary
		if bool(v["active"]):
			active_valve_pos = v["pos"] as Vector2
			has_active = true
			break
	if not has_active:
		return
	for tid in [1, 2]:
		var best_id: int = 0
		var best_dist: float = 99999.0
		for raw_nid in _players.keys():
			var nid: int = int(raw_nid)
			var p: Dictionary = _players[raw_nid] as Dictionary
			if int(p["team_id"]) != tid or not bool(p["is_ai"]) or not bool(p["alive"]) or not bool(p["connected"]):
				continue
			var p3: Vector3 = p["pos"] as Vector3
			var d: float = Vector2(p3.x, p3.z).distance_to(active_valve_pos)
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
	_ai_state_cache["cart_vel"] = _cart_vel
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
		elif _standalone_mode and nid == 1:
			var local_inp: Dictionary = _read_local_input()
			move_dir = local_inp["move"] as Vector2
			want_action = bool(local_inp["action"])
		elif _client_inputs.has(nid):
			var cinp: Dictionary = _client_inputs[nid] as Dictionary
			move_dir = cinp.get("move", Vector2.ZERO) as Vector2
			want_action = bool(cinp.get("action", false))
			cinp["action"] = false

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
		pos2 = C.resolve_arena_obstacles(pos2, float(C.PLAYER_RADIUS), _cart_x)
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
		var resolved2: Vector2 = C.resolve_arena_obstacles(Vector2(p3.x, p3.z), float(C.PLAYER_RADIUS), _cart_x)
		p["pos"] = Vector3(resolved2.x, 0.0, resolved2.y)


func _perform_action(actor_id: int) -> void:
	if not _players.has(actor_id):
		return
	var actor: Dictionary = _players[actor_id] as Dictionary
	if float(actor["stun_timer"]) > 0.0 or float(actor["action_cd"]) > 0.0:
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
	var cart_pos2 := Vector2(_cart_x, 0.0)
	if a2.distance_to(cart_pos2) <= float(C.RAM_RANGE):
		var ram_dir: float = 1.0 if actor_tid == 1 else -1.0
		_cart_vel += ram_dir * float(C.RAM_IMPULSE)
		_emit_fx("ram", Vector3(_cart_x, 0.8, 0.0), Vector3.ZERO, actor_tid)
		return

	# Priority 3: Quick Valve Slam
	for v_idx in range(_valves.size()):
		var v: Dictionary = _valves[v_idx] as Dictionary
		if bool(v["active"]) and a2.distance_to(v["pos"] as Vector2) <= float(C.VALVE_RADIUS):
			_trigger_valve(v_idx, actor_tid)
			return


func _step_cart(delta: float) -> void:
	var cart_pos2 := Vector2(_cart_x, 0.0)
	var red_push: int = 0
	var blue_push: int = 0
	var push_r: float = float(C.PUSH_AURA_RADIUS)

	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if not bool(p["connected"]) or not bool(p["alive"]) or float(p["stun_timer"]) > 0.0:
			continue
		var p3: Vector3 = p["pos"] as Vector3
		if Vector2(p3.x, p3.z).distance_to(cart_pos2) <= push_r:
			if int(p["team_id"]) == 1:
				red_push += 1
			elif int(p["team_id"]) == 2:
				blue_push += 1

	var red_alive: int = _active_members_in_team(1)
	var blue_alive: int = _active_members_in_team(2)
	var red_w: float = float(C.underdog_weight(red_alive, blue_alive))
	var blue_w: float = float(C.underdog_weight(blue_alive, red_alive))

	var net_adv: float = float(red_push) * red_w - float(blue_push) * blue_w
	var eff_adv: float = float(C.push_advantage_factor(net_adv))
	var target_vel: float = eff_adv * float(C.BASE_PUSH_SPEED) * float(C.phase_speed_mult(_match_phase))

	if _surge_team == 1 and _surge_timer > 0.0:
		target_vel += float(C.SURGE_SPEED)
	elif _surge_team == 2 and _surge_timer > 0.0:
		target_vel -= float(C.SURGE_SPEED)

	if red_push > 0 and blue_push > 0:
		_cart_owner = 0
	elif eff_adv > 0.05 or _surge_team == 1:
		_cart_owner = 1
	elif eff_adv < -0.05 or _surge_team == 2:
		_cart_owner = 2
	else:
		_cart_owner = 0

	_cart_vel = lerpf(_cart_vel, target_vel, clampf(delta * 10.0, 0.0, 1.0))
	_cart_x = clampf(_cart_x + _cart_vel * delta, -float(C.TRACK_HALF_LEN), float(C.TRACK_HALF_LEN))


func player_disconnected(network_id: int) -> void:
	if not _players.has(network_id):
		return
	var p: Dictionary = _players[network_id] as Dictionary
	p["connected"] = false
	p["alive"] = false
	if _is_server_sim and _phase != PH_ENDED and _active_team_count() <= 1:
		_finish_match(_first_active_team())


func _finish_match(winner_tid: int) -> void:
	if _phase == PH_ENDED:
		return
	_phase = PH_ENDED
	_winner_team = winner_tid
	if winner_tid == 1 or winner_tid == 2:
		_team_scores[winner_tid] = 1

	var raw_scores: Dictionary = {}
	var alive_ids: Array = []
	for raw_nid in _players.keys():
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[raw_nid] as Dictionary
		var tid: int = int(p.get("team_id", 0))
		raw_scores[nid] = 1 if (winner_tid > 0 and tid == winner_tid) else 0
		if bool(p.get("connected", false)) and bool(p.get("alive", false)):
			alive_ids.append(nid)

	var final_scores: Dictionary = raw_scores
	if _team != null:
		final_scores = _team.sync_scores(raw_scores, alive_ids) as Dictionary
		_team.notify_round_win(final_scores, self)
		_team.mark_scores_applied(self)

	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_round_end.rpc(final_scores, _team_scores, winner_tid)

	if winner_tid == 1 or winner_tid == 2:
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
		"co": _cart_owner,
		"st": _surge_team,
		"sr": _surge_timer,
		"pa": _pulse_active,
		"pr": _pulse_remaining,
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
	_cart_owner = int(snap.get("co", _cart_owner))
	_surge_team = int(snap.get("st", _surge_team))
	_surge_timer = float(snap.get("sr", _surge_timer))
	_pulse_active = bool(snap.get("pa", _pulse_active))
	_pulse_remaining = float(snap.get("pr", _pulse_remaining))

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
				p["alive"] = bool(p["connected"])


@rpc("authority", "call_remote", "reliable")
func _rpc_round_end(final_scores: Dictionary, team_scores_snap: Dictionary = {}, winner_tid: int = 0) -> void:
	if _is_server_sim:
		return
	_phase = PH_ENDED
	_winner_team = winner_tid
	if not team_scores_snap.is_empty():
		_team_scores = team_scores_snap.duplicate()
	round_finished.emit(final_scores)


func _animate_visuals(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.tick(delta)

	if _camera != null and is_instance_valid(_camera) and _cam_base_pos != Vector3.ZERO:
		if _cam_shake > 0.001:
			_cam_shake = maxf(0.0, _cam_shake - delta * 1.4)
			var ox: float = sin(_srv_time * 57.0) * _cam_shake
			var oy: float = cos(_srv_time * 63.0) * _cam_shake * 0.7
			_camera.position = _cam_base_pos + Vector3(ox, oy, 0.0)
		elif _camera.position != _cam_base_pos:
			_camera.position = _cam_base_pos

	if _cart_root != null and is_instance_valid(_cart_root):
		_cart_root.position.x = lerpf(_cart_root.position.x, _cart_x, clampf(delta * 20.0, 0.0, 1.0))
		for raw_w in _cart_wheels:
			var w := raw_w as Node3D
			if w != null and is_instance_valid(w):
				w.rotate_z(-_cart_vel * delta * 1.8)

	if _cart_warhead_mat != null:
		var pulse_blink: float = 0.5 + 0.5 * sin(_srv_time * (14.0 if _match_phase >= 3 else 5.0))
		if _match_phase >= 3:
			_cart_warhead_mat.emission = Color(1.0, 0.18, 0.12)
			_cart_warhead_mat.emission_energy_multiplier = 1.2 + pulse_blink * 2.2
		elif _match_phase == 2:
			_cart_warhead_mat.emission = Color(1.0, 0.45, 0.12)
			_cart_warhead_mat.emission_energy_multiplier = 0.8 + pulse_blink * 1.0
		else:
			_cart_warhead_mat.emission = Color(0.9, 0.25, 0.15)
			_cart_warhead_mat.emission_energy_multiplier = 0.45

	if _push_aura_mat != null:
		if _cart_owner == 1:
			_push_aura_mat.albedo_color = Color(1.0, 0.30, 0.28, 0.36)
		elif _cart_owner == 2:
			_push_aura_mat.albedo_color = Color(0.26, 0.68, 1.0, 0.36)
		else:
			_push_aura_mat.albedo_color = Color(1.0, 0.84, 0.24, 0.28)

	if _pulse_ring_mesh != null and is_instance_valid(_pulse_ring_mesh):
		_pulse_ring_mesh.visible = _pulse_active
		if _pulse_active and _pulse_ring_mat != null:
			var t_prog: float = 1.0 - clampf(_pulse_remaining / maxf(0.01, float(C.PULSE_WARN_TIME)), 0.0, 1.0)
			var sc: float = lerpf(0.4, 1.0, t_prog)
			_pulse_ring_mesh.scale = Vector3(sc, 1.0, sc)
			_pulse_ring_mat.albedo_color = Color(1.0, 0.22, 0.18, 0.25 + t_prog * 0.55)

	for v_idx in range(_valves.size()):
		if not _valve_nodes.has(v_idx):
			continue
		var v: Dictionary = _valves[v_idx] as Dictionary
		var vn: Dictionary = _valve_nodes[v_idx] as Dictionary
		var rmat := vn.get("ring_mat", null) as StandardMaterial3D
		var pmat := vn.get("pipe_mat", null) as StandardMaterial3D
		var is_act: bool = bool(v["active"])
		if rmat != null:
			rmat.albedo_color = Color(0.35, 0.95, 0.55, 0.85) if is_act else Color(0.35, 0.40, 0.45, 0.30)
		if pmat != null:
			pmat.emission_energy_multiplier = 1.4 if is_act else 0.15

	for raw_led in _track_leds:
		var led: Dictionary = raw_led as Dictionary
		var lx: float = float(led.get("x", 0.0))
		var lmat := led.get("mat", null) as StandardMaterial3D
		if lmat != null:
			if lx <= _cart_x - 0.3:
				lmat.albedo_color = C.TEAM_COLORS[1] as Color
				lmat.emission = C.TEAM_COLORS[1] as Color
			elif lx >= _cart_x + 0.3:
				lmat.albedo_color = C.TEAM_COLORS[2] as Color
				lmat.emission = C.TEAM_COLORS[2] as Color
			else:
				lmat.albedo_color = Color(1.0, 0.86, 0.25)
				lmat.emission = Color(1.0, 0.86, 0.25)

	for tid in [1, 2]:
		var dmat := _door_lights.get(tid, null) as StandardMaterial3D
		if dmat != null:
			var door_x: float = -float(C.TRACK_HALF_LEN) if tid == 1 else float(C.TRACK_HALF_LEN)
			var near_door: bool = absf(_cart_x - door_x) <= 3.5
			var flash_freq: float = 14.0 if near_door else 3.0
			dmat.emission_energy_multiplier = 0.6 + (1.8 if near_door else 0.4) * (0.5 + 0.5 * sin(_srv_time * flash_freq))

	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		var pnode: Node3D = p.get("node", null) as Node3D
		if pnode == null or not is_instance_valid(pnode):
			continue
		pnode.visible = bool(p.get("connected", true))
		var target_pos: Vector3 = p["pos"] as Vector3
		var cur_rp: Vector3 = p.get("render_pos", target_pos) as Vector3
		var move_speed: float = cur_rp.distance_to(target_pos) / maxf(delta, 0.001)
		var next_rp: Vector3 = cur_rp.lerp(target_pos, clampf(delta * 18.0, 0.0, 1.0))
		p["render_pos"] = next_rp
		pnode.position = next_rp
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
		_hud_state_cache["cart_x"] = _cart_x
		_hud_state_cache["track_half"] = float(C.TRACK_HALF_LEN)
		_hud_state_cache["time_left"] = _time_remaining
		_hud_state_cache["phase"] = _match_phase
		_hud_state_cache["overtime"] = _overtime
		_hud_state_cache["surge_team"] = _surge_team
		_hud_state_cache["surge_timer"] = _surge_timer
		_hud_state_cache["prep_left"] = _prep_remaining
		_hud_state_cache["banner_text"] = ""
		_hud_state_cache["winner_team"] = _winner_team
		_hud_state_cache["red_count"] = _active_members_in_team(1)
		_hud_state_cache["blue_count"] = _active_members_in_team(2)
		_hud_state_cache["screenshot_mode"] = not _screenshot_path.is_empty()
		_hud.update_hud(_hud_state_cache)
