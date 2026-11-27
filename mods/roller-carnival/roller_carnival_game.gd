extends Node3D

## Roller Carnival (滾筒嘉年華) — 3D Oblique Top-Down Dodge Party Minigame.
##
## Rules:
## - 1-8 players spawn dispersed in the central stage area.
## - Gold High Rollers appear at mid-height on the far right -> tap S (or Down) to crouch under.
## - Silver Low Rollers appear at ground-level on the far right -> press Space to jump over.
## - Rollers keep fixed height and roll left; touching a player applies pure knockback (~1 body width),
##   zero HP loss, cumulative across hits. Being pushed into the left lava pit eliminates immediately.
## - Dodge count increments (+1) per roller safely passed without collision; eliminated players keep
##   their dodge counts for end-of-round ranking & configurable bonus points.
## - Round lasts default 50s; surviving to 0s wins, or ends early if all players are eliminated.

const REG_RES_DIR := "res://mods_roller_carnival/"

var config = null
var _meshes = null
var _team = null
var _fx_pool = null
var _hud_ui = null
var _self_test_runner = null
var _mpm_last_scores: Dictionary = {}

signal round_finished(scores: Dictionary)
var _hosted_in_official_game := false
var _roster: Array = []
const COUNTDOWN_SECONDS := 3.0
const ENTRANCE_SECONDS := 0.75
const ENTRANCE_HEIGHT := 3.0
const RELEASE_CROUCH := 4
const CAM_BASE_POS := Vector3(0.45, 11.8, 11.8)
const CAM_LOOK_TARGET := Vector3(0.35, 0.65, 0.0)
var _held_controls := {}
var _snapshot_timer := 0.0
var _countdown := 0.0

var _rng := RandomNumberGenerator.new()
var _scene_props: Dictionary = {}
var _players: Array[Dictionary] = []
var _rollers: Array[Dictionary] = []

var _players_layer: Node3D
var _rollers_layer: Node3D
var _fx_layer: Node3D

var _elapsed: float = 0.0
var _time_left: float = 50.0
var _spawn_timer: float = 1.0
var _wave_remaining := 0
var _last_roller_type: String = ""
var _same_type_streak: int = 0
var _next_roller_id: int = 1
var _match_ended: bool = false
var _beacon_gold_flash: float = 0.0
var _beacon_silver_flash: float = 0.0
var _camera_shake: float = 0.0
var _cam_sway_time: float = 0.0
var _go_timer: float = 0.0
var _you_marker_timer: float = 0.0
var _you_marker_shown: bool = false
var _last_countdown_ceil: int = 4
var _last_timer_beep_sec: int = -1

# UI References
var _ui_layer: CanvasLayer
var _countdown_label: Label
var _go_label: Label
var _round_banner: Control
var _round_title_label: Label
var _round_tagline_label: Label
var _you_marker: Control
var _results_panel: PanelContainer
var _results_title: Label
var _results_subtitle: Label
var _results_rows: VBoxContainer
var _is_self_test: bool = false
var _screenshot_path: String = ""
var _sfx_shove: AudioStreamPlayer = null
var _sfx_fall: AudioStreamPlayer = null
var _sfx_round_show: AudioStreamPlayer = null
var _sfx_ding: AudioStreamPlayer = null
var _sfx_countdown: AudioStreamPlayer = null
var _sfx_timer_beep: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null
var _shader_layer: CanvasLayer = null
var _fx_hit_blood_scene: PackedScene = null
var _fx_bloodmist_scene: PackedScene = null
var _blood_tex_01: Texture2D = null
var _blood_tex_02: Texture2D = null


func _load_sibling_script(filename: String):
	var reg_res: String = REG_RES_DIR + filename
	if ResourceLoader.exists(reg_res):
		return ResourceLoader.load(reg_res)
	var self_script: Script = get_script() as Script
	if self_script != null and not self_script.resource_path.is_empty():
		var abs_path: String = self_script.resource_path.get_base_dir().path_join(filename)
		if ResourceLoader.exists(abs_path):
			return ResourceLoader.load(abs_path)
	return load("res://" + filename)


func _exit_tree() -> void:
	if _ambience_player != null and is_instance_valid(_ambience_player):
		_ambience_player.stop()
	if _fx_pool != null:
		_fx_pool.clear()
	_ambience_player = null
	_team = null
	_fx_pool = null
	_hud_ui = null
	_self_test_runner = null


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_load_dependencies()
	_rng.randomize()

	var user_args := OS.get_cmdline_user_args()
	for arg in user_args:
		if arg == "--self-test":
			_is_self_test = true
		elif arg.begins_with("--capture-screenshot="):
			_screenshot_path = arg.trim_prefix("--capture-screenshot=")

	_players_layer = Node3D.new()
	_players_layer.name = "PlayersLayer"
	add_child(_players_layer)

	_rollers_layer = Node3D.new()
	_rollers_layer.name = "RollersLayer"
	add_child(_rollers_layer)

	_fx_layer = Node3D.new()
	_fx_layer.name = "EffectsLayer"
	add_child(_fx_layer)

	_scene_props = _meshes.build_stage_and_environment(self, config)
	_build_post_fx_and_audio()
	_hosted_in_official_game = get_parent().has_method("all_players_loaded")
	_build_ui()

	if _is_self_test:
		_run_self_tests()
		return

	if not _hosted_in_official_game:
		if DisplayServer.get_name() != "headless":
			DisplayServer.set_icon(_meshes.build_roller_icon().get_image())
		start_round([])
		if not _screenshot_path.is_empty():
			await get_tree().create_timer(4.7).timeout
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			DirAccess.make_dir_recursive_absolute(_screenshot_path.get_base_dir())
			var error := image.save_png(_screenshot_path)
			if error == OK:
				print("SCREENSHOT_SAVED=" + _screenshot_path)
			get_tree().quit(error)


func _loc_or(key: String, fallback: String) -> String:
	var translated := tr(key)
	return fallback if (translated.is_empty() or translated == key) else translated


