extends Node3D

## ============================================================================
## Core Heist / 能源搶奪戰 — Server-Authoritative Team-Only Minigame Stage
## ============================================================================

signal round_finished(scores: Dictionary)

const CONFIG_RES := "res://mods_core_heist/config.gd"
const MESHES_RES := "res://mods_core_heist/arena_meshes.gd"
const TEAM_RES := "res://mods_core_heist/team_support.gd"
const FX_POOL_RES := "res://mods_core_heist/fx_pool.gd"
const HUD_RES := "res://mods_core_heist/hud_ui.gd"
const AI_RES := "res://mods_core_heist/ai_controller.gd"
const SELF_TEST_RES := "res://mods_core_heist/self_test.gd"

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
var _cli_teams: int = 0
var _cli_per_team: int = 0
var _per_team_count: int = 2
var _is_server_sim: bool = true
var _local_net_id: int = 1

var _phase: int = PH_PREP
var _srv_time: float = 0.0
var _prep_remaining: float = 0.0
var _elapsed_time: float = 0.0
var _time_remaining: float = 75.0
var _last_countdown_sec: int = 4
var _map_seed: int = 20261123
var _rng := RandomNumberGenerator.new()
var _sync_accum: float = 0.0

var _team_count: int = 2
var _active_team_ids: Array = [1, 2]
var _vault_by_team: Dictionary = {}
var _arena_size: float = 24.0
var _arena_half: float = 12.0
var _base_positions: Array = []
var _pillars: Array = []
var _team_scores: Dictionary = {}
var _team_steal_bonus: Dictionary = {}

var _players: Dictionary = {}
var _client_inputs: Dictionary = {}
var _batteries: Array = []
var _battery_nodes: Array = []
var _resonance_pairs: Array = []
var _resonance_beams: Array = []

var _spawn_timer: float = 0.0
var _spawn_counter: int = 0
var _core1_warned: bool = false
var _core1_dropped: bool = false
var _core1_warn_timer: float = 0.0
var _core2_warned: bool = false
var _core2_dropped: bool = false
var _core2_warn_timer: float = 0.0
var _client_core_warn: bool = false
var _client_core_warn_z: float = 3.0
var _overdrive_announced: bool = false
var _warn_beacon_node: Node3D = null

var _arena_root: Node3D = null
var _bat_root: Node3D = null
var _fx_root: Node3D = null
var _player_root: Node3D = null
var _shader_layer: CanvasLayer = null
var _camera: Camera3D = null
var _vault_nodes: Dictionary = {}
var _dispenser_ring: Node3D = null
var _dispenser_ring_b: Node3D = null
var _conveyor_mat_l: StandardMaterial3D = null
var _conveyor_mat_r: StandardMaterial3D = null
var _monitor_timer: Label3D = null
var _monitor_phase: Label3D = null
var _last_crt_timer_text: String = ""
var _last_crt_phase_text: String = ""
var _bat_vis_cache: Array = []
var _cam_base_pos: Vector3 = Vector3.ZERO
var _cam_shake: float = 0.0
var _prev_action_pressed: bool = false
var _input_send_accum: float = 0.0
var _pending_client_action: bool = false
var _pck_mounted: bool = false

var _sfx_push: AudioStreamPlayer = null
var _sfx_ding: AudioStreamPlayer = null
var _sfx_beep: AudioStreamPlayer = null
var _sfx_warn: AudioStreamPlayer = null
var _ambience: AudioStreamPlayer = null


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
		if arg == "--smoke-test":
			_is_self_test = true
			var st_cls2 = _load_script_res(SELF_TEST_RES, "self_test.gd")
			if st_cls2 != null:
				_self_test_runner = st_cls2.new()
				_self_test_runner.run_smoke_test(self)
			return
		if arg.begins_with("--capture-screenshot="):
			_screenshot_path = arg.substr("--capture-screenshot=".length())
		elif arg.begins_with("--teams="):
			_cli_teams = clampi(int(arg.substr("--teams=".length())), 2, 4)
		elif arg.begins_with("--per-team="):
			_cli_per_team = clampi(int(arg.substr("--per-team=".length())), 1, 4)

	if not _screenshot_path.is_empty():
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var shot_teams: int = _cli_teams if _cli_teams >= 2 else 4
		var shot_per_team: int = _cli_per_team if _cli_per_team >= 1 else 2
		_per_team_count = shot_per_team
		var demo_roster: Array = _build_standalone_roster(shot_teams, shot_per_team)
		_setup_match_local(0, 20261123, demo_roster, true)
		var st_cls3 = _load_script_res(SELF_TEST_RES, "self_test.gd")
		if st_cls3 != null:
			_self_test_runner = st_cls3.new()
			_self_test_runner.stage_screenshot_action(self)
		call_deferred("_capture_and_quit")
		return

	if get_parent() == get_tree().root:
		_standalone_mode = true
		_is_server_sim = true
		_mount_preview_pck()
		var init_teams: int = _cli_teams if _cli_teams >= 2 else 2
		var init_per_team: int = _cli_per_team if _cli_per_team >= 1 else 2
		_per_team_count = init_per_team
		var roster: Array = _build_standalone_roster(init_teams, init_per_team)
		_setup_match_local(0, 20261123, roster, false)


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
			_setup_match_local(0, _map_seed + 1, _build_standalone_roster(_team_count, _per_team_count), false)
		elif kc == KEY_F2:
			_per_team_count = 2
			_setup_match_local(0, 20261123, _build_standalone_roster(2, 2), false)
		elif kc == KEY_F3:
			_per_team_count = 2
			_setup_match_local(0, 20261123, _build_standalone_roster(3, 2), false)
		elif kc == KEY_F4:
			_per_team_count = 2
			_setup_match_local(0, 20261123, _build_standalone_roster(4, 2), false)
		elif kc == KEY_F5:
			_per_team_count = 4
			_setup_match_local(0, 20261123, _build_standalone_roster(2, 4), false)


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


const SCREENSHOT_COSMETICS := [
	["hard_hat", "sunglasses"],
	["tophat", ""],
	["traffic_cone", "reading_glasses"],
	["drill_sgt_hat", "sunglasses"],
	["maska_helmet", ""],
	["cap_blade", "sunglasses"],
	["beer_hat", ""],
	["rubiks_cube", "reading_glasses"],
]

const SCREENSHOT_NAMES_TW := {
	1: ["紅心活塞", "鍋爐紅醬", "赤焰扳手", "高熱紅管"],
	2: ["高壓藍鴨", "發條藍仔", "磁軌藍星", "冷卻藍泵"],
	3: ["電容綠寶", "齒輪綠豆", "螢光綠帽", "電弧綠葉"],
	4: ["火花阿金", "熔爐黃王", "焊槍阿黃", "高爐金匠"],
}

const SCREENSHOT_NAMES_CN := {
	1: ["红心活塞", "锅炉红酱", "赤焰扳手", "高热红管"],
	2: ["高压蓝鸭", "发条蓝仔", "磁轨蓝星", "冷却蓝泵"],
	3: ["电容绿宝", "齿轮绿豆", "荧光绿帽", "电弧绿叶"],
	4: ["火花阿金", "熔炉黄王", "焊枪阿黄", "高炉金匠"],
}

const SCREENSHOT_NAMES_EN := {
	1: ["Red Piston", "Boiler Red", "Rust Wrench", "Valve Red"],
	2: ["Volt Blue", "Gear Blue", "Coil Blue", "Cryo Blue"],
	3: ["Coil Green", "Bolt Green", "Neon Green", "Arc Green"],
	4: ["Spark Gold", "Furnace King", "Weld Gold", "Forge King"],
}


