extends RefCounted

## Authentic Machine Party 3D asset loader and arena builders for Core Heist (能源搶奪戰).
## Reuses vanilla Machine Party worker rigs, cosmetics, industrial textures,
## Terminal F4 font, and animations when Machine Party.pck is available,
## with clean procedural fallbacks for headless tests.

const TEX_THREADPLATE := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate albedo.png"
const TEX_THREADPLATE_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate normal 1024.png"
const TEX_FLOOR_CONCRETE := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_chisel gauntlet floor6.png"
const TEX_BRICK_WALL := "res://minigames/burn_recycle/models/burn recycle visuals6/burn recycle visuals6_burn and recycle brick wall bake.png"
const TEX_PLASTER_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_plaster damaged normal.png"
const TEX_DARK_METAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_shotgun device metal darkened3.png"
const TEX_RUST_PAINTED := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust painted2.png"
const TEX_CONTROL_PANEL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_chisel gauntlet control panel1.png"
const TEX_METAL_PLATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_metal plate1.png"
const TEX_GRATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba grate.png"
const TEX_WALL := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba walls1.png"
const TEX_SIDING := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba siding.png"
const TEX_PIPES := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_fc pipes2.png"
const TEX_HEAVY_RUST := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust2.png"
const TEX_CONVEYOR := "res://textures/conveyor belt new1.png"
const TEX_DECAL_STAIN := "res://textures/decal stain masked1.png"
const TEX_DECAL_SCORCH := "res://textures/decals/explosion_mark.png"
const GLB_WALL_LAMP := "res://models/elevator light2/elevator light2.glb"
const GLB_FAN := "res://minigames/smoke_break/models/smoke break fan1/smoke break fan1.glb"
const GLB_LIGHT_FIXTURE := "res://minigames/exploding_collar_race/models/collar race light fixture1/collar race light fixture1.glb"
const GLB_SERVER_RACK := "res://minigames/intermission_new/models/intermission server rack temp1/intermission server rack temp1.glb"
const GLB_PALLET := "res://minigames/chisel_gauntlet_multiplayer/models/chisel game pallet1/chisel game pallet1.glb"
const GLB_DEBRIS := "res://minigames/junk_platform/models/junk platform debris1/junk platform debris1.glb"

const TEAM_SUIT_TEXTURES := {
	1: "res://modules/character_customization/character_customization_textures/main character painted red.png",
	2: "res://modules/character_customization/character_customization_textures/main character painted blue.png",
	3: "res://modules/character_customization/character_customization_textures/main character painted green.png",
	4: "res://modules/character_customization/character_customization_textures/main character painted yellow.png",
}

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

const HAT_COSMETIC_BY_NAME := {
	"tophat": 0, "traffic_cone": 1, "rubiks_cube": 2, "maska_helmet": 3,
	"beer_hat": 4, "cap_blade": 5, "drill_sgt_hat": 6, "hard_hat": 7,
}

const GLASSES_COSMETICS := {
	0: {"path": "res://models/character cosmetics/cosmetic_glasses sunglasses/cosmetic_glasses sunglasses.glb", "tf": Transform3D(Basis(Vector3(-0.000494335, -0.00512526, 0.999987), Vector3(-0.0133705, 0.999898, 0.00511819), Vector3(-0.99991, -0.0133678, -0.000562828)), Vector3(0.249448, 0.222335, 6.0644e-05))},
	5: {"path": "res://models/character cosmetics/cosmetic_reading glasses/cosmetic_reading glasses.glb", "tf": Transform3D(Basis(Vector3(0.00952975, -0.0227329, 0.999696), Vector3(-0.141247, 0.989687, 0.0238517), Vector3(-0.989929, -0.141432, 0.00622053)), Vector3(0.253487, 0.231504, -0.0139316))},
}

const GLASSES_COSMETIC_BY_NAME := {
	"sunglasses": 0, "reading_glasses": 5,
}

static var _pck_checked: bool = false
static var _pck_available: bool = false
static var _shove_anim_cache: Animation = null
static var _shove_anim_checked: bool = false

var _mesh_cache: Dictionary = {}
var _mat_cache: Dictionary = {}
var _cjk_label_font: Font = null


func _get_cjk_label_font() -> Font:
	if _cjk_label_font != null:
		return _cjk_label_font
	var base: Font = load_terminal_font()
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"PingFang TC",
		"PingFang SC",
		"Microsoft YaHei",
		"Noto Sans CJK TC",
		"Noto Sans CJK SC",
		"Heiti TC",
		"Heiti SC",
		"Sans-Serif",
	])
	if base == null:
		_cjk_label_font = sys
	else:
		var fv := FontVariation.new()
		fv.base_font = base
		fv.fallbacks = [sys]
		_cjk_label_font = fv
	return _cjk_label_font


static func ensure_game_pck_mounted() -> bool:
	if _pck_checked:
		return _pck_available
	_pck_checked = true
	if ResourceLoader.exists("res://fonts/Terminal F4.ttf"):
		_pck_available = true
		return true
	var pck_path: String = OS.get_environment("MP_PCK_PATH")
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
	return load_optional("res://fonts/Terminal F4.ttf") as Font


func _get_mat(
	key: String,
	albedo: Color,
	metallic: float = 0.25,
	roughness: float = 0.55,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0,
	alpha: bool = false,
	tex_path: String = "",
	uv_scale: Vector3 = Vector3.ONE,
	normal_path: String = "",
	triplanar: bool = false,
	normal_scale: float = 0.72,
	linear_filter: bool = false
) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	if alpha:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if not tex_path.is_empty():
		var tex = load_optional(tex_path)
		if tex is Texture2D:
			mat.albedo_texture = tex as Texture2D
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if linear_filter else BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_scale = uv_scale
	if not normal_path.is_empty():
		var ntex = load_optional(normal_path)
		if ntex is Texture2D:
			mat.normal_enabled = true
			mat.normal_texture = ntex as Texture2D
			mat.normal_scale = normal_scale
	if triplanar:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
	_mat_cache[key] = mat
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


static func _add_floor_decal(
	parent: Node3D,
	tex: Texture2D,
	pos: Vector3,
	size: Vector3,
	modulate: Color,
	rot_y: float = 0.0
) -> void:
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


func _get_box(key: String, size: Vector3) -> BoxMesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key] as BoxMesh
	var m := BoxMesh.new()
	m.size = size
	_mesh_cache[key] = m
	return m


func _get_cyl(key: String, top_r: float, bot_r: float, h: float, segs: int = 18) -> CylinderMesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key] as CylinderMesh
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = h
	m.radial_segments = segs
	_mesh_cache[key] = m
	return m


func _get_torus(key: String, inner_r: float, outer_r: float, rings: int = 24) -> TorusMesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key] as TorusMesh
	var m := TorusMesh.new()
	m.inner_radius = inner_r
	m.outer_radius = outer_r
	m.rings = rings
	m.ring_segments = 6
	_mesh_cache[key] = m
	return m