@rpc("authority", "call_local", "reliable")
func start_round(roster: Array) -> void:
	_roster = roster
	_start_new_round()
	# The briefing and the stage share a viewport in the official game.
	$StageCamera.make_current()
	_countdown = COUNTDOWN_SECONDS
	_update_entrance()
	_countdown_label.text = str(ceili(_countdown))
	_countdown_label.show()

	if not _is_self_test and _round_banner != null:
		var round_num := 1
		var total_num := 1
		if not _roster.is_empty() and _roster[0] is Dictionary:
			round_num = int((_roster[0] as Dictionary).get("round_number", 1))
			total_num = int((_roster[0] as Dictionary).get("total_rounds", 1))
		_round_title_label.text = _loc_or("LOC_IM_ROUND", "Round %s/%s") % [round_num, total_num]
		_round_tagline_label.text = _loc_or("LOC_MG_TAGLINE_11", "SURVIVAL IS UNLIKELY.")
		_round_tagline_label.visible_ratio = 0.0
		_round_banner.modulate.a = 1.0
		_round_banner.visible = true
		_countdown_label.modulate.a = 0.0
		if _sfx_round_show != null and _screenshot_path.is_empty():
			_sfx_round_show.play()


func _update_entrance() -> void:
	var progress := clampf((COUNTDOWN_SECONDS - _countdown) / ENTRANCE_SECONDS, 0.0, 1.0)
	for player in _players:
		var visual: Node3D = player["visual"]
		visual.position.y = ENTRANCE_HEIGHT * (1.0 - progress * progress)


func player_disconnected(_network_id: int) -> void:
	for p in _players:
		if int(p.get("network_id", -1)) == _network_id and bool(p["alive"]):
			_eliminate_player(p)


func _load_dependencies() -> void:
	if config == null:
		var cfg_script = _load_sibling_script("config.gd")
		config = cfg_script.new()
	if _meshes == null:
		_meshes = _load_sibling_script("carnival_meshes.gd")
	_meshes.ensure_game_pck_mounted()
	if _team == null:
		var ts = _load_sibling_script("team_support.gd")
		if ts != null:
			_team = ts.new()
	if _fx_pool == null:
		var fp = _load_sibling_script("fx_pool.gd")
		if fp != null:
			_fx_pool = fp.new()
	if _hud_ui == null:
		var hu = _load_sibling_script("hud_ui.gd")
		if hu != null:
			_hud_ui = hu.new()
	if _self_test_runner == null:
		var st = _load_sibling_script("self_test.gd")
		if st != null:
			_self_test_runner = st.new()


func _build_post_fx_and_audio() -> void:
	# Audio cues from Machine Party (skipped during headless self-test)
	if not _is_self_test:
		var shove_stream = _meshes.load_optional("res://audio/unique/disco dodge/dd shove.ogg")
		if shove_stream is AudioStream:
			_sfx_shove = AudioStreamPlayer.new()
			_sfx_shove.stream = shove_stream
			_sfx_shove.volume_db = -3.0
			add_child(_sfx_shove)

		var fall_stream = _meshes.load_optional("res://audio/unique/disco dodge/dd fall scream impact.ogg")
		if fall_stream is AudioStream:
			_sfx_fall = AudioStreamPlayer.new()
			_sfx_fall.stream = fall_stream
			_sfx_fall.volume_db = -2.0
			add_child(_sfx_fall)

		var round_stream = _meshes.load_optional("res://audio/unique/intermission/intermission show round1.ogg")
		if round_stream is AudioStream:
			_sfx_round_show = AudioStreamPlayer.new()
			_sfx_round_show.stream = round_stream
			_sfx_round_show.pitch_scale = 0.6
			_sfx_round_show.volume_db = -3.0
			add_child(_sfx_round_show)

		var ding_stream = _meshes.load_optional("res://audio/sfx/airplane ding.ogg")
		if ding_stream is AudioStream:
			_sfx_ding = AudioStreamPlayer.new()
			_sfx_ding.stream = ding_stream
			_sfx_ding.volume_db = -4.0
			add_child(_sfx_ding)

		var cd_stream = _meshes.load_optional("res://audio/sfx/countdown_mechanism2.ogg")
		if cd_stream is AudioStream:
			_sfx_countdown = AudioStreamPlayer.new()
			_sfx_countdown.stream = cd_stream
			_sfx_countdown.volume_db = -4.0
			add_child(_sfx_countdown)

		var beep_stream = _meshes.load_optional("res://audio/sfx/ekg_beep.ogg")
		if beep_stream is AudioStream:
			_sfx_timer_beep = AudioStreamPlayer.new()
			_sfx_timer_beep.stream = beep_stream
			_sfx_timer_beep.volume_db = -9.0
			add_child(_sfx_timer_beep)

		var amb_stream = _meshes.load_optional("res://audio/ambience/industrial-machine-cycle_loop.ogg")
		if amb_stream == null:
			amb_stream = _meshes.load_optional("res://audio/unique/dvd roomba/dvd roomba ambience.ogg")
		if amb_stream is AudioStream and _screenshot_path.is_empty():
			if amb_stream is AudioStreamOggVorbis:
				(amb_stream as AudioStreamOggVorbis).loop = true
			_ambience_player = AudioStreamPlayer.new()
			_ambience_player.stream = amb_stream
			_ambience_player.volume_db = -14.0
			add_child(_ambience_player)
			_ambience_player.play()

		var hit_scene = _meshes.load_optional("res://prefabs/managed_effects/hit_blood.tscn")
		if hit_scene is PackedScene:
			_fx_hit_blood_scene = hit_scene as PackedScene
		var mist_scene = _meshes.load_optional("res://prefabs/managed_effects/bloodmist_01.tscn")
		if mist_scene is PackedScene:
			_fx_bloodmist_scene = mist_scene as PackedScene
		var bt1 = _meshes.load_optional("res://textures/decals/blood decals/blood_splat_01.png")
		if bt1 is Texture2D:
			_blood_tex_01 = bt1 as Texture2D
		var bt2 = _meshes.load_optional("res://textures/decals/blood decals/blood_splat_02.png")
		if bt2 is Texture2D:
			_blood_tex_02 = bt2 as Texture2D
		_warmup_fx_pipelines.call_deferred()

	# Machine Party signature vignette + 8-step posterization with BackBufferCopy on layer 1 (below HUD layer 2)
	var post_shader = _meshes.load_optional("res://shaders/posterization.gdshader")
	var vig_shader = _meshes.load_optional("res://shaders/vignette.gdshader")
	if post_shader is Shader or vig_shader is Shader:
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
			vig_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
			vig_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fx_root.add_child(vig_holder)

			var vig_copy := BackBufferCopy.new()
			vig_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
			vig_holder.add_child(vig_copy)

			var vig_rect := ColorRect.new()
			vig_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			vig_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var vm := ShaderMaterial.new()
			vm.shader = vig_shader
			vm.set_shader_parameter("radius", 0.93)
			vm.set_shader_parameter("softness", 0.44)
			vm.set_shader_parameter("intensity", 1.32)
			vm.set_shader_parameter("contrast", 1.22)
			vm.set_shader_parameter("vignette_color", Color(0.0, 0.0, 0.0, 1.0))
			vig_rect.material = vm
			vig_holder.add_child(vig_rect)

		if post_shader is Shader:
			var post_holder := Control.new()
			post_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
			post_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fx_root.add_child(post_holder)

			var post_copy := BackBufferCopy.new()
			post_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
			post_holder.add_child(post_copy)

			var post_rect := ColorRect.new()
			post_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pm := ShaderMaterial.new()
			pm.shader = post_shader
			pm.set_shader_parameter("SCREEN_WIDTH", 1920.0)
			pm.set_shader_parameter("RED_COMPONENT", 8.0)
			pm.set_shader_parameter("GREEN_COMPONENT", 8.0)
			pm.set_shader_parameter("BLUE_COMPONENT", 8.0)
			post_rect.material = pm
			post_holder.add_child(post_rect)


