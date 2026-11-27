extends SceneTree

## Multi-Mod Team Party Sandbox (macOS Interactive Tester + Headless End-to-End Test)
## Combines native:
##   - mods/team-party/* (room team setup, HUD & vanilla minigame hooks)
##   - mods/player-spotlight/main.gd
##   - mods/lobby-bots/main.gd (via live compatible bots + DiscoBrain runner)
##   - mods/bubble-blitz/* (native team mode via team_support.gd)
##   - mods/spike-ring/* (native team mode via team_support.gd)
##   - mods/roller-carnival/* (native team mode via team_support.gd)
## Plus a playable Disco Dodge team brawl arena.

const SCENE_LOBBY := 0
const SCENE_BUBBLE := 1
const SCENE_SPIKE := 2
const SCENE_ROLLER := 3
const SCENE_DISCO := 4
const MP8_ROW2_OFFSET := Vector3(0.6, 0.0, 5.2)
const WORKER_HATS := ["hard_hat", "traffic_cone", "tophat", "rubiks_cube", "beer_hat", "cap_blade", "drill_sgt_hat", "maska_helmet"]
const WORKER_GLASSES := ["sunglasses", "", "reading_glasses", "", "", "sunglasses", "", "reading_glasses"]


class SandboxLoader:
	var scene_hooks: Dictionary = {}
	var node_callbacks: Array = []
	var registries: Dictionary = {}
	var mod_dirs: Dictionary = {}

	func has_api(api_name: String) -> bool:
		return api_name == "registry"

	func on_scene_script(path: String, cb: Callable) -> void:
		scene_hooks[path] = cb

	func on_node_added(cb: Callable) -> void:
		node_callbacks.append(cb)

	func registry(id: String) -> Dictionary:
		if not registries.has(id):
			registries[id] = {}
		return registries[id]

	func dir_of(id: String) -> String:
		return str(mod_dirs.get(id, ""))


class SandboxNetwork extends Node:
	signal on_peer_connected(id)
	var active_backend: Dictionary = {
		"lobby_id": 2026,
		"connected_players": {
			1: {"name": "Host (你)", "customization": ["hard_hat", "sunglasses", "red"]},
			2: {"name": "Player 2", "customization": ["traffic_cone", "", "blue"]},
		},
		"self_data": {"customization": ["hard_hat", "sunglasses", "red"]},
	}
	var max_player_count: int = 8


class SandboxGlobals extends Node:
	const suit_colors := ["red", "blue", "green", "yellow", "purple"]
	var allow_singleplayer: bool = true
	var local_game: bool = false
	var active_cosmetic_hat: String = "hard_hat"
	var active_cosmetic_glasses: String = "sunglasses"
	var active_cosmetic_suit_color: String = "red"
	var settings: Dictionary = {"custom_shuffled": false}


class SandboxGameManager extends Node:
	signal input_device_changed
	var host_game: bool = true
	var local_game: bool = false
	var in_lobby: bool = true
	var custom_shuffled: bool = false
	var game_in_progress: bool = false

	func is_using_controller() -> bool:
		return false


class SandboxBotsMod extends Node:
	var bots: Dictionary = {-1: 1, -2: 2}
	var outfits: Dictionary = {}


class SandboxLobbyHandler extends Control:
	signal start_pressed
	signal back_pressed
	var active: bool = true
	var root: Control = self
	var players: Array = []
	var nametags: Array = []


class SandboxLobby extends Node3D:
	var lobby_handler: SandboxLobbyHandler = SandboxLobbyHandler.new()
	var loading: bool = false
	var player_order_by_seat: Dictionary = {}

	func update_player_list() -> void:
		if get_tree() != null and get_tree().has_method("_render_lobby_from_seat_map"):
			get_tree().call("_render_lobby_from_seat_map")


class SandboxGameHost extends Node:
	signal player_game_ready(id)
	var round_score_by_network_id: Dictionary = {}

	func load_minigame() -> void:
		pass


class SandboxMinigameHost extends Node:
	signal minigame_finished(id)
	signal player_scores_finalized(scores)
	var round_number: int = 1
	var total_rounds: int = 3
	var active_players: Dictionary = {}
	var dead_players: Array = []
	var player_scores: Dictionary = {}
	var player_count: int = 0
	var finished: bool = false
	var game_end: bool = false

	func all_players_loaded() -> void:
		pass


class SandboxInputRelay extends Node:
	var owner_tree: SceneTree = null

	func _input(event: InputEvent) -> void:
		if owner_tree != null:
			owner_tree.call("_on_sandbox_input", event)


class SandboxDiscoActor extends Node3D:
	var player_presence: Dictionary = {}
	var player_name_label: Label3D = null
	var players_in_shove_proximity: Array = []
	var active: bool = true
	var team_id: int = 0
	var velocity_vec: Vector3 = Vector3.ZERO
	var elim_time: float = 0.0
	var shoves: int = 0
	var shove_cd: float = 0.0
	var fall_timer: float = 0.0
	var is_human: bool = false


var _repo_root: String = ""
var _loader: SandboxLoader = SandboxLoader.new()
var _net: SandboxNetwork = SandboxNetwork.new()
var _globals: SandboxGlobals = SandboxGlobals.new()
var _game_manager: SandboxGameManager = SandboxGameManager.new()
var _mod_loader: Node = Node.new()
var _bots_mod: SandboxBotsMod = SandboxBotsMod.new()
var _tp_mod: Node = null
var _spot_mod: Node = null

var _bb_cfg = null
var _bb_meshes = null
var _bb_stage_script: GDScript = null

var _sr_cfg = null
var _sr_meshes = null
var _sr_stage_script: GDScript = null

var _rc_cfg = null
var _rc_meshes = null
var _rc_stage_script: GDScript = null

var _human_names: Dictionary = {1: "Host (你)", 2: "Player 2"}
var _next_human_id: int = 3
var _next_bot_slot: int = 3
var _human_count_id_order: Array = [1, 2]
var _bot_id_order: Array = [-1, -2]

var _current_scene_kind: int = SCENE_LOBBY
var _pending_scene_kind: int = -1
var _scene_switch_queued: bool = false
var _scene_container: Node = null
var _active_lobby: Node = null
var _active_game: SandboxGameHost = null
var _active_mg: SandboxMinigameHost = null
var _active_stage: Node = null
var _lobby_refresh_timer: float = 0.0

var _pck_mounted: bool = false
var _stubs_registered: bool = false
var _stub_scripts: Array = []
var _stub_scenes: Array = []
var _translations: Array = []
var _real_lobby_packed: PackedScene = null

# Sandbox Disco Dodge Arena state
var _disco_actors: Dictionary = {}
var _disco_camera: Camera3D = null
var _disco_ended: bool = false
var _disco_elapsed: float = 0.0

# Sandbox UI Chrome (CanvasLayer layer 19 — keeps TeamParty HUD/Panels clean on top)
var _chrome_layer: CanvasLayer = null
var _nav_bar: PanelContainer = null
var _status_label: Label = null
var _tab_buttons: Array = []
var _room_panel: PanelContainer = null
var _room_count_label: Label = null
var _action_panel: PanelContainer = null
var _action_title_label: Label = null
var _action_buttons_box: VBoxContainer = null
var _action_feedback_label: Label = null
var _results_modal: PanelContainer = null
var _results_text: Label = null
var _input_relay: SandboxInputRelay = null

var _is_self_test: bool = false
var _screenshot_path: String = ""
var _screenshot_scene: String = ""
var _failed: bool = false


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--sandbox-test":
			_is_self_test = true
		elif arg.begins_with("--sandbox-screenshot="):
			_screenshot_path = arg.trim_prefix("--sandbox-screenshot=")
		elif arg.begins_with("--sandbox-scene="):
			_screenshot_scene = arg.trim_prefix("--sandbox-scene=")
	var pck_path: String = OS.get_environment("MP_PCK_PATH")
	if not pck_path.is_empty() and FileAccess.file_exists(pck_path):
		_pck_mounted = ProjectSettings.load_resource_pack(pck_path, false)
	if _pck_mounted:
		_register_pck_uid_cache()
		var preferred_locale: String = "zh_TW"
		for tr_path in [
			"res://localization/localization sheet/Machine Party - Loc Sheet - Game Content.EN.translation",
			"res://localization/localization sheet/Machine Party - Loc Sheet - Game Content.ZHS.translation",
			"res://localization/localization sheet/Machine Party - Loc Sheet - Game Content.ZHT.translation",
		]:
			if ResourceLoader.exists(tr_path):
				var tr = ResourceLoader.load(tr_path)
				if tr is Translation:
					var t_obj := tr as Translation
					TranslationServer.add_translation(t_obj)
					_translations.append(t_obj)
					if tr_path.contains(".ZHT.") and not t_obj.locale.is_empty():
						preferred_locale = t_obj.locale
		var env_loc: String = OS.get_environment("MP_SANDBOX_LOCALE")
		TranslationServer.set_locale(env_loc if not env_loc.is_empty() else preferred_locale)
	call_deferred("_boot")


func _register_pck_uid_cache() -> void:
	var f := FileAccess.open("res://.godot/uid_cache.bin", FileAccess.READ)
	if f == null:
		return
	var count: int = f.get_32()
	for _i in range(count):
		if f.eof_reached():
			break
		var uid_id: int = f.get_64()
		var path_len: int = f.get_32()
		if path_len <= 0 or path_len > 1024:
			break
		var res_path: String = f.get_buffer(path_len).get_string_from_utf8()
		if uid_id != ResourceUID.INVALID_ID and not res_path.is_empty() and not ResourceUID.has_id(uid_id):
			ResourceUID.add_id(uid_id, res_path)


func _clear_button_focus_recursive(node: Node) -> void:
	if node is Control:
		var ctrl := node as Control
		if ctrl is BaseButton:
			ctrl.focus_mode = Control.FOCUS_NONE
	for ch in node.get_children():
		_clear_button_focus_recursive(ch)


func _take_over_script(res_path: String, code: String) -> void:
	var s := GDScript.new()
	s.source_code = code
	var err: int = s.reload()
	if err != OK:
		push_error("Sandbox stub compile failed for %s (%d)" % [res_path, err])
		return
	s.take_over_path(res_path)
	_stub_scripts.append(s)


