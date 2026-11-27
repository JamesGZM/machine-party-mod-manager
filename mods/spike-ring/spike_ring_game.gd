extends Node3D

## ============================================================================
## Spike Ring / 尖刺圆环 — 服务器权威 2.5D 圆形竞技场生存小游戏
## ----------------------------------------------------------------------------
## 架构：
##   * 官方 Minigame 子类（official_minigame.gd）负责加载/信号协议，$Stage 即本脚本。
##   * 准备倒计时、60s 正式计时、移动校验、推人命中、机关生成/激活时间、
##     出局判定、计分、轮次结算 —— 全部只在 multiplayer.is_server() 分支执行。
##   * 客户端只发输入 + 按服务器时间轴插值/外推表现，绝不做出局判定。
##   * 机关由服务器种子 + reliable RPC 下发完整时间线，客户端按 srv_time 播放。
##   * 人数完全由 roster 决定（PlayerManager.player_presences），不写死 8 人上限。
## 风格：复用原版 Machine Party 工业纹理、角色 rig、Terminal F4 字体与音效。
## ============================================================================

signal round_finished(scores: Dictionary)

const CONFIG_RES := "res://mods_spike_ring/config.gd"
const MESHES_RES := "res://mods_spike_ring/arena_meshes.gd"
const TEAM_RES := "res://mods_spike_ring/team_support.gd"
const HAZARDS_RES := "res://mods_spike_ring/hazard_director.gd"
const FX_POOL_RES := "res://mods_spike_ring/fx_pool.gd"
const AI_RES := "res://mods_spike_ring/ai_controller.gd"
const SELF_TEST_RES := "res://mods_spike_ring/self_test.gd"

# ---------------------------------------------------------------- 阶段
const PH_PREP := 0
const PH_LIVE := 1
const PH_ENDED := 2

var C = null
var M = null
var _team = null
var _hazard_director = null
var _fx_pool = null
var _ai_ctrl = null
var _self_test_runner = null
var _early_win_tid: int = 0
var _mpm_last_official: Dictionary = {}

var _standalone_mode: bool = false
var _is_server_sim: bool = true
var _phase: int = PH_PREP
var _srv_time: float = 0.0                 # 服务器单调时钟：所有机关时间戳基准
var _srv_time_est: float = 0.0             # 客户端估算的服务器时钟
var _prep_remaining: float = 0.0
var _elapsed_time: float = 0.0
var _time_remaining: float = 60.0
var _last_countdown_sec: int = 4
var _round_index: int = 0
var _round_cfg: Dictionary = {}
var _map_seed: int = 0
var _rng := RandomNumberGenerator.new()
var _sync_accum: float = 0.0
var _local_net_id: int = 1

# ---------------------------------------------------------------- 实体
var _players: Dictionary = {}              # network_id -> state Dictionary
var _client_inputs: Dictionary = {}        # network_id -> input Dictionary
var _hazards: Dictionary = {}              # hazard_id -> hazard Dictionary
var _hazard_nodes: Dictionary = {}         # hazard_id -> {warn, active, saw}
var _next_hazard_id: int = 1
var _spawn_timer: float = 0.0
var _last_type_spawn: Dictionary = {}      # type -> srv_time
var _nozzle_cooldown: Dictionary = {}      # nozzle index -> srv_time
var _pos_history: Dictionary = {}          # network_id -> Array[[t, Vector3]]
var _snap_buffer: Array = []               # 客户端插值缓冲 [{t, players}]

# ---------------------------------------------------------------- 场景节点
var _arena_root: Node3D = null
var _hazard_root: Node3D = null
var _fx_root: Node3D = null
var _player_root: Node3D = null
var _camera: Camera3D = null
var _timer_label: Label3D = null
var _phase_label: Label3D = null
var _alive_label: Label3D = null
var _nozzles: Array = []
var _fans: Array = []
var _world_env: Environment = null
var _light_rig: Node3D = null

var _hud_layer: CanvasLayer = null
var _shader_layer: CanvasLayer = null
var _banner_label: Label = null
var _top_label: Label = null
var _stats_label: Label = null
var _result_label: Label = null
var _spectate_hint: Label = null
var _term_font: Font = null

var _prev_push_pressed: bool = false
var _prev_jump_pressed: bool = false
var _spectator_angle: float = 0.0
var _result_rows: Array = []

var _sfx_push: AudioStreamPlayer = null
var _sfx_elim: AudioStreamPlayer = null
var _sfx_warn: AudioStreamPlayer = null
var _sfx_ding: AudioStreamPlayer = null
var _sfx_beep: AudioStreamPlayer = null
var _sfx_flame: AudioStreamPlayer = null
var _ambience: AudioStreamPlayer = null
var _fx_hit_scene: PackedScene = null
var _fx_dust_scene: PackedScene = null

var _active_saw_lights: int = 0
var _is_self_test: bool = false
var _cam_base_pos: Vector3 = Vector3(0.0, 14.0, 8.8)
var _cam_shake: float = 0.0
var _stats_panel: PanelContainer = null

var _arena_radius: float = 10.5
var _shrink_ring: Node3D = null
var _shrink_warn: Node3D = null
var _slap_box: PanelContainer = null
var _slap_style: StyleBoxFlat = null
var _slap_icon_gray: TextureRect = null
var _slap_fill_clip: Control = null
var _slap_icon_color: TextureRect = null
var _slap_cd_label: Label = null
var _slap_buff_label: Label = null
var _slap_prev_ready: bool = true
var _slap_pop_timer: float = 0.0
var _airdrops: Array = []
var _airdrop_next_idx: int = 0

var _screenshot_path: String = ""
var _screenshot_frames: int = 0


# ============================================================================
# 1. 生命周期与场景搭建
# ============================================================================

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
	if _hazard_director == null:
		var hd = _load_sibling_script(HAZARDS_RES, "hazard_director.gd")
		if hd != null:
			_hazard_director = hd.new()
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


func _ready() -> void:
	var args: Array = Array(OS.get_cmdline_args()) + Array(OS.get_cmdline_user_args())
	for raw_a in args:
		var a: String = str(raw_a)
		if a == "--self-test":
			_is_self_test = true
			_load_helpers()
			_setup_environment()
			_setup_hud()
			_run_self_test()
			return
		if a == "--smoke-test":
			_is_self_test = true
			_load_helpers()
			_setup_environment()
			_setup_hud()
			_run_smoke_test()
			return
		if a.begins_with("--capture-screenshot="):
			_screenshot_path = a.substr("--capture-screenshot=".length())

	_load_helpers()
	_setup_environment()
	_setup_post_fx()
	_setup_audio_and_fx()
	_setup_hud()
	var vp: Viewport = get_viewport()
	if vp != null and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)

	_warmup_fx_pipelines.call_deferred()

	_standalone_mode = (get_parent() == get_tree().root)
	if _standalone_mode:
		_start_standalone_preview()


func _exit_tree() -> void:
	if _ambience != null and is_instance_valid(_ambience):
		_ambience.stop()
	if _fx_pool != null:
		_fx_pool.clear()
	if M != null and M.has_method("clear_caches"):
		M.clear_caches()
	_ambience = null
	_world_env = null
	_light_rig = null
	_team = null
	_hazard_director = null
	_fx_pool = null
	_ai_ctrl = null
	_self_test_runner = null
	_fx_hit_scene = null
	_fx_dust_scene = null
	_term_font = null


func _setup_environment() -> void:
	var env := Environment.new()
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.background_mode = Environment.BG_COLOR
	# 对齐 Machine Party 重工业车间氛围：ACES + SSAO + 深度雾，突出中央冷混凝土地板与外圈压花钢环。
	env.background_color = Color(0.020, 0.018, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.40, 0.42, 0.46)
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
	env.fog_depth_begin = 32.0
	env.fog_depth_end = 68.0
	env.fog_depth_curve = 1.2
	_world_env = env
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnv"
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "KeyLight"
	sun.light_color = Color(0.92, 0.91, 0.94)
	sun.light_energy = 0.90
	sun.rotation_degrees = Vector3(-52.0, 26.0, 0.0)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_blur = 1.3
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)

	var rig := Node3D.new()
	rig.name = "FoundryLightRig"
	add_child(rig)
	_light_rig = rig

	var center_spot := SpotLight3D.new()
	center_spot.name = "PitCenterSpot"
	center_spot.position = Vector3(0.0, 14.5, 0.8)
	center_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
	center_spot.light_color = Color(1.0, 0.90, 0.76)
	center_spot.light_energy = 14.0
	center_spot.spot_range = 32.0
	center_spot.spot_angle = 66.0
	center_spot.spot_angle_attenuation = 0.85
	center_spot.spot_attenuation = 1.15
	center_spot.shadow_enabled = true
	center_spot.shadow_bias = 0.05
	center_spot.shadow_blur = 1.4
	rig.add_child(center_spot)

	for rim_spec in [["WestRimSpot", -9.6], ["EastRimSpot", 9.6]]:
		var rim_spot := SpotLight3D.new()
		rim_spot.name = str(rim_spec[0])
		rim_spot.position = Vector3(float(rim_spec[1]), 12.0, 0.4)
		rim_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
		rim_spot.light_color = Color(0.96, 0.84, 0.68)
		rim_spot.light_energy = 9.2
		rim_spot.spot_range = 28.0
		rim_spot.spot_angle = 62.0
		rim_spot.spot_attenuation = 1.12
		rim_spot.shadow_enabled = false
		rig.add_child(rim_spot)

	_camera = Camera3D.new()
	_camera.name = "SpikeRingCamera"
	_camera.fov = C.CAMERA_FOV
	_camera.near = 0.1
	_camera.far = 400.0
	_camera.current = true
	add_child(_camera)
	_frame_arena()

	_arena_root = Node3D.new()
	_arena_root.name = "ArenaRoot"
	add_child(_arena_root)
	_hazard_root = Node3D.new()
	_hazard_root.name = "HazardRoot"
	add_child(_hazard_root)
	_fx_root = Node3D.new()
	_fx_root.name = "FxRoot"
	add_child(_fx_root)
	_player_root = Node3D.new()
	_player_root.name = "PlayerRoot"
	add_child(_player_root)