func _start_new_round() -> void:
	for child in _players_layer.get_children():
		child.queue_free()
	for child in _rollers_layer.get_children():
		child.queue_free()
	for child in _fx_layer.get_children():
		child.queue_free()

	_players.clear()
	_rollers.clear()
	if _fx_pool != null:
		_fx_pool.clear()
	_mpm_last_scores.clear()

	_elapsed = 0.0
	_time_left = config.round_duration
	_wave_remaining = 0
	_spawn_timer = 0.75
	_last_roller_type = ""
	_same_type_streak = 0
	_next_roller_id = 1
	_match_ended = false
	_snapshot_timer = 0.0
	_camera_shake = 0.0
	_go_timer = 0.0
	_you_marker_timer = 0.0
	_you_marker_shown = false
	_last_countdown_ceil = 4
	_last_timer_beep_sec = -1

	if _results_panel != null:
		_results_panel.visible = false
	if _go_label != null:
		_go_label.visible = false
	if _round_banner != null:
		_round_banner.visible = false
	if _you_marker != null:
		_you_marker.active = false
		_you_marker.visible = false

	if _meshes != null:
		_meshes.update_starting_line(_scene_props, config)
	_init_fx_pools()
	_spawn_players()


func _resolve_roster_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if _hosted_in_official_game or not _roster.is_empty():
		entries.assign(_roster)
	else:
		var count: int = clampi(config.max_players, 1, 16)
		for i in range(count):
			entries.append({
				"id": i,
				"network_id": i + 1,
				"nickname": _meshes.PLAYER_NAMES[i % _meshes.PLAYER_NAMES.size()],
			})
	return entries


func _spawn_players() -> void:
	var roster: Array[Dictionary] = _resolve_roster_entries()
	if _team != null:
		_team.begin_match(self, roster)
	var synced_roster: Array = _team.annotate_roster(roster) if (_team != null and _team.is_active()) else roster
	var count: int = synced_roster.size()
	# Option A: All 1-16 players stand shoulder-to-shoulder on the exact same starting line (player_spawn_x)
	var z_span: float = 7.5 if count > 8 else 6.3
	var char_scale: float = 0.76 if count > 12 else (0.86 if count > 8 else 1.0)
	var spawn_x: float = config.player_spawn_x
	var local_nid := multiplayer.get_unique_id() if _hosted_in_official_game else 1
	for i in range(count):
		var entry: Dictionary = synced_roster[i]
		var frac: float = 0.5 if count == 1 else float(i) / float(count - 1)
		var spawn_z: float = lerpf(-z_span * 0.5, z_span * 0.5, frac)
		var nickname: String = str(entry["nickname"])
		var nid: int = int(entry["network_id"])
		var is_local: bool = (nid == local_nid)
		var cust_raw = entry.get("customization", [])
		var cust: Array = cust_raw if cust_raw is Array else []
		var visual_dict: Dictionary = _meshes.build_cartoon_character(i, nickname, cust, is_local)
		var pnode: Node3D = visual_dict["root"]
		pnode.position = Vector3(spawn_x, 0.0, spawn_z)
		pnode.scale = Vector3.ONE * char_scale
		_players_layer.add_child(pnode)

		_players.append({
			"id": i,
			"network_id": nid,
			"team_id": 0,
			"is_local": is_local,
			"nickname": nickname,
			"color": _meshes.PLAYER_COLORS[i % _meshes.PLAYER_COLORS.size()],
			"node": pnode,
			"visual": visual_dict["visual"],
			"shadow": visual_dict["shadow"],
			"label": visual_dict["label"],
			"anim_player": visual_dict.get("anim_player", null),
			"x": spawn_x,
			"y": 0.0,
			"z": spawn_z,
			"alive": true,
			"dodges": 0,
			"survival_time": 0.0,
			"crouching": false,
			"crouch_remaining": 0.0,
			"crouch_ready_in": 0.0,
			"ai_held": 0,
			"jumping": false,
			"jump_timer": 0.0,
			"recovery_timer": 0.0,
			"knockback_remaining": 0.0,
			"knockback_timer": 0.0,
			"knockback_cooldown": 0.0,
			"hit_flash": 0.0,
			"sink_progress": 0.0,
			"ai_target_action": "",
			"ai_reaction_delay": _rng.randf_range(0.03, 0.16),
			"ai_mistake_rate": 0.14 + float(i % 4) * 0.05,
			"ai_decided_roller_id": -1,
		})

	if _team != null and _team.is_active() and not _players.is_empty():
		_team.group_lane_spawns(_players)
		for p in _players:
			var nid: int = int(p["network_id"])
			var tid: int = _team.player_team(nid)
			p["team_id"] = tid
			if tid > 0:
				var pnode: Node3D = p.get("node", null) as Node3D
				if pnode != null:
					_team.attach_foot_ring(pnode, tid, 0.36, 0.45)
				var lbl := p.get("label", null) as Label3D
				p["nickname"] = _team.apply_nameplate(lbl, str(p["nickname"]), tid, 11)