func _screenshot_nickname(team_id: int, member_idx: int, fallback_nid: int) -> String:
	var low: String = TranslationServer.get_locale().to_lower()
	var table: Dictionary = SCREENSHOT_NAMES_EN
	if low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo"):
		table = SCREENSHOT_NAMES_TW
	elif low.begins_with("zh") or low == "zhs":
		table = SCREENSHOT_NAMES_CN
	var pool: Array = table.get(team_id, []) as Array
	if member_idx >= 0 and member_idx < pool.size():
		return str(pool[member_idx])
	return "Bot%d" % fallback_nid


func _build_standalone_roster(teams: int, per_team: int) -> Array:
	var roster: Array = []
	var idx: int = 0
	var is_shot: bool = not _screenshot_path.is_empty()
	for t in range(1, teams + 1):
		for m in range(per_team):
			var nid: int = idx + 1
			var nick: String = _screenshot_nickname(t, m, nid) if is_shot else ("Bot%d" % nid if idx > 0 else "Player1")
			var custom: Array = (SCREENSHOT_COSMETICS[idx % SCREENSHOT_COSMETICS.size()] as Array).duplicate() if is_shot else []
			roster.append({
				"id": idx,
				"network_id": nid,
				"nickname": nick,
				"team_id": t,
				"is_ai": idx > 0,
				"customization": custom,
			})
			idx += 1
	return roster


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
	for child_arr in [_arena_root, _bat_root, _fx_root, _player_root]:
		if child_arr != null and is_instance_valid(child_arr):
			child_arr.queue_free()
	_arena_root = null
	_bat_root = null
	_fx_root = null
	_player_root = null
	_vault_nodes.clear()
	_battery_nodes.clear()
	_resonance_beams.clear()
	_warn_beacon_node = null
	_monitor_timer = null
	_monitor_phase = null
	_last_crt_timer_text = ""
	_last_crt_phase_text = ""


func _setup_match_local(round_idx: int, seed_val: int, roster: Array, all_ai: bool = false) -> void:
	_load_helpers()
	_clear_scene_children()
	_map_seed = seed_val + round_idx * 31
	_rng.seed = _map_seed

	_phase = PH_PREP
	_srv_time = 0.0
	_prep_remaining = float(C.PREP_DURATION)
	_elapsed_time = 0.0
	_time_remaining = float(C.MATCH_DURATION)
	_last_countdown_sec = 4
	_sync_accum = 0.0
	_spawn_timer = 0.4
	_spawn_counter = 0
	_core1_warned = false
	_core1_dropped = false
	_core1_warn_timer = 0.0
	_core2_warned = false
	_core2_dropped = false
	_core2_warn_timer = 0.0
	_client_core_warn = false
	_client_core_warn_z = 3.0
	_overdrive_announced = false
	_players.clear()
	_client_inputs.clear()
	_batteries.clear()
	_bat_vis_cache.clear()
	_resonance_pairs.clear()
	_team_scores.clear()
	_team_steal_bonus.clear()
	_vault_by_team.clear()
	_cam_shake = 0.0

	if _team != null:
		_team.begin_match(self, roster)

	# Determine sorted active team IDs (supports sparse IDs such as [1, 3] or [2, 4])
	var distinct_teams: Dictionary = {}
	for raw_r in roster:
		if not (raw_r is Dictionary):
			continue
		var r: Dictionary = raw_r as Dictionary
		var nid: int = int(r.get("network_id", 0))
		var tid: int = int(r.get("team_id", 0))
		if tid <= 0 and _team != null:
			tid = int(_team.player_team(nid))
		if tid > 0:
			distinct_teams[tid] = true
	_active_team_ids = distinct_teams.keys()
	_active_team_ids.sort()
	if _active_team_ids.size() < 2:
		_active_team_ids = [1, 2]
	elif _active_team_ids.size() > 4:
		_active_team_ids = _active_team_ids.slice(0, 4)
	_team_count = _active_team_ids.size()
	_arena_size = float(C.arena_size_for_teams(_team_count))
	_arena_half = _arena_size * 0.5
	_base_positions = C.base_positions_for_teams(_team_count)
	_pillars = C.pillar_positions(_arena_size)

	for i in range(_active_team_ids.size()):
		var tid: int = int(_active_team_ids[i])
		_vault_by_team[tid] = _base_positions[i] as Vector2
		_team_scores[tid] = 0
		_team_steal_bonus[tid] = 0

	# Create scene roots
	_arena_root = Node3D.new()
	_arena_root.name = "ArenaRoot"
	add_child(_arena_root)
	_bat_root = Node3D.new()
	_bat_root.name = "BatteryRoot"
	add_child(_bat_root)
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
			var arena_info: Dictionary = M.build_arena(_arena_root, _active_team_ids, C, _vault_by_team, _pillars)
			_vault_nodes = arena_info.get("vault_nodes", {}) as Dictionary
			_dispenser_ring = arena_info.get("dispenser_ring", null) as Node3D
			_dispenser_ring_b = arena_info.get("dispenser_ring_b", null) as Node3D
			_conveyor_mat_l = arena_info.get("conveyor_mat_l", null) as StandardMaterial3D
			_conveyor_mat_r = arena_info.get("conveyor_mat_r", null) as StandardMaterial3D
			_monitor_timer = arena_info.get("monitor_timer", null) as Label3D
			_monitor_phase = arena_info.get("monitor_phase", null) as Label3D
		if _fx_pool != null:
			_fx_pool.init_pools(_fx_root, not _screenshot_path.is_empty())
			for _b in range(4):
				var beam := _fx_pool.acquire("resonance", 0.0) as Node3D
				if beam != null:
					beam.visible = false
					_resonance_beams.append(beam)
			_warn_beacon_node = _fx_pool.acquire("warn", 0.0) as Node3D
			if _warn_beacon_node != null:
				_warn_beacon_node.visible = false
		if _hud != null:
			_hud.build_hud(self, _team, _standalone_mode)
			_hud.hide_results()
			_hud.set_standalone_hint(_standalone_mode)
		_update_crt_monitor()

	_init_battery_pool()
	_spawn_players(roster, all_ai)


func _ensure_environment_and_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.name = "ArenaCamera"
		_camera.fov = 45.0
		_camera.current = true
		add_child(_camera)
	if _team_count <= 2:
		_camera.position = Vector3(0.0, 20.6, 25.0)
		_camera.look_at(Vector3(0.0, 0.2, 1.1), Vector3.UP)
	else:
		_camera.position = Vector3(0.0, 23.8, 29.0)
		_camera.look_at(Vector3(0.0, 0.2, 1.3), Vector3.UP)
	_cam_base_pos = _camera.position

	if get_node_or_null("WorldEnv") == null:
		# Authentic Machine Party warm low-saturation dark industrial workshop atmosphere.
		var env_node := WorldEnvironment.new()
		env_node.name = "WorldEnv"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.04, 0.04, 0.05)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.42, 0.36, 0.32)
		env.ambient_light_energy = 0.86
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.08
		env.adjustment_contrast = 1.12
		env.adjustment_saturation = 0.86
		env.glow_enabled = true
		env.glow_intensity = 0.42
		env.glow_bloom = 0.16
		env_node.environment = env
		add_child(env_node)

	if get_node_or_null("KeyLight") == null:
		var sun := DirectionalLight3D.new()
		sun.name = "KeyLight"
		sun.rotation_degrees = Vector3(-56.0, 22.0, 0.0)
		sun.light_color = Color(1.0, 0.94, 0.86)
		sun.light_energy = 1.25
		sun.shadow_enabled = true
		add_child(sun)

	if get_node_or_null("FillLight") == null:
		var fill := DirectionalLight3D.new()
		fill.name = "FillLight"
		fill.rotation_degrees = Vector3(-32.0, -145.0, 0.0)
		fill.light_color = Color(0.84, 0.80, 0.75)
		fill.light_energy = 0.28
		add_child(fill)

	_setup_post_fx()