func _register_vanilla_lobby_stubs() -> void:
	if _stubs_registered or not ResourceLoader.exists("res://scenes/lobby/lobby_scene.tscn"):
		return
	_stubs_registered = true

	var dummy_game := PackedScene.new()
	var gn := Node.new()
	gn.name = "GameStub"
	dummy_game.pack(gn)
	gn.free()
	dummy_game.take_over_path("res://scenes/game.tscn")
	_stub_scenes.append(dummy_game)

	_take_over_script("res://addons/shaker/data/Vector3/BaseShakerType3D.gd", """extends Resource
""")
	_take_over_script("res://addons/shaker/data/Vector3/ShakerTypeNoiseShake3D.gd", """extends Resource
@export var noise_texture: Texture = null
@export var amplitude: Vector3 = Vector3.ZERO
@export var offset: Vector3 = Vector3.ZERO
""")
	_take_over_script("res://addons/shaker/data/Vector3/ShakerPreset3D.gd", """extends Resource
@export var PositionShake: Array = []
@export var RotationShake: Array = []
@export var ScaleShake: Array = []
""")
	_take_over_script("res://addons/shaker/src/Vector3/shaker_component3D.gd", """extends Node3D
@export var custom_target: bool = false
@export var Targets: Array = []
@export var AutoPlay: bool = false
@export var randomize: bool = false
@export var duration: float = 0.25
@export var fade_out: float = 1.0
@export var shake_speed: float = 1.0
@export var intensity: float = 1.0
@export var shakerPreset: Resource = null

func play_shake() -> void:
	pass

func stop_shake() -> void:
	pass
""")
	_take_over_script("res://scenes/lobby/components/playlist_handler.gd", """extends Node
signal back_pressed()
signal accept_pressed()
@export var root: Control
@export var all_minigames_list: Control
@export var selected_minigames_list: Control
@export var back_button: Button
@export var presets_button: Button
@export var default_button: Button
@export var reset_button: Button
@export var accept_button: Button
@export var shuffle_button: Button
@export var message_label: Label
var active: bool = false

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(func() -> void: back_pressed.emit())
	if accept_button != null:
		accept_button.pressed.connect(func() -> void: accept_pressed.emit())

func set_active(v: bool) -> void:
	active = v
	if root != null:
		root.visible = v
""")
	_take_over_script("res://scripts/components/character customization/button_class.gd", """extends Node
signal is_exited
signal is_focused
signal is_pressed
signal is_hovered
@export var alias: String = ""
@export var playing_sound: bool = true
@export var isDynamic: bool = false
@export var speaker_press: AudioStreamPlayer
@export var speaker_hover: AudioStreamPlayer
@export var ui_opacity_inactive: float = 1.0
@export var ui_opacity_active: float = 0.78
@export var set_cursor_to_point_after_press: bool = false
@export var custom_ui_target: CanvasItem
@export var force_play_sound: bool = false
@export var check_if_disabled: bool = false
@export var randomizing_pitch: bool = true
@export var play_hover_sound: bool = false

func _ready() -> void:
	var p = get_parent()
	if p is BaseButton:
		(p as BaseButton).pressed.connect(func() -> void:
			is_pressed.emit()
			if speaker_press != null and speaker_press.stream != null:
				speaker_press.play()
		)
""")
	_take_over_script("res://scripts/components/character customization/customization_assigner.gd", """extends Node3D
@export var character_mesh: MeshInstance3D
@export var shake_on_cosmetic_change: bool = true
@export var use_cutoff_textures: bool = false
@export var assigning: bool = true
@export var bone_attachment_hat: BoneAttachment3D
@export var bone_attachment_glasses: BoneAttachment3D
@export var suit_texture_red: Texture
@export var suit_texture_blue: Texture
@export var suit_texture_green: Texture
@export var suit_texture_yellow: Texture
@export var suit_texture_purple: Texture
@export var shaker_hat: Node
@export var shaker_glasses: Node
@export var suit_texture_cutoff_red: Texture
@export var suit_texture_cutoff_blue: Texture
@export var suit_texture_cutoff_green: Texture
@export var suit_texture_cutoff_yellow: Texture
@export var suit_texture_cutoff_purple: Texture
var assigned_suit_color: String = "red"
var character_material: StandardMaterial3D = null

func _ready() -> void:
	if not assigning:
		return
	get_character_material()
	link_bone_attachments()
	var g = get_tree().root.get_node_or_null("Globals") if is_inside_tree() else null
	if g != null:
		assign_hat(str(g.get(&"active_cosmetic_hat")))
		assign_glasses(str(g.get(&"active_cosmetic_glasses")))
		assign_suit_color(str(g.get(&"active_cosmetic_suit_color")))

func link_bone_attachments() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var skel_path: NodePath = get_parent().get_path()
	if bone_attachment_glasses != null:
		bone_attachment_glasses.set_use_external_skeleton(true)
		bone_attachment_glasses.set_external_skeleton(skel_path)
		bone_attachment_glasses.bone_name = "head"
		bone_attachment_glasses.bone_idx = 4
	if bone_attachment_hat != null:
		bone_attachment_hat.set_use_external_skeleton(true)
		bone_attachment_hat.set_external_skeleton(skel_path)
		bone_attachment_hat.bone_name = "hat"
		bone_attachment_hat.bone_idx = 5

func get_character_material() -> void:
	if character_material == null and character_mesh != null:
		var base_mat = character_mesh.get_active_material(0)
		if base_mat is StandardMaterial3D:
			character_material = (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			character_mesh.set_surface_override_material(0, character_material)

func assign_hat(cosmetic_name: String) -> void:
	if bone_attachment_hat == null:
		return
	for ch in bone_attachment_hat.get_children():
		if ch is Node3D:
			(ch as Node3D).visible = (ch.name == cosmetic_name)
	bone_attachment_hat.visible = true

func assign_glasses(cosmetic_name: String) -> void:
	if bone_attachment_glasses == null:
		return
	for ch in bone_attachment_glasses.get_children():
		if ch is Node3D:
			(ch as Node3D).visible = (ch.name == cosmetic_name)

func _get_suit_texture(color_name: String) -> Texture:
	if not use_cutoff_textures:
		match color_name:
			"red": return suit_texture_red
			"blue": return suit_texture_blue
			"green": return suit_texture_green
			"yellow": return suit_texture_yellow
			"purple": return suit_texture_purple
			_: return suit_texture_blue
	match color_name:
		"red": return suit_texture_cutoff_red
		"blue": return suit_texture_cutoff_blue
		"green": return suit_texture_cutoff_green
		"yellow": return suit_texture_cutoff_yellow
		"purple": return suit_texture_cutoff_purple
		_: return suit_texture_cutoff_blue

func assign_suit_color(color_name: String) -> void:
	assigned_suit_color = color_name
	get_character_material()
	if character_material != null:
		var tex: Texture = _get_suit_texture(color_name)
		if tex != null:
			character_material.set("albedo_texture", tex)
""")
	_take_over_script("res://modules/multiplayer_lobby/components/lobby_handler/lobby_handler.gd", """extends Node
signal back_pressed()
signal invite_pressed()
signal playlist_pressed()
signal start_pressed()
signal message_sent(message)
signal skip_intro_toggled()
@export var root: Control
@export var back_button: Button
@export var copy_lobby_id_button: Button
@export var invite_button: Button
@export var playlist_button: Button
@export var start_button: Button
@export var skip_intro_button: Button
@export var button_parents: Array[Control] = []
@export var players: Array[Node3D] = []
@export var player_models: Array[Node3D] = []
@export var customization_assigners: Array = []
@export var nametags: Array[Label3D] = []
@export var force_playlist_visible: bool = false
@export var players_order: Array[int] = []
@export var anim_message: AnimationPlayer
@export var label_message: Label
@export var show_skip_intro: bool = false
@export var allow_single_player: bool = true
@export var check_locale: bool = false
@export var debug_player_label: Label
var active: bool = true

func _ready() -> void:
	if root != null:
		root.visible = true
	if start_button != null:
		start_button.visible = true
		start_button.pressed.connect(func() -> void: start_pressed.emit())
	if playlist_button != null:
		playlist_button.visible = true
		playlist_button.pressed.connect(func() -> void: playlist_pressed.emit())
	if back_button != null:
		back_button.pressed.connect(func() -> void: back_pressed.emit())
	if debug_player_label != null:
		debug_player_label.text = ""
		debug_player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_active(v: bool) -> void:
	active = v
	if root != null:
		root.visible = v

func send_lobby_message(msg: String) -> void:
	if label_message != null:
		label_message.text = msg
		label_message.modulate = Color.WHITE
	if anim_message != null and anim_message.has_animation("show"):
		anim_message.stop()
		anim_message.play("show")
	message_sent.emit(msg)
""")
	_take_over_script("res://scenes/lobby/scripts/lobby_scene.gd", """extends Control
@export var game_scene: PackedScene
@export var lobby_handler: Node
@export var playlist_handler: Node
@export var reconnect_handler: Node
@export var sc_ambience: Node
@export var screen_handlers: Array[Node] = []
@export var loading_screen: Control
@export var loading_screen_label_container: Control
@export var screen_roots: Array[Control] = []
@export var main_buttons_containers: Array[Control] = []
@export var load_timeout_timer: Timer
var loading: bool = false
var player_order_by_seat: Dictionary = {0: -1, 1: -1, 2: -1, 3: -1, 4: -1, 5: -1, 6: -1, 7: -1}

func _ready() -> void:
	loading = false
	if loading_screen != null:
		loading_screen.visible = false
	for sr in screen_roots:
		if sr != null:
			sr.visible = false
	for sh in screen_handlers:
		if sh != null and sh != lobby_handler and sh.has_method("set_active"):
			sh.call("set_active", false)
	if lobby_handler != null:
		lobby_handler.call("set_active", true)

func update_player_list() -> void:
	if get_tree() != null and get_tree().has_method("_render_lobby_from_seat_map"):
		get_tree().call("_render_lobby_from_seat_map")
""")
	if _is_self_test:
		_take_over_script("res://minigames/exploding_collar_race/components/player/scripts/character_blink.gd", """extends Node
@export var texture_eye_open: Texture
@export var texture_eye_closed: Texture
@export var character_mesh: MeshInstance3D
""")


func _boot() -> void:
	var script_path: String = ProjectSettings.globalize_path((get_script() as Script).resource_path)
	_repo_root = script_path.get_base_dir().get_base_dir().get_base_dir()

	_globals.name = "Globals"
	root.add_child(_globals)
	_game_manager.name = "GameManager"
	root.add_child(_game_manager)
	_net.name = "NetworkManager"
	root.add_child(_net)
	_mod_loader.name = "ModLoader"
	root.add_child(_mod_loader)

	_bots_mod.name = "lobby-bots"
	_mod_loader.add_child(_bots_mod)

	_register_vanilla_lobby_stubs()

	# Forward SceneTree node_added to every mod registered via SandboxLoader
	node_added.connect(func(n: Node) -> void:
		for cb in _loader.node_callbacks:
			(cb as Callable).call(n)
	)

	var tp_script: GDScript = ResourceLoader.load(_repo_root.path_join("mods/team-party/main.gd")) as GDScript
	_tp_mod = tp_script.new()
	_tp_mod.name = "team-party"
	_mod_loader.add_child(_tp_mod)
	_tp_mod.call("_mod_init", _loader)
	_tp_mod.call("_mod_ready", _loader)

	var spot_script: GDScript = ResourceLoader.load(_repo_root.path_join("mods/player-spotlight/main.gd")) as GDScript
	_spot_mod = spot_script.new()
	_spot_mod.name = "player-spotlight"
	_mod_loader.add_child(_spot_mod)
	_spot_mod.call("_mod_init", _loader)
	_spot_mod.call("_mod_ready", _loader)

	_load_untouched_minigame_modules()
	_build_chrome_ui()
	_input_relay = SandboxInputRelay.new()
	_input_relay.owner_tree = self
	root.add_child(_input_relay)

	if _is_self_test:
		await _run_headless_self_tests()
		await _shutdown(1 if _failed else 0)
		return

	_switch_scene(SCENE_LOBBY)
	# Boot interactive session directly into an 8-player Overtime room in 2-per-team (2v2v2v2)
	_apply_roster_preset("8p_duo")
	await process_frame
	_tp_mod.call("_process", 0.05)

	if _screenshot_scene == "lobby_shuffled":
		_tp_mod.call("shuffle_teams")
		await process_frame
		_tp_mod.call("_process", 0.05)
	elif _screenshot_scene == "lobby_open":
		_bots_mod.bots.clear()
		_bots_mod.outfits.clear()
		_bot_id_order.clear()
		_human_names = {1: "Host (你)", 2: "Player 2", 3: "Player 3"}
		_human_count_id_order = [1, 2, 3]
		_net.active_backend["connected_players"] = {
			1: {"name": "Host (你)"},
			2: {"name": "Player 2"},
			3: {"name": "Player 3"},
		}
		_tp_mod.call("set_team_format", 1)
		_active_lobby.player_order_by_seat = {0: 1, 1: -1, 2: 2, 3: 3, 4: -1, 5: -1, 6: -1, 7: -1}
		_tp_mod.call("assign_player_team", 1, 1)
		_tp_mod.call("assign_player_team", 2, 2)
		_tp_mod.call("assign_player_team", 3, 2)
		_render_lobby_from_seat_map()
		await process_frame
		_tp_mod.call("_process", 0.05)
	elif _screenshot_scene == "lobby_drag":
		var h_drag = _active_lobby.get("lobby_handler")
		if h_drag != null and (h_drag.get("players") is Array) and (h_drag.get("players") as Array).size() > 5:
			await process_frame
			_tp_mod.call("_process", 0.05)
			var p_arr: Array = h_drag.get("players") as Array
			var n_arr: Array = h_drag.get("nametags") as Array
			var s1: Node3D = p_arr[1] as Node3D
			var s5: Node3D = p_arr[5] as Node3D
			var l1: Label3D = n_arr[1] as Label3D
			var l5: Label3D = n_arr[5] as Label3D
			var f1: Vector3 = _tp_mod.call("_seat_world_floor_pos", s1, l1, 1) as Vector3
			var f5: Vector3 = _tp_mod.call("_seat_world_floor_pos", s5, l5, 5) as Vector3
			var vp_drag: Viewport = s1.get_viewport()
			var cam_drag: Camera3D = vp_drag.get_camera_3d() if vp_drag != null else null
			var tex_drag: TextureRect = _active_lobby.get_node_or_null("Lobby/Control/TextureRect") as TextureRect
			var scr_pt: Vector2 = _tp_mod.call("_project_seat_to_screen", Vector3(f5.x + 0.15, 2.35, f5.z), cam_drag, vp_drag, tex_drag) as Vector2
			var fg_hit = _tp_mod.call("_screen_to_lobby_drag_pos", scr_pt)
			var tgt: Vector3 = fg_hit as Vector3 if (fg_hit is Vector3) else Vector3(f5.x + 0.15, 2.55, f5.z + 2.2)
			_tp_mod.set("_drag_seat", 1)
			_tp_mod.set("_drag_actor_id", 2)
			_tp_mod.set("_drag_active", true)
			_tp_mod.set("_hovered_seat", 5)
			_tp_mod.set("_drag_elapsed", 0.28)
			_tp_mod.set("_drag_orig_floor", f1)
			_tp_mod.set("_drag_rest_collar", Vector3(f1.x, 2.05, f1.z))
			_tp_mod.set("_drag_target_pos", tgt)
			_tp_mod.set("_drag_visual_pos", tgt - Vector3(0.45, 0.08, 0.0))
			_tp_mod.set("_drag_vel", Vector3(8.5, 1.2, 0.0))
			_tp_mod.call("_begin_drag_skeleton", s1)
			_tp_mod.call("_update_lobby_nametags")
			for _df in range(3):
				_tp_mod.set("_drag_target_pos", (_tp_mod.get("_drag_target_pos") as Vector3) + Vector3(0.14, 0.02, 0.0))
				await process_frame
	elif _screenshot_scene == "lobby_swap":
		await process_frame
		_tp_mod.call("_process", 0.05)
		_tp_mod.call("click_lobby_chair", 0, 2)
		_tp_mod.call("_process", 0.05)
	elif _screenshot_scene == "bubble":
		_switch_scene(SCENE_BUBBLE)
		await process_frame
		_bb_action_friendly_bomb()
		_bb_action_rescue()
	elif _screenshot_scene == "spike":
		_switch_scene(SCENE_SPIKE)
		await process_frame
		_sr_action_shield_link()
	elif _screenshot_scene == "roller":
		_switch_scene(SCENE_ROLLER)
		await process_frame
		_ensure_rc_live()
	elif _screenshot_scene == "disco":
		_switch_scene(SCENE_DISCO)

	if not _screenshot_path.is_empty():
		await process_frame
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_screenshot_path.get_base_dir())
		var err: int = img.save_png(_screenshot_path)
		print("SANDBOX_SCREENSHOT_SAVED=%s err=%d" % [_screenshot_path, err])
		await _shutdown(err)


