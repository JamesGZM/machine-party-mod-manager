extends Node3D

## Bubble Blitz (泡泡爆破) — 3D Top-Down Party Minigame Stage.
## Reuses authentic Machine Party worker rigs, cosmetics, industrial textures,
## Terminal F4 CRT monitor/UI, vignette+posterization post-FX, gore FX, and SFX.

signal round_finished(scores: Dictionary)

const CONFIG_RES := "res://mods_bubble_blitz/config.gd"
const MESHES_RES := "res://mods_bubble_blitz/arena_meshes.gd"
const TEAM_RES := "res://mods_bubble_blitz/team_support.gd"
const FX_POOL_RES := "res://mods_bubble_blitz/fx_pool.gd"
const AI_RES := "res://mods_bubble_blitz/ai_controller.gd"
const SELF_TEST_RES := "res://mods_bubble_blitz/self_test.gd"
const CHAIN_DETONATE_DELAY_SEC := 0.05

var C = null
var M = null
var _team = null
var _fx_pool = null
var _ai_ctrl = null
var _self_test_runner = null
var _mpm_last_scores: Dictionary = {}

var _standalone_mode: bool = false
var _is_server_sim: bool = true
var _round_active: bool = false
var _round_ended: bool = false
var _intro_timer: float = 0.0
var _time_remaining: float = 75.0
var _elapsed_time: float = 0.0
var _crusher_timer: float = 0.0
var _crusher_index: int = 0
var _sync_accum: float = 0.0
var _next_bubble_id: int = 1
var _next_item_id: int = 1
var _last_countdown_sec: int = 4
var _last_beep_sec: int = -1
var _rng := RandomNumberGenerator.new()

var _map_width: int = 11
var _map_height: int = 9
var _theme_id: int = 0
var _map_seed: int = 0
var _tiles: Array = []
var _conveyors: Dictionary = {}
var _crush_order: Array = []

var _players: Dictionary = {} # network_id -> Dictionary
var _bubbles: Dictionary = {} # bubble_id -> Dictionary
var _blasts: Array = [] # Array of Dictionary
var _items: Dictionary = {} # item_id -> Dictionary
var _client_inputs: Dictionary = {} # network_id -> { "dir": Vector2, "drop": bool }

var _arena_root: Node3D = null
var _tile_nodes: Dictionary = {} # Vector2i -> Node3D
var _bubble_nodes: Dictionary = {} # bubble_id -> Node3D
var _item_nodes: Dictionary = {} # item_id -> Node3D
var _blast_root: Node3D = null
var _fx_root: Node3D = null
var _player_root: Node3D = null
var _camera: Camera3D = null

var _monitor_timer: Label3D = null
var _monitor_theme: Label3D = null
var _fans: Array = []
var _flicker_lamp_mat: StandardMaterial3D = null
var _shader_layer: CanvasLayer = null
var _hud_layer: CanvasLayer = null
var _banner_label: Label = null
var _kill_feed_label: Label = null
var _kill_feed_timer: float = 0.0
var _stats_panel: PanelContainer = null
var _stats_label: Label = null
var _local_net_id: int = 1

var _sfx_shove: AudioStreamPlayer = null
var _sfx_elim: AudioStreamPlayer = null
var _sfx_explosion: AudioStreamPlayer = null
var _sfx_place: AudioStreamPlayer = null
var _sfx_pickup: AudioStreamPlayer = null
var _sfx_countdown: AudioStreamPlayer = null
var _sfx_ding: AudioStreamPlayer = null
var _sfx_beep: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null
var _fx_hit_blood_scene: PackedScene = null
var _fx_bloodmist_scene: PackedScene = null
var _fx_explosion_scene: PackedScene = null
var _fx_dustplume_scene: PackedScene = null
var _explosion_mark_tex: Texture2D = null
var _blood_tex_01: Texture2D = null
var _blood_tex_02: Texture2D = null

var _prev_drop_pressed: bool = false
var _is_self_test: bool = false
var _screenshot_path: String = ""
var _screenshot_frames: int = 0


func _load_sibling_script(reg_res: String, filename: String):
	if ResourceLoader.exists(reg_res):
		return ResourceLoader.load(reg_res)
	var self_script: Script = get_script() as Script
	if self_script != null and not self_script.resource_path.is_empty():
		var abs_path: String = self_script.resource_path.get_base_dir().path_join(filename)
		if ResourceLoader.exists(abs_path):
			return ResourceLoader.load(abs_path)
	return load("res://" + filename)


func _load_helpers() -> void:
	if C == null:
		C = _load_sibling_script(CONFIG_RES, "config.gd")
	if M == null:
		M = _load_sibling_script(MESHES_RES, "arena_meshes.gd")
	if M != null:
		M.ensure_game_pck_mounted()
	if _team == null:
		var ts = _load_sibling_script(TEAM_RES, "team_support.gd")
		if ts != null:
			_team = ts.new()
	if _fx_pool == null:
		var fp = _load_sibling_script(FX_POOL_RES, "fx_pool.gd")
		if fp != null:
			_fx_pool = fp.new()
	if _ai_ctrl == null:
		var ai = _load_sibling_script(AI_RES, "ai_controller.gd")
		if ai != null:
			_ai_ctrl = ai.new()
	if _self_test_runner == null:
		var st = _load_sibling_script(SELF_TEST_RES, "self_test.gd")
		if st != null:
			_self_test_runner = st.new()


func _exit_tree() -> void:
	if _fx_pool != null:
		_fx_pool.clear()
	_tile_nodes.clear()
	_bubble_nodes.clear()
	_item_nodes.clear()
	_players.clear()
	_bubbles.clear()
	_blasts.clear()
	_items.clear()
	_client_inputs.clear()
	_fans.clear()
	_flicker_lamp_mat = null
	_fx_hit_blood_scene = null
	_fx_bloodmist_scene = null
	_fx_explosion_scene = null
	_fx_dustplume_scene = null
	_explosion_mark_tex = null
	_blood_tex_01 = null
	_blood_tex_02 = null
	_sfx_shove = null
	_sfx_elim = null
	_sfx_explosion = null
	_sfx_place = null
	_sfx_pickup = null
	_sfx_countdown = null
	_sfx_ding = null
	_sfx_beep = null
	_ambience_player = null
	if M != null and M.has_method("clear_caches"):
		M.clear_caches()
	C = null
	M = null
	_team = null
	_fx_pool = null
	_ai_ctrl = null
	_self_test_runner = null


func _ready() -> void:
	_load_helpers()
	var args: Array = Array(OS.get_cmdline_args()) + Array(OS.get_cmdline_user_args())
	for raw_a in args:
		var a: String = str(raw_a)
		if a == "--self-test":
			_is_self_test = true
		elif a.begins_with("--capture-screenshot="):
			_screenshot_path = a.substr("--capture-screenshot=".length())

	_setup_environment()
	if not _is_self_test:
		_setup_post_fx()
		_setup_vanilla_audio_and_fx()
	_setup_hud()

	if _is_self_test:
		_run_self_test()
		return

	_standalone_mode = (get_parent() == get_tree().root)
	if _standalone_mode:
		_start_standalone_preview()


func _setup_environment() -> void:
	# Authentic Machine Party indoor warehouse light pools + SSAO + depth fog + ACES.
	var env := Environment.new()
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.016, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.38, 0.43)
	env.ambient_light_energy = 0.38
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.09
	env.adjustment_saturation = 0.78
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_bloom = 0.09
	env.ssao_enabled = true
	env.ssao_radius = 0.75
	env.ssao_intensity = 1.75
	env.ssao_power = 1.45
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.028, 0.025, 0.024)
	env.fog_depth_begin = 25.0
	env.fog_depth_end = 60.0
	env.fog_depth_curve = 1.2

	var we := WorldEnvironment.new()
	we.name = "WorldEnv"
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "KeyLight"
	sun.rotation_degrees = Vector3(-52.0, 26.0, 0.0)
	sun.light_color = Color(0.92, 0.90, 0.90)
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_blur = 1.3
	add_child(sun)

	var rig := Node3D.new()
	rig.name = "WarehouseLightRig"
	add_child(rig)

	var center_spot := SpotLight3D.new()
	center_spot.name = "CenterGridSpot"
	center_spot.position = Vector3(0.0, 12.8, 0.6)
	center_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
	center_spot.light_color = Color(1.0, 0.90, 0.76)
	center_spot.light_energy = 13.5
	center_spot.spot_range = 28.0
	center_spot.spot_angle = 68.0
	center_spot.spot_angle_attenuation = 0.85
	center_spot.spot_attenuation = 1.15
	center_spot.shadow_enabled = true
	center_spot.shadow_bias = 0.05
	center_spot.shadow_blur = 1.4
	rig.add_child(center_spot)

	for bay_raw in [
		["WestBaySpot", Vector3(-10.2, 12.0, -0.4), 10.6, 72.0, 30.0],
		["EastBaySpot", Vector3(10.2, 12.0, -0.4), 10.6, 72.0, 30.0],
		["SouthBaySpot", Vector3(0.0, 11.4, 6.2), 6.5, 66.0, 26.0],
	]:
		var bay: Array = bay_raw as Array
		var bay_spot := SpotLight3D.new()
		bay_spot.name = str(bay[0])
		bay_spot.position = bay[1] as Vector3
		bay_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
		bay_spot.light_color = Color(0.96, 0.84, 0.68)
		bay_spot.light_energy = float(bay[2])
		bay_spot.spot_range = float(bay[4])
		bay_spot.spot_angle = float(bay[3])
		bay_spot.spot_attenuation = 1.05
		bay_spot.shadow_enabled = false
		rig.add_child(bay_spot)

	_camera = Camera3D.new()
	_camera.name = "ArenaCamera"
	_camera.fov = 44.0
	_camera.current = true
	add_child(_camera)

	_arena_root = Node3D.new()
	_arena_root.name = "ArenaRoot"
	add_child(_arena_root)

	_blast_root = Node3D.new()
	_blast_root.name = "BlastRoot"
	add_child(_blast_root)

	_fx_root = Node3D.new()
	_fx_root.name = "FxRoot"
	add_child(_fx_root)

	_player_root = Node3D.new()
	_player_root.name = "PlayerRoot"
	add_child(_player_root)