func _setup_post_fx() -> void:
	if _is_self_test or (_shader_layer != null and is_instance_valid(_shader_layer)) or M == null:
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
		vm.set_shader_parameter("radius", 0.96)
		vm.set_shader_parameter("softness", 0.45)
		vm.set_shader_parameter("intensity", 1.38)
		vm.set_shader_parameter("contrast", 1.35)
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


func _init_battery_pool() -> void:
	for i in range(int(C.BATTERY_POOL_SIZE)):
		_batteries.append({
			"idx": i,
			"active": false,
			"type": int(C.CELL_STANDARD),
			"state": int(C.BAT_LOOSE),
			"pos": Vector3.ZERO,
			"carrier_id": 0,
			"vault_team": 0,
			"stolen_from_team": 0,
			"lock_timer": 0.0,
			"perm_locked": false,
			"throw_start": Vector2.ZERO,
			"throw_end": Vector2.ZERO,
			"throw_t": 0.0,
			"thrower_id": 0,
		})
		if not _is_self_test and M != null and _bat_root != null:
			var bn: Node3D = M.build_battery_node(C)
			bn.name = "Bat_%d" % i
			_bat_root.add_child(bn)
			_battery_nodes.append(bn)
		else:
			_battery_nodes.append(null)
		_bat_vis_cache.append({"type": -1, "locked": false, "perm": false})


func _spawn_players(roster: Array, all_ai: bool) -> void:
	var team_members: Dictionary = {}
	for raw_r in roster:
		if not (raw_r is Dictionary):
			continue
		var r: Dictionary = raw_r as Dictionary
		var nid: int = int(r.get("network_id", 0))
		var tid: int = int(r.get("team_id", 0))
		if tid <= 0 and _team != null:
			tid = int(_team.player_team(nid))
		if tid <= 0:
			tid = int(_active_team_ids[absi(nid) % _active_team_ids.size()])
		if not team_members.has(tid):
			team_members[tid] = []
		(team_members[tid] as Array).append(r)

	var placed_spawns: Array = []
	for tid_raw in team_members.keys():
		var tid: int = int(tid_raw)
		var members: Array = team_members[tid_raw] as Array
		var base2: Vector2 = _vault_by_team.get(tid, _base_positions[0]) as Vector2
		var to_center: Vector2 = (-base2).normalized()
		if to_center.length() < 0.01:
			to_center = Vector2(0.0, 1.0)
		var perp := Vector2(-to_center.y, to_center.x)
		var front_dist: float = 2.65 if _team_count <= 2 else 2.80
		var spacing: float = 1.35
		var front_center: Vector2 = base2 + to_center * front_dist

		for m_idx in range(members.size()):
			var r: Dictionary = members[m_idx] as Dictionary
			var nid: int = int(r.get("network_id", 0))
			var offset: float = (float(m_idx) - float(members.size() - 1) * 0.5) * spacing
			var spawn2: Vector2 = front_center + perp * offset
			# Push cleanly outside vault ring, pillars, walls, and prior spawn positions
			var from_vault: Vector2 = spawn2 - base2
			var min_vault: float = float(C.VAULT_RADIUS) + float(C.PLAYER_RADIUS) * 0.75
			if from_vault.length() < min_vault:
				spawn2 = base2 + (from_vault.normalized() if from_vault.length() > 0.01 else to_center) * min_vault
			spawn2 = C.resolve_arena_obstacles(spawn2, float(C.PLAYER_RADIUS) + 0.05, _arena_half, _pillars)
			for prev_raw in placed_spawns:
				var prev2: Vector2 = prev_raw as Vector2
				var sep: Vector2 = spawn2 - prev2
				if sep.length() < float(C.PLAYER_RADIUS) * 2.2:
					var push_dir: Vector2 = sep.normalized() if sep.length() > 0.01 else perp
					spawn2 = C.resolve_arena_obstacles(prev2 + push_dir * (float(C.PLAYER_RADIUS) * 2.25), float(C.PLAYER_RADIUS) + 0.05, _arena_half, _pillars)
			placed_spawns.append(spawn2)
			var spawn3 := Vector3(spawn2.x, 0.0, spawn2.y)
			var is_ai: bool = all_ai or bool(r.get("is_ai", nid < 0))
			var pnode: Node3D = null
			var rig_node: Node3D = null
			var name_lbl: Label3D = null
			var anim_player: AnimationPlayer = null
			if not _is_self_test and M != null and _player_root != null:
				var vis: Dictionary = M.build_player_visual(
					nid, str(r.get("nickname", "P%d" % nid)), tid, r.get("customization", []) as Array, _team, C
				)
				pnode = vis.get("root", null) as Node3D
				rig_node = vis.get("rig", null) as Node3D
				name_lbl = vis.get("name_label", null) as Label3D
				anim_player = vis.get("anim_player", null) as AnimationPlayer
				if pnode != null:
					pnode.position = spawn3
					_player_root.add_child(pnode)
					if not is_ai and nid == _local_net_id:
						pnode.set_meta(&"mpm_local_player", true)

			_players[nid] = {
				"network_id": nid,
				"nickname": str(r.get("nickname", "P%d" % nid)),
				"team_id": tid,
				"is_ai": is_ai,
				"connected": true,
				"alive": true,
				"pos": spawn3,
				"render_pos": spawn3,
				"facing": to_center,
				"carried_battery": -1,
				"stun_timer": 0.0,
				"shove_cooldown": 0.0,
				"shove_anim_timer": 0.0,
				"knockback_vel": Vector2.ZERO,
				"has_resonance": false,
				"node": pnode,
				"rig": rig_node,
				"name_label": name_lbl,
				"anim_player": anim_player,
			}


func _process(delta: float) -> void:
	if _is_self_test or not _screenshot_path.is_empty():
		return
	var dt: float = minf(delta, 0.05)
	_srv_time += dt
	if _is_server_sim:
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
	if _fx_pool != null:
		_fx_pool.clear()


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
				if arg > 0:
					_hud.show_countdown(str(arg), Color(0.76, 1.0, 0.72), 0.90)
				else:
					_hud.show_countdown("GO!", Color(1.0, 0.90, 0.34), 0.75)
			if arg > 0 and _sfx_beep != null:
				_sfx_beep.play()
			elif arg <= 0 and _sfx_ding != null:
				_sfx_ding.play()
		"core":
			if _hud != null:
				_hud.show_banner(_hud.pick_loc("HEAVY CORE INCOMING!", "重型反应炉核心即将空投!", "重型反應爐核心即將空投!"), Color(1.0, 0.45, 0.16), 2.2)
			if _sfx_warn != null:
				_sfx_warn.play()
		"overdrive":
			if _hud != null:
				_hud.show_banner(_hud.pick_loc("OVERDRIVE! 2x SPAWN & +1 STEAL BONUS", "过载冲刺! 产线加倍 + 偷家额外 +1 分", "過載衝刺! 產線加倍 + 偷家額外 +1 分"), Color(1.0, 0.85, 0.25), 2.5)
			if _sfx_warn != null:
				_sfx_warn.play()
		"win":
			if _hud != null and _team != null:
				_hud.show_banner(_team.team_win_banner(arg), C.TEAM_COLORS.get(arg, Color.WHITE) as Color, 4.0)
			if _sfx_ding != null:
				_sfx_ding.play()
		"draw":
			if _hud != null:
				_hud.show_banner(_hud.draw_banner(), Color(0.92, 0.92, 0.96), 4.0)
			if _sfx_ding != null:
				_sfx_ding.play()