func _setup_post_fx() -> void:
	if _is_self_test or (_shader_layer != null and is_instance_valid(_shader_layer)) or get_node_or_null("PostFXLayer") != null or M == null:
		return
	var post_shader = M.load_optional("res://shaders/posterization.gdshader")
	var vig_shader = M.load_optional("res://shaders/vignette.gdshader")
	if not (post_shader is Shader or vig_shader is Shader):
		return

	_shader_layer = CanvasLayer.new()
	_shader_layer.name = "PostFXLayer"
	_shader_layer.layer = 4
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
		vm.set_shader_parameter("radius", 0.93)
		vm.set_shader_parameter("softness", 0.44)
		vm.set_shader_parameter("intensity", 1.28)
		vm.set_shader_parameter("contrast", 1.22)
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


# ---------------------------------------------------------------- 高角度斜俯视 3D 舞台相机
func _camera_fit_distance() -> float:
	var vp: Viewport = get_viewport()
	var vs: Vector2 = Vector2(1280.0, 720.0)
	if vp != null and vp.size.x > 0 and vp.size.y > 0:
		vs = Vector2(vp.size)
	var aspect: float = vs.x / vs.y
	var tan_v: float = tan(deg_to_rad(C.CAMERA_FOV * 0.5))
	var tan_h: float = tan_v * aspect
	var need: float = (_arena_radius + 1.4) * C.CAMERA_FIT_MARGIN
	var d_v: float = need / maxf(0.001, tan_v)
	var d_h: float = need / maxf(0.001, tan_h)
	return maxf(_arena_radius * 1.65, maxf(d_v, d_h))


func _frame_arena() -> void:
	## 58° 高角度斜俯视：完整框住圆形舞台与尖刺墙，同时立体展现角色全身、跳跃高度与激光净空。
	if _camera == null:
		return
	var dist: float = _camera_fit_distance()
	var pitch_rad: float = deg_to_rad(C.CAMERA_PITCH_DEG)
	var look_target := Vector3(0.0, 0.0, 0.35)
	_cam_base_pos = look_target + Vector3(0.0, dist * sin(pitch_rad), dist * cos(pitch_rad))
	_camera.position = _cam_base_pos
	_camera.look_at(look_target, Vector3.UP)
	if _world_env != null:
		_world_env.fog_depth_begin = dist + 6.0
		_world_env.fog_depth_end = dist + 42.0
	if _light_rig != null and is_instance_valid(_light_rig):
		var scale_r: float = maxf(1.0, _arena_radius / 8.5)
		var energy_r: float = clampf(scale_r, 1.0, 1.35)
		var c_spot := _light_rig.get_node_or_null("PitCenterSpot") as SpotLight3D
		if c_spot != null:
			c_spot.position = Vector3(0.0, 14.5 * scale_r, 0.8)
			c_spot.spot_range = 32.0 * scale_r
			c_spot.light_energy = 14.0 * energy_r
		var w_spot := _light_rig.get_node_or_null("WestRimSpot") as SpotLight3D
		if w_spot != null:
			w_spot.position = Vector3(-_arena_radius * 1.08, 12.0 * scale_r, 0.4)
			w_spot.spot_range = 28.0 * scale_r
			w_spot.light_energy = 9.2 * energy_r
		var e_spot := _light_rig.get_node_or_null("EastRimSpot") as SpotLight3D
		if e_spot != null:
			e_spot.position = Vector3(_arena_radius * 1.08, 12.0 * scale_r, 0.4)
			e_spot.spot_range = 28.0 * scale_r
			e_spot.light_energy = 9.2 * energy_r


func _on_viewport_resized() -> void:
	## 窗口尺寸/全屏切换后重新框定，保证始终完整看到整个圆形场地。
	_frame_arena()


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


func _setup_audio_and_fx() -> void:
	# 全部复用原版 Machine Party 音效资源，不引入外部素材；自测与截图模式跳过音频加载与播放。
	_term_font = M.load_terminal_font()
	var hit = M.load_optional("res://prefabs/managed_effects/hit_blood.tscn")
	if hit is PackedScene:
		_fx_hit_scene = hit as PackedScene
	var dust = M.load_optional("res://prefabs/managed_effects/dustplume.tscn")
	if dust is PackedScene:
		_fx_dust_scene = dust as PackedScene
	if _is_self_test or not _screenshot_path.is_empty():
		return
	_sfx_push = _make_audio_player("res://audio/unique/disco dodge/dd shove.ogg", -4.0)
	_sfx_elim = _make_audio_player("res://audio/unique/disco dodge/dd fall scream impact.ogg", -2.0)
	_sfx_warn = _make_audio_player("res://audio/unique/exploding collar race/mine_detected.ogg", -6.0)
	_sfx_ding = _make_audio_player("res://audio/sfx/airplane ding.ogg", -2.0)
	_sfx_beep = _make_audio_player("res://audio/sfx/ekg_beep.ogg", -5.0)
	_sfx_flame = _make_audio_player("res://audio/sfx/bad_explosion.ogg", -8.0)
	_ambience = _make_audio_player("res://audio/ambience/industrial-machine-cycle_loop.ogg", -16.0, true)
	if _ambience == null:
		_ambience = _make_audio_player("res://audio/unique/dvd roomba/dvd roomba ambience.ogg", -15.0, true)


func _mk_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 6))
	if _term_font != null:
		l.add_theme_font_override("font", _term_font)
	return l


func _setup_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "SpikeRingHUD"
	_hud_layer.layer = 5
	add_child(_hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root)

	_banner_label = _mk_label(84, Color(0.98, 0.80, 0.30))
	_banner_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_label.offset_top = 120.0
	_banner_label.offset_bottom = -300.0
	root.add_child(_banner_label)

	# 顶部与底部文字 HUD 已移除：倒计时直接嵌入 3D 场景 CRT 屏，底部仅保留右下角巴掌推人冷却图示
	_top_label = _mk_label(24, Color(0.72, 1.0, 0.72))
	_top_label.visible = false
	root.add_child(_top_label)

	_stats_label = _mk_label(20, Color(0.84, 1.0, 0.86))
	_stats_label.visible = false
	root.add_child(_stats_label)

	# 右下角巴掌推人技能冷却 HUD（带遮罩进度 + 冷却完成闪光弹跳动画）
	var skill_anchor := VBoxContainer.new()
	skill_anchor.name = "ShoveSkillHUD"
	skill_anchor.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skill_anchor.offset_left = -108.0
	skill_anchor.offset_top = -126.0
	skill_anchor.offset_right = -24.0
	skill_anchor.offset_bottom = -20.0
	skill_anchor.alignment = BoxContainer.ALIGNMENT_CENTER
	skill_anchor.add_theme_constant_override("separation", 4)
	skill_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(skill_anchor)

	_slap_box = PanelContainer.new()
	_slap_box.custom_minimum_size = Vector2(74.0, 74.0)
	_slap_box.pivot_offset = Vector2(37.0, 37.0)
	_slap_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slap_style = StyleBoxFlat.new()
	_slap_style.bg_color = Color(0.035, 0.045, 0.035, 0.92)
	_slap_style.border_color = Color(0.56, 0.88, 0.60, 0.90)
	_slap_style.set_border_width_all(2)
	_slap_style.set_corner_radius_all(2)
	_slap_box.add_theme_stylebox_override("panel", _slap_style)
	skill_anchor.add_child(_slap_box)

	var icon_wrap := Control.new()
	icon_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_wrap.clip_contents = true
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slap_box.add_child(icon_wrap)

	var slap_tex: Texture2D = M.build_slap_icon()
	# 底层：暗灰色巴掌（进入冷却时立刻显示灰色底图）
	_slap_icon_gray = TextureRect.new()
	_slap_icon_gray.texture = slap_tex
	_slap_icon_gray.modulate = Color(0.28, 0.30, 0.28, 0.88)
	_slap_icon_gray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_slap_icon_gray.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_slap_icon_gray.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slap_icon_gray.offset_left = 8.0
	_slap_icon_gray.offset_top = 8.0
	_slap_icon_gray.offset_right = -8.0
	_slap_icon_gray.offset_bottom = -8.0
	_slap_icon_gray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(_slap_icon_gray)

	# 上层充能裁切容器：随冷却进度从 0%（底）平滑向上涨满到 100%（顶），把灰色巴掌染回亮色
	_slap_fill_clip = Control.new()
	_slap_fill_clip.clip_contents = true
	_slap_fill_clip.anchor_left = 0.0
	_slap_fill_clip.anchor_right = 1.0
	_slap_fill_clip.anchor_top = 0.0
	_slap_fill_clip.anchor_bottom = 1.0
	_slap_fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(_slap_fill_clip)

	_slap_icon_color = TextureRect.new()
	_slap_icon_color.texture = slap_tex
	_slap_icon_color.modulate = Color(0.76, 1.0, 0.78, 1.0)
	_slap_icon_color.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_slap_icon_color.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_slap_icon_color.position = Vector2(8.0, 8.0)
	_slap_icon_color.size = Vector2(54.0, 54.0)
	_slap_icon_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slap_fill_clip.add_child(_slap_icon_color)

	_slap_cd_label = _mk_label(22, Color(0.95, 0.84, 0.42))
	_slap_cd_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slap_cd_label.visible = false
	icon_wrap.add_child(_slap_cd_label)

	_slap_buff_label = _mk_label(14, Color(1.0, 0.78, 0.24))
	_slap_buff_label.anchor_left = 0.0
	_slap_buff_label.anchor_right = 1.0
	_slap_buff_label.anchor_top = 0.0
	_slap_buff_label.anchor_bottom = 0.36
	_slap_buff_label.visible = false
	icon_wrap.add_child(_slap_buff_label)

	var key_hint := _mk_label(13, Color(0.68, 0.88, 0.70))
	key_hint.text = "[SPACE]"
	skill_anchor.add_child(key_hint)

	_spectate_hint = _mk_label(22, Color(1.0, 0.62, 0.42))
	_spectate_hint.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	_spectate_hint.offset_top = -140.0
	_spectate_hint.offset_bottom = -90.0
	root.add_child(_spectate_hint)
	_spectate_hint.visible = false

	_result_label = _mk_label(22, Color(0.74, 1.0, 0.80))
	_result_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_label.offset_left = 180.0
	_result_label.offset_right = -180.0
	_result_label.offset_top = 90.0
	_result_label.offset_bottom = -90.0
	root.add_child(_result_label)
	_result_label.visible = false


# ============================================================================
# 2. 回合启动（官方 Minigame 协议）
# ============================================================================