func _load_untouched_minigame_modules() -> void:
	_bb_cfg = ResourceLoader.load(_repo_root.path_join("mods/bubble-blitz/config.gd"))
	_bb_meshes = ResourceLoader.load(_repo_root.path_join("mods/bubble-blitz/arena_meshes.gd"))
	_bb_stage_script = ResourceLoader.load(_repo_root.path_join("mods/bubble-blitz/bubble_blitz_game.gd")) as GDScript

	_sr_cfg = ResourceLoader.load(_repo_root.path_join("mods/spike-ring/config.gd"))
	_sr_meshes = ResourceLoader.load(_repo_root.path_join("mods/spike-ring/arena_meshes.gd"))
	_sr_stage_script = ResourceLoader.load(_repo_root.path_join("mods/spike-ring/spike_ring_game.gd")) as GDScript

	_rc_cfg = ResourceLoader.load(_repo_root.path_join("mods/roller-carnival/config.gd"))
	_rc_meshes = ResourceLoader.load(_repo_root.path_join("mods/roller-carnival/carnival_meshes.gd"))
	_rc_stage_script = ResourceLoader.load(_repo_root.path_join("mods/roller-carnival/roller_carnival_game.gd")) as GDScript


func _build_panel_style(bg: Color = Color(0.02, 0.02, 0.04, 0.88), border: Color = Color(0.90, 0.90, 0.90, 0.88)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb


func _build_chrome_ui() -> void:
	_chrome_layer = CanvasLayer.new()
	_chrome_layer.name = "SandboxChrome"
	_chrome_layer.layer = 19
	root.add_child(_chrome_layer)

	# Bottom-center scene switcher bar (keeps top-center timers & top-right Team HUD 100% clear)
	_nav_bar = PanelContainer.new()
	_nav_bar.name = "SandboxNavBar"
	_nav_bar.add_theme_stylebox_override("panel", _build_panel_style())
	_nav_bar.anchor_left = 0.5
	_nav_bar.anchor_right = 0.5
	_nav_bar.anchor_top = 1.0
	_nav_bar.anchor_bottom = 1.0
	_nav_bar.offset_left = -326.0
	_nav_bar.offset_right = 326.0
	_nav_bar.offset_top = -44.0
	_nav_bar.offset_bottom = -8.0
	_chrome_layer.add_child(_nav_bar)

	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 5)
	_nav_bar.add_child(tabs_hbox)

	var tab_defs: Array = [
		[SCENE_LOBBY, "[1] 大廳"],
		[SCENE_BUBBLE, "[2] 泡泡爆破"],
		[SCENE_SPIKE, "[3] 尖刺圓環"],
		[SCENE_ROLLER, "[4] 滾筒嘉年華"],
		[SCENE_DISCO, "[5] 迪斯可推擠"],
	]
	for td in tab_defs:
		var idx: int = int(td[0])
		var btn := Button.new()
		btn.text = str(td[1])
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_request_switch_scene.bind(idx))
		tabs_hbox.add_child(btn)
		_tab_buttons.append(btn)

	# Top-right room member simulator (visible inside Lobby ONLY — mirrors lobby-bots corner)
	_room_panel = PanelContainer.new()
	_room_panel.name = "SandboxRoomPanel"
	_room_panel.add_theme_stylebox_override("panel", _build_panel_style())
	_room_panel.anchor_left = 1.0
	_room_panel.anchor_right = 1.0
	_room_panel.anchor_top = 0.0
	_room_panel.offset_left = -286.0
	_room_panel.offset_right = -16.0
	_room_panel.offset_top = 20.0
	_chrome_layer.add_child(_room_panel)

	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 5)
	_room_panel.add_child(rv)

	var rt := Label.new()
	rt.text = "測試房間 / OVERTIME 8人擴展"
	rt.add_theme_font_size_override("font_size", 12)
	rt.add_theme_color_override("font_color", Color(0.95, 0.86, 0.56))
	rv.add_child(rt)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.76, 0.94, 0.82))
	rv.add_child(_status_label)

	_room_count_label = Label.new()
	_room_count_label.add_theme_font_size_override("font_size", 11)
	rv.add_child(_room_count_label)

	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 4)
	rv.add_child(hrow)
	var b_add_h := Button.new()
	b_add_h.text = "+ 真人"
	b_add_h.focus_mode = Control.FOCUS_NONE
	b_add_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_add_h.pressed.connect(_add_human_player)
	hrow.add_child(b_add_h)
	var b_rem_h := Button.new()
	b_rem_h.text = "- 真人"
	b_rem_h.focus_mode = Control.FOCUS_NONE
	b_rem_h.pressed.connect(_remove_human_player)
	hrow.add_child(b_rem_h)

	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 4)
	rv.add_child(brow)
	var b_add_b := Button.new()
	b_add_b.text = "+ 機器人"
	b_add_b.focus_mode = Control.FOCUS_NONE
	b_add_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_add_b.pressed.connect(_add_bot_player)
	brow.add_child(b_add_b)
	var b_rem_b := Button.new()
	b_rem_b.text = "- Bot"
	b_rem_b.focus_mode = Control.FOCUS_NONE
	b_rem_b.pressed.connect(_remove_bot_player)
	brow.add_child(b_rem_b)

	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 4)
	rv.add_child(prow)
	for preset in [["8人 2v2v2v2", "8p_duo"], ["8人 4v4", "8p_squad"], ["4人 2v2", "2v2"]]:
		var pbtn := Button.new()
		pbtn.text = str(preset[0])
		pbtn.focus_mode = Control.FOCUS_NONE
		pbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pbtn.add_theme_font_size_override("font_size", 11)
		var pkey: String = str(preset[1])
		pbtn.pressed.connect(func() -> void: _apply_roster_preset(pkey))
		prow.add_child(pbtn)

	# Bottom-left minigame quick-test drawer (only visible inside Minigames — keeps top clear)
	_action_panel = PanelContainer.new()
	_action_panel.name = "SandboxActionPanel"
	_action_panel.add_theme_stylebox_override("panel", _build_panel_style(Color(0.02, 0.03, 0.05, 0.86), Color(0.36, 0.72, 0.96, 0.90)))
	_action_panel.anchor_left = 0.0
	_action_panel.anchor_right = 0.0
	_action_panel.anchor_top = 1.0
	_action_panel.anchor_bottom = 1.0
	_action_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_action_panel.offset_left = 12.0
	_action_panel.offset_right = 294.0
	_action_panel.offset_bottom = -8.0
	_chrome_layer.add_child(_action_panel)

	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 4)
	_action_panel.add_child(av)

	_action_title_label = Label.new()
	_action_title_label.add_theme_font_size_override("font_size", 12)
	_action_title_label.add_theme_color_override("font_color", Color(0.56, 0.88, 1.0))
	av.add_child(_action_title_label)

	_action_buttons_box = VBoxContainer.new()
	_action_buttons_box.add_theme_constant_override("separation", 3)
	av.add_child(_action_buttons_box)

	_action_feedback_label = Label.new()
	_action_feedback_label.add_theme_font_size_override("font_size", 11)
	_action_feedback_label.add_theme_color_override("font_color", Color(0.84, 0.98, 0.68))
	_action_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	av.add_child(_action_feedback_label)

	# Center settlement overlay modal
	_results_modal = PanelContainer.new()
	_results_modal.visible = false
	_results_modal.add_theme_stylebox_override("panel", _build_panel_style(Color(0.03, 0.04, 0.07, 0.95), Color(1.0, 0.82, 0.28, 0.95)))
	_results_modal.anchor_left = 0.5
	_results_modal.anchor_right = 0.5
	_results_modal.anchor_top = 0.5
	_results_modal.anchor_bottom = 0.5
	_results_modal.offset_left = -260.0
	_results_modal.offset_right = 260.0
	_results_modal.offset_top = -170.0
	_results_modal.offset_bottom = 170.0
	_chrome_layer.add_child(_results_modal)

	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 8)
	_results_modal.add_child(mv)

	var mt := Label.new()
	mt.text = "TEAM PARTY // 本回合小隊同步結算對照"
	mt.add_theme_font_size_override("font_size", 16)
	mt.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34))
	mv.add_child(mt)

	_results_text = Label.new()
	_results_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results_text.add_theme_font_size_override("font_size", 14)
	mv.add_child(_results_text)

	var mclose := Button.new()
	mclose.text = "再試一局 / 返回"
	mclose.focus_mode = Control.FOCUS_NONE
	mclose.pressed.connect(func() -> void:
		_results_modal.visible = false
		_request_switch_scene(_current_scene_kind)
	)
	mv.add_child(mclose)