func _process(delta: float) -> void:
	if _is_self_test:
		return

	_update_camera(delta)
	_animate_environment(delta)
	_update_particles(delta)
	_step_fx_pools(delta)
	_update_you_marker(delta)

	if _go_timer > 0.0 and _go_label != null:
		_go_timer = maxf(0.0, _go_timer - delta)
		if _go_timer <= 0.0:
			_go_label.visible = false
		else:
			var t_go := 1.0 - clampf(_go_timer / 0.55, 0.0, 1.0)
			_go_label.position.y = lerpf(28.0, 0.0, clampf(t_go * 3.5, 0.0, 1.0))
			_go_label.modulate.a = clampf(_go_timer / 0.35, 0.0, 1.0)

	if _match_ended or _players.is_empty():
		return

	if _countdown > 0:
		_countdown = maxf(0.0, _countdown - delta)
		_update_entrance()
		_step_countdown_overlay()
		return

	if _hosted_in_official_game and not multiplayer.is_server():
		_step_rollers(delta)
		return

	_elapsed += delta
	_time_left = maxf(0.0, _time_left - delta)

	_step_spawner(delta)
	_step_players(delta)
	_step_rollers(delta)
	_resolve_player_spacing(delta)
	if _hosted_in_official_game:
		_snapshot_timer -= delta
		if _snapshot_timer <= 0:
			_snapshot_timer = 0.05
			_send_snapshot()
	_check_round_end()


func _step_countdown_overlay() -> void:
	if _hud_ui != null:
		_hud_ui.step_countdown_overlay(self)


func _find_local_player() -> Dictionary:
	var local_nid := multiplayer.get_unique_id() if _hosted_in_official_game else 1
	for p in _players:
		if int(p.get("network_id", -1)) == local_nid:
			return p
	return _players[0] if not _players.is_empty() else {}


func _update_you_marker(delta: float) -> void:
	if _hud_ui != null:
		_hud_ui.update_you_marker(self, delta)


func _update_camera(delta: float) -> void:
	if _is_self_test:
		return
	var cam := get_node_or_null("StageCamera") as Camera3D
	if cam == null:
		return
	_cam_sway_time += delta
	_camera_shake = maxf(0.0, _camera_shake - delta * 2.6)
	var sway := Vector3(
		sin(_cam_sway_time * 0.55) * 0.07,
		cos(_cam_sway_time * 0.42) * 0.05,
		sin(_cam_sway_time * 0.35) * 0.04
	)
	var mag := 0.28 * _camera_shake * _camera_shake
	var shake := Vector3(
		_rng.randf_range(-1.0, 1.0) * mag,
		_rng.randf_range(-1.0, 1.0) * mag,
		_rng.randf_range(-1.0, 1.0) * mag
	) if _camera_shake > 0.001 else Vector3.ZERO
	cam.look_at_from_position(CAM_BASE_POS + sway + shake, CAM_LOOK_TARGET + shake * 0.35, Vector3.UP)


func _animate_environment(delta: float) -> void:
	var gears: Array = _scene_props.get("gears", [])
	for i in range(gears.size()):
		var g: Node3D = gears[i]
		var dir: float = 1.0 if i % 2 == 0 else -1.0
		g.rotation.z += delta * (0.65 + float(i % 2) * 0.35) * dir

	var shredders: Array = _scene_props.get("pit_shredders", [])
	for i in range(shredders.size()):
		var sh := shredders[i] as Node3D
		if sh != null:
			sh.rotation.z += delta * (-2.8 if i % 2 == 0 else 2.8)

	var bubbles: Array = _scene_props.get("lava_bubbles", [])
	for b in bubbles:
		var node: MeshInstance3D = b["node"]
		var phase: float = b["phase"] + _cam_sway_time * 2.1
		var rise: float = fposmod(phase, TAU) / TAU
		node.position.y = -0.72 + rise * 0.72
		node.rotation.y += delta * 1.4
		var s: float = 1.0 - absf(rise * 2.0 - 1.0) * 0.65
		node.scale = Vector3(s, s, s)

	var bulbs: Array = _scene_props.get("bulbs", [])
	var flicker_mat := _scene_props.get("flicker_lamp_mat") as StandardMaterial3D
	for i in range(bulbs.size()):
		var entry = bulbs[i]
		var mat: StandardMaterial3D = null
		if entry is StandardMaterial3D:
			mat = entry as StandardMaterial3D
		elif entry is MeshInstance3D:
			mat = (entry as MeshInstance3D).material_override as StandardMaterial3D
		if mat != null:
			if mat == flicker_mat:
				var fl_wave: float = sin(_cam_sway_time * 13.7) * sin(_cam_sway_time * 31.3)
				var fl_dip: float = 0.48 if fl_wave > 0.72 else 1.0
				mat.emission_energy_multiplier = 1.65 * fl_dip + 0.12 * sin(_cam_sway_time * 5.3)
			else:
				mat.emission_energy_multiplier = 1.45 + 0.18 * sin(_cam_sway_time * 4.2 + float(i) * 1.7)

	var fans: Array = _scene_props.get("fans", [])
	for raw_fan in fans:
		var fan := raw_fan as Node3D
		if fan != null and is_instance_valid(fan):
			fan.rotate_z(delta * 4.5)

	_beacon_gold_flash = maxf(0.0, _beacon_gold_flash - delta * 2.8)
	_beacon_silver_flash = maxf(0.0, _beacon_silver_flash - delta * 2.8)
	var bg := _scene_props.get("beacon_gold") as MeshInstance3D
	if bg and bg.material_override:
		(bg.material_override as StandardMaterial3D).emission_energy_multiplier = 0.5 + _beacon_gold_flash * 3.0
	var bs := _scene_props.get("beacon_silver") as MeshInstance3D
	if bs and bs.material_override:
		(bs.material_override as StandardMaterial3D).emission_energy_multiplier = 0.5 + _beacon_silver_flash * 3.0

	var timer_lbl := _scene_props.get("monitor_timer_label") as Label3D
	var phase_lbl := _scene_props.get("monitor_phase_label") as Label3D
	if timer_lbl != null:
		var secs_left := ceili(maxf(0.0, _time_left))
		timer_lbl.text = "00:%02d" % secs_left
		if _countdown <= 0.0 and not _match_ended and _time_left <= 10.0 and _time_left > 0.0:
			var pulse := 0.75 + 0.25 * sin(_cam_sway_time * 12.0)
			timer_lbl.modulate = Color(1.0, 0.32 * pulse, 0.22 * pulse)
			if secs_left != _last_timer_beep_sec:
				_last_timer_beep_sec = secs_left
				if _sfx_timer_beep != null and _screenshot_path.is_empty():
					_sfx_timer_beep.play()
		else:
			timer_lbl.modulate = Color(0.53, 0.83, 0.50)
	if phase_lbl != null:
		if _elapsed < config.pair_start_time:
			phase_lbl.text = "WAVE 01 // SINGLE"
		elif _elapsed < config.triple_start_time:
			phase_lbl.text = "WAVE 02 // DOUBLE"
		else:
			phase_lbl.text = "WAVE 03 // OVERDRIVE"