func build_arena(parent: Node3D, team_ids: Array, cfg, vault_by_team: Dictionary, pillars: Array) -> Dictionary:
	ensure_game_pck_mounted()
	var team_count: int = clampi(team_ids.size(), 2, 4)
	var arena_size: float = float(cfg.arena_size_for_teams(team_count))
	var half: float = arena_size * 0.5
	var term_font: Font = load_terminal_font()
	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D
	var scorch_tex := load_optional(TEX_DECAL_SCORCH) as Texture2D

	var floor_mat := _get_mat("floor", Color(0.60, 0.56, 0.52), 0.10, 0.86, Color.BLACK, 0.0, false, TEX_FLOOR_CONCRETE, Vector3(0.22, 0.22, 0.22), "", true, 0.72, true)
	var apron_mat := _get_mat("apron", Color(0.50, 0.46, 0.43), 0.68, 0.42, Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.50, 0.50, 0.50), TEX_THREADPLATE_NORMAL, true, 0.88, true)
	var subdeck_mat := _get_mat("subdeck", Color(0.48, 0.44, 0.41), 0.46, 0.60, Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.42, 0.42, 0.42), TEX_THREADPLATE_NORMAL, true, 0.82, true)
	var dark_metal_mat := _get_mat("dark_metal", Color(0.46, 0.42, 0.40), 0.62, 0.46, Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(1.5, 1.5, 1.0))
	var rim_mat := _get_mat("floor_rim", Color(0.32, 0.30, 0.29), 0.62, 0.46, Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(4.0, 4.0, 1.0))
	var wall_mat := _get_mat("wall_tex", Color(0.56, 0.50, 0.45), 0.42, 0.58, Color.BLACK, 0.0, false, TEX_WALL, Vector3(8.0, 1.0, 1.0))
	var back_wall_mat := _get_mat("back_wall", Color(0.82, 0.76, 0.70), 0.12, 0.86, Color.BLACK, 0.0, false, TEX_BRICK_WALL, Vector3(0.22, 0.22, 0.22), TEX_PLASTER_NORMAL, true, 0.85, true)
	var trim_mat := _get_mat("trim", Color(0.50, 0.46, 0.42), 0.62, 0.44, Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(2.0, 2.0, 1.0))
	var steel_trim_mat := _get_mat("steel_trim", Color(0.58, 0.55, 0.52), 0.88, 0.24)
	var panel_mat := _get_mat("ctrl_panel", Color(0.70, 0.65, 0.59), 0.40, 0.48, Color.BLACK, 0.0, false, TEX_CONTROL_PANEL, Vector3(1.0, 1.0, 1.0))
	var hazard_mat := _get_mat("hazard", Color(0.92, 0.64, 0.16), 0.20, 0.48, Color(0.86, 0.56, 0.12), 0.24, false, TEX_SIDING, Vector3(6.0, 1.0, 1.0))
	var pipes_mat := _get_mat("pipes", Color(0.58, 0.52, 0.46), 0.60, 0.44, Color.BLACK, 0.0, false, TEX_PIPES, Vector3(2.0, 2.0, 1.0))
	var rust_mat := _get_mat("rust", Color(0.58, 0.46, 0.38), 0.48, 0.56, Color.BLACK, 0.0, false, TEX_RUST_PAINTED, Vector3(2.0, 2.0, 1.0))
	var conv_mat_l := _get_mat("conveyor_l", Color(0.60, 0.57, 0.54), 0.26, 0.62, Color.BLACK, 0.0, false, TEX_CONVEYOR, Vector3(3.0, 1.0, 1.0))
	var conv_mat_r := _get_mat("conveyor_r", Color(0.60, 0.57, 0.54), 0.26, 0.62, Color.BLACK, 0.0, false, TEX_CONVEYOR, Vector3(3.0, 1.0, 1.0))
	var crt_body_mat := _get_mat("crt_body", Color(0.22, 0.21, 0.21), 0.52, 0.46, Color(0.02, 0.03, 0.02), 0.15, false, TEX_DARK_METAL, Vector3(1.0, 1.0, 1.0))
	var amber_beacon_mat := _get_mat("amber_beacon", Color(1.0, 0.64, 0.16), 0.2, 0.22, Color(1.0, 0.60, 0.12), 1.65)

	# Heavy dark industrial sub-deck & trim rim (grounds the arena into the factory floor with zero seams or Z-fighting)
	var deck_w: float = arena_size + 4.4
	var subdeck := MeshInstance3D.new()
	subdeck.name = "SubDeck"
	subdeck.mesh = _get_box("subdeck_" + str(int(arena_size)), Vector3(deck_w, 1.12, deck_w))
	subdeck.position = Vector3(0.0, -0.78, 0.0)
	subdeck.material_override = subdeck_mat
	parent.add_child(subdeck)

	var rim := MeshInstance3D.new()
	rim.name = "FloorRim"
	rim.mesh = _get_box("rim_" + str(int(arena_size)), Vector3(arena_size + 0.96, 0.20, arena_size + 0.96))
	rim.position = Vector3(0.0, -0.12, 0.0)
	rim.material_override = rim_mat
	parent.add_child(rim)

	# Main matte dark factory concrete floor
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = _get_box("floor_" + str(int(arena_size)), Vector3(arena_size, 0.5, arena_size))
	floor_mi.position = Vector3(0.0, -0.25, 0.0)
	floor_mi.material_override = floor_mat
	parent.add_child(floor_mi)

	# Reinforced perimeter walls (non-overlapping corner joints to prevent Z-fighting)
	var wall_specs: Array = [
		[Vector3(0.0, 0.52, -half), Vector3(arena_size + 0.62, 1.04, 0.62), Vector3(arena_size + 0.64, 0.16, 0.64)],
		[Vector3(0.0, 0.52, half), Vector3(arena_size + 0.62, 1.04, 0.62), Vector3(arena_size + 0.64, 0.16, 0.64)],
		[Vector3(-half, 0.52, 0.0), Vector3(0.62, 1.04, arena_size - 0.62), Vector3(0.64, 0.16, arena_size - 0.64)],
		[Vector3(half, 0.52, 0.0), Vector3(0.62, 1.04, arena_size - 0.62), Vector3(0.64, 0.16, arena_size - 0.64)],
	]
	for i in range(wall_specs.size()):
		var spec: Array = wall_specs[i] as Array
		var w := MeshInstance3D.new()
		var sz: Vector3 = spec[1] as Vector3
		w.mesh = _get_box("wall_%d_%d" % [int(arena_size), i], sz)
		w.position = spec[0] as Vector3
		w.material_override = wall_mat
		parent.add_child(w)

		var stripe := MeshInstance3D.new()
		var ssz: Vector3 = spec[2] as Vector3
		stripe.mesh = _get_box("wstripe_%d_%d" % [int(arena_size), i], ssz)
		stripe.position = (spec[0] as Vector3) + Vector3(0.0, 0.60, 0.0)
		stripe.material_override = hazard_mat
		parent.add_child(stripe)

	# --- Tall North Industrial Brick Back Wall + Buttress Columns + Exhaust Fans + Bay Light Fixtures + CRT ---
	var back_z: float = -half - 1.38
	var back_wall := MeshInstance3D.new()
	back_wall.name = "FactoryBackWall"
	back_wall.mesh = _get_box("back_wall_" + str(int(arena_size)), Vector3(deck_w, 9.6, 0.84))
	back_wall.material_override = back_wall_mat
	back_wall.position = Vector3(0.0, 3.4, back_z)
	parent.add_child(back_wall)

	var col_mesh := _get_box("back_col_" + str(int(arena_size)), Vector3(0.72, 9.6, 0.98))
	var col_xs: Array = [-half - 1.85, -half * 0.55, -4.3, 4.3, half * 0.55, half + 1.85]
	for cx in col_xs:
		var col_mi := MeshInstance3D.new()
		col_mi.mesh = col_mesh
		col_mi.position = Vector3(float(cx), 3.4, back_z + 0.14)
		col_mi.material_override = dark_metal_mat
		parent.add_child(col_mi)

	for py in [1.35, 7.35]:
		var pipe := MeshInstance3D.new()
		pipe.mesh = _get_cyl("back_pipe_" + str(int(arena_size)), 0.20, 0.20, deck_w - 0.8, 12)
		pipe.material_override = pipes_mat
		pipe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		pipe.position = Vector3(0.0, float(py), back_z + 0.58)
		parent.add_child(pipe)

	# Spinning industrial exhaust fans on north wall (2 for 2-team, 3 for 3-4 team)
	var fans: Array = []
	var fan_packed = load_optional(GLB_FAN)
	var fan_specs: Array = [
		Vector3(-half * 0.66, 4.35, back_z + 0.50),
		Vector3(half * 0.66, 4.35, back_z + 0.50),
	]
	if team_count >= 3:
		fan_specs.append(Vector3(0.0, 6.25, back_z + 0.50))
	var fan_shroud_mesh := _get_cyl("fan_shroud", 0.94, 1.00, 0.34, 20)
	for f_idx in range(fan_specs.size()):
		var fpos: Vector3 = fan_specs[f_idx] as Vector3
		var shroud := MeshInstance3D.new()
		shroud.name = "ExhaustFanShroud_%d" % f_idx
		shroud.mesh = fan_shroud_mesh
		shroud.rotation_degrees.x = 90.0
		shroud.position = fpos + Vector3(0.0, 0.0, -0.06)
		shroud.material_override = dark_metal_mat
		parent.add_child(shroud)

		var fan_mount := Node3D.new()
		fan_mount.name = "ExhaustFanMount_%d" % f_idx
		fan_mount.position = fpos + Vector3(0.0, 0.0, 0.08)
		fan_mount.rotation_degrees.y = 180.0
		fan_mount.scale = Vector3(0.68, 0.68, 0.68)
		parent.add_child(fan_mount)

		if fan_packed is PackedScene:
			var fan_inst: Node3D = (fan_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(fan_inst)
			fan_mount.add_child(fan_inst)
			var fan_mesh := fan_inst.get_node_or_null("fan_002") as MeshInstance3D
			if fan_mesh != null:
				fan_mesh.position = Vector3.ZERO
				fans.append(fan_mesh)
			else:
				fans.append(fan_inst)
		else:
			var hub_pivot := Node3D.new()
			hub_pivot.name = "FallbackFan_%d" % f_idx
			for b_i in range(4):
				var blade := MeshInstance3D.new()
				blade.mesh = _get_box("fallback_fan_blade", Vector3(1.60, 0.24, 0.08))
				blade.rotation_degrees.z = float(b_i) * 45.0
				blade.material_override = rust_mat
				hub_pivot.add_child(blade)
			fan_mount.add_child(hub_pivot)
			fans.append(hub_pivot)

	# Warm industrial fluorescent wall lamps flanking the CRT monitor + 1 subtle flicker lamp + warm wall wash
	var tube_mat := _get_mat("fluor_tube", Color(0.95, 0.90, 0.76), 0.1, 0.2, Color(0.96, 0.88, 0.68), 1.45)
	var flicker_lamp_mat := _get_mat("flicker_lamp", Color(1.0, 0.80, 0.44), 0.1, 0.22, Color(1.0, 0.72, 0.30), 1.75)
	var cage_lamp_mat := _get_mat("cage_lamp", Color(1.0, 0.78, 0.40), 0.1, 0.24, Color(1.0, 0.70, 0.28), 1.65)
	var fixture_mat := _get_mat("fluor_fixture", Color(0.24, 0.23, 0.22), 0.65, 0.48)
	var tube_xs: Array = [-half * 0.78, -half * 0.46, half * 0.46, half * 0.78]
	for t_idx in range(tube_xs.size()):
		var lx: float = float(tube_xs[t_idx])
		var fix := MeshInstance3D.new()
		fix.mesh = _get_box("lamp_fix", Vector3(2.1, 0.28, 0.36))
		fix.material_override = fixture_mat
		fix.position = Vector3(lx, 5.75, back_z + 0.56)
		parent.add_child(fix)

		var tube := MeshInstance3D.new()
		tube.mesh = _get_box("lamp_tube", Vector3(1.85, 0.12, 0.16))
		tube.material_override = flicker_lamp_mat if t_idx == 1 else tube_mat
		tube.position = Vector3(lx, 5.60, back_z + 0.68)
		parent.add_child(tube)

	for wx in [-half * 0.64, 0.0, half * 0.64]:
		var wall_light := OmniLight3D.new()
		wall_light.light_color = Color(1.0, 0.76, 0.44)
		wall_light.light_energy = 2.8 if is_zero_approx(float(wx)) else 4.0
		wall_light.omni_range = 22.0
		wall_light.omni_attenuation = 1.15
		wall_light.shadow_enabled = false
		wall_light.position = Vector3(float(wx), 5.0, back_z + 2.6)
		parent.add_child(wall_light)

	var lamp_packed = load_optional(GLB_WALL_LAMP)
	var wall_lamp_xs: Array = [-half * 0.44, half * 0.44]
	for l_idx in range(wall_lamp_xs.size()):
		var lx: float = float(wall_lamp_xs[l_idx])
		var target_lmat: StandardMaterial3D = flicker_lamp_mat if l_idx == 0 else cage_lamp_mat
		if lamp_packed is PackedScene:
			var lamp := (lamp_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(lamp)
			lamp.position = Vector3(lx, 2.35, back_z + 0.56)
			lamp.scale = Vector3(0.82, 0.82, 0.82)
			parent.add_child(lamp)
			for c in lamp.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).set_surface_override_material(0, target_lmat)

	# Tucked flanking bay light fixtures (13.28m tall -> scaled down 0.22-0.24, strictly within wall silhouette & outside CRT)
	var bay_fixture_packed = load_optional(GLB_LIGHT_FIXTURE)
	var bay_bulb_mat := _get_mat("bay_fix_bulb", Color(1.0, 0.84, 0.54), 0.1, 0.2, Color(1.0, 0.76, 0.38), 1.6)
	var bay_scale: float = 0.22 if team_count <= 2 else 0.24
	for b_idx in range(2):
		var bx: float = (-half * 0.84) if b_idx == 0 else (half * 0.84)
		var bpos := Vector3(bx, -0.22, back_z + 0.72)
		if bay_fixture_packed is PackedScene:
			var finst := (bay_fixture_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(finst)
			finst.name = "NorthBayFixture_%d" % b_idx
			finst.position = bpos
			finst.scale = Vector3(bay_scale, bay_scale, bay_scale)
			var cyl_mi := finst.get_node_or_null("Cylinder") as MeshInstance3D
			if cyl_mi != null:
				cyl_mi.set_surface_override_material(1, bay_bulb_mat)
			parent.add_child(finst)
		else:
			var pole_h: float = 13.28 * bay_scale
			var stem := MeshInstance3D.new()
			stem.mesh = _get_cyl("bay_stem_%d" % int(arena_size), 0.08, 0.11, pole_h, 8)
			stem.position = bpos + Vector3(0.0, pole_h * 0.5, 0.0)
			stem.material_override = dark_metal_mat
			parent.add_child(stem)
			var hood := MeshInstance3D.new()
			hood.mesh = _get_cyl("bay_hood", 0.22, 0.48, 0.32, 12)
			hood.position = bpos + Vector3(0.0, pole_h, 0.0)
			hood.material_override = rust_mat
			parent.add_child(hood)

	# Outer sub-deck industrial dressing (server racks, weathered pallets, scrap debris — zero playable intrusion)
	var rack_packed = load_optional(GLB_SERVER_RACK)
	var pallet_packed = load_optional(GLB_PALLET)
	var debris_packed = load_optional(GLB_DEBRIS)
	var pallet_mat := _get_mat("pallet_weathered", Color(0.36, 0.30, 0.25), 0.15, 0.85, Color.BLACK, 0.0, false, TEX_HEAVY_RUST, Vector3(1.0, 1.0, 1.0))

	for r_idx in range(2):
		var side_s: float = -1.0 if r_idx == 0 else 1.0
		var rpos := Vector3(side_s * (half + 1.05), -0.22, -half + 2.2)
		var ryaw: float = 18.0 * (-side_s)
		if rack_packed is PackedScene:
			var rinst := (rack_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(rinst)
			rinst.name = "OuterServerRack_%d" % r_idx
			rinst.position = rpos
			rinst.rotation_degrees.y = ryaw
			rinst.scale = Vector3(0.45, 0.45, 0.45)
			parent.add_child(rinst)
		else:
			var rbox := MeshInstance3D.new()
			rbox.mesh = _get_box("rack_fb", Vector3(0.75, 2.4, 1.05))
			rbox.position = rpos + Vector3(0.0, 1.2, 0.0)
			rbox.rotation_degrees.y = ryaw
			rbox.material_override = dark_metal_mat
			parent.add_child(rbox)

	var pallet_specs: Array = [
		[Vector3(-half - 1.00, -0.08, half * 0.24), 7.0],
		[Vector3(half + 1.00, -0.08, -half * 0.14), -9.0],
	]
	for pp_raw in pallet_specs:
		var pp: Array = pp_raw as Array
		var ppos: Vector3 = pp[0] as Vector3
		var pyaw: float = float(pp[1])
		if pallet_packed is PackedScene:
			var pinst := (pallet_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(pinst)
			var cube := pinst.get_node_or_null("Cube_019") as MeshInstance3D
			if cube != null:
				cube.position = Vector3.ZERO
				cube.rotation = Vector3.ZERO
				cube.material_override = pallet_mat
			pinst.position = ppos
			pinst.rotation_degrees.y = pyaw
			pinst.scale = Vector3(0.46, 0.46, 0.46)
			parent.add_child(pinst)
		else:
			var pbox := MeshInstance3D.new()
			pbox.mesh = _get_box("pallet_fb", Vector3(1.3, 0.22, 1.0))
			pbox.position = ppos
			pbox.rotation_degrees.y = pyaw
			pbox.material_override = pallet_mat
			parent.add_child(pbox)

	var debris_specs: Array = [
		[Vector3(-half - 1.02, -0.20, -half * 0.18), 28.0, 0.56],
		[Vector3(half + 1.02, -0.20, half * 0.34), -38.0, 0.54],
	]
	for dp_raw in debris_specs:
		var dp: Array = dp_raw as Array
		var base_dpos: Vector3 = dp[0] as Vector3
		var dyaw: float = float(dp[1])
		var dscale: float = float(dp[2])
		if debris_packed is PackedScene:
			var dinst := (debris_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(dinst)
			dinst.position = base_dpos + Vector3(0.0, 0.725 * dscale, 0.0)
			dinst.rotation_degrees.y = dyaw
			dinst.scale = Vector3(dscale, dscale, dscale)
			parent.add_child(dinst)
		else:
			var dbox := MeshInstance3D.new()
			dbox.mesh = _get_box("debris_fb", Vector3(0.8, 0.65, 0.8))
			dbox.position = base_dpos + Vector3(0.0, 0.32, 0.0)
			dbox.rotation_degrees.y = dyaw
			dbox.material_override = rust_mat
			parent.add_child(dbox)

	# Large 3D Diegetic Industrial CRT Monitor mounted on the north back wall
	var crt_root := Node3D.new()
	crt_root.name = "BackWallCRT"
	crt_root.position = Vector3(0.0, 3.25, back_z + 0.90)
	crt_root.rotation_degrees = Vector3(24.0, 0.0, 0.0)
	parent.add_child(crt_root)

	for sx in [-2.7, 2.7]:
		var strut := MeshInstance3D.new()
		strut.mesh = _get_box("crt_strut", Vector3(0.34, 0.34, 0.95))
		strut.material_override = steel_trim_mat
		strut.position = Vector3(float(sx), 0.0, -0.58)
		crt_root.add_child(strut)

	var crt_casing := MeshInstance3D.new()
	crt_casing.mesh = _get_box("back_crt_casing", Vector3(7.6, 3.55, 0.94))
	crt_casing.material_override = crt_body_mat
	crt_root.add_child(crt_casing)

	var crt_trim := MeshInstance3D.new()
	crt_trim.mesh = _get_box("back_crt_trim", Vector3(7.10, 3.10, 0.08))
	crt_trim.material_override = _get_mat("back_crt_trim_mat", Color(0.22, 0.38, 0.24), 0.2, 0.35, Color(0.26, 0.50, 0.28), 0.45)
	crt_trim.position = Vector3(0.0, 0.0, 0.45)
	crt_root.add_child(crt_trim)

	var crt_screen := MeshInstance3D.new()
	crt_screen.mesh = _get_box("back_crt_screen", Vector3(6.74, 2.78, 0.08))
	crt_screen.material_override = _get_mat("back_crt_glass", Color(0.03, 0.09, 0.04), 0.1, 0.2, Color(0.05, 0.14, 0.06), 0.72)
	crt_screen.position = Vector3(0.0, 0.0, 0.48)
	crt_root.add_child(crt_screen)

	var monitor_timer := Label3D.new()
	monitor_timer.name = "MonitorTimer"
	monitor_timer.text = "01:15"
	monitor_timer.font_size = 152
	monitor_timer.pixel_size = 0.0110
	monitor_timer.modulate = Color(0.68, 1.0, 0.68)
	monitor_timer.outline_modulate = Color(0.03, 0.16, 0.05)
	monitor_timer.outline_size = 12
	if term_font != null:
		monitor_timer.font = term_font
	monitor_timer.position = Vector3(0.0, 0.42, 0.56)
	crt_root.add_child(monitor_timer)

	var monitor_phase := Label3D.new()
	monitor_phase.name = "MonitorPhase"
	monitor_phase.text = "STANDARD LINE"
	monitor_phase.font_size = 68
	monitor_phase.pixel_size = 0.0104
	monitor_phase.modulate = Color(0.62, 0.96, 0.66)
	monitor_phase.outline_modulate = Color.BLACK
	monitor_phase.outline_size = 10
	if term_font != null:
		monitor_phase.font = term_font
	monitor_phase.position = Vector3(0.0, -0.66, 0.56)
	crt_root.add_child(monitor_phase)

	# Central Brushed-Treadplate Conveyor Apron + Ground Scorch & Oil Stain Decals
	var conv_apron := MeshInstance3D.new()
	conv_apron.name = "CenterConveyorApron"
	conv_apron.mesh = _get_box("conv_apron", Vector3(float(cfg.CONVEYOR_END_X) * 2.0 + 1.3, 0.024, float(cfg.CONVEYOR_HALF_Z) * 2.0 + 1.25))
	conv_apron.position = Vector3(0.0, 0.010, 0.0)
	conv_apron.material_override = apron_mat
	parent.add_child(conv_apron)

	_add_floor_decal(parent, scorch_tex, Vector3(0.0, 0.04, 0.0), Vector3(4.2, 0.45, 4.2), Color(0.14, 0.12, 0.10, 0.52), 0.35)
	for end_sign in [-1.0, 1.0]:
		_add_floor_decal(parent, stain_tex, Vector3(end_sign * float(cfg.CONVEYOR_END_X), 0.04, 0.0), Vector3(3.2, 0.45, 2.8), Color(0.18, 0.14, 0.12, 0.58), end_sign * 0.4)

	# Central Energy Reactor Station
	var disp_root := Node3D.new()
	disp_root.name = "EnergyReactorStation"
	parent.add_child(disp_root)

	var disp_plinth := MeshInstance3D.new()
	disp_plinth.mesh = _get_cyl("disp_plinth", 1.55, 1.72, 0.42, 8)
	disp_plinth.position = Vector3(0.0, 0.21, 0.0)
	disp_plinth.material_override = apron_mat
	disp_root.add_child(disp_plinth)

	var disp_base := MeshInstance3D.new()
	disp_base.mesh = _get_cyl("disp_base", 1.28, 1.48, 0.85, 16)
	disp_base.position = Vector3(0.0, 0.78, 0.0)
	disp_base.material_override = rust_mat
	disp_root.add_child(disp_base)

	var disp_core := MeshInstance3D.new()
	disp_core.mesh = _get_cyl("disp_core", 0.68, 0.68, 2.35, 20)
	disp_core.position = Vector3(0.0, 2.05, 0.0)
	disp_core.material_override = _get_mat("disp_glow", Color(0.20, 0.78, 0.92, 0.92), 0.1, 0.18, Color(0.18, 0.76, 0.90), 1.35, true)
	disp_root.add_child(disp_core)

	# 4 armored vertical pipe ribs around the reactor core
	for r_idx in range(4):
		var ang: float = float(r_idx) * PI * 0.5 + PI * 0.25
		var rib := MeshInstance3D.new()
		rib.mesh = _get_cyl("disp_rib", 0.15, 0.17, 2.45, 10)
		rib.position = Vector3(cos(ang) * 1.05, 2.05, sin(ang) * 1.05)
		rib.material_override = pipes_mat
		disp_root.add_child(rib)

	# Armored reactor crown + top beacon
	var disp_cap := MeshInstance3D.new()
	disp_cap.mesh = _get_cyl("disp_cap", 0.95, 1.32, 0.48, 8)
	disp_cap.position = Vector3(0.0, 3.35, 0.0)
	disp_cap.material_override = steel_trim_mat
	disp_root.add_child(disp_cap)

	var disp_beacon := MeshInstance3D.new()
	disp_beacon.mesh = _get_cyl("disp_beacon", 0.26, 0.34, 0.32, 12)
	disp_beacon.position = Vector3(0.0, 3.72, 0.0)
	disp_beacon.material_override = amber_beacon_mat
	disp_root.add_child(disp_beacon)

	# 2 counter-rotating energy containment rings
	var disp_ring := MeshInstance3D.new()
	disp_ring.mesh = _get_torus("disp_ring", 1.25, 1.44, 24)
	disp_ring.position = Vector3(0.0, 1.85, 0.0)
	disp_ring.scale = Vector3(1.0, 0.22, 1.0)
	disp_ring.material_override = _get_mat("disp_ring_mat", Color(0.28, 0.84, 0.92), 0.2, 0.3, Color(0.28, 0.84, 0.92), 1.05)
	disp_root.add_child(disp_ring)

	var disp_ring_b := MeshInstance3D.new()
	disp_ring_b.mesh = _get_torus("disp_ring_b", 1.02, 1.18, 24)
	disp_ring_b.position = Vector3(0.0, 2.55, 0.0)
	disp_ring_b.scale = Vector3(1.0, 0.22, 1.0)
	disp_ring_b.material_override = _get_mat("disp_ring_b_mat", Color(0.96, 0.70, 0.20), 0.2, 0.3, Color(0.96, 0.66, 0.16), 1.05)
	disp_root.add_child(disp_ring_b)

	# Flanking conveyor chute hoods (-X and +X)
	for dir_sign in [-1.0, 1.0]:
		var hood := MeshInstance3D.new()
		hood.mesh = _get_box("chute_hood", Vector3(0.65, 0.95, 1.75))
		hood.position = Vector3(dir_sign * 1.48, 0.65, 0.0)
		hood.material_override = panel_mat
		disp_root.add_child(hood)

	# Two short opposing conveyor belts (-X and +X) with high-specular oiled steel side rails and end rollers
	var chevron_mat := _get_mat("chevron", Color(0.94, 0.70, 0.20), 0.22, 0.35, Color(0.90, 0.64, 0.16), 0.95)
	var conv_len: float = float(cfg.CONVEYOR_END_X) - float(cfg.CONVEYOR_START_X)
	var conv_mid: float = (float(cfg.CONVEYOR_END_X) + float(cfg.CONVEYOR_START_X)) * 0.5
	var half_z: float = float(cfg.CONVEYOR_HALF_Z)
	for dir_sign in [-1.0, 1.0]:
		var belt := MeshInstance3D.new()
		belt.mesh = _get_box("belt", Vector3(conv_len, 0.12, half_z * 2.0))
		belt.position = Vector3(dir_sign * conv_mid, 0.05, 0.0)
		belt.material_override = conv_mat_l if dir_sign < 0.0 else conv_mat_r
		parent.add_child(belt)

		for side_z in [-half_z - 0.08, half_z + 0.08]:
			var rail := MeshInstance3D.new()
			rail.mesh = _get_box("belt_rail", Vector3(conv_len + 0.16, 0.20, 0.14))
			rail.position = Vector3(dir_sign * conv_mid, 0.10, side_z)
			rail.material_override = steel_trim_mat
			parent.add_child(rail)

		var roller := MeshInstance3D.new()
		roller.mesh = _get_cyl("belt_roller", 0.14, 0.14, half_z * 2.1, 12)
		roller.rotation.x = PI * 0.5
		roller.position = Vector3(dir_sign * float(cfg.CONVEYOR_END_X), 0.08, 0.0)
		roller.material_override = steel_trim_mat
		parent.add_child(roller)

		for s_idx in range(3):
			var strip := MeshInstance3D.new()
			strip.mesh = _get_box("belt_strip", Vector3(0.16, 0.03, half_z * 1.45))
			var offset_x: float = float(cfg.CONVEYOR_START_X) + 0.6 + float(s_idx) * 1.15
			strip.position = Vector3(dir_sign * offset_x, 0.12, 0.0)
			strip.material_override = chevron_mat
			parent.add_child(strip)

	# 4 Core-Heist-distinct Square Armored Capacitor / Transformer Pylons
	var pylon_fin_mat := _get_mat("pylon_fin", Color(0.28, 0.29, 0.30), 0.65, 0.44, Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(1.0, 1.0, 1.0))
	var pylon_charge_mat := _get_mat("pylon_charge", Color(0.26, 0.92, 0.84), 0.15, 0.22, Color(0.24, 0.88, 0.78), 1.55)
	for pil_idx in range(pillars.size()):
		var p2: Vector2 = pillars[pil_idx] as Vector2
		var proot := Node3D.new()
		proot.name = "CapacitorPylon_%d" % (pil_idx + 1)
		proot.position = Vector3(p2.x, 0.0, p2.y)
		parent.add_child(proot)

		_add_floor_decal(proot, stain_tex, Vector3(0.0, 0.03, 0.0), Vector3(2.8, 0.45, 2.8), Color(0.18, 0.14, 0.12, 0.58), float(pil_idx) * 0.85)

		# Stepped square armored industrial plinth (treadplate base + dark metal step)
		var pbase := MeshInstance3D.new()
		pbase.mesh = _get_box("pylon_base", Vector3(1.78, 0.26, 1.78))
		pbase.position = Vector3(0.0, 0.13, 0.0)
		pbase.material_override = apron_mat
		proot.add_child(pbase)

		var pstep := MeshInstance3D.new()
		pstep.mesh = _get_box("pylon_step", Vector3(1.52, 0.24, 1.52))
		pstep.position = Vector3(0.0, 0.38, 0.0)
		pstep.material_override = dark_metal_mat
		proot.add_child(pstep)

		# Armored square transformer chassis with control-panel detailing
		var pbody := MeshInstance3D.new()
		pbody.mesh = _get_box("pylon_body", Vector3(1.32, 1.66, 1.32))
		pbody.position = Vector3(0.0, 1.33, 0.0)
		pbody.material_override = panel_mat
		proot.add_child(pbody)

		# 4 corner structural oiled-steel armor rails
		for cx in [-0.62, 0.62]:
			for cz in [-0.62, 0.62]:
				var strut := MeshInstance3D.new()
				strut.mesh = _get_box("pylon_strut", Vector3(0.20, 1.72, 0.20))
				strut.position = Vector3(float(cx), 1.34, float(cz))
				strut.material_override = steel_trim_mat
				proot.add_child(strut)

		# Dark steel radiator cooling fins on both side flanks (-X / +X)
		for fx in [-0.72, 0.72]:
			for fy in [0.76, 1.10, 1.44, 1.78]:
				var fin := MeshInstance3D.new()
				fin.mesh = _get_box("pylon_fin", Vector3(0.18, 0.08, 0.96))
				fin.position = Vector3(float(fx), float(fy), 0.0)
				fin.material_override = pylon_fin_mat
				proot.add_child(fin)

		# Recessed glowing phosphor/cyan charge bar on camera-facing (+Z) and rear (-Z) faces
		for fz in [1.0, -1.0]:
			var recess := MeshInstance3D.new()
			recess.mesh = _get_box("pylon_recess", Vector3(0.68, 1.18, 0.10))
			recess.position = Vector3(0.0, 1.34, fz * 0.65)
			recess.material_override = crt_body_mat
			proot.add_child(recess)

			var charge := MeshInstance3D.new()
			charge.mesh = _get_box("pylon_charge_bar", Vector3(0.38, 0.92, 0.08))
			charge.position = Vector3(0.0, 1.34, fz * 0.68)
			charge.material_override = pylon_charge_mat
			proot.add_child(charge)

			for ry in [1.14, 1.54]:
				var rib := MeshInstance3D.new()
				rib.mesh = _get_box("pylon_charge_rib", Vector3(0.56, 0.07, 0.11))
				rib.position = Vector3(0.0, float(ry), fz * 0.69)
				rib.material_override = pylon_fin_mat
				proot.add_child(rib)

		# Flat riveted top cap (armored collar + top plate + 4 corner rivets + flat phosphor charge strip)
		var pcollar := MeshInstance3D.new()
		pcollar.mesh = _get_box("pylon_collar", Vector3(1.48, 0.22, 1.48))
		pcollar.position = Vector3(0.0, 2.27, 0.0)
		pcollar.material_override = steel_trim_mat
		proot.add_child(pcollar)

		var pcap := MeshInstance3D.new()
		pcap.mesh = _get_box("pylon_top_plate", Vector3(1.26, 0.14, 1.26))
		pcap.position = Vector3(0.0, 2.45, 0.0)
		pcap.material_override = rust_mat
		proot.add_child(pcap)

		for rx in [-0.46, 0.46]:
			for rz in [-0.46, 0.46]:
				var rivet := MeshInstance3D.new()
				rivet.mesh = _get_box("pylon_rivet", Vector3(0.14, 0.07, 0.14))
				rivet.position = Vector3(float(rx), 2.54, float(rz))
				rivet.material_override = pipes_mat
				proot.add_child(rivet)

		var top_bar := MeshInstance3D.new()
		top_bar.mesh = _get_box("pylon_top_charge", Vector3(0.68, 0.05, 0.20))
		top_bar.position = Vector3(0.0, 2.53, 0.0)
		top_bar.material_override = pylon_charge_mat
		proot.add_child(top_bar)

	# Team Recycling Furnace Vaults with overhead gantry & CRT scoreboard (tamed team emissives for ACES)
	var vault_nodes: Dictionary = {}
	var grate_mat := _get_mat("vault_grate", Color(0.44, 0.42, 0.40), 0.65, 0.50, Color.BLACK, 0.0, false, TEX_GRATE, Vector3(0.75, 0.75, 0.75), "", true)
	for raw_tid in team_ids:
		var tid: int = int(raw_tid)
		var bp: Vector2 = vault_by_team.get(tid, Vector2.ZERO) as Vector2
		var tcol: Color = (cfg.TEAM_COLORS.get(tid, Color.WHITE) as Color)
		var vroot := Node3D.new()
		vroot.name = "Vault_T%d" % tid
		vroot.position = Vector3(bp.x, 0.0, bp.y)
		# Keep gantry & overhead CRT scoreboard facing the overhead camera (+Z) so south corners never appear edge-on.
		parent.add_child(vroot)

		_add_floor_decal(vroot, stain_tex, Vector3(0.0, 0.03, 0.0), Vector3(float(cfg.VAULT_RADIUS) * 2.55, 0.45, float(cfg.VAULT_RADIUS) * 2.55), Color(0.18, 0.14, 0.12, 0.58), float(tid) * 0.7)

		var pad := MeshInstance3D.new()
		pad.mesh = _get_cyl("vault_pad", float(cfg.VAULT_RADIUS) + 0.08, float(cfg.VAULT_RADIUS) + 0.24, 0.18, 24)
		pad.position = Vector3(0.0, 0.09, 0.0)
		pad.material_override = dark_metal_mat
		vroot.add_child(pad)

		var grate := MeshInstance3D.new()
		grate.mesh = _get_cyl("vault_grate_m", float(cfg.VAULT_RADIUS) - 0.18, float(cfg.VAULT_RADIUS) - 0.18, 0.20, 24)
		grate.position = Vector3(0.0, 0.10, 0.0)
		grate.material_override = grate_mat
		vroot.add_child(grate)

		var inner_pad := MeshInstance3D.new()
		inner_pad.mesh = _get_cyl("vault_inner", float(cfg.VAULT_RADIUS) - 0.95, float(cfg.VAULT_RADIUS) - 0.95, 0.21, 24)
		inner_pad.position = Vector3(0.0, 0.11, 0.0)
		inner_pad.material_override = _get_mat("vault_pad_%d" % tid, tcol * 0.48, 0.2, 0.38, tcol, 0.42)
		vroot.add_child(inner_pad)

		var arch := MeshInstance3D.new()
		arch.mesh = _get_torus("vault_arch", float(cfg.VAULT_RADIUS) - 0.20, float(cfg.VAULT_RADIUS) + 0.02, 24)
		arch.position = Vector3(0.0, 0.20, 0.0)
		arch.scale = Vector3(1.0, 0.24, 1.0)
		arch.material_override = _get_mat("vault_arch_%d" % tid, tcol * 0.75, 0.2, 0.34, tcol, 0.72)
		vroot.add_child(arch)

		# Twin gantry pylons + overhead CRT scoreboard housing
		var gantry_r: float = float(cfg.VAULT_RADIUS) - 0.15
		for gx in [-gantry_r * 0.78, gantry_r * 0.78]:
			var post := MeshInstance3D.new()
			post.mesh = _get_cyl("vault_post", 0.14, 0.16, 2.35, 10)
			post.position = Vector3(gx, 1.20, 0.0)
			post.material_override = pipes_mat
			vroot.add_child(post)

		var crt_box := MeshInstance3D.new()
		crt_box.mesh = _get_box("vault_crt", Vector3(2.2, 1.15, 0.42))
		crt_box.position = Vector3(0.0, 2.65, 0.0)
		crt_box.material_override = crt_body_mat
		vroot.add_child(crt_box)

		var crt_bezel := MeshInstance3D.new()
		crt_bezel.mesh = _get_box("vault_bezel", Vector3(2.32, 1.26, 0.32))
		crt_bezel.position = Vector3(0.0, 2.65, 0.0)
		crt_bezel.material_override = _get_mat("vault_bezel_%d" % tid, tcol * 0.75, 0.2, 0.34, tcol, 0.58)
		vroot.add_child(crt_bezel)

		var lock_ring := MeshInstance3D.new()
		lock_ring.name = "LockRing"
		lock_ring.mesh = _get_torus("vault_lock", float(cfg.VAULT_RADIUS) + 0.16, float(cfg.VAULT_RADIUS) + 0.34, 24)
		lock_ring.position = Vector3(0.0, 0.72, 0.0)
		lock_ring.scale = Vector3(1.0, 0.45, 1.0)
		lock_ring.material_override = _get_mat("vault_lock_%d" % tid, Color(tcol.r, tcol.g, tcol.b, 0.75), 0.1, 0.22, tcol, 1.75, true)
		lock_ring.visible = false
		vroot.add_child(lock_ring)

		var score_lbl := Label3D.new()
		score_lbl.name = "ScoreLabel"
		score_lbl.text = "0"
		score_lbl.font_size = 78
		score_lbl.pixel_size = 0.018
		score_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		score_lbl.no_depth_test = true
		score_lbl.modulate = tcol
		score_lbl.outline_modulate = Color(0.04, 0.05, 0.08, 1.0)
		score_lbl.outline_size = 12
		if term_font != null:
			score_lbl.font = term_font
		score_lbl.position = Vector3(0.0, 2.65, 0.0)
		vroot.add_child(score_lbl)

		vault_nodes[tid] = {
			"root": vroot,
			"lock_ring": lock_ring,
			"score_label": score_lbl,
		}

	return {
		"vault_nodes": vault_nodes,
		"dispenser_ring": disp_ring,
		"dispenser_ring_b": disp_ring_b,
		"conveyor_mat_l": conv_mat_l,
		"conveyor_mat_r": conv_mat_r,
		"monitor_timer": monitor_timer,
		"monitor_phase": monitor_phase,
		"fans": fans,
		"flicker_lamp_mat": flicker_lamp_mat,
	}


func build_battery_node(cfg) -> Node3D:
	var root := Node3D.new()
	root.visible = false

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _get_cyl("bat_std", 0.24, 0.24, 0.48, 14)
	body.position = Vector3(0.0, 0.32, 0.0)
	body.material_override = _get_mat("bat_std_mat", Color(0.28, 0.88, 1.0), 0.25, 0.25, Color(0.24, 0.85, 1.0), 1.8)
	root.add_child(body)

	var cap_top := MeshInstance3D.new()
	cap_top.name = "CapTop"
	cap_top.mesh = _get_cyl("bat_cap_std", 0.27, 0.27, 0.09, 14)
	cap_top.position = Vector3(0.0, 0.56, 0.0)
	cap_top.material_override = _get_mat("bat_cap_steel", Color(0.68, 0.74, 0.82), 0.65, 0.32)
	root.add_child(cap_top)

	var cap_bot := MeshInstance3D.new()
	cap_bot.name = "CapBot"
	cap_bot.mesh = _get_cyl("bat_cap_std", 0.27, 0.27, 0.09, 14)
	cap_bot.position = Vector3(0.0, 0.08, 0.0)
	cap_bot.material_override = _get_mat("bat_cap_steel", Color(0.68, 0.74, 0.82), 0.65, 0.32)
	root.add_child(cap_bot)

	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = _get_torus("bat_eq_ring", 0.26, 0.33, 16)
	ring.position = Vector3(0.0, 0.34, 0.0)
	ring.scale = Vector3(1.0, 0.30, 1.0)
	ring.material_override = _get_mat("bat_ring_gold", Color(1.0, 0.78, 0.22), 0.5, 0.25, Color(1.0, 0.75, 0.15), 1.4)
	ring.visible = false
	root.add_child(ring)

	var lock_halo := MeshInstance3D.new()
	lock_halo.name = "LockHalo"
	lock_halo.mesh = _get_torus("bat_halo", 0.38, 0.46, 16)
	lock_halo.position = Vector3(0.0, 0.10, 0.0)
	lock_halo.scale = Vector3(1.0, 0.25, 1.0)
	lock_halo.material_override = _get_mat("bat_halo_mat", Color(0.45, 0.92, 1.0, 0.8), 0.1, 0.2, Color(0.45, 0.92, 1.0), 2.2, true)
	lock_halo.visible = false
	root.add_child(lock_halo)
	return root


func configure_battery_visual(node: Node3D, cell_type: int, locked: bool, perm_locked: bool, cfg) -> void:
	if node == null or not is_instance_valid(node):
		return
	var body := node.get_node_or_null("Body") as MeshInstance3D
	var cap_top := node.get_node_or_null("CapTop") as MeshInstance3D
	var cap_bot := node.get_node_or_null("CapBot") as MeshInstance3D
	var ring := node.get_node_or_null("Ring") as MeshInstance3D
	var halo := node.get_node_or_null("LockHalo") as MeshInstance3D

	if cell_type == cfg.CELL_CORE:
		if body != null:
			body.mesh = _get_cyl("bat_core", 0.38, 0.40, 0.74, 16)
			body.position = Vector3(0.0, 0.45, 0.0)
			body.material_override = _get_mat("bat_core_mat", Color(1.0, 0.38, 0.16), 0.25, 0.2, Color(1.0, 0.42, 0.14), 3.0)
		if cap_top != null:
			cap_top.mesh = _get_cyl("bat_cap_core", 0.44, 0.42, 0.13, 16)
			cap_top.position = Vector3(0.0, 0.84, 0.0)
			cap_top.material_override = _get_mat("bat_cap_dark", Color(0.24, 0.27, 0.34), 0.7, 0.35)
		if cap_bot != null:
			cap_bot.mesh = _get_cyl("bat_cap_core", 0.42, 0.44, 0.13, 16)
			cap_bot.position = Vector3(0.0, 0.09, 0.0)
			cap_bot.material_override = _get_mat("bat_cap_dark", Color(0.24, 0.27, 0.34), 0.7, 0.35)
		if ring != null:
			ring.mesh = _get_torus("bat_core_ring", 0.42, 0.52, 18)
			ring.position = Vector3(0.0, 0.46, 0.0)
			ring.material_override = _get_mat("bat_ring_core", Color(1.0, 0.56, 0.18), 0.3, 0.2, Color(1.0, 0.50, 0.14), 2.4)
			ring.visible = true
	elif cell_type == cfg.CELL_GOLD:
		if body != null:
			body.mesh = _get_cyl("bat_gold", 0.28, 0.28, 0.58, 14)
			body.position = Vector3(0.0, 0.36, 0.0)
			body.material_override = _get_mat("bat_gold_mat", Color(1.0, 0.84, 0.18), 0.45, 0.2, Color(1.0, 0.78, 0.12), 2.2)
		if cap_top != null:
			cap_top.mesh = _get_cyl("bat_cap_gold", 0.32, 0.32, 0.10, 14)
			cap_top.position = Vector3(0.0, 0.66, 0.0)
			cap_top.material_override = _get_mat("bat_cap_brass", Color(0.86, 0.68, 0.24), 0.7, 0.28)
		if cap_bot != null:
			cap_bot.mesh = _get_cyl("bat_cap_gold", 0.32, 0.32, 0.10, 14)
			cap_bot.position = Vector3(0.0, 0.08, 0.0)
			cap_bot.material_override = _get_mat("bat_cap_brass", Color(0.86, 0.68, 0.24), 0.7, 0.28)
		if ring != null:
			ring.mesh = _get_torus("bat_eq_ring", 0.29, 0.36, 16)
			ring.position = Vector3(0.0, 0.36, 0.0)
			ring.material_override = _get_mat("bat_ring_gold", Color(1.0, 0.78, 0.22), 0.5, 0.25, Color(1.0, 0.75, 0.15), 1.4)
			ring.visible = true
	else:
		if body != null:
			body.mesh = _get_cyl("bat_std", 0.24, 0.24, 0.48, 14)
			body.position = Vector3(0.0, 0.32, 0.0)
			body.material_override = _get_mat("bat_std_mat", Color(0.28, 0.88, 1.0), 0.25, 0.25, Color(0.24, 0.85, 1.0), 1.8)
		if cap_top != null:
			cap_top.mesh = _get_cyl("bat_cap_std", 0.27, 0.27, 0.09, 14)
			cap_top.position = Vector3(0.0, 0.56, 0.0)
			cap_top.material_override = _get_mat("bat_cap_steel", Color(0.68, 0.74, 0.82), 0.65, 0.32)
		if cap_bot != null:
			cap_bot.mesh = _get_cyl("bat_cap_std", 0.27, 0.27, 0.09, 14)
			cap_bot.position = Vector3(0.0, 0.08, 0.0)
			cap_bot.material_override = _get_mat("bat_cap_steel", Color(0.68, 0.74, 0.82), 0.65, 0.32)
		if ring != null:
			ring.visible = false
	if halo != null:
		halo.visible = locked or perm_locked


static func _customize_official_rig(rig: Node3D, net_id: int, team_id: int, customization: Array = []) -> void:
	var sk := rig.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if sk == null:
		return

	var char_mesh := sk.get_node_or_null("character mesh") as MeshInstance3D
	if char_mesh != null:
		var suit_path: String = str(TEAM_SUIT_TEXTURES.get(team_id, TEAM_SUIT_TEXTURES[1]))
		var suit_tex = load_optional(suit_path)
		if suit_tex is Texture2D:
			var suit_mat := StandardMaterial3D.new()
			suit_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			suit_mat.albedo_texture = suit_tex as Texture2D
			suit_mat.albedo_color = Color.WHITE
			suit_mat.metallic = 0.02
			suit_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			char_mesh.set_surface_override_material(0, suit_mat)

		var hands_tex = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2_main character hands boots.png")
		if hands_tex is Texture2D:
			var hands_mat := StandardMaterial3D.new()
			hands_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			hands_mat.albedo_texture = hands_tex as Texture2D
			hands_mat.roughness = 0.76
			hands_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			char_mesh.set_surface_override_material(1, hands_mat)

		var eye_tex = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2_main character eye open.png")
		if eye_tex is Texture2D:
			var eye_mat := StandardMaterial3D.new()
			eye_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			eye_mat.albedo_texture = eye_tex as Texture2D
			eye_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			char_mesh.set_surface_override_material(2, eye_mat)

	var has_custom: bool = not customization.is_empty()
	var hat_cfg = null
	if has_custom:
		var hat_name: String = str(customization[0]).strip_edges().to_lower()
		if HAT_COSMETIC_BY_NAME.has(hat_name):
			hat_cfg = HAT_COSMETICS[int(HAT_COSMETIC_BY_NAME[hat_name])]
	else:
		hat_cfg = HAT_COSMETICS[absi(net_id) % HAT_COSMETICS.size()]
	if hat_cfg is Dictionary:
		var hat_packed = load_optional(str((hat_cfg as Dictionary)["path"]))
		if hat_packed is PackedScene:
			var hat_attach := BoneAttachment3D.new()
			hat_attach.name = "ModHatAttachment"
			hat_attach.bone_name = "hat"
			hat_attach.bone_idx = sk.find_bone("hat")
			sk.add_child(hat_attach)
			var hat_inst: Node3D = (hat_packed as PackedScene).instantiate() as Node3D
			hat_inst.transform = (hat_cfg as Dictionary)["tf"] as Transform3D
			hat_attach.add_child(hat_inst)

	var gl_cfg = null
	if has_custom and customization.size() >= 2:
		var gl_name: String = str(customization[1]).strip_edges().to_lower()
		if GLASSES_COSMETIC_BY_NAME.has(gl_name):
			gl_cfg = GLASSES_COSMETICS[int(GLASSES_COSMETIC_BY_NAME[gl_name])]
	elif GLASSES_COSMETICS.has(absi(net_id) % 8):
		gl_cfg = GLASSES_COSMETICS[absi(net_id) % 8]
	if gl_cfg is Dictionary:
		var gl_packed = load_optional(str((gl_cfg as Dictionary)["path"]))
		if gl_packed is PackedScene:
			var gl_attach := BoneAttachment3D.new()
			gl_attach.name = "ModGlassesAttachment"
			gl_attach.bone_name = "head"
			gl_attach.bone_idx = sk.find_bone("head")
			sk.add_child(gl_attach)
			var gl_inst: Node3D = (gl_packed as PackedScene).instantiate() as Node3D
			gl_inst.transform = (gl_cfg as Dictionary)["tf"] as Transform3D
			gl_attach.add_child(gl_inst)


static func _load_official_shove_anim() -> Animation:
	if _shove_anim_checked:
		return _shove_anim_cache
	_shove_anim_checked = true
	var anim := Animation.new()
	anim.length = 0.34
	anim.loop_mode = Animation.LOOP_NONE
	var tracks: Array = [
		["Armature/Skeleton3D:spine", Quaternion(0.0, 0.0, 0.0, 1.0), Quaternion(0.14, 0.0, 0.0, 0.99)],
		["Armature/Skeleton3D:chest", Quaternion(0.0, 0.0, 0.0, 1.0), Quaternion(0.18, 0.0, 0.0, 0.98)],
		["Armature/Skeleton3D:shoulder.L", Quaternion(-0.45, 0.04, 0.03, 0.89), Quaternion(-0.73, 0.05, 0.04, 0.68)],
		["Armature/Skeleton3D:upper_arm.L", Quaternion(-0.25, 0.02, -0.06, 0.96), Quaternion(-0.57, 0.03, -0.10, 0.82)],
		["Armature/Skeleton3D:forearm.L", Quaternion(-0.35, 0.02, -0.10, 0.93), Quaternion(-0.08, 0.02, -0.10, 0.99)],
		["Armature/Skeleton3D:shoulder.R", Quaternion(0.45, -0.05, 0.04, 0.89), Quaternion(0.74, -0.07, 0.06, 0.66)],
		["Armature/Skeleton3D:upper_arm.R", Quaternion(0.25, -0.01, -0.05, 0.96), Quaternion(0.56, -0.01, -0.07, 0.82)],
		["Armature/Skeleton3D:forearm.R", Quaternion(0.35, 0.05, -0.10, 0.93), Quaternion(0.16, 0.06, -0.12, 0.97)],
	]
	for tr in tracks:
		var idx: int = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(idx, NodePath(str(tr[0])))
		var q_rest: Quaternion = (tr[1] as Quaternion).normalized()
		var q_push: Quaternion = (tr[2] as Quaternion).normalized()
		anim.rotation_track_insert_key(idx, 0.0, q_rest)
		anim.rotation_track_insert_key(idx, 0.09, q_push)
		anim.rotation_track_insert_key(idx, 0.21, q_push)
		anim.rotation_track_insert_key(idx, 0.34, q_rest)
	_shove_anim_cache = anim
	return _shove_anim_cache


static func _setup_official_animations(rig: Node3D) -> AnimationPlayer:
	var ap := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return null
	var lib := AnimationLibrary.new()
	var anim_idle = load_optional("res://animations/standing_idle_dynamic.res")
	var anim_shove: Animation = _load_official_shove_anim()
	var anim_shoved = load_optional("res://minigames/disco_dodge/animations/shoved_main2.res")
	if anim_shoved == null:
		anim_shoved = load_optional("res://minigames/disco_dodge/animations/shoved_main.res")

	var anim_run: Animation = null
	for raw_name in ap.get_animation_list():
		var aname: String = str(raw_name)
		if aname.to_lower() == "running" or aname.to_lower().ends_with("/running") or "run" in aname.to_lower():
			var candidate := ap.get_animation(raw_name)
			if candidate is Animation:
				anim_run = candidate
				break
	if anim_run == null:
		var fallback_run = load_optional("res://minigames/knife_at_the_office/animations/infected_running.res")
		if fallback_run is Animation:
			anim_run = fallback_run as Animation

	if anim_idle is Animation:
		var dup_idle: Animation = (anim_idle as Animation).duplicate()
		dup_idle.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(&"idle", dup_idle)
	if anim_run != null:
		var dup_run: Animation = anim_run.duplicate()
		dup_run.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(&"run", dup_run)
	if anim_shove is Animation:
		lib.add_animation(&"shove", anim_shove)
	if anim_shoved is Animation:
		lib.add_animation(&"shoved", anim_shoved as Animation)

	if not lib.get_animation_list().is_empty():
		ap.add_animation_library(&"mp_mod", lib)
		if ap.has_animation(&"mp_mod/idle"):
			ap.play(&"mp_mod/idle")
	return ap


func _build_fallback_character(rig: Node3D, team_id: int, cfg) -> void:
	var tcol: Color = (cfg.TEAM_COLORS.get(team_id, Color(0.85, 0.85, 0.9)) as Color)
	var torso := MeshInstance3D.new()
	torso.mesh = _get_cyl("p_torso", 0.30, 0.34, 0.72, 12)
	torso.position = Vector3(0.0, 0.48, 0.0)
	torso.material_override = _get_mat("p_body_%d" % team_id, tcol.lerp(Color(0.22, 0.25, 0.32), 0.45), 0.45, 0.4)
	rig.add_child(torso)

	var head := MeshInstance3D.new()
	head.mesh = _get_box("p_head", Vector3(0.42, 0.36, 0.38))
	head.position = Vector3(0.0, 1.05, 0.0)
	head.material_override = _get_mat("p_head_%d" % team_id, Color(0.86, 0.90, 0.96), 0.3, 0.35)
	rig.add_child(head)

	var visor := MeshInstance3D.new()
	visor.mesh = _get_box("p_visor", Vector3(0.32, 0.12, 0.08))
	visor.position = Vector3(0.0, 1.06, 0.20)
	visor.material_override = _get_mat("p_visor_%d" % team_id, tcol, 0.2, 0.2, tcol, 2.2)
	rig.add_child(visor)


func build_player_visual(net_id: int, nickname: String, team_id: int, customization: Array, team_helper, cfg) -> Dictionary:
	ensure_game_pck_mounted()
	var root := Node3D.new()
	root.name = "Player_%d" % net_id

	var shadow := MeshInstance3D.new()
	shadow.name = "ShadowDisc"
	shadow.mesh = _get_cyl("p_shadow", 0.46, 0.46, 0.02, 14)
	shadow.position = Vector3(0.0, 0.015, 0.0)
	shadow.material_override = _get_mat("p_shadow_mat", Color(0.0, 0.0, 0.0, 0.42), 0.0, 1.0, Color.BLACK, 0.0, true)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shadow)

	var rig := Node3D.new()
	rig.name = "Rig"
	root.add_child(rig)

	var anim_player: AnimationPlayer = null
	var char_packed = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2.glb")
	if char_packed is PackedScene:
		var official_rig: Node3D = (char_packed as PackedScene).instantiate() as Node3D
		official_rig.name = "OfficialCharacterRig"
		official_rig.rotation_degrees.y = 180.0
		official_rig.scale = Vector3(0.42, 0.42, 0.42)
		rig.add_child(official_rig)
		_customize_official_rig(official_rig, net_id, team_id, customization)
		anim_player = _setup_official_animations(official_rig)
	else:
		_build_fallback_character(rig, team_id, cfg)

	var label_font: Font = _get_cjk_label_font()
	var lbl := Label3D.new()
	lbl.name = "NameLabel"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 44
	lbl.pixel_size = 0.0094
	lbl.position = Vector3(0.0, 2.48, 0.0)
	lbl.outline_size = 11
	lbl.outline_modulate = Color(0.05, 0.06, 0.08, 1.0)
	if label_font != null:
		lbl.font = label_font
	lbl.text = nickname
	root.add_child(lbl)

	if team_helper != null and team_id > 0:
		team_helper.attach_foot_ring(root, team_id, 0.44, 0.56)
		team_helper.apply_nameplate(lbl, nickname, team_id, 12)

	return {
		"root": root,
		"rig": rig,
		"name_label": lbl,
		"anim_player": anim_player,
	}


static func build_core_heist_icon() -> Texture2D:
	var w: int = 128
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg_col := Color(0.07, 0.07, 0.08, 1.0)
	var frame_col := Color(0.32, 0.29, 0.26, 1.0)
	var hazard_col := Color(0.94, 0.66, 0.14, 1.0)
	var cap_col := Color(0.46, 0.43, 0.40, 1.0)
	var cap_hi := Color(0.64, 0.60, 0.55, 1.0)
	var core_outer := Color(0.96, 0.42, 0.12, 1.0)
	var core_inner := Color(1.0, 0.84, 0.24, 1.0)
	var casing_dark := Color(0.16, 0.16, 0.17, 1.0)
	var phosphor := Color(0.56, 0.94, 0.54, 1.0)
	img.fill(bg_col)
	for y in range(h):
		for x in range(w):
			# Outer industrial steel frame & hazard corner chevrons
			if x < 5 or x >= w - 5 or y < 5 or y >= h - 5:
				var stripe: bool = ((x + y) / 10) % 2 == 0
				if (x < 22 or x >= w - 22) and (y < 22 or y >= h - 22) and stripe:
					img.set_pixel(x, y, hazard_col)
				else:
					img.set_pixel(x, y, frame_col)
				continue

			# Top battery terminal post
			if x >= 50 and x < 78 and y >= 15 and y < 25:
				img.set_pixel(x, y, cap_hi if y < 19 else cap_col)
				continue

			# Armored battery housing body
			if x >= 34 and x < 94 and y >= 25 and y < 110:
				# Steel end-caps
				if y < 37 or y >= 98:
					img.set_pixel(x, y, cap_hi if x < 46 else cap_col)
				# Side armored rails
				elif x < 41 or x >= 87:
					img.set_pixel(x, y, casing_dark)
				else:
					# Glowing reactor core window with 3 horizontal charge cells
					var in_bar1: bool = y >= 43 and y < 57
					var in_bar2: bool = y >= 61 and y < 75
					var in_bar3: bool = y >= 79 and y < 93
					if in_bar1 or in_bar2 or in_bar3:
						var inner_x: bool = x >= 47 and x < 81
						if inner_x:
							img.set_pixel(x, y, core_inner if in_bar2 else core_outer)
						else:
							img.set_pixel(x, y, core_outer)
					else:
						img.set_pixel(x, y, casing_dark)
				continue

			# Subtle phosphor indicator LEDs flanking the reactor cell
			var dx_l: float = float(x - 20)
			var dx_r: float = float(x - 108)
			var dy_c: float = float(y - 67)
			if (dx_l * dx_l + dy_c * dy_c) < 25.0 or (dx_r * dx_r + dy_c * dy_c) < 25.0:
				img.set_pixel(x, y, phosphor)
	return ImageTexture.create_from_image(img)