func _build_roster_entries() -> Array:
	var roster: Array = []
	var suits := ["red", "blue", "green", "yellow", "purple"]
	var idx: int = 0
	for hid in _human_count_id_order:
		var nid: int = int(hid)
		var nick: String = str(_human_names.get(nid, "Player %d" % nid))
		var hat: String = WORKER_HATS[idx % WORKER_HATS.size()]
		var glasses: String = WORKER_GLASSES[idx % WORKER_GLASSES.size()]
		var suit: String = suits[idx % suits.size()]
		var cplayers: Dictionary = _net.active_backend["connected_players"] as Dictionary
		if cplayers.has(nid) and cplayers[nid] is Dictionary:
			var existing_cust = (cplayers[nid] as Dictionary).get("customization", null)
			if existing_cust is Array and (existing_cust as Array).size() >= 3:
				suit = str((existing_cust as Array)[2])
		var cust := [hat, glasses, suit]
		if cplayers.has(nid) and cplayers[nid] is Dictionary:
			(cplayers[nid] as Dictionary)["customization"] = cust
		roster.append({
			"id": idx,
			"network_id": nid,
			"nickname": nick,
			"customization": cust,
			"is_ai": false,
			"round_number": 1,
			"total_rounds": 3,
		})
		idx += 1
	for bid_v in _bot_id_order:
		var bid: int = int(bid_v)
		var bnum: int = int(_bots_mod.bots.get(bid, 1))
		var hat: String = WORKER_HATS[idx % WORKER_HATS.size()]
		var glasses: String = WORKER_GLASSES[idx % WORKER_GLASSES.size()]
		var suit: String = suits[(idx + 1) % suits.size()]
		if _bots_mod.outfits.has(bid) and _bots_mod.outfits[bid] is Array and (_bots_mod.outfits[bid] as Array).size() >= 3:
			suit = str((_bots_mod.outfits[bid] as Array)[2])
		var bcust := [hat, glasses, suit]
		_bots_mod.outfits[bid] = bcust
		roster.append({
			"id": idx,
			"network_id": bid,
			"nickname": "Bot %d" % bnum,
			"customization": bcust,
			"is_ai": true,
			"round_number": 1,
			"total_rounds": 3,
		})
		idx += 1
	return roster


func _update_chrome_summary() -> void:
	if _status_label == null:
		return
	var tc: int = int(_tp_mod.get("team_count"))
	var mode_str: String = "各自為戰 FFA" if tc < 2 else ("%d 隊組隊模式" % tc)
	var spot_str: String = "ON" if (_spot_mod != null and bool(_spot_mod.get("enabled"))) else "OFF"
	_status_label.text = "%s  |  聚光燈 [F8]: %s" % [mode_str, spot_str]
	if _room_count_label != null:
		_room_count_label.text = "真人 %d 人 + Bot %d 名  (共 %d/8 席)" % [
			_human_count_id_order.size(), _bot_id_order.size(), _human_count_id_order.size() + _bot_id_order.size()
		]
	for i in range(_tab_buttons.size()):
		var b: Button = _tab_buttons[i] as Button
		b.disabled = (i == _current_scene_kind)


