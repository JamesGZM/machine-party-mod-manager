extends RefCounted

## Authentic Machine Party 3D asset loader and arena builders for Bubble Blitz (泡泡爆破).
## Reuses vanilla Machine Party worker rigs, cosmetics, industrial textures,
## Terminal F4 font, and CRT monitor aesthetics when Machine Party.pck is available,
## with clean procedural fallbacks for headless tests.

const PLAYER_COLORS := [
	Color(0.22, 0.58, 1.00),
	Color(0.70, 0.34, 0.98),
	Color(0.22, 0.84, 0.44),
	Color(0.96, 0.28, 0.30),
	Color(0.86, 0.89, 0.93),
	Color(1.00, 0.56, 0.14),
	Color(0.14, 0.86, 0.88),
	Color(1.00, 0.84, 0.20),
	Color(1.00, 0.36, 0.72),
	Color(0.62, 0.92, 0.24),
	Color(0.95, 0.66, 0.22),
	Color(0.20, 0.92, 0.68),
	Color(0.88, 0.20, 0.48),
	Color(0.30, 0.48, 0.98),
	Color(0.76, 0.54, 1.00),
	Color(0.84, 0.72, 0.34),
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

const TEX_THREADPLATE := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate albedo.png"
const TEX_THREADPLATE_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate normal 1024.png"
const TEX_SHREDDER := "res://minigames/escalator_pit/models/escalator pit art11/escalator pit art11_shredder6.png"
const TEX_HEAVY_RUST := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust2.png"
const TEX_RUST_PAINTED := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust painted2.png"
const TEX_DARK_METAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_shotgun device metal darkened3.png"
const TEX_METAL_PLATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_metal plate1.png"
const TEX_FLOOR := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba floor5.png"
const TEX_GRATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba grate.png"
const TEX_PIPES := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_fc pipes2.png"
const TEX_WALL := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba walls1.png"
const TEX_BRICK_WALL := "res://minigames/burn_recycle/models/burn recycle visuals6/burn recycle visuals6_burn and recycle brick wall bake.png"
const TEX_PLASTER_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_plaster damaged normal.png"
const TEX_SIDING := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba siding.png"
const TEX_CRATE_WOOD := "res://minigames/smoke_break/models/smoke break near final3/smoke break near final3_crate3.png"
const TEX_CRATE_SUPPLY := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_box2.png"
const TEX_BARREL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_barrel.jpg"
const TEX_SCORCH := "res://textures/particles/scorch_01.png"
const TEX_SMOKE := "res://textures/particles/smoke/smoke_07.png"
const TEX_EXPLOSION_MARK := "res://textures/decals/explosion_mark.png"
const TEX_DECAL_STAIN := "res://textures/decal stain masked1.png"

const GLB_SYRINGE := "res://minigames/knife_at_the_office/models/kato syringe2/kato syringe2.glb"
const GLB_SHOE := "res://models/shared/shoe_gib.glb"
const GLB_SPRING := "res://models/manufacture gun prop spring1/manufacture gun prop spring1.glb"
const GLB_DETONATOR := "res://minigames/chisel_gauntlet_multiplayer/models/exploding collar radio1/exploding collar radio1.glb"
const GLB_WALL_LAMP := "res://models/elevator light2/elevator light2.glb"
const GLB_FAN := "res://minigames/smoke_break/models/smoke break fan1/smoke break fan1.glb"
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


static func make_std_mat(
	albedo: Color,
	metallic: float = 0.15,
	roughness: float = 0.55,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0,
	transparent: bool = false,
	tex_path: String = "",
	uv_scale: Vector3 = Vector3.ONE,
	normal_path: String = "",
	world_triplanar: bool = true,
	normal_scale: float = 0.72
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if not tex_path.is_empty():
		var tex = load_optional(tex_path)
		if tex is Texture2D:
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_triplanar = true
			mat.uv1_world_triplanar = world_triplanar
			mat.uv1_scale = uv_scale
	if not normal_path.is_empty():
		var norm = load_optional(normal_path)
		if norm is Texture2D:
			mat.normal_enabled = true
			mat.normal_texture = norm
			mat.normal_scale = normal_scale
			mat.uv1_triplanar = true
			mat.uv1_world_triplanar = world_triplanar
			mat.uv1_scale = uv_scale
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
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


static func _tint_glb_meshes(node: Node, tint: Color, roughness_add: float = 0.0) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			var sc: int = mi.mesh.get_surface_count()
			for si in range(sc):
				var mat: Material = mi.get_active_material(si)
				if mat is StandardMaterial3D:
					var dup: StandardMaterial3D = (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					dup.albedo_color = dup.albedo_color * tint
					dup.roughness = clampf(dup.roughness + roughness_add, 0.15, 0.98)
					mi.set_surface_override_material(si, dup)
	for child in node.get_children():
		_tint_glb_meshes(child, tint, roughness_add)


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
	decal.upper_fade = 0.30
	decal.lower_fade = 0.30
	decal.position = pos
	decal.rotation.y = rot_y
	parent.add_child(decal)


static func clear_caches() -> void:
	_bomb_asset_cache.clear()
	_blast_asset_cache.clear()


static func build_floor_and_backdrop(width: int, height: int, tile_size: float, theme_meta: Dictionary) -> Dictionary:
	ensure_game_pck_mounted()
	var root := Node3D.new()
	root.name = "ArenaFloor"

	var col_a: Color = theme_meta.get("floor_a", Color(0.58, 0.55, 0.52))
	var col_b: Color = theme_meta.get("floor_b", Color(0.47, 0.45, 0.43))

	# Matte factory concrete checkerboard so blasts, crates, bombs, pickups, and 4 players stay vividly distinct.
	var tint_a := Color(0.59, 0.56, 0.53).lerp(col_a, 0.10)
	var tint_b := Color(0.49, 0.47, 0.45).lerp(col_b, 0.10)
	var mat_a := make_std_mat(tint_a, 0.10, 0.86, Color.BLACK, 0.0, false, TEX_FLOOR, Vector3(0.28, 0.28, 0.28))
	var mat_b := make_std_mat(tint_b, 0.12, 0.86, Color.BLACK, 0.0, false, TEX_FLOOR, Vector3(0.28, 0.28, 0.28))
	var mat_frame := make_std_mat(Color(0.56, 0.52, 0.48), 0.36, 0.66, Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.42, 0.42, 0.42), TEX_THREADPLATE_NORMAL, true, 0.85)
	var mat_border := make_std_mat(Color(0.60, 0.56, 0.52), 0.66, 0.42, Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.48, 0.48, 0.48), TEX_THREADPLATE_NORMAL, true, 0.85)
	var mat_wall := make_std_mat(Color(0.72, 0.68, 0.64), 0.12, 0.86, Color.BLACK, 0.0, false, TEX_BRICK_WALL, Vector3(0.22, 0.22, 0.22), TEX_PLASTER_NORMAL, true, 0.85)
	var mat_dark_metal := make_std_mat(Color(0.56, 0.52, 0.50), 0.60, 0.46, Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(0.38, 0.38, 0.38))
	var mat_rust := make_std_mat(Color(0.58, 0.46, 0.38), 0.50, 0.54, Color.BLACK, 0.0, false, TEX_RUST_PAINTED, Vector3(0.35, 0.35, 0.35))
	var mat_pipe := make_std_mat(Color(0.58, 0.52, 0.46), 0.62, 0.40, Color.BLACK, 0.0, false, TEX_PIPES, Vector3(0.38, 0.38, 0.38))
	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D

	var total_w: float = float(width) * tile_size
	var total_h: float = float(height) * tile_size
	var back_z: float = -total_h * 0.5 - 1.35
	var wall_w: float = total_w + 8.0
	var deck_top_y: float = -0.08

	# Heavy dark iron industrial sub-deck & rim tight beneath the arena (zero distracting tiled siding).
	var deck := MeshInstance3D.new()
	deck.name = "WarehouseSubDeck"
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(wall_w, 0.8, total_h + 3.4)
	deck.mesh = deck_mesh
	deck.material_override = mat_frame
	deck.position = Vector3(0.0, deck_top_y - 0.40, 0.0)
	root.add_child(deck)

	var deck_rim := MeshInstance3D.new()
	deck_rim.name = "WarehouseSubDeckRim"
	var dr_mesh := BoxMesh.new()
	dr_mesh.size = Vector3(wall_w + 0.18, 0.12, total_h + 3.56)
	deck_rim.mesh = dr_mesh
	deck_rim.material_override = mat_dark_metal
	deck_rim.position = Vector3(0.0, deck_top_y - 0.06, 0.0)
	root.add_child(deck_rim)

	# Brushed treadplate perimeter border framing the playable grid.
	var border_t: float = 0.38
	var border_specs: Array = [
		[Vector3(0.0, 0.02, -total_h * 0.5 - border_t * 0.5), Vector3(total_w + border_t * 2.0, 0.14, border_t)],
		[Vector3(0.0, 0.02, total_h * 0.5 + border_t * 0.5), Vector3(total_w + border_t * 2.0, 0.14, border_t)],
		[Vector3(-total_w * 0.5 - border_t * 0.5, 0.02, 0.0), Vector3(border_t, 0.14, total_h)],
		[Vector3(total_w * 0.5 + border_t * 0.5, 0.02, 0.0), Vector3(border_t, 0.14, total_h)],
	]
	for bspec_raw in border_specs:
		var bspec: Array = bspec_raw as Array
		var bcurb := MeshInstance3D.new()
		var bcm := BoxMesh.new()
		bcm.size = bspec[1] as Vector3
		bcurb.mesh = bcm
		bcurb.material_override = mat_border
		bcurb.position = bspec[0] as Vector3
		root.add_child(bcurb)

	# Checkerboard matte concrete floor tiles using two MultiMeshInstance3D batches.
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(tile_size * 0.995, 0.08, tile_size * 0.995)
	var transforms_a: Array[Transform3D] = []
	var transforms_b: Array[Transform3D] = []
	var ox: float = (float(width) - 1.0) * 0.5
	var oz: float = (float(height) - 1.0) * 0.5

	for y in range(height):
		for x in range(width):
			var pos := Vector3((float(x) - ox) * tile_size, -0.04, (float(y) - oz) * tile_size)
			var t := Transform3D(Basis.IDENTITY, pos)
			if (x + y) % 2 == 0:
				transforms_a.append(t)
			else:
				transforms_b.append(t)

	for pair in [[transforms_a, mat_a, "TilesA"], [transforms_b, mat_b, "TilesB"]]:
		var arr: Array[Transform3D] = pair[0]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tile_mesh
		mm.instance_count = arr.size()
		for i in range(arr.size()):
			mm.set_instance_transform(i, arr[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = str(pair[2])
		mmi.multimesh = mm
		mmi.material_override = pair[1]
		root.add_child(mmi)

	# Grounded oil/grime Decal stains along north wall base, perimeter rim, and arena corners.
	var stain_spots: Array = [
		[Vector3(-total_w * 0.32, 0.02, -total_h * 0.5 + 0.55), Vector3(2.8, 0.45, 2.2), 0.25],
		[Vector3(total_w * 0.32, 0.02, -total_h * 0.5 + 0.55), Vector3(2.8, 0.45, 2.2), -0.40],
		[Vector3(-total_w * 0.36, 0.02, total_h * 0.5 - 0.55), Vector3(2.6, 0.45, 2.0), 0.85],
		[Vector3(total_w * 0.36, 0.02, total_h * 0.5 - 0.55), Vector3(2.6, 0.45, 2.0), -0.75],
		[Vector3(0.0, 0.02, -total_h * 0.5 - 0.65), Vector3(4.2, 0.45, 1.8), 0.05],
		[Vector3(-total_w * 0.5 - 1.0, deck_top_y + 0.04, 0.0), Vector3(2.4, 0.45, 3.6), 0.45],
		[Vector3(total_w * 0.5 + 1.0, deck_top_y + 0.04, 0.0), Vector3(2.4, 0.45, 3.6), -0.45],
	]
	for st_raw in stain_spots:
		var st: Array = st_raw as Array
		_add_floor_decal(root, stain_tex, st[0] as Vector3, st[1] as Vector3, Color(0.16, 0.13, 0.11, 0.60), float(st[2]))

	# --- Industrial Brick Warehouse North Wall + Buttress Columns + Pipes + Fans + Cage Lamps + 3D CRT Monitor ---
	var wall := MeshInstance3D.new()
	wall.name = "NorthBrickWall"
	var wm := BoxMesh.new()
	wm.size = Vector3(wall_w, 6.8, 0.7)
	wall.mesh = wm
	wall.material_override = mat_wall
	wall.position = Vector3(0.0, 2.6, back_z)
	root.add_child(wall)

	var col_mesh := BoxMesh.new()
	col_mesh.size = Vector3(0.66, 6.8, 0.90)
	var col_xs: Array = [-total_w * 0.5 - 2.6, -total_w * 0.44, -3.15, 3.15, total_w * 0.44, total_w * 0.5 + 2.6]
	for cx in col_xs:
		var col_mi := MeshInstance3D.new()
		col_mi.mesh = col_mesh
		col_mi.material_override = mat_dark_metal
		col_mi.position = Vector3(float(cx), 2.6, back_z + 0.25)
		root.add_child(col_mi)

	for py in [0.95, 3.35]:
		var pipe := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.16
		pm.bottom_radius = 0.16
		pm.height = wall_w - 0.8
		pipe.mesh = pm
		pipe.material_override = mat_pipe
		pipe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		pipe.position = Vector3(0.0, py, back_z + 0.48)
		root.add_child(pipe)

	# 2 spinning exhaust fans mounted on the north brick wall flanking the CRT.
	var fans: Array = []
	var fan_packed = load_optional(GLB_FAN)
	var fan_shroud_mesh := CylinderMesh.new()
	fan_shroud_mesh.top_radius = 0.84
	fan_shroud_mesh.bottom_radius = 0.90
	fan_shroud_mesh.height = 0.30
	fan_shroud_mesh.radial_segments = 20
	for f_idx in range(2):
		var fx: float = -6.0 if f_idx == 0 else 6.0
		var fpos := Vector3(fx, 2.15, back_z + 0.46)
		var shroud := MeshInstance3D.new()
		shroud.name = "ExhaustFanShroud_%d" % f_idx
		shroud.mesh = fan_shroud_mesh
		shroud.rotation_degrees.x = 90.0
		shroud.position = fpos + Vector3(0.0, 0.0, -0.06)
		shroud.material_override = mat_dark_metal
		root.add_child(shroud)

		var fan_mount := Node3D.new()
		fan_mount.name = "ExhaustFanMount_%d" % f_idx
		fan_mount.position = fpos + Vector3(0.0, 0.0, 0.10)
		fan_mount.rotation_degrees.y = 180.0
		fan_mount.scale = Vector3(0.62, 0.62, 0.62)
		root.add_child(fan_mount)

		if fan_packed is PackedScene:
			var fan_inst: Node3D = (fan_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(fan_inst)
			var fan_mesh := fan_inst.get_node_or_null("fan_002") as MeshInstance3D
			if fan_mesh != null:
				fan_mesh.position = Vector3.ZERO
				fans.append(fan_mesh)
			else:
				fans.append(fan_inst)
			fan_mount.add_child(fan_inst)
		else:
			var hub_pivot := Node3D.new()
			hub_pivot.name = "FallbackFan_%d" % f_idx
			for b_i in range(4):
				var blade := MeshInstance3D.new()
				var bmesh := BoxMesh.new()
				bmesh.size = Vector3(1.50, 0.22, 0.08)
				blade.mesh = bmesh
				blade.rotation_degrees.z = float(b_i) * 45.0
				blade.material_override = mat_rust
				hub_pivot.add_child(blade)
			fan_mount.add_child(hub_pivot)
			fans.append(hub_pivot)

	# Warm industrial cage lamps mounted on north wall (index 1 uses subtle flicker material).
	var lamp_packed = load_optional(GLB_WALL_LAMP)
	var fixture_mat := make_std_mat(Color(0.24, 0.22, 0.21), 0.7, 0.45)
	var lamp_mat := make_std_mat(Color(1.0, 0.76, 0.36), 0.1, 0.25, Color(1.0, 0.68, 0.24), 1.85)
	var flicker_lamp_mat := make_std_mat(Color(1.0, 0.76, 0.36), 0.1, 0.25, Color(1.0, 0.68, 0.24), 1.85)
	var lamp_xs: Array = [-8.2, -3.9, 3.9, 8.2]
	for l_idx in range(lamp_xs.size()):
		var lx: float = float(lamp_xs[l_idx])
		var target_lamp_mat: StandardMaterial3D = flicker_lamp_mat if l_idx == 1 else lamp_mat
		if lamp_packed is PackedScene:
			var linst: Node3D = (lamp_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(linst)
			linst.position = Vector3(lx, 2.85, back_z + 0.52)
			linst.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			linst.scale = Vector3(0.68, 0.68, 0.68)
			root.add_child(linst)
			for c in linst.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).set_surface_override_material(0, target_lamp_mat)
		else:
			var fix := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(1.15, 0.26, 0.30)
			fix.mesh = fm
			fix.material_override = fixture_mat
			fix.position = Vector3(lx, 2.85, back_z + 0.44)
			root.add_child(fix)

			var tube := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(0.92, 0.14, 0.14)
			tube.mesh = tm
			tube.material_override = target_lamp_mat
			tube.position = Vector3(lx, 2.82, back_z + 0.56)
			root.add_child(tube)

	# Outer sub-deck industrial dressing (racks tucked against north wall, weathered pallets, dark-tinted scrap debris).
	var rack_packed = load_optional(GLB_SERVER_RACK)
	var pallet_packed = load_optional(GLB_PALLET)
	var debris_packed = load_optional(GLB_DEBRIS)
	var pallet_mat := make_std_mat(Color(0.48, 0.38, 0.28), 0.14, 0.84, Color.BLACK, 0.0, false, TEX_CRATE_WOOD, Vector3(0.9, 0.9, 0.9))

	var flank_x: float = total_w * 0.5 + 1.15
	var rack_placements: Array = [
		[Vector3(-total_w * 0.5 - 0.95, deck_top_y, back_z + 0.92), 14.0],
		[Vector3(total_w * 0.5 + 0.95, deck_top_y, back_z + 0.92), -14.0],
	]
	for rp_raw in rack_placements:
		var rp: Array = rp_raw as Array
		var rpos: Vector3 = rp[0] as Vector3
		var ryaw: float = float(rp[1])
		if rack_packed is PackedScene:
			var rinst: Node3D = (rack_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(rinst)
			_tint_glb_meshes(rinst, Color(0.50, 0.47, 0.45), 0.12)
			rinst.position = rpos
			rinst.rotation_degrees.y = ryaw
			rinst.scale = Vector3(0.42, 0.42, 0.42)
			root.add_child(rinst)
		else:
			var rbox := MeshInstance3D.new()
			var rbm := BoxMesh.new()
			rbm.size = Vector3(0.75, 2.25, 1.0)
			rbox.mesh = rbm
			rbox.position = rpos + Vector3(0.0, 1.12, 0.0)
			rbox.rotation_degrees.y = ryaw
			rbox.material_override = mat_dark_metal
			root.add_child(rbox)

	var pallet_placements: Array = [
		[Vector3(-flank_x, deck_top_y + 0.14, -total_h * 0.14), 8.0],
		[Vector3(flank_x, deck_top_y + 0.14, total_h * 0.12), -10.0],
	]
	for pp_raw in pallet_placements:
		var pp: Array = pp_raw as Array
		var ppos: Vector3 = pp[0] as Vector3
		var pyaw: float = float(pp[1])
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
			pinst.scale = Vector3(0.54, 0.54, 0.54)
			root.add_child(pinst)
		else:
			var pbox := MeshInstance3D.new()
			var pbm := BoxMesh.new()
			pbm.size = Vector3(1.5, 0.24, 1.2)
			pbox.mesh = pbm
			pbox.position = ppos
			pbox.rotation_degrees.y = pyaw
			pbox.material_override = pallet_mat
			root.add_child(pbox)

	var debris_placements: Array = [
		[Vector3(-flank_x - 0.15, deck_top_y + 0.725 * 0.54, total_h * 0.20), 26.0, 0.54],
		[Vector3(flank_x + 0.15, deck_top_y + 0.725 * 0.54, -total_h * 0.22), -34.0, 0.54],
		[Vector3(-flank_x - 0.10, deck_top_y + 0.725 * 0.50, -total_h * 0.36), 112.0, 0.50],
	]
	for dp_raw in debris_placements:
		var dp: Array = dp_raw as Array
		var dpos: Vector3 = dp[0] as Vector3
		var dyaw: float = float(dp[1])
		var dscale: float = float(dp[2])
		if debris_packed is PackedScene:
			var dinst: Node3D = (debris_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(dinst)
			_tint_glb_meshes(dinst, Color(0.50, 0.45, 0.41), 0.14)
			dinst.position = dpos
			dinst.rotation_degrees.y = dyaw
			dinst.scale = Vector3(dscale, dscale, dscale)
			root.add_child(dinst)
		else:
			var dbox := MeshInstance3D.new()
			var dbm := BoxMesh.new()
			dbm.size = Vector3(0.80, 0.80, 0.80)
			dbox.mesh = dbm
			dbox.position = Vector3(dpos.x, deck_top_y + 0.40, dpos.z)
			dbox.rotation_degrees.y = dyaw
			dbox.material_override = mat_rust
			root.add_child(dbox)

	# Warm north wall & outer corner wash lights so brick wall, pipes, CRT, fans, and corner racks read clearly.
	for g_spec_raw in [
		["NorthWallGlowLeft", Vector3(-8.8, 3.4, back_z + 2.8), 4.2, 18.0],
		["NorthWallGlowRight", Vector3(8.8, 3.4, back_z + 2.8), 4.2, 18.0],
		["NorthWallGlowCenter", Vector3(0.0, 3.5, back_z + 2.8), 2.8, 14.0],
	]:
		var g_spec: Array = g_spec_raw as Array
		var wall_omni := OmniLight3D.new()
		wall_omni.name = str(g_spec[0])
		wall_omni.light_color = Color(1.0, 0.68, 0.34)
		wall_omni.light_energy = float(g_spec[2])
		wall_omni.omni_range = float(g_spec[3])
		wall_omni.shadow_enabled = false
		wall_omni.position = g_spec[1] as Vector3
		root.add_child(wall_omni)

	# 3D CRT Countdown & Theme Monitor mounted on back wall (authentic Machine Party style).
	var crt_root := Node3D.new()
	crt_root.name = "BackWallCRT"
	crt_root.position = Vector3(0.0, 2.08, back_z + 0.68)
	crt_root.rotation_degrees = Vector3(22.0, 0.0, 0.0)
	root.add_child(crt_root)

	var casing := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(4.6, 2.1, 0.65)
	casing.mesh = cm
	casing.material_override = make_std_mat(Color(0.46, 0.40, 0.36), 0.54, 0.52, Color.BLACK, 0.0, false, TEX_RUST_PAINTED, Vector3(0.45, 0.45, 0.45))
	crt_root.add_child(casing)

	var bezel := MeshInstance3D.new()
	var bzm := BoxMesh.new()
	bzm.size = Vector3(4.32, 1.82, 0.12)
	bezel.mesh = bzm
	bezel.material_override = make_std_mat(Color(0.16, 0.15, 0.15), 0.45, 0.58)
	bezel.position = Vector3(0.0, 0.0, 0.29)
	crt_root.add_child(bezel)

	var screen := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(4.12, 1.62, 0.06)
	screen.mesh = sm
	screen.material_override = make_std_mat(Color(0.02, 0.05, 0.03), 0.1, 0.2, Color(0.04, 0.12, 0.05), 0.55)
	screen.position = Vector3(0.0, 0.0, 0.35)
	crt_root.add_child(screen)

	var term_font: Font = load_terminal_font()
	var monitor_timer := Label3D.new()
	monitor_timer.name = "MonitorTimer"
	monitor_timer.text = "01:15"
	monitor_timer.font_size = 136
	monitor_timer.pixel_size = 0.0072
	monitor_timer.modulate = Color(0.68, 1.0, 0.68)
	monitor_timer.outline_modulate = Color(0.04, 0.18, 0.06)
	monitor_timer.outline_size = 10
	if term_font != null:
		monitor_timer.font = term_font
	monitor_timer.position = Vector3(0.0, 0.22, 0.41)
	crt_root.add_child(monitor_timer)

	var monitor_theme := Label3D.new()
	monitor_theme.name = "MonitorTheme"
	monitor_theme.text = "BUBBLE BLITZ"
	monitor_theme.font_size = 54
	monitor_theme.pixel_size = 0.0074
	monitor_theme.modulate = Color(0.68, 0.98, 0.72)
	monitor_theme.outline_modulate = Color.BLACK
	monitor_theme.outline_size = 9
	if term_font != null:
		monitor_theme.font = term_font
	monitor_theme.position = Vector3(0.0, -0.43, 0.41)
	crt_root.add_child(monitor_theme)

	return {
		"root": root,
		"monitor_timer": monitor_timer,
		"monitor_theme": monitor_theme,
		"fans": fans,
		"flicker_lamp_mat": flicker_lamp_mat,
	}


static func build_steel_pillar(tile_size: float, accent: Color) -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tile_size * 0.94, tile_size * 0.88, tile_size * 0.94)
	body.mesh = bm
	body.material_override = make_std_mat(
		Color(0.64, 0.60, 0.58),
		0.58,
		0.44,
		Color.BLACK,
		0.0,
		false,
		TEX_DARK_METAL,
		Vector3(0.65, 0.65, 0.65)
	)
	body.position = Vector3(0.0, tile_size * 0.44, 0.0)
	n.add_child(body)

	var cap := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(tile_size * 0.76, tile_size * 0.14, tile_size * 0.76)
	cap.mesh = cm
	cap.material_override = make_std_mat(
		Color(0.70, 0.68, 0.65),
		0.86,
		0.26,
		accent * 0.14,
		0.18,
		false,
		TEX_THREADPLATE,
		Vector3(0.7, 0.7, 0.7),
		TEX_THREADPLATE_NORMAL,
		true,
		0.82
	)
	cap.position = Vector3(0.0, tile_size * 0.91, 0.0)
	n.add_child(cap)

	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D
	_add_floor_decal(n, stain_tex, Vector3(0.0, 0.02, 0.0), Vector3(tile_size * 1.35, 0.35, tile_size * 1.35), Color(0.16, 0.13, 0.11, 0.50), 0.35)
	return n


static func build_crate(tile_size: float, is_gold: bool, base_color: Color) -> Node3D:
	var n := Node3D.new()
	var main_col: Color = Color(1.0, 0.84, 0.34) if is_gold else base_color.lerp(Color(0.92, 0.86, 0.78), 0.65)
	var em_col: Color = Color(0.95, 0.68, 0.12) if is_gold else Color.BLACK
	var em_e: float = 0.32 if is_gold else 0.0
	var tex_path: String = TEX_CRATE_SUPPLY if is_gold else TEX_CRATE_WOOD

	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tile_size * 0.88, tile_size * 0.80, tile_size * 0.88)
	body.mesh = bm
	body.material_override = make_std_mat(
		main_col,
		0.45 if is_gold else 0.14,
		0.42 if is_gold else 0.78,
		em_col,
		em_e,
		false,
		tex_path,
		Vector3(0.82, 0.82, 0.82)
	)
	body.position = Vector3(0.0, tile_size * 0.40, 0.0)
	n.add_child(body)

	var brace_mat := make_std_mat(
		Color(0.60, 0.44, 0.14) if is_gold else Color(0.28, 0.24, 0.20),
		0.62,
		0.48,
		Color.BLACK,
		0.0,
		false,
		TEX_METAL_PLATE,
		Vector3(0.9, 0.9, 0.9)
	)
	var b1 := MeshInstance3D.new()
	var bm1 := BoxMesh.new()
	bm1.size = Vector3(tile_size * 0.90, tile_size * 0.09, tile_size * 0.16)
	b1.mesh = bm1
	b1.material_override = brace_mat
	b1.position = Vector3(0.0, tile_size * 0.80, 0.0)
	n.add_child(b1)

	var b2 := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(tile_size * 0.16, tile_size * 0.09, tile_size * 0.90)
	b2.mesh = bm2
	b2.material_override = brace_mat
	b2.position = Vector3(0.0, tile_size * 0.80, 0.0)
	n.add_child(b2)
	return n


static func build_conveyor_tile(tile_size: float, dir: Vector2i, _accent: Color) -> Node3D:
	var n := Node3D.new()
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tile_size * 0.94, 0.06, tile_size * 0.94)
	belt.mesh = bm
	belt.material_override = make_std_mat(
		Color(0.32, 0.33, 0.35),
		0.52,
		0.62,
		Color.BLACK,
		0.0,
		false,
		TEX_SHREDDER,
		Vector3(0.8, 0.8, 0.8)
	)
	belt.position = Vector3(0.0, 0.03, 0.0)
	n.add_child(belt)

	# High-specular steel conveyor rollers at entry/exit lips.
	var roller_mesh := CylinderMesh.new()
	roller_mesh.top_radius = 0.028
	roller_mesh.bottom_radius = 0.028
	roller_mesh.height = tile_size * 0.88
	roller_mesh.radial_segments = 10
	var roller_mat := make_std_mat(Color(0.46, 0.45, 0.44), 0.88, 0.24)
	for rz in [-tile_size * 0.43, tile_size * 0.43]:
		var roller := MeshInstance3D.new()
		roller.mesh = roller_mesh
		roller.material_override = roller_mat
		roller.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		roller.position = Vector3(0.0, 0.032, rz)
		n.add_child(roller)

	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D
	_add_floor_decal(n, stain_tex, Vector3(0.0, 0.02, 0.0), Vector3(tile_size * 1.15, 0.30, tile_size * 1.15), Color(0.16, 0.13, 0.11, 0.38), 0.0)

	# Industrial stencil hazard chevron painted on conveyor belt (low-saturation ochre, no neon).
	var arrow := MeshInstance3D.new()
	var am := PrismMesh.new()
	am.size = Vector3(tile_size * 0.38, tile_size * 0.40, 0.03)
	arrow.mesh = am
	var arrow_col := Color(0.82, 0.60, 0.18)
	arrow.material_override = make_std_mat(arrow_col, 0.15, 0.62, arrow_col, 0.16)
	arrow.position = Vector3(0.0, 0.072, 0.0)
	arrow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var yaw: float = 0.0
	if dir == Vector2i(1, 0):
		yaw = -90.0
	elif dir == Vector2i(-1, 0):
		yaw = 90.0
	elif dir == Vector2i(0, 1):
		yaw = 180.0
	elif dir == Vector2i(0, -1):
		yaw = 0.0
	n.rotation_degrees = Vector3(0.0, yaw, 0.0)
	n.add_child(arrow)
	return n


static func build_crusher_block(tile_size: float) -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tile_size * 0.95, tile_size * 1.12, tile_size * 0.95)
	body.mesh = bm
	body.material_override = make_std_mat(
		Color(0.50, 0.46, 0.44),
		0.68,
		0.40,
		Color.BLACK,
		0.0,
		false,
		TEX_THREADPLATE,
		Vector3(0.7, 0.7, 0.7),
		TEX_THREADPLATE_NORMAL,
		true,
		0.88
	)
	body.position = Vector3(0.0, tile_size * 0.56, 0.0)
	n.add_child(body)

	var stripe := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(tile_size * 0.98, tile_size * 0.22, tile_size * 0.98)
	stripe.mesh = sm
	stripe.material_override = make_std_mat(Color(0.96, 0.70, 0.10), 0.3, 0.45, Color(0.96, 0.50, 0.06), 0.55)
	stripe.position = Vector3(0.0, tile_size * 0.96, 0.0)
	n.add_child(stripe)
	return n


static func _collect_aabb(node: Node, parent_xform: Transform3D) -> AABB:
	var combined := AABB()
	var has_box := false
	var cur_xform: Transform3D = parent_xform
	if node is Node3D:
		cur_xform = parent_xform * (node as Node3D).transform
	if node is VisualInstance3D:
		var local_box: AABB = (node as VisualInstance3D).get_aabb()
		if local_box.size.length_squared() > 0.00001:
			var world_box: AABB = cur_xform * local_box
			combined = world_box if not has_box else combined.merge(world_box)
			has_box = true
	for child in node.get_children():
		var sub: AABB = _collect_aabb(child, cur_xform)
		if sub.size.length_squared() > 0.00001:
			combined = sub if not has_box else combined.merge(sub)
			has_box = true
	return combined


static func _attach_normalized_glb(parent: Node3D, glb_path: String, target_extent: float, base_y: float, tilt_deg: Vector3 = Vector3.ZERO) -> bool:
	var packed = load_optional(glb_path)
	if not (packed is PackedScene):
		return false
	var inst = (packed as PackedScene).instantiate()
	if not (inst is Node3D):
		if inst != null:
			inst.free()
		return false
	var holder := Node3D.new()
	holder.position = Vector3(0.0, base_y, 0.0)
	holder.rotation_degrees = tilt_deg
	var model: Node3D = inst
	var box: AABB = _collect_aabb(model, Transform3D.IDENTITY)
	var max_dim: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	if max_dim > 0.001:
		var s: float = target_extent / max_dim
		model.scale = Vector3.ONE * s
		var center: Vector3 = box.position + box.size * 0.5
		model.position = -center * s
	holder.add_child(model)
	parent.add_child(holder)
	return true


static var _bomb_asset_cache: Dictionary = {}
static var _blast_asset_cache: Dictionary = {}


static func _get_bomb_assets(tile_size: float) -> Dictionary:
	var key := snappedi(int(round(tile_size * 1000.0)), 1)
	if _bomb_asset_cache.has(key):
		return _bomb_asset_cache[key]
	var bm := CylinderMesh.new()
	bm.top_radius = tile_size * 0.34
	bm.bottom_radius = tile_size * 0.38
	bm.height = tile_size * 0.14

	var cm := CylinderMesh.new()
	cm.top_radius = tile_size * 0.29
	cm.bottom_radius = tile_size * 0.31
	cm.height = tile_size * 0.52

	var bnd_m := CylinderMesh.new()
	bnd_m.top_radius = tile_size * 0.315
	bnd_m.bottom_radius = tile_size * 0.315
	bnd_m.height = tile_size * 0.10

	var cap_m := CylinderMesh.new()
	cap_m.top_radius = tile_size * 0.18
	cap_m.bottom_radius = tile_size * 0.24
	cap_m.height = tile_size * 0.12

	var sm := SphereMesh.new()
	sm.radius = tile_size * 0.10
	sm.height = tile_size * 0.20

	var canister_mat := make_std_mat(Color(0.68, 0.22, 0.16), 0.48, 0.54, Color(0.92, 0.22, 0.06), 0.0, false, TEX_BARREL, Vector3(0.9, 0.9, 0.9))
	canister_mat.emission_enabled = true
	canister_mat.emission = Color(0.92, 0.22, 0.06)
	canister_mat.emission_energy_multiplier = 0.0

	var assets := {
		"base_mesh": bm,
		"base_mat": make_std_mat(Color(0.24, 0.24, 0.26), 0.82, 0.42, Color.BLACK, 0.0, false, TEX_METAL_PLATE, Vector3(1.2, 1.2, 1.2)),
		"canister_mesh": cm,
		"canister_mat": canister_mat,
		"band_mesh": bnd_m,
		"band_mat": make_std_mat(Color(0.66, 0.46, 0.14), 0.55, 0.46, Color(0.45, 0.26, 0.05), 0.25, false, TEX_METAL_PLATE),
		"cap_mesh": cap_m,
		"cap_mat": make_std_mat(Color(0.22, 0.22, 0.24), 0.85, 0.36, Color.BLACK, 0.0, false, TEX_THREADPLATE),
		"beacon_mesh": sm,
		"beacon_mat": make_std_mat(Color(0.95, 0.20, 0.10), 0.1, 0.2, Color(1.0, 0.18, 0.08), 2.2),
	}
	_bomb_asset_cache[key] = assets
	return assets


static func _get_blast_assets(tile_size: float, is_center: bool) -> Dictionary:
	var key := "%d_%d" % [int(round(tile_size * 1000.0)), 1 if is_center else 0]
	if _blast_asset_cache.has(key):
		return _blast_asset_cache[key]

	var qm := QuadMesh.new()
	qm.size = Vector2(tile_size * (1.28 if is_center else 1.06), tile_size * (1.28 if is_center else 1.06))
	var scorch_mat := StandardMaterial3D.new()
	scorch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scorch_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	scorch_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scorch_mat.albedo_color = Color(1.0, 0.44, 0.12, 0.85 if is_center else 0.70)
	var scorch_tex = load_optional(TEX_SCORCH)
	if scorch_tex is Texture2D:
		scorch_mat.albedo_texture = scorch_tex

	var pm := QuadMesh.new()
	pm.size = Vector2(tile_size * (1.20 if is_center else 0.92), tile_size * (1.20 if is_center else 0.92))
	var puff_mat := StandardMaterial3D.new()
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	puff_mat.albedo_color = Color(1.0, 0.56, 0.22, 0.72 if is_center else 0.58)
	var smoke_tex = load_optional(TEX_SMOKE)
	if smoke_tex is Texture2D:
		puff_mat.albedo_texture = smoke_tex

	var assets := {
		"scorch_mesh": qm,
		"scorch_mat": scorch_mat,
		"puff_mesh": pm,
		"puff_mat": puff_mat,
	}
	_blast_asset_cache[key] = assets
	return assets


static func build_water_bubble(tile_size: float, _owner_color: Color) -> Node3D:
	## Authentic Machine Party industrial explosive canister (dark iron + hazard rust barrel + red detonator LED).
	var assets := _get_bomb_assets(tile_size)
	var n := Node3D.new()

	var base := MeshInstance3D.new()
	base.mesh = assets["base_mesh"]
	base.material_override = assets["base_mat"]
	base.position = Vector3(0.0, tile_size * 0.07, 0.0)
	n.add_child(base)

	var canister := MeshInstance3D.new()
	canister.name = "CanisterBody"
	canister.mesh = assets["canister_mesh"]
	# Duplicate per-bomb material so individual fuse glow pulses independently without sharing state.
	canister.material_override = (assets["canister_mat"] as StandardMaterial3D).duplicate()
	canister.position = Vector3(0.0, tile_size * 0.38, 0.0)
	n.add_child(canister)

	# Hazard dark-amber steel clamp band (unified industrial palette, no bright neon).
	var band := MeshInstance3D.new()
	band.mesh = assets["band_mesh"]
	band.material_override = assets["band_mat"]
	band.position = Vector3(0.0, tile_size * 0.38, 0.0)
	n.add_child(band)

	var cap := MeshInstance3D.new()
	cap.mesh = assets["cap_mesh"]
	cap.material_override = assets["cap_mat"]
	cap.position = Vector3(0.0, tile_size * 0.68, 0.0)
	n.add_child(cap)

	var beacon := MeshInstance3D.new()
	beacon.name = "FuseBeacon"
	beacon.mesh = assets["beacon_mesh"]
	beacon.material_override = (assets["beacon_mat"] as StandardMaterial3D).duplicate()
	beacon.position = Vector3(0.0, tile_size * 0.79, 0.0)
	n.add_child(beacon)
	return n


static func build_blast_cell(tile_size: float, is_center: bool, with_flash: bool = true) -> Node3D:
	## Gritty vanilla scorch + fiery smoke cloud indicator (replaces blocky orange cubes).
	var assets := _get_blast_assets(tile_size, is_center)
	var n := Node3D.new()

	# Ground scorch / ember ring using vanilla scorch_01.png.
	var ground_quad := MeshInstance3D.new()
	ground_quad.mesh = assets["scorch_mesh"]
	ground_quad.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	ground_quad.position = Vector3(0.0, 0.06, 0.0)
	ground_quad.material_override = assets["scorch_mat"]
	n.add_child(ground_quad)

	# Billboard smoke/fire puff using vanilla smoke_07.png (no solid cubes or spheres).
	var puff := MeshInstance3D.new()
	puff.mesh = assets["puff_mesh"]
	puff.position = Vector3(0.0, tile_size * (0.46 if is_center else 0.34), 0.0)
	puff.material_override = assets["puff_mat"]
	n.add_child(puff)

	if is_center and with_flash:
		var flash := OmniLight3D.new()
		flash.light_color = Color(1.0, 0.55, 0.20)
		flash.light_energy = 4.5
		flash.omni_range = tile_size * 3.2
		flash.position = Vector3(0.0, 0.65, 0.0)
		n.add_child(flash)

	return n


static func _pickup_short_label(item_type: int) -> String:
	var loc: String = TranslationServer.get_locale().to_upper()
	var is_zhs: bool = loc.begins_with("ZHS")
	var is_zh: bool = loc.begins_with("ZH")
	if item_type == 1:
		return "炸弹+1" if is_zhs else ("炸彈+1" if is_zh else "BOMB+")
	if item_type == 2:
		return "范围+1" if is_zhs else ("範圍+1" if is_zh else "RANGE+")
	if item_type == 3:
		return "移速+" if is_zhs else ("移速+" if is_zh else "SPEED+")
	if item_type == 4:
		return "踢弹" if is_zhs else ("踢彈" if is_zh else "KICK")
	return "救命针" if is_zhs else ("救命針" if is_zh else "NEEDLE")


static func build_powerup_node(tile_size: float, item_type: int) -> Node3D:
	## Authentic Machine Party 3D industrial pickups on unified dark-steel supply pads (no rainbow neon).
	var n := Node3D.new()
	var spin_root := Node3D.new()
	spin_root.name = "SpinMesh"
	spin_root.position = Vector3(0.0, tile_size * 0.44, 0.0)
	n.add_child(spin_root)

	var attached := false
	if item_type == 1: # BOMB+ (mini industrial explosive canister)
		var mini := build_water_bubble(tile_size * 0.54, Color.WHITE)
		mini.position = Vector3(0.0, -tile_size * 0.22, 0.0)
		spin_root.add_child(mini)
		attached = true
	elif item_type == 2: # POWER+ (vanilla exploding collar radio detonator)
		attached = _attach_normalized_glb(spin_root, GLB_DETONATOR, tile_size * 0.62, 0.0, Vector3(12.0, 0.0, 14.0))
	elif item_type == 3: # SPEED+ (vanilla industrial spring)
		attached = _attach_normalized_glb(spin_root, GLB_SPRING, tile_size * 0.58, 0.0, Vector3(22.0, 0.0, 18.0))
	elif item_type == 4: # KICK (vanilla heavy work boot)
		attached = _attach_normalized_glb(spin_root, GLB_SHOE, tile_size * 0.64, 0.0, Vector3(10.0, 0.0, -14.0))
	else: # NEEDLE (vanilla glowing kato syringe)
		attached = _attach_normalized_glb(spin_root, GLB_SYRINGE, tile_size * 0.72, 0.0, Vector3(28.0, 0.0, 32.0))

	if not attached:
		var fallback := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3.ONE * (tile_size * 0.36)
		fallback.mesh = fm
		fallback.material_override = make_std_mat(Color(0.76, 0.60, 0.24), 0.4, 0.4, Color(0.76, 0.55, 0.16), 0.5)
		spin_root.add_child(fallback)

	# Unified dark industrial steel supply pad with subtle warm-amber rim (consistent with Machine Party).
	var pad := MeshInstance3D.new()
	var pm2 := CylinderMesh.new()
	pm2.top_radius = tile_size * 0.30
	pm2.bottom_radius = tile_size * 0.34
	pm2.height = 0.07
	pad.mesh = pm2
	pad.material_override = make_std_mat(Color(0.22, 0.22, 0.24), 0.78, 0.46, Color.BLACK, 0.0, false, TEX_METAL_PLATE)
	pad.position = Vector3(0.0, 0.035, 0.0)
	n.add_child(pad)

	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = tile_size * 0.315
	rm.bottom_radius = tile_size * 0.315
	rm.height = 0.025
	ring.mesh = rm
	ring.material_override = make_std_mat(Color(0.86, 0.68, 0.26, 0.62), 0.2, 0.35, Color(0.82, 0.58, 0.16), 0.65, true)
	ring.position = Vector3(0.0, 0.075, 0.0)
	n.add_child(ring)

	# Clean Terminal F4 tag above each pickup so players know what it does at a glance.
	var tag := Label3D.new()
	tag.name = "PickupTag"
	tag.text = _pickup_short_label(item_type)
	tag.font_size = 28
	tag.pixel_size = 0.0064
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.modulate = Color(0.96, 0.90, 0.68)
	tag.outline_modulate = Color.BLACK
	tag.outline_size = 9
	var term_font: Font = load_terminal_font()
	if term_font != null:
		tag.font = term_font
	tag.position = Vector3(0.0, tile_size * 0.86, 0.0)
	n.add_child(tag)
	return n


static func build_trap_bubble_shell() -> Node3D:
	## Authentic Machine Party "CRITICAL / LOCKDOWN" hazard ring instead of a cartoon blue soap bubble.
	## Signals the 4-second downed state where rivals can bump-execute or Needle can auto-revive.
	var root := Node3D.new()
	root.name = "TrapBubble"
	root.visible = false

	var outer_ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.52
	tm.outer_radius = 0.66
	outer_ring.mesh = tm
	outer_ring.material_override = make_std_mat(
		Color(0.94, 0.18, 0.12, 0.85),
		0.2,
		0.3,
		Color(1.0, 0.16, 0.10),
		1.8,
		true
	)
	outer_ring.position = Vector3(0.0, 0.08, 0.0)
	root.add_child(outer_ring)

	var inner_disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.52
	dm.bottom_radius = 0.52
	dm.height = 0.02
	inner_disc.mesh = dm
	inner_disc.material_override = make_std_mat(
		Color(0.86, 0.12, 0.08, 0.24),
		0.0,
		0.5,
		Color(0.92, 0.14, 0.08),
		0.7,
		true
	)
	inner_disc.position = Vector3(0.0, 0.04, 0.0)
	root.add_child(inner_disc)

	var alarm_light := OmniLight3D.new()
	alarm_light.light_color = Color(1.0, 0.18, 0.12)
	alarm_light.light_energy = 2.6
	alarm_light.omni_range = 2.6
	alarm_light.position = Vector3(0.0, 0.75, 0.0)
	root.add_child(alarm_light)

	return root


static func _resolve_player_color(idx: int, customization: Array) -> Color:
	if customization.size() >= 3:
		var suit_name: String = str(customization[2]).strip_edges().to_lower()
		if SUIT_COLOR_VALUES.has(suit_name):
			return SUIT_COLOR_VALUES[suit_name]
	return PLAYER_COLORS[idx % PLAYER_COLORS.size()]


static func build_worker_character(idx: int, net_id: int, nickname: String, customization: Array, is_local: bool) -> Dictionary:
	ensure_game_pck_mounted()
	var col: Color = _resolve_player_color(idx, customization)
	var root := Node3D.new()
	root.name = "Player_%d" % net_id

	# Ground drop shadow disc.
	var shadow := MeshInstance3D.new()
	shadow.name = "GroundShadow"
	var sh_m := CylinderMesh.new()
	sh_m.top_radius = 0.40
	sh_m.bottom_radius = 0.40
	sh_m.height = 0.02
	shadow.mesh = sh_m
	shadow.material_override = make_std_mat(Color(0.03, 0.02, 0.04, 0.7), 0.0, 0.9, Color.BLACK, 0.0, true)
	shadow.position = Vector3(0.0, 0.025, 0.0)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shadow)

	if is_local:
		root.add_to_group(&"mpm_local_player")
		root.set_meta(&"mpm_local_player", true)
		root.set_meta(&"mpm_alive", true)

	var avatar := Node3D.new()
	avatar.name = "Avatar"
	root.add_child(avatar)

	var anim_player: AnimationPlayer = null
	var char_packed = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2.glb")
	if char_packed is PackedScene:
		var rig: Node3D = (char_packed as PackedScene).instantiate()
		rig.name = "OfficialCharacterRig"
		# main character2.glb Armature faces local -Z; rotate 180 deg so local +Z aligns with atan2(fx, fz).
		rig.rotation_degrees.y = 180.0
		rig.scale = Vector3(0.28, 0.28, 0.28)
		avatar.add_child(rig)
		_customize_official_rig(rig, idx, customization)
		anim_player = _setup_official_animations(rig)
	else:
		_build_fallback_character(avatar, col)

	var trap_shell: Node3D = build_trap_bubble_shell()
	root.add_child(trap_shell)

	var term_font: Font = load_terminal_font()
	var formatted_name: String = nickname.left(11) + "-" if nickname.length() > 11 else nickname
	var label := Label3D.new()
	label.name = "Nameplate"
	label.text = formatted_name
	label.font_size = 36
	label.pixel_size = 0.0076
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	label.outline_size = 12
	if term_font != null:
		label.font = term_font
	label.position = Vector3(0.0, 1.98, 0.0)
	root.add_child(label)

	var hp_label := Label3D.new()
	hp_label.name = "HpBar"
	hp_label.text = "■■■"
	hp_label.font_size = 32
	hp_label.pixel_size = 0.0072
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.no_depth_test = true
	hp_label.modulate = Color(0.98, 0.34, 0.28)
	hp_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	hp_label.outline_size = 10
	if term_font != null:
		hp_label.font = term_font
	hp_label.position = Vector3(0.0, 1.66, 0.0)
	root.add_child(hp_label)

	return {
		"root": root,
		"avatar": avatar,
		"color": col,
		"anim_player": anim_player,
	}


static func _customize_official_rig(rig: Node3D, idx: int, customization: Array = []) -> void:
	var sk := rig.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if sk == null:
		return

	var has_custom: bool = not customization.is_empty()
	var char_mesh := sk.get_node_or_null("character mesh") as MeshInstance3D
	if char_mesh != null:
		var suit_tex = null
		var suit_tint := Color.WHITE
		if has_custom and customization.size() >= 3:
			var suit_name: String = str(customization[2]).strip_edges().to_lower()
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

	var hat_cfg = null
	if has_custom:
		var hat_name: String = str(customization[0]).strip_edges().to_lower()
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
			var hat_inst: Node3D = (hat_packed as PackedScene).instantiate()
			hat_inst.transform = hat_cfg["tf"]
			hat_attach.add_child(hat_inst)

	var gl_cfg = null
	if has_custom and customization.size() >= 2:
		var gl_name: String = str(customization[1]).strip_edges().to_lower()
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
			var gl_inst: Node3D = (gl_packed as PackedScene).instantiate()
			gl_inst.transform = gl_cfg["tf"]
			gl_attach.add_child(gl_inst)


static func _setup_official_animations(rig: Node3D) -> AnimationPlayer:
	var ap := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		return null

	var lib := AnimationLibrary.new()
	var anim_idle = load_optional("res://animations/standing_idle_dynamic.res")
	var anim_shove = load_optional("res://minigames/disco_dodge/animations/shoved_main.res")
	var anim_crawl = load_optional("res://animations/crawl_overwrite.res")
	var anim_fall = load_optional("res://minigames/disco_dodge/animations/falling.res")

	# Reuse vanilla built-in "running" animation from main character2.glb (fallback to infected_running.res).
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
		lib.add_animation(&"shoved", anim_shove as Animation)
	var downed_src = anim_crawl if anim_crawl is Animation else anim_fall
	if downed_src is Animation:
		var dup_downed: Animation = (downed_src as Animation).duplicate()
		dup_downed.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(&"falling", dup_downed)

	if not lib.get_animation_list().is_empty():
		ap.add_animation_library(&"mp_mod", lib)
		if ap.has_animation(&"mp_mod/idle"):
			ap.play(&"mp_mod/idle")
	return ap


static func _build_fallback_character(parent: Node3D, suit_color: Color) -> void:
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.28
	bm.height = 0.96
	body.mesh = bm
	body.material_override = make_std_mat(suit_color, 0.2, 0.52)
	body.position = Vector3(0.0, 0.52, 0.0)
	parent.add_child(body)

	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.24
	hm.height = 0.48
	head.mesh = hm
	head.material_override = make_std_mat(Color(0.92, 0.86, 0.78), 0.1, 0.55)
	head.position = Vector3(0.0, 1.12, 0.0)
	parent.add_child(head)


static func build_bubble_icon() -> ImageTexture:
	## Authentic Machine Party 256x256 monochrome (#000 / #e5e5e5) CRT silhouette icon
	## matching stock minigames and Roller Carnival in Custom Playlist & Intermission Picker.
	var image := Image.new()
	image.load_svg_from_string("""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
	  <rect width="256" height="256" fill="#000"/>
	  <g fill="#e5e5e5">
	    <!-- Cross blast rays behind bomb -->
	    <path d="M118 14h20l-4 42h-12zM118 200h20l-4 42h-12zM14 118l42 4v12l-42 4zM200 122l42-4v20l-42-4z"/>
	    <!-- Diagonal sparks -->
	    <path d="M48 48l28 20-8 8-20-28zM208 48l-20 28-8-8 28-20zM48 208l20-28 8 8-28 20zM208 208l-28-20 8-8 20 28z"/>
	    <!-- Industrial pressure bomb canister -->
	    <circle cx="128" cy="140" r="56" stroke="#000" stroke-width="10"/>
	    <rect x="104" y="68" width="48" height="22" rx="6" stroke="#000" stroke-width="8"/>
	    <!-- Hazard band cutouts -->
	    <rect x="74" y="132" width="108" height="16" fill="#000"/>
	    <rect x="82" y="136" width="92" height="8" fill="#e5e5e5"/>
	    <!-- Lit fuse & spark star -->
	    <path d="M128 68c0-18 16-24 28-28" fill="none" stroke="#e5e5e5" stroke-width="10" stroke-linecap="round"/>
	    <polygon points="168,20 174,34 190,34 177,43 182,58 168,49 154,58 159,43 146,34 162,34"/>
	  </g>
	</svg>""")
	return ImageTexture.create_from_image(image)