@rpc("authority", "call_local", "reliable")
func start_round(roster: Array) -> void:
	_load_helpers()
	_standalone_mode = false
	_is_server_sim = multiplayer.is_server()
	_local_net_id = multiplayer.get_unique_id()
	if _is_server_sim:
		# 关卡索引由官方轮次号驱动，超出配置数量自动循环，不写死人数/轮数。
		var rn: int = 1
		var parent: Node = get_parent()
		if parent != null and parent.get("round_number") != null:
			rn = maxi(1, int(parent.round_number))
		_round_index = (rn - 1) % maxi(1, C.ROUND_CONFIGS.size())
		_rng.randomize()
		_map_seed = _rng.randi()
		_rpc_setup_match.rpc(_round_index, _map_seed, roster)


@rpc("authority", "call_local", "reliable")
func _rpc_setup_match(round_index: int, seed_val: int, roster: Array) -> void:
	_setup_match_local(round_index, seed_val, roster, false)


func _start_standalone_preview() -> void:
	_is_server_sim = true
	_local_net_id = 1
	_rng.randomize()
	var roster: Array = []
	var names: Array = ["玩家 1 (你)", "發條阿紫", "鍋爐綠醬", "紅心活塞", "銅齒老闆", "蒸氣小妹", "螺絲工匠", "警示燈塔"]
	var count: int = 8 if _screenshot_path.is_empty() else 6
	for i in range(count):
		roster.append({
			"id": i,
			"network_id": i + 1,
			"nickname": str(names[i % names.size()]),
			"customization": [],
			"is_ai": i != 0,
		})
	_setup_match_local(0, 20261121, roster, true)
	if not _screenshot_path.is_empty():
		_stage_screenshot_action()


func _clear_arena() -> void:
	for child in _arena_root.get_children():
		child.queue_free()
	for child in _hazard_root.get_children():
		child.queue_free()
	for child in _fx_root.get_children():
		child.queue_free()
	for child in _player_root.get_children():
		child.queue_free()
	_hazard_nodes.clear()
	_hazards.clear()
	_airdrops.clear()
	_airdrop_next_idx = 0
	if _fx_pool != null:
		_fx_pool.clear()
	_active_saw_lights = 0
	_fans.clear()
	_players.clear()
	_client_inputs.clear()
	_pos_history.clear()
	_snap_buffer.clear()


func _setup_match_local(round_index: int, seed_val: int, roster: Array, is_preview: bool) -> void:
	_clear_arena()
	if _team != null:
		_team.begin_match(self, roster)
	var synced_roster: Array = _team.annotate_roster(roster) if (_team != null and _team.is_active()) else roster
	_early_win_tid = 0
	_mpm_last_official.clear()
	_round_index = round_index
	_round_cfg = C.ROUND_CONFIGS[round_index % maxi(1, C.ROUND_CONFIGS.size())]
	_map_seed = seed_val
	_rng.seed = seed_val

	_phase = PH_PREP
	_srv_time = 0.0
	_srv_time_est = 0.0
	_prep_remaining = C.PREP_DURATION_SEC if _screenshot_path.is_empty() else 0.0
	_elapsed_time = 0.0
	_time_remaining = C.ROUND_DURATION_SEC
	_last_countdown_sec = 4
	_spawn_timer = 0.0
	_next_hazard_id = 1
	_last_type_spawn.clear()
	_nozzle_cooldown.clear()
	_result_rows.clear()
	_result_label.visible = false
	_spectate_hint.visible = false
	if _prep_remaining <= 0.0:
		_phase = PH_LIVE

	_arena_radius = C.arena_radius_for_players(synced_roster.size())
	_frame_arena()

	var accent_rgb: Array = _round_cfg.get("accent", [0.96, 0.68, 0.22])
	# 外围工厂环境先挂（在场地之外），再叠加竞技场本体。
	var surroundings: Node3D = M.build_surroundings(_arena_radius, accent_rgb)
	_arena_root.add_child(surroundings)
	var stage: Dictionary = M.build_arena(_arena_radius, accent_rgb)
	_arena_root.add_child(stage["root"])
	_timer_label = stage["timer_label"] as Label3D
	_phase_label = stage["phase_label"] as Label3D
	_alive_label = null
	_shrink_ring = stage.get("shrink_ring", null) as Node3D
	_shrink_warn = stage.get("shrink_warn", null) as Node3D
	_nozzles = stage["nozzles"]
	var raw_fans = stage.get("fans", [])
	_fans = raw_fans as Array if raw_fans is Array else []

	var spawns: Array = C.compute_spawns(synced_roster.size(), seed_val, _arena_radius)
	for i in range(synced_roster.size()):
		var entry: Dictionary = synced_roster[i]
		var net_id: int = int(entry.get("network_id", i + 1))
		var spawn: Vector2 = spawns[i % spawns.size()]
		var cust_raw = entry.get("customization", [])
		var cust: Array = cust_raw if cust_raw is Array else []
		var is_local: bool = (net_id == _local_net_id)
		var nick: String = str(entry.get("nickname", "P%d" % (i + 1)))
		var char_pack: Dictionary = M.build_worker_character(i, net_id, nick, cust, is_local, C.PLAYER_VISUAL_SCALE, C.PLAYER_LABEL_HEIGHT)
		var node: Node3D = char_pack["root"]
		node.position = Vector3(spawn.x, 0.0, spawn.y)
		_player_root.add_child(node)

		var is_bot: bool = bool(entry.get("is_ai", false)) or net_id < 0
		if not is_preview and _is_server_sim:
			var peers: PackedInt32Array = multiplayer.get_peers()
			if net_id != 1 and not peers.has(net_id):
				is_bot = true

		var shield_node: Node3D = M.build_player_shield()
		node.add_child(shield_node)
		var power_aura: Node3D = M.build_player_power_aura()
		node.add_child(power_aura)
		node.set_meta(&"mpm_alive", true)
		_players[net_id] = {
			"network_id": net_id,
			"nickname": nick,
			"node": node,
			"anim_player": char_pack.get("anim_player", null),
			"shadow": char_pack.get("shadow", null),
			"shield_node": shield_node,
			"power_aura": power_aura,
			"shield": false,
			"power_item": C.ITEM_NONE,
			"knock_vel": Vector2.ZERO,
			"shove_anim_timer": 0.0,
			"color": char_pack["color"],
			"is_ai": is_bot,
			"pos": Vector3(spawn.x, 0.0, spawn.y),
			"render_pos": Vector3(spawn.x, 0.0, spawn.y),
			"facing": Vector2(0.0, 1.0),
			"vel_y": 0.0,
			"state": C.ST_READY if _phase == PH_PREP else C.ST_NORMAL,
			"state_timer": 0.0,
			"invuln_timer": 0.0,
			"push_cooldown": 0.0,
			"knock_dir": Vector2.ZERO,
			"alive": true,
			"alive_sec": 0.0,
			"score": 0,
			"last_scored_sec": 0,
			"pushes": 0,
			"hits_taken": 0,
			"out_reason": "",
			"elim_time": 0.0,
			"input": {"dir": Vector2.ZERO, "aim": Vector2(0.0, 1.0), "jump": false, "push": false},
			"last_input_seq": -1,
			"ai_dir": Vector2.ZERO,
			"ai_timer": 0.0,
		}
		_pos_history[net_id] = [[0.0, Vector3(spawn.x, 0.0, spawn.y)]]

	if _team != null and _team.is_active() and not _players.is_empty():
		_team.group_radial_spawns(_players, synced_roster, _pos_history)
		for raw_nid in _players.keys():
			var nid: int = int(raw_nid)
			var tid: int = _team.player_team(nid)
			var p: Dictionary = _players[raw_nid] as Dictionary
			if tid > 0:
				var pnode: Node3D = p.get("node", null) as Node3D
				if pnode != null:
					_team.attach_foot_ring(pnode, tid)
					var np := pnode.get_node_or_null("Nameplate") as Label3D
					p["nickname"] = _team.apply_nameplate(np, str(p.get("nickname", "")), tid)

	_init_fx_pools()
	_banner_label.text = str(int(ceil(_prep_remaining))) if _prep_remaining > 0.0 else ""
	_update_hud()
	if _ambience != null and not _ambience.playing and not _is_self_test and _screenshot_path.is_empty():
		_ambience.play()


# ============================================================================
# 3. 主循环 / 输入 / 服务器权威模拟
# ============================================================================

func _process(delta: float) -> void:
	if not _screenshot_path.is_empty():
		_screenshot_frames += 1
		_animate_visuals(delta)
		if _screenshot_frames >= 8:
			_save_screenshot_and_quit()
		return

	if not _is_server_sim:
		_srv_time_est = maxf(_srv_time_est + delta, _srv_time_est)
		_read_local_input()

	if _is_server_sim:
		_srv_time += delta
		_read_local_input()
		if _phase == PH_PREP:
			_step_prep(delta)
		elif _phase == PH_LIVE:
			_step_simulation(delta)
		if not _standalone_mode:
			_sync_accum += delta
			if _sync_accum >= C.SNAPSHOT_INTERVAL_SEC:
				_sync_accum = 0.0
				_broadcast_snapshot()
	else:
		_apply_snapshot_interpolation(delta)
		_update_hazard_states(_render_time())

	_animate_visuals(delta)
	_update_hud()


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


func _mouse_aim(world_pos: Vector3) -> Vector2:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return Vector2(0.0, 1.0)
	var mpos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mpos)
	var ray: Vector3 = cam.project_ray_normal(mpos)
	if absf(ray.y) < 0.0001:
		return Vector2(0.0, 1.0)
	var t: float = -origin.y / ray.y
	if t <= 0.0:
		return Vector2(0.0, 1.0)
	var hit: Vector3 = origin + ray * t
	var aim := Vector2(hit.x - world_pos.x, hit.z - world_pos.z)
	if aim.length_squared() < 0.0001:
		return Vector2(0.0, 1.0)
	return aim.normalized()


func _screen_dir_to_world(screen_dir: Vector2) -> Vector2:
	## screen_dir: x=右为正、y=下为正（W 键 => y=-1）。用当前相机的屏幕基向量
	## 投影到世界 XZ，得到与 AI/快照一致的世界方向，使 W 永远朝屏幕正上方。
	if screen_dir.length_squared() < 0.0001:
		return Vector2.ZERO
	var vp: Viewport = get_viewport()
	if vp == null:
		return screen_dir
	var cam: Camera3D = vp.get_camera_3d()
	if cam == null:
		return screen_dir
	var b: Basis = cam.global_transform.basis
	var right := Vector2(b.x.x, b.x.z)
	var up := Vector2(b.y.x, b.y.z)
	if right.length_squared() < 0.0001 or up.length_squared() < 0.0001:
		return screen_dir
	right = right.normalized()
	up = up.normalized()
	var world_dir: Vector2 = right * screen_dir.x + up * (-screen_dir.y)
	return world_dir.limit_length(1.0)


