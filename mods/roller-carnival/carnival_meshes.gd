extends RefCounted

## Asset loader and 3D builders for Roller Carnival (滾筒嘉年華).
## Uses authentic Machine Party 3D worker characters, cosmetics, textures,
## fonts, and animations when Machine Party.pck is mounted/available,
## with procedural mesh fallbacks if standalone assets are absent.

const PLAYER_COLORS := [
	Color(0.22, 0.58, 1.00), # P1: Blue
	Color(0.70, 0.34, 0.98), # P2: Purple
	Color(0.22, 0.84, 0.44), # P3: Green
	Color(0.96, 0.28, 0.30), # P4: Red
	Color(0.86, 0.89, 0.93), # P5: White / Silver
	Color(1.00, 0.56, 0.14), # P6: Orange
	Color(0.14, 0.86, 0.88), # P7: Cyan
	Color(1.00, 0.84, 0.20), # P8: Yellow
	Color(1.00, 0.36, 0.72), # P9: Hot Pink
	Color(0.62, 0.92, 0.24), # P10: Lime
	Color(0.95, 0.66, 0.22), # P11: Amber
	Color(0.20, 0.92, 0.68), # P12: Emerald
	Color(0.88, 0.20, 0.48), # P13: Crimson
	Color(0.30, 0.48, 0.98), # P14: Cobalt
	Color(0.76, 0.54, 1.00), # P15: Amethyst
	Color(0.84, 0.72, 0.34), # P16: Brass Gold
]

const PLAYER_NAMES := [
	"玩家 1 (你)",
	"發條阿紫",
	"鍋爐綠醬",
	"紅心活塞",
	"白銀鉚釘",
	"橘子渦輪",
	"青藍齒輪",
	"黃金彈簧",
	"霓虹飛輪",
	"蒸氣板手",
	"琥珀發條",
	"翡翠軸承",
	"深紅閥門",
	"鈷藍彈簧",
	"紫晶渦輪",
	"黑金齒輪",
]

const SUIT_TINTS := [
	Color.WHITE,
	Color.WHITE,
	Color.WHITE,
	Color.WHITE,
	Color.WHITE,
	Color(1.0, 0.62, 0.26),
	Color(0.32, 0.92, 0.96),
	Color.WHITE,
	Color(1.0, 0.45, 0.78),
	Color(0.68, 1.0, 0.34),
	Color(1.0, 0.72, 0.30),
	Color(0.32, 0.95, 0.74),
	Color(0.95, 0.26, 0.52),
	Color(0.38, 0.58, 1.0),
	Color(0.82, 0.62, 1.0),
	Color(0.92, 0.78, 0.38),
]

# Indices match PLAYER_COLORS (16 distinct workers using Machine Party textures & tints)
const SUIT_TEXTURE_MAP := [
	"res://modules/character_customization/character_customization_textures/main character painted blue.png",
	"res://modules/character_customization/character_customization_textures/main character painted purple.png",
	"res://modules/character_customization/character_customization_textures/main character painted green.png",
	"res://modules/character_customization/character_customization_textures/main character painted red.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://modules/character_customization/character_customization_textures/main character painted yellow.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
	"res://models/intermission intro2/intermission intro2_main character2_main character white.png",
]

const HAT_COSMETICS := [
	{"path": "res://models/character cosmetics/cosmetic_tophat/cosmetic_tophat.glb", "tf": Transform3D(Basis(Vector3(8.158974e-05, -0.037862033, 0.99928296), Vector3(0.019726971, 0.999088, 0.037853032), Vector3(-0.999805, 0.019709742, 0.00082841865)), Vector3(-0.037711527, -0.012129298, 0.0011413771))},
	{"path": "res://models/character cosmetics/cosmetic_traffic cone/cosmetic_traffic cone.glb", "tf": Transform3D(Basis(Vector3(8.235251e-05, 0.01972697, -0.999805), Vector3(-0.037861828, 0.999088, 0.019709704), Vector3(0.99928296, 0.03785286, 0.0008291773)), Vector3(0.003989991, 0.022721278, 0.00048916205))},
	{"path": "res://models/character cosmetics/cosmetic_rubiks cube/cosmetic_rubiks cube.glb", "tf": Transform3D(Basis(Vector3(-0.0005221995, -0.03484504, 0.9993929), Vector3(0.0957382, 0.9947999, 0.034734927), Vector3(-0.995406, 0.095698185, 0.0028165167)), Vector3(-0.042844664, -0.28462917, -0.0064088996))},
	{"path": "res://models/character cosmetics/cosmetic_maska helmet/cosmetic_maska helmet.glb", "tf": Transform3D(Basis(Vector3(7.8010664e-05, -0.035887193, 0.94715995), Vector3(0.018698016, 0.94697505, 0.035878647), Vector3(-0.94765496, 0.018681668, 0.00078588596)), Vector3(0.14080398, -0.25333482, -0.0127572995))},
	{"path": "res://models/character cosmetics/cosmetic_beer hat/cosmetic_beer hat.glb", "tf": Transform3D(Basis(Vector3(1.0025692e-06, -1.7719703e-12, 0.974151), Vector3(-1.4175761e-11, 0.974151, 1.7719849e-12), Vector3(-0.974152, -1.4175778e-11, 1.0025702e-06)), Vector3(-0.0142675, -0.0986309, -0.022806684))},
	{"path": "res://models/character cosmetics/cosmetic_cap blade/cosmetic_cap blade.glb", "tf": Transform3D(Basis(Vector3(0.003480548, 0.004266754, 0.956244), Vector3(0.113083966, 0.94953805, -0.0046484363), Vector3(-0.949544, 0.11309913, 0.0029515137)), Vector3(0.084976204, -0.106761985, -0.0011991335))},
	{"path": "res://models/character cosmetics/cosmetic_drill sgt hat/cosmetic_drill sgt hat.glb", "tf": Transform3D(Basis(Vector3(-4.4703484e-08, 1.8626451e-09, 1.0), Vector3(0.10154249, 0.9948314, 3.7252903e-09), Vector3(-0.9948314, 0.10154248, -3.7252903e-08)), Vector3(0.026, -0.018, 0.0))},
	{"path": "res://models/character cosmetics/cosmetic_hard hat/cosmetic_hard hat.glb", "tf": Transform3D(Basis(Vector3(-4.4703484e-08, -1.8626451e-09, 1.0), Vector3(0.1583304, 0.9873862, 9.313226e-09), Vector3(-0.9873862, 0.15833038, -3.7252903e-08)), Vector3(0.073, -0.045, 0.0))},
]

const GLASSES_COSMETICS := {
	0: {"path": "res://models/character cosmetics/cosmetic_glasses sunglasses/cosmetic_glasses sunglasses.glb", "tf": Transform3D(Basis(Vector3(-0.000494335, -0.00512526, 0.999987), Vector3(-0.0133705, 0.999898, 0.00511819), Vector3(-0.99991, -0.0133678, -0.000562828)), Vector3(0.249448, 0.222335, 6.0644e-05))},
	5: {"path": "res://models/character cosmetics/cosmetic_reading glasses/cosmetic_reading glasses.glb", "tf": Transform3D(Basis(Vector3(0.00952975, -0.0227329, 0.999696), Vector3(-0.141247, 0.989687, 0.0238517), Vector3(-0.989929, -0.141432, 0.00622053)), Vector3(0.253487, 0.231504, -0.0139316))},
}

const HAT_COSMETIC_BY_NAME := {
	"tophat": 0,
	"traffic_cone": 1,
	"rubiks_cube": 2,
	"maska_helmet": 3,
	"beer_hat": 4,
	"cap_blade": 5,
	"drill_sgt_hat": 6,
	"hard_hat": 7,
}

const GLASSES_COSMETIC_BY_NAME := {
	"sunglasses": 0,
	"reading_glasses": 5,
}

const SUIT_COLOR_VALUES := {
	"red": Color(0.96, 0.28, 0.30),
	"blue": Color(0.22, 0.58, 1.00),
	"green": Color(0.22, 0.84, 0.44),
	"yellow": Color(1.00, 0.84, 0.20),
	"purple": Color(0.70, 0.34, 0.98),
}

const TEX_SHREDDER := "res://minigames/escalator_pit/models/escalator pit art11/escalator pit art11_shredder6.png"
const TEX_HEAVY_RUST := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust2.png"
const TEX_RUST_PAINTED := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust painted2.png"
const TEX_METAL_PLATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_metal plate1.png"
const TEX_DARK_METAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_shotgun device metal darkened3.png"
const TEX_FLOOR := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba floor5.png"
const TEX_GRATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba grate.png"
const TEX_PIPES := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_fc pipes2.png"
const TEX_WALL := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba walls1.png"
const TEX_BRICK_WALL := "res://minigames/burn_recycle/models/burn recycle visuals6/burn recycle visuals6_burn and recycle brick wall bake.png"
const TEX_PLASTER_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_plaster damaged normal.png"
const TEX_SIDING := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba siding.png"
const TEX_DECAL_STAIN := "res://textures/decal stain masked1.png"
const TEX_DECAL_SCORCH := "res://textures/decals/explosion_mark.png"
const GLB_FAN := "res://minigames/smoke_break/models/smoke break fan1/smoke break fan1.glb"
const GLB_LIGHT_FIXTURE := "res://minigames/exploding_collar_race/models/collar race light fixture1/collar race light fixture1.glb"
const GLB_SERVER_RACK := "res://minigames/intermission_new/models/intermission server rack temp1/intermission server rack temp1.glb"
const GLB_PALLET := "res://minigames/chisel_gauntlet_multiplayer/models/chisel game pallet1/chisel game pallet1.glb"
const GLB_DEBRIS := "res://minigames/junk_platform/models/junk platform debris1/junk platform debris1.glb"