func _emit_fx(kind: String, pos: Vector3, scale_val: float) -> void:
	if _is_self_test:
		return
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_fx_event.rpc(kind, pos, scale_val)
	else:
		_rpc_fx_event(kind, pos, scale_val)


@rpc("authority", "call_local", "reliable")
func _rpc_fx_event(kind: String, pos: Vector3, scale_val: float) -> void:
	if _is_self_test:
		return
	if _fx_pool != null:
		_fx_pool.spawn_burst(kind, pos, 0.35 if kind == "deposit" else 0.25, scale_val)
	if kind == "shove":
		if _sfx_push != null:
			_sfx_push.play()
		_cam_shake = maxf(_cam_shake, 0.14)
	elif kind == "deposit" and _sfx_ding != null:
		_sfx_ding.play()


func _emit_popup(pos: Vector3, text: String, color: Color) -> void:
	if _is_self_test:
		return
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_popup_event.rpc(pos, text, color)
	else:
		_rpc_popup_event(pos, text, color)


@rpc("authority", "call_local", "reliable")
func _rpc_popup_event(pos: Vector3, text: String, color: Color) -> void:
	if _is_self_test or _fx_pool == null:
		return
	_fx_pool.spawn_popup(pos, text, color)


func _step_prep(delta: float) -> void:
	_prep_remaining = maxf(0.0, _prep_remaining - delta)
	var sec: int = ceili(_prep_remaining)
	if sec != _last_countdown_sec:
		_last_countdown_sec = sec
		_emit_banner("prep", sec)
	if _prep_remaining <= 0.0:
		_phase = PH_LIVE
		# Spawn initial pair of Standard batteries on conveyor outputs
		_spawn_battery(int(C.CELL_STANDARD), Vector3(-2.6, 0.0, 0.0))
		_spawn_battery(int(C.CELL_STANDARD), Vector3(2.6, 0.0, 0.0))


func _step_simulation(delta: float) -> void:
	_elapsed_time += delta
	_time_remaining = maxf(0.0, float(C.MATCH_DURATION) - _elapsed_time)

	_step_phase_events(delta)
	_step_spawner(delta)
	_update_resonance_state()
	_step_players(delta)
	_step_batteries(delta)
	_recompute_team_scores()

	if _time_remaining <= 0.0 or _active_team_count() <= 1:
		_finish_match()


func _step_phase_events(delta: float) -> void:
	if not _core1_warned and _elapsed_time >= float(C.PHASE2_START):
		_core1_warned = true
		_core1_warn_timer = float(C.CORE_WARN_DURATION)
		_emit_banner("core", 1)
	if _core1_warn_timer > 0.0:
		_core1_warn_timer -= delta
		if _core1_warn_timer <= 0.0 and not _core1_dropped:
			_core1_dropped = true
			_spawn_battery(int(C.CELL_CORE), Vector3(0.0, 0.0, 3.0))

	if not _overdrive_announced and _elapsed_time >= float(C.PHASE3_START):
		_overdrive_announced = true
		_emit_banner("overdrive", 0)

	if not _core2_warned and _elapsed_time >= float(C.SECOND_CORE_TIME):
		_core2_warned = true
		_core2_warn_timer = float(C.CORE_WARN_DURATION)
		_emit_banner("core", 2)
	if _core2_warn_timer > 0.0:
		_core2_warn_timer -= delta
		if _core2_warn_timer <= 0.0 and not _core2_dropped:
			_core2_dropped = true
			_spawn_battery(int(C.CELL_CORE), Vector3(0.0, 0.0, -3.0))


func _step_spawner(delta: float) -> void:
	var player_count: int = maxi(2, _players.size())
	var is_overdrive: bool = _elapsed_time >= float(C.PHASE3_START)
	var interval: float = float(C.spawn_interval(is_overdrive, player_count))
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = interval
	var loose_std: int = 0
	var loose_gold: int = 0
	var active_total: int = 0
	for raw_b in _batteries:
		var b: Dictionary = raw_b as Dictionary
		if bool(b["active"]):
			active_total += 1
			if int(b["state"]) == int(C.BAT_LOOSE):
				if int(b["type"]) == int(C.CELL_STANDARD):
					loose_std += 1
				elif int(b["type"]) == int(C.CELL_GOLD):
					loose_gold += 1

	# Always reserve 2 slots in the fixed pool for Heavy Reactor Cores #1 and #2.
	if active_total >= int(C.BATTERY_POOL_SIZE) - 2:
		return

	var cap_std: int = int(C.max_loose_standard(_team_count, player_count))
	var cap_gold: int = int(C.max_loose_gold(_team_count, player_count))
	_spawn_counter += 1
	var side: float = -1.0 if (_spawn_counter % 2 == 0) else 1.0
	var spawn_pos := Vector3(side * 2.1, 0.0, _rng.randf_range(-0.6, 0.6))
	if _spawn_counter % 3 == 0 and loose_gold < cap_gold:
		_spawn_battery(int(C.CELL_GOLD), spawn_pos)
	elif loose_std < cap_std:
		_spawn_battery(int(C.CELL_STANDARD), spawn_pos)


func _spawn_battery(cell_type: int, pos: Vector3) -> int:
	for raw_b in _batteries:
		var b: Dictionary = raw_b as Dictionary
		if not bool(b["active"]):
			b["active"] = true
			b["type"] = cell_type
			b["state"] = int(C.BAT_LOOSE)
			b["pos"] = pos
			b["carrier_id"] = 0
			b["vault_team"] = 0
			b["stolen_from_team"] = 0
			b["lock_timer"] = 0.0
			b["perm_locked"] = false
			b["throw_t"] = 0.0
			b["thrower_id"] = 0
			return int(b["idx"])
	return -1


func _active_members_in_team(tid: int) -> int:
	var count: int = 0
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if bool(p.get("connected", true)) and int(p.get("team_id", 0)) == tid:
			count += 1
	return count


func _active_team_count() -> int:
	var seen: Dictionary = {}
	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if bool(p.get("connected", true)):
			var tid: int = int(p.get("team_id", 0))
			if tid > 0:
				seen[tid] = true
	return seen.size()


func _update_resonance_state() -> void:
	_resonance_pairs.clear()
	for raw_p in _players.values():
		(raw_p as Dictionary)["has_resonance"] = false

	for raw_p in _players.values():
		var p: Dictionary = raw_p as Dictionary
		if not bool(p.get("connected", true)):
			continue
		var b_idx: int = int(p.get("carried_battery", -1))
		if b_idx < 0 or b_idx >= _batteries.size():
			continue
		var bat: Dictionary = _batteries[b_idx] as Dictionary
		if int(bat["type"]) != int(C.CELL_CORE):
			continue
		var my_id: int = int(p["network_id"])
		var my_team: int = int(p["team_id"])
		var my_pos: Vector3 = p["pos"] as Vector3
		for raw_other in _players.values():
			var other: Dictionary = raw_other as Dictionary
			if not bool(other.get("connected", true)) or float(other.get("stun_timer", 0.0)) > 0.0:
				continue
			var oid: int = int(other["network_id"])
			if oid == my_id or int(other["team_id"]) != my_team:
				continue
			if my_pos.distance_to(other["pos"] as Vector3) <= float(C.RESONANCE_RADIUS):
				p["has_resonance"] = true
				_resonance_pairs.append([my_id, oid])
				break