func _read_local_input() -> void:
	if not _players.has(_local_net_id):
		return
	var p: Dictionary = _players[_local_net_id]
	var dir := Vector2.ZERO
	var jump_edge := false
	var push_edge := false
	if _is_input_blocked_by_ui() or not bool(p["alive"]):
		_prev_jump_pressed = false
		_prev_push_pressed = false
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
		# 屏幕意图 -> 世界 XZ：无论相机角度/是否被替换，W 永远朝屏幕正上方。
		dir = _screen_dir_to_world(dir)
		# 纯键盘操作（对齐官方 Disco Dodge）：WASD/方向键移动并自动转向，按住 Space（备用 J/E）持续推人，无需鼠标介入。
		var push_now: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_E)
		jump_edge = false
		push_edge = push_now
		_prev_jump_pressed = false
		_prev_push_pressed = push_now

	var aim: Vector2 = p.get("facing", Vector2(0.0, 1.0))
	if dir.length_squared() > 0.001:
		aim = dir.normalized()
	var packet: Dictionary = {
		"dir": dir,
		"aim": aim,
		"jump": jump_edge,
		"push": push_edge,
	}
	if _is_server_sim:
		_client_inputs[_local_net_id] = packet
	else:
		var seq: int = int(Time.get_ticks_msec())
		_rpc_client_input.rpc_id(1, dir, aim, jump_edge, push_edge, seq)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_client_input(dir: Vector2, aim: Vector2, jump_edge: bool, push_edge: bool, seq: int) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0 or not _players.has(sender):
		return
	if seq <= int(_players[sender].get("last_input_seq", -1)):
		return
	_players[sender]["last_input_seq"] = seq
	_client_inputs[sender] = {
		"dir": dir.limit_length(1.0),
		"aim": aim.limit_length(1.0),
		"jump": jump_edge,
		"push": push_edge,
	}


func _step_prep(delta: float) -> void:
	## 3 秒准备：不生成机关、不出局、推人禁用；仅允许移动与跳跃熟悉操作。
	_prep_remaining = maxf(0.0, _prep_remaining - delta)
	var cd: int = int(ceil(_prep_remaining))
	if cd != _last_countdown_sec and cd > 0 and cd <= 3:
		_last_countdown_sec = cd
		_banner_label.text = str(cd)
		if _sfx_beep != null:
			_sfx_beep.play()
	_step_player_motions(delta, true)
	if _prep_remaining <= 0.0:
		_phase = PH_LIVE
		_elapsed_time = 0.0
		_time_remaining = C.ROUND_DURATION_SEC
		_spawn_timer = 0.8
		_banner_label.text = "GO!"
		if _sfx_ding != null:
			_sfx_ding.play()
		for net_id in _players.keys():
			var p: Dictionary = _players[net_id]
			if bool(p["alive"]) and int(p["state"]) == C.ST_READY:
				p["state"] = C.ST_NORMAL


func _step_simulation(delta: float) -> void:
	_elapsed_time += delta
	_time_remaining = maxf(0.0, C.ROUND_DURATION_SEC - _elapsed_time)
	var sec_left: int = int(ceil(_time_remaining))
	if sec_left <= 5 and sec_left > 0 and sec_left != _last_countdown_sec:
		_last_countdown_sec = sec_left
		if _sfx_beep != null:
			_sfx_beep.play()
	if _banner_label.text == "GO!" and _elapsed_time > 0.7:
		_banner_label.text = ""

	_step_hazards(delta)                 # 先推进机关时间线（激活/预警/电锯位置）
	_step_player_motions(delta, false) # 再按当前机关状态判定玩家出局
	_step_airdrops(delta)
	_step_popups_and_shockwaves(delta)
	_step_spawner(delta)
	_accrue_scores(delta)
	_check_round_end()


# ============================================================================
# 4. 玩家状态机 / 移动 / 跳跃 / 推人
# ============================================================================

func _state_allows_push(p: Dictionary) -> bool:
	var st: int = int(p["state"])
	return bool(p["alive"]) and st != C.ST_FALLEN and st != C.ST_OUT and st != C.ST_SPECTATOR and st != C.ST_READY


func _step_player_motions(delta: float, prep: bool) -> void:
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		if not bool(p["alive"]):
			continue

		# --- 计时器 ---
		if float(p["push_cooldown"]) > 0.0:
			p["push_cooldown"] = maxf(0.0, float(p["push_cooldown"]) - delta)
		if float(p.get("shove_anim_timer", 0.0)) > 0.0:
			p["shove_anim_timer"] = maxf(0.0, float(p["shove_anim_timer"]) - delta)
		if float(p["invuln_timer"]) > 0.0:
			p["invuln_timer"] = maxf(0.0, float(p["invuln_timer"]) - delta)
			if float(p["invuln_timer"]) <= 0.0 and int(p["state"]) == C.ST_INVULN:
				p["state"] = C.ST_NORMAL

		# --- 输入来源：AI / 客户端 / 本地 ---
		var input: Dictionary = p["input"]
		if bool(p["is_ai"]):
			input = _compute_ai_input(p, delta, prep)
		elif _client_inputs.has(net_id):
			input = _client_inputs[net_id]
		p["input"] = input

		var dir: Vector2 = input.get("dir", Vector2.ZERO)
		var aim: Vector2 = input.get("aim", Vector2(0.0, 1.0))
		var jump_edge: bool = bool(input.get("jump", false))
		var push_edge: bool = bool(input.get("push", false))
		if aim.length_squared() > 0.0001:
			p["facing"] = aim.normalized()

		# --- 摔倒：固定 0.30 秒后爬起，期间按物理减速击退滑行（对齐原版推人冲量手感）---
		if int(p["state"]) == C.ST_FALLEN:
			p["state_timer"] = float(p["state_timer"]) + delta
			var kv: Vector2 = p.get("knock_vel", Vector2.ZERO)
			var new_pos: Vector3 = p["pos"]
			new_pos.x += kv.x * delta
			new_pos.z += kv.y * delta
			p["pos"] = new_pos
			p["knock_vel"] = kv.move_toward(Vector2.ZERO, C.PUSH_DECAY * delta)
			if float(p["state_timer"]) >= C.FALL_DURATION_SEC:
				p["state_timer"] = 0.0
				p["knock_dir"] = Vector2.ZERO
				p["knock_vel"] = Vector2.ZERO
				if C.RECOVERY_IMMUNITY_SEC > 0.0:
					p["state"] = C.ST_INVULN
					p["invuln_timer"] = C.RECOVERY_IMMUNITY_SEC
				else:
					p["state"] = C.ST_NORMAL
					p["invuln_timer"] = 0.0
		else:
			# --- 平滑加减速移动（消除起步/急停顿挫）---
			var target_vel: Vector2 = dir * C.PLAYER_MOVE_SPEED
			var cur_vel: Vector2 = p.get("last_vel", Vector2.ZERO)
			var rate: float = C.PLAYER_ACCEL if target_vel.length_squared() > 0.01 else C.PLAYER_DECEL
			cur_vel = cur_vel.move_toward(target_vel, rate * delta)
			p["last_vel"] = cur_vel
			var new_pos: Vector3 = p["pos"]
			new_pos.x += cur_vel.x * delta
			new_pos.z += cur_vel.y * delta

			# --- 跳跃 ---
			if jump_edge and float(p["vel_y"]) <= 0.001 and float(p["pos"].y) <= 0.001:
				p["vel_y"] = C.PLAYER_JUMP_VELOCITY
				p["state"] = C.ST_JUMPING
			if float(p["vel_y"]) > 0.0 or float(p["pos"].y) > 0.0:
				p["vel_y"] = float(p["vel_y"]) - C.PLAYER_GRAVITY * delta
				new_pos.y = maxf(0.0, float(new_pos.y) + float(p["vel_y"]) * delta)
				if new_pos.y <= 0.0:
					p["vel_y"] = 0.0
					if int(p["state"]) == C.ST_JUMPING:
						p["state"] = C.ST_NORMAL if float(p["invuln_timer"]) <= 0.0 else C.ST_INVULN
			p["pos"] = new_pos

		# --- 准备期：钳制在场地内，绝不因边缘出局 ---
		if prep:
			var flat := Vector2(p["pos"].x, p["pos"].z)
			var limit: float = (_arena_radius - C.PLAYER_RADIUS) * 0.92
			if flat.length() > limit:
				flat = flat.normalized() * limit
				p["pos"].x = flat.x
				p["pos"].z = flat.y
		else:
			# --- 推人（服务器权威命中/击退），准备期禁用 ---
			if push_edge and _state_allows_push(p) and float(p["push_cooldown"]) <= 0.0:
				_try_push(p)

		_record_history(net_id, p["pos"])
		if not prep:
			_check_player_collisions(p)

	# --- 玩家两两圆形碰撞分离（彻底防止角色互相穿模）---
	var ids: Array = _players.keys()
	var min_sep: float = C.PLAYER_RADIUS * 2.0
	var min_sep_sq: float = min_sep * min_sep
	for i in range(ids.size()):
		var pa: Dictionary = _players[ids[i]]
		if not bool(pa["alive"]):
			continue
		for j in range(i + 1, ids.size()):
			var pb: Dictionary = _players[ids[j]]
			if not bool(pb["alive"]):
				continue
			var dx: float = float(pb["pos"].x) - float(pa["pos"].x)
			var dz: float = float(pb["pos"].z) - float(pa["pos"].z)
			var dist_sq: float = dx * dx + dz * dz
			if dist_sq < min_sep_sq:
				var dist: float = sqrt(dist_sq)
				var nx: float = (dx / dist) if dist > 0.0001 else 1.0
				var nz: float = (dz / dist) if dist > 0.0001 else 0.0
				var push_half: float = (min_sep - dist) * 0.5
				pa["pos"].x -= nx * push_half
				pa["pos"].z -= nz * push_half
				pb["pos"].x += nx * push_half
				pb["pos"].z += nz * push_half