static var _pck_checked: bool = false
static var _pck_available: bool = false


static func ensure_game_pck_mounted() -> bool:
	if _pck_checked:
		return _pck_available
	_pck_checked = true

	if ResourceLoader.exists("res://fonts/Terminal F4.ttf"):
		_pck_available = true
		return true

	var pck_path := OS.get_environment("MP_PCK_PATH")
	if not pck_path.is_empty() and FileAccess.file_exists(pck_path):
		if ProjectSettings.load_resource_pack(pck_path, false):
			_pck_available = ResourceLoader.exists("res://fonts/Terminal F4.ttf")
			return _pck_available

	_pck_available = false
	return false


static func load_optional(path: String):
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func load_terminal_font() -> Font:
	return load_optional("res://fonts/Terminal F4.ttf")


static func make_toon_mat(color: Color, roughness: float = 0.48, metallic: float = 0.08, emission: Color = Color.BLACK, emission_energy: float = 0.0, tex_path: String = "", uv_scale: Vector3 = Vector3.ONE, triplanar: bool = true, normal_path: String = "", normal_scale: float = 0.72, linear_filter: bool = true) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if not tex_path.is_empty():
		var tex = load_optional(tex_path)
		if tex is Texture2D:
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC if linear_filter else BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_triplanar = triplanar
			mat.uv1_world_triplanar = triplanar
			mat.uv1_scale = uv_scale
	if not normal_path.is_empty():
		var norm = load_optional(normal_path)
		if norm is Texture2D:
			mat.normal_enabled = true
			mat.normal_texture = norm
			mat.normal_scale = normal_scale
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat


static func _strip_prop_collisions(node: Node) -> void:
	var children: Array = node.get_children()
	for raw_c in children:
		var c: Node = raw_c as Node
		if c is CollisionObject3D or c is CollisionShape3D:
			node.remove_child(c)
			c.free()
		else:
			_strip_prop_collisions(c)


static func _add_floor_decal(parent: Node3D, tex: Texture2D, pos: Vector3, size: Vector3, modulate: Color, rot_y: float = 0.0) -> void:
	if tex == null or parent == null:
		return
	var decal := Decal.new()
	decal.texture_albedo = tex
	decal.size = size
	decal.modulate = modulate
	decal.upper_fade = 0.25
	decal.lower_fade = 0.25
	decal.position = pos
	decal.rotation.y = rot_y
	parent.add_child(decal)


static func build_stage_and_environment(root: Node3D, cfg) -> Dictionary:
	ensure_game_pck_mounted()
	var result := {
		"gears": [],
		"bulbs": [],
		"fans": [],
		"flicker_lamp_mat": null,
		"lava_mesh": null,
		"lava_bubbles": [],
		"pit_shredders": [],
		"beacon_gold": null,
		"beacon_silver": null,
		"starting_line": null,
		"lane_tracks": [],
		"monitor_timer_label": null,
		"monitor_phase_label": null,
	}

	# --- World Environment (Machine Party indoor industrial tone + SSAO + depth fog + ACES) ---
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.016, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.39, 0.44)
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
	env.fog_light_color = Color(0.028, 0.024, 0.022)
	env.fog_depth_begin = 18.5
	env.fog_depth_end = 44.0
	env.fog_depth_curve = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	root.add_child(world_env)

	# --- Warm Directional Key Light with Crisp Shadows ---
	var dir_light := DirectionalLight3D.new()
	dir_light.name = "KeyLight"
	dir_light.light_color = Color(0.98, 0.90, 0.78)
	dir_light.light_energy = 1.20
	dir_light.shadow_enabled = true
	dir_light.shadow_bias = 0.05
	dir_light.shadow_blur = 1.3
	dir_light.directional_shadow_max_distance = 45.0
	dir_light.rotation_degrees = Vector3(-50.0, -28.0, 0.0)
	root.add_child(dir_light)

	# --- Overhead Industrial Stage Light Rig (Light Pools across center, dispenser & pit edge) ---
	var light_rig := Node3D.new()
	light_rig.name = "StageLightRig"
	root.add_child(light_rig)

	var center_spot := SpotLight3D.new()
	center_spot.name = "CenterStageSpot"
	center_spot.position = Vector3(1.2, 11.5, 0.4)
	center_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
	center_spot.light_color = Color(1.0, 0.91, 0.78)
	center_spot.light_energy = 11.5
	center_spot.spot_range = 24.0
	center_spot.spot_angle = 66.0
	center_spot.spot_angle_attenuation = 0.85
	center_spot.spot_attenuation = 1.15
	center_spot.shadow_enabled = true
	center_spot.shadow_bias = 0.05
	center_spot.shadow_blur = 1.4
	light_rig.add_child(center_spot)

	var dispenser_spot := SpotLight3D.new()
	dispenser_spot.name = "DispenserSpot"
	dispenser_spot.position = Vector3(10.2, 10.2, 0.2)
	dispenser_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
	dispenser_spot.light_color = Color(0.98, 0.86, 0.68)
	dispenser_spot.light_energy = 8.5
	dispenser_spot.spot_range = 22.0
	dispenser_spot.spot_angle = 58.0
	dispenser_spot.spot_attenuation = 1.18
	dispenser_spot.shadow_enabled = false
	light_rig.add_child(dispenser_spot)

	var pit_edge_spot := SpotLight3D.new()
	pit_edge_spot.name = "PitEdgeSpot"
	pit_edge_spot.position = Vector3(-5.6, 10.0, 0.2)
	pit_edge_spot.rotation_degrees = Vector3(-84.0, 0.0, 0.0)
	pit_edge_spot.light_color = Color(1.0, 0.80, 0.60)
	pit_edge_spot.light_energy = 7.8
	pit_edge_spot.spot_range = 22.0
	pit_edge_spot.spot_angle = 58.0
	pit_edge_spot.spot_attenuation = 1.18
	pit_edge_spot.shadow_enabled = false
	light_rig.add_child(pit_edge_spot)

	# --- Oblique 45-degree Top-Down Camera ---
	var cam := Camera3D.new()
	cam.name = "StageCamera"
	cam.fov = 40.0
	cam.position = Vector3(0.45, 11.8, 11.8)
	cam.look_at_from_position(cam.position, Vector3(0.35, 0.65, 0.0), Vector3.UP)
	cam.current = true
	root.add_child(cam)

	# --- Main Stage Platform (Matte concrete/iron deck vs brushed treadplate aprons) ---
	var left_x: float = cfg.stage_left_lava_x
	var right_x: float = cfg.roller_spawn_x + 0.8
	var stage_width: float = right_x - left_x
	var stage_center_x: float = (left_x + right_x) * 0.5
	var stage_depth: float = 9.2

	var deck := MeshInstance3D.new()
	deck.name = "StageDeck"
	var deck_box := BoxMesh.new()
	deck_box.size = Vector3(stage_width, 0.9, stage_depth)
	deck.mesh = deck_box
	deck.material_override = make_toon_mat(
		Color(0.56, 0.52, 0.49), 0.88, 0.06, Color.BLACK, 0.0,
		TEX_FLOOR, Vector3(0.16, 0.16, 0.16), true, "", 0.72, true
	)
	deck.position = Vector3(stage_center_x, -0.45, 0.0)
	root.add_child(deck)

	# Heavy brushed steel launch apron (dispenser entry) & landing apron (pit border) — clean matte steel, zero mesh moire
	var apron_steel_mat := make_toon_mat(
		Color(0.46, 0.44, 0.42), 0.48, 0.62, Color.BLACK, 0.0,
		TEX_METAL_PLATE, Vector3(0.18, 0.18, 0.18), true, "", 0.72, true
	)
	var launch_apron := MeshInstance3D.new()
	launch_apron.name = "LaunchApron"
	var la_box := BoxMesh.new()
	la_box.size = Vector3(3.6, 0.016, stage_depth - 0.16)
	launch_apron.mesh = la_box
	launch_apron.material_override = apron_steel_mat
	launch_apron.position = Vector3(right_x - 1.8, 0.003, 0.0)
	root.add_child(launch_apron)

	var landing_apron := MeshInstance3D.new()
	landing_apron.name = "LandingApron"
	var lnd_box := BoxMesh.new()
	lnd_box.size = Vector3(1.55, 0.016, stage_depth - 0.16)
	landing_apron.mesh = lnd_box
	landing_apron.material_override = apron_steel_mat
	landing_apron.position = Vector3(left_x + 1.52, 0.003, 0.0)
	root.add_child(landing_apron)

	# Grounded oil/grime & scorch decals along stage deck, dispenser mouth & shredder lip
	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D
	var scorch_tex := load_optional(TEX_DECAL_SCORCH) as Texture2D
	for st_spec in [
		[Vector3(-2.4, 0.04, -1.8), Vector3(2.8, 0.45, 2.4), 0.35],
		[Vector3(1.4, 0.04, 1.9), Vector3(3.1, 0.45, 2.5), 1.25],
		[Vector3(5.6, 0.04, -0.7), Vector3(2.9, 0.45, 2.6), -0.60],
		[Vector3(10.8, 0.04, 0.3), Vector3(3.2, 0.45, 3.0), 0.85],
	]:
		var sarr: Array = st_spec as Array
		_add_floor_decal(root, stain_tex, sarr[0] as Vector3, sarr[1] as Vector3, Color(0.16, 0.13, 0.11, 0.52), float(sarr[2]))
	for sc_spec in [
		[Vector3(left_x + 1.15, 0.04, -2.1), Vector3(2.1, 0.45, 2.1), 0.4],
		[Vector3(left_x + 1.10, 0.04, 2.2), Vector3(2.3, 0.45, 2.3), 1.9],
		[Vector3(12.0, 0.04, -1.4), Vector3(2.0, 0.45, 2.0), -0.8],
		[Vector3(12.2, 0.04, 1.8), Vector3(2.0, 0.45, 2.0), 2.1],
	]:
		var carr: Array = sc_spec as Array
		_add_floor_decal(root, scorch_tex, carr[0] as Vector3, carr[1] as Vector3, Color(0.14, 0.11, 0.09, 0.48), float(carr[2]))

	# Structural steel expansion plates spaced cleanly across the poured concrete runway
	var seam_mat := make_toon_mat(Color(0.28, 0.26, 0.26), 0.62, 0.55, Color.BLACK, 0.0, TEX_DARK_METAL, Vector3(0.24, 0.24, 0.24), true, "", 0.72, true)
	for i in range(1, 5):
		var sx: float = lerpf(left_x + 2.4, right_x - 3.6, float(i) / 5.0)
		var seam := MeshInstance3D.new()
		var seam_mesh := BoxMesh.new()
		seam_mesh.size = Vector3(0.14, 0.014, stage_depth - 0.4)
		seam.mesh = seam_mesh
		seam.material_override = seam_mat
		seam.position = Vector3(sx, 0.008, 0.0)
		root.add_child(seam)

	# Starting Line (clean painted industrial safety yellow strip on concrete)
	var start_line := MeshInstance3D.new()
	start_line.name = "StartingLine"
	var sl_mesh := BoxMesh.new()
	sl_mesh.size = Vector3(0.22, 0.024, stage_depth - 0.6)
	start_line.mesh = sl_mesh
	start_line.material_override = make_toon_mat(Color(0.94, 0.72, 0.18), 0.68, 0.08, Color(0.88, 0.62, 0.12), 0.16, TEX_FLOOR, Vector3(0.22, 0.22, 0.22), true, "", 0.72, true)
	start_line.position = Vector3(cfg.player_spawn_x, 0.016, 0.0)
	root.add_child(start_line)
	result["starting_line"] = start_line

	# Horizontal lane tracks from starting line leftward toward shredder pit (16 reusable tracks)
	var lane_mat := make_toon_mat(Color(0.08, 0.07, 0.07, 0.35), 0.88, 0.05)
	lane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var lane_tracks: Array = []
	for li in range(16):
		var lane := MeshInstance3D.new()
		lane.name = "LaneTrack_%d" % li
		var lm := BoxMesh.new()
		lm.size = Vector3(1.0, 0.012, 0.08)
		lane.mesh = lm
		lane.material_override = lane_mat
		root.add_child(lane)
		lane_tracks.append(lane)
	result["lane_tracks"] = lane_tracks

	var crack_mat := make_toon_mat(Color(0.10, 0.08, 0.11), 0.85, 0.1)
	for c in [Vector3(-2.6, 0.012, -1.6), Vector3(1.8, 0.012, 2.0), Vector3(-4.1, 0.012, 1.3), Vector3(4.3, 0.012, -1.9)]:
		var crack := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.95, 0.015, 0.07)
		crack.mesh = cm
		crack.material_override = crack_mat
		crack.position = c
		crack.rotation_degrees.y = (c.x * 23.0)
		root.add_child(crack)

	# Left Hazard Warning Stripes + Cast-Iron Curb bordering the shredder pit
	var pit_lip_grate := MeshInstance3D.new()
	pit_lip_grate.name = "PitLipGrate"
	var plg_m := BoxMesh.new()
	plg_m.size = Vector3(0.84, 0.022, stage_depth - 0.12)
	pit_lip_grate.mesh = plg_m
	pit_lip_grate.material_override = make_toon_mat(Color(0.26, 0.24, 0.24), 0.56, 0.62, Color.BLACK, 0.0, TEX_DARK_METAL, Vector3(0.22, 0.22, 0.22), true, "", 0.72, true)
	pit_lip_grate.position = Vector3(left_x + 0.38, 0.008, 0.0)
	root.add_child(pit_lip_grate)

	var stripe_yellow := make_toon_mat(Color(0.88, 0.66, 0.12), 0.64, 0.12, Color(0.88, 0.56, 0.08), 0.10, TEX_METAL_PLATE, Vector3(0.22, 0.22, 0.22), true, "", 0.72, true)
	var stripe_dark := make_toon_mat(Color(0.18, 0.16, 0.19), 0.66, 0.28, Color.BLACK, 0.0, TEX_METAL_PLATE, Vector3(0.22, 0.22, 0.22), true, "", 0.72, true)
	for idx in range(14):
		var sz: float = -stage_depth * 0.5 + 0.3 + float(idx) * (stage_depth / 14.0)
		var stripe := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.75, 0.03, 0.44)
		stripe.mesh = sm
		stripe.material_override = stripe_yellow if (idx % 2 == 0) else stripe_dark
		stripe.position = Vector3(left_x + 0.38, 0.015, sz)
		root.add_child(stripe)

	_build_guide_rails(root, cfg, left_x, right_x, stage_width, stage_center_x, stage_depth)
	_build_shredder_pit(root, result, left_x, stage_depth)
	_build_back_wall_and_monitor(root, result, left_x, stage_width, stage_center_x, stage_depth)
	_build_dispenser_gantry(root, result, cfg, stage_depth)
	_build_flank_props(root, left_x, right_x, stage_depth)

	update_starting_line(result, cfg)
	return result