func _setup_post_fx() -> void:
	# Reuse authentic Machine Party vignette + 8-step posterization shaders.
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
		vm.set_shader_parameter("radius", 0.94)
		vm.set_shader_parameter("softness", 0.45)
		vm.set_shader_parameter("intensity", 1.24)
		vm.set_shader_parameter("contrast", 1.20)
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


func _setup_vanilla_audio_and_fx() -> void:
	_sfx_shove = _make_audio_player("res://audio/unique/disco dodge/dd shove.ogg", -4.0)
	_sfx_elim = _make_audio_player("res://audio/unique/disco dodge/dd fall scream impact.ogg", -2.0)
	_sfx_explosion = _make_audio_player("res://audio/sfx/bad_explosion.ogg", -5.0)
	_sfx_place = _make_audio_player("res://audio/unique/exploding collar race/mine_detected.ogg", -6.0)
	_sfx_pickup = _make_audio_player("res://audio/sfx/manufacture_gun_pickup_gear.ogg", -4.0)
	_sfx_countdown = _make_audio_player("res://audio/sfx/countdown_mechanism2.ogg", -3.0)
	_sfx_ding = _make_audio_player("res://audio/sfx/airplane ding.ogg", -2.0)
	_sfx_beep = _make_audio_player("res://audio/sfx/ekg_beep.ogg", -5.0)
	_ambience_player = _make_audio_player("res://audio/ambience/industrial-machine-cycle_loop.ogg", -15.0, true)
	if _ambience_player == null:
		_ambience_player = _make_audio_player("res://audio/unique/dvd roomba/dvd roomba ambience.ogg", -15.0, true)

	var hit_scene = M.load_optional("res://prefabs/managed_effects/hit_blood.tscn")
	if hit_scene is PackedScene:
		_fx_hit_blood_scene = hit_scene as PackedScene
	var mist_scene = M.load_optional("res://prefabs/managed_effects/bloodmist_01.tscn")
	if mist_scene is PackedScene:
		_fx_bloodmist_scene = mist_scene as PackedScene
	var exp_scene = M.load_optional("res://prefabs/managed_effects/mine_explosion.tscn")
	if exp_scene is PackedScene:
		_fx_explosion_scene = exp_scene as PackedScene
	var dust_scene = M.load_optional("res://prefabs/managed_effects/dustplume.tscn")
	if dust_scene is PackedScene:
		_fx_dustplume_scene = dust_scene as PackedScene
	var mark_tex = M.load_optional("res://textures/decals/explosion_mark.png")
	if mark_tex is Texture2D:
		_explosion_mark_tex = mark_tex as Texture2D
	var bt1 = M.load_optional("res://textures/decals/blood decals/blood_splat_01.png")
	if bt1 is Texture2D:
		_blood_tex_01 = bt1 as Texture2D
	var bt2 = M.load_optional("res://textures/decals/blood decals/blood_splat_02.png")
	if bt2 is Texture2D:
		_blood_tex_02 = bt2 as Texture2D


func _make_audio_player(res_path: String, volume_db: float, loop_audio: bool = false) -> AudioStreamPlayer:
	var stream = M.load_optional(res_path)
	if not (stream is AudioStream):
		return null
	if loop_audio and stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var p := AudioStreamPlayer.new()
	p.stream = stream as AudioStream
	p.volume_db = volume_db
	add_child(p)
	return p


func _setup_hud() -> void:
	# Clean vanilla CRT-style overlay: timer & theme live on the 3D back-wall CRT monitor.
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "BubbleBlitzHUD"
	_hud_layer.layer = 5
	add_child(_hud_layer)

	var hud_root := Control.new()
	hud_root.name = "HudRoot"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(hud_root)

	var term_font: Font = M.load_terminal_font()

	_banner_label = Label.new()
	_banner_label.anchor_left = 0.1
	_banner_label.anchor_right = 0.9
	_banner_label.anchor_top = 0.36
	_banner_label.anchor_bottom = 0.56
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 74)
	_banner_label.add_theme_color_override("font_color", Color(0.68, 1.0, 0.68))
	_banner_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner_label.add_theme_constant_override("outline_size", 14)
	if term_font != null:
		_banner_label.add_theme_font_override("font", term_font)
	hud_root.add_child(_banner_label)

	_kill_feed_label = Label.new()
	_kill_feed_label.anchor_left = 0.1
	_kill_feed_label.anchor_right = 0.9
	_kill_feed_label.anchor_top = 0.80
	_kill_feed_label.anchor_bottom = 0.87
	_kill_feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kill_feed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_kill_feed_label.add_theme_font_size_override("font_size", 22)
	_kill_feed_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.62))
	_kill_feed_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_kill_feed_label.add_theme_constant_override("outline_size", 6)
	if term_font != null:
		_kill_feed_label.add_theme_font_override("font", term_font)
	hud_root.add_child(_kill_feed_label)

	# Local-player-only compact CRT status bar, strictly centered across all resolutions & UI scales.
	var stats_center := CenterContainer.new()
	stats_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	stats_center.offset_top = -48.0
	stats_center.offset_bottom = -10.0
	stats_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(stats_center)

	_stats_panel = PanelContainer.new()
	_stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.04, 0.86)
	sb.border_color = Color(0.42, 0.88, 0.48, 0.90)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	_stats_panel.add_theme_stylebox_override("panel", sb)
	stats_center.add_child(_stats_panel)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.76))
	_stats_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_stats_label.add_theme_constant_override("outline_size", 4)
	if term_font != null:
		_stats_label.add_theme_font_override("font", term_font)
	_stats_panel.add_child(_stats_label)


@rpc("authority", "call_local", "reliable")
func start_round(roster: Array) -> void:
	_load_helpers()
	_standalone_mode = false
	_is_server_sim = multiplayer.is_server()
	_local_net_id = multiplayer.get_unique_id()
	if _is_server_sim:
		_rng.randomize()
		var theme_id: int = _rng.randi_range(0, C.THEME_COUNT - 1)
		var seed_val: int = _rng.randi()
		_rpc_setup_match.rpc(theme_id, seed_val, roster)


@rpc("authority", "call_local", "reliable")
func _rpc_setup_match(theme_id: int, seed_val: int, roster: Array) -> void:
	_setup_match_local(theme_id, seed_val, roster, false)


func _start_standalone_preview() -> void:
	_is_server_sim = true
	_local_net_id = 1
	_rng.randomize()
	var theme_id: int = C.THEME_CONVEYOR if not _screenshot_path.is_empty() else _rng.randi_range(0, C.THEME_COUNT - 1)
	var seed_val: int = 20261120 if not _screenshot_path.is_empty() else _rng.randi()
	var roster: Array = [
		{"id": 0, "network_id": 1, "nickname": "玩家 1 (你)", "customization": ["hard_hat", "sunglasses", "blue"], "is_ai": false},
		{"id": 1, "network_id": 2, "nickname": "發條阿紫", "customization": ["tophat", "", "purple"], "is_ai": true},
		{"id": 2, "network_id": 3, "nickname": "鍋爐綠醬", "customization": ["traffic_cone", "", "green"], "is_ai": true},
		{"id": 3, "network_id": 4, "nickname": "紅心活塞", "customization": ["beer_hat", "", "red"], "is_ai": true},
	]
	_setup_match_local(theme_id, seed_val, roster, true)
	if not _screenshot_path.is_empty():
		_stage_screenshot_action()


func _clear_arena() -> void:
	for child in _arena_root.get_children():
		child.queue_free()
	for child in _blast_root.get_children():
		child.queue_free()
	for child in _fx_root.get_children():
		child.queue_free()
	for child in _player_root.get_children():
		child.queue_free()
	_tile_nodes.clear()
	_bubble_nodes.clear()
	_item_nodes.clear()
	_players.clear()
	_bubbles.clear()
	_blasts.clear()
	_items.clear()
	if _fx_pool != null:
		_fx_pool.clear()
	_client_inputs.clear()
	_prev_drop_pressed = false
	_monitor_timer = null
	_monitor_theme = null
	_fans.clear()
	_flicker_lamp_mat = null