func _current_progress() -> float:
	if config.round_duration <= 0.001:
		return 1.0
	return clampf(_elapsed / config.round_duration, 0.0, 1.0)


func _current_roller_speed() -> float:
	return config.speed_at_progress(_current_progress())


func _step_spawner(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	if _wave_remaining == 0:
		_wave_remaining = config.wave_size(_elapsed)
	_spawn_roller(_pick_next_roller_type(), config.roller_spawn_x)
	_wave_remaining -= 1
	_spawn_timer = config.spawn_interval(_elapsed, _wave_remaining > 0, _rng)


func _pick_next_roller_type() -> String:
	var chosen: String = "gold" if _rng.randf() < config.gold_roller_probability else "silver"
	if chosen == _last_roller_type and _same_type_streak >= config.max_same_type_streak:
		chosen = "silver" if chosen == "gold" else "gold"
	if chosen == _last_roller_type:
		_same_type_streak += 1
	else:
		_last_roller_type = chosen
		_same_type_streak = 1
	return chosen


func _spawn_roller(roller_type: String, spawn_x: float) -> Dictionary:
	var is_gold: bool = (roller_type == "gold")
	var center_y: float = config.gold_roller_center_y if is_gold else config.silver_roller_center_y
	var radius: float = config.gold_roller_radius if is_gold else config.silver_roller_radius

	var built: Dictionary = _meshes.build_roller_mesh(roller_type, radius, 9.0)
	var rnode: Node3D = built["root"]
	rnode.position = Vector3(spawn_x, center_y, 0.0)
	_rollers_layer.add_child(rnode)

	if is_gold:
		_beacon_gold_flash = 1.0
	else:
		_beacon_silver_flash = 1.0

	var roller := {
		"id": _next_roller_id,
		"type": roller_type,
		"node": rnode,
		"spin": built["spin"],
		"x": spawn_x,
		"y": center_y,
		"radius": radius,
		"hit_players": {} as Dictionary,
		"passed_players": {} as Dictionary,
	}
	_next_roller_id += 1
	_rollers.append(roller)
	return roller


func _input(event: InputEvent) -> void:
	var action: int
	var control: Vector2i
	if event is InputEventKey:
		if event.echo:
			return
		match event.keycode:
			KEY_S, KEY_DOWN: action = 1
			KEY_SPACE, KEY_W, KEY_UP: action = 2
			_: return
		control = Vector2i(-1, event.keycode)
	elif event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_B: action = 1
			JOY_BUTTON_A: action = 2
			_: return
		control = Vector2i(event.device, event.button_index)
	else:
		return

	if not event.is_pressed():
		_release_control(control)
		return
	var already_held := action in _held_controls.values()
	_held_controls[control] = action
	if not already_held:
		_dispatch_action(action)


func _release_control(control: Vector2i) -> void:
	var was_crouch := int(_held_controls.get(control, 0)) == 1
	_held_controls.erase(control)
	if was_crouch and not 1 in _held_controls.values():
		_dispatch_action(RELEASE_CROUCH)


func _dispatch_action(action: int) -> void:
	if _countdown > 0 or _match_ended or _players.is_empty():
		return
	if _hosted_in_official_game and not multiplayer.is_server():
		submit_action.rpc_id(1, action)
	else:
		var peer := multiplayer.get_unique_id() if _hosted_in_official_game else 1
		_apply_input(peer, action)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected:
		for control in _held_controls.keys():
			if control.x == device:
				_release_control(control)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for control in _held_controls.keys():
			_release_control(control)


@rpc("any_peer", "call_remote", "reliable")
func submit_action(pressed: int) -> void:
	if multiplayer.is_server() and _countdown <= 0 and not _match_ended:
		_apply_input(multiplayer.get_remote_sender_id(), pressed)


func _apply_input(peer: int, pressed: int) -> void:
	for p in _players:
		if p.network_id == peer:
			_begin_action(p, pressed)
			return


func _begin_action(p: Dictionary, pressed: int) -> void:
	if pressed == RELEASE_CROUCH:
		if p.crouching:
			p.crouching = false
			p.crouch_remaining = 0.0
			p.crouch_ready_in = config.crouch_recovery
		return
	if not p.alive or p.jumping or p.crouch_ready_in > 0 or p.recovery_timer > 0:
		return
	if pressed & 2:
		p.jumping = true
		p.jump_timer = 0.0
	elif pressed & 1:
		p.crouching = true
		p.crouch_remaining = config.crouch_duration
		p.crouch_ready_in = config.crouch_duration + config.crouch_recovery


func _tick_crouch(p: Dictionary, delta: float) -> void:
	p.crouch_remaining = maxf(0.0, p.crouch_remaining - delta)
	p.crouch_ready_in = maxf(0.0, p.crouch_ready_in - delta)
	p.crouching = p.crouch_remaining > 0


func _step_players(delta: float) -> void:
	for p in _players:
		if not p["alive"]:
			p["sink_progress"] = minf(1.0, float(p["sink_progress"]) + delta * 1.8)
			var pnode: Node3D = p["node"]
			pnode.position = Vector3(p["x"], -float(p["sink_progress"]) * 1.6, p["z"])
			pnode.rotation_degrees.z = float(p["sink_progress"]) * 48.0
			continue

		p["survival_time"] = float(p["survival_time"]) + delta
		p["knockback_cooldown"] = maxf(0.0, float(p["knockback_cooldown"]) - delta)
		p["recovery_timer"] = maxf(0.0, float(p["recovery_timer"]) - delta)
		p["hit_flash"] = maxf(0.0, float(p["hit_flash"]) - delta * 3.5)

		# Smooth knockback displacement
		if float(p["knockback_timer"]) > 0.0:
			var step_t: float = minf(delta, float(p["knockback_timer"]))
			var frac: float = step_t / maxf(0.01, float(p["knockback_timer"]))
			var dx: float = float(p["knockback_remaining"]) * frac
			p["x"] = float(p["x"]) - dx
			p["knockback_remaining"] = float(p["knockback_remaining"]) - dx
			p["knockback_timer"] = float(p["knockback_timer"]) - step_t

		var is_ai_seat: bool = (not _hosted_in_official_game and int(p["id"]) > 0)
		if not is_ai_seat and _hosted_in_official_game and multiplayer.is_server():
			var nid: int = int(p["network_id"])
			if nid != 1 and not multiplayer.get_peers().has(nid):
				is_ai_seat = true
		if is_ai_seat:
			var ai := _compute_ai_action(p)
			var held := int(ai.crouch) | (int(ai.jump) << 1)
			_begin_action(p, held & ~int(p.ai_held))
			p.ai_held = held
		_tick_crouch(p, delta)
		if bool(p["jumping"]):
			p["jump_timer"] = float(p["jump_timer"]) + delta
			var t: float = float(p["jump_timer"]) / maxf(0.1, config.jump_air_time)
			if t >= 1.0:
				p["jumping"] = false
				p["jump_timer"] = 0.0
				p["y"] = 0.0
				p["recovery_timer"] = config.landing_recovery_time
			else:
				p["y"] = 4.0 * config.jump_height * t * (1.0 - t)
			p["crouching"] = false
		else:
			p["y"] = 0.0
		# Check lava elimination boundary
		if float(p["x"]) <= config.stage_left_lava_x:
			_eliminate_player(p)
			continue

		_update_player_visuals(p)


func _compute_ai_action(p: Dictionary) -> Dictionary:
	var px: float = float(p["x"])
	var speed: float = maxf(1.0, _current_roller_speed())
	var nearest = null
	var best_dist: float = 999.0

	for r in _rollers:
		var rx: float = float(r["x"])
		var dist: float = rx - px
		if dist >= -0.25 and dist < best_dist:
			best_dist = dist
			nearest = r

	if nearest == null:
		return {"crouch": false, "jump": false}

	var rid: int = int(nearest["id"])
	if int(p["ai_decided_roller_id"]) != rid:
		p["ai_decided_roller_id"] = rid
		var rtype: String = str(nearest["type"])
		if _rng.randf() < float(p["ai_mistake_rate"]):
			p["ai_target_action"] = "none" if _rng.randf() < 0.6 else ("jump" if rtype == "gold" else "crouch")
		else:
			p["ai_target_action"] = "crouch" if rtype == "gold" else "jump"

	var time_to_hit: float = best_dist / speed
	var act: String = str(p["ai_target_action"])
	if act == "crouch" and time_to_hit <= 0.36 + float(p["ai_reaction_delay"]) and best_dist >= -0.35:
		return {"crouch": true, "jump": false}
	if act == "jump" and time_to_hit <= config.jump_air_time * 0.45 and time_to_hit >= 0.0:
		return {"crouch": false, "jump": true}
	return {"crouch": false, "jump": false}


func _update_player_visuals(p: Dictionary) -> void:
	var pnode: Node3D = p["node"]
	var visual: Node3D = p["visual"]
	var shadow: Node3D = p["shadow"]
	var lbl: Label3D = p["label"]

	pnode.position = Vector3(float(p["x"]), 0.0, float(p["z"]))
	visual.position.y = float(p["y"])

	var target_scale := Vector3.ONE
	if bool(p["crouching"]):
		var y_ratio: float = config.crouch_height / maxf(0.5, config.standing_height)
		target_scale = Vector3(1.22, y_ratio, 1.22)
	elif bool(p["jumping"]):
		target_scale = Vector3(0.90, 1.14, 0.90)
	else:
		var bob: float = 0.03 * sin(_elapsed * 7.5 + float(p["id"]))
		target_scale = Vector3(1.0 - bob * 0.4, 1.0 + bob, 1.0 - bob * 0.4)

	visual.scale = visual.scale.lerp(target_scale, 0.35)
	var ap: AnimationPlayer = p.get("anim_player", null)
	if float(p["hit_flash"]) > 0.0:
		visual.rotation_degrees.z = 18.0 * float(p["hit_flash"])
	else:
		visual.rotation_degrees.z = lerpf(visual.rotation_degrees.z, 0.0, 0.25)
		if ap != null and ap.has_animation(&"mp_mod/idle") and ap.current_animation == &"mp_mod/shoved":
			ap.play(&"mp_mod/idle")

	var shadow_scale: float = clampf(1.0 - float(p["y"]) * 0.25, 0.45, 1.0)
	shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale)

	lbl.position.y = (1.35 if bool(p["crouching"]) else 1.88) + float(p["y"])