func _step_players(delta: float) -> void:
	var sorted_ids: Array = _players.keys()
	sorted_ids.sort()
	for raw_nid in sorted_ids:
		var nid: int = int(raw_nid)
		var p: Dictionary = _players[nid] as Dictionary
		if not bool(p.get("connected", true)):
			continue

		p["shove_cooldown"] = maxf(0.0, float(p.get("shove_cooldown", 0.0)) - delta)
		p["shove_anim_timer"] = maxf(0.0, float(p.get("shove_anim_timer", 0.0)) - delta)
		var stun: float = float(p.get("stun_timer", 0.0))
		if stun > 0.0:
			p["stun_timer"] = maxf(0.0, stun - delta)

		var inp: Dictionary = {"move": Vector2.ZERO, "action": false}
		if bool(p.get("is_ai", false)):
			if _ai_ctrl != null:
				inp = _ai_ctrl.compute_input(self, p, delta, false) as Dictionary
		elif nid == _local_net_id:
			inp = _read_local_input()
		else:
			inp = _client_inputs.get(nid, {"move": Vector2.ZERO, "action": false}) as Dictionary
			_client_inputs[nid] = {"move": inp.get("move", Vector2.ZERO), "action": false}

		var mv: Vector2 = (inp.get("move", Vector2.ZERO) as Vector2).limit_length(1.0)
		var action_pressed: bool = bool(inp.get("action", false))
		var pos3: Vector3 = p["pos"] as Vector3
		var pos2 := Vector2(pos3.x, pos3.z)

		var kb: Vector2 = p.get("knockback_vel", Vector2.ZERO) as Vector2
		if kb.length() > 0.05:
			pos2 += kb * delta
			p["knockback_vel"] = kb.move_toward(Vector2.ZERO, 24.0 * delta)

		if float(p["stun_timer"]) <= 0.0 and mv.length() > 0.05:
			var facing: Vector2 = mv.normalized()
			p["facing"] = facing
			var mult: float = 1.0
			var b_idx: int = int(p.get("carried_battery", -1))
			if b_idx >= 0 and b_idx < _batteries.size():
				var bat: Dictionary = _batteries[b_idx] as Dictionary
				var solo_team: bool = _active_members_in_team(int(p["team_id"])) <= 1
				mult = float(C.battery_speed_mult(int(bat["type"]), bool(p.get("has_resonance", false)), solo_team))
			pos2 += facing * float(C.BASE_MOVE_SPEED) * mult * delta

		pos2 = C.resolve_arena_obstacles(pos2, float(C.PLAYER_RADIUS), _arena_half, _pillars)
		p["pos"] = Vector3(pos2.x, 0.0, pos2.y)

		if float(p["stun_timer"]) <= 0.0 and action_pressed:
			var b_idx: int = int(p.get("carried_battery", -1))
			if b_idx >= 0:
				_throw_battery(nid, b_idx)
			elif float(p["shove_cooldown"]) <= 0.0:
				_perform_shove(nid)

		# Auto-pickup loose or unlocked enemy vault battery
		if float(p["stun_timer"]) <= 0.0 and int(p.get("carried_battery", -1)) < 0:
			_try_auto_pickup(nid)
		elif int(p.get("carried_battery", -1)) >= 0:
			_check_walk_in_deposit(nid)


func _perform_shove(attacker_id: int) -> void:
	var att: Dictionary = _players[attacker_id] as Dictionary
	att["shove_cooldown"] = float(C.SHOVE_COOLDOWN)
	att["shove_anim_timer"] = 0.30
	var ap3: Vector3 = att["pos"] as Vector3
	var ap2 := Vector2(ap3.x, ap3.z)
	var facing: Vector2 = (att.get("facing", Vector2(0.0, 1.0)) as Vector2).normalized()
	var att_team: int = int(att["team_id"])

	_emit_fx("shove", ap3 + Vector3(facing.x * 0.9, 0.3, facing.y * 0.9), 1.0)

	for raw_nid in _players.keys():
		var tid_nid: int = int(raw_nid)
		if tid_nid == attacker_id:
			continue
		if _team != null and bool(_team.are_teammates(attacker_id, tid_nid)):
			continue
		var target: Dictionary = _players[tid_nid] as Dictionary
		if not bool(target.get("connected", true)) or int(target["team_id"]) == att_team:
			continue
		var tp3: Vector3 = target["pos"] as Vector3
		var tp2 := Vector2(tp3.x, tp3.z)
		var diff: Vector2 = tp2 - ap2
		var dist: float = diff.length()
		if dist > float(C.SHOVE_RANGE) or dist < 0.001:
			continue
		var dir: Vector2 = diff / dist
		if facing.dot(dir) < float(C.SHOVE_COS_HALF):
			continue

		target["stun_timer"] = float(C.STUN_DURATION)
		target["knockback_vel"] = dir * float(C.SHOVE_IMPULSE)
		var tb_idx: int = int(target.get("carried_battery", -1))
		if tb_idx >= 0 and not bool(target.get("has_resonance", false)):
			_drop_battery(tid_nid, tb_idx)


func _drop_battery(player_id: int, b_idx: int) -> void:
	if not _players.has(player_id) or b_idx < 0 or b_idx >= _batteries.size():
		return
	var p: Dictionary = _players[player_id] as Dictionary
	p["carried_battery"] = -1
	var bat: Dictionary = _batteries[b_idx] as Dictionary
	var p3: Vector3 = p["pos"] as Vector3
	var f: Vector2 = p.get("facing", Vector2(0.0, 1.0)) as Vector2
	var drop2: Vector2 = C.resolve_arena_obstacles(Vector2(p3.x, p3.z) + f * 0.75, 0.35, _arena_half, _pillars)
	bat["state"] = int(C.BAT_LOOSE)
	bat["carrier_id"] = 0
	bat["pos"] = Vector3(drop2.x, 0.0, drop2.y)


func _throw_battery(player_id: int, b_idx: int) -> void:
	if not _players.has(player_id) or b_idx < 0 or b_idx >= _batteries.size():
		return
	var p: Dictionary = _players[player_id] as Dictionary
	p["carried_battery"] = -1
	p["shove_anim_timer"] = 0.26
	var p3: Vector3 = p["pos"] as Vector3
	var start2 := Vector2(p3.x, p3.z)
	var facing: Vector2 = (p.get("facing", Vector2(0.0, 1.0)) as Vector2).normalized()
	var end2: Vector2 = C.resolve_arena_obstacles(start2 + facing * float(C.THROW_DISTANCE), 0.35, _arena_half, _pillars)
	var bat: Dictionary = _batteries[b_idx] as Dictionary
	bat["state"] = int(C.BAT_THROWN)
	bat["carrier_id"] = 0
	bat["throw_start"] = start2
	bat["throw_end"] = end2
	bat["throw_t"] = 0.0
	bat["thrower_id"] = player_id