static func _build_guide_rails(root: Node3D, cfg, left_x: float, right_x: float, stage_width: float, stage_center_x: float, stage_depth: float) -> void:
	var curb_mat := make_toon_mat(Color(0.68, 0.54, 0.34), 0.52, 0.48, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(0.28, 0.28, 0.28))
	var rail_mat := make_toon_mat(Color(0.62, 0.59, 0.58), 0.40, 0.68, Color.BLACK, 0.0, TEX_METAL_PLATE, Vector3(0.28, 0.28, 0.28))
	var post_mat := make_toon_mat(Color(0.44, 0.40, 0.39), 0.54, 0.56, Color.BLACK, 0.0, TEX_DARK_METAL, Vector3(0.28, 0.28, 0.28))

	for side in [-1.0, 1.0]:
		var curb := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(stage_width, 0.28, 0.26)
		curb.mesh = cm
		curb.material_override = curb_mat
		curb.position = Vector3(stage_center_x, 0.12, side * (stage_depth * 0.5 + 0.10))
		root.add_child(curb)

		var rail_z: float = side * (stage_depth * 0.5 + 0.24)
		for rail_y in [cfg.silver_roller_center_y, cfg.gold_roller_center_y]:
			var rail := MeshInstance3D.new()
			var rm := BoxMesh.new()
			rm.size = Vector3(stage_width, 0.14, 0.18)
			rail.mesh = rm
			rail.material_override = rail_mat
			rail.position = Vector3(stage_center_x, rail_y, rail_z)
			root.add_child(rail)

		var stanchion_count: int = 7
		for si in range(stanchion_count):
			var sx: float = lerpf(left_x + 0.4, right_x - 0.5, float(si) / float(stanchion_count - 1))
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.20, 1.72, 0.22)
			post.mesh = pm
			post.material_override = post_mat
			post.position = Vector3(sx, 0.80, rail_z)
			root.add_child(post)