func _disable_tree_safely(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	if &"blinking" in node:
		node.set(&"blinking", false)
	if node is AudioStreamPlayer:
		var asp := node as AudioStreamPlayer
		asp.stop()
		asp.stream = null
	elif node is AudioStreamPlayer3D:
		var asp3 := node as AudioStreamPlayer3D
		asp3.stop()
		asp3.stream = null
	for ch in node.get_children():
		_disable_tree_safely(ch)


func _clear_current_scene() -> void:
	_disco_actors.clear()
	_disco_camera = null
	_disco_ended = true
	if _active_lobby != null and is_instance_valid(_active_lobby):
		var h = _active_lobby.get("lobby_handler")
		if h != null:
			h.set("active", false)
	if _tp_mod != null:
		_tp_mod.call("_clear_lobby_3d_rings")
		_tp_mod.call("_hide_hud")
		var tracked: Dictionary = _tp_mod.get("_tracked_actors") as Dictionary
		if tracked != null:
			for rec in tracked.values():
				_tp_mod.call("_cleanup_actor_record", rec)
			tracked.clear()
	_active_lobby = null
	_active_stage = null
	_active_mg = null
	_active_game = null
	if _scene_container != null and is_instance_valid(_scene_container):
		_disable_tree_safely(_scene_container)
		if _scene_container.get_parent() == root:
			root.remove_child(_scene_container)
		_scene_container.free()
	_scene_container = null
	if _results_modal != null:
		_results_modal.visible = false


func _request_switch_scene(kind: int) -> void:
	_pending_scene_kind = kind
	if not _scene_switch_queued:
		_scene_switch_queued = true
		call_deferred("_apply_pending_scene")


func _apply_pending_scene() -> void:
	_scene_switch_queued = false
	var target: int = _pending_scene_kind
	_pending_scene_kind = -1
	if target >= 0:
		_switch_scene(target)


func _switch_scene(kind: int) -> void:
	_clear_current_scene()
	_current_scene_kind = kind
	_scene_container = Node.new()
	_scene_container.name = "ActiveSandboxScene"
	root.add_child(_scene_container)

	_room_panel.visible = (kind == SCENE_LOBBY)
	_action_panel.visible = (kind != SCENE_LOBBY)
	if _nav_bar != null:
		if kind == SCENE_LOBBY:
			_nav_bar.anchor_left = 0.5
			_nav_bar.anchor_right = 0.5
			_nav_bar.anchor_top = 0.0
			_nav_bar.anchor_bottom = 0.0
			_nav_bar.offset_left = -260.0
			_nav_bar.offset_right = 260.0
			_nav_bar.offset_top = 14.0
			_nav_bar.offset_bottom = 48.0
		else:
			_nav_bar.anchor_left = 0.0
			_nav_bar.anchor_right = 0.0
			_nav_bar.anchor_top = 0.0
			_nav_bar.anchor_bottom = 0.0
			_nav_bar.offset_left = 12.0
			_nav_bar.offset_right = 498.0
			_nav_bar.offset_top = 12.0
			_nav_bar.offset_bottom = 46.0
	_action_feedback_label.text = ""
	for ch in _action_buttons_box.get_children():
		_action_buttons_box.remove_child(ch)
		ch.queue_free()

	if kind == SCENE_LOBBY:
		_tp_mod.set("locked", false)
		_enter_sandbox_lobby()
	else:
		_tp_mod.call("_lock_for_game")
		if kind == SCENE_BUBBLE:
			_enter_minigame_stage(_bb_stage_script, _bb_cfg, _bb_meshes, "BubbleStage", false)
			_setup_bubble_actions()
		elif kind == SCENE_SPIKE:
			_enter_minigame_stage(_sr_stage_script, _sr_cfg, _sr_meshes, "SpikeStage", false)
			_setup_spike_actions()
		elif kind == SCENE_ROLLER:
			_enter_minigame_stage(_rc_stage_script, _rc_cfg, _rc_meshes, "RollerStage", true)
			_setup_roller_actions()
		elif kind == SCENE_DISCO:
			_enter_disco_sandbox()
			_setup_disco_actions()
	if root.get_viewport() != null:
		root.get_viewport().gui_release_focus()
	if _tp_mod != null:
		_tp_mod.call("_refresh_hud", true)
	_update_chrome_summary()


var _cjk_3d_font: SystemFont = null


func _make_3d_font() -> Font:
	if _cjk_3d_font == null:
		_cjk_3d_font = SystemFont.new()
		_cjk_3d_font.font_names = PackedStringArray(["PingFang TC", "PingFang SC", "Heiti TC", "Helvetica Neue", "Arial"])
	return _cjk_3d_font


func _mp8_extend_real_lobby(lobby_inst: Node) -> void:
	var h = lobby_inst.get("lobby_handler")
	if h == null:
		return
	var players_arr: Array = h.get("players")
	var assigners_arr: Array = h.get("customization_assigners")
	var nametags_arr: Array = h.get("nametags")
	if players_arr.size() >= 8 or players_arr.size() < 4:
		return

	var env_node := lobby_inst.get_node_or_null("LobbyPreviewViewport/LobbyViewport/lobby environment1") as Node3D
	if env_node != null and env_node.get_node_or_null("MP8ChairRow") == null:
		var row_root := Node3D.new()
		row_root.name = "MP8ChairRow"
		row_root.position = MP8_ROW2_OFFSET
		env_node.add_child(row_root)
		for child in env_node.get_children():
			if child == row_root:
				continue
			if child is Node3D and str(child.name).to_lower().begins_with("chair") and (child as Node3D).visible:
				var chair_dup: Node = child.duplicate()
				row_root.add_child(chair_dup)

	for nt_front in nametags_arr:
		if nt_front is Label3D:
			var lf := nt_front as Label3D
			lf.position.y += 0.65
			lf.font_size = 72

	for j in range(4, 8):
		var src: Node3D = players_arr[j % 4] as Node3D
		if src == null or src.get_parent() == null:
			continue
		var dup: Node3D = src.duplicate() as Node3D
		dup.name = "MP8Slot%d" % j
		src.get_parent().add_child(dup)
		dup.position = src.position + MP8_ROW2_OFFSET
		players_arr.append(dup)

		var ca := dup.get_node_or_null("main character2/Armature_001/Skeleton3D/customization assigner")
		assigners_arr.append(ca)
		var nt := dup.get_node_or_null("main character2/player nametag")
		if nt is Label3D:
			var lr := nt as Label3D
			lr.position.y -= 1.65
			lr.font_size = 72
			nametags_arr.append(lr)

	h.set("players", players_arr)
	h.set("customization_assigners", assigners_arr)
	h.set("nametags", nametags_arr)

	var cam := lobby_inst.get_node_or_null("LobbyPreviewViewport/LobbyViewport/Camera3D") as Camera3D
	if cam != null:
		var before: Vector3 = cam.position
		cam.position = Vector3(before.x, before.y * 1.08, before.z * 1.22)


func _configure_real_lobby_layout(lobby_inst: Control) -> void:
	lobby_inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pp := lobby_inst.get_node_or_null("Lobby/Control/post processing") as Control
	if pp != null:
		pp.visible = false
	var vp := lobby_inst.get_node_or_null("LobbyPreviewViewport") as SubViewport
	if vp != null:
		vp.size = Vector2i(1280, 720)
	var lobby_ctrl := lobby_inst.get_node_or_null("Lobby/Control") as Control
	if lobby_ctrl != null:
		lobby_ctrl.anchor_left = 0.0
		lobby_ctrl.anchor_top = 0.0
		lobby_ctrl.anchor_right = 1.0
		lobby_ctrl.anchor_bottom = 1.0
		lobby_ctrl.offset_left = 16.0
		lobby_ctrl.offset_top = 16.0
		lobby_ctrl.offset_right = -16.0
		lobby_ctrl.offset_bottom = -52.0
		var tex_rect := lobby_ctrl.get_node_or_null("TextureRect") as TextureRect
		if tex_rect != null:
			tex_rect.scale = Vector2.ONE
			tex_rect.pivot_offset = Vector2.ZERO
			tex_rect.anchor_left = 0.0
			tex_rect.anchor_top = 0.0
			tex_rect.anchor_right = 1.0
			tex_rect.anchor_bottom = 1.0
			tex_rect.offset_left = -16.0
			tex_rect.offset_top = -16.0
			tex_rect.offset_right = 16.0
			tex_rect.offset_bottom = 52.0
		var hf1 := lobby_ctrl.get_node_or_null("HFlowContainer") as Control
		if hf1 != null:
			hf1.pivot_offset = Vector2.ZERO
			hf1.scale = Vector2(0.88, 0.88)
			hf1.anchor_left = 0.0
			hf1.anchor_right = 0.0
			hf1.anchor_top = 1.0
			hf1.anchor_bottom = 1.0
			hf1.offset_left = 8.0
			hf1.offset_top = 8.0
			hf1.offset_right = 680.0
			hf1.offset_bottom = 44.0
		var hf2 := lobby_ctrl.get_node_or_null("HFlowContainer2") as Control
		if hf2 != null:
			hf2.pivot_offset = Vector2.ZERO
			hf2.scale = Vector2(0.88, 0.88)
			hf2.anchor_left = 1.0
			hf2.anchor_right = 1.0
			hf2.anchor_top = 1.0
			hf2.anchor_bottom = 1.0
			hf2.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			hf2.offset_left = -420.0
			hf2.offset_right = -8.0
			hf2.offset_top = 8.0
			hf2.offset_bottom = 44.0
		var hf3 := lobby_ctrl.get_node_or_null("HFlowContainer3") as Control
		if hf3 != null:
			hf3.visible = false
	var msg_lbl := lobby_inst.get_node_or_null("Lobby/message") as Control
	if msg_lbl != null:
		msg_lbl.offset_left = 24.0
		msg_lbl.offset_top = 626.0
		msg_lbl.offset_right = 560.0
		msg_lbl.offset_bottom = 664.0


func _enter_sandbox_lobby() -> void:
	if _pck_mounted and ResourceLoader.exists("res://scenes/lobby/lobby_scene.tscn"):
		if _real_lobby_packed == null:
			_real_lobby_packed = ResourceLoader.load("res://scenes/lobby/lobby_scene.tscn") as PackedScene
		if _real_lobby_packed != null:
			var real_lobby := _real_lobby_packed.instantiate() as Control
			if real_lobby != null:
				_configure_real_lobby_layout(real_lobby)
				_mp8_extend_real_lobby(real_lobby)
				_active_lobby = real_lobby
				_scene_container.add_child(real_lobby)
				var h = real_lobby.get("lobby_handler")
				if h != null:
					var ca_arr: Array = h.get("customization_assigners")
					for ca in ca_arr:
						if ca != null and ca.has_method("link_bone_attachments"):
							ca.call("link_bone_attachments")
					if h.has_signal("start_pressed"):
						h.connect("start_pressed", func() -> void: _request_switch_scene(SCENE_BUBBLE))
					if h.has_signal("playlist_pressed"):
						h.connect("playlist_pressed", func() -> void:
							if h.has_method("send_lobby_message"):
								h.call("send_lobby_message", "使用上方 [2]..[5] 可直接切換小遊戲")
						)
				_clear_button_focus_recursive(real_lobby)
				_sync_lobby_seats()
				_tp_mod.call("_enter_lobby", real_lobby)
				return

	# Clean synthetic fallback ONLY when Machine Party .pck is not mounted (e.g. unit/CI env)
	var lobby := SandboxLobby.new()
	lobby.name = "Lobby"
	lobby.lobby_handler.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby.add_child(lobby.lobby_handler)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.10, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.60, 0.70)
	env.environment = e
	lobby.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 26.0, 0.0)
	sun.light_energy = 1.2
	lobby.add_child(sun)

	var cam := Camera3D.new()
	cam.look_at_from_position(Vector3(0.0, 4.2, 9.2), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	lobby.add_child(cam)
	cam.make_current()

	var floor_mesh := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(14.0, 0.4, 7.0)
	floor_mesh.mesh = fbox
	floor_mesh.position = Vector3(0.0, -0.2, 0.0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.16, 0.19, 0.24)
	floor_mesh.material_override = fmat
	lobby.add_child(floor_mesh)

	for seat in range(8):
		var col: int = seat % 4
		var row: int = seat / 4
		var stand := Node3D.new()
		stand.position = Vector3(-3.0 + float(col) * 2.0, 0.0, -1.2 + float(row) * 2.4)
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.34
		cap.height = 1.15
		body.mesh = cap
		body.position = Vector3(0.0, 0.85, 0.0)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color.from_hsv(float(seat) / 8.0, 0.65, 0.88)
		body.material_override = bmat
		stand.add_child(body)

		var lbl := Label3D.new()
		lbl.font = _make_3d_font()
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.font_size = 42
		lbl.pixel_size = 0.0065
		lbl.outline_size = 12
		lbl.outline_modulate = Color.BLACK
		lbl.position = Vector3(0.0, 2.05, 0.0)
		stand.add_child(lbl)

		lobby.add_child(stand)
		lobby.lobby_handler.players.append(stand)
		lobby.lobby_handler.nametags.append(lbl)

	_active_lobby = lobby
	_sync_lobby_seats()
	_scene_container.add_child(lobby)
	_tp_mod.call("_enter_lobby", lobby)


func _sync_lobby_seats(reset_order: bool = false) -> void:
	if _active_lobby == null or not is_instance_valid(_active_lobby):
		return
	var h = _active_lobby.get("lobby_handler")
	if h == null:
		return
	var players_arr: Array = h.get("players")
	var seat_map: Dictionary = _active_lobby.get("player_order_by_seat") as Dictionary
	if seat_map == null:
		return
	var total: int = players_arr.size()
	if reset_order or seat_map.size() != total:
		seat_map.clear()
		for s in range(total):
			if s < _human_count_id_order.size():
				seat_map[s] = int(_human_count_id_order[s])
			else:
				seat_map[s] = -1
	else:
		# Preserve each remaining human's existing chair; only free removed humans & place new joiners.
		var seated := {}
		for s in range(total):
			var cur_id: int = int(seat_map.get(s, -1))
			if cur_id > 0:
				if _human_count_id_order.has(cur_id):
					seated[cur_id] = s
				else:
					seat_map[s] = -1
		for nid_v in _human_count_id_order:
			var nid: int = int(nid_v)
			if not seated.has(nid):
				for s in range(total):
					if int(seat_map.get(s, -1)) <= 0:
						seat_map[s] = nid
						seated[nid] = s
						break
	_render_lobby_from_seat_map()


func _render_lobby_from_seat_map() -> void:
	if _active_lobby == null or not is_instance_valid(_active_lobby):
		return
	var h = _active_lobby.get("lobby_handler")
	if h == null:
		return
	var players_arr: Array = h.get("players")
	var nametags_arr: Array = h.get("nametags")
	var assigners_arr = h.get("customization_assigners") if (&"customization_assigners" in h) else []
	var seat_map: Dictionary = _active_lobby.get("player_order_by_seat") as Dictionary
	if seat_map == null:
		return
	var roster: Array = _build_roster_entries()
	var by_id: Dictionary = {}
	for e_raw in roster:
		var e: Dictionary = e_raw as Dictionary
		by_id[int(e["network_id"])] = e
	var bot_queue: Array = []
	for bid_v in _bot_id_order:
		if by_id.has(int(bid_v)):
			bot_queue.append(int(bid_v))
	var next_bot: int = 0

	for s in range(players_arr.size()):
		var node: Node3D = players_arr[s] as Node3D
		var lbl: Label3D = nametags_arr[s] as Label3D if s < nametags_arr.size() else null
		var raw_id: int = int(seat_map.get(s, -1))
		var entry: Dictionary = {}
		if raw_id > 0 and by_id.has(raw_id):
			entry = by_id[raw_id] as Dictionary
		elif next_bot < bot_queue.size():
			var bid: int = int(bot_queue[next_bot])
			next_bot += 1
			entry = by_id[bid] as Dictionary

		if not entry.is_empty():
			if node != null:
				node.visible = true
			if lbl != null:
				lbl.visible = true
				lbl.text = str(entry["nickname"])
			if assigners_arr is Array and s < (assigners_arr as Array).size():
				var ca = (assigners_arr as Array)[s]
				var cust: Array = entry.get("customization", []) as Array
				if ca != null and cust.size() >= 3:
					if ca.has_method("assign_hat"):
						ca.call("assign_hat", str(cust[0]))
					if ca.has_method("assign_glasses"):
						ca.call("assign_glasses", str(cust[1]))
					if ca.has_method("assign_suit_color"):
						ca.call("assign_suit_color", str(cust[2]))
		else:
			if node != null:
				node.visible = false
			if lbl != null:
				lbl.visible = false
				lbl.text = ""
	if _tp_mod != null:
		_tp_mod.call("_refresh_lobby_ui")
		_tp_mod.call("_sync_lobby_3d_visuals")
	_update_chrome_summary()


func _add_human_player() -> void:
	if _human_count_id_order.size() + _bot_id_order.size() >= 8:
		return
	var nid: int = _next_human_id
	_next_human_id += 1
	var nick: String = "Player %d" % nid
	_human_names[nid] = nick
	_human_count_id_order.append(nid)
	_net.active_backend["connected_players"][nid] = {"name": nick}
	_sync_lobby_seats()


func _remove_human_player() -> void:
	if _human_count_id_order.size() <= 1:
		return
	var nid: int = int(_human_count_id_order.pop_back())
	_net.active_backend["connected_players"].erase(nid)
	_sync_lobby_seats()


func _add_bot_player() -> void:
	if _human_count_id_order.size() + _bot_id_order.size() >= 8:
		return
	var bid: int = -_next_bot_slot
	var bnum: int = _next_bot_slot
	_next_bot_slot += 1
	_bots_mod.bots[bid] = bnum
	_bot_id_order.append(bid)
	_sync_lobby_seats()


func _remove_bot_player() -> void:
	if _bot_id_order.is_empty():
		return
	var bid: int = int(_bot_id_order.pop_back())
	_bots_mod.bots.erase(bid)
	_bots_mod.outfits.erase(bid)
	_sync_lobby_seats()


func _apply_roster_preset(preset: String) -> void:
	_net.active_backend["connected_players"] = {1: {"name": "Host (你)"}}
	_human_names = {1: "Host (你)"}
	_human_count_id_order = [1]
	_bots_mod.bots.clear()
	_bots_mod.outfits.clear()
	_bot_id_order.clear()
	_next_human_id = 2
	_next_bot_slot = 1
	_sync_lobby_seats(true)

	if preset == "2v2":
		_add_human_player()
		_add_bot_player()
		_add_bot_player()
		_tp_mod.call("set_team_format", 1) # 2 per team -> 2v2
	elif preset == "3v2v2":
		_add_human_player()
		_add_human_player()
		for _i in range(4):
			_add_bot_player()
		_tp_mod.call("set_team_mode", 3)
		_tp_mod.call("assign_player_team", 1, 1)
		_tp_mod.call("assign_player_team", 2, 1)
		_tp_mod.call("assign_player_team", -1, 1)
		_tp_mod.call("assign_player_team", 3, 2)
		_tp_mod.call("assign_player_team", -2, 2)
		_tp_mod.call("assign_player_team", -3, 3)
		_tp_mod.call("assign_player_team", -4, 3)
	elif preset == "8p_duo" or preset == "8p4t":
		# Overtime 8-player room: Host + P2 + Bot 1..6 -> 2-per-team (2v2v2v2)
		_add_human_player()
		for _i in range(6):
			_add_bot_player()
		_tp_mod.call("set_team_format", 1)
	elif preset == "8p_squad":
		_add_human_player()
		for _i in range(6):
			_add_bot_player()
		_tp_mod.call("set_team_format", 2) # 4v4 big teams
	_sync_lobby_seats(true)


func _enter_minigame_stage(stage_script: GDScript, cfg_res, mesh_res, node_name: String, is_roller: bool) -> void:
	_active_game = SandboxGameHost.new()
	_active_game.name = "Game"
	_scene_container.add_child(_active_game)

	_active_mg = SandboxMinigameHost.new()
	_active_mg.name = "ActiveMinigame"
	_active_game.add_child(_active_mg)

	var stage: Node3D = stage_script.new()
	stage.name = node_name
	if is_roller:
		stage.set("config", cfg_res.new())
		stage.set("_meshes", mesh_res)
	else:
		stage.set("C", cfg_res)
		stage.set("M", mesh_res)
	_active_stage = stage
	_active_mg.add_child(stage)

	var raw_scores_ref: Dictionary = {}
	stage.round_finished.connect(func(scores: Dictionary) -> void:
		if not is_instance_valid(_active_game) or not is_instance_valid(_active_mg) or not stage.is_inside_tree():
			return
		for k in scores.keys():
			_active_game.round_score_by_network_id[k] = int(scores[k])
		_active_mg.minigame_finished.emit(1)
		_show_synced_results(raw_scores_ref, _active_game.round_score_by_network_id)
	)
	var roster: Array = _build_roster_entries()
	stage.call("start_round", roster)
	if not _is_self_test:
		if not is_roller:
			stage.set("_intro_timer", 0.35)
			if stage.get("_prep_remaining") != null:
				stage.set("_prep_remaining", 0.35)
		else:
			stage.set("_countdown", 0.35)


func _show_synced_results(_raw_ref: Dictionary, final_scores: Dictionary) -> void:
	if _is_self_test or _results_modal == null:
		return
	var roster: Array = _build_roster_entries()
	var lines: PackedStringArray = PackedStringArray()
	for raw in roster:
		var e: Dictionary = raw as Dictionary
		var nid: int = int(e["network_id"])
		var tid: int = int(_tp_mod.call("get_team", nid))
		var tname: String = str(_tp_mod.call("get_team_name", tid)) if tid > 0 else "FFA"
		var sc: int = int(final_scores.get(nid, 0))
		lines.append("• %s  [%s]   →  同步後過場得分: %d 分" % [str(e["nickname"]), tname, sc])
	_results_text.text = "\n".join(lines)
	_results_modal.visible = true


func _add_action_button(label: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(cb)
	_action_buttons_box.add_child(btn)


func _find_first_teammate_and_enemy(players_dict: Dictionary, my_id: int) -> Dictionary:
	var mate: Dictionary = {}
	var enemy: Dictionary = {}
	for raw_id in players_dict.keys():
		var oid: int = int(raw_id)
		if oid == my_id:
			continue
		var p: Dictionary = players_dict[raw_id]
		if not bool(p.get("alive", true)):
			continue
		if bool(_tp_mod.call("are_teammates", my_id, oid)):
			if mate.is_empty():
				mate = p
		elif enemy.is_empty():
			enemy = p
	return {"mate": mate, "enemy": enemy}


func _setup_bubble_actions() -> void:
	_action_title_label.text = "泡泡爆破測試 (WASD+Space)"
	_add_action_button("[F5] 隊友瀕死 / 再按救援", _bb_action_rescue)
	_add_action_button("[F6] 友軍炸彈免傷測試", _bb_action_friendly_bomb)
	_add_action_button("[F7] 淘汰敵隊 (提前勝利)", _bb_action_win_early)


func _ensure_bb_live() -> void:
	if _active_stage == null:
		return
	_active_stage.set("_intro_timer", 0.0)
	_active_stage.set("_round_active", true)
	var b := _active_stage.get("_banner_label") as Label
	if b != null and (b.text == "3" or b.text == "2" or b.text == "1" or b.text == "GO!"):
		b.text = ""


func _bb_action_rescue() -> void:
	if _active_stage == null:
		return
	_ensure_bb_live()
	var ps: Dictionary = _active_stage.get("_players") as Dictionary
	if not ps.has(1):
		return
	var pair: Dictionary = _find_first_teammate_and_enemy(ps, 1)
	var mate: Dictionary = pair["mate"] as Dictionary
	var me: Dictionary = ps[1] as Dictionary
	if mate.is_empty():
		_action_feedback_label.text = "目前紅隊沒有隊友，請回大廳調整分隊。"
		return
	var tile_sz: float = float(_bb_cfg.TILE_SIZE)
	if bool(mate.get("trapped", false)):
		mate["pos"] = (me["pos"] as Vector3) + Vector3(tile_sz * 0.40, 0.0, 0.0)
		if mate.get("node", null) != null:
			(mate["node"] as Node3D).position = mate["pos"]
		_active_stage.call("_step_players", 0.02)
		_action_feedback_label.text = "救援成功：隊友 trapped=%s, hp=%d（重傷免疫處決並回 1 HP！）" % [str(mate["trapped"]), int(mate["hp"])]
	else:
		mate["invuln_timer"] = 0.0
		mate["trapped"] = true
		mate["trapped_timer"] = 0.0
		mate["hp"] = 0
		mate["pos"] = (me["pos"] as Vector3) + Vector3(tile_sz * 0.95, 0.0, 0.0)
		if mate.get("node", null) != null:
			(mate["node"] as Node3D).position = mate["pos"]
		_active_stage.call("_update_player_hud_3d", mate)
		_action_feedback_label.text = "隊友進入 4 秒瀕死 [救命!]！走向他碰撞即可救起，或再按一次 F5 立即救援。"


func _bb_action_friendly_bomb() -> void:
	if _active_stage == null:
		return
	_ensure_bb_live()
	var ps: Dictionary = _active_stage.get("_players") as Dictionary
	if not ps.has(1):
		return
	var pair: Dictionary = _find_first_teammate_and_enemy(ps, 1)
	var mate: Dictionary = pair["mate"] as Dictionary
	var enemy: Dictionary = pair["enemy"] as Dictionary
	if mate.is_empty() or enemy.is_empty():
		_action_feedback_label.text = "需要至少 1 名同隊隊友與 1 名敵人。"
		return
	mate["invuln_timer"] = 0.0
	enemy["invuln_timer"] = 0.0
	var hp_mate_before: int = int(mate["hp"])
	var hp_enemy_before: int = int(enemy["hp"])
	_active_stage.call("_hit_player_by_blast", mate, 1)
	_active_stage.call("_hit_player_by_blast", enemy, 1)
	_action_feedback_label.text = "友軍炸彈檢測：隊友 HP %d→%d (免傷!) | 敵人 HP %d→%d (扣血!)" % [
		hp_mate_before, int(mate["hp"]), hp_enemy_before, int(enemy["hp"])
	]


func _bb_action_win_early() -> void:
	if _active_stage == null:
		return
	_ensure_bb_live()
	var ps: Dictionary = _active_stage.get("_players") as Dictionary
	for raw_id in ps.keys():
		var oid: int = int(raw_id)
		if oid != 1 and not bool(_tp_mod.call("are_teammates", 1, oid)):
			_active_stage.call("_eliminate_player", ps[raw_id], 1, "TEST")
	_active_stage.call("_check_round_end")
	_action_feedback_label.text = "已淘汰全部敵隊，等待隊伍勝利橫幅與同步計分！"


func _setup_spike_actions() -> void:
	_action_title_label.text = "尖刺圓環測試 (WASD+Space)"
	_add_action_button("[F5] 360° 衝擊波免傷隊友", _sr_action_shockwave)
	_add_action_button("[F6] 拾取護盾 (3.5m 共振)", _sr_action_shield_link)
	_add_action_button("[F7] 淘汰敵隊 (提前勝利)", _sr_action_win_early)


func _ensure_sr_live() -> void:
	if _active_stage == null:
		return
	_active_stage.set("_prep_remaining", 0.0)
	_active_stage.set("_phase", 1)
	var b := _active_stage.get("_banner_label") as Label
	if b != null and (b.text == "3" or b.text == "2" or b.text == "1" or b.text == "READY"):
		b.text = ""


func _sr_move_player(p: Dictionary, new_pos: Vector3) -> void:
	p["pos"] = new_pos
	p["render_pos"] = new_pos
	var nid: int = int(p["network_id"])
	var hist: Dictionary = _active_stage.get("_pos_history") as Dictionary
	if hist != null:
		hist[nid] = [[0.0, new_pos]]
	if p.get("node", null) != null:
		(p["node"] as Node3D).position = new_pos


func _sr_action_shockwave() -> void:
	if _active_stage == null:
		return
	_ensure_sr_live()
	var ps: Dictionary = _active_stage.get("_players") as Dictionary
	var pair: Dictionary = _find_first_teammate_and_enemy(ps, 1)
	var mate: Dictionary = pair["mate"] as Dictionary
	var enemy: Dictionary = pair["enemy"] as Dictionary
	var me: Dictionary = ps[1] as Dictionary
	if mate.is_empty() or enemy.is_empty():
		_action_feedback_label.text = "需要至少 1 名同隊隊友與 1 名敵人。"
		return
	_sr_move_player(me, Vector3.ZERO)
	_sr_move_player(mate, Vector3(1.1, 0.0, 0.0))
	mate["invuln_timer"] = 0.0
	mate["state"] = 1
	_sr_move_player(enemy, Vector3(-1.1, 0.0, 0.0))
	enemy["invuln_timer"] = 0.0
	enemy["state"] = 1
	me["power_item"] = int(_sr_cfg.ITEM_SHOCKWAVE)
	_active_stage.call("_try_push", me)
	_action_feedback_label.text = "衝擊波結果：隊友 state=%d (未摔倒!) | 敵人 state=%d (3=已摔倒飛出!)" % [
		int(mate["state"]), int(enemy["state"])
	]


func _sr_action_shield_link() -> void:
	if _active_stage == null:
		return
	_ensure_sr_live()
	var ps: Dictionary = _active_stage.get("_players") as Dictionary
	var pair: Dictionary = _find_first_teammate_and_enemy(ps, 1)
	var mate: Dictionary = pair["mate"] as Dictionary
	var me: Dictionary = ps[1] as Dictionary
	if mate.is_empty():
		_action_feedback_label.text = "需要至少 1 名同隊隊友。"
		return
	_sr_move_player(me, Vector3.ZERO)
	me["shield"] = false
	_sr_move_player(mate, Vector3(2.4, 0.0, 0.0))
	mate["shield"] = false
	var ads: Array = _active_stage.get("_airdrops") as Array
	ads.append({"id": 999, "type": int(_sr_cfg.ITEM_SHIELD), "pos": Vector2.ZERO, "age": 0.0, "landed": true, "fall_timer": 0.0, "node": null})
	_active_stage.call("_step_airdrops", 0.01)
	_action_feedback_label.text = "護盾共振完成：Host=%s | 2.4m 內隊友=%s" % [str(me["shield"]), str(mate["shield"])]


func _sr_action_win_early() -> void:
	if _active_stage == null:
		return
	_ensure_sr_live()
	var ps: Dictionary = _active_stage.get("_players") as Dictionary
	for raw_id in ps.keys():
		var oid: int = int(raw_id)
		if oid != 1 and not bool(_tp_mod.call("are_teammates", 1, oid)):
			_active_stage.call("_eliminate_player", ps[raw_id], "TEST", 0)
	_active_stage.call("_check_round_end")
	_action_feedback_label.text = "已觸發僅剩一隊存活提前結束與 +10 同步結算！"


func _setup_roller_actions() -> void:
	_action_title_label.text = "滾筒嘉年華測試 (S=蹲 Space=跳)"
	_add_action_button("[F5] 隊友閃避 +5 次 (帶飛)", _rc_action_ally_boost)
	_add_action_button("[F6] 淘汰自己 (測隊友續戰)", _rc_action_elim_self)
	_add_action_button("[F7] 淘汰敵隊 (同步結算)", _rc_action_win_early)


func _ensure_rc_live() -> void:
	if _active_stage == null:
		return
	_active_stage.set("_countdown", 0.0)
	_active_stage.call("_update_entrance")
	_active_stage.call("_step_countdown_overlay")


func _rc_action_ally_boost() -> void:
	if _active_stage == null:
		return
	_ensure_rc_live()
	var plist: Array = _active_stage.get("_players") as Array
	for p in plist:
		var nid: int = int((p as Dictionary)["network_id"])
		if nid != 1 and bool(_tp_mod.call("are_teammates", 1, nid)):
			(p as Dictionary)["dodges"] = int((p as Dictionary)["dodges"]) + 5
			_action_feedback_label.text = "已為隊友 %s 增加 5 次躲避 (現 %d 次)，稍後結束可見你也會同步取得隊伍最高分！" % [str(p["nickname"]), int(p["dodges"])]
			return
	_action_feedback_label.text = "目前沒有同隊隊友。"


func _rc_action_elim_self() -> void:
	if _active_stage == null:
		return
	_ensure_rc_live()
	var plist: Array = _active_stage.get("_players") as Array
	for p in plist:
		if int((p as Dictionary)["network_id"]) == 1:
			_active_stage.call("_eliminate_player", p)
			_active_stage.call("_check_round_end")
			_action_feedback_label.text = "自己已被淘汰！因同隊仍有隊友存活，對局尚未結束 (%s)。" % ("未結束" if not bool(_active_stage.get("_match_ended")) else "已結束")
			return


func _rc_action_win_early() -> void:
	if _active_stage == null:
		return
	_ensure_rc_live()
	var plist: Array = _active_stage.get("_players") as Array
	for p in plist:
		var nid: int = int((p as Dictionary)["network_id"])
		if nid != 1 and not bool(_tp_mod.call("are_teammates", 1, nid)) and bool((p as Dictionary)["alive"]):
			_active_stage.call("_eliminate_player", p)
	_active_stage.call("_check_round_end")
	_action_feedback_label.text = "敵隊已全滅！已觸發紅隊提前勝利與同步分數。"


func _enter_disco_sandbox() -> void:
	_active_game = SandboxGameHost.new()
	_active_game.name = "Game"
	_scene_container.add_child(_active_game)

	_active_mg = SandboxMinigameHost.new()
	_active_mg.name = "DiscoMinigame"
	_disco_ended = false
	_disco_elapsed = 0.0
	_active_game.add_child(_active_mg)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.04, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.58, 0.78)
	env.environment = e
	_active_mg.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 24.0, 0.0)
	sun.light_energy = 1.25
	_active_mg.add_child(sun)

	_disco_camera = Camera3D.new()
	_disco_camera.look_at_from_position(Vector3(0.0, 9.6, 11.8), Vector3(0.0, 0.4, 0.0), Vector3.UP)
	_active_mg.add_child(_disco_camera)
	_disco_camera.make_current()

	var deck := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(13.6, 0.3, 13.6)
	deck.mesh = dbox
	deck.position = Vector3(0.0, -0.15, 0.0)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.11, 0.10, 0.20)
	deck.material_override = dmat
	_active_mg.add_child(deck)

	# Stylized lit disco tiles for visual clarity
	for gx in range(-2, 3):
		for gz in range(-2, 3):
			var tile := MeshInstance3D.new()
			var tbox := BoxMesh.new()
			tbox.size = Vector3(2.2, 0.04, 2.2)
			tile.mesh = tbox
			tile.position = Vector3(float(gx) * 2.4, 0.02, float(gz) * 2.4)
			var tmat := StandardMaterial3D.new()
			var checker: bool = ((gx + gz) & 1) == 0
			tmat.albedo_color = Color(0.19, 0.14, 0.34) if checker else Color(0.13, 0.18, 0.30)
			tile.material_override = tmat
			_active_mg.add_child(tile)

	var roster: Array = _build_roster_entries()
	_active_mg.player_count = roster.size()
	for i in range(roster.size()):
		var entry: Dictionary = roster[i] as Dictionary
		var nid: int = int(entry["network_id"])
		var tid: int = int(_tp_mod.call("get_team", nid))
		var actor := SandboxDiscoActor.new()
		actor.name = "DiscoPlayer_%d" % nid
		actor.player_presence = {"network_id": nid}
		actor.team_id = tid
		actor.is_human = (nid == 1)
		var ang: float = TAU * float(i) / float(maxi(1, roster.size()))
		actor.position = Vector3(cos(ang) * 4.0, 0.0, sin(ang) * 4.0)
		actor.look_at_from_position(actor.position, Vector3.ZERO, Vector3.UP)
		if nid == 1:
			actor.add_to_group(&"mpm_local_player")

		var cust: Array = (entry.get("customization", []) as Array).duplicate()

		var np: Label3D = null
		if _bb_meshes != null:
			var char_pack: Dictionary = _bb_meshes.build_worker_character(i, nid, str(entry["nickname"]), cust, nid == 1)
			var worker_root := char_pack.get("root", null) as Node3D
			if worker_root != null:
				actor.add_child(worker_root)
				np = worker_root.get_node_or_null("Nameplate") as Label3D
		if np == null:
			var mesh_inst := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.34
			cap.height = 1.1
			mesh_inst.mesh = cap
			mesh_inst.position = Vector3(0.0, 0.78, 0.0)
			var amat := StandardMaterial3D.new()
			amat.albedo_color = Color.from_hsv(float(i) / float(maxi(1, roster.size())), 0.7, 0.9)
			mesh_inst.material_override = amat
			actor.add_child(mesh_inst)
			np = Label3D.new()
			np.font = _make_3d_font()
			np.text = str(entry["nickname"])
			np.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			np.no_depth_test = true
			np.font_size = 42
			np.pixel_size = 0.0065
			np.outline_size = 12
			np.outline_modulate = Color.BLACK
			np.position = Vector3(0.0, 2.0, 0.0)
			actor.add_child(np)
		actor.player_name_label = np

		_active_mg.add_child(actor)
		_active_mg.active_players[nid] = actor
		_disco_actors[nid] = actor
		_active_game.round_score_by_network_id[nid] = 1