func _try_auto_pickup(player_id: int) -> void:
	var p: Dictionary = _players[player_id] as Dictionary
	var my_team: int = int(p["team_id"])
	var p3: Vector3 = p["pos"] as Vector3
	var p2 := Vector2(p3.x, p3.z)

	var best_idx: int = -1
	var best_score: int = -1
	var best_dist: float = 999.0

	for raw_b in _batteries:
		var b: Dictionary = raw_b as Dictionary
		if not bool(b["active"]):
			continue
		var st: int = int(b["state"])
		if st != int(C.BAT_LOOSE) and st != int(C.BAT_DEPOSITED):
			continue
		if st == int(C.BAT_DEPOSITED):
			if int(b["vault_team"]) == my_team or bool(b["perm_locked"]) or float(b["lock_timer"]) > 0.0:
				continue
		var bp3: Vector3 = b["pos"] as Vector3
		var d: float = p2.distance_to(Vector2(bp3.x, bp3.z))
		if d > float(C.PICKUP_RADIUS):
			continue
		var pts: int = int(C.battery_points(int(b["type"])))
		if pts > best_score or (pts == best_score and d < best_dist):
			best_score = pts
			best_dist = d
			best_idx = int(b["idx"])

	if best_idx >= 0:
		var chosen: Dictionary = _batteries[best_idx] as Dictionary
		if int(chosen["state"]) == int(C.BAT_DEPOSITED):
			chosen["stolen_from_team"] = int(chosen["vault_team"])
			chosen["vault_team"] = 0
		chosen["state"] = int(C.BAT_CARRIED)
		chosen["carrier_id"] = player_id
		p["carried_battery"] = best_idx


func _check_walk_in_deposit(player_id: int) -> void:
	var p: Dictionary = _players[player_id] as Dictionary
	var my_team: int = int(p["team_id"])
	var b_idx: int = int(p.get("carried_battery", -1))
	if b_idx < 0 or not _vault_by_team.has(my_team):
		return
	var vault2: Vector2 = _vault_by_team[my_team] as Vector2
	var p3: Vector3 = p["pos"] as Vector3
	if Vector2(p3.x, p3.z).distance_to(vault2) <= float(C.VAULT_RADIUS) * 0.88:
		p["carried_battery"] = -1
		_deposit_battery(b_idx, my_team)


func _deposit_battery(b_idx: int, team_id: int) -> void:
	var bat: Dictionary = _batteries[b_idx] as Dictionary
	var vault2: Vector2 = _vault_by_team.get(team_id, _base_positions[0]) as Vector2
	bat["state"] = int(C.BAT_DEPOSITED)
	bat["carrier_id"] = 0
	bat["vault_team"] = team_id
	var is_core: bool = int(bat["type"]) == int(C.CELL_CORE)
	bat["perm_locked"] = is_core
	bat["lock_timer"] = 0.0 if is_core else float(C.VAULT_LOCK_DURATION)

	# Count existing batteries in this vault to arrange neatly
	var slot_idx: int = 0
	for raw_b in _batteries:
		var ob: Dictionary = raw_b as Dictionary
		if bool(ob["active"]) and int(ob["state"]) == int(C.BAT_DEPOSITED) and int(ob["vault_team"]) == team_id and int(ob["idx"]) != b_idx:
			slot_idx += 1
	var angle: float = float(slot_idx) * 0.85
	var rad: float = 0.75 if slot_idx > 0 else 0.0
	bat["pos"] = Vector3(vault2.x + cos(angle) * rad, 0.15, vault2.y + sin(angle) * rad)

	var steal_bonus_hit: bool = false
	if _elapsed_time >= float(C.PHASE3_START):
		var stolen_from: int = int(bat.get("stolen_from_team", 0))
		if stolen_from > 0 and stolen_from != team_id:
			_team_steal_bonus[team_id] = int(_team_steal_bonus.get(team_id, 0)) + int(C.OVERDRIVE_STEAL_BONUS)
			steal_bonus_hit = true
	bat["stolen_from_team"] = 0

	var pts: int = int(C.battery_points(int(bat["type"]))) + (int(C.OVERDRIVE_STEAL_BONUS) if steal_bonus_hit else 0)
	var pop_txt: String = "+%d!" % pts if steal_bonus_hit else "+%d" % pts
	var pop_col: Color = C.TEAM_COLORS.get(team_id, Color.WHITE) as Color
	_emit_popup(Vector3(vault2.x, 1.4, vault2.y), pop_txt, pop_col)
	_emit_fx("deposit", Vector3(vault2.x, 0.25, vault2.y), 1.15)


func _step_batteries(delta: float) -> void:
	for raw_b in _batteries:
		var b: Dictionary = raw_b as Dictionary
		if not bool(b["active"]):
			continue
		var st: int = int(b["state"])
		if st == int(C.BAT_CARRIED):
			var cid: int = int(b["carrier_id"])
			if _players.has(cid):
				var cp: Vector3 = (_players[cid] as Dictionary)["pos"] as Vector3
				b["pos"] = cp + Vector3(0.0, 1.92, 0.0)
		elif st == int(C.BAT_DEPOSITED):
			if not bool(b["perm_locked"]) and float(b["lock_timer"]) > 0.0:
				b["lock_timer"] = maxf(0.0, float(b["lock_timer"]) - delta)
		elif st == int(C.BAT_LOOSE):
			var bp3: Vector3 = b["pos"] as Vector3
			var bp2 := Vector2(bp3.x, bp3.z)
			var cvel: Vector2 = C.conveyor_velocity_at(bp2)
			if cvel.length_squared() > 0.01:
				bp2 = C.resolve_arena_obstacles(bp2 + cvel * delta, 0.35, _arena_half, _pillars)
				b["pos"] = Vector3(bp2.x, 0.0, bp2.y)
		elif st == int(C.BAT_THROWN):
			var t: float = float(b["throw_t"]) + delta / float(C.THROW_DURATION)
			b["throw_t"] = t
			var s2: Vector2 = b["throw_start"] as Vector2
			var e2: Vector2 = b["throw_end"] as Vector2
			var cur2: Vector2 = s2.lerp(e2, minf(t, 1.0))
			var arc_y: float = sin(minf(t, 1.0) * PI) * float(C.THROW_ARC_HEIGHT)
			b["pos"] = Vector3(cur2.x, arc_y, cur2.y)

			var thrower_id: int = int(b["thrower_id"])
			var thrower_team: int = int((_players.get(thrower_id, {}) as Dictionary).get("team_id", 0))
			# Check throw-in into thrower's own vault
			if _vault_by_team.has(thrower_team):
				var tv2: Vector2 = _vault_by_team[thrower_team] as Vector2
				if cur2.distance_to(tv2) <= float(C.VAULT_RADIUS) * 0.92:
					_deposit_battery(int(b["idx"]), thrower_team)
					continue
			# Check teammate relay catch
			var caught: bool = false
			if t >= 0.25:
				for raw_nid in _players.keys():
					var nid: int = int(raw_nid)
					if nid == thrower_id:
						continue
					var pl: Dictionary = _players[nid] as Dictionary
					if not bool(pl.get("connected", true)) or float(pl.get("stun_timer", 0.0)) > 0.0:
						continue
					if int(pl.get("carried_battery", -1)) >= 0:
						continue
					var pl3: Vector3 = pl["pos"] as Vector3
					if cur2.distance_to(Vector2(pl3.x, pl3.z)) <= float(C.PICKUP_RADIUS) * 0.9:
						b["state"] = int(C.BAT_CARRIED)
						b["carrier_id"] = nid
						pl["carried_battery"] = int(b["idx"])
						caught = true
						break
			if caught:
				continue
			if t >= 1.0:
				b["state"] = int(C.BAT_LOOSE)
				b["pos"] = Vector3(e2.x, 0.0, e2.y)


func _recompute_team_scores() -> void:
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		_team_scores[tid] = int(_team_steal_bonus.get(tid, 0))
	for raw_b in _batteries:
		var b: Dictionary = raw_b as Dictionary
		if bool(b["active"]) and int(b["state"]) == int(C.BAT_DEPOSITED):
			var vt: int = int(b["vault_team"])
			if _vault_by_team.has(vt):
				_team_scores[vt] = int(_team_scores.get(vt, 0)) + int(C.battery_points(int(b["type"])))