func _setup_match_local(theme_id: int, seed_val: int, roster: Array, is_preview: bool) -> void:
	_clear_arena()
	if _team != null:
		_team.begin_match(self, roster)
	var synced_roster: Array = _team.annotate_roster(roster) if (_team != null and _team.is_active()) else roster
	_mpm_last_scores.clear()
	_theme_id = theme_id
	_map_seed = seed_val
	_rng.seed = seed_val
	_round_ended = false
	_round_active = false
	_intro_timer = 0.0 if not _screenshot_path.is_empty() else 2.2
	_last_countdown_sec = 4
	_last_beep_sec = -1
	_time_remaining = C.ROUND_DURATION_SEC
	_elapsed_time = 0.0
	_crusher_timer = 0.0
	_crusher_index = 0
	_next_bubble_id = 1
	_next_item_id = 1

	var map_data: Dictionary = C.generate_map(synced_roster.size(), theme_id, seed_val)
	_map_width = int(map_data["width"])
	_map_height = int(map_data["height"])
	_tiles = map_data["tiles"]
	_conveyors = map_data["conveyors"]
	_crush_order = map_data["crush_order"]
	var spawns: Array = map_data["spawns"]

	var theme_meta: Dictionary = C.THEME_META.get(theme_id, C.THEME_META[C.THEME_CLASSIC])
	var accent: Color = theme_meta.get("accent", Color(0.24, 0.78, 0.96))
	var crate_col: Color = theme_meta.get("crate", Color(0.68, 0.45, 0.22))

	var stage_pack: Dictionary = M.build_floor_and_backdrop(_map_width, _map_height, C.TILE_SIZE, theme_meta)
	_arena_root.add_child(stage_pack["root"])
	_monitor_timer = stage_pack["monitor_timer"] as Label3D
	_monitor_theme = stage_pack["monitor_theme"] as Label3D
	var raw_fans = stage_pack.get("fans", [])
	_fans = raw_fans as Array if raw_fans is Array else []
	var raw_flicker = stage_pack.get("flicker_lamp_mat", null)
	_flicker_lamp_mat = raw_flicker as StandardMaterial3D if raw_flicker is StandardMaterial3D else null

	for cell_key in _conveyors.keys():
		var c: Vector2i = cell_key
		var dir: Vector2i = _conveyors[cell_key]
		var conv: Node3D = M.build_conveyor_tile(C.TILE_SIZE, dir, accent)
		conv.position = C.grid_to_world(c, _map_width, _map_height)
		_arena_root.add_child(conv)

	for y in range(_map_height):
		for x in range(_map_width):
			var t: int = int(_tiles[y][x])
			var c := Vector2i(x, y)
			if t == C.TILE_STEEL:
				var p: Node3D = M.build_steel_pillar(C.TILE_SIZE, accent)
				p.position = C.grid_to_world(c, _map_width, _map_height)
				_arena_root.add_child(p)
				_tile_nodes[c] = p
			elif t == C.TILE_CRATE or t == C.TILE_GOLD_CRATE:
				var cr: Node3D = M.build_crate(C.TILE_SIZE, t == C.TILE_GOLD_CRATE, crate_col)
				cr.position = C.grid_to_world(c, _map_width, _map_height)
				_arena_root.add_child(cr)
				_tile_nodes[c] = cr

	# Frame the full arena + back-wall CRT monitor.
	var span_z: float = float(_map_height) * C.TILE_SIZE
	var span_x: float = float(_map_width) * C.TILE_SIZE
	var cam_dist: float = maxf(span_z * 1.18, span_x * 0.80)
	_camera.position = Vector3(0.0, cam_dist * 0.84, cam_dist * 0.64)
	_camera.look_at(Vector3(0.0, 0.25, -0.45), Vector3.UP)

	for i in range(synced_roster.size()):
		var entry: Dictionary = synced_roster[i]
		var net_id: int = int(entry.get("network_id", i + 1))
		var spawn_cell: Vector2i = spawns[i % spawns.size()]
		var world_pos: Vector3 = C.grid_to_world(spawn_cell, _map_width, _map_height)
		var cust_raw = entry.get("customization", [])
		var cust: Array = cust_raw if cust_raw is Array else []
		var is_local: bool = (net_id == _local_net_id)
		var nick: String = str(entry.get("nickname", "P%d" % (i + 1)))
		var char_pack: Dictionary = M.build_worker_character(i, net_id, nick, cust, is_local)
		var node: Node3D = char_pack["root"]
		node.position = world_pos
		_player_root.add_child(node)

		var is_bot_seat: bool = bool(entry.get("is_ai", false))
		if not is_preview and _is_server_sim:
			var peers: PackedInt32Array = multiplayer.get_peers()
			if net_id != 1 and not peers.has(net_id):
				is_bot_seat = true

		_players[net_id] = {
			"network_id": net_id,
			"nickname": nick,
			"color": char_pack["color"],
			"anim_player": char_pack["anim_player"],
			"is_ai": is_bot_seat,
			"pos": world_pos,
			"facing": Vector2(0.0, 1.0),
			"hp": C.MAX_HP,
			"alive": true,
			"trapped": false,
			"trapped_timer": 0.0,
			"invuln_timer": 0.0,
			"elim_time": 0.0,
			"max_bubbles": C.START_MAX_BUBBLES,
			"active_bubbles": 0,
			"power": C.START_POWER,
			"speed_level": C.START_SPEED_LEVEL,
			"has_kick": false,
			"has_needle": false,
			"pops": 0,
			"traps": 0,
			"last_attacker": 0,
			"mpm_team_id": 0,
			"mpm_rescues": 0,
			"pass_bubble_ids": {},
			"ai_cooldown": 0.0,
			"ai_dir": Vector2.ZERO,
			"node": node,
		}
		_update_player_hud_3d(_players[net_id])

	if _team != null and _team.is_active() and not _players.is_empty():
		_team.group_radial_spawns(_players, synced_roster)
		var cjk_font: Font = _team.tp_font()
		for raw_nid in _players.keys():
			var nid: int = int(raw_nid)
			var tid: int = _team.player_team(nid)
			var p: Dictionary = _players[raw_nid] as Dictionary
			p["mpm_team_id"] = tid
			if tid > 0:
				var pnode: Node3D = p.get("node", null) as Node3D
				if pnode != null:
					_team.attach_foot_ring(pnode, tid)
					var np := pnode.get_node_or_null("Nameplate") as Label3D
					p["nickname"] = _team.apply_nameplate(np, str(p.get("nickname", "")), tid)
					var hp_lbl := pnode.get_node_or_null("HpBar") as Label3D
					if hp_lbl != null and cjk_font != null and hp_lbl.font != cjk_font:
						hp_lbl.font = cjk_font

	_init_fx_pools()
	_update_crt_monitor()
	_update_local_stats_hud()
	_banner_label.text = "3" if _intro_timer > 0.0 else ""
	_kill_feed_label.text = ""
	if _ambience_player != null and not _ambience_player.playing and not _is_self_test and _screenshot_path.is_empty():
		_ambience_player.play()
	if _intro_timer <= 0.0:
		_round_active = true


func _update_crt_monitor() -> void:
	if _monitor_timer != null:
		var sec: int = max(0, int(ceil(_time_remaining)))
		var mm: int = sec / 60
		var ss: int = sec % 60
		_monitor_timer.text = "%02d:%02d" % [mm, ss]
		if sec <= 10:
			var flash_on: bool = int(floor(Time.get_ticks_msec() * 0.006)) % 2 == 0
			_monitor_timer.modulate = Color(1.0, 0.28, 0.24) if flash_on else Color(1.0, 0.72, 0.68)
		elif _time_remaining <= C.HURRY_UP_REMAINING_SEC:
			_monitor_timer.modulate = Color(1.0, 0.76, 0.24)
		else:
			_monitor_timer.modulate = Color(0.68, 1.0, 0.68)
	if _monitor_theme != null:
		var phase_tag: String = "HURRY UP!" if _time_remaining <= C.HURRY_UP_REMAINING_SEC else C.theme_display_name(_theme_id)
		_monitor_theme.text = "BUBBLE BLITZ // " + phase_tag


func _update_local_stats_hud() -> void:
	if _stats_label == null or _stats_panel == null:
		return
	if not _players.has(_local_net_id):
		_stats_panel.visible = false
		return
	_stats_panel.visible = true
	var p: Dictionary = _players[_local_net_id]
	var loc: String = TranslationServer.get_locale().to_upper()
	var is_zhs: bool = loc.begins_with("ZHS")
	var is_zh: bool = loc.begins_with("ZH")

	var hp_str: String = ""
	if not bool(p["alive"]):
		hp_str = "已淘汰" if is_zhs else ("已淘汰" if is_zh else "OUT")
	elif bool(p["trapped"]):
		hp_str = "濒死中!" if is_zhs else ("瀕死中!" if is_zh else "CRITICAL!")
	else:
		for i in range(int(p["hp"])):
			hp_str += "♥"

	var avail_bombs: int = max(0, int(p["max_bubbles"]) - int(p["active_bubbles"]))
	var max_bombs: int = int(p["max_bubbles"])
	var rng_val: int = int(p["power"])
	var spd_lv: int = int(p["speed_level"]) + 1
	var kick_on: bool = bool(p["has_kick"])
	var needle_on: bool = bool(p["has_needle"])

	if is_zhs:
		_stats_label.text = "血量 %s | 炸弹 %d/%d | 范围 %d | 移速 Lv.%d | 踢弹:%s | 救命针:%s" % [
			hp_str, avail_bombs, max_bombs, rng_val, spd_lv,
			"有" if kick_on else "无",
			"有" if needle_on else "无",
		]
	elif is_zh:
		_stats_label.text = "血量 %s | 炸彈 %d/%d | 範圍 %d | 移速 Lv.%d | 踢彈:%s | 救命針:%s" % [
			hp_str, avail_bombs, max_bombs, rng_val, spd_lv,
			"有" if kick_on else "無",
			"有" if needle_on else "無",
		]
	else:
		_stats_label.text = "HP %s | BOMB %d/%d | RNG %d | SPD Lv.%d | KICK:%s | NEEDLE:%s" % [
			hp_str, avail_bombs, max_bombs, rng_val, spd_lv,
			"ON" if kick_on else "OFF",
			"YES" if needle_on else "NO",
		]