func _record_history(net_id: int, pos: Vector3) -> void:
	var hist: Array = _pos_history.get(net_id, [])
	hist.append([_srv_time, pos])
	while hist.size() > 2 and _srv_time - float(hist[0][0]) > C.HISTORY_WINDOW_SEC:
		hist.remove_at(0)
	_pos_history[net_id] = hist


func _history_position(net_id: int, at_time: float) -> Vector3:
	## 延迟补偿：服务器危险判定统一回溯 LAG_COMPENSATION_SEC 取历史位置。
	var hist: Array = _pos_history.get(net_id, [])
	if hist.is_empty():
		return Vector3.ZERO
	if at_time <= float(hist[0][0]):
		return hist[0][1]
	for i in range(1, hist.size()):
		var t1: float = float(hist[i][0])
		if at_time <= t1:
			var t0: float = float(hist[i - 1][0])
			var a: float = 0.0 if t1 <= t0 else (at_time - t0) / (t1 - t0)
			return (hist[i - 1][1] as Vector3).lerp(hist[i][1] as Vector3, a)
	return hist[hist.size() - 1][1]


func _try_push(attacker: Dictionary) -> void:
	## 推人：支持普通推击、空投重击铁拳（2x 击退）与震荡冲击波（360° 范围震飞）。
	## 取消黄色矩形波，改为攻击者推人动作 + 命中粒子 + 3D 飘字 `+2`。
	var origin := Vector2(attacker["pos"].x, attacker["pos"].z)
	var facing: Vector2 = attacker["facing"]
	var power_item: int = int(attacker.get("power_item", C.ITEM_NONE))
	var is_shockwave: bool = (power_item == C.ITEM_SHOCKWAVE)
	var is_power_shove: bool = (power_item == C.ITEM_POWER_SHOVE)
	attacker["shove_anim_timer"] = 0.26
	attacker["push_cooldown"] = C.PUSH_COOLDOWN_SEC

	var attacker_id: int = int(attacker["network_id"])
	var victims: Array = []
	if is_shockwave:
		attacker["power_item"] = C.ITEM_NONE
		_spawn_shockwave(Vector3(origin.x, 0.35, origin.y))
		for net_id in _players.keys():
			if int(net_id) == attacker_id:
				continue
			if _team != null and _team.are_teammates(attacker_id, int(net_id)):
				continue
			var target: Dictionary = _players[net_id]
			if not bool(target["alive"]) or int(target["state"]) == C.ST_FALLEN or float(target["invuln_timer"]) > 0.0:
				continue
			var tp := Vector2(target["pos"].x, target["pos"].z)
			if tp.distance_to(origin) <= C.SHOCKWAVE_RANGE:
				victims.append(target)
	else:
		var best_id: int = -1
		var best_dist: float = C.PUSH_RANGE
		for net_id in _players.keys():
			if int(net_id) == attacker_id:
				continue
			if _team != null and _team.are_teammates(attacker_id, int(net_id)):
				continue
			var target: Dictionary = _players[net_id]
			if not bool(target["alive"]) or int(target["state"]) == C.ST_FALLEN:
				continue
			if float(target["invuln_timer"]) > 0.0:
				continue
			var tp := Vector2(target["pos"].x, target["pos"].z)
			var to_t: Vector2 = tp - origin
			var dist: float = to_t.length()
			if dist > C.PUSH_RANGE or dist < 0.001:
				continue
			if facing.dot(to_t.normalized()) < C.PUSH_HALF_ANGLE_COS:
				continue
			if dist < best_dist:
				best_dist = dist
				best_id = net_id
		if best_id >= 0:
			victims.append(_players[best_id])

	if victims.is_empty():
		if _sfx_push != null:
			_sfx_push.volume_db = -10.0
			_sfx_push.play()
		return

	if is_power_shove:
		attacker["power_item"] = C.ITEM_NONE

	var impulse: float = 28.0 if is_power_shove else (20.0 if is_shockwave else C.PUSH_KNOCKBACK_SPEED)
	for raw_v in victims:
		var victim: Dictionary = raw_v
		victim["state"] = C.ST_FALLEN
		victim["state_timer"] = 0.0
		victim["hits_taken"] = int(victim["hits_taken"]) + 1
		var vp := Vector2(victim["pos"].x, victim["pos"].z)
		var knock: Vector2 = (vp - origin).normalized()
		if knock.length_squared() < 0.001:
			knock = facing
		victim["knock_dir"] = knock
		victim["knock_vel"] = knock * impulse
		attacker["pushes"] = int(attacker["pushes"]) + 1
		attacker["score"] = int(attacker["score"]) + C.PUSH_SCORE
		_spawn_fx(_fx_hit_scene, Vector3(vp.x, 0.8, vp.y), 0.55 if (is_power_shove or is_shockwave) else 0.42, 1.2)

	var total_pts: int = victims.size() * C.PUSH_SCORE
	var popup_text: String = "+%d 2x!" % total_pts if is_power_shove else ("+%d 360°!" % total_pts if is_shockwave else "+%d" % total_pts)
	var popup_col: Color = Color(1.0, 0.72, 0.18) if (is_power_shove or is_shockwave) else Color(0.58, 1.0, 0.62)
	_spawn_score_popup(Vector3(origin.x, 2.35, origin.y), popup_text, popup_col)
	_cam_shake = maxf(_cam_shake, 0.28 if (is_power_shove or is_shockwave) else 0.18)
	if _sfx_push != null:
		_sfx_push.volume_db = -1.5 if (is_power_shove or is_shockwave) else -3.0
		_sfx_push.play()


func _spawn_score_popup(world_pos: Vector3, text: String, color: Color) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_score_popup(self, world_pos, text, color)


func _spawn_shockwave(world_pos: Vector3) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_shockwave(self, world_pos)


func _step_popups_and_shockwaves(_delta: float) -> void:
	# Pooled popups & shockwaves are ticked once per frame in _step_fx_pools(delta) via _animate_visuals.
	pass


func _step_airdrops(delta: float) -> void:
	## 直接空投可见 3D 消耗品道具（防爆护盾 / 重击铁拳 / 震荡冲击波），无盲盒箱子。
	if _airdrop_next_idx < C.AIRDROP_TIMES.size() and _elapsed_time >= float(C.AIRDROP_TIMES[_airdrop_next_idx]):
		_airdrop_next_idx += 1
		var itype: int = _rng.randi_range(C.ITEM_SHIELD, C.ITEM_SHOCKWAVE)
		var live_r: float = C.current_arena_radius(_elapsed_time, _arena_radius)
		var ang: float = _rng.randf() * TAU
		var dist: float = sqrt(_rng.randf()) * live_r * 0.62
		var drop_pos := Vector2(cos(ang) * dist, sin(ang) * dist)
		var node: Node3D = null
		if not _is_self_test and _fx_root != null and M != null:
			node = M.build_airdrop_item(itype)
			node.position = Vector3(drop_pos.x, 0.0, drop_pos.y)
			var vis := node.get_node_or_null("ItemVisual") as Node3D
			if vis != null:
				vis.position.y = 11.0
			_fx_root.add_child(node)
		_airdrops.append({
			"type": itype,
			"pos": drop_pos,
			"fall_timer": C.AIRDROP_FALL_SEC,
			"landed": false,
			"node": node,
			"age": 0.0,
		})
		if _sfx_warn != null:
			_sfx_warn.play()

	var t_now: float = Time.get_ticks_msec() * 0.001
	for i in range(_airdrops.size() - 1, -1, -1):
		var ad: Dictionary = _airdrops[i]
		ad["age"] = float(ad["age"]) + delta
		var node: Node3D = ad["node"]
		if not bool(ad["landed"]):
			ad["fall_timer"] = maxf(0.0, float(ad["fall_timer"]) - delta)
			var prog: float = 1.0 - float(ad["fall_timer"]) / maxf(0.01, C.AIRDROP_FALL_SEC)
			if node != null and is_instance_valid(node):
				var vis := node.get_node_or_null("ItemVisual") as Node3D
				if vis != null:
					vis.position.y = lerpf(11.0, 0.0, prog * prog)
					vis.rotation.y += delta * 2.8
				var ring := node.get_node_or_null("DropRing") as Node3D
				if ring != null:
					var s: float = 0.85 + 0.25 * sin(t_now * 10.0)
					ring.scale = Vector3(s, 1.0, s)
			if float(ad["fall_timer"]) <= 0.0:
				ad["landed"] = true
				if node != null and is_instance_valid(node):
					var vis := node.get_node_or_null("ItemVisual") as Node3D
					if vis != null:
						vis.position.y = 0.0
					var ring := node.get_node_or_null("DropRing") as Node3D
					if ring != null:
						ring.scale = Vector3.ONE
				_spawn_fx(_fx_dust_scene, Vector3(ad["pos"].x, 0.3, ad["pos"].y), 0.45, 0.8)
			_airdrops[i] = ad
			continue

		# 已落地：缓慢自转悬浮，等待玩家触碰拾取
		if node != null and is_instance_valid(node):
			var vis := node.get_node_or_null("ItemVisual") as Node3D
			if vis != null:
				vis.position.y = 0.10 + 0.08 * sin(t_now * 3.5)
				vis.rotation.y += delta * 1.8

		var picked := false
		var apos: Vector2 = ad["pos"]
		for net_id in _players.keys():
			var p: Dictionary = _players[net_id]
			if not bool(p["alive"]):
				continue
			var pflat := Vector2(p["pos"].x, p["pos"].z)
			if pflat.distance_to(apos) <= C.AIRDROP_PICKUP_RADIUS:
				var itype: int = int(ad["type"])
				if itype == C.ITEM_SHIELD:
					p["shield"] = true
					_spawn_score_popup(Vector3(pflat.x, 2.5, pflat.y), "護盾!", Color(0.36, 0.92, 1.0))
					if _team != null and _team.is_active():
						var link_txt: String = "護盾共振!" if _team.is_tw_locale() else ("护盾共振!" if _team.is_cn_locale() else "SHIELD LINK!")
						var picker_id: int = int(net_id)
						for ally_id in _players.keys():
							var aid: int = int(ally_id)
							if aid == picker_id or not _team.are_teammates(picker_id, aid):
								continue
							var ally: Dictionary = _players[ally_id]
							if not bool(ally["alive"]) or bool(ally.get("shield", false)):
								continue
							var aflat := Vector2(ally["pos"].x, ally["pos"].z)
							if aflat.distance_to(pflat) <= 3.5:
								ally["shield"] = true
								_spawn_score_popup(Vector3(aflat.x, 2.5, aflat.y), link_txt, Color(0.36, 0.92, 1.0))
				elif itype == C.ITEM_POWER_SHOVE:
					p["power_item"] = C.ITEM_POWER_SHOVE
					p["push_cooldown"] = 0.0
					_spawn_score_popup(Vector3(pflat.x, 2.5, pflat.y), "重推 2x!", Color(1.0, 0.74, 0.20))
				else:
					p["power_item"] = C.ITEM_SHOCKWAVE
					p["push_cooldown"] = 0.0
					_spawn_score_popup(Vector3(pflat.x, 2.5, pflat.y), "衝擊波 360°!", Color(1.0, 0.38, 0.24))
				if _sfx_ding != null:
					_sfx_ding.play()
				picked = true
				break

		if picked or float(ad["age"]) > 22.0:
			if node != null and is_instance_valid(node):
				node.queue_free()
			_airdrops.remove_at(i)
		else:
			_airdrops[i] = ad