func player_disconnected(network_id: int) -> void:
	if not _players.has(network_id):
		return
	var p: Dictionary = _players[network_id] as Dictionary
	p["connected"] = false
	p["alive"] = false
	var b_idx: int = int(p.get("carried_battery", -1))
	if b_idx >= 0:
		_drop_battery(network_id, b_idx)
	if _is_server_sim and _phase != PH_ENDED and _active_team_count() <= 1:
		_finish_match()


func _winning_teams() -> Array:
	var best_sc: int = -1
	var winners: Array = []
	for raw_tid in _active_team_ids:
		var tid: int = int(raw_tid)
		var sc: int = int(_team_scores.get(tid, 0))
		if sc > best_sc:
			best_sc = sc
			winners = [tid]
		elif sc == best_sc:
			winners.append(tid)
	return winners


func _finish_match() -> void:
	if _phase == PH_ENDED:
		return
	_phase = PH_ENDED
	_recompute_team_scores()
	var raw_scores: Dictionary = {}
	for raw_nid in _players.keys():
		var nid: int = int(raw_nid)
		var tid: int = int((_players[nid] as Dictionary).get("team_id", 0))
		raw_scores[nid] = int(_team_scores.get(tid, 0))
	var final_scores: Dictionary = raw_scores
	if _team != null:
		final_scores = _team.sync_scores(raw_scores, []) as Dictionary
		_team.notify_round_win(final_scores, self)
		_team.mark_scores_applied(self)
	if not _standalone_mode and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_rpc_round_end.rpc(final_scores, _team_scores)
	var winners: Array = _winning_teams()
	if winners.size() == 1:
		_emit_banner("win", int(winners[0]))
	else:
		_emit_banner("draw", 0)
	if _hud != null and not _is_self_test:
		_hud.show_results(_active_team_ids, _team_scores, winners, _standalone_mode)
	round_finished.emit(final_scores)


func _build_snapshot() -> Dictionary:
	var p_snaps: Dictionary = {}
	for raw_nid in _players.keys():
		var p: Dictionary = _players[raw_nid] as Dictionary
		p_snaps[int(raw_nid)] = {
			"p": p["pos"],
			"f": p["facing"],
			"c": int(p["carried_battery"]),
			"s": float(p["stun_timer"]),
			"sa": float(p.get("shove_anim_timer", 0.0)) > 0.0,
			"r": bool(p["has_resonance"]),
			"on": bool(p["connected"]),
		}
	var b_snaps: Array = []
	for raw_b in _batteries:
		var b: Dictionary = raw_b as Dictionary
		if bool(b["active"]):
			b_snaps.append({
				"i": int(b["idx"]),
				"t": int(b["type"]),
				"st": int(b["state"]),
				"p": b["pos"],
				"vt": int(b["vault_team"]),
				"lk": float(b["lock_timer"]) > 0.0,
				"pl": bool(b["perm_locked"]),
			})
	return {
		"ph": _phase,
		"prep": _prep_remaining,
		"rem": _time_remaining,
		"ts": _team_scores.duplicate(),
		"pl": p_snaps,
		"bt": b_snaps,
		"rp": _resonance_pairs.duplicate(true),
		"cw": _core1_warn_timer > 0.0 or _core2_warn_timer > 0.0,
		"cwz": 3.0 if _core1_warn_timer > 0.0 else -3.0,
	}


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_state_snapshot(snap: Dictionary) -> void:
	if _is_server_sim:
		return
	_apply_snapshot(snap)


func _apply_snapshot(snap: Dictionary) -> void:
	_phase = int(snap.get("ph", _phase))
	_prep_remaining = float(snap.get("prep", _prep_remaining))
	_time_remaining = float(snap.get("rem", _time_remaining))
	_elapsed_time = 0.0 if _phase == PH_PREP else maxf(0.0, float(C.MATCH_DURATION) - _time_remaining)
	var ts = snap.get("ts", {})
	if ts is Dictionary:
		_team_scores = (ts as Dictionary).duplicate()
	var pl_map = snap.get("pl", {})
	if pl_map is Dictionary:
		for raw_nid in (pl_map as Dictionary).keys():
			var nid: int = int(raw_nid)
			if _players.has(nid):
				var ps: Dictionary = (pl_map as Dictionary)[raw_nid] as Dictionary
				var p: Dictionary = _players[nid] as Dictionary
				p["pos"] = ps.get("p", p["pos"])
				p["facing"] = ps.get("f", p["facing"])
				p["carried_battery"] = int(ps.get("c", -1))
				p["stun_timer"] = float(ps.get("s", 0.0))
				p["shove_anim_timer"] = 0.20 if bool(ps.get("sa", false)) else 0.0
				p["has_resonance"] = bool(ps.get("r", false))
				p["connected"] = bool(ps.get("on", true))
				p["alive"] = bool(p["connected"])
	for raw_b in _batteries:
		(raw_b as Dictionary)["active"] = false
	var bt_arr = snap.get("bt", [])
	if bt_arr is Array:
		for raw_bs in bt_arr:
			var bs: Dictionary = raw_bs as Dictionary
			var idx: int = int(bs.get("i", -1))
			if idx >= 0 and idx < _batteries.size():
				var b: Dictionary = _batteries[idx] as Dictionary
				b["active"] = true
				b["type"] = int(bs.get("t", 1))
				b["state"] = int(bs.get("st", 0))
				b["pos"] = bs.get("p", Vector3.ZERO)
				b["vault_team"] = int(bs.get("vt", 0))
				b["lock_timer"] = 1.0 if bool(bs.get("lk", false)) else 0.0
				b["perm_locked"] = bool(bs.get("pl", false))
	var rp = snap.get("rp", [])
	if rp is Array:
		_resonance_pairs = (rp as Array).duplicate(true)
	_client_core_warn = bool(snap.get("cw", false))
	_client_core_warn_z = float(snap.get("cwz", 3.0))


@rpc("authority", "call_remote", "reliable")
func _rpc_round_end(final_scores: Dictionary, team_scores_snap: Dictionary = {}) -> void:
	if _is_server_sim:
		return
	_phase = PH_ENDED
	if not team_scores_snap.is_empty():
		_team_scores = team_scores_snap.duplicate()
	if _hud != null and not _is_self_test:
		_hud.show_results(_active_team_ids, _team_scores, _winning_teams(), _standalone_mode)
	round_finished.emit(final_scores)


func _is_local_in_resonance() -> bool:
	for raw_pair in _resonance_pairs:
		if raw_pair is Array:
			var pair: Array = raw_pair as Array
			if pair.size() >= 2 and (int(pair[0]) == _local_net_id or int(pair[1]) == _local_net_id):
				return true
	return false