func _resolve_player_spacing(_delta: float) -> void:
	# Option A: players stay aligned on their Z lanes; scale separation for up to 16 players
	var min_z_sep: float = minf(0.72, 7.2 / float(maxi(1, _players.size())))
	for i in range(_players.size()):
		if not _players[i]["alive"]:
			continue
		for j in range(i + 1, _players.size()):
			if not _players[j]["alive"]:
				continue
			var dz: float = float(_players[i]["z"]) - float(_players[j]["z"])
			if absf(dz) < min_z_sep:
				var sign_z: float = 1.0 if dz >= 0.0 else -1.0
				var push_z: float = (min_z_sep - absf(dz)) * 0.2
				_players[i]["z"] = clampf(float(_players[i]["z"]) + sign_z * push_z, -3.85, 3.85)
				_players[j]["z"] = clampf(float(_players[j]["z"]) - sign_z * push_z, -3.85, 3.85)


# Only the host evaluates collisions. Each packet contains all visible rollers
# so a lost spawn or removal is repaired by the next packet.
func _send_snapshot() -> void:
	var poses := PackedFloat32Array()
	for p in _players:
		poses.append_array(PackedFloat32Array([p.x, p.y, int(p.crouching), int(p.jumping),
			int(p.alive), p.dodges, p.hit_flash, p.sink_progress]))
	var rollers := PackedFloat32Array()
	for r in _rollers:
		rollers.append_array(PackedFloat32Array([r.id, int(r.type == "gold"), r.x]))
	_show_snapshot.rpc(_elapsed, poses, rollers)