func _compute_ai_input(p: Dictionary, delta: float, prep: bool) -> Dictionary:
	if _ai_ctrl != null:
		return _ai_ctrl.compute_input(self, p, delta, prep)
	return {"dir": Vector2.ZERO, "aim": Vector2(0.0, 1.0), "jump": false, "push": false}


# ============================================================================
# 5. 机关生成 / 安全生成器 / 机关时间线
# ============================================================================

func _step_spawner(delta: float) -> void:
	if _hazard_director != null:
		_hazard_director.step_spawner(self, delta)


@rpc("authority", "call_remote", "reliable")
func _rpc_hazard_spawn(h: Dictionary) -> void:
	if _hazard_director != null:
		_hazard_director.apply_remote_spawn(self, h)


func _render_time() -> float:
	return maxf(0.0, _srv_time_est - C.INTERP_DELAY_SEC)


func _update_hazard_states(t: float) -> void:
	if _hazard_director != null:
		_hazard_director.update_hazard_states(self, t)


func _step_hazards(delta: float) -> void:
	if _hazard_director != null:
		_hazard_director.step_hazards(self, delta)


# ============================================================================
# 6. 出局判定 / 计分 / 轮次结算
# ============================================================================

func _check_player_collisions(p: Dictionary) -> void:
	## 所有出局均由服务器判定；统一回溯 LAG_COMPENSATION_SEC 取历史位置 + 宽容余量。
	if float(p.get("invuln_timer", 0.0)) > 0.0 and int(p.get("state", C.ST_NORMAL)) == C.ST_INVULN:
		return
	var at: float = maxf(0.0, _srv_time - C.LAG_COMPENSATION_SEC)
	var hist_pos: Vector3 = _history_position(int(p["network_id"]), at)
	var flat := Vector2(hist_pos.x, hist_pos.z)

	var live_limit: float = C.current_arena_radius(_elapsed_time, _arena_radius) - C.PLAYER_RADIUS
	if flat.length() > live_limit - C.HIT_FORGIVENESS:
		var reason: String = "SHRINK_RING" if _elapsed_time > C.SHRINK_START_SEC else "EDGE_SPIKES"
		_handle_fatal_hit(p, reason, 0)
		return

	for raw in _hazards.values():
		var h: Dictionary = raw
		if int(h["state"]) != C.HAZARD_STATE_ACTIVE:
			continue
		var hz_type: int = int(h["type"])
		var height_ok: bool = hist_pos.y >= float(h["clear_height"]) - C.HIT_FORGIVENESS
		if hz_type == C.HZ_SAW:
			var saw_pos: Vector2 = h["saw_pos"]
			var hit_r: float = C.SAW_RADIUS + C.PLAYER_RADIUS - C.HIT_FORGIVENESS
			if flat.distance_to(saw_pos) <= hit_r and hist_pos.y < 0.35:
				_handle_fatal_hit(p, "SAW", 0)
				return
		elif hz_type == C.HZ_LASER:
			var half: float = float(h["width"]) * 0.5 + C.PLAYER_RADIUS - C.HIT_FORGIVENESS
			if C.point_chord_distance(flat, h["n"], float(h["d"])) <= half and not height_ok:
				var ha: Vector2 = h["a"]
				var hb: Vector2 = h["b"]
				var total_len: float = ha.distance_to(hb)
				if total_len > 0.2:
					var seg_dir: Vector2 = (hb - ha) / total_len
					var gap_t: float = float(h.get("gap_t", 0.5))
					var gap_w: float = float(h.get("gap_width", C.LASER_GAP_WIDTH))
					var gap_c: float = clampf(gap_t * total_len, gap_w * 0.65, total_len - gap_w * 0.65)
					var proj: float = (flat - ha).dot(seg_dir)
					if absf(proj - gap_c) <= gap_w * 0.5 - C.PLAYER_RADIUS * 0.3:
						continue
				_handle_fatal_hit(p, C.hazard_name(hz_type), 0)
				return
		else:
			var half: float = float(h["width"]) * 0.5 + C.PLAYER_RADIUS - C.HIT_FORGIVENESS
			if C.point_chord_distance(flat, h["n"], float(h["d"])) <= half and not height_ok:
				_handle_fatal_hit(p, C.hazard_name(hz_type), 0)
				return


func _handle_fatal_hit(p: Dictionary, reason: String, killer_id: int) -> void:
	if bool(p.get("shield", false)):
		p["shield"] = false
		p["state"] = C.ST_INVULN
		p["invuln_timer"] = 0.85
		var flat := Vector2(p["pos"].x, p["pos"].z)
		var inward: Vector2 = -flat.normalized() if flat.length_squared() > 0.01 else Vector2(0.0, 1.0)
		var safe_r: float = maxf(1.0, C.current_arena_radius(_elapsed_time, _arena_radius) - C.PLAYER_RADIUS - 1.2)
		if flat.length() > safe_r:
			flat = flat.normalized() * safe_r
			p["pos"].x = flat.x
			p["pos"].z = flat.y
		p["last_vel"] = inward * 6.5
		_spawn_fx(_fx_dust_scene, Vector3(p["pos"].x, 0.9, p["pos"].z), 0.55, 1.0)
		_spawn_score_popup(Vector3(p["pos"].x, 2.4, p["pos"].z), "護盾抵擋!", Color(0.36, 0.92, 1.0))
		if _sfx_ding != null:
			_sfx_ding.play()
		return
	_eliminate_player(p, reason, killer_id)


func _eliminate_player(p: Dictionary, reason: String, _killer: int) -> void:
	if not bool(p["alive"]):
		return
	p["alive"] = false
	p["state"] = C.ST_OUT
	p["out_reason"] = reason
	p["elim_time"] = _elapsed_time
	_spawn_fx(_fx_dust_scene, Vector3(p["pos"].x, 0.7, p["pos"].z), 0.5, 2.0)
	if _fx_pool != null:
		_fx_pool.spawn_scorch_decal(p["pos"] as Vector3, 1.9)
		_fx_pool.spawn_flash_light(p["pos"] as Vector3, Color(1.0, 0.42, 0.16), 3.6, 6.0, 0.22)
	if _sfx_elim != null:
		_sfx_elim.play()
	if _is_server_sim and not _standalone_mode:
		_rpc_elimination.rpc(int(p["network_id"]), reason)


@rpc("authority", "call_remote", "reliable")
func _rpc_elimination(net_id: int, reason: String) -> void:
	if not _players.has(net_id):
		return
	var p: Dictionary = _players[net_id]
	p["alive"] = false
	p["state"] = C.ST_OUT
	p["out_reason"] = reason
	_players[net_id] = p
	_spawn_fx(_fx_dust_scene, Vector3(p["pos"].x, 0.7, p["pos"].z), 0.5, 2.0)
	if _fx_pool != null:
		_fx_pool.spawn_scorch_decal(p["pos"] as Vector3, 1.9)
		_fx_pool.spawn_flash_light(p["pos"] as Vector3, Color(1.0, 0.42, 0.16), 3.6, 6.0, 0.22)
	if _sfx_elim != null:
		_sfx_elim.play()


func _accrue_scores(delta: float) -> void:
	## 正式计时开始后每存活 1 秒 +1；出局即停止计分，已获分数保留。
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		if not bool(p["alive"]):
			continue
		p["alive_sec"] = float(p["alive_sec"]) + delta
		var sec: int = int(floor(float(p["alive_sec"])))
		while sec > int(p["last_scored_sec"]):
			p["score"] = int(p["score"]) + C.SCORE_PER_SECOND
			p["last_scored_sec"] = int(p["last_scored_sec"]) + 1


func _check_round_end() -> void:
	if _phase != PH_LIVE:
		return
	var team_mode: bool = _team != null and _team.is_active()
	if not team_mode:
		var alive_count: int = 0
		for net_id in _players.keys():
			if bool(_players[net_id]["alive"]):
				alive_count += 1
		var all_out: bool = (alive_count == 0 and _players.size() > 0)
		var time_up: bool = (_time_remaining <= 0.0)
		if not all_out and not time_up:
			return
		_finish_round(time_up)
		return

	var counts: Dictionary = _team.count_alive_teams_dict(_players)
	var alive_ids: Array = counts["alive_ids"]
	var alive_teams: Dictionary = counts["alive_teams"]
	var all_out_t: bool = (alive_ids.is_empty() and _players.size() > 0)
	var team_decided: bool = (alive_teams.size() <= 1 and _players.size() > 1)
	var time_up_t: bool = (_time_remaining <= 0.0)
	if not all_out_t and not team_decided and not time_up_t:
		return
	_early_win_tid = 0
	if team_decided and alive_teams.size() == 1:
		var only_key: int = int(alive_teams.keys()[0])
		if only_key > 0:
			_early_win_tid = only_key
	_finish_round(time_up_t or _early_win_tid > 0)