static func _build_shredder_pit(root: Node3D, result: Dictionary, left_x: float, stage_depth: float) -> void:
	var pit_width: float = 7.5
	var pit_center_x: float = left_x - pit_width * 0.5 + 0.05

	var slag := MeshInstance3D.new()
	slag.name = "LavaPool"
	var slag_box := BoxMesh.new()
	slag_box.size = Vector3(pit_width - 0.6, 0.28, stage_depth - 0.55)
	slag.mesh = slag_box
	slag.material_override = make_toon_mat(
		Color(0.42, 0.24, 0.12), 0.62, 0.15,
		Color(0.78, 0.28, 0.05), 0.34,
		TEX_HEAVY_RUST, Vector3(0.40, 0.40, 0.40)
	)
	slag.position = Vector3(pit_center_x, -0.88, 0.0)
	root.add_child(slag)
	result["lava_mesh"] = slag

	# Dark rusted retaining walls framing the sunken shredder trench
	var wall_mat := make_toon_mat(Color(0.20, 0.18, 0.20), 0.68, 0.55, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(0.30, 0.30, 0.30))
	for side in [-1.0, 1.0]:
		var side_wall := MeshInstance3D.new()
		var swm := BoxMesh.new()
		swm.size = Vector3(pit_width + 0.6, 1.60, 0.50)
		side_wall.mesh = swm
		side_wall.material_override = wall_mat
		side_wall.position = Vector3(pit_center_x + 0.2, -0.52, side * (stage_depth * 0.5 + 0.38))
		root.add_child(side_wall)

	var far_wall := MeshInstance3D.new()
	var fwm := BoxMesh.new()
	fwm.size = Vector3(0.55, 1.45, stage_depth + 1.2)
	far_wall.mesh = fwm
	far_wall.material_override = wall_mat
	far_wall.position = Vector3(left_x - pit_width + 0.25, -0.25, 0.0)
	root.add_child(far_wall)

	var pit_grate_floor := MeshInstance3D.new()
	pit_grate_floor.name = "PitPerimeterGrate"
	var pgf_m := BoxMesh.new()
	pgf_m.size = Vector3(1.15, 0.12, stage_depth + 0.3)
	pit_grate_floor.mesh = pgf_m
	pit_grate_floor.material_override = make_toon_mat(
		Color(0.26, 0.24, 0.24), 0.56, 0.62, Color.BLACK, 0.0, TEX_GRATE, Vector3(0.35, 0.35, 0.35), true, "", 0.72, true
	)
	pit_grate_floor.position = Vector3(left_x - 2.65, -0.56, 0.0)
	root.add_child(pit_grate_floor)

	var shredder_mat := make_toon_mat(Color(0.68, 0.62, 0.62), 0.45, 0.72, Color.BLACK, 0.0, TEX_SHREDDER, Vector3(1.0, 2.0, 1.0), false)
	var blade_mat := make_toon_mat(Color(0.26, 0.22, 0.22), 0.50, 0.65, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(0.5, 0.5, 0.5))
	for sx_idx in range(2):
		var sx: float = left_x - 0.62 - float(sx_idx) * 0.96
		var shaft := Node3D.new()
		shaft.name = "PitShredder_%d" % sx_idx
		shaft.position = Vector3(sx, -0.22, 0.0)

		var core := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.radial_segments = 10
		cm.rings = 1
		cm.top_radius = 0.35
		cm.bottom_radius = 0.35
		cm.height = stage_depth + 0.2
		core.mesh = cm
		core.material_override = shredder_mat
		core.rotation_degrees.x = 90.0
		shaft.add_child(core)

		for ring_i in range(9):
			var rz: float = -stage_depth * 0.44 + float(ring_i) * (stage_depth * 0.88 / 8.0)
			for b in range(4):
				var ang: float = TAU * float(b) / 4.0 + float(ring_i) * 0.38
				var blade := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.24, 0.09, 0.36)
				blade.mesh = bm
				blade.material_override = blade_mat
				blade.position = Vector3(cos(ang) * 0.36, sin(ang) * 0.36, rz)
				blade.rotation.z = ang + 0.3
				shaft.add_child(blade)

		root.add_child(shaft)
		result["pit_shredders"].append(shaft)

	var lava_light := OmniLight3D.new()
	lava_light.name = "LavaGlowLight"
	lava_light.light_color = Color(1.0, 0.34, 0.06)
	lava_light.light_energy = 2.4
	lava_light.omni_range = 11.5
	lava_light.position = Vector3(left_x - 1.8, 1.1, 0.0)
	root.add_child(lava_light)

	var ember_mat := make_toon_mat(Color(1.0, 0.56, 0.12), 0.25, 0.0, Color(1.0, 0.48, 0.06), 1.55)
	for b in range(16):
		var emesh := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		var esize: float = 0.09 + float(b % 3) * 0.03
		ebox.size = Vector3(esize, esize, esize)
		emesh.mesh = ebox
		emesh.material_override = ember_mat
		var bx: float = left_x - 0.55 - float(b % 5) * 0.95
		var bz: float = -3.6 + float(b) * 0.48
		emesh.position = Vector3(bx, -0.58, bz)
		emesh.rotation_degrees = Vector3(float(b * 23), float(b * 41), float(b * 17))
		root.add_child(emesh)
		result["lava_bubbles"].append({
			"node": emesh,
			"base_x": bx,
			"base_z": bz,
			"phase": float(b) * 0.67,
		})