@rpc("authority", "call_remote", "unreliable_ordered")
func _show_snapshot(elapsed: float, poses: PackedFloat32Array, rollers: PackedFloat32Array) -> void:
	if _match_ended or poses.size() != _players.size() * 8:
		return
	_elapsed = elapsed
	_time_left = maxf(0, config.round_duration - elapsed)
	for i in range(_players.size()):
		var p := _players[i]
		var offset := i * 8
		p.x = poses[offset]
		p.y = poses[offset + 1]
		p.crouching = bool(poses[offset + 2])
		p.jumping = bool(poses[offset + 3])
		if p.alive and not bool(poses[offset + 4]):
			_eliminate_player(p)
		p.dodges = int(poses[offset + 5])
		var new_flash: float = poses[offset + 6]
		if new_flash > 0.85 and float(p.hit_flash) <= 0.4:
			_play_hit_feedback(p)
		p.hit_flash = new_flash
		_update_player_visuals(p)
		if not p.alive:
			p.node.position.y = -poses[offset + 7] * 1.6
			p.node.rotation_degrees.z = poses[offset + 7] * 48.0
	var existing := {}
	for r in _rollers:
		existing[r.id] = r
	for offset in range(0, rollers.size(), 3):
		var id := int(rollers[offset])
		var r: Dictionary
		if existing.has(id):
			r = existing[id]
			existing.erase(id)
		else:
			r = _spawn_roller("gold" if rollers[offset + 1] else "silver", rollers[offset + 2])
			r.id = id
		r.x = rollers[offset + 2]
		r.node.position.x = r.x
	for r in existing.values():
		_rollers.erase(r)
		r.node.queue_free()


func _step_rollers(delta: float) -> void:
	var speed: float = _current_roller_speed()
	var to_remove: Array[int] = []

	for idx in range(_rollers.size()):
		var r: Dictionary = _rollers[idx]
		r["x"] = float(r["x"]) - speed * delta
		var rnode: Node3D = r["node"]
		rnode.position = Vector3(float(r["x"]), float(r["y"]), 0.0)
		var spin: Node3D = r["spin"]
		spin.rotation.z += (speed * delta) / maxf(0.1, float(r["radius"]))

		if not _hosted_in_official_game or multiplayer.is_server():
			_evaluate_roller_interactions(r)

		if float(r["x"]) < config.roller_despawn_x:
			to_remove.append(idx)

	for i in range(to_remove.size() - 1, -1, -1):
		var rm_idx: int = to_remove[i]
		var dead_node: Node3D = _rollers[rm_idx]["node"]
		dead_node.queue_free()
		_rollers.remove_at(rm_idx)


func _evaluate_roller_interactions(r: Dictionary) -> void:
	var rx: float = float(r["x"])
	var ry: float = float(r["y"])
	var rad: float = float(r["radius"])
	var hit_rad: float = maxf(0.05, rad - 0.06)
	var hit_rad_sq: float = hit_rad * hit_rad
	var r_right: float = rx + rad

	var hit_map: Dictionary = r["hit_players"]
	var pass_map: Dictionary = r["passed_players"]

	for p in _players:
		if not p["alive"]:
			continue
		var pid: int = int(p["id"])
		var px: float = float(p["x"])
		var p_half_w: float = 0.22
		var p_bottom: float = float(p["y"])
		var p_height: float = config.crouch_height if bool(p["crouching"]) else config.standing_height
		var p_top: float = p_bottom + p_height

		var closest_x: float = clampf(rx, px - p_half_w, px + p_half_w)
		var closest_y: float = clampf(ry, p_bottom, p_top)
		var dx: float = rx - closest_x
		var dy: float = ry - closest_y
		var hit: bool = (dx * dx + dy * dy) <= hit_rad_sq

		if hit:
			if not hit_map.has(pid) and float(p["knockback_cooldown"]) <= 0.0:
				hit_map[pid] = true
				_apply_knockback_to_player(p)
		elif r_right < px - p_half_w:
			if not hit_map.has(pid) and not pass_map.has(pid):
				pass_map[pid] = true
				p["dodges"] = int(p["dodges"]) + 1


func _play_hit_feedback(p: Dictionary) -> void:
	if not _is_self_test:
		_camera_shake = maxf(_camera_shake, 0.55)
	var pos := Vector3(float(p["x"]), 0.02, float(p["z"]))
	_spawn_impact_decal(pos, 1.0)
	if not _spawn_vanilla_effect("res://prefabs/managed_effects/hit_blood.tscn", Vector3(pos.x, 0.72, pos.z), 0.38, 1.2):
		_spawn_burst(Vector3(pos.x, 0.75, pos.z), Color(0.42, 0.02, 0.01), 6)
	var ap: AnimationPlayer = p.get("anim_player", null)
	if ap != null and ap.has_animation(&"mp_mod/shoved"):
		ap.play(&"mp_mod/shoved")
	if _sfx_shove != null and not _is_self_test:
		_sfx_shove.play()


func _apply_knockback_to_player(p: Dictionary) -> void:
	p["knockback_remaining"] = float(p["knockback_remaining"]) + config.knockback_distance
	p["knockback_timer"] = config.knockback_duration
	p["knockback_cooldown"] = config.knockback_cooldown
	p["hit_flash"] = 1.0
	_play_hit_feedback(p)

	# In instant/headless step verification or heavy hit, check boundary after knockback applies
	if _is_self_test:
		p["x"] = float(p["x"]) - config.knockback_distance
		p["knockback_remaining"] = 0.0
		p["knockback_timer"] = 0.0
		if float(p["x"]) <= config.stage_left_lava_x:
			_eliminate_player(p)