func _finish_round(time_up: bool) -> void:
	_phase = PH_ENDED
	if time_up:
		for net_id in _players.keys():
			var p: Dictionary = _players[net_id]
			if bool(p["alive"]):
				p["score"] = int(p["score"]) + C.SCORE_SURVIVAL_BONUS
				_spawn_score_popup(Vector3(p["pos"].x, 2.6, p["pos"].z), "+10 存活!", Color(1.0, 0.86, 0.28))
	var team_mode: bool = _team != null and _team.is_active()
	var alive_ids: Array = []
	var entries: Array = []
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		if bool(p["alive"]):
			alive_ids.append(int(net_id))
		var row: Dictionary = {
			"network_id": int(p["network_id"]),
			"nickname": str(p["nickname"]),
			"score": int(p["score"]),
			"alive_sec": float(p["alive_sec"]),
			"pushes": int(p["pushes"]),
			"hits_taken": int(p["hits_taken"]),
			"out_reason": str(p["out_reason"]),
			"alive": bool(p["alive"]),
		}
		if team_mode:
			row["team_id"] = _team.player_team(int(p["network_id"]))
		entries.append(row)
	var ranked: Array = C.rank_entries(entries)
	var official: Dictionary = C.official_scores(ranked)
	var banner_text: String = "ROUND COMPLETE"
	if team_mode:
		official = _team.sync_scores(official, alive_ids)
		_team.notify_round_win(official, self)
		if not _standalone_mode:
			_team.mark_scores_applied(self)
		var winner_tid: int = _early_win_tid
		if winner_tid <= 0 and ranked.size() > 0:
			winner_tid = int(ranked[0].get("team_id", 0))
		if winner_tid > 0:
			banner_text = _team.team_win_banner(winner_tid)
	_mpm_last_official = official
	_result_rows = ranked
	_banner_label.text = banner_text
	if not _standalone_mode and multiplayer.is_server():
		_rpc_round_result.rpc(ranked)
	if _standalone_mode:
		return
	round_finished.emit(official)


@rpc("authority", "call_remote", "reliable")
func _rpc_round_result(ranked: Array) -> void:
	_result_rows = ranked
	_phase = PH_ENDED
	_banner_label.text = "ROUND COMPLETE"


# ============================================================================
# 7. 联机同步：服务器快照 / 客户端插值与外推
# ============================================================================

func _broadcast_snapshot() -> void:
	var p_snap: Dictionary = {}
	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		p_snap[net_id] = [
			p["pos"], p["facing"], int(p["state"]), int(p["score"]),
			float(p["alive_sec"]), int(p["pushes"]), int(p["hits_taken"]),
			float(p["push_cooldown"]), bool(p["alive"]), str(p["out_reason"]),
			float(p["vel_y"]), bool(p.get("shield", false)), int(p.get("power_item", C.ITEM_NONE)),
		]
	_rpc_snapshot.rpc(_srv_time, _phase, _prep_remaining, _time_remaining, p_snap)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_snapshot(srv_time: float, phase: int, prep_remaining: float, time_remaining: float, p_snap: Dictionary) -> void:
	_srv_time_est = maxf(_srv_time_est, srv_time)
	_phase = phase
	_prep_remaining = prep_remaining
	_time_remaining = time_remaining
	var snap: Dictionary = {"t": srv_time, "players": {}}
	for net_id in p_snap.keys():
		if not _players.has(net_id):
			continue
		var arr: Array = p_snap[net_id]
		var p: Dictionary = _players[net_id]
		p["pos"] = arr[0]
		p["facing"] = arr[1]
		p["state"] = int(arr[2])
		p["score"] = int(arr[3])
		p["alive_sec"] = float(arr[4])
		p["pushes"] = int(arr[5])
		p["hits_taken"] = int(arr[6])
		p["push_cooldown"] = float(arr[7])
		p["alive"] = bool(arr[8])
		p["out_reason"] = str(arr[9])
		p["vel_y"] = float(arr[10])
		if arr.size() > 11:
			p["shield"] = bool(arr[11])
		if arr.size() > 12:
			p["power_item"] = int(arr[12])
		_players[net_id] = p
		snap["players"][net_id] = {
			"pos": arr[0],
			"facing": arr[1],
			"vel_y": float(arr[10]),
			"alive": bool(arr[8]),
		}
	_snap_buffer.append(snap)
	while _snap_buffer.size() > 8:
		_snap_buffer.remove_at(0)

	var cd: int = int(ceil(_prep_remaining))
	if _phase == PH_PREP and cd != _last_countdown_sec and cd > 0 and cd <= 3:
		_last_countdown_sec = cd
		_banner_label.text = str(cd)
		if _sfx_beep != null:
			_sfx_beep.play()
	elif _phase == PH_LIVE and _banner_label.text == str(int(ceil(C.PREP_DURATION_SEC))):
		_banner_label.text = "GO!"


func _apply_snapshot_interpolation(delta: float) -> void:
	## 客户端：按 render_time 在最近两个快照间插值；本地玩家额外做限速外推。
	if _snap_buffer.size() < 2:
		return
	var target_t: float = _render_time()
	var a: Dictionary = _snap_buffer[_snap_buffer.size() - 2]
	var b: Dictionary = _snap_buffer[_snap_buffer.size() - 1]
	var t0: float = float(a["t"])
	var t1: float = float(b["t"])
	var alpha: float = 1.0
	if t1 > t0:
		alpha = clampf((target_t - t0) / (t1 - t0), 0.0, 1.0)
	for net_id in _players.keys():
		if not (a["players"] as Dictionary).has(net_id) or not (b["players"] as Dictionary).has(net_id):
			continue
		var pa: Dictionary = (a["players"] as Dictionary)[net_id]
		var pb: Dictionary = (b["players"] as Dictionary)[net_id]
		var pos_a: Vector3 = pa["pos"]
		var pos_b: Vector3 = pb["pos"]
		var interp: Vector3 = pos_a.lerp(pos_b, alpha)
		# 外推：超出最新快照的时间用速度补，限幅避免高延迟下"瞬移"。
		var lead: float = clampf(target_t - t1, 0.0, 0.12)
		if lead > 0.0 and net_id == _local_net_id:
			var p: Dictionary = _players[net_id]
			var lv: Vector2 = p.get("last_vel", Vector2.ZERO)
			interp += Vector3(lv.x, 0.0, lv.y) * lead * 0.55
		var pl: Dictionary = _players[net_id]
		var smooth: float = 1.0 - exp(-22.0 * delta)
		pl["render_pos"] = (pl["render_pos"] as Vector3).lerp(interp, smooth)
		pl["facing"] = pb["facing"]
		_players[net_id] = pl


func player_disconnected(network_id: int) -> void:
	## 掉线清理：立即出局并停止计分，不中途复活。
	if not _players.has(network_id):
		return
	var p: Dictionary = _players[network_id]
	if bool(p["alive"]):
		p["alive"] = false
		p["state"] = C.ST_OUT
		p["out_reason"] = "DISCONNECTED"
		_players[network_id] = p
	_client_inputs.erase(network_id)


# ============================================================================
# 8. 表现层：视觉、HUD、特效
# ============================================================================

func _warmup_fx_pipelines() -> void:
	pass


func _init_fx_pools() -> void:
	if _fx_pool != null:
		_fx_pool.init_pools(self)