static func _build_back_wall_and_monitor(root: Node3D, result: Dictionary, _left_x: float, stage_width: float, stage_center_x: float, stage_depth: float) -> void:
	var back_z: float = -stage_depth * 0.5 - 1.05
	var wall_mat := make_toon_mat(
		Color(0.70, 0.66, 0.62), 0.84, 0.10, Color.BLACK, 0.0,
		TEX_BRICK_WALL, Vector3(0.20, 0.20, 0.20), true, TEX_PLASTER_NORMAL, 0.80, true
	)
	var pipe_mat := make_toon_mat(Color(0.56, 0.50, 0.48), 0.46, 0.65, Color.BLACK, 0.0, TEX_PIPES, Vector3(0.4, 0.4, 0.4))
	var dark_metal_mat := make_toon_mat(Color(0.42, 0.39, 0.38), 0.46, 0.62, Color.BLACK, 0.0, TEX_DARK_METAL, Vector3(0.4, 0.4, 0.4))

	var back_wall := MeshInstance3D.new()
	back_wall.name = "BackWall"
	var wm := BoxMesh.new()
	wm.size = Vector3(stage_width + 11.0, 6.6, 0.45)
	back_wall.mesh = wm
	back_wall.material_override = wall_mat
	back_wall.position = Vector3(stage_center_x - 3.6, 2.6, back_z - 0.45)
	root.add_child(back_wall)

	# North wall service ledge so wall fixtures & racks sit grounded cleanly clear of guide rails
	var north_ledge := MeshInstance3D.new()
	north_ledge.name = "NorthWallLedge"
	var nlm := BoxMesh.new()
	nlm.size = Vector3(stage_width + 10.5, 0.9, 1.35)
	north_ledge.mesh = nlm
	north_ledge.material_override = dark_metal_mat
	north_ledge.position = Vector3(stage_center_x - 3.6, -0.45, back_z + 0.22)
	root.add_child(north_ledge)

	for py in [1.95, 4.55]:
		var pipe := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.radial_segments = 10
		pm.top_radius = 0.16
		pm.bottom_radius = 0.16
		pm.height = stage_width + 9.5
		pipe.mesh = pm
		pipe.material_override = pipe_mat
		pipe.rotation_degrees.z = 90.0
		pipe.position = Vector3(stage_center_x - 3.6, py, back_z - 0.14)
		root.add_child(pipe)

	# Rotating mechanical saw gears along the lower back wall (kept cleanly below fans & clear of fixtures)
	var gear_specs := [
		[-3.80, 0.78, 1.15],
		[0.35, 1.05, 1.45],
		[4.50, 0.78, 1.15],
		[8.40, 0.88, 1.20],
	]
	for g in range(gear_specs.size()):
		var gs: Array = gear_specs[g] as Array
		var saw_tex := "res://minigames/dvd_roomba/models/dvd roomba visuals1_circular saw2.png" if g % 2 == 0 else "res://minigames/dvd_roomba/models/dvd roomba visuals1_circular saw bloody.png"
		var gear := _build_gear(float(gs[2]), 10, Color(0.84, 0.68, 0.42) if g % 2 == 0 else Color(0.76, 0.78, 0.82), saw_tex)
		gear.position = Vector3(float(gs[0]), float(gs[1]), back_z + 0.05)
		root.add_child(gear)
		result["gears"].append(gear)

	# Two spinning exhaust fans mirrored symmetrically outside the 4 tube lamps around CRT (x=0.35)
	var fan_packed = load_optional(GLB_FAN)
	var fan_shroud_m := CylinderMesh.new()
	fan_shroud_m.radial_segments = 20
	fan_shroud_m.top_radius = 0.72
	fan_shroud_m.bottom_radius = 0.76
	fan_shroud_m.height = 0.28
	var fan_positions := [
		Vector3(-6.65, 3.00, back_z + 0.10),
		Vector3(7.35, 3.00, back_z + 0.10),
	]
	for f_idx in range(fan_positions.size()):
		var fpos: Vector3 = fan_positions[f_idx] as Vector3
		var shroud := MeshInstance3D.new()
		shroud.name = "ExhaustFanShroud_%d" % f_idx
		shroud.mesh = fan_shroud_m
		shroud.rotation_degrees.x = 90.0
		shroud.position = fpos + Vector3(0.0, 0.0, -0.10)
		shroud.material_override = dark_metal_mat
		root.add_child(shroud)

		var fan_mount := Node3D.new()
		fan_mount.name = "ExhaustFanMount_%d" % f_idx
		fan_mount.position = fpos + Vector3(0.0, 0.0, 0.04)
		fan_mount.rotation_degrees.y = 180.0
		fan_mount.scale = Vector3(0.56, 0.56, 0.56)
		root.add_child(fan_mount)

		if fan_packed is PackedScene:
			var fan_inst: Node3D = (fan_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(fan_inst)
			var fan_mesh := fan_inst.get_node_or_null("fan_002") as MeshInstance3D
			if fan_mesh != null:
				fan_mesh.position = Vector3.ZERO
				result["fans"].append(fan_mesh)
			else:
				result["fans"].append(fan_inst)
			fan_mount.add_child(fan_inst)
		else:
			var hub_pivot := Node3D.new()
			hub_pivot.name = "FallbackFan_%d" % f_idx
			var rust_fb := make_toon_mat(Color(0.54, 0.42, 0.34), 0.52, 0.55)
			for b_i in range(4):
				var blade := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(1.55, 0.22, 0.08)
				blade.mesh = bm
				blade.rotation_degrees.z = float(b_i) * 45.0
				blade.material_override = rust_fb
				hub_pivot.add_child(blade)
			fan_mount.add_child(hub_pivot)
			result["fans"].append(hub_pivot)

	# Tucked flanking bay light fixtures strictly inside north wall height & clear of saw gears
	var fixture_packed = load_optional(GLB_LIGHT_FIXTURE)
	var fix_bulb_mat := make_toon_mat(Color(1.0, 0.84, 0.54), 0.20, 0.10, Color(1.0, 0.76, 0.38), 1.80)
	var fix_rust_mat := make_toon_mat(Color(0.46, 0.36, 0.28), 0.54, 0.58)
	var fix_specs := [
		[Vector3(-8.55, 0.0, back_z + 0.14), 0.22],
		[Vector3(10.25, 0.0, back_z + 0.14), 0.22],
	]
	for fx_idx in range(fix_specs.size()):
		var fspec: Array = fix_specs[fx_idx] as Array
		var fpos: Vector3 = fspec[0] as Vector3
		var fscale: float = float(fspec[1])
		if fixture_packed is PackedScene:
			var finst: Node3D = (fixture_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(finst)
			finst.name = "BayLightFixture_%d" % fx_idx
			finst.position = fpos
			finst.scale = Vector3(fscale, fscale, fscale)
			var cyl_mi := finst.get_node_or_null("Cylinder") as MeshInstance3D
			if cyl_mi != null:
				cyl_mi.set_surface_override_material(1, fix_bulb_mat)
			root.add_child(finst)
		else:
			var pole_h: float = 13.28 * fscale
			var stem := MeshInstance3D.new()
			var stm := CylinderMesh.new()
			stm.top_radius = 0.07
			stm.bottom_radius = 0.11
			stm.height = pole_h
			stem.mesh = stm
			stem.position = fpos + Vector3(0.0, pole_h * 0.5, 0.0)
			stem.material_override = dark_metal_mat
			root.add_child(stem)
			var hood := MeshInstance3D.new()
			var hdm := CylinderMesh.new()
			hdm.top_radius = 0.22
			hdm.bottom_radius = 0.48
			hdm.height = 0.34
			hood.mesh = hdm
			hood.position = fpos + Vector3(0.0, pole_h, 0.0)
			hood.material_override = fix_rust_mat
			root.add_child(hood)

	# Symmetric industrial cage wall lamps flanking the CRT monitor (1 assigned to flicker_lamp_mat)
	var lamp_packed = load_optional("res://models/elevator light2/elevator light2.glb")
	var cage_mat := make_toon_mat(Color(0.24, 0.22, 0.22), 0.52, 0.72, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(0.5, 0.5, 0.5))
	var lamp_xs := [-4.65, -2.25, 2.95, 5.35]
	for l_idx in range(lamp_xs.size()):
		var lx: float = float(lamp_xs[l_idx])
		var lamp_mat := make_toon_mat(Color(1.0, 0.74, 0.36), 0.22, 0.0, Color(1.0, 0.66, 0.24), 1.65)
		if l_idx == 1:
			result["flicker_lamp_mat"] = lamp_mat
		if lamp_packed is PackedScene:
			var linst: Node3D = lamp_packed.instantiate()
			_strip_prop_collisions(linst)
			linst.position = Vector3(lx, 3.22, back_z + 0.08)
			linst.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			linst.scale = Vector3(0.62, 0.62, 0.62)
			root.add_child(linst)
			for c in linst.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).set_surface_override_material(0, lamp_mat)
		else:
			var housing := MeshInstance3D.new()
			var hm := BoxMesh.new()
			hm.size = Vector3(0.95, 0.32, 0.28)
			housing.mesh = hm
			housing.material_override = cage_mat
			housing.position = Vector3(lx, 3.22, back_z - 0.08)
			root.add_child(housing)

			var filament := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(0.72, 0.16, 0.16)
			filament.mesh = fm
			filament.material_override = lamp_mat
			filament.position = Vector3(lx, 3.20, back_z + 0.04)
			root.add_child(filament)
		result["bulbs"].append(lamp_mat)

	var warm_stage_light := OmniLight3D.new()
	warm_stage_light.name = "CarnivalStageGlow"
	warm_stage_light.light_color = Color(1.0, 0.74, 0.40)
	warm_stage_light.light_energy = 3.1
	warm_stage_light.omni_range = 16.0
	warm_stage_light.position = Vector3(1.5, 2.6, back_z + 2.2)
	root.add_child(warm_stage_light)

	var left_wall_light := OmniLight3D.new()
	left_wall_light.name = "PitWallLight"
	left_wall_light.light_color = Color(1.0, 0.66, 0.34)
	left_wall_light.light_energy = 2.8
	left_wall_light.omni_range = 14.0
	left_wall_light.position = Vector3(-7.0, 2.6, back_z + 2.2)
	root.add_child(left_wall_light)

	var right_wall_light := OmniLight3D.new()
	right_wall_light.name = "DispenserWallLight"
	right_wall_light.light_color = Color(1.0, 0.70, 0.38)
	right_wall_light.light_energy = 2.9
	right_wall_light.omni_range = 14.0
	right_wall_light.position = Vector3(8.5, 2.6, back_z + 2.2)
	root.add_child(right_wall_light)

	# --- 3D Diegetic Industrial CRT Timer Monitor on Back Wall ---
	var monitor := Node3D.new()
	monitor.name = "DiegeticMonitor"
	monitor.position = Vector3(0.35, 2.78, back_z + 0.22)
	monitor.rotation_degrees.x = 18.0
	root.add_child(monitor)

	var casing := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.45, 1.78, 0.45)
	casing.mesh = cm
	casing.material_override = make_toon_mat(Color(0.30, 0.28, 0.28), 0.56, 0.65, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(0.4, 0.4, 0.4))
	monitor.add_child(casing)

	var bezel := MeshInstance3D.new()
	var bzm := BoxMesh.new()
	bzm.size = Vector3(3.16, 1.50, 0.10)
	bezel.mesh = bzm
	bezel.material_override = make_toon_mat(Color(0.10, 0.10, 0.11), 0.68, 0.45)
	bezel.position = Vector3(0.0, 0.0, 0.20)
	monitor.add_child(bezel)

	var screen := MeshInstance3D.new()
	var scm := BoxMesh.new()
	scm.size = Vector3(2.96, 1.30, 0.04)
	screen.mesh = scm
	screen.material_override = make_toon_mat(Color(0.03, 0.06, 0.04), 0.25, 0.10, Color(0.08, 0.20, 0.10), 0.32)
	screen.position = Vector3(0.0, 0.0, 0.24)
	monitor.add_child(screen)

	var term_font := load_terminal_font()
	var timer_lbl := Label3D.new()
	timer_lbl.name = "MonitorTimerLabel"
	timer_lbl.text = "00:50"
	timer_lbl.font_size = 96
	timer_lbl.pixel_size = 0.0095
	timer_lbl.modulate = Color(0.53, 0.83, 0.50)
	timer_lbl.outline_modulate = Color(0.02, 0.06, 0.02)
	timer_lbl.outline_size = 14
	if term_font != null:
		timer_lbl.font = term_font
	timer_lbl.position = Vector3(0.0, 0.14, 0.27)
	monitor.add_child(timer_lbl)
	result["monitor_timer_label"] = timer_lbl

	var phase_lbl := Label3D.new()
	phase_lbl.name = "MonitorPhaseLabel"
	phase_lbl.text = "WAVE 01 // SINGLE"
	phase_lbl.font_size = 30
	phase_lbl.pixel_size = 0.0085
	phase_lbl.modulate = Color(0.45, 0.72, 0.42)
	phase_lbl.outline_modulate = Color(0.02, 0.06, 0.02)
	phase_lbl.outline_size = 8
	if term_font != null:
		phase_lbl.font = term_font
	phase_lbl.position = Vector3(0.0, -0.38, 0.27)
	monitor.add_child(phase_lbl)
	result["monitor_phase_label"] = phase_lbl