func _setup_disco_actions() -> void:
	_action_title_label.text = "Disco Dodge 測試 (WASD+Space)"
	_add_action_button("[F5] 推擊對照 (過濾隊友)", _disco_action_test_shove)
	_add_action_button("[F7] 淘汰敵隊 (同步計分)", _disco_action_win_early)


func _disco_action_test_shove() -> void:
	if _active_mg == null or not _disco_actors.has(1):
		return
	var host_a: SandboxDiscoActor = _disco_actors[1] as SandboxDiscoActor
	var mate_a: SandboxDiscoActor = null
	var enemy_a: SandboxDiscoActor = null
	for nid_v in _disco_actors.keys():
		var nid: int = int(nid_v)
		if nid == 1:
			continue
		var a: SandboxDiscoActor = _disco_actors[nid_v] as SandboxDiscoActor
		if not a.active:
			continue
		if bool(_tp_mod.call("are_teammates", 1, nid)) and mate_a == null:
			mate_a = a
		elif not bool(_tp_mod.call("are_teammates", 1, nid)) and enemy_a == null:
			enemy_a = a
	if mate_a == null or enemy_a == null:
		_action_feedback_label.text = "需要同隊隊友與敵人皆在場。"
		return
	mate_a.position = host_a.position + Vector3(1.1, 0.0, 0.0)
	enemy_a.position = host_a.position + Vector3(-1.1, 0.0, 0.0)
	host_a.players_in_shove_proximity = [mate_a, enemy_a]
	_tp_mod.call("_physics_process", 0.016)
	var before_enemy: Vector3 = enemy_a.position
	var pushed_count: int = 0
	for victim in host_a.players_in_shove_proximity:
		var va: SandboxDiscoActor = victim as SandboxDiscoActor
		var dir: Vector3 = (va.position - host_a.position).normalized()
		va.velocity_vec += dir * 9.0
		pushed_count += 1
	_action_feedback_label.text = "過濾後實際被推人數=%d | 隊友速度=%.2f (免疫!) | 敵人 %s 速度=%.2f (飛出!)" % [
		pushed_count, mate_a.velocity_vec.length(), enemy_a.player_presence["network_id"], (enemy_a.velocity_vec.length() if before_enemy == before_enemy else 0.0)
	]