func _step_fx_pools(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.step_fx_pools(delta)


func _spawn_fx(scene: PackedScene, world_pos: Vector3, scale_val: float, lifetime: float) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_fx(self, scene, world_pos, scale_val, lifetime)


func _animate_visuals(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	if _camera != null:
		if _cam_shake > 0.001:
			_cam_shake = maxf(0.0, _cam_shake - delta * 1.4)
			_camera.position = _cam_base_pos + Vector3(
				sin(t * 58.0) * _cam_shake,
				cos(t * 47.0) * _cam_shake * 0.5,
				0.0
			)
		else:
			_camera.position = _cam_base_pos

	for net_id in _players.keys():
		var p: Dictionary = _players[net_id]
		var node: Node3D = p["node"]
		var rp: Vector3 = p["render_pos"] if _is_server_sim == false else p["pos"]
		node.position = rp
		var f: Vector2 = p["facing"]
		var target_yaw: float = atan2(f.x, f.y)
		node.rotation.y = lerp_angle(node.rotation.y, target_yaw, minf(1.0, delta * 18.0))
		var alive: bool = bool(p["alive"])
		node.set_meta(&"mpm_alive", alive)
		var fallen: bool = int(p["state"]) == C.ST_FALLEN
		var shoving: bool = float(p.get("shove_anim_timer", 0.0)) > 0.0
		var ap = p.get("anim_player", null)
		if ap is AnimationPlayer:
			var anim_p: AnimationPlayer = ap
			var vel_len_sq: float = (p.get("last_vel", Vector2.ZERO) as Vector2).length_squared()
			var moving: bool = vel_len_sq > 0.12
			if fallen:
				if anim_p.has_animation(&"mp_mod/shoved") and anim_p.current_animation != &"mp_mod/shoved":
					anim_p.play(&"mp_mod/shoved", 0.06)
				anim_p.speed_scale = 1.0
				node.rotation_degrees.z = 0.0
			elif shoving:
				var shove_anim: StringName = &"mp_mod/shove" if anim_p.has_animation(&"mp_mod/shove") else &"mp_mod/shoved"
				if anim_p.has_animation(shove_anim) and anim_p.current_animation != shove_anim:
					anim_p.play(shove_anim, 0.05)
				anim_p.speed_scale = 1.35
				node.rotation_degrees.z = 0.0
			elif moving:
				if anim_p.has_animation(&"mp_mod/run") and anim_p.current_animation != &"mp_mod/run":
					anim_p.play(&"mp_mod/run", 0.12)
				anim_p.speed_scale = clampf(sqrt(vel_len_sq) / maxf(0.1, C.PLAYER_MOVE_SPEED), 0.65, 1.15)
				node.rotation_degrees.z = 0.0
			else:
				if anim_p.has_animation(&"mp_mod/idle") and anim_p.current_animation != &"mp_mod/idle":
					anim_p.play(&"mp_mod/idle", 0.14)
				anim_p.speed_scale = 1.0
				node.rotation_degrees.z = 0.0
		else:
			node.rotation_degrees.z = 68.0 if fallen else 0.0

		var shield_n = p.get("shield_node", null)
		if shield_n is Node3D and is_instance_valid(shield_n):
			var sn: Node3D = shield_n
			var has_sh: bool = bool(p.get("shield", false)) and alive
			sn.visible = has_sh
			if has_sh:
				sn.rotation.y = t * 1.8
				var ra := sn.get_node_or_null("RingA") as Node3D
				var rb := sn.get_node_or_null("RingB") as Node3D
				if ra != null:
					ra.rotation.y = t * 2.2
				if rb != null:
					rb.rotation.y = -t * 1.9

		var aura_n = p.get("power_aura", null)
		if aura_n is Node3D and is_instance_valid(aura_n):
			var an: Node3D = aura_n
			var pi_val: int = int(p.get("power_item", C.ITEM_NONE))
			var show_gold: bool = alive and (pi_val == C.ITEM_POWER_SHOVE)
			var show_red: bool = alive and (pi_val == C.ITEM_SHOCKWAVE)
			var gr := an.get_node_or_null("GoldRing") as Node3D
			var rr := an.get_node_or_null("RedRing") as Node3D
			if gr != null:
				gr.visible = show_gold
			if rr != null:
				rr.visible = show_red
			if show_gold or show_red:
				var pulse_s: float = 0.94 + 0.10 * sin(t * 7.5)
				an.scale = Vector3(pulse_s, 1.0, pulse_s)

		var shadow = p.get("shadow", null)
		if shadow is Node3D and is_instance_valid(shadow):
			var sh: Node3D = shadow
			sh.position = Vector3(0.0, -rp.y + 0.03, 0.0)
			var sh_scale: float = clampf(1.0 - rp.y * 0.42, 0.35, 1.0)
			sh.scale = Vector3(sh_scale, 1.0, sh_scale)

		if not alive:
			node.visible = false
		else:
			node.visible = true
			if int(p["state"]) == C.ST_INVULN:
				node.visible = (int(t * 12.0) % 2 == 0)

	# 机关视觉：激光采用一体化滑车+细红瞄准线->无缝点燃；火带与电锯保留贴地警示带。
	for hid in _hazards.keys():
		if not _hazard_nodes.has(hid):
			continue
		var h: Dictionary = _hazards[hid]
		var pack: Dictionary = _hazard_nodes[hid]
		var st: int = int(h["state"])
		if bool(pack.get("is_laser_rig", false)):
			var rig: Node3D = pack["active"]
			var warn_dur: float = maxf(0.05, float(h.get("active_start", 1.0)) - float(h.get("warn_start", 0.0)))
			var charge_prog: float = clampf((_srv_time - float(h.get("warn_start", 0.0))) / warn_dur, 0.0, 1.0)
			var pulse: float = clampf(charge_prog * 0.65 + 0.35 * (0.5 + 0.5 * sin(t * 22.0)), 0.0, 1.0)
			M.update_laser_rig(
				rig, h["a"], h["b"], float(h["width"]),
				float(h.get("gap_t", 0.5)), float(h.get("gap_width", C.LASER_GAP_WIDTH)),
				st, pulse
			)
			continue
		var warn_node: Node3D = pack["warn"]
		var active_node: Node3D = pack["active"]
		if warn_node != null:
			warn_node.visible = (st == C.HAZARD_STATE_WARN) and (int(t * 10.0) % 2 == 0)
		active_node.visible = (st == C.HAZARD_STATE_ACTIVE)
		if int(h["type"]) == C.HZ_SAW and pack["saw"] != null:
			var saw: Node3D = pack["saw"]
			saw.visible = (st == C.HAZARD_STATE_ACTIVE)
			var sp: Vector2 = h["saw_pos"]
			saw.position = Vector3(sp.x, 0.22, sp.y)
			saw.rotation.y += delta * 18.0
		# 喷火口亮灯
		if int(h["type"]) == C.HZ_FLAME and int(h["nozzle"]) >= 0 and int(h["nozzle"]) < _nozzles.size():
			var nz: Node3D = _nozzles[int(h["nozzle"])]
			nz.scale = Vector3.ONE * (1.15 if st != C.HAZARD_STATE_DONE else 1.0)

	# 真实机械尖刺环收缩（平时在最外圈，最后 25 秒整体向圆心合拢并点亮内侧警戒环）
	if _shrink_ring != null and is_instance_valid(_shrink_ring):
		var cur_r: float = C.current_arena_radius(_elapsed_time, _arena_radius) if _phase == PH_LIVE else _arena_radius
		var ratio: float = clampf(cur_r / maxf(0.1, _arena_radius), 0.35, 1.0)
		_shrink_ring.scale = Vector3(ratio, 1.0, ratio)
		if _shrink_warn != null and is_instance_valid(_shrink_warn):
			_shrink_warn.visible = (_phase == PH_LIVE and _elapsed_time > C.SHRINK_START_SEC)

	# 推人技能巴掌冷却完成弹跳动画
	if _slap_pop_timer > 0.0 and _slap_box != null:
		_slap_pop_timer = maxf(0.0, _slap_pop_timer - delta)
		var p_norm: float = _slap_pop_timer / 0.28
		var s: float = 1.0 + 0.22 * sin(p_norm * PI)
		_slap_box.scale = Vector2(s, s)
	elif _slap_box != null and _slap_box.scale != Vector2.ONE:
		_slap_box.scale = Vector2.ONE
	for raw_fan in _fans:
		var fan := raw_fan as Node3D
		if fan != null and is_instance_valid(fan):
			fan.rotate_z(delta * 4.5)
	_step_fx_pools(delta)

	# 观战：保持俯视全景相机不动，出局玩家仍能完整看到整个场地与所有存活玩家，
	# 不切到低空斜视，避免「看不全」与方向错乱（相机由 _frame_arena 固定）。


func _update_hud() -> void:
	var alive_count: int = 0
	for net_id in _players.keys():
		if bool(_players[net_id]["alive"]):
			alive_count += 1
	if _timer_label != null:
		if _phase == PH_PREP:
			_timer_label.text = "00:0%d" % maxi(0, int(ceil(_prep_remaining)))
			_timer_label.modulate = Color(1.0, 0.84, 0.36)
		else:
			var secs: int = maxi(0, int(ceil(_time_remaining)))
			_timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]
			_timer_label.modulate = Color(1.0, 0.34, 0.24) if _elapsed_time > C.SHRINK_START_SEC else Color(0.68, 1.0, 0.72)
	if _phase_label != null:
		if _phase == PH_PREP:
			_phase_label.text = "PREPARE"
		elif _phase == PH_ENDED:
			_phase_label.text = "ROUND OVER"
		elif _elapsed_time > C.SHRINK_START_SEC:
			_phase_label.text = "RING SHRINKING!"
		else:
			_phase_label.text = "SPIKE RING // %s" % str(_round_cfg.get("name_en", "ARENA"))

	if _players.has(_local_net_id):
		var me: Dictionary = _players[_local_net_id]
		var alive: bool = bool(me["alive"])
		var cd: float = float(me["push_cooldown"])
		var ready: bool = alive and _phase == PH_LIVE and cd <= 0.0
		if _slap_box != null:
			_slap_box.visible = alive and _phase != PH_ENDED
		var p_item: int = int(me.get("power_item", C.ITEM_NONE))
		if _slap_style != null:
			if p_item == C.ITEM_POWER_SHOVE:
				_slap_style.border_color = Color(1.0, 0.74, 0.20, 0.95)
			elif p_item == C.ITEM_SHOCKWAVE:
				_slap_style.border_color = Color(1.0, 0.36, 0.22, 0.95)
			else:
				_slap_style.border_color = Color(0.56, 0.88, 0.60, 0.90)
		if _slap_buff_label != null:
			if p_item == C.ITEM_POWER_SHOVE:
				_slap_buff_label.text = "2x"
				_slap_buff_label.modulate = Color(1.0, 0.80, 0.26)
				_slap_buff_label.visible = true
			elif p_item == C.ITEM_SHOCKWAVE:
				_slap_buff_label.text = "360°"
				_slap_buff_label.modulate = Color(1.0, 0.44, 0.28)
				_slap_buff_label.visible = true
			else:
				_slap_buff_label.visible = false
		if _slap_fill_clip != null and _slap_icon_color != null and _slap_cd_label != null:
			var box_h: float = 70.0
			if not ready and cd > 0.0:
				# 从 0%（全灰）平滑向上充能至 100%（全亮绿）
				var charge: float = clampf(1.0 - cd / maxf(0.01, C.PUSH_COOLDOWN_SEC), 0.0, 1.0)
				var top_px: float = box_h * (1.0 - charge)
				_slap_fill_clip.anchor_top = 1.0 - charge
				_slap_fill_clip.anchor_bottom = 1.0
				_slap_fill_clip.visible = charge > 0.01
				# 保持亮色图标与底层灰图逐像素对齐
				_slap_icon_color.position = Vector2(8.0, 8.0 - top_px)
				_slap_cd_label.text = "%.1f" % cd
				_slap_cd_label.visible = true
			elif _phase == PH_PREP:
				_slap_fill_clip.visible = false
				_slap_cd_label.visible = false
			else:
				_slap_fill_clip.anchor_top = 0.0
				_slap_fill_clip.anchor_bottom = 1.0
				_slap_fill_clip.visible = true
				_slap_icon_color.position = Vector2(8.0, 8.0)
				_slap_cd_label.visible = false
				if not _slap_prev_ready:
					_slap_pop_timer = 0.28
		_slap_prev_ready = ready
		var spectating: bool = not alive
		_spectate_hint.visible = spectating and _phase != PH_ENDED
		if spectating:
			_spectate_hint.text = "已出局（%s）· 观战中" % str(me["out_reason"])

	if _phase == PH_ENDED and not _result_rows.is_empty():
		_result_label.visible = true
		var lines: Array = ["本轮结算 · 总分 / 存活 / 推倒 / 出局原因 / 排名"]
		for raw in _result_rows:
			var e: Dictionary = raw
			var reason: String = str(e.get("out_reason", ""))
			if reason.is_empty():
				reason = "SURVIVED"
			lines.append("#%d  %s  |  %d 分  |  %.1fs  |  推倒 %d  |  %s" % [
				int(e.get("rank", 0)), str(e.get("nickname", "?")), int(e.get("score", 0)),
				float(e.get("alive_sec", 0.0)), int(e.get("pushes", 0)), reason
			])
		_result_label.text = "\n".join(lines)
	else:
		_result_label.visible = false


func _stage_screenshot_action() -> void:
	if _self_test_runner != null:
		_self_test_runner.stage_screenshot_action(self)
	if _fx_pool != null:
		_fx_pool.spawn_scorch_decal(Vector3(-2.6, 0.0, 1.4), 2.2)
		_fx_pool.tick(0.05)


func _save_screenshot_and_quit() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_screenshot_path)
	get_tree().quit(0)


# ============================================================================
# 9. Headless 自测（Tier 0）
# ============================================================================

func _run_smoke_test() -> void:
	if _self_test_runner != null:
		_self_test_runner.run_smoke_test(self)


func _run_self_test() -> void:
	if _self_test_runner != null:
		_self_test_runner.run_self_test(self)