func _animate_visuals(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.tick(delta)
	if _dispenser_ring != null and is_instance_valid(_dispenser_ring):
		_dispenser_ring.rotate_y(delta * 1.4)
	if _dispenser_ring_b != null and is_instance_valid(_dispenser_ring_b):
		_dispenser_ring_b.rotate_y(-delta * 1.9)
	if _phase == PH_LIVE:
		if _conveyor_mat_l != null:
			_conveyor_mat_l.uv1_offset.x = fmod(_conveyor_mat_l.uv1_offset.x - delta * 0.65, 1.0)
		if _conveyor_mat_r != null:
			_conveyor_mat_r.uv1_offset.x = fmod(_conveyor_mat_r.uv1_offset.x + delta * 0.65, 1.0)
	if _camera != null and is_instance_valid(_camera) and _cam_base_pos != Vector3.ZERO:
		if _cam_shake > 0.001:
			_cam_shake = maxf(0.0, _cam_shake - delta * 1.4)
			var ox: float = sin(_srv_time * 57.0) * _cam_shake
			var oy: float = cos(_srv_time * 63.0) * _cam_shake * 0.7
			_camera.position = _cam_base_pos + Vector3(ox, oy, 0.0)
		elif _camera.position != _cam_base_pos:
			_camera.position = _cam_base_pos

	var local_res: bool = _is_local_in_resonance()
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
		var f: Vector2 = p.get("facing", Vector2(0.0, 1.0)) as Vector2
		if f.length_squared() > 0.01:
			pnode.rotation.y = atan2(f.x, f.y)
		var stunned: bool = float(p.get("stun_timer", 0.0)) > 0.0
		var shoving: bool = float(p.get("shove_anim_timer", 0.0)) > 0.0
		var rig := p.get("rig", null) as Node3D
		if rig != null and is_instance_valid(rig):
			var target_tilt: float = 0.45 if stunned else 0.0
			rig.rotation.z = lerpf(rig.rotation.z, target_tilt, clampf(delta * 16.0, 0.0, 1.0))
		var name_lbl := p.get("name_label", null) as Label3D
		if name_lbl != null and is_instance_valid(name_lbl):
			var carry_idx: int = int(p.get("carried_battery", -1))
			var target_lbl_y: float = 2.48
			if carry_idx >= 0 and carry_idx < _batteries.size():
				var cbat: Dictionary = _batteries[carry_idx] as Dictionary
				target_lbl_y = 3.24 if int(cbat["type"]) == int(C.CELL_CORE) else 2.78
			if not is_equal_approx(name_lbl.position.y, target_lbl_y):
				name_lbl.position.y = target_lbl_y
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

	# Batteries (only reconfigure meshes/materials when state changes)
	for i in range(_batteries.size()):
		var b: Dictionary = _batteries[i] as Dictionary
		var bn: Node3D = _battery_nodes[i] as Node3D if i < _battery_nodes.size() else null
		if bn == null or not is_instance_valid(bn):
			continue
		bn.visible = bool(b["active"])
		if bn.visible:
			bn.position = b["pos"] as Vector3
			var btype: int = int(b["type"])
			var is_locked: bool = float(b["lock_timer"]) > 0.0
			var is_perm: bool = bool(b["perm_locked"])
			var vc: Dictionary = _bat_vis_cache[i] as Dictionary
			if M != null and (int(vc["type"]) != btype or bool(vc["locked"]) != is_locked or bool(vc["perm"]) != is_perm):
				vc["type"] = btype
				vc["locked"] = is_locked
				vc["perm"] = is_perm
				M.configure_battery_visual(bn, btype, is_locked, is_perm, C)

	# Vault lock rings & overhead scoreboards
	for tid in _vault_nodes.keys():
		var vn: Dictionary = _vault_nodes[tid] as Dictionary
		var lbl := vn.get("score_label", null) as Label3D
		if lbl != null:
			lbl.text = str(int(_team_scores.get(int(tid), 0)))
		var lock_ring := vn.get("lock_ring", null) as MeshInstance3D
		if lock_ring != null:
			var has_lock: bool = false
			for raw_b in _batteries:
				var b: Dictionary = raw_b as Dictionary
				if bool(b["active"]) and int(b["state"]) == int(C.BAT_DEPOSITED) and int(b["vault_team"]) == int(tid) and float(b["lock_timer"]) > 0.0:
					has_lock = true
					break
			lock_ring.visible = has_lock
			if has_lock:
				lock_ring.rotate_y(delta * 1.8)

	# Resonance beams
	for bi in range(_resonance_beams.size()):
		var beam := _resonance_beams[bi] as Node3D
		if beam == null or not is_instance_valid(beam):
			continue
		if bi < _resonance_pairs.size():
			var pair: Array = _resonance_pairs[bi] as Array
			var id_a: int = int(pair[0])
			var id_b: int = int(pair[1])
			if _players.has(id_a) and _players.has(id_b):
				var pa: Dictionary = _players[id_a] as Dictionary
				var pb: Dictionary = _players[id_b] as Dictionary
				var col: Color = C.TEAM_COLORS.get(int(pa["team_id"]), Color.CYAN) as Color
				beam.visible = true
				_fx_pool.update_resonance_beam(beam, pa["pos"] as Vector3, pb["pos"] as Vector3, col)
				continue
		beam.visible = false

	# Core warning beacon (host timers or client snapshot)
	if _warn_beacon_node != null and is_instance_valid(_warn_beacon_node):
		if _is_server_sim:
			if _core1_warn_timer > 0.0:
				_warn_beacon_node.visible = true
				_warn_beacon_node.position = Vector3(0.0, 0.0, 3.0)
			elif _core2_warn_timer > 0.0:
				_warn_beacon_node.visible = true
				_warn_beacon_node.position = Vector3(0.0, 0.0, -3.0)
			else:
				_warn_beacon_node.visible = false
		else:
			_warn_beacon_node.visible = _client_core_warn
			if _client_core_warn:
				_warn_beacon_node.position = Vector3(0.0, 0.0, _client_core_warn_z)

	_update_crt_monitor()

	if _hud != null:
		_hud.update_hud(_active_team_ids, _team_scores, _time_remaining, _phase, _prep_remaining, local_res, delta)
		var show_you: bool = _screenshot_path.is_empty() and (_phase == PH_PREP or (_phase == PH_LIVE and _elapsed_time <= 2.5))
		var local_pos := Vector3.ZERO
		if show_you and _players.has(_local_net_id):
			var lp: Dictionary = _players[_local_net_id] as Dictionary
			if bool(lp.get("connected", true)):
				local_pos = lp.get("render_pos", lp.get("pos", Vector3.ZERO)) as Vector3
			else:
				show_you = false
		else:
			show_you = false
		_hud.update_you_marker(_camera, local_pos, show_you, _srv_time)


func _update_crt_monitor() -> void:
	if _monitor_timer != null and is_instance_valid(_monitor_timer):
		var t_txt: String = ""
		var t_col := Color(0.68, 1.0, 0.68)
		if _phase == PH_PREP:
			var psec: int = maxi(1, ceili(_prep_remaining))
			t_txt = "00:0%d" % psec
			t_col = Color(0.68, 1.0, 0.68)
		else:
			var secs: int = maxi(0, ceili(_time_remaining))
			var mins: int = secs / 60
			var rem: int = secs % 60
			t_txt = "%02d:%02d" % [mins, rem]
			if _phase == PH_LIVE and _time_remaining <= 15.0:
				t_col = Color(1.0, 0.46, 0.24)
		if t_txt != _last_crt_timer_text:
			_last_crt_timer_text = t_txt
			_monitor_timer.text = t_txt
		_monitor_timer.modulate = t_col

	if _monitor_phase != null and is_instance_valid(_monitor_phase):
		var ph_txt: String = "STANDARD LINE"
		var ph_col := Color(0.62, 0.96, 0.66)
		if _phase == PH_PREP:
			ph_txt = "STANDBY"
		elif _phase == PH_ENDED:
			ph_txt = "SHIFT COMPLETE"
			ph_col = Color(0.82, 0.94, 0.78)
		elif _elapsed_time >= float(C.PHASE3_START) or _time_remaining <= 15.0:
			ph_txt = "OVERDRIVE"
			ph_col = Color(1.0, 0.56, 0.24)
		elif _elapsed_time >= float(C.PHASE2_START) or _time_remaining <= 30.0:
			ph_txt = "HEAVY CORE"
			ph_col = Color(0.72, 1.0, 0.68)
		if ph_txt != _last_crt_phase_text:
			_last_crt_phase_text = ph_txt
			_monitor_phase.text = ph_txt
		_monitor_phase.modulate = ph_col