func _disco_action_win_early() -> void:
	if _active_mg == null:
		return
	var alive_nids: Array = []
	for nid_v in _disco_actors.keys():
		var nid: int = int(nid_v)
		var a: SandboxDiscoActor = _disco_actors[nid_v] as SandboxDiscoActor
		if nid == 1 or bool(_tp_mod.call("are_teammates", 1, nid)):
			alive_nids.append(nid)
			_active_game.round_score_by_network_id[nid] = 5 if nid == 1 else 2
		else:
			a.active = false
			a.visible = false
			_active_mg.active_players.erase(nid)
			_active_mg.dead_players.append(nid)
			_active_game.round_score_by_network_id[nid] = 1
	_active_game.round_score_by_network_id = _tp_mod.call("compute_team_synchronized_scores", _active_game.round_score_by_network_id, alive_nids)
	_active_mg.minigame_finished.emit(1)
	_show_synced_results({}, _active_game.round_score_by_network_id)


func _process(delta: float) -> bool:
	if _current_scene_kind == SCENE_LOBBY and _active_lobby != null:
		_lobby_refresh_timer += delta
		if _lobby_refresh_timer >= 0.25:
			_lobby_refresh_timer = 0.0
			_update_chrome_summary()
	elif _current_scene_kind == SCENE_DISCO and not _disco_ended and _active_mg != null:
		_step_disco_sandbox(delta)
	return false


func _step_disco_sandbox(delta: float) -> void:
	_disco_elapsed += delta
	if _disco_actors.has(1):
		var h: SandboxDiscoActor = _disco_actors[1] as SandboxDiscoActor
		if h.active:
			var move := Vector3.ZERO
			if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
				move.x -= 1.0
			if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
				move.x += 1.0
			if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
				move.z -= 1.0
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
				move.z += 1.0
			if move.length_squared() > 0.01:
				h.position += move.normalized() * 4.8 * delta
			h.shove_cd = maxf(0.0, h.shove_cd - delta)
			if Input.is_key_pressed(KEY_SPACE) and h.shove_cd <= 0.0:
				h.shove_cd = 0.65
				_disco_action_test_shove()
	for a_v in _disco_actors.values():
		var a: SandboxDiscoActor = a_v as SandboxDiscoActor
		if not a.active:
			continue
		a.position += a.velocity_vec * delta
		a.velocity_vec = a.velocity_vec.move_toward(Vector3.ZERO, 14.0 * delta)


func _on_sandbox_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		if ke.keycode == KEY_F8:
			_update_chrome_summary()
		elif ke.keycode == KEY_1:
			_request_switch_scene(SCENE_LOBBY)
		elif ke.keycode == KEY_2:
			_request_switch_scene(SCENE_BUBBLE)
		elif ke.keycode == KEY_3:
			_request_switch_scene(SCENE_SPIKE)
		elif ke.keycode == KEY_4:
			_request_switch_scene(SCENE_ROLLER)
		elif ke.keycode == KEY_5:
			_request_switch_scene(SCENE_DISCO)
		elif ke.keycode == KEY_F5:
			match _current_scene_kind:
				SCENE_BUBBLE: _bb_action_rescue()
				SCENE_SPIKE: _sr_action_shockwave()
				SCENE_ROLLER: _rc_action_ally_boost()
				SCENE_DISCO: _disco_action_test_shove()
		elif ke.keycode == KEY_F6:
			match _current_scene_kind:
				SCENE_BUBBLE: _bb_action_friendly_bomb()
				SCENE_SPIKE: _sr_action_shield_link()
				SCENE_ROLLER: _rc_action_elim_self()
		elif ke.keycode == KEY_F7:
			match _current_scene_kind:
				SCENE_BUBBLE: _bb_action_win_early()
				SCENE_SPIKE: _sr_action_win_early()
				SCENE_ROLLER: _rc_action_win_early()
				SCENE_DISCO: _disco_action_win_early()


# ============================================================================
# Headless Automated Multi-Mod Team Verification (--sandbox-test)
# ============================================================================

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		push_error("TEAM_SANDBOX_FAIL: " + msg)