static func _build_dispenser_gantry(root: Node3D, result: Dictionary, cfg, stage_depth: float) -> void:
	var gantry_x: float = cfg.roller_spawn_x + 0.2
	var gantry_mat := make_toon_mat(Color(0.50, 0.46, 0.48), 0.48, 0.68, Color.BLACK, 0.0, TEX_SIDING, Vector3(0.26, 0.26, 0.26))
	var beam_mat := make_toon_mat(Color(0.58, 0.44, 0.24), 0.50, 0.64, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(0.26, 0.26, 0.26))
	for gz in [-stage_depth * 0.5 - 0.15, stage_depth * 0.5 + 0.15]:
		var pillar := MeshInstance3D.new()
		var pil_m := BoxMesh.new()
		pil_m.size = Vector3(0.55, 3.4, 0.55)
		pillar.mesh = pil_m
		pillar.material_override = gantry_mat
		pillar.position = Vector3(gantry_x, 1.7, gz)
		root.add_child(pillar)

	var top_beam := MeshInstance3D.new()
	var beam_m := BoxMesh.new()
	beam_m.size = Vector3(0.65, 0.55, stage_depth + 0.85)
	top_beam.mesh = beam_m
	top_beam.material_override = beam_mat
	top_beam.position = Vector3(gantry_x, 3.35, 0.0)
	root.add_child(top_beam)

	var beacon_gold := MeshInstance3D.new()
	var bg_m := CylinderMesh.new()
	bg_m.radial_segments = 8
	bg_m.top_radius = 0.22
	bg_m.bottom_radius = 0.26
	bg_m.height = 0.44
	beacon_gold.mesh = bg_m
	beacon_gold.material_override = make_toon_mat(Color(0.95, 0.68, 0.16), 0.25, 0.1, Color(0.95, 0.66, 0.12), 0.5)
	beacon_gold.position = Vector3(gantry_x - 0.22, 3.35, -1.2)
	root.add_child(beacon_gold)
	result["beacon_gold"] = beacon_gold

	var beacon_silver := MeshInstance3D.new()
	var bs_m := CylinderMesh.new()
	bs_m.radial_segments = 8
	bs_m.top_radius = 0.22
	bs_m.bottom_radius = 0.26
	bs_m.height = 0.44
	beacon_silver.mesh = bs_m
	beacon_silver.material_override = make_toon_mat(Color(0.68, 0.82, 0.94), 0.25, 0.1, Color(0.52, 0.78, 0.96), 0.5)
	beacon_silver.position = Vector3(gantry_x - 0.22, 3.35, 1.2)
	root.add_child(beacon_silver)
	result["beacon_silver"] = beacon_silver