func _item_pickup_text(item_type: int) -> String:
	var loc: String = TranslationServer.get_locale().to_upper()
	var is_zhs: bool = loc.begins_with("ZHS")
	var is_zh: bool = loc.begins_with("ZH")
	if item_type == C.ITEM_BUBBLE:
		return "拾取：可放炸弹数 +1" if is_zhs else ("拾取：可放炸彈數 +1" if is_zh else "PICKUP: MAX BOMBS +1")
	if item_type == C.ITEM_POWER:
		return "拾取：爆炸范围 +1 格" if is_zhs else ("拾取：爆炸範圍 +1 格" if is_zh else "PICKUP: BLAST RANGE +1")
	if item_type == C.ITEM_SPEED:
		return "拾取：移动速度提升" if is_zhs else ("拾取：移動速度提升" if is_zh else "PICKUP: MOVE SPEED UP")
	if item_type == C.ITEM_KICK:
		return "拾取：踢炸弹（撞向炸弹即可踢飞）" if is_zhs else ("拾取：踢炸彈（撞向炸彈即可踢飛）" if is_zh else "PICKUP: KICK BOMBS (WALK INTO BOMB)")
	return "拾取：救命针（重伤倒地 1.5 秒自动自救）" if is_zhs else ("拾取：救命針（重傷倒地 1.5 秒自動自救）" if is_zh else "PICKUP: SYRINGE (AUTO-REVIVE WHEN DOWNED)")


func _update_player_hud_3d(p: Dictionary) -> void:
	var node: Node3D = p["node"]
	if node == null or not is_instance_valid(node):
		return
	node.set_meta(&"mpm_alive", bool(p["alive"]))
	var hp_label: Label3D = node.get_node_or_null("HpBar") as Label3D
	var trap_shell: Node3D = node.get_node_or_null("TrapBubble") as Node3D
	if trap_shell != null:
		trap_shell.visible = bool(p["trapped"]) and bool(p["alive"])
	if hp_label != null:
		if not bool(p["alive"]):
			hp_label.visible = false
		elif bool(p["trapped"]):
			hp_label.visible = true
			var rem: float = maxf(0.0, C.TRAPPED_DURATION_SEC - float(p["trapped_timer"]))
			if _team != null and _team.is_active() and not bool(p["has_needle"]):
				var is_zh: bool = _team.is_tw_locale() or _team.is_cn_locale()
				hp_label.text = ("[救命! %.1fs]" % rem) if is_zh else ("[HELP! %.1fs]" % rem)
				var cf: Font = _team.tp_font()
				if cf != null and hp_label.font != cf:
					hp_label.font = cf
				var tid: int = _team.player_team(int(p["network_id"]))
				var flash_on: bool = int(floor(Time.get_ticks_msec() * 0.010)) % 2 == 0
				hp_label.modulate = _team.team_color(tid) if (tid > 0 and flash_on) else Color(1.0, 0.92, 0.30)
			else:
				hp_label.text = "[CRITICAL %.1fs]" % rem if not bool(p["has_needle"]) else "[SYRINGE...]"
				hp_label.modulate = Color(1.0, 0.24, 0.18) if not bool(p["has_needle"]) else Color(1.0, 0.84, 0.28)
		else:
			hp_label.visible = true
			var bars: String = ""
			for i in range(int(p["hp"])):
				bars += "■"
			if bool(p["has_needle"]):
				bars += " +"
			hp_label.text = bars
			hp_label.modulate = Color(0.98, 0.34, 0.28) if int(p["hp"]) > 1 else Color(1.0, 0.80, 0.22)
	node.visible = bool(p["alive"])

	if int(p["network_id"]) == _local_net_id:
		_update_local_stats_hud()
	var ap: AnimationPlayer = p.get("anim_player", null)
	if ap != null:
		if bool(p["trapped"]) and ap.has_animation(&"mp_mod/falling"):
			if ap.current_animation != &"mp_mod/falling":
				ap.play(&"mp_mod/falling")
		elif not bool(p["trapped"]) and ap.has_animation(&"mp_mod/idle"):
			if ap.current_animation != &"mp_mod/idle" and ap.current_animation != &"mp_mod/shoved":
				ap.play(&"mp_mod/idle")


func _init_fx_pools() -> void:
	if _fx_pool != null:
		_fx_pool.init_pools(self)