func _run_headless_self_tests() -> void:
	# 1. Lobby + Room Builder (including existing Bots) + Asymmetric 3v2v2 preset
	_switch_scene(SCENE_LOBBY)
	await process_frame
	_apply_roster_preset("3v2v2")
	_tp_mod.call("_process", 0.05)
	await process_frame
	var roster: Array = _build_roster_entries()
	_expect(roster.size() == 7, "3v2v2 preset yields 7 existing members")
	_expect(_bots_mod.bots.size() == 4, "lobby-bots count stays strictly at 4 existing bots")
	_expect(bool(_tp_mod.call("are_teammates", 1, -1)) and not bool(_tp_mod.call("are_teammates", 1, 3)), "Red [1,-1] vs Blue [3,-2]")
	var bot1_lbl: Label3D = _active_lobby.lobby_handler.nametags[3] as Label3D
	_expect(bot1_lbl.text.begins_with("[RED] ") or bot1_lbl.text.begins_with("[红]") or bot1_lbl.text.begins_with("[紅]"), "Bot 1 3D lobby nametag gets team prefix")

	# 2. Bubble Blitz (native team support inside bubble-blitz mod)
	_switch_scene(SCENE_BUBBLE)
	await process_frame
	_expect(_active_stage.has_meta(&"mpm_native_team_stage") and not _active_stage.has_meta(&"mpm_team_wrapped"), "BubbleBlitz runs native team mode without runtime wrapper")
	_bb_action_friendly_bomb()
	var bb_ps: Dictionary = _active_stage.get("_players") as Dictionary
	var bb_pair: Dictionary = _find_first_teammate_and_enemy(bb_ps, 1)
	var bb_mate: Dictionary = bb_pair["mate"] as Dictionary
	var bb_enemy: Dictionary = bb_pair["enemy"] as Dictionary
	_expect(int(bb_mate["hp"]) == int(_bb_cfg.MAX_HP), "BubbleBlitz: friendly blast deals 0 damage to teammate")
	_expect(int(bb_enemy["hp"]) == int(_bb_cfg.MAX_HP) - 1, "BubbleBlitz: blast deals 1 damage to enemy")
	_bb_action_rescue()
	var mate_hp_lbl := (bb_mate["node"] as Node3D).get_node_or_null("HpBar") as Label3D
	_expect(bool(bb_mate["trapped"]) and mate_hp_lbl != null and (mate_hp_lbl.text.contains("救命") or mate_hp_lbl.text.contains("HELP")), "BubbleBlitz: first F5 enters SOS countdown with localized prompt")
	_bb_action_rescue()
	_expect(not bool(bb_mate["trapped"]) and int(bb_mate["hp"]) == 1, "BubbleBlitz: second F5 / teammate touch rescues downed ally")
	var bb_won := {}
	_active_stage.round_finished.connect(func(s: Dictionary) -> void: bb_won.merge(s))
	_bb_action_win_early()
	await create_timer(1.55).timeout
	_expect(not bb_won.is_empty() and int(bb_won.get(1, -1)) == int(bb_won.get(int(bb_mate["network_id"]), -2)), "BubbleBlitz: early win emits synced squad scores")

	# 3. Spike Ring (native team support inside spike-ring mod)
	_switch_scene(SCENE_SPIKE)
	await process_frame
	_expect(_active_stage.has_meta(&"mpm_native_team_stage") and not _active_stage.has_meta(&"mpm_team_wrapped"), "SpikeRing runs native team mode without runtime wrapper")
	_sr_action_shockwave()
	var sr_ps: Dictionary = _active_stage.get("_players") as Dictionary
	var sr_pair: Dictionary = _find_first_teammate_and_enemy(sr_ps, 1)
	var sr_mate: Dictionary = sr_pair["mate"] as Dictionary
	var sr_enemy: Dictionary = sr_pair["enemy"] as Dictionary
	_expect(int(sr_mate["state"]) != int(_sr_cfg.ST_FALLEN), "SpikeRing: teammate immune to 360 shockwave")
	_expect(int(sr_enemy["state"]) == int(_sr_cfg.ST_FALLEN), "SpikeRing: enemy knocked down by shockwave")
	_sr_action_shield_link()
	_expect(bool(sr_ps[1]["shield"]) and bool(sr_mate["shield"]) and not bool(sr_enemy["shield"]), "SpikeRing: 3.5m shield resonance buffs ally only")
	var sr_won := {}
	_active_stage.round_finished.connect(func(s: Dictionary) -> void: sr_won.merge(s))
	_sr_action_win_early()
	await process_frame
	_expect(int(sr_won.get(1, -1)) > 0 and int(sr_won.get(1, -1)) == int(sr_won.get(2, -2)) and int(sr_won.get(1, -1)) == int(sr_won.get(-1, -3)), "SpikeRing: early win + synced squad scores")

	# 4. Roller Carnival (native team support inside roller-carnival mod)
	_switch_scene(SCENE_ROLLER)
	await process_frame
	_expect(_active_stage.has_meta(&"mpm_native_team_stage") and not _active_stage.has_meta(&"mpm_team_wrapped"), "RollerCarnival runs native team mode without runtime wrapper")
	var rc_ps: Array = _active_stage.get("_players") as Array
	_expect(rc_ps.size() == 7, "RollerCarnival spawns 7 players")
	# Verify Z lanes grouped by team (Red team 1 comes first along Z)
	_expect(int(rc_ps[0]["team_id"]) == 1 and int(rc_ps[1]["team_id"]) == 1 and int(rc_ps[2]["team_id"]) == 1, "RollerCarnival sorts Red 3-stack onto adjacent Z lanes")
	_rc_action_ally_boost()
	_rc_action_elim_self()
	_expect(not bool(_active_stage.get("_match_ended")), "RollerCarnival keeps going while Red teammates survive")
	var rc_won := {}
	_active_stage.round_finished.connect(func(s: Dictionary) -> void: rc_won.merge(s))
	_rc_action_win_early()
	await process_frame
	_expect(int(rc_won.get(1, -1)) == int(rc_won.get(-1, -2)) and int(rc_won.get(1, -1)) > 0, "RollerCarnival: early win syncs Red carry dodges onto eliminated host")

	# 5. Disco Dodge + Player Spotlight compat
	_switch_scene(SCENE_DISCO)
	await process_frame
	_disco_action_test_shove()
	var ha: SandboxDiscoActor = _disco_actors[1] as SandboxDiscoActor
	_expect(ha.players_in_shove_proximity.size() == 1 and (_disco_actors[-1] as SandboxDiscoActor).velocity_vec.length() == 0.0, "DiscoDodge: shove filter spares teammate")
	_expect(Engine.has_meta(&"mpm_player_spotlight_active"), "Player Spotlight meta coexists cleanly")
	_disco_action_win_early()
	await process_frame
	_expect(int(_active_game.round_score_by_network_id.get(1, -1)) == int(_active_game.round_score_by_network_id.get(-1, -2)), "DiscoDodge: squad synchronized scores")

	# 6. Deferred transition back -> 8-player Overtime 2v2v2v2 + Random Shuffle + round-trip to BubbleBlitz
	_request_switch_scene(SCENE_LOBBY)
	await process_frame
	await process_frame
	_apply_roster_preset("8p_duo")
	await process_frame
	_tp_mod.call("_process", 0.05)
	_expect(_build_roster_entries().size() == 8 and int(_tp_mod.get("team_count")) == 4, "Overtime 8P 2-per-team boots 8 members into 4 teams (2v2v2v2)")
	_tp_mod.call("shuffle_teams")
	var cnt := {1: 0, 2: 0, 3: 0, 4: 0}
	for e_raw in _build_roster_entries():
		var tid: int = int(_tp_mod.call("get_team", int((e_raw as Dictionary)["network_id"])))
		cnt[tid] = int(cnt.get(tid, 0)) + 1
	_expect(cnt[1] == 2 and cnt[2] == 2 and cnt[3] == 2 and cnt[4] == 2, "8P shuffle keeps exact 2v2v2v2 balance")
	# Chair click test in 8p_duo: reset to ordered 8p_duo, click seat 4 (Green Bot) as Host -> Host moves to seat 4 & swaps team with Bot
	_apply_roster_preset("8p_duo")
	await process_frame
	var pre_host_team: int = int(_tp_mod.call("get_team", 1))
	var pre_seat4_team: int = int(_tp_mod.call("_seat_zone_team", 4, 8))
	var clicked_ok: bool = bool(_tp_mod.call("click_lobby_chair", 4, 1))
	_expect(clicked_ok and int(_tp_mod.call("get_team", 1)) == pre_seat4_team and pre_seat4_team != pre_host_team, "Sandbox chair click swaps Host into seat 4 team")
	_expect(int((_active_lobby.get("player_order_by_seat") as Dictionary).get(4, -1)) == 1, "Sandbox chair click moves Host onto physical seat 4")
	# Host Grab-and-Drop test in 8p_duo: drag seat 0 (Host) onto seat 2 (Blue Bot) -> swaps teams & seats Host at seat 2
	_apply_roster_preset("8p_duo")
	await process_frame
	var drop_ok: bool = bool(_tp_mod.call("host_drop_chair", 0, 2))
	_expect(drop_ok and int(_tp_mod.call("get_team", 1)) == 2, "Sandbox host_drop_chair swaps Host onto Blue team")
	_expect(int((_active_lobby.get("player_order_by_seat") as Dictionary).get(2, -1)) == 1, "Sandbox host_drop_chair moves Host onto physical seat 2")
	# Removing & adding a Bot must preserve Host's moved seat, keep team_count == 4 fixed chair stances, and zero floating text badges
	_remove_bot_player()
	_tp_mod.call("_process", 0.05)
	_expect(int(_tp_mod.get("team_count")) == 4 and int((_active_lobby.get("player_order_by_seat") as Dictionary).get(2, -1)) == 1, "Removing a Bot keeps 8-chair stances fixed and preserves Host moved seat")
	_add_bot_player()
	_tp_mod.call("_process", 0.05)
	if ResourceLoader.exists("res://scenes/lobby/lobby_scene.tscn"):
		_expect((_tp_mod.get("_lobby_seat_rings") as Dictionary).size() == 8 and (_tp_mod.get("_lobby_seat_halos") as Dictionary).size() == 8, "3D lobby renders 8 pure ring+halo effects")
	_expect(_active_lobby.find_children("TeamChairBadge_*", "", true, false).is_empty(), "3D lobby has zero floating text TeamChairBadge_* labels")
	_request_switch_scene(SCENE_BUBBLE)
	await process_frame
	await process_frame
	var bb8_ps: Dictionary = _active_stage.get("_players") as Dictionary
	_expect(bb8_ps.size() == 8, "8-player scene switch into BubbleBlitz spawns all 8 workers cleanly")
	var hud_p := _tp_mod.get("_hud_panel") as PanelContainer
	_expect(hud_p != null and hud_p.visible and (hud_p.get_theme_stylebox("panel") is StyleBoxEmpty), "In-game HUD uses frameless native StyleBoxEmpty in BubbleBlitz")
	_expect(_tp_mod.get("_hud_rows") is HBoxContainer, "In-game HUD uses horizontal HBoxContainer strip")

	if not _failed:
		print("TEAM_SANDBOX_ALL_MODS_VERIFIED")
		print("SELF_TEST_PASSED")


func _shutdown(code: int) -> void:
	_clear_current_scene()
	_real_lobby_packed = null
	if _tp_mod != null:
		_disable_tree_safely(_tp_mod)
		_tp_mod.set("_sfx_ui_click", null)
		_tp_mod.free()
		_tp_mod = null
	if _spot_mod != null:
		_disable_tree_safely(_spot_mod)
		_spot_mod.free()
		_spot_mod = null
	if _chrome_layer != null:
		_chrome_layer.free()
		_chrome_layer = null
	if _input_relay != null:
		_input_relay.free()
		_input_relay = null
	_mod_loader.free()
	_net.free()
	_game_manager.free()
	_globals.free()
	# Release static asset caches from untouched minigame mesh scripts cleanly
	if _sr_meshes != null:
		_sr_meshes._shove_anim_cache = null
		_sr_meshes._hazard_assets.clear()
		_sr_meshes._saw_asset_cache.clear()
		_sr_meshes._shadow_assets.clear()
		_sr_meshes._item_assets.clear()
	if _bb_meshes != null:
		_bb_meshes._bomb_asset_cache.clear()
		_bb_meshes._blast_asset_cache.clear()
	if _rc_meshes != null:
		_rc_meshes._roller_asset_cache.clear()
	for tr in _translations:
		if tr is Translation:
			TranslationServer.remove_translation(tr as Translation)
	_translations.clear()
	_stub_scenes.clear()
	_stub_scripts.clear()
	_tab_buttons.clear()
	_bb_cfg = null
	_bb_meshes = null
	_bb_stage_script = null
	_sr_cfg = null
	_sr_meshes = null
	_sr_stage_script = null
	_rc_cfg = null
	_rc_meshes = null
	_rc_stage_script = null
	_cjk_3d_font = null
	for uid_rel in [
		"res://main.gd.uid",
		"res://team_registry.gd.uid",
		"res://lobby_assignment.gd.uid",
		"res://lobby_ui.gd.uid",
		"res://lobby_drag_3d.gd.uid",
		"res://vanilla_ingame.gd.uid",
		"res://ingame_hud.gd.uid",
	]:
		if FileAccess.file_exists(uid_rel):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(uid_rel))
	await create_timer(0.10).timeout
	await process_frame
	quit(code)