func _eliminate_player(p: Dictionary) -> void:
	if not p["alive"]:
		return
	p["alive"] = false
	p["sink_progress"] = 0.0
	if not _is_self_test:
		_camera_shake = 1.0
	var lbl: Label3D = p["label"]
	lbl.visible = false
	var pnode = p.get("node", null)
	if pnode is Node:
		(pnode as Node).set_meta(&"mpm_alive", false)
	var ap: AnimationPlayer = p.get("anim_player", null)
	if ap != null and ap.has_animation(&"mp_mod/falling"):
		ap.play(&"mp_mod/falling")
	if _sfx_fall != null and not _is_self_test:
		_sfx_fall.play()
	_spawn_impact_decal(Vector3(config.stage_left_lava_x + 0.35, 0.02, float(p["z"])), 1.35)
	var pit_pos := Vector3(config.stage_left_lava_x - 0.35, 0.35, float(p["z"]))
	if not _spawn_vanilla_effect("res://prefabs/managed_effects/bloodmist_01.tscn", pit_pos, 0.42, 3.2):
		_spawn_burst(pit_pos, Color(0.38, 0.02, 0.01), 14)


func _warmup_fx_pipelines() -> void:
	pass


func _init_fx_pools() -> void:
	if _fx_pool != null:
		_fx_pool.init_pools(self)


func _step_fx_pools(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.step_fx_pools(delta)


func _spawn_vanilla_effect(scene_path: String, origin: Vector3, eff_scale: float, lifetime: float) -> bool:
	if _fx_pool != null:
		return _fx_pool.spawn_vanilla_effect(self, scene_path, origin, eff_scale, lifetime)
	return false


func _spawn_impact_decal(pos: Vector3, scale_mul: float = 1.0) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_impact_decal(self, pos, scale_mul)


func _spawn_burst(origin: Vector3, color: Color, count: int) -> void:
	if _fx_pool != null:
		_fx_pool.spawn_burst(self, origin, color, count)


func _update_particles(delta: float) -> void:
	if _fx_pool != null:
		_fx_pool.update_particles(delta)


func _check_round_end() -> void:
	var team_mode: bool = _team != null and _team.is_active()
	if not team_mode:
		var alive_count: int = 0
		for p in _players:
			if p["alive"]:
				alive_count += 1
		if alive_count == 0:
			_finish_round("全員落入粉碎熔爐淘汰（提前結束）")
		elif _time_left <= 0.0:
			_finish_round("倒計時結束！%d 名存活玩家獲勝" % alive_count)
		return

	var counts: Dictionary = _team.count_alive_teams_array(_players)
	var alive_count_t: int = int(counts["alive_count"])
	var alive_teams: Dictionary = counts["alive_teams"]
	if alive_count_t == 0:
		_finish_round("全員落入粉碎熔爐淘汰（提前結束）")
	elif alive_teams.size() <= 1 and _players.size() > 1:
		var win_tid: int = int(alive_teams.keys()[0]) if alive_teams.size() == 1 else 0
		_finish_round(_team.team_win_banner(win_tid) if win_tid > 0 else "對局提前結束")
	elif _time_left <= 0.0:
		_finish_round("倒計時結束！%d 名存活玩家獲勝" % alive_count_t)


func _compute_rankings() -> Array[Dictionary]:
	var sorted: Array[Dictionary] = []
	for p in _players:
		sorted.append(p)

	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da: int = int(a["dodges"])
		var db: int = int(b["dodges"])
		if da != db:
			return da > db
		if config.tie_break_rule == "survival_time":
			if bool(a["alive"]) != bool(b["alive"]):
				return bool(a["alive"])
			if not is_equal_approx(float(a["survival_time"]), float(b["survival_time"])):
				return float(a["survival_time"]) > float(b["survival_time"])
		return int(a["id"]) < int(b["id"])
	)

	var entries: Array[Dictionary] = []
	var prev_dodges: int = -1
	var prev_rank: int = 1
	for idx in range(sorted.size()):
		var p: Dictionary = sorted[idx]
		var d: int = int(p["dodges"])
		var rank: int = idx + 1
		if config.tie_break_rule == "shared_rank" and idx > 0 and d == prev_dodges:
			rank = prev_rank
		prev_dodges = d
		prev_rank = rank
		var bonus: int = config.bonus_for_rank(rank, sorted.size())
		entries.append({
			"rank": rank,
			"id": int(p["id"]),
			"network_id": int(p.get("network_id", int(p["id"]) + 1)),
			"nickname": str(p["nickname"]),
			"color": p["color"],
			"alive": bool(p["alive"]),
			"dodges": d,
			"survival_time": float(p["survival_time"]),
			"bonus": bonus,
		})
	return entries


func _finish_round(reason: String) -> void:
	if _match_ended:
		return
	_match_ended = true

	var rankings: Array[Dictionary] = _compute_rankings()
	var finalized_scores: Dictionary = {}
	for r in rankings:
		var nid: int = int(r["network_id"])
		var bonus: int = int(r["bonus"])
		finalized_scores[nid] = bonus

	if _team != null and _team.is_active():
		var alive_ids: Array = []
		for p in _players:
			if bool(p["alive"]):
				alive_ids.append(int(p["network_id"]))
		finalized_scores = _team.sync_scores(finalized_scores, alive_ids)
		_team.notify_round_win(finalized_scores, self)
		if _hosted_in_official_game:
			_team.mark_scores_applied(self)

	_mpm_last_scores = finalized_scores
	if _hosted_in_official_game and not _is_self_test:
		show_round_result.rpc(rankings, reason)
	else:
		show_round_result(rankings, reason)
	if _hosted_in_official_game:
		round_finished.emit(finalized_scores)


@rpc("authority", "call_local", "reliable")
func show_round_result(rankings: Array, reason: String) -> void:
	_match_ended = true
	_countdown_label.hide()
	if not _hosted_in_official_game:
		_populate_results_ui(rankings, reason)


func _build_ui() -> void:
	if _hud_ui != null:
		_hud_ui.build_ui(self)


func _populate_results_ui(rankings: Array, reason: String) -> void:
	if _hud_ui != null:
		_hud_ui.populate_results_ui(self, rankings, reason)


func _run_self_tests() -> void:
	if _self_test_runner != null:
		_self_test_runner.run_self_tests(self)