func _step_fx_pools(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.step_fx_pools(self, delta)


func _spawn_vanilla_fx(scene: PackedScene, world_pos: Vector3, scale_val: float, lifetime: float) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_vanilla_fx(self, scene, world_pos, scale_val, lifetime)


func _spawn_explosion_mark(world_pos: Vector3, size_val: float) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_explosion_mark(self, world_pos, size_val)


func _spawn_blood_decal(world_pos: Vector3) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_blood_decal(self, world_pos)


func _process(delta: float) -> void:
	if not _screenshot_path.is_empty():
		_screenshot_frames += 1
		_animate_visuals(delta)
		if _screenshot_frames >= 6:
			_save_screenshot_and_quit()
		return

	if _kill_feed_timer > 0.0:
		_kill_feed_timer = maxf(0.0, _kill_feed_timer - delta)
		if _kill_feed_timer <= 0.0:
			_kill_feed_label.text = ""

	if _round_ended:
		_animate_visuals(delta)
		return

	if _intro_timer > 0.0:
		_intro_timer -= delta
		var cd_sec: int = int(ceil(_intro_timer / 0.72))
		if cd_sec != _last_countdown_sec and cd_sec > 0 and cd_sec <= 3:
			_last_countdown_sec = cd_sec
			_banner_label.text = str(cd_sec)
			if _sfx_countdown != null:
				_sfx_countdown.play()
		if _intro_timer <= 0.0:
			_banner_label.text = "GO!"
			if _sfx_ding != null:
				_sfx_ding.play()
			_round_active = true
		_animate_visuals(delta)
		return
	elif _banner_label.text == "GO!" and _elapsed_time > 0.65:
		_banner_label.text = ""

	if not _round_active:
		return

	_read_local_input()

	if _is_server_sim:
		_step_simulation(delta)
		if not _standalone_mode:
			_sync_accum += delta
			if _sync_accum >= 0.05:
				_sync_accum = 0.0
				_broadcast_snapshot()
	_update_crt_monitor()
	_animate_visuals(delta)


func _is_input_blocked_by_ui() -> bool:
	if get_tree() == null or get_tree().root == null:
		return false
	var pause_menu: Node = get_tree().root.get_node_or_null("PauseMenu")
	if pause_menu != null and bool(pause_menu.get("active")):
		return true
	var gm: Node = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.get("game_focused") == false:
		return true
	return false


func _read_local_input() -> void:
	var dir := Vector2.ZERO
	var drop_edge := false
	if _is_input_blocked_by_ui():
		_prev_drop_pressed = false
	else:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			dir.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			dir.y += 1.0
		if dir.length_squared() > 0.0:
			dir = dir.normalized()
		var drop_now: bool = Input.is_key_pressed(KEY_SPACE)
		drop_edge = drop_now and not _prev_drop_pressed
		_prev_drop_pressed = drop_now

	if _is_server_sim:
		var prev_drop: bool = false
		if _client_inputs.has(_local_net_id):
			prev_drop = bool(_client_inputs[_local_net_id].get("drop", false))
		_client_inputs[_local_net_id] = {"dir": dir, "drop": prev_drop or drop_edge}
	else:
		_rpc_client_input.rpc_id(1, dir, false)
		if drop_edge:
			_rpc_request_drop.rpc_id(1)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_client_input(dir: Vector2, drop: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		return
	var prev_drop: bool = false
	if _client_inputs.has(sender):
		prev_drop = bool(_client_inputs[sender].get("drop", false))
	_client_inputs[sender] = {"dir": dir.limit_length(1.0), "drop": prev_drop or drop}


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_drop() -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		return
	var prev_dir: Vector2 = Vector2.ZERO
	if _client_inputs.has(sender):
		prev_dir = _client_inputs[sender].get("dir", Vector2.ZERO)
	_client_inputs[sender] = {"dir": prev_dir, "drop": true}


func _step_simulation(delta: float) -> void:
	_elapsed_time += delta
	_time_remaining = maxf(0.0, C.ROUND_DURATION_SEC - _elapsed_time)
	var sec_left: int = int(ceil(_time_remaining))
	if sec_left <= 10 and sec_left > 0 and sec_left != _last_beep_sec:
		_last_beep_sec = sec_left
		if _sfx_beep != null:
			_sfx_beep.play()
	if _time_remaining <= C.HURRY_UP_REMAINING_SEC:
		_step_crusher_shrink(delta)

	_step_bubbles(delta)
	_step_blasts(delta)
	_step_players(delta)
	_check_round_end()


func _step_crusher_shrink(delta: float) -> void:
	_crusher_timer += delta
	while _crusher_timer >= C.CRUSHER_STEP_INTERVAL_SEC and _crusher_index < _crush_order.size():
		_crusher_timer -= C.CRUSHER_STEP_INTERVAL_SEC
		var cell: Vector2i = _crush_order[_crusher_index]
		_crusher_index += 1
		_crush_tile(cell)


func _crush_tile(cell: Vector2i) -> void:
	if cell.x <= 0 or cell.y <= 0 or cell.x >= _map_width - 1 or cell.y >= _map_height - 1:
		return
	_tiles[cell.y][cell.x] = C.TILE_CRUSHED
	if _tile_nodes.has(cell):
		var old_n: Node3D = _tile_nodes[cell]
		if is_instance_valid(old_n):
			old_n.queue_free()
		_tile_nodes.erase(cell)
	var block: Node3D = M.build_crusher_block(C.TILE_SIZE)
	block.position = C.grid_to_world(cell, _map_width, _map_height)
	_arena_root.add_child(block)
	_tile_nodes[cell] = block

	for item_id in _items.keys():
		if _items[item_id]["cell"] == cell:
			_remove_item(item_id)
	for b_id in _bubbles.keys():
		if _bubbles[b_id]["cell"] == cell:
			_detonate_bubble(b_id)

	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		if not bool(p["alive"]):
			continue
		var p_cell: Vector2i = C.world_to_grid(p["pos"], _map_width, _map_height)
		if p_cell == cell:
			_eliminate_player(p, 0, "CRUSHED")

	if not _standalone_mode and multiplayer.is_server():
		_rpc_crush_tile.rpc(cell)


@rpc("authority", "call_remote", "reliable")
func _rpc_crush_tile(cell: Vector2i) -> void:
	_tiles[cell.y][cell.x] = C.TILE_CRUSHED
	if _tile_nodes.has(cell):
		var old_n: Node3D = _tile_nodes[cell]
		if is_instance_valid(old_n):
			old_n.queue_free()
		_tile_nodes.erase(cell)
	var block: Node3D = M.build_crusher_block(C.TILE_SIZE)
	block.position = C.grid_to_world(cell, _map_width, _map_height)
	_arena_root.add_child(block)
	_tile_nodes[cell] = block


func _is_tile_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= _map_width or cell.y >= _map_height:
		return true
	return int(_tiles[cell.y][cell.x]) != C.TILE_EMPTY


func _bubble_at_cell(cell: Vector2i, ignore_id: int = -1) -> int:
	for b_id in _bubbles.keys():
		if int(b_id) == ignore_id:
			continue
		if _bubbles[b_id]["cell"] == cell:
			return int(b_id)
	return -1


func _step_players(delta: float) -> void:
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		if not bool(p["alive"]):
			continue

		if float(p["invuln_timer"]) > 0.0:
			p["invuln_timer"] = maxf(0.0, float(p["invuln_timer"]) - delta)

		if bool(p["trapped"]):
			p["trapped_timer"] = float(p["trapped_timer"]) + delta
			_update_player_hud_3d(p)
			if bool(p["has_needle"]) and float(p["trapped_timer"]) >= C.NEEDLE_AUTO_SAVE_DELAY_SEC:
				p["has_needle"] = false
				p["trapped"] = false
				p["trapped_timer"] = 0.0
				p["hp"] = 1
				p["invuln_timer"] = C.INVULN_DURATION_SEC
				_show_kill_feed(str(p["nickname"]) + " NEEDLE ESCAPE!")
				_update_player_hud_3d(p)
				continue
			if float(p["trapped_timer"]) >= C.TRAPPED_DURATION_SEC:
				_eliminate_player(p, int(p["last_attacker"]), "POPPED")
				continue

		var input_dir := Vector2.ZERO
		var want_drop := false
		if bool(p["is_ai"]):
			var ai_act: Dictionary = _compute_ai_input(p, delta)
			input_dir = ai_act["dir"]
			want_drop = bool(ai_act["drop"])
		elif _client_inputs.has(net_id):
			var ci: Dictionary = _client_inputs[net_id]
			input_dir = ci["dir"]
			want_drop = bool(ci["drop"])
			ci["drop"] = false

		var speed: float = C.BASE_MOVE_SPEED + float(p["speed_level"]) * C.SPEED_STEP_BONUS
		if bool(p["trapped"]):
			speed *= C.TRAPPED_MOVE_MULTIPLIER

		var cur_pos: Vector3 = p["pos"]
		var cur_cell: Vector2i = C.world_to_grid(cur_pos, _map_width, _map_height)

		var conv_vel := Vector3.ZERO
		if _conveyors.has(cur_cell):
			var cdir: Vector2i = _conveyors[cur_cell]
			conv_vel = Vector3(float(cdir.x), 0.0, float(cdir.y)) * C.CONVEYOR_PLAYER_PUSH

		var move_vec := Vector3(input_dir.x, 0.0, input_dir.y) * speed + conv_vel
		if input_dir.length_squared() > 0.01:
			p["facing"] = input_dir.normalized()

		var next_pos: Vector3 = _move_player_with_collision(p, cur_pos, move_vec, speed, delta)
		p["pos"] = next_pos

		var pass_ids: Dictionary = p["pass_bubble_ids"]
		for b_id in pass_ids.keys():
			if not _bubbles.has(b_id):
				pass_ids.erase(b_id)
				continue
			var b_pos: Vector3 = _bubbles[b_id]["pos"]
			if Vector2(next_pos.x - b_pos.x, next_pos.z - b_pos.z).length() > C.TILE_SIZE * 0.72:
				pass_ids.erase(b_id)

		if want_drop and not bool(p["trapped"]):
			_try_place_bubble(p)

		if not bool(p["trapped"]):
			var new_cell: Vector2i = C.world_to_grid(next_pos, _map_width, _map_height)
			for item_id in _items.keys():
				if _items[item_id]["cell"] == new_cell:
					_apply_item(p, int(_items[item_id]["type"]))
					_remove_item(item_id)
					break

	var ids: Array = _players.keys()
	for i in range(ids.size()):
		var a: Dictionary = _players[ids[i]]
		if not bool(a["alive"]) or not bool(a["trapped"]):
			continue
		for j in range(ids.size()):
			if i == j:
				continue
			var b: Dictionary = _players[ids[j]]
			if not bool(b["alive"]) or bool(b["trapped"]):
				continue
			var dist: float = Vector2(a["pos"].x - b["pos"].x, a["pos"].z - b["pos"].z).length()
			if dist <= C.TILE_SIZE * 0.62:
				_eliminate_player(a, int(b["network_id"]), "BUMP POP")
				break


func _move_player_with_collision(p: Dictionary, start_pos: Vector3, move_vec: Vector3, max_speed: float, delta: float) -> Vector3:
	var radius: float = C.TILE_SIZE * 0.30
	var pos := start_pos
	var dx: float = move_vec.x * delta
	var dz: float = move_vec.z * delta
	var want_x: bool = absf(dx) > 0.0001
	var want_z: bool = absf(dz) > 0.0001
	var blocked_x: bool = false
	var blocked_z: bool = false

	# 1. Try X axis first.
	if want_x:
		var cand_x := Vector3(pos.x + dx, 0.0, pos.z)
		if not _collides_world(p, cand_x, radius, Vector2(signf(dx), 0.0)):
			pos.x = cand_x.x
		else:
			blocked_x = true

	# 2. Try Z axis. If X was blocked while moving diagonally, preserve full wall-slide speed on Z!
	if want_z:
		var eff_dz: float = dz
		if blocked_x:
			eff_dz = signf(dz) * maxf(absf(dz), max_speed * delta)
		var cand_z := Vector3(pos.x, 0.0, pos.z + eff_dz)
		if not _collides_world(p, cand_z, radius, Vector2(0.0, signf(eff_dz))):
			pos.z = cand_z.z
		else:
			blocked_z = true

	# 3. If Z was blocked while moving diagonally and X succeeded, preserve full wall-slide speed on X!
	if want_x and blocked_z and not blocked_x:
		var full_dx: float = signf(dx) * maxf(absf(dx), max_speed * delta)
		var extra_dx: float = full_dx - dx
		if absf(extra_dx) > 0.0001:
			var cand_x2 := Vector3(pos.x + extra_dx, 0.0, pos.z)
			if not _collides_world(p, cand_x2, radius, Vector2(signf(dx), 0.0)):
				pos.x = cand_x2.x

	# 4. Corner assist ONLY for pure single-axis input clipping a pillar corner into an open lane.
	if blocked_x and not want_z:
		var cell: Vector2i = C.world_to_grid(pos, _map_width, _map_height)
		var ahead_cell := Vector2i(cell.x + (1 if dx > 0.0 else -1), cell.y)
		if not _is_tile_blocked(ahead_cell) and _bubble_at_cell(ahead_cell) == -1:
			var row_center: float = C.grid_to_world(cell, _map_width, _map_height).z
			var diff_z: float = row_center - pos.z
			if absf(diff_z) > 0.01 and absf(diff_z) < C.TILE_SIZE * 0.48:
				var nudge: float = signf(diff_z) * minf(absf(diff_z), absf(dx))
				var assist_pos := Vector3(pos.x, 0.0, pos.z + nudge)
				if not _collides_world(p, assist_pos, radius, Vector2.ZERO):
					pos.z = assist_pos.z
	elif blocked_z and not want_x:
		var cell: Vector2i = C.world_to_grid(pos, _map_width, _map_height)
		var ahead_cell := Vector2i(cell.x, cell.y + (1 if dz > 0.0 else -1))
		if not _is_tile_blocked(ahead_cell) and _bubble_at_cell(ahead_cell) == -1:
			var col_center: float = C.grid_to_world(cell, _map_width, _map_height).x
			var diff_x: float = col_center - pos.x
			if absf(diff_x) > 0.01 and absf(diff_x) < C.TILE_SIZE * 0.48:
				var nudge: float = signf(diff_x) * minf(absf(diff_x), absf(dz))
				var assist_pos := Vector3(pos.x + nudge, 0.0, pos.z)
				if not _collides_world(p, assist_pos, radius, Vector2.ZERO):
					pos.x = assist_pos.x

	return pos


func _collides_world(p: Dictionary, test_pos: Vector3, radius: float, push_dir: Vector2) -> bool:
	var half: float = C.TILE_SIZE * 0.5
	var center_cell: Vector2i = C.world_to_grid(test_pos, _map_width, _map_height)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := Vector2i(center_cell.x + dx, center_cell.y + dy)
			if not _is_tile_blocked(c):
				continue
			var tile_w: Vector3 = C.grid_to_world(c, _map_width, _map_height)
			var cx: float = clampf(test_pos.x, tile_w.x - half, tile_w.x + half)
			var cz: float = clampf(test_pos.z, tile_w.z - half, tile_w.z + half)
			if Vector2(test_pos.x - cx, test_pos.z - cz).length_squared() < radius * radius:
				return true

	var pass_ids: Dictionary = p["pass_bubble_ids"]
	var cur_p: Vector3 = p["pos"]
	var min_bubble_dist: float = radius + C.TILE_SIZE * 0.34
	for b_id in _bubbles.keys():
		if pass_ids.has(b_id):
			continue
		var b: Dictionary = _bubbles[b_id]
		var bp: Vector3 = b["pos"]
		var d: float = Vector2(test_pos.x - bp.x, test_pos.z - bp.z).length()
		if d < min_bubble_dist:
			var cur_d: float = Vector2(cur_p.x - bp.x, cur_p.z - bp.z).length()
			# If already overlapping a bubble (e.g. placed or slid into the player),
			# allow any movement that increases separation so players can never be stuck.
			if cur_d < min_bubble_dist and d > cur_d + 0.0001:
				continue
			if bool(p["has_kick"]) and not bool(p["trapped"]) and push_dir.length_squared() > 0.5:
				var kdir := Vector2i(int(round(push_dir.x)), int(round(push_dir.y)))
				b["slide_dir"] = kdir
				b["slide_speed"] = C.BUBBLE_SLIDE_SPEED
			return true
	return false


func _try_place_bubble(p: Dictionary) -> bool:
	if int(p["active_bubbles"]) >= int(p["max_bubbles"]):
		return false
	var cell: Vector2i = C.world_to_grid(p["pos"], _map_width, _map_height)
	if _is_tile_blocked(cell) or _bubble_at_cell(cell) != -1:
		return false

	var b_id: int = _next_bubble_id
	_next_bubble_id += 1
	var world_pos: Vector3 = C.grid_to_world(cell, _map_width, _map_height)
	_bubbles[b_id] = {
		"id": b_id,
		"owner_id": int(p["network_id"]),
		"cell": cell,
		"pos": world_pos,
		"power": int(p["power"]),
		"fuse": C.BUBBLE_FUSE_SEC,
		"slide_dir": Vector2i.ZERO,
		"slide_speed": 0.0,
	}
	p["active_bubbles"] = int(p["active_bubbles"]) + 1
	(p["pass_bubble_ids"] as Dictionary)[b_id] = true
	# Grant pass-through to any alive player currently overlapping the new bubble so
	# dropping a bomb in someone's face on open ground cannot trap them in place.
	for other_id in _players.keys():
		var other: Dictionary = _players[other_id]
		if not bool(other["alive"]):
			continue
		var op: Vector3 = other["pos"]
		if Vector2(op.x - world_pos.x, op.z - world_pos.z).length() <= C.TILE_SIZE * 0.72:
			(other["pass_bubble_ids"] as Dictionary)[b_id] = true
	if int(p["network_id"]) == _local_net_id:
		_update_local_stats_hud()

	var node: Node3D = M.build_water_bubble(C.TILE_SIZE, p["color"])
	node.position = world_pos
	_arena_root.add_child(node)
	_bubble_nodes[b_id] = node
	if _sfx_place != null:
		_sfx_place.play()

	if not _standalone_mode and multiplayer.is_server():
		_rpc_spawn_bubble.rpc(b_id, int(p["network_id"]), cell, p["color"])
	return true


@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_bubble(b_id: int, owner_id: int, cell: Vector2i, color: Color) -> void:
	var world_pos: Vector3 = C.grid_to_world(cell, _map_width, _map_height)
	_bubbles[b_id] = {
		"id": b_id,
		"owner_id": owner_id,
		"cell": cell,
		"pos": world_pos,
		"fuse": C.BUBBLE_FUSE_SEC,
	}
	var node: Node3D = M.build_water_bubble(C.TILE_SIZE, color)
	node.position = world_pos
	_arena_root.add_child(node)
	_bubble_nodes[b_id] = node


func _step_bubbles(delta: float) -> void:
	var to_detonate: Array = []
	for b_id in _bubbles.keys():
		var b: Dictionary = _bubbles[b_id]
		b["fuse"] = float(b["fuse"]) - delta

		var sdir: Vector2i = b["slide_dir"]
		var sspeed: float = float(b["slide_speed"])
		var cur_cell: Vector2i = b["cell"]
		if sdir == Vector2i.ZERO and _conveyors.has(cur_cell):
			sdir = _conveyors[cur_cell]
			sspeed = C.CONVEYOR_BUBBLE_SPEED

		if sdir != Vector2i.ZERO and sspeed > 0.0:
			var next_pos: Vector3 = b["pos"] + Vector3(float(sdir.x), 0.0, float(sdir.y)) * sspeed * delta
			var ahead_pos: Vector3 = next_pos + Vector3(float(sdir.x), 0.0, float(sdir.y)) * (C.TILE_SIZE * 0.42)
			var ahead_cell: Vector2i = C.world_to_grid(ahead_pos, _map_width, _map_height)
			var blocked: bool = _is_tile_blocked(ahead_cell) or _bubble_at_cell(ahead_cell, int(b_id)) != -1
			if not blocked:
				for net_id in _players.keys():
					var p: Dictionary = _players[net_id]
					if not bool(p["alive"]):
						continue
					if (p["pass_bubble_ids"] as Dictionary).has(b_id):
						continue
					if Vector2(next_pos.x - p["pos"].x, next_pos.z - p["pos"].z).length() < C.TILE_SIZE * 0.56:
						blocked = true
						break
			if blocked:
				var snap: Vector2i = C.world_to_grid(b["pos"], _map_width, _map_height)
				b["cell"] = snap
				b["pos"] = C.grid_to_world(snap, _map_width, _map_height)
				b["slide_dir"] = Vector2i.ZERO
				b["slide_speed"] = 0.0
			else:
				b["pos"] = next_pos
				b["cell"] = C.world_to_grid(next_pos, _map_width, _map_height)

		if _bubble_nodes.has(b_id):
			var bn: Node3D = _bubble_nodes[b_id]
			if is_instance_valid(bn):
				bn.position = b["pos"]

		if float(b["fuse"]) <= 0.0:
			to_detonate.append(int(b_id))

	for b_id in to_detonate:
		if _bubbles.has(b_id):
			_detonate_bubble(b_id)


func _detonate_bubble(b_id: int) -> void:
	if not _bubbles.has(b_id):
		return
	var b: Dictionary = _bubbles[b_id]
	_bubbles.erase(b_id)
	if _bubble_nodes.has(b_id):
		var bn: Node3D = _bubble_nodes[b_id]
		if is_instance_valid(bn):
			bn.queue_free()
		_bubble_nodes.erase(b_id)

	var owner_id: int = int(b["owner_id"])
	if _players.has(owner_id):
		var owner_p: Dictionary = _players[owner_id]
		owner_p["active_bubbles"] = max(0, int(owner_p["active_bubbles"]) - 1)
		if owner_id == _local_net_id:
			_update_local_stats_hud()

	var origin: Vector2i = b["cell"]
	var power: int = int(b["power"])
	var cells: Array = [origin]
	var destroyed_crates: Array = []
	var chain_ids: Array = []

	var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for raw_dir in dirs:
		var d: Vector2i = raw_dir
		for step in range(1, power + 1):
			var c: Vector2i = origin + d * step
			if c.x < 0 or c.y < 0 or c.x >= _map_width or c.y >= _map_height:
				break
			var t: int = int(_tiles[c.y][c.x])
			if t == C.TILE_STEEL or t == C.TILE_CRUSHED:
				break
			cells.append(c)
			if t == C.TILE_CRATE or t == C.TILE_GOLD_CRATE:
				destroyed_crates.append({"cell": c, "gold": t == C.TILE_GOLD_CRATE})
				break
			var hit_b: int = _bubble_at_cell(c)
			if hit_b != -1 and not chain_ids.has(hit_b):
				chain_ids.append(hit_b)

	for cr in destroyed_crates:
		var c: Vector2i = cr["cell"]
		var is_gold: bool = bool(cr["gold"])
		_tiles[c.y][c.x] = C.TILE_EMPTY
		if _tile_nodes.has(c):
			var cn: Node3D = _tile_nodes[c]
			if is_instance_valid(cn):
				cn.queue_free()
			_tile_nodes.erase(c)
		var drop_chance: float = C.GOLD_CRATE_DROP_CHANCE if is_gold else C.CRATE_DROP_CHANCE
		if _rng.randf() <= drop_chance:
			var itype: int = C.roll_item_type(_rng, is_gold)
			_spawn_item(c, itype)

	_spawn_blast_visual(cells, owner_id)
	if not _standalone_mode and multiplayer.is_server():
		_rpc_detonate.rpc(b_id, cells, destroyed_crates)

	for cid in chain_ids:
		if _bubbles.has(cid):
			# Stagger chain detonations across frames to prevent single-frame spikes and create a chain ripple.
			_bubbles[cid]["fuse"] = minf(float(_bubbles[cid]["fuse"]), CHAIN_DETONATE_DELAY_SEC)


@rpc("authority", "call_remote", "reliable")
func _rpc_detonate(b_id: int, cells: Array, destroyed_crates: Array) -> void:
	_bubbles.erase(b_id)
	if _bubble_nodes.has(b_id):
		var bn: Node3D = _bubble_nodes[b_id]
		if is_instance_valid(bn):
			bn.queue_free()
		_bubble_nodes.erase(b_id)
	for cr in destroyed_crates:
		var c: Vector2i = cr["cell"]
		_tiles[c.y][c.x] = C.TILE_EMPTY
		if _tile_nodes.has(c):
			var cn: Node3D = _tile_nodes[c]
			if is_instance_valid(cn):
				cn.queue_free()
			_tile_nodes.erase(c)
	_spawn_blast_visual(cells, 0)


func _spawn_blast_visual(cells: Array, owner_id: int) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_blast_visual(self, cells, owner_id)


func _step_blasts(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.step_blasts(self, delta)


func _hit_player_by_blast(p: Dictionary, attacker_id: int) -> void:
	if _team != null and _team.is_active() and attacker_id > 0 and _team.are_teammates(int(p["network_id"]), attacker_id):
		return
	if not bool(p["alive"]):
		return
	if float(p["invuln_timer"]) > 0.0:
		return

	if bool(p["trapped"]):
		var credit: int = attacker_id if attacker_id != int(p["network_id"]) and attacker_id > 0 else int(p["last_attacker"])
		_eliminate_player(p, credit, "BLAST POP")
		return

	p["hp"] = int(p["hp"]) - 1
	if attacker_id > 0 and attacker_id != int(p["network_id"]):
		p["last_attacker"] = attacker_id

	var hit_pos: Vector3 = p["pos"]
	_spawn_vanilla_fx(_fx_hit_blood_scene, Vector3(hit_pos.x, 0.72, hit_pos.z), 0.36, 1.1)
	_spawn_blood_decal(hit_pos)
	if _sfx_shove != null:
		_sfx_shove.play()
	if int(p["network_id"]) == _local_net_id:
		_update_local_stats_hud()
	var ap: AnimationPlayer = p.get("anim_player", null)
	if ap != null and ap.has_animation(&"mp_mod/shoved"):
		ap.play(&"mp_mod/shoved")

	if int(p["hp"]) <= 0:
		p["hp"] = 0
		p["trapped"] = true
		p["trapped_timer"] = 0.0
		p["invuln_timer"] = 0.45
		if attacker_id > 0 and attacker_id != int(p["network_id"]) and _players.has(attacker_id):
			_players[attacker_id]["traps"] = int(_players[attacker_id]["traps"]) + 1
		_show_kill_feed(str(p["nickname"]) + " DOWNED! BUMP TO FINISH!")
	else:
		p["invuln_timer"] = C.INVULN_DURATION_SEC
	_update_player_hud_3d(p)


func _eliminate_player(p: Dictionary, killer_id: int, reason: String) -> void:
	if _team != null and _team.is_active() and reason == "BUMP POP" and killer_id > 0 and _team.are_teammates(int(p["network_id"]), killer_id):
		if not bool(p["alive"]) or not bool(p["trapped"]):
			return
		p["trapped"] = false
		p["trapped_timer"] = 0.0
		p["hp"] = 1
		p["invuln_timer"] = C.INVULN_DURATION_SEC
		if _players.has(killer_id):
			var rescuer: Dictionary = _players[killer_id]
			rescuer["mpm_rescues"] = int(rescuer.get("mpm_rescues", 0)) + 1
			var r_name: String = str(rescuer["nickname"])
			var v_name: String = str(p["nickname"])
			var is_zh: bool = _team.is_tw_locale() or _team.is_cn_locale()
			_show_kill_feed(("%s 救活了 %s!" % [r_name, v_name]) if is_zh else ("%s RESCUED %s!" % [r_name, v_name]))
		if _sfx_ding != null:
			_sfx_ding.play()
		_update_player_hud_3d(p)
		return
	if not bool(p["alive"]):
		return
	p["alive"] = false
	p["trapped"] = false
	p["elim_time"] = _elapsed_time
	var pos: Vector3 = p["pos"]
	_spawn_vanilla_fx(_fx_bloodmist_scene, Vector3(pos.x, 0.65, pos.z), 0.42, 2.8)
	_spawn_blood_decal(pos)
	if _sfx_elim != null:
		_sfx_elim.play()
	if killer_id > 0 and killer_id != int(p["network_id"]) and _players.has(killer_id):
		_players[killer_id]["pops"] = int(_players[killer_id]["pops"]) + 1
		_show_kill_feed(str(_players[killer_id]["nickname"]) + " POPPED " + str(p["nickname"]) + "!")
	else:
		_show_kill_feed(str(p["nickname"]) + " OUT (" + reason + ")")
	_update_player_hud_3d(p)


func _spawn_item(cell: Vector2i, item_type: int) -> void:
	var item_id: int = _next_item_id
	_next_item_id += 1
	_items[item_id] = {"id": item_id, "cell": cell, "type": item_type}
	var node: Node3D = M.build_powerup_node(C.TILE_SIZE, item_type)
	node.position = C.grid_to_world(cell, _map_width, _map_height)
	_arena_root.add_child(node)
	_item_nodes[item_id] = node
	if not _standalone_mode and multiplayer.is_server():
		_rpc_spawn_item.rpc(item_id, cell, item_type)


@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_item(item_id: int, cell: Vector2i, item_type: int) -> void:
	_items[item_id] = {"id": item_id, "cell": cell, "type": item_type}
	var node: Node3D = M.build_powerup_node(C.TILE_SIZE, item_type)
	node.position = C.grid_to_world(cell, _map_width, _map_height)
	_arena_root.add_child(node)
	_item_nodes[item_id] = node


func _remove_item(item_id: int) -> void:
	_items.erase(item_id)
	if _item_nodes.has(item_id):
		var n: Node3D = _item_nodes[item_id]
		if is_instance_valid(n):
			n.queue_free()
		_item_nodes.erase(item_id)
	if not _standalone_mode and multiplayer.is_server():
		_rpc_remove_item.rpc(item_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_remove_item(item_id: int) -> void:
	_items.erase(item_id)
	if _item_nodes.has(item_id):
		var n: Node3D = _item_nodes[item_id]
		if is_instance_valid(n):
			n.queue_free()
		_item_nodes.erase(item_id)


func _apply_item(p: Dictionary, item_type: int) -> void:
	if item_type == C.ITEM_BUBBLE:
		p["max_bubbles"] = min(C.MAX_BUBBLES_CAP, int(p["max_bubbles"]) + 1)
	elif item_type == C.ITEM_POWER:
		p["power"] = min(C.MAX_POWER_CAP, int(p["power"]) + 1)
	elif item_type == C.ITEM_SPEED:
		p["speed_level"] = min(C.MAX_SPEED_LEVEL, int(p["speed_level"]) + 1)
	elif item_type == C.ITEM_KICK:
		p["has_kick"] = true
	elif item_type == C.ITEM_NEEDLE:
		p["has_needle"] = true
	if _sfx_pickup != null:
		_sfx_pickup.play()
	if int(p["network_id"]) == _local_net_id:
		_show_kill_feed(_item_pickup_text(item_type))
	_update_player_hud_3d(p)


func _show_kill_feed(msg: String) -> void:
	if _kill_feed_label != null:
		_kill_feed_label.text = msg
		_kill_feed_timer = 2.4


func _check_round_end() -> void:
	if _round_ended:
		return
	var team_mode: bool = _team != null and _team.is_active()
	var alive_count: int = 0
	var alive_ids: Array = []
	var alive_teams: Dictionary = {}
	if team_mode:
		var counts: Dictionary = _team.count_alive_teams_dict(_players)
		alive_ids = counts["alive_ids"]
		alive_teams = counts["alive_teams"]
		alive_count = alive_ids.size()
	else:
		for net_id in _players.keys():
			if bool(_players[net_id]["alive"]):
				alive_count += 1

	var should_end: bool = (
		(_time_remaining <= 0.0)
		or (_players.size() > 1 and (alive_teams.size() <= 1 if team_mode else alive_count <= 1))
		or (_players.size() == 1 and alive_count == 0)
	)
	if not should_end:
		return

	_round_ended = true
	_round_active = false
	var entries: Array = []
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		entries.append({
			"network_id": int(p["network_id"]),
			"alive": bool(p["alive"]),
			"elim_time": float(p["elim_time"]),
			"pops": int(p["pops"]),
			"traps": int(p["traps"]),
		})
	var scores: Dictionary = C.compute_rank_scores(entries)
	var banner_text: String = "ROUND COMPLETE!"
	if team_mode:
		scores = _team.sync_scores(scores, alive_ids)
		_mpm_last_scores = scores
		_team.notify_round_win(scores, self)
		_team.mark_scores_applied(self)
		var win_tid: int = 0
		if alive_teams.size() == 1:
			var k: int = int(alive_teams.keys()[0])
			if k > 0:
				win_tid = k
		else:
			var best_sc: int = -1
			for nid_v in scores.keys():
				var tid: int = _team.player_team(int(nid_v))
				if tid > 0 and int(scores[nid_v]) > best_sc:
					best_sc = int(scores[nid_v])
					win_tid = tid
		if win_tid > 0:
			banner_text = _team.team_win_banner(win_tid)
	else:
		_mpm_last_scores = scores
	_banner_label.text = banner_text
	if _is_self_test:
		return
	if _standalone_mode:
		await get_tree().create_timer(1.8).timeout
		if is_inside_tree():
			get_tree().quit()
	else:
		_rpc_round_banner.rpc(banner_text)
		await get_tree().create_timer(1.4).timeout
		if is_inside_tree():
			round_finished.emit(scores)


@rpc("authority", "call_remote", "reliable")
func _rpc_round_banner(text: String) -> void:
	if _banner_label != null:
		_banner_label.text = text


func _broadcast_snapshot() -> void:
	var p_snap: Dictionary = {}
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		p_snap[net_id] = [
			p["pos"],
			p["facing"],
			int(p["hp"]),
			bool(p["alive"]),
			bool(p["trapped"]),
			float(p["invuln_timer"]),
			bool(p["has_needle"]),
			int(p["max_bubbles"]),
			int(p["active_bubbles"]),
			int(p["power"]),
			int(p["speed_level"]),
			bool(p["has_kick"]),
			float(p["trapped_timer"]),
		]
	var b_snap: Dictionary = {}
	for b_id in _bubbles.keys():
		b_snap[b_id] = _bubbles[b_id]["pos"]
	_rpc_snapshot.rpc(_time_remaining, p_snap, b_snap)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_snapshot(rem_time: float, p_snap: Dictionary, b_snap: Dictionary) -> void:
	_time_remaining = rem_time
	for net_id in p_snap.keys():
		if not _players.has(net_id):
			continue
		var arr: Array = p_snap[net_id]
		var p: Dictionary = _players[net_id]
		var prev_hp: int = int(p["hp"])
		var prev_alive: bool = bool(p["alive"])
		p["pos"] = arr[0]
		p["facing"] = arr[1]
		p["hp"] = int(arr[2])
		p["alive"] = bool(arr[3])
		p["trapped"] = bool(arr[4])
		p["invuln_timer"] = float(arr[5])
		p["has_needle"] = bool(arr[6])
		if arr.size() >= 12:
			p["max_bubbles"] = int(arr[7])
			p["active_bubbles"] = int(arr[8])
			p["power"] = int(arr[9])
			p["speed_level"] = int(arr[10])
			p["has_kick"] = bool(arr[11])
		if arr.size() >= 13:
			p["trapped_timer"] = float(arr[12])
		if prev_alive and not bool(p["alive"]):
			var pos: Vector3 = p["pos"]
			_spawn_vanilla_fx(_fx_bloodmist_scene, Vector3(pos.x, 0.65, pos.z), 0.42, 2.8)
			_spawn_blood_decal(pos)
			if _sfx_elim != null:
				_sfx_elim.play()
		elif int(p["hp"]) < prev_hp:
			var pos: Vector3 = p["pos"]
			_spawn_vanilla_fx(_fx_hit_blood_scene, Vector3(pos.x, 0.72, pos.z), 0.36, 1.1)
			_spawn_blood_decal(pos)
			if _sfx_shove != null:
				_sfx_shove.play()
		_update_player_hud_3d(p)
	for b_id in b_snap.keys():
		if _bubbles.has(b_id):
			_bubbles[b_id]["pos"] = b_snap[b_id]


func _animate_visuals(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for raw_fan in _fans:
		var fan: Node3D = raw_fan as Node3D
		if fan != null and is_instance_valid(fan):
			fan.rotate_z(delta * 4.5)
	if _flicker_lamp_mat != null:
		var fl_wave: float = sin(t * 13.7) * sin(t * 31.3)
		var fl_dip: float = 0.48 if fl_wave > 0.72 else 1.0
		_flicker_lamp_mat.emission_energy_multiplier = 1.85 * fl_dip + 0.12 * sin(t * 5.3)
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		var node: Node3D = p["node"]
		if node == null or not is_instance_valid(node):
			continue
		var target_pos: Vector3 = p["pos"]
		var prev_pos: Vector3 = node.position
		node.position = node.position.lerp(target_pos, clampf(delta * 18.0, 0.0, 1.0))
		var move_speed_vis: float = Vector2(node.position.x - prev_pos.x, node.position.z - prev_pos.z).length() / maxf(delta, 0.001)

		var f: Vector2 = p["facing"]
		var avatar: Node3D = node.get_node_or_null("Avatar") as Node3D
		if avatar != null:
			if f.length_squared() > 0.01:
				var target_yaw: float = atan2(f.x, f.y)
				avatar.rotation.y = lerp_angle(avatar.rotation.y, target_yaw, clampf(delta * 16.0, 0.0, 1.0))
			if float(p["invuln_timer"]) > 0.0 and not bool(p["trapped"]):
				avatar.visible = int(floor(t * 16.0)) % 2 == 0
			else:
				avatar.visible = true

		# Drive vanilla run / idle / falling skeletal animations cleanly on both host and clients.
		var ap: AnimationPlayer = p.get("anim_player", null)
		if ap != null and bool(p["alive"]):
			if bool(p["trapped"]):
				ap.speed_scale = 1.0
				if ap.has_animation(&"mp_mod/falling") and ap.current_animation != &"mp_mod/falling":
					ap.play(&"mp_mod/falling")
			elif ap.current_animation == &"mp_mod/shoved" and ap.is_playing():
				ap.speed_scale = 1.0
			elif move_speed_vis > 0.35 and ap.has_animation(&"mp_mod/run"):
				ap.speed_scale = 1.15 + float(p["speed_level"]) * 0.14
				if ap.current_animation != &"mp_mod/run":
					ap.play(&"mp_mod/run", 0.10)
			elif ap.has_animation(&"mp_mod/idle"):
				ap.speed_scale = 1.0
				if ap.current_animation != &"mp_mod/idle":
					ap.play(&"mp_mod/idle", 0.12)

	for b_id in _bubble_nodes.keys():
		var bn: Node3D = _bubble_nodes[b_id]
		if is_instance_valid(bn):
			var progress: float = 0.0
			if _bubbles.has(b_id):
				var b: Dictionary = _bubbles[b_id]
				if not _is_server_sim:
					b["fuse"] = maxf(0.0, float(b["fuse"]) - delta)
				var base_pos: Vector3 = b["pos"]
				progress = clampf(1.0 - float(b["fuse"]) / C.BUBBLE_FUSE_SEC, 0.0, 1.0)
				var target_bpos: Vector3 = base_pos
				# High-frequency pressure tremor in the final 35% before detonation.
				if progress > 0.65:
					var shake: float = (progress - 0.65) * 0.14
					target_bpos += Vector3(sin(t * 62.0 + float(b_id)) * shake, 0.0, cos(t * 58.0 + float(b_id) * 1.7) * shake)
				bn.position = bn.position.lerp(target_bpos, clampf(delta * 22.0, 0.0, 1.0))

			# Escalating pressure swell + accelerating squash-and-stretch heartbeat (no numeric timer needed).
			var freq: float = lerpf(6.0, 26.0, progress * progress)
			var amp: float = lerpf(0.04, 0.16, progress)
			var swell: float = 1.0 + progress * progress * 0.22
			var wave: float = sin(t * freq + float(b_id))
			var sx: float = swell * (1.0 + wave * amp)
			var sy: float = swell * (1.0 - wave * amp * 0.85)
			bn.scale = Vector3(sx, sy, sx)

			# Accelerating warning beacon strobe & canister overheat glow.
			var blink_on: bool = sin(t * lerpf(8.0, 38.0, progress * progress)) > (0.15 - progress * 0.35)
			var beacon: MeshInstance3D = bn.get_node_or_null("FuseBeacon") as MeshInstance3D
			if beacon != null and beacon.material_override is StandardMaterial3D:
				var bmat: StandardMaterial3D = beacon.material_override
				bmat.emission_energy_multiplier = (4.2 if progress > 0.7 else 2.4) if blink_on else 0.15
				bmat.emission = Color(1.0, 0.72, 0.25) if (progress > 0.75 and blink_on) else Color(1.0, 0.16, 0.08)
			var body_m: MeshInstance3D = bn.get_node_or_null("CanisterBody") as MeshInstance3D
			if body_m != null and body_m.material_override is StandardMaterial3D:
				var cmat: StandardMaterial3D = body_m.material_override
				if progress > 0.55 and blink_on:
					cmat.emission_energy_multiplier = (progress - 0.55) * 2.4
				else:
					cmat.emission_energy_multiplier = 0.0

	for item_id in _item_nodes.keys():
		var inode: Node3D = _item_nodes[item_id]
		if is_instance_valid(inode):
			var spin: Node3D = inode.get_node_or_null("SpinMesh") as Node3D
			if spin != null:
				spin.rotation.y += delta * 2.6
				spin.position.y = C.TILE_SIZE * 0.42 + sin(t * 4.5 + float(item_id)) * 0.08
	_step_fx_pools(delta)


func player_disconnected(network_id: int) -> void:
	if _players.has(network_id):
		_eliminate_player(_players[network_id], 0, "DISCONNECTED")


func _compute_ai_input(p: Dictionary, delta: float) -> Dictionary:
	if _ai_ctrl != null:
		return _ai_ctrl.compute_input(self, p, delta)
	return {"dir": Vector2.ZERO, "drop": false}


func _stage_screenshot_action() -> void:
	if _self_test_runner != null:
		_self_test_runner.stage_screenshot_action(self)


func _save_screenshot_and_quit() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var err: int = img.save_png(_screenshot_path)
		if err == OK:
			print("SCREENSHOT_SAVED: " + _screenshot_path)
		else:
			push_error("Failed to save screenshot: err=" + str(err))
	get_tree().quit()


func _run_self_test() -> void:
	if _self_test_runner != null:
		_self_test_runner.run_self_test(self)