static func _build_flank_props(root: Node3D, left_x: float, right_x: float, stage_depth: float) -> void:
	var back_z: float = -stage_depth * 0.5 - 1.05
	var dark_metal_mat := make_toon_mat(Color(0.28, 0.26, 0.26), 0.52, 0.58, Color.BLACK, 0.0, TEX_DARK_METAL, Vector3(0.5, 0.5, 0.5))
	var screen_mat := make_toon_mat(Color(0.06, 0.14, 0.09), 0.30, 0.10, Color(0.22, 0.48, 0.28), 0.45)
	var rust_mat := make_toon_mat(Color(0.40, 0.31, 0.24), 0.62, 0.42, Color.BLACK, 0.0, TEX_RUST_PAINTED, Vector3(0.5, 0.5, 0.5))
	var pier_steel_mat := make_toon_mat(Color(0.36, 0.34, 0.33), 0.58, 0.52, Color.BLACK, 0.0, TEX_DARK_METAL, Vector3(0.22, 0.22, 0.22), true, "", 0.72, true)
	var pallet_mat := make_toon_mat(Color(0.36, 0.30, 0.25), 0.85, 0.15, Color.BLACK, 0.0, TEX_HEAVY_RUST, Vector3(1.0, 1.0, 1.0))

	# Grounded service aprons on outer left pit flank and outer right dispenser flank
	var left_pier := MeshInstance3D.new()
	left_pier.name = "LeftPitServicePier"
	var lpm := BoxMesh.new()
	lpm.size = Vector3(3.2, 0.9, 2.0)
	left_pier.mesh = lpm
	left_pier.material_override = pier_steel_mat
	left_pier.position = Vector3(left_x - 3.5, -0.45, -3.75)
	root.add_child(left_pier)

	var right_apron := MeshInstance3D.new()
	right_apron.name = "RightDispenserServiceApron"
	var ram := BoxMesh.new()
	ram.size = Vector3(2.4, 0.9, stage_depth + 0.6)
	right_apron.mesh = ram
	right_apron.material_override = pier_steel_mat
	right_apron.position = Vector3(right_x + 0.9, -0.45, 0.0)
	root.add_child(right_apron)

	var rack_packed = load_optional(GLB_SERVER_RACK)
	var pallet_packed = load_optional(GLB_PALLET)
	var debris_packed = load_optional(GLB_DEBRIS)

	# Darkened control racks tucked cleanly against north wall flanks (zero clipping / zero bright monoliths)
	for rp_raw in [
		[Vector3(-9.75, 0.0, back_z + 0.44), 16.0, 0.38],
		[Vector3(11.35, 0.0, back_z + 0.44), -24.0, 0.38],
	]:
		var rp: Array = rp_raw as Array
		var rpos: Vector3 = rp[0] as Vector3
		var ryaw: float = float(rp[1])
		var rscale: float = float(rp[2])
		if rack_packed is PackedScene:
			var rinst: Node3D = (rack_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(rinst)
			var rack_cube := rinst.get_node_or_null("Cube") as MeshInstance3D
			if rack_cube != null:
				rack_cube.material_override = dark_metal_mat
				var rack_screen := rack_cube.get_node_or_null("Plane_001") as MeshInstance3D
				if rack_screen != null:
					rack_screen.material_override = screen_mat
			rinst.position = rpos
			rinst.rotation_degrees.y = ryaw
			rinst.scale = Vector3(rscale, rscale, rscale)
			root.add_child(rinst)
		else:
			var rbox := MeshInstance3D.new()
			var rbm := BoxMesh.new()
			rbm.size = Vector3(0.65, 2.0, 0.9)
			rbox.mesh = rbm
			rbox.position = rpos + Vector3(0.0, 1.0, 0.0)
			rbox.rotation_degrees.y = ryaw
			rbox.material_override = dark_metal_mat
			root.add_child(rbox)

	# Low weathered pallets (reset Cube_019 offset/rotation + dark weathered wood/rust override)
	for pp_raw in [
		[Vector3(left_x - 3.1, 0.15, -3.55), 10.0, 0.44],
		[Vector3(9.45, 0.15, back_z + 0.44), -6.0, 0.38],
	]:
		var pp: Array = pp_raw as Array
		var ppos: Vector3 = pp[0] as Vector3
		var pyaw: float = float(pp[1])
		var pscale: float = float(pp[2])
		if pallet_packed is PackedScene:
			var pinst: Node3D = (pallet_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(pinst)
			var cube := pinst.get_node_or_null("Cube_019") as MeshInstance3D
			if cube != null:
				cube.position = Vector3.ZERO
				cube.rotation = Vector3.ZERO
				cube.material_override = pallet_mat
			pinst.position = ppos
			pinst.rotation_degrees.y = pyaw
			pinst.scale = Vector3(pscale, pscale, pscale)
			root.add_child(pinst)
		else:
			var pbox := MeshInstance3D.new()
			var pbm := BoxMesh.new()
			pbm.size = Vector3(1.5, 0.25, 1.2)
			pbox.mesh = pbm
			pbox.position = ppos
			pbox.rotation_degrees.y = pyaw
			pbox.material_override = pallet_mat
			root.add_child(pbox)

	# Low rusted scrap debris lifted by 0.725 * scale so min.y sits flush without sticking up sharply
	for dp_raw in [
		[Vector3(left_x - 4.35, 0.0, -3.85), 28.0, 0.40],
		[Vector3(10.75, 0.0, back_z + 0.48), -36.0, 0.38],
		[Vector3(left_x - 2.2, 0.28, 4.95), 72.0, 0.40],
	]:
		var dp: Array = dp_raw as Array
		var base_pos: Vector3 = dp[0] as Vector3
		var dyaw: float = float(dp[1])
		var dscale: float = float(dp[2])
		var lifted_pos := Vector3(base_pos.x, base_pos.y + 0.725 * dscale, base_pos.z)
		if debris_packed is PackedScene:
			var dinst: Node3D = (debris_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(dinst)
			var d_cube := dinst.get_node_or_null("Cube") as MeshInstance3D
			if d_cube != null:
				d_cube.material_override = rust_mat
			dinst.position = lifted_pos
			dinst.rotation_degrees = Vector3(12.0, dyaw, 8.0)
			dinst.scale = Vector3(dscale, dscale * 0.78, dscale)
			root.add_child(dinst)
		else:
			var dbox := MeshInstance3D.new()
			var dbm := BoxMesh.new()
			dbm.size = Vector3(0.85, 0.65, 0.85)
			dbox.mesh = dbm
			dbox.position = base_pos + Vector3(0.0, 0.325, 0.0)
			dbox.rotation_degrees.y = dyaw
			dbox.material_override = rust_mat
			root.add_child(dbox)


static func update_starting_line(scene_props: Dictionary, cfg) -> void:
	if scene_props.is_empty() or cfg == null:
		return
	var sl = scene_props.get("starting_line", null)
	if sl is Node3D:
		(sl as Node3D).position.x = cfg.player_spawn_x

	var lane_tracks = scene_props.get("lane_tracks", [])
	if not (lane_tracks is Array):
		return
	var left_limit: float = cfg.stage_left_lava_x + 0.8
	var right_limit: float = cfg.player_spawn_x + 0.6
	var lane_len: float = maxf(1.0, right_limit - left_limit)
	var lane_center_x: float = (left_limit + right_limit) * 0.5
	var lane_count: int = clampi(cfg.max_players, 1, 16)
	var z_half: float = 3.75 if lane_count > 8 else 3.15
	for li in range(lane_tracks.size()):
		var lane = lane_tracks[li]
		if not (lane is Node3D):
			continue
		var lane_node := lane as Node3D
		if lane_count <= 1 or li >= lane_count:
			lane_node.visible = false
			continue
		lane_node.visible = true
		var lz: float = 0.0 if lane_count == 1 else lerpf(-z_half, z_half, float(li) / float(lane_count - 1))
		lane_node.position = Vector3(lane_center_x, 0.012, lz)
		lane_node.scale = Vector3(lane_len, 1.0, 1.0)


static func _build_gear(radius: float, teeth: int, color: Color, tex_path: String = "") -> Node3D:
	var gear := Node3D.new()
	var mat := make_toon_mat(color, 0.42, 0.55, Color.BLACK, 0.0, tex_path, Vector3(0.4, 0.4, 0.4))

	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 12
	cyl.rings = 1
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.26
	disc.mesh = cyl
	disc.material_override = mat
	disc.rotation_degrees.x = 90.0
	gear.add_child(disc)

	for t in range(teeth):
		var angle: float = TAU * float(t) / float(teeth)
		var tooth := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(radius * 0.26, radius * 0.28, 0.24)
		tooth.mesh = tm
		tooth.material_override = mat
		tooth.position = Vector3(cos(angle) * (radius + 0.1), sin(angle) * (radius + 0.1), 0.0)
		tooth.rotation.z = angle
		gear.add_child(tooth)

	return gear


static func _resolve_player_color(idx: int, customization: Array = []) -> Color:
	if customization.size() >= 3:
		var suit_name := str(customization[2]).strip_edges().to_lower()
		if SUIT_COLOR_VALUES.has(suit_name):
			return SUIT_COLOR_VALUES[suit_name]
	return PLAYER_COLORS[idx % PLAYER_COLORS.size()]


static func build_cartoon_character(idx: int, nickname: String, customization: Array = [], is_local: bool = false) -> Dictionary:
	ensure_game_pck_mounted()
	var col: Color = _resolve_player_color(idx, customization)
	var root := Node3D.new()
	root.name = "Player_%d" % (idx + 1)

	# Ground drop shadow disc (stays at y=0.025 even when character jumps)
	var shadow := MeshInstance3D.new()
	shadow.name = "GroundShadow"
	var sh_m := CylinderMesh.new()
	sh_m.top_radius = 0.42
	sh_m.bottom_radius = 0.42
	sh_m.height = 0.02
	shadow.mesh = sh_m
	shadow.material_override = make_toon_mat(Color(0.03, 0.02, 0.04, 0.7), 0.9, 0.0)
	shadow.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.position = Vector3(0.0, 0.025, 0.0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shadow)

	if is_local:
		root.add_to_group(&"mpm_local_player")
		root.set_meta(&"mpm_alive", true)

	var visual := Node3D.new()
	visual.name = "VisualPivot"
	root.add_child(visual)

	var anim_player: AnimationPlayer = null
	var char_packed = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2.glb")
	if char_packed is PackedScene:
		var rig: Node3D = char_packed.instantiate()
		rig.name = "OfficialCharacterRig"
		# main character2.glb Armature faces local -Z; rotate -90 deg so character faces +X (toward incoming rollers)
		rig.rotation_degrees.y = -90.0
		# Original mesh height is ~4.84 units -> 0.31 scale aligns character height to ~1.50 units
		rig.scale = Vector3(0.31, 0.31, 0.31)
		visual.add_child(rig)
		_customize_official_rig(rig, idx, customization)
		anim_player = _setup_official_animations(rig)
	else:
		_build_fallback_character(visual, idx, col)

	# Vanilla Machine Party pure-white heavy-outlined Terminal F4 nametag (truncated at 11 chars)
	var formatted_name := nickname.left(11) + "-" if nickname.length() > 11 else nickname
	var label := Label3D.new()
	label.name = "NicknameLabel"
	label.text = formatted_name
	label.font_size = 36
	label.pixel_size = 0.0080
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	label.outline_size = 12
	var font := load_terminal_font()
	if font != null:
		label.font = font
	label.position = Vector3(0.0, 1.92, 0.0)
	root.add_child(label)

	return {
		"root": root,
		"visual": visual,
		"shadow": shadow,
		"label": label,
		"anim_player": anim_player,
	}


static func _customize_official_rig(rig: Node3D, idx: int, customization: Array = []) -> void:
	var sk := rig.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if sk == null:
		return

	var has_custom := not customization.is_empty()
	var char_mesh := sk.get_node_or_null("character mesh") as MeshInstance3D
	if char_mesh != null:
		var suit_tex = null
		var suit_tint := Color.WHITE
		if has_custom and customization.size() >= 3:
			var suit_name := str(customization[2]).strip_edges().to_lower()
			if SUIT_COLOR_VALUES.has(suit_name):
				suit_tex = load_optional("res://modules/character_customization/character_customization_textures/main character painted %s.png" % suit_name)
		if suit_tex == null:
			suit_tex = load_optional(SUIT_TEXTURE_MAP[idx % SUIT_TEXTURE_MAP.size()])
			suit_tint = SUIT_TINTS[idx % SUIT_TINTS.size()]
		if suit_tex is Texture2D:
			var suit_mat := StandardMaterial3D.new()
			suit_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			suit_mat.albedo_texture = suit_tex
			suit_mat.albedo_color = suit_tint
			suit_mat.metallic = 0.02
			suit_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			char_mesh.set_surface_override_material(0, suit_mat)

		var hands_tex = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2_main character hands boots.png")
		if hands_tex is Texture2D:
			var hands_mat := StandardMaterial3D.new()
			hands_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			hands_mat.albedo_texture = hands_tex
			hands_mat.roughness = 0.76
			hands_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			char_mesh.set_surface_override_material(1, hands_mat)

		var eye_tex = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2_main character eye open.png")
		if eye_tex is Texture2D:
			var eye_mat := StandardMaterial3D.new()
			eye_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			eye_mat.albedo_texture = eye_tex
			eye_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			char_mesh.set_surface_override_material(2, eye_mat)

	# Attach official Machine Party 3D hat to Skeleton3D bone "hat" (idx 5)
	var hat_cfg = null
	if has_custom:
		var hat_name := str(customization[0]).strip_edges().to_lower()
		if HAT_COSMETIC_BY_NAME.has(hat_name):
			hat_cfg = HAT_COSMETICS[int(HAT_COSMETIC_BY_NAME[hat_name])]
	else:
		hat_cfg = HAT_COSMETICS[idx % HAT_COSMETICS.size()]
	if hat_cfg is Dictionary:
		var hat_packed = load_optional(str(hat_cfg["path"]))
		if hat_packed is PackedScene:
			var hat_attach := BoneAttachment3D.new()
			hat_attach.name = "ModHatAttachment"
			hat_attach.bone_name = "hat"
			hat_attach.bone_idx = sk.find_bone("hat")
			sk.add_child(hat_attach)

			var hat_inst: Node3D = hat_packed.instantiate()
			hat_inst.transform = hat_cfg["tf"]
			hat_attach.add_child(hat_inst)

	# Attach official Machine Party 3D glasses where configured
	var gl_cfg = null
	if has_custom and customization.size() >= 2:
		var gl_name := str(customization[1]).strip_edges().to_lower()
		if GLASSES_COSMETIC_BY_NAME.has(gl_name):
			gl_cfg = GLASSES_COSMETICS[int(GLASSES_COSMETIC_BY_NAME[gl_name])]
	elif GLASSES_COSMETICS.has(idx):
		gl_cfg = GLASSES_COSMETICS[idx]
	if gl_cfg is Dictionary:
		var gl_packed = load_optional(str(gl_cfg["path"]))
		if gl_packed is PackedScene:
			var gl_attach := BoneAttachment3D.new()
			gl_attach.name = "ModGlassesAttachment"
			gl_attach.bone_name = "head"
			gl_attach.bone_idx = sk.find_bone("head")
			sk.add_child(gl_attach)

			var gl_inst: Node3D = gl_packed.instantiate()
			gl_inst.transform = gl_cfg["tf"]
			gl_attach.add_child(gl_inst)


static func _setup_official_animations(rig: Node3D) -> AnimationPlayer:
	var ap := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return null

	var lib := AnimationLibrary.new()
	var anim_idle = load_optional("res://animations/standing_idle_dynamic.res")
	var anim_shove = load_optional("res://minigames/disco_dodge/animations/shoved_main.res")
	var anim_fall = load_optional("res://minigames/disco_dodge/animations/falling.res")

	if anim_idle is Animation:
		var dup_idle: Animation = anim_idle.duplicate()
		dup_idle.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(&"idle", dup_idle)
	if anim_shove is Animation:
		lib.add_animation(&"shoved", anim_shove)
	if anim_fall is Animation:
		var dup_fall: Animation = anim_fall.duplicate()
		dup_fall.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(&"falling", dup_fall)

	if not lib.get_animation_list().is_empty():
		ap.add_animation_library(&"mp_mod", lib)
		if lib.has_animation(&"idle"):
			ap.play(&"mp_mod/idle")
	elif ap.has_animation(&"standing idle"):
		ap.play(&"standing idle")

	return ap


static func _build_fallback_character(visual: Node3D, idx: int, col: Color) -> void:
	var body_mat := make_toon_mat(col, 0.42, 0.12)
	var accent_mat := make_toon_mat(col.darkened(0.32), 0.45, 0.18)
	var skin_mat := make_toon_mat(Color(1.0, 0.87, 0.74), 0.52, 0.02)
	var eye_mat := make_toon_mat(Color(0.08, 0.08, 0.10), 0.2, 0.1)

	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.29
	tm.height = 0.88
	torso.mesh = tm
	torso.material_override = body_mat
	torso.position = Vector3(0.0, 0.56, 0.0)
	visual.add_child(torso)

	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.28
	hm.height = 0.56
	head.mesh = hm
	head.material_override = skin_mat
	head.position = Vector3(0.0, 1.16, 0.0)
	visual.add_child(head)

	for ez in [-0.10, 0.10]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.055
		em.height = 0.11
		eye.mesh = em
		eye.material_override = eye_mat
		eye.position = Vector3(0.23, 1.18, ez)
		visual.add_child(eye)

	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.24
	cm.bottom_radius = 0.30
	cm.height = 0.22
	cap.mesh = cm
	cap.material_override = accent_mat
	cap.position = Vector3(0.0, 1.44 + float(idx % 2) * 0.04, 0.0)
	visual.add_child(cap)


static func _first_existing_path(candidates: Array) -> String:
	for p in candidates:
		var path := str(p)
		if ResourceLoader.exists(path):
			return path
	return ""


static var _roller_asset_cache: Dictionary = {}


static func _get_roller_assets(roller_type: String, radius: float, length: float) -> Dictionary:
	var key := "%s_%d_%d" % [roller_type, int(round(radius * 1000.0)), int(round(length * 1000.0))]
	if _roller_asset_cache.has(key):
		return _roller_asset_cache[key]

	var is_gold: bool = (roller_type == "gold")
	var base_color: Color = Color(1.0, 0.72, 0.16) if is_gold else Color(0.76, 0.88, 1.0)
	var glow_color: Color = Color(1.0, 0.68, 0.10) if is_gold else Color(0.50, 0.82, 1.0)
	var trim_color: Color = Color(0.32, 0.24, 0.20) if is_gold else Color(0.24, 0.28, 0.34)

	var body_tex := _first_existing_path([TEX_METAL_PLATE] if is_gold else [TEX_SHREDDER, TEX_METAL_PLATE])
	var rust_tex := _first_existing_path([TEX_HEAVY_RUST, TEX_METAL_PLATE])

	var cyl := CylinderMesh.new()
	cyl.radial_segments = 18
	cyl.rings = 1
	cyl.top_radius = radius * 0.90
	cyl.bottom_radius = radius * 0.90
	cyl.height = length

	var am := CylinderMesh.new()
	am.radial_segments = 10
	am.rings = 1
	am.top_radius = 0.13
	am.bottom_radius = 0.13
	am.height = length + 0.75

	var fm := CylinderMesh.new()
	fm.radial_segments = 18
	fm.rings = 1
	fm.top_radius = radius + (0.045 if is_gold else 0.035)
	fm.bottom_radius = fm.top_radius
	fm.height = 0.24 if is_gold else 0.20

	var rm := CylinderMesh.new()
	rm.radial_segments = 18
	rm.rings = 1
	rm.top_radius = radius * 0.94
	rm.bottom_radius = radius * 0.94
	rm.height = 0.16

	var lm := BoxMesh.new()
	lm.size = Vector3(0.18, 0.14, 0.34) if is_gold else Vector3(0.22, 0.09, 0.28)

	var cm := BoxMesh.new()
	cm.size = Vector3(0.46, 0.46, 0.36)

	var rvm := BoxMesh.new()
	rvm.size = Vector3(0.20, 0.14, 0.40)

	var assets := {
		"trim_color": trim_color,
		"body_mat": make_toon_mat(
			Color(0.96, 0.70, 0.22) if is_gold else Color(0.84, 0.90, 0.96),
			0.36 if is_gold else 0.34,
			0.78 if is_gold else 0.82,
			Color(0.28, 0.16, 0.02) if is_gold else Color(0.10, 0.18, 0.26), 0.10,
			body_tex,
			Vector3(1.8, 1.0, 1.0),
			false,
			"",
			0.72,
			true
		),
		"flange_mat": make_toon_mat(trim_color, 0.54, 0.64, Color.BLACK, 0.0, rust_tex, Vector3(0.35, 0.35, 0.35)),
		"lug_mat": make_toon_mat(Color(0.24, 0.20, 0.18) if is_gold else Color(0.36, 0.42, 0.48), 0.45, 0.78),
		"beacon_mat": make_toon_mat(glow_color, 0.25, 0.15, glow_color, 1.05),
		"drum_mesh": cyl,
		"axle_mesh": am,
		"flange_mesh": fm,
		"ring_mesh": rm,
		"lug_mesh": lm,
		"carriage_mesh": cm,
		"rivet_mesh": rvm,
	}
	_roller_asset_cache[key] = assets
	return assets


static func build_roller_mesh(roller_type: String, radius: float, length: float = 9.0) -> Dictionary:
	ensure_game_pck_mounted()
	var assets := _get_roller_assets(roller_type, radius, length)
	var root := Node3D.new()
	var is_gold: bool = (roller_type == "gold")
	var trim_color: Color = assets["trim_color"]
	var body_mat: StandardMaterial3D = assets["body_mat"]
	var flange_mat: StandardMaterial3D = assets["flange_mat"]
	var lug_mat: StandardMaterial3D = assets["lug_mat"]
	var beacon_mat: StandardMaterial3D = assets["beacon_mat"]

	var spin_pivot := Node3D.new()
	spin_pivot.name = "SpinPivot"
	root.add_child(spin_pivot)

	# 12-sided low-poly industrial steel drum
	var drum := MeshInstance3D.new()
	drum.mesh = assets["drum_mesh"]
	drum.material_override = body_mat
	drum.rotation_degrees.x = 90.0
	spin_pivot.add_child(drum)

	# Central steel axle running out to the guide rail carriages
	var axle := MeshInstance3D.new()
	axle.mesh = assets["axle_mesh"]
	axle.material_override = flange_mat
	axle.rotation_degrees.x = 90.0
	spin_pivot.add_child(axle)

	# 5 heavy ribbed flanges / shredder collars along the drum
	var flange_count := 5
	for fi in range(flange_count):
		var fz: float = lerpf(-length * 0.36, length * 0.36, float(fi) / float(flange_count - 1))
		var flange := MeshInstance3D.new()
		flange.mesh = assets["flange_mesh"]
		flange.material_override = flange_mat
		flange.rotation_degrees.x = 90.0
		flange.position = Vector3(0.0, 0.0, fz)
		spin_pivot.add_child(flange)

	# Two hazard indicator rings near the ends
	for rz in [-3.5, 3.5]:
		var ring := MeshInstance3D.new()
		ring.mesh = assets["ring_mesh"]
		ring.material_override = beacon_mat
		ring.rotation_degrees.x = 90.0
		ring.position = Vector3(0.0, 0.0, rz)
		spin_pivot.add_child(ring)

	# Chunky angular crusher lugs (gold) or angled shredder teeth (silver) in 6 rings
	for s_idx in range(6):
		var z_pos: float = lerpf(-length * 0.40, length * 0.40, float(s_idx) / 5.0)
		for k in range(4):
			var ang: float = TAU * float(k) / 4.0 + float(s_idx) * (TAU / 8.0)
			var lug := MeshInstance3D.new()
			lug.mesh = assets["lug_mesh"]
			lug.material_override = lug_mat
			var radial_offset := radius * (0.93 if is_gold else 0.95)
			lug.position = Vector3(cos(ang) * radial_offset, sin(ang) * radial_offset, z_pos)
			lug.rotation.z = ang + (0.0 if is_gold else 0.28)
			spin_pivot.add_child(lug)

	var saw_tex := "res://minigames/dvd_roomba/models/dvd roomba visuals1_circular saw2.png" if is_gold else "res://minigames/dvd_roomba/models/dvd roomba visuals1_circular saw bloody.png"
	for ez in [-length * 0.5, length * 0.5]:
		var cap := _build_gear(radius + 0.05, 8, trim_color, saw_tex)
		cap.position = Vector3(0.0, 0.0, ez)
		spin_pivot.add_child(cap)

	# Non-rotating steel bearing carriage blocks engaging the front/back guide rails
	for cz in [-(length * 0.5 + 0.28), length * 0.5 + 0.28]:
		var carriage := MeshInstance3D.new()
		carriage.mesh = assets["carriage_mesh"]
		carriage.material_override = flange_mat
		carriage.position = Vector3(0.0, 0.0, cz)
		root.add_child(carriage)

		var rivet := MeshInstance3D.new()
		rivet.mesh = assets["rivet_mesh"]
		rivet.material_override = beacon_mat
		rivet.position = Vector3(0.0, 0.0, cz)
		root.add_child(rivet)

	return {
		"root": root,
		"spin": spin_pivot,
	}


## Original rolling drum pictogram for the official black-and-white icon grid.
static func build_roller_icon() -> ImageTexture:
	var image := Image.new()
	image.load_svg_from_string("""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
	  <rect width="256" height="256" fill="#000"/>
	  <g fill="#e5e5e5">
	    <path d="M15 150h48l-8 13H7zm14-26h48l-8 13H21zm-8 53h33l6 13H13z"/>
	    <g transform="rotate(-28 145 132)">
	      <path d="M82 78h110v108H82c-20 0-33-24-33-54s13-54 33-54z"/>
	      <path d="M85 80c-23 25-23 78 0 104m25-104c-23 25-23 78 0 104" stroke="#000" stroke-width="10" fill="none"/>
	      <ellipse cx="193" cy="132" rx="35" ry="56" stroke="#000" stroke-width="9"/>
	      <ellipse cx="193" cy="132" rx="13" ry="25" fill="#000"/>
	    </g>
	  </g>
	</svg>""")
	return ImageTexture.create_from_image(image)
