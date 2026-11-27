extends RefCounted

## 3D foundry-railyard arena, adaptive 2-4 team steel rails & turntable hub,
## 3D diegetic CRT monitor, bomb cart, player rig, and icon builders for Bomb Cart (炸彈推車).

const TEX_CONTROL_PANEL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_chisel gauntlet control panel1.png"
const TEX_METAL_PLATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_metal plate1.png"
const TEX_WALL := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba walls1.png"
const TEX_SIDING := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba siding.png"
const TEX_PIPES := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_fc pipes2.png"
const TEX_HEAVY_RUST := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust2.png"
const TEX_FLOOR_CONCRETE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba floor5.png"
const TEX_BRICK_WALL := "res://minigames/burn_recycle/models/burn recycle visuals6/burn recycle visuals6_burn and recycle brick wall bake.png"
const TEX_PLASTER_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_plaster damaged normal.png"
const TEX_DARK_METAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_shotgun device metal darkened3.png"
const TEX_RUST_PAINTED := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust painted2.png"
const TEX_DECAL_STAIN := "res://textures/decal stain masked1.png"
const TEX_DECAL_SCORCH := "res://textures/decals/explosion_mark.png"
const GLB_WALL_LAMP := "res://models/elevator light2/elevator light2.glb"
const GLB_FAN := "res://minigames/smoke_break/models/smoke break fan1/smoke break fan1.glb"
const GLB_LIGHT_FIXTURE := "res://minigames/exploding_collar_race/models/collar race light fixture1/collar race light fixture1.glb"
const GLB_SERVER_RACK := "res://minigames/intermission_new/models/intermission server rack temp1/intermission server rack temp1.glb"

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
static var _cjk_font_cache: Font = null


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


static func load_cjk_terminal_font() -> Font:
	if _cjk_font_cache != null:
		return _cjk_font_cache
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"PingFang TC", "PingFang SC", "Microsoft JhengHei", "Microsoft YaHei",
		"Noto Sans CJK TC", "Heiti TC", "Helvetica Neue", "Arial",
	])
	var raw: Font = load_terminal_font()
	if raw != null:
		var fv := FontVariation.new()
		fv.base_font = raw
		fv.fallbacks = [sys]
		_cjk_font_cache = fv
		return _cjk_font_cache
	_cjk_font_cache = sys
	return _cjk_font_cache


static func _make_mat(
	albedo: Color,
	metallic: float = 0.3,
	roughness: float = 0.55,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0,
	alpha: bool = false,
	unshaded: bool = false,
	tex_path: String = "",
	uv_scale: Vector3 = Vector3.ONE,
	normal_path: String = "",
	triplanar: bool = false,
	normal_scale: float = 0.72,
	linear_filter: bool = true
) -> StandardMaterial3D:
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
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not tex_path.is_empty():
		var tex = load_optional(tex_path)
		if tex is Texture2D:
			mat.albedo_texture = tex as Texture2D
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC if linear_filter else BaseMaterial3D.TEXTURE_FILTER_NEAREST
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


static func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _cyl_mesh(top_r: float, bot_r: float, h: float, segs: int = 16) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = h
	m.radial_segments = segs
	return m


static func _torus_mesh(inner_r: float, outer_r: float, rings: int = 28) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner_r
	m.outer_radius = outer_r
	m.rings = rings
	m.ring_segments = 8
	return m


static func _team_color(team_id: int, cfg) -> Color:
	if cfg != null:
		var raw_colors = cfg.get("TEAM_COLORS")
		if raw_colors is Dictionary and (raw_colors as Dictionary).has(team_id):
			return (raw_colors as Dictionary)[team_id] as Color
	match team_id:
		1: return Color(1.0, 0.30, 0.28, 1.0)
		2: return Color(0.26, 0.68, 1.0, 1.0)
		3: return Color(0.28, 0.92, 0.48, 1.0)
		4: return Color(1.0, 0.84, 0.24, 1.0)
		_: return Color(0.86, 0.80, 0.72, 1.0)


static func build_bomb_cart_icon() -> ImageTexture:
	# High-contrast warm foundry charcoal / iron / amber bomb-on-rails icon.
	var w: int = 128
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.09, 0.07, 0.06, 1.0))
	for y in range(h):
		for x in range(w):
			# Riveted copper-amber industrial border
			if x < 5 or x >= w - 5 or y < 5 or y >= h - 5:
				var is_rivet: bool = ((x < 10 or x >= w - 10) and (y < 10 or y >= h - 10))
				img.set_pixel(x, y, Color(1.0, 0.78, 0.28, 1.0) if is_rivet else Color(0.68, 0.42, 0.16, 1.0))
				continue
			# Subtle warm furnace radial glow behind cart
			var gx: float = (float(x) - 64.0) / 56.0
			var gy: float = (float(y) - 60.0) / 56.0
			var gd2: float = gx * gx + gy * gy
			if gd2 < 1.0:
				var glow: float = (1.0 - gd2) * 0.22
				img.set_pixel(x, y, Color(0.09 + glow * 1.1, 0.07 + glow * 0.52, 0.06 + glow * 0.15, 1.0))
			# Industrial rail ties & steel track bar across lower third
			if y >= 88 and y <= 98 and x >= 12 and x <= w - 13:
				if (x % 14) < 5:
					img.set_pixel(x, y, Color(0.36, 0.25, 0.18, 1.0))
			if absf(float(y - 86)) <= 3.5 and x >= 10 and x <= w - 11:
				img.set_pixel(x, y, Color(0.76, 0.70, 0.64, 1.0))
			# Heavy iron cart chassis + hazard bumpers
			if absf(float(x - 64)) <= 30.0 and y >= 68 and y <= 82:
				if absf(float(x - 64)) >= 24.0:
					var stripe: bool = ((x + y) / 4) % 2 == 0
					img.set_pixel(x, y, Color(0.98, 0.70, 0.14, 1.0) if stripe else Color(0.14, 0.11, 0.10, 1.0))
				else:
					img.set_pixel(x, y, Color(0.34, 0.28, 0.24, 1.0))
			# Heavy cast-iron bomb warhead with glowing furnace amber core
			var dx: float = (float(x) - 64.0) / 28.0
			var dy: float = (float(y) - 50.0) / 20.0
			var d2: float = dx * dx + dy * dy
			if d2 <= 1.0:
				if absf(float(x - 64)) <= 5.0:
					img.set_pixel(x, y, Color(1.0, 0.84, 0.22, 1.0))
				elif absf(float(x - 64)) <= 10.0:
					img.set_pixel(x, y, Color(0.98, 0.42, 0.12, 1.0))
				else:
					img.set_pixel(x, y, Color(0.24, 0.20, 0.19, 1.0))
			# Top detonator beacon dome
			var bdx: float = (float(x) - 64.0) / 8.0
			var bdy: float = (float(y) - 27.0) / 7.0
			if bdx * bdx + bdy * bdy <= 1.0:
				img.set_pixel(x, y, Color(1.0, 0.74, 0.18, 1.0))
			# Flanged steel wheels
			for wx in [44.0, 84.0]:
				var wdx: float = float(x) - wx
				var wdy: float = float(y) - 84.0
				var wd2: float = wdx * wdx + wdy * wdy
				if wd2 <= 64.0:
					img.set_pixel(x, y, Color(0.95, 0.74, 0.24, 1.0) if wd2 <= 16.0 else Color(0.72, 0.66, 0.60, 1.0))
	return ImageTexture.create_from_image(img)


static func _build_foundry_backdrop(
	root: Node3D,
	half_x: float,
	half_z: float,
	team_count: int,
	wall_mat: StandardMaterial3D,
	pipes_mat: StandardMaterial3D,
	rust_mat: StandardMaterial3D,
	dark_metal_mat: StandardMaterial3D
) -> Dictionary:
	var fans: Array = []
	var flicker_lamp_mat: StandardMaterial3D = null
	var result: Dictionary = {
		"monitor_timer_label": null,
		"monitor_phase_label": null,
		"fans": fans,
		"flicker_lamp_mat": null,
	}
	var back_z: float = -half_z - 0.90
	var wall_w: float = half_x * 2.0 + 5.6
	var wall_h: float = 9.2 if team_count >= 3 else 8.2

	# 1. Sub-deck dark steel factory catwalk foundation tight beneath arena (zero void slabs)
	var sub_deck := MeshInstance3D.new()
	sub_deck.name = "FoundrySubDeck"
	sub_deck.mesh = _box_mesh(Vector3(wall_w, 0.8, half_z * 2.0 + 3.8))
	sub_deck.position = Vector3(0.0, -0.66, 0.0)
	sub_deck.material_override = _make_mat(
		Color(0.36, 0.34, 0.33), 0.50, 0.62,
		Color.BLACK, 0.0, false, false, TEX_DARK_METAL, Vector3(0.22, 0.22, 0.22), "", true
	)
	root.add_child(sub_deck)

	var deck_rim := MeshInstance3D.new()
	deck_rim.name = "FoundrySubDeckRim"
	deck_rim.mesh = _box_mesh(Vector3(wall_w + 0.16, 0.12, half_z * 2.0 + 3.96))
	deck_rim.position = Vector3(0.0, -0.32, 0.0)
	deck_rim.material_override = dark_metal_mat
	root.add_child(deck_rim)

	# 2. Tall foundry North brick back wall matched to sub-deck width
	var back_wall := MeshInstance3D.new()
	back_wall.name = "FoundryBackWall"
	back_wall.mesh = _box_mesh(Vector3(wall_w, wall_h, 0.65))
	back_wall.position = Vector3(0.0, wall_h * 0.5 - 0.6, back_z - 0.45)
	back_wall.material_override = wall_mat
	root.add_child(back_wall)

	# Heavy vertical steel buttress columns framing the north wall bays
	var col_mesh := _box_mesh(Vector3(0.72, wall_h + 0.2, 0.95))
	var col_xs: Array = [-half_x - 2.3, -half_x * 0.68, -4.4, 4.4, half_x * 0.68, half_x + 2.3]
	for cx in col_xs:
		var col_mi := MeshInstance3D.new()
		col_mi.mesh = col_mesh
		col_mi.position = Vector3(float(cx), wall_h * 0.5 - 0.5, back_z - 0.15)
		col_mi.material_override = dark_metal_mat
		root.add_child(col_mi)

	# 3. Overhead horizontal steam pipes spanning back wall
	var pipe_y_list: Array = [2.4, 5.2] if team_count <= 2 else [2.2, 6.4]
	for py in pipe_y_list:
		var pipe := MeshInstance3D.new()
		pipe.mesh = _cyl_mesh(0.24, 0.24, wall_w - 0.8, 12)
		pipe.rotation_degrees.z = 90.0
		pipe.position = Vector3(0.0, float(py), back_z + 0.05)
		pipe.material_override = pipes_mat
		root.add_child(pipe)

	# 3b. Industrial exhaust fans mounted on North wall (2 for 2-team, 3 for 3-4 team)
	var fan_packed = load_optional(GLB_FAN)
	var fan_specs: Array = []
	if team_count <= 2:
		fan_specs = [
			Vector3(-6.6, 3.85, back_z + 0.10),
			Vector3(6.6, 3.85, back_z + 0.10),
		]
	else:
		fan_specs = [
			Vector3(-6.6, 4.35, back_z + 0.10),
			Vector3(0.0, 3.30, back_z + 0.10),
			Vector3(6.6, 4.35, back_z + 0.10),
		]
	var fan_shroud_mesh := _cyl_mesh(0.98, 1.04, 0.34, 20)
	for f_idx in range(fan_specs.size()):
		var fpos: Vector3 = fan_specs[f_idx] as Vector3
		var shroud := MeshInstance3D.new()
		shroud.name = "ExhaustFanShroud_%d" % f_idx
		shroud.mesh = fan_shroud_mesh
		shroud.rotation_degrees.x = 90.0
		shroud.position = fpos + Vector3(0.0, 0.0, -0.08)
		shroud.material_override = dark_metal_mat
		root.add_child(shroud)

		var fan_mount := Node3D.new()
		fan_mount.name = "ExhaustFanMount_%d" % f_idx
		fan_mount.position = fpos + Vector3(0.0, 0.0, 0.06)
		fan_mount.rotation_degrees.y = 180.0
		fan_mount.scale = Vector3(0.72, 0.72, 0.72)
		root.add_child(fan_mount)

		if fan_packed is PackedScene:
			var fan_inst: Node3D = (fan_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(fan_inst)
			var fan_mesh := fan_inst.get_node_or_null("fan_002") as MeshInstance3D
			if fan_mesh != null:
				fan_mesh.position = Vector3(-0.034, 0.021, 0.0)
			fan_mount.add_child(fan_inst)
			fans.append(fan_inst)
		else:
			var hub_pivot := Node3D.new()
			hub_pivot.name = "FallbackFan_%d" % f_idx
			for b_i in range(4):
				var blade := MeshInstance3D.new()
				blade.mesh = _box_mesh(Vector3(1.65, 0.24, 0.08))
				blade.rotation_degrees.z = float(b_i) * 45.0
				blade.material_override = rust_mat
				hub_pivot.add_child(blade)
			fan_mount.add_child(hub_pivot)
			fans.append(hub_pivot)

	# 4. Warm industrial cage lamps mounted outside CRT monitor (1 assigned to flicker_lamp_mat)
	var lamp_packed = load_optional(GLB_WALL_LAMP)
	var cage_mat := _make_mat(Color(0.26, 0.21, 0.19), 0.55, 0.62, Color.BLACK, 0.0, false, false, TEX_HEAVY_RUST, Vector3(0.5, 0.5, 0.5))
	var lamp_mat := _make_mat(Color(1.0, 0.72, 0.32), 0.1, 0.25, Color(1.0, 0.64, 0.20), 1.85)
	flicker_lamp_mat = _make_mat(Color(1.0, 0.72, 0.32), 0.1, 0.25, Color(1.0, 0.64, 0.20), 1.85)
	result["flicker_lamp_mat"] = flicker_lamp_mat
	var lamp_y: float = 4.1 if team_count <= 2 else 4.9
	var lamp_xs: Array = [-11.4, -3.55, 3.55, 11.4]
	for l_idx in range(lamp_xs.size()):
		var lx: float = float(lamp_xs[l_idx])
		var target_lamp_mat: StandardMaterial3D = flicker_lamp_mat if l_idx == 1 else lamp_mat
		if lamp_packed is PackedScene:
			var linst: Node3D = (lamp_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(linst)
			linst.position = Vector3(lx, lamp_y, back_z + 0.26)
			linst.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			linst.scale = Vector3(0.75, 0.75, 0.75)
			root.add_child(linst)
			for c in linst.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).set_surface_override_material(0, target_lamp_mat)
		else:
			var housing := MeshInstance3D.new()
			housing.mesh = _box_mesh(Vector3(1.15, 0.36, 0.32))
			housing.position = Vector3(lx, lamp_y, back_z + 0.04)
			housing.material_override = cage_mat
			root.add_child(housing)

			var filament := MeshInstance3D.new()
			filament.mesh = _box_mesh(Vector3(0.88, 0.18, 0.16))
			filament.position = Vector3(lx, lamp_y - 0.02, back_z + 0.18)
			filament.material_override = target_lamp_mat
			root.add_child(filament)

	# 4b. Flanking industrial light fixtures tucked strictly inside the north wall silhouette
	var fixture_packed = load_optional(GLB_LIGHT_FIXTURE)
	var fix_bulb_mat := _make_mat(Color(1.0, 0.84, 0.54), 0.1, 0.2, Color(1.0, 0.76, 0.38), 1.8)
	var fix_specs: Array = []
	if team_count <= 2:
		fix_specs = [
			[Vector3(-9.0, -0.26, back_z + 0.15), 0.47],
			[Vector3(9.0, -0.26, back_z + 0.15), 0.47],
		]
	else:
		fix_specs = [
			[Vector3(-9.0, -0.26, back_z + 0.15), 0.53],
			[Vector3(9.0, -0.26, back_z + 0.15), 0.53],
		]
	for fx_idx in range(fix_specs.size()):
		var fspec: Array = fix_specs[fx_idx] as Array
		var fpos: Vector3 = fspec[0] as Vector3
		var fscale: float = float(fspec[1])
		if fixture_packed is PackedScene:
			var finst: Node3D = (fixture_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(finst)
			finst.name = "OverheadFixture_%d" % fx_idx
			finst.position = fpos
			finst.scale = Vector3(fscale, fscale, fscale)
			var cyl_mi := finst.get_node_or_null("Cylinder") as MeshInstance3D
			if cyl_mi != null:
				cyl_mi.set_surface_override_material(1, fix_bulb_mat)
			root.add_child(finst)
		else:
			var pole_h: float = 13.0 * fscale
			var stem := MeshInstance3D.new()
			stem.mesh = _cyl_mesh(0.08, 0.12, pole_h, 8)
			stem.position = fpos + Vector3(0.0, pole_h * 0.5, 0.0)
			stem.material_override = dark_metal_mat
			root.add_child(stem)
			var hood := MeshInstance3D.new()
			hood.mesh = _cyl_mesh(0.24, 0.56, 0.38, 12)
			hood.position = fpos + Vector3(0.0, pole_h, 0.0)
			hood.material_override = rust_mat
			root.add_child(hood)

	# 4c. North-flank industrial server racks anchored tight against the lit north brick back wall (zero outer-void props)
	var rack_packed = load_optional(GLB_SERVER_RACK)
	var rack_placements: Array = [
		[Vector3(-half_x * 0.48, -0.26, back_z + 0.24), 10.0],
		[Vector3(half_x * 0.48, -0.26, back_z + 0.24), -10.0],
	]
	for rp_raw in rack_placements:
		var rp: Array = rp_raw as Array
		var rpos: Vector3 = rp[0] as Vector3
		var ryaw: float = float(rp[1])
		if rack_packed is PackedScene:
			var rinst: Node3D = (rack_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(rinst)
			rinst.position = rpos
			rinst.rotation_degrees.y = ryaw
			rinst.scale = Vector3(0.48, 0.48, 0.48)
			root.add_child(rinst)
		else:
			var rbox := MeshInstance3D.new()
			rbox.mesh = _box_mesh(Vector3(0.8, 2.8, 1.0))
			rbox.position = rpos + Vector3(0.0, 1.4, 0.0)
			rbox.rotation_degrees.y = ryaw
			rbox.material_override = dark_metal_mat
			root.add_child(rbox)

	# Warm furnace accent lights washing the north brick wall, pipes, and exhaust fans
	var furnace_l := OmniLight3D.new()
	furnace_l.name = "FoundryGlowLeft"
	furnace_l.light_color = Color(1.0, 0.64, 0.28)
	furnace_l.light_energy = 4.2
	furnace_l.omni_range = 21.0
	furnace_l.position = Vector3(-7.5, 5.0, back_z + 2.6)
	root.add_child(furnace_l)

	var furnace_r := OmniLight3D.new()
	furnace_r.name = "FoundryGlowRight"
	furnace_r.light_color = Color(1.0, 0.64, 0.28)
	furnace_r.light_energy = 4.2
	furnace_r.omni_range = 21.0
	furnace_r.position = Vector3(7.5, 5.0, back_z + 2.6)
	root.add_child(furnace_r)

	var furnace_c := OmniLight3D.new()
	furnace_c.name = "FoundryGlowCenter"
	furnace_c.light_color = Color(1.0, 0.72, 0.38)
	furnace_c.light_energy = 2.6
	furnace_c.omni_range = 15.0
	furnace_c.position = Vector3(0.0, 5.2, back_z + 2.6)
	root.add_child(furnace_c)

	# 5. Large 3D Diegetic Industrial CRT Clock/Phase Monitor on North Back Wall
	var mon_y: float = 4.35 if team_count <= 2 else 6.00
	var mon_scale: float = 1.0 if team_count <= 2 else 1.24
	var monitor := Node3D.new()
	monitor.name = "DiegeticMonitor"
	monitor.position = Vector3(0.0, mon_y, back_z + 0.38)
	monitor.rotation_degrees.x = 20.0
	monitor.scale = Vector3(mon_scale, mon_scale, mon_scale)
	root.add_child(monitor)

	var casing := MeshInstance3D.new()
	casing.mesh = _box_mesh(Vector3(4.90, 2.35, 0.56))
	casing.material_override = _make_mat(Color(0.28, 0.24, 0.22), 0.55, 0.60, Color.BLACK, 0.0, false, false, TEX_HEAVY_RUST, Vector3(0.6, 0.4, 0.4))
	monitor.add_child(casing)

	var bezel := MeshInstance3D.new()
	bezel.mesh = _box_mesh(Vector3(4.52, 2.00, 0.12))
	bezel.position = Vector3(0.0, 0.0, 0.26)
	bezel.material_override = _make_mat(Color(0.09, 0.08, 0.08), 0.40, 0.68)
	monitor.add_child(bezel)

	var screen := MeshInstance3D.new()
	screen.mesh = _box_mesh(Vector3(4.24, 1.76, 0.05))
	screen.position = Vector3(0.0, 0.0, 0.31)
	screen.material_override = _make_mat(Color(0.05, 0.04, 0.02), 0.15, 0.28, Color(0.24, 0.14, 0.03), 0.35)
	monitor.add_child(screen)

	var term_font: Font = load_cjk_terminal_font()
	var timer_lbl := Label3D.new()
	timer_lbl.name = "MonitorTimerLabel"
	timer_lbl.text = "01:15"
	timer_lbl.font_size = 112
	timer_lbl.pixel_size = 0.0096
	timer_lbl.modulate = Color(1.0, 0.78, 0.24)
	timer_lbl.outline_modulate = Color(0.06, 0.03, 0.01)
	timer_lbl.outline_size = 16
	if term_font != null:
		timer_lbl.font = term_font
	timer_lbl.position = Vector3(0.0, 0.24, 0.35)
	monitor.add_child(timer_lbl)
	result["monitor_timer_label"] = timer_lbl

	var phase_lbl := Label3D.new()
	phase_lbl.name = "MonitorPhaseLabel"
	phase_lbl.text = "PUSH"
	phase_lbl.font_size = 54
	phase_lbl.pixel_size = 0.0092
	phase_lbl.modulate = Color(0.96, 0.62, 0.18)
	phase_lbl.outline_modulate = Color(0.06, 0.03, 0.01)
	phase_lbl.outline_size = 11
	if term_font != null:
		phase_lbl.font = term_font
	phase_lbl.position = Vector3(0.0, -0.41, 0.35)
	monitor.add_child(phase_lbl)
	result["monitor_phase_label"] = phase_lbl

	return result


static func build_arena(parent: Node3D, cfg, active_team_ids: Array = [1, 2]) -> Dictionary:
	ensure_game_pck_mounted()
	var teams: Array = active_team_ids.duplicate()
	if teams.size() < 2:
		teams = [1, 2]
	var team_count: int = clampi(teams.size(), 2, 4)

	var half_sz: Vector2 = cfg.arena_half_size(team_count) if (cfg != null and cfg.has_method("arena_half_size")) else Vector2(13.0, 8.0)
	var half_x: float = half_sz.x
	var half_z: float = half_sz.y
	var track_len: float = float(cfg.track_length(team_count)) if (cfg != null and cfg.has_method("track_length")) else 11.5
	var push_r: float = float(cfg.PUSH_AURA_RADIUS) if cfg != null else 2.6
	var pulse_r: float = float(cfg.PULSE_RADIUS) if cfg != null else 3.2
	var pillar_r: float = float(cfg.PILLAR_RADIUS) if cfg != null else 1.0
	var door_dirs: Dictionary = cfg.door_directions(teams) if (cfg != null and cfg.has_method("door_directions")) else {1: Vector2(-1.0, 0.0), 2: Vector2(1.0, 0.0)}

	var root := Node3D.new()
	root.name = "BombCartArena"
	if parent != null:
		parent.add_child(root)

	# Warm heavy-foundry / steel-railyard PBR materials with clear surface contrast separation
	var floor_mat := _make_mat(
		Color(0.62, 0.58, 0.54), 0.08, 0.88,
		Color.BLACK, 0.0, false, false, TEX_FLOOR_CONCRETE, Vector3(0.16, 0.16, 0.16), "", true
	)
	var wall_mat := _make_mat(
		Color(0.74, 0.65, 0.59), 0.12, 0.86,
		Color.BLACK, 0.0, false, false, TEX_BRICK_WALL, Vector3(0.22, 0.22, 0.22), TEX_PLASTER_NORMAL, true, 0.85
	)
	var guard_mat := _make_mat(Color(0.52, 0.45, 0.40), 0.48, 0.56, Color.BLACK, 0.0, false, false, TEX_WALL, Vector3(8.0, 1.0, 1.0))
	var trim_mat := _make_mat(
		Color(0.52, 0.48, 0.45), 0.66, 0.42,
		Color.BLACK, 0.0, false, false, TEX_METAL_PLATE, Vector3(0.35, 0.35, 0.35), "", true
	)
	var apron_mat := _make_mat(
		Color(0.48, 0.45, 0.43), 0.60, 0.48,
		Color.BLACK, 0.0, false, false, TEX_METAL_PLATE, Vector3(0.20, 0.20, 0.20), "", true
	)
	var panel_mat := _make_mat(Color(0.76, 0.68, 0.60), 0.45, 0.44, Color.BLACK, 0.0, false, false, TEX_CONTROL_PANEL, Vector3(1.0, 1.0, 1.0))
	var hazard_mat := _make_mat(Color(0.92, 0.62, 0.16), 0.22, 0.48, Color(0.86, 0.54, 0.12), 0.25, false, false, TEX_SIDING, Vector3(6.0, 1.0, 1.0))
	var pipes_mat := _make_mat(Color(0.58, 0.50, 0.44), 0.58, 0.42, Color.BLACK, 0.0, false, false, TEX_PIPES, Vector3(2.0, 2.0, 1.0))
	var rust_mat := _make_mat(Color(0.58, 0.46, 0.38), 0.50, 0.54, Color.BLACK, 0.0, false, false, TEX_RUST_PAINTED, Vector3(2.0, 2.0, 1.0))
	var dark_metal_mat := _make_mat(Color(0.46, 0.42, 0.40), 0.62, 0.46, Color.BLACK, 0.0, false, false, TEX_DARK_METAL, Vector3(0.30, 0.30, 0.30), "", true)
	var rail_steel_mat := _make_mat(Color(0.78, 0.74, 0.69), 0.90, 0.20)
	var rail_bed_mat := _make_mat(Color(0.20, 0.19, 0.19), 0.45, 0.68, Color.BLACK, 0.0, false, false, TEX_DARK_METAL, Vector3(0.28, 0.28, 0.28), "", true)
	var amber_mat := _make_mat(Color(1.0, 0.68, 0.18), 0.2, 0.22, Color(1.0, 0.64, 0.14), 1.8)

	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D
	var scorch_tex := load_optional(TEX_DECAL_SCORCH) as Texture2D

	# 0. Industrial Foundry Backdrop, Vanilla GLB Dressing & 3D Diegetic Monitor
	var backdrop_info: Dictionary = _build_foundry_backdrop(root, half_x, half_z, team_count, wall_mat, pipes_mat, rust_mat, dark_metal_mat)

	# 1. Main Factory Floor
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "ArenaFloor"
	floor_mi.mesh = _box_mesh(Vector3(half_x * 2.0, 0.5, half_z * 2.0))
	floor_mi.position = Vector3(0.0, -0.25, 0.0)
	floor_mi.material_override = floor_mat
	root.add_child(floor_mi)

	# 2. Perimeter Industrial Guardrails
	var wall_specs: Array = [
		[Vector3(0.0, 0.52, -half_z - 0.30), Vector3(half_x * 2.0 + 1.2, 1.04, 0.60)],
		[Vector3(0.0, 0.52, half_z + 0.30), Vector3(half_x * 2.0 + 1.2, 1.04, 0.60)],
		[Vector3(-half_x - 0.30, 0.52, 0.0), Vector3(0.60, 1.04, half_z * 2.0 + 1.2)],
		[Vector3(half_x + 0.30, 0.52, 0.0), Vector3(0.60, 1.04, half_z * 2.0 + 1.2)],
	]
	for w_spec in wall_specs:
		var spec: Array = w_spec as Array
		var pos: Vector3 = spec[0] as Vector3
		var sz: Vector3 = spec[1] as Vector3
		var w := MeshInstance3D.new()
		w.mesh = _box_mesh(sz)
		w.position = pos
		w.material_override = guard_mat
		root.add_child(w)

		var stripe := MeshInstance3D.new()
		stripe.mesh = _box_mesh(Vector3(sz.x * 0.99, 0.16, sz.z * 1.02))
		stripe.position = pos + Vector3(0.0, 0.54, 0.0)
		stripe.material_override = hazard_mat
		root.add_child(stripe)

	# 3. Heavy Steel Rail Network (2-team straight vs 3-4 team radial turntable hub)
	var rail_root := Node3D.new()
	rail_root.name = "RailNetwork"
	root.add_child(rail_root)

	var track_leds: Array = []
	var turntable_node: Node3D = null
	var marker_mat := _make_mat(Color(0.96, 0.76, 0.24, 0.85), 0.1, 0.4, Color(0.96, 0.72, 0.20), 0.95, true)

	if team_count <= 2:
		var rail_apron := MeshInstance3D.new()
		rail_apron.name = "RailApron"
		rail_apron.mesh = _box_mesh(Vector3(track_len * 2.0 + 1.4, 0.024, 3.2))
		rail_apron.position = Vector3(0.0, 0.010, 0.0)
		rail_apron.material_override = apron_mat
		rail_root.add_child(rail_apron)

		var rail_bed := MeshInstance3D.new()
		rail_bed.mesh = _box_mesh(Vector3(track_len * 2.0 + 0.6, 0.05, 2.2))
		rail_bed.position = Vector3(0.0, 0.026, 0.0)
		rail_bed.material_override = rail_bed_mat
		rail_root.add_child(rail_bed)

		for rz in [-0.62, 0.62]:
			var beam := MeshInstance3D.new()
			beam.mesh = _box_mesh(Vector3(track_len * 2.0 + 0.2, 0.14, 0.14))
			beam.position = Vector3(0.0, 0.095, float(rz))
			beam.material_override = rail_steel_mat
			rail_root.add_child(beam)

		var tie_mesh: BoxMesh = _box_mesh(Vector3(0.24, 0.06, 1.75))
		var tie_x: float = -track_len + 0.5
		while tie_x <= track_len - 0.4:
			var tie := MeshInstance3D.new()
			tie.mesh = tie_mesh
			tie.position = Vector3(tie_x, 0.058, 0.0)
			tie.material_override = rust_mat
			rail_root.add_child(tie)
			tie_x += 1.15

		for mx in [-track_len * 0.5, 0.0, track_len * 0.5]:
			var mark := MeshInstance3D.new()
			var mark_w: float = 0.22 if is_zero_approx(float(mx)) else 0.12
			mark.mesh = _box_mesh(Vector3(mark_w, 0.02, 3.0))
			mark.position = Vector3(float(mx), 0.026, 0.0)
			mark.material_override = marker_mat
			rail_root.add_child(mark)

		for rx_decal in [-6.5, 0.0, 6.5]:
			_add_floor_decal(rail_root, stain_tex, Vector3(float(rx_decal), 0.05, 0.0), Vector3(3.4, 0.45, 2.5), Color(0.18, 0.14, 0.12, 0.58), 0.15 * float(rx_decal))
		for sx_decal in [-2.4, 0.0, 2.4]:
			_add_floor_decal(rail_root, scorch_tex, Vector3(float(sx_decal), 0.05, 0.0), Vector3(2.2, 0.45, 2.2), Color(0.15, 0.12, 0.10, 0.45), float(sx_decal) * 0.6)

		var led_mesh: BoxMesh = _box_mesh(Vector3(1.15, 0.05, 0.14))
		for i in range(11):
			var lx: float = -10.0 + float(i) * 2.0
			var led_mat := _make_mat(Color(0.55, 0.48, 0.42), 0.1, 0.3, Color(0.55, 0.48, 0.42), 0.6)
			for sz in [-0.95, 0.95]:
				var led := MeshInstance3D.new()
				led.mesh = led_mesh
				led.position = Vector3(lx, 0.06, float(sz))
				led.material_override = led_mat
				rail_root.add_child(led)
			track_leds.append({"mode": 2, "x": lx, "mat": led_mat})
	else:
		# Central Heavy Steel Turntable Hub at (0, 0)
		var hub_apron := MeshInstance3D.new()
		hub_apron.name = "TurntableApron"
		hub_apron.mesh = _cyl_mesh(2.90, 3.02, 0.024, 32)
		hub_apron.position = Vector3(0.0, 0.010, 0.0)
		hub_apron.material_override = apron_mat
		rail_root.add_child(hub_apron)

		var hub_pit := MeshInstance3D.new()
		hub_pit.name = "TurntablePit"
		hub_pit.mesh = _cyl_mesh(2.25, 2.35, 0.08, 32)
		hub_pit.position = Vector3(0.0, 0.032, 0.0)
		hub_pit.material_override = rail_bed_mat
		rail_root.add_child(hub_pit)

		var hub_trim := MeshInstance3D.new()
		hub_trim.mesh = _torus_mesh(2.10, 2.38, 36)
		hub_trim.position = Vector3(0.0, 0.06, 0.0)
		hub_trim.scale = Vector3(1.0, 0.16, 1.0)
		hub_trim.material_override = hazard_mat
		rail_root.add_child(hub_trim)

		turntable_node = Node3D.new()
		turntable_node.name = "TurntableDisc"
		rail_root.add_child(turntable_node)

		var disc := MeshInstance3D.new()
		disc.mesh = _cyl_mesh(1.92, 1.98, 0.10, 28)
		disc.position = Vector3(0.0, 0.05, 0.0)
		disc.material_override = trim_mat
		turntable_node.add_child(disc)

		for rz in [-0.62, 0.62]:
			var bridge_rail := MeshInstance3D.new()
			bridge_rail.mesh = _box_mesh(Vector3(3.65, 0.14, 0.14))
			bridge_rail.position = Vector3(0.0, 0.10, float(rz))
			bridge_rail.material_override = rail_steel_mat
			turntable_node.add_child(bridge_rail)

		var hub_bolt := MeshInstance3D.new()
		hub_bolt.mesh = _cyl_mesh(0.28, 0.34, 0.14, 16)
		hub_bolt.position = Vector3(0.0, 0.08, 0.0)
		hub_bolt.material_override = amber_mat
		turntable_node.add_child(hub_bolt)

		_add_floor_decal(rail_root, scorch_tex, Vector3(0.0, 0.06, 0.0), Vector3(3.4, 0.45, 3.4), Color(0.15, 0.12, 0.10, 0.45), 0.35)

		# Radial branch steel rails to each active team's Blast Door
		var branch_start: float = 1.95
		var branch_len: float = maxf(2.0, track_len - branch_start)
		var tie_mesh_m: BoxMesh = _box_mesh(Vector3(0.24, 0.06, 1.75))
		var led_mesh_m: BoxMesh = _box_mesh(Vector3(1.05, 0.05, 0.14))
		for raw_tid in teams:
			var tid: int = int(raw_tid)
			var dir2: Vector2 = door_dirs.get(tid, Vector2(1.0, 0.0)) as Vector2
			var yaw: float = float(cfg.branch_yaw_from_dir(dir2)) if (cfg != null and cfg.has_method("branch_yaw_from_dir")) else atan2(-dir2.y, dir2.x)
			var arm := Node3D.new()
			arm.name = "RailBranch_%d" % tid
			arm.rotation.y = yaw
			rail_root.add_child(arm)

			var branch_apron := MeshInstance3D.new()
			branch_apron.mesh = _box_mesh(Vector3(branch_len + 0.7, 0.024, 3.1))
			branch_apron.position = Vector3(branch_start + branch_len * 0.5, 0.010, 0.0)
			branch_apron.material_override = apron_mat
			arm.add_child(branch_apron)

			var bed := MeshInstance3D.new()
			bed.mesh = _box_mesh(Vector3(branch_len + 0.4, 0.05, 2.2))
			bed.position = Vector3(branch_start + branch_len * 0.5, 0.026, 0.0)
			bed.material_override = rail_bed_mat
			arm.add_child(bed)

			for rz in [-0.62, 0.62]:
				var beam := MeshInstance3D.new()
				beam.mesh = _box_mesh(Vector3(branch_len + 0.25, 0.14, 0.14))
				beam.position = Vector3(branch_start + branch_len * 0.5, 0.095, float(rz))
				beam.material_override = rail_steel_mat
				arm.add_child(beam)

			var tr: float = branch_start + 0.45
			while tr <= track_len - 0.45:
				var tie := MeshInstance3D.new()
				tie.mesh = tie_mesh_m
				tie.position = Vector3(tr, 0.058, 0.0)
				tie.material_override = rust_mat
				arm.add_child(tie)
				tr += 1.15

			var mid_mark := MeshInstance3D.new()
			mid_mark.mesh = _box_mesh(Vector3(0.14, 0.02, 2.8))
			mid_mark.position = Vector3(track_len * 0.55, 0.026, 0.0)
			mid_mark.material_override = marker_mat
			arm.add_child(mid_mark)

			_add_floor_decal(arm, stain_tex, Vector3(branch_start + branch_len * 0.52, 0.05, 0.0), Vector3(3.2, 0.45, 2.4), Color(0.18, 0.14, 0.12, 0.58), 0.2 * float(tid))

			var tcol: Color = _team_color(tid, cfg)
			for i in range(4):
				var lr: float = branch_start + 1.15 + float(i) * ((branch_len - 1.8) / 3.0)
				var led_mat := _make_mat(tcol, 0.1, 0.3, tcol, 0.75)
				for sz in [-0.95, 0.95]:
					var led := MeshInstance3D.new()
					led.mesh = led_mesh_m
					led.position = Vector3(lr, 0.06, float(sz))
					led.material_override = led_mat
					arm.add_child(led)
				track_leds.append({"mode": 4, "team_id": tid, "dist": lr, "mat": led_mat})

	# 4. Team Blast Doors (2, 3, or 4 dynamic doors along door_dirs — brightly lit & emissive on both faces)
	var door_lights: Dictionary = {}
	var door_nodes: Dictionary = {}
	for raw_tid in teams:
		var tid: int = int(raw_tid)
		var dir2: Vector2 = door_dirs.get(tid, Vector2(1.0, 0.0)) as Vector2
		var yaw: float = float(cfg.branch_yaw_from_dir(dir2)) if (cfg != null and cfg.has_method("branch_yaw_from_dir")) else atan2(-dir2.y, dir2.x)
		var tcol: Color = _team_color(tid, cfg)

		var d_root := Node3D.new()
		d_root.name = "BlastDoor_%d" % tid
		var dpos2: Vector2 = dir2 * (track_len + 0.35)
		d_root.position = Vector3(dpos2.x, 0.0, dpos2.y)
		d_root.rotation.y = yaw
		root.add_child(d_root)

		var zone_w: float = half_z * 1.75 if team_count <= 2 else 4.8
		var zone_mat := _make_mat(Color(tcol.r, tcol.g, tcol.b, 0.42), 0.08, 0.48, tcol, 0.55, true)
		var zone := MeshInstance3D.new()
		zone.mesh = _box_mesh(Vector3(1.65, 0.025, zone_w))
		zone.position = Vector3(-0.42, 0.014, 0.0)
		zone.material_override = zone_mat
		d_root.add_child(zone)

		var gate_mat := _make_mat(
			Color(0.58, 0.54, 0.50).lerp(tcol, 0.26), 0.50, 0.42,
			tcol, 0.08, false, false, TEX_METAL_PLATE, Vector3(1.5, 1.5, 1.0)
		)
		var gate := MeshInstance3D.new()
		gate.mesh = _box_mesh(Vector3(0.50, 3.1, 3.85))
		gate.position = Vector3(0.0, 1.55, 0.0)
		gate.material_override = gate_mat
		d_root.add_child(gate)

		# Riveted horizontal shutter ribs attached directly to the moving gate
		var rib_mesh := _box_mesh(Vector3(0.58, 0.11, 3.80))
		for rib_y in [-0.98, -0.52, 0.56]:
			var s_rib := MeshInstance3D.new()
			s_rib.mesh = rib_mesh
			s_rib.position = Vector3(0.0, float(rib_y), 0.0)
			s_rib.material_override = dark_metal_mat
			gate.add_child(s_rib)

		var band_mat := _make_mat(tcol, 0.14, 0.28, tcol, 1.05)
		var team_band := MeshInstance3D.new()
		team_band.mesh = _box_mesh(Vector3(0.62, 0.42, 3.74))
		team_band.position = Vector3(0.0, 2.66, 0.0)
		team_band.material_override = band_mat
		d_root.add_child(team_band)

		var mid_chevron := MeshInstance3D.new()
		mid_chevron.mesh = _box_mesh(Vector3(0.60, 0.26, 3.56))
		mid_chevron.position = Vector3(0.0, 1.38, 0.0)
		mid_chevron.material_override = band_mat
		d_root.add_child(mid_chevron)

		var post_mat := _make_mat(Color(0.56, 0.46, 0.39).lerp(tcol, 0.14), 0.52, 0.50, tcol, 0.14, false, false, TEX_RUST_PAINTED, Vector3(1.5, 1.5, 1.0))
		for pz in [-2.12, 2.12]:
			var plinth_low := MeshInstance3D.new()
			plinth_low.mesh = _box_mesh(Vector3(1.12, 0.28, 0.86))
			plinth_low.position = Vector3(0.0, 0.14, float(pz))
			plinth_low.material_override = dark_metal_mat
			d_root.add_child(plinth_low)

			var plinth_mid := MeshInstance3D.new()
			plinth_mid.mesh = _box_mesh(Vector3(0.96, 0.22, 0.72))
			plinth_mid.position = Vector3(0.0, 0.39, float(pz))
			plinth_mid.material_override = dark_metal_mat
			d_root.add_child(plinth_mid)

			var post := MeshInstance3D.new()
			post.mesh = _box_mesh(Vector3(0.82, 3.45, 0.58))
			post.position = Vector3(0.0, 1.72, float(pz))
			post.material_override = post_mat
			d_root.add_child(post)

			var pier_cap := MeshInstance3D.new()
			pier_cap.mesh = _box_mesh(Vector3(0.94, 0.18, 0.70))
			pier_cap.position = Vector3(0.0, 3.48, float(pz))
			pier_cap.material_override = dark_metal_mat
			d_root.add_child(pier_cap)

			var edge_strip := MeshInstance3D.new()
			edge_strip.mesh = _box_mesh(Vector3(0.88, 2.95, 0.14))
			edge_strip.position = Vector3(0.0, 1.62, float(pz) * 0.85)
			edge_strip.material_override = band_mat
			d_root.add_child(edge_strip)

		var light_mat := _make_mat(tcol.lightened(0.12), 0.08, 0.22, tcol, 1.65)
		door_lights[tid] = light_mat
		var beacon := MeshInstance3D.new()
		beacon.mesh = _cyl_mesh(0.30, 0.36, 0.44, 14)
		beacon.position = Vector3(0.0, 3.38, 0.0)
		beacon.material_override = light_mat
		d_root.add_child(beacon)

		# Industrial protective cage around BlastDoor beacon
		var cage_base := MeshInstance3D.new()
		cage_base.mesh = _cyl_mesh(0.42, 0.44, 0.10, 14)
		cage_base.position = Vector3(0.0, 3.16, 0.0)
		cage_base.material_override = dark_metal_mat
		d_root.add_child(cage_base)

		var cage_cap := MeshInstance3D.new()
		cage_cap.mesh = _cyl_mesh(0.38, 0.42, 0.08, 14)
		cage_cap.position = Vector3(0.0, 3.63, 0.0)
		cage_cap.material_override = dark_metal_mat
		d_root.add_child(cage_cap)

		var cage_bar_mesh := _cyl_mesh(0.035, 0.035, 0.46, 6)
		for cb_i in range(4):
			var ang: float = float(cb_i) * PI * 0.5 + PI * 0.25
			var cbar := MeshInstance3D.new()
			cbar.mesh = cage_bar_mesh
			cbar.position = Vector3(cos(ang) * 0.36, 3.40, sin(ang) * 0.36)
			cbar.material_override = dark_metal_mat
			d_root.add_child(cbar)

		_add_floor_decal(d_root, stain_tex, Vector3(-0.65, 0.03, 0.0), Vector3(2.8, 0.45, 4.2), Color(0.18, 0.14, 0.12, 0.58), 0.0)

		var door_omni := OmniLight3D.new()
		door_omni.light_color = tcol.lightened(0.22)
		door_omni.light_energy = 0.80
		door_omni.omni_range = 5.5
		door_omni.shadow_enabled = false
		door_omni.position = Vector3(-0.35, 3.15, 0.0)
		d_root.add_child(door_omni)

		door_nodes[tid] = {
			"root": d_root,
			"gate": gate,
			"gate_mat": gate_mat,
			"band_mat": band_mat,
			"light_mat": light_mat,
			"zone_mat": zone_mat,
			"omni": door_omni,
		}

	# 5. Bomb-Cart-Distinct Heavy Steel Rail Crash Bollards (chunky low riveted iron-and-rust crash blocks)
	var bollard_iron := _make_mat(Color(0.46, 0.42, 0.40), 0.62, 0.46, Color.BLACK, 0.0, false, false, TEX_DARK_METAL, Vector3(1.0, 1.0, 1.0))
	var bollard_dark := _make_mat(Color(0.11, 0.10, 0.09), 0.48, 0.64)
	var base_plate_mesh: BoxMesh = _box_mesh(Vector3(pillar_r * 1.68, 0.20, pillar_r * 1.68))
	var core_box_mesh: BoxMesh = _box_mesh(Vector3(pillar_r * 1.32, 0.82, pillar_r * 1.32))
	var oct_rib_mesh: BoxMesh = _box_mesh(Vector3(pillar_r * 1.24, 0.72, pillar_r * 1.24))
	var chevron_band_mesh: BoxMesh = _box_mesh(Vector3(pillar_r * 1.42, 0.14, pillar_r * 1.42))
	var dark_rib_a: BoxMesh = _box_mesh(Vector3(pillar_r * 1.46, 0.15, pillar_r * 0.42))
	var dark_rib_b: BoxMesh = _box_mesh(Vector3(pillar_r * 0.42, 0.15, pillar_r * 1.46))
	var cap_plate_mesh: BoxMesh = _box_mesh(Vector3(pillar_r * 1.26, 0.12, pillar_r * 1.26))
	var slit_a_mesh: BoxMesh = _box_mesh(Vector3(pillar_r * 0.86, 0.07, 0.16))
	var slit_b_mesh: BoxMesh = _box_mesh(Vector3(0.16, 0.07, pillar_r * 0.86))
	var rivet_mesh: CylinderMesh = _cyl_mesh(0.07, 0.08, 0.08, 8)
	var pillar_positions: Array = cfg.pillar_positions(team_count) if (cfg != null and cfg.has_method("pillar_positions")) else [
		Vector2(-5.5, -3.8), Vector2(5.5, -3.8), Vector2(-5.5, 3.8), Vector2(5.5, 3.8),
	]
	for p_idx in range(pillar_positions.size()):
		var p2: Vector2 = pillar_positions[p_idx] as Vector2
		var p_root := Node3D.new()
		p_root.position = Vector3(p2.x, 0.0, p2.y)
		root.add_child(p_root)

		_add_floor_decal(p_root, stain_tex, Vector3(0.0, 0.02, 0.0), Vector3(pillar_r * 2.9, 0.45, pillar_r * 2.3), Color(0.18, 0.14, 0.12, 0.58), float(p_idx) * 0.9)

		var base_plate := MeshInstance3D.new()
		base_plate.mesh = base_plate_mesh
		base_plate.position = Vector3(0.0, 0.10, 0.0)
		base_plate.material_override = bollard_iron
		p_root.add_child(base_plate)

		var core_block := MeshInstance3D.new()
		core_block.mesh = core_box_mesh
		core_block.position = Vector3(0.0, 0.58, 0.0)
		core_block.material_override = rust_mat
		p_root.add_child(core_block)

		var oct_block := MeshInstance3D.new()
		oct_block.mesh = oct_rib_mesh
		oct_block.position = Vector3(0.0, 0.56, 0.0)
		oct_block.rotation_degrees.y = 45.0
		oct_block.material_override = bollard_iron
		p_root.add_child(oct_block)

		for cy in [0.34, 0.84]:
			var h_band := MeshInstance3D.new()
			h_band.mesh = chevron_band_mesh
			h_band.position = Vector3(0.0, float(cy), 0.0)
			h_band.material_override = hazard_mat
			p_root.add_child(h_band)

			var rib1 := MeshInstance3D.new()
			rib1.mesh = dark_rib_a
			rib1.position = Vector3(0.0, float(cy), 0.0)
			rib1.rotation_degrees.y = 45.0
			rib1.material_override = bollard_dark
			p_root.add_child(rib1)

			var rib2 := MeshInstance3D.new()
			rib2.mesh = dark_rib_b
			rib2.position = Vector3(0.0, float(cy), 0.0)
			rib2.rotation_degrees.y = 45.0
			rib2.material_override = bollard_dark
			p_root.add_child(rib2)

		var cap_plate := MeshInstance3D.new()
		cap_plate.mesh = cap_plate_mesh
		cap_plate.position = Vector3(0.0, 1.05, 0.0)
		cap_plate.material_override = bollard_iron
		p_root.add_child(cap_plate)

		var slit_a := MeshInstance3D.new()
		slit_a.mesh = slit_a_mesh
		slit_a.position = Vector3(0.0, 1.12, 0.0)
		slit_a.material_override = amber_mat
		p_root.add_child(slit_a)

		var slit_b := MeshInstance3D.new()
		slit_b.mesh = slit_b_mesh
		slit_b.position = Vector3(0.0, 1.12, 0.0)
		slit_b.material_override = amber_mat
		p_root.add_child(slit_b)

		var rv_off: float = pillar_r * 0.48
		for rx in [-rv_off, rv_off]:
			for rz in [-rv_off, rv_off]:
				var rivet := MeshInstance3D.new()
				rivet.mesh = rivet_mesh
				rivet.position = Vector3(float(rx), 1.13, float(rz))
				rivet.material_override = bollard_dark
				p_root.add_child(rivet)

	# 6. Adaptive Steam Boost Valves (2 for straight rail, 3 for Y, 4 for Cross)
	var valve_nodes: Dictionary = {}
	var valve_positions: Array = cfg.valve_positions_for_teams(team_count) if (cfg != null and cfg.has_method("valve_positions_for_teams")) else [
		Vector2(0.0, -6.0), Vector2(0.0, 6.0),
	]
	for v_idx in range(valve_positions.size()):
		var vpos: Vector2 = valve_positions[v_idx] as Vector2
		var v_root := Node3D.new()
		v_root.name = "SteamValve_%d" % v_idx
		v_root.position = Vector3(vpos.x, 0.0, vpos.y)
		root.add_child(v_root)

		var pad := MeshInstance3D.new()
		pad.mesh = _cyl_mesh(1.38, 1.52, 0.12, 20)
		pad.position = Vector3(0.0, 0.06, 0.0)
		pad.material_override = trim_mat
		v_root.add_child(pad)

		_add_floor_decal(v_root, stain_tex, Vector3(0.0, 0.02, 0.0), Vector3(3.4, 0.45, 2.7), Color(0.18, 0.14, 0.12, 0.58), float(v_idx) * 1.1)

		var ped := MeshInstance3D.new()
		ped.mesh = _cyl_mesh(0.24, 0.32, 0.72, 12)
		ped.position = Vector3(0.0, 0.42, 0.0)
		ped.material_override = pipes_mat
		v_root.add_child(ped)

		var wheel := MeshInstance3D.new()
		wheel.mesh = _torus_mesh(0.32, 0.42, 16)
		wheel.position = Vector3(0.0, 0.80, 0.0)
		wheel.material_override = _make_mat(Color(0.95, 0.30, 0.14), 0.35, 0.35)
		v_root.add_child(wheel)

		var ring_mat := _make_mat(Color(1.0, 0.72, 0.22, 0.45), 0.0, 0.3, Color(1.0, 0.68, 0.18), 1.4, true, true)
		var ring_mesh := MeshInstance3D.new()
		ring_mesh.mesh = _torus_mesh(1.42, 1.62, 28)
		ring_mesh.position = Vector3(0.0, 0.09, 0.0)
		ring_mesh.scale = Vector3(1.0, 0.18, 1.0)
		ring_mesh.material_override = ring_mat
		v_root.add_child(ring_mesh)

		# Floor steam pipe connecting valve cleanly toward central rail / turntable hub
		var pipe_mat := _make_mat(Color(0.54, 0.46, 0.38), 0.48, 0.42, Color(1.0, 0.66, 0.18), 0.2)
		var to_center: Vector2 = -vpos
		var target_stop: float = 2.35 if team_count >= 3 else 1.15
		var pipe_len: float = maxf(0.8, to_center.length() - target_stop)
		var pipe_dir2: Vector2 = to_center.normalized() if to_center.length_squared() > 0.001 else Vector2(0.0, 1.0)
		var pipe_holder := Node3D.new()
		pipe_holder.rotation.y = atan2(-pipe_dir2.y, pipe_dir2.x)
		v_root.add_child(pipe_holder)

		var pipe := MeshInstance3D.new()
		pipe.mesh = _cyl_mesh(0.14, 0.14, pipe_len, 10)
		pipe.rotation.z = PI * 0.5
		pipe.position = Vector3(pipe_len * 0.5 + 0.45, 0.12, 0.0)
		pipe.material_override = pipe_mat
		pipe_holder.add_child(pipe)

		valve_nodes[v_idx] = {
			"root": v_root,
			"ring_mesh": ring_mesh,
			"ring_mat": ring_mat,
			"pipe_mat": pipe_mat,
		}

	# 7. Hero Bomb Cart Assembly (riveted brackets, cowcatcher plows, molten core bands, exhaust stacks, warhead glow)
	var cart_root := Node3D.new()
	cart_root.name = "BombCart"
	root.add_child(cart_root)

	var chassis := MeshInstance3D.new()
	chassis.mesh = _box_mesh(Vector3(2.20, 0.36, 1.42))
	chassis.position = Vector3(0.0, 0.42, 0.0)
	chassis.material_override = rust_mat
	cart_root.add_child(chassis)

	# Bolted steel corner brackets & chassis rivets
	var bracket_mesh := _box_mesh(Vector3(0.34, 0.40, 0.24))
	var cart_rivet_mesh := _cyl_mesh(0.05, 0.06, 0.06, 8)
	for br_x in [-1.02, 1.02]:
		for br_z in [-0.64, 0.64]:
			var bracket := MeshInstance3D.new()
			bracket.mesh = bracket_mesh
			bracket.position = Vector3(float(br_x), 0.43, float(br_z))
			bracket.material_override = dark_metal_mat
			cart_root.add_child(bracket)

			var c_rivet := MeshInstance3D.new()
			c_rivet.mesh = cart_rivet_mesh
			c_rivet.position = Vector3(float(br_x), 0.65, float(br_z))
			c_rivet.material_override = rail_steel_mat
			cart_root.add_child(c_rivet)

	for sz_side in [-0.73, 0.73]:
		var ctrl := MeshInstance3D.new()
		ctrl.mesh = _box_mesh(Vector3(1.55, 0.24, 0.06))
		ctrl.position = Vector3(0.0, 0.44, float(sz_side))
		ctrl.material_override = panel_mat
		cart_root.add_child(ctrl)

	# Angled iron cowcatcher bumpers with hazard striping
	for bx in [-1.18, 1.18]:
		var b_dir: float = -1.0 if bx < 0.0 else 1.0
		var bumper := MeshInstance3D.new()
		bumper.mesh = _box_mesh(Vector3(0.24, 0.22, 1.48))
		bumper.position = Vector3(float(bx), 0.44, 0.0)
		bumper.material_override = hazard_mat
		cart_root.add_child(bumper)

		var plow := MeshInstance3D.new()
		plow.mesh = _box_mesh(Vector3(0.32, 0.24, 1.42))
		plow.position = Vector3(float(bx) + b_dir * 0.10, 0.26, 0.0)
		plow.rotation.z = -b_dir * 0.42
		plow.material_override = dark_metal_mat
		cart_root.add_child(plow)

		for pz in [-0.52, 0.0, 0.52]:
			var plow_rib := MeshInstance3D.new()
			plow_rib.mesh = _box_mesh(Vector3(0.38, 0.14, 0.12))
			plow_rib.position = Vector3(float(bx) + b_dir * 0.14, 0.24, float(pz))
			plow_rib.rotation.z = -b_dir * 0.42
			plow_rib.material_override = hazard_mat
			cart_root.add_child(plow_rib)

	for nx in [-0.88, 0.88]:
		var n_dir: float = -1.0 if nx < 0.0 else 1.0
		for nz in [-0.46, 0.46]:
			var nozzle := MeshInstance3D.new()
			nozzle.mesh = _cyl_mesh(0.10, 0.16, 0.34, 12)
			nozzle.rotation.z = n_dir * PI * 0.5
			nozzle.position = Vector3(float(nx) + n_dir * 0.24, 0.52, float(nz))
			nozzle.material_override = pipes_mat
			cart_root.add_child(nozzle)

	# Dual short vertical exhaust stacks
	var stack_mesh := _cyl_mesh(0.075, 0.095, 0.54, 10)
	var stack_lip_mesh := _cyl_mesh(0.105, 0.085, 0.09, 10)
	for ez in [-0.56, 0.56]:
		var stack := MeshInstance3D.new()
		stack.mesh = stack_mesh
		stack.position = Vector3(-0.68, 0.84, float(ez))
		stack.rotation.z = 0.10
		stack.material_override = dark_metal_mat
		cart_root.add_child(stack)

		var stack_lip := MeshInstance3D.new()
		stack_lip.mesh = stack_lip_mesh
		stack_lip.position = Vector3(-0.71, 1.12, float(ez))
		stack_lip.rotation.z = 0.10
		stack_lip.material_override = rail_steel_mat
		cart_root.add_child(stack_lip)

	var cart_wheels: Array = []
	var wheel_mat := _make_mat(Color(0.24, 0.21, 0.20), 0.76, 0.36)
	var spoke_mat := _make_mat(Color(0.92, 0.68, 0.20), 0.42, 0.35)
	var wheel_cyl := _cyl_mesh(0.28, 0.28, 0.16, 16)
	var spoke_box := _box_mesh(Vector3(0.46, 0.07, 0.18))
	for wx in [-0.72, 0.72]:
		for wz in [-0.66, 0.66]:
			var w_node := Node3D.new()
			w_node.position = Vector3(float(wx), 0.28, float(wz))
			var w_mi := MeshInstance3D.new()
			w_mi.mesh = wheel_cyl
			w_mi.rotation.x = PI * 0.5
			w_mi.material_override = wheel_mat
			w_node.add_child(w_mi)
			var sp := MeshInstance3D.new()
			sp.mesh = spoke_box
			sp.material_override = spoke_mat
			w_node.add_child(sp)
			cart_root.add_child(w_node)
			cart_wheels.append(w_node)

	var cart_warhead_mat := _make_mat(Color(0.22, 0.19, 0.18), 0.68, 0.34, Color(1.0, 0.36, 0.12), 0.72)
	var warhead := MeshInstance3D.new()
	warhead.mesh = _cyl_mesh(0.54, 0.54, 1.56, 20)
	warhead.rotation.z = PI * 0.5
	warhead.position = Vector3(0.0, 1.04, 0.0)
	warhead.material_override = cart_warhead_mat
	cart_root.add_child(warhead)

	# Ribbed glowing molten warhead core bands + heavy clamping rings
	var molten_band_mat := _make_mat(Color(1.0, 0.58, 0.18), 0.15, 0.25, Color(1.0, 0.44, 0.12), 2.45)
	for mx_band in [-0.18, 0.18]:
		var m_band := MeshInstance3D.new()
		m_band.mesh = _cyl_mesh(0.562, 0.562, 0.11, 20)
		m_band.rotation.z = PI * 0.5
		m_band.position = Vector3(float(mx_band), 1.04, 0.0)
		m_band.material_override = molten_band_mat
		cart_root.add_child(m_band)

	for clamp_x in [-0.30, 0.0, 0.30]:
		var clamp_ring := MeshInstance3D.new()
		clamp_ring.mesh = _cyl_mesh(0.578, 0.578, 0.075, 20)
		clamp_ring.rotation.z = PI * 0.5
		clamp_ring.position = Vector3(float(clamp_x), 1.04, 0.0)
		clamp_ring.material_override = dark_metal_mat
		cart_root.add_child(clamp_ring)

	for ex in [-0.88, 0.88]:
		var endcap := MeshInstance3D.new()
		endcap.mesh = _cyl_mesh(0.32 if ex > 0.0 else 0.50, 0.50 if ex > 0.0 else 0.32, 0.26, 20)
		endcap.rotation.z = PI * 0.5
		endcap.position = Vector3(float(ex), 1.04, 0.0)
		endcap.material_override = trim_mat
		cart_root.add_child(endcap)

	for rx in [-0.48, 0.48]:
		var band := MeshInstance3D.new()
		band.mesh = _cyl_mesh(0.57, 0.57, 0.13, 20)
		band.rotation.z = PI * 0.5
		band.position = Vector3(float(rx), 1.04, 0.0)
		band.material_override = hazard_mat
		cart_root.add_child(band)

	var beacon_base := MeshInstance3D.new()
	beacon_base.mesh = _cyl_mesh(0.20, 0.24, 0.14, 14)
	beacon_base.position = Vector3(0.0, 1.60, 0.0)
	beacon_base.material_override = trim_mat
	cart_root.add_child(beacon_base)

	var beacon_dome := MeshInstance3D.new()
	beacon_dome.mesh = _cyl_mesh(0.14, 0.17, 0.18, 14)
	beacon_dome.position = Vector3(0.0, 1.74, 0.0)
	beacon_dome.material_override = amber_mat
	cart_root.add_child(beacon_dome)

	var cart_light := OmniLight3D.new()
	cart_light.name = "CartWarheadGlow"
	cart_light.position = Vector3(0.0, 1.55, 0.0)
	cart_light.omni_range = 6.2
	cart_light.light_color = Color(1.0, 0.46, 0.14)
	cart_light.light_energy = 1.9
	cart_light.shadow_enabled = false
	cart_root.add_child(cart_light)

	var push_aura_mat := _make_mat(Color(1.0, 0.82, 0.22, 0.42), 0.0, 0.4, Color(1.0, 0.78, 0.20), 1.5, true, true)
	var push_aura_mesh := MeshInstance3D.new()
	push_aura_mesh.name = "PushAura"
	push_aura_mesh.mesh = _torus_mesh(push_r - 0.14, push_r, 36)
	push_aura_mesh.position = Vector3(0.0, 0.05, 0.0)
	push_aura_mesh.scale = Vector3(1.0, 0.16, 1.0)
	push_aura_mesh.material_override = push_aura_mat
	push_aura_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cart_root.add_child(push_aura_mesh)

	var pulse_ring_mat := _make_mat(Color(1.0, 0.22, 0.14, 0.72), 0.0, 0.3, Color(1.0, 0.22, 0.14), 2.6, true, true)
	var pulse_ring_mesh := MeshInstance3D.new()
	pulse_ring_mesh.name = "PulseRing"
	pulse_ring_mesh.mesh = _torus_mesh(pulse_r - 0.18, pulse_r, 40)
	pulse_ring_mesh.position = Vector3(0.0, 0.08, 0.0)
	pulse_ring_mesh.scale = Vector3(1.0, 0.18, 1.0)
	pulse_ring_mesh.material_override = pulse_ring_mat
	pulse_ring_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pulse_ring_mesh.visible = false
	cart_root.add_child(pulse_ring_mesh)

	return {
		"root": root,
		"cart_root": cart_root,
		"cart_wheels": cart_wheels,
		"cart_warhead_mat": cart_warhead_mat,
		"push_aura_mesh": push_aura_mesh,
		"push_aura_mat": push_aura_mat,
		"pulse_ring_mesh": pulse_ring_mesh,
		"pulse_ring_mat": pulse_ring_mat,
		"valve_nodes": valve_nodes,
		"door_lights": door_lights,
		"door_nodes": door_nodes,
		"track_leds": track_leds,
		"turntable_node": turntable_node,
		"monitor_timer_label": backdrop_info.get("monitor_timer_label", null),
		"monitor_phase_label": backdrop_info.get("monitor_phase_label", null),
		"fans": backdrop_info.get("fans", []),
		"flicker_lamp_mat": backdrop_info.get("flicker_lamp_mat", null),
		"cart_light": cart_light,
	}


static func _customize_official_rig(rig: Node3D, net_id: int, team_id: int, customization: Array = []) -> StandardMaterial3D:
	var sk := rig.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var suit_mat: StandardMaterial3D = null
	if sk == null:
		return suit_mat

	var char_mesh := sk.get_node_or_null("character mesh") as MeshInstance3D
	if char_mesh != null:
		var suit_path: String = str(TEAM_SUIT_TEXTURES.get(team_id, TEAM_SUIT_TEXTURES[1]))
		var suit_tex = load_optional(suit_path)
		if suit_tex is Texture2D:
			suit_mat = StandardMaterial3D.new()
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
	return suit_mat


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


static func _team_prefix(team_id: int) -> String:
	var low: String = TranslationServer.get_locale().to_lower()
	var is_tw: bool = low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo")
	var is_cn: bool = not is_tw and (low.begins_with("zh") or low == "zhs")
	match team_id:
		1: return "[紅]" if is_tw else ("[红]" if is_cn else "[RED]")
		2: return "[藍]" if is_tw else ("[蓝]" if is_cn else "[BLU]")
		3: return "[綠]" if is_tw else ("[绿]" if is_cn else "[GRN]")
		4: return "[黃]" if is_tw else ("[黄]" if is_cn else "[YEL]")
		_: return "[T%d]" % team_id


static func build_player_mesh(
	team_id: int,
	is_local: bool,
	display_name: String,
	cfg,
	net_id: int = 1,
	customization: Array = []
) -> Dictionary:
	ensure_game_pck_mounted()
	var tcol: Color = _team_color(team_id, cfg)
	var root := Node3D.new()
	root.name = "Player_%s" % display_name

	var shadow := MeshInstance3D.new()
	shadow.name = "ShadowDisc"
	shadow.mesh = _cyl_mesh(0.44, 0.44, 0.02, 14)
	shadow.position = Vector3(0.0, 0.015, 0.0)
	shadow.material_override = _make_mat(Color(0.0, 0.0, 0.0, 0.44), 0.0, 1.0, Color.BLACK, 0.0, true, true)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shadow)

	var rig := Node3D.new()
	rig.name = "Rig"
	root.add_child(rig)

	var body_mat: StandardMaterial3D = _make_mat(tcol.lerp(Color(0.24, 0.21, 0.19), 0.32), 0.45, 0.42)
	var anim_player: AnimationPlayer = null
	var char_packed = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2.glb")
	if char_packed is PackedScene:
		var official_rig: Node3D = (char_packed as PackedScene).instantiate() as Node3D
		official_rig.name = "OfficialCharacterRig"
		official_rig.rotation_degrees.y = 180.0
		official_rig.scale = Vector3(0.42, 0.42, 0.42)
		rig.add_child(official_rig)
		var suit_mat: StandardMaterial3D = _customize_official_rig(official_rig, net_id, team_id, customization)
		if suit_mat != null:
			body_mat = suit_mat
		anim_player = _setup_official_animations(official_rig)
	else:
		var torso := MeshInstance3D.new()
		torso.mesh = _cyl_mesh(0.30, 0.34, 0.72, 12)
		torso.position = Vector3(0.0, 0.48, 0.0)
		torso.material_override = body_mat
		rig.add_child(torso)

		var head := MeshInstance3D.new()
		head.mesh = _box_mesh(Vector3(0.42, 0.36, 0.38))
		head.position = Vector3(0.0, 1.05, 0.0)
		head.material_override = _make_mat(Color(0.84, 0.80, 0.76), 0.30, 0.35)
		rig.add_child(head)

		var visor := MeshInstance3D.new()
		visor.mesh = _box_mesh(Vector3(0.32, 0.12, 0.08))
		visor.position = Vector3(0.0, 1.06, 0.20)
		visor.material_override = _make_mat(tcol, 0.2, 0.2, tcol, 2.2)
		rig.add_child(visor)

	var ring_mat := _make_mat(
		Color(tcol.r, tcol.g, tcol.b, 0.92 if is_local else 0.72),
		0.0, 0.2, tcol, 2.4 if is_local else 1.5, true, true
	)
	var ring := MeshInstance3D.new()
	ring.mesh = _torus_mesh(0.44, 0.56 if is_local else 0.52, 20)
	ring.position = Vector3(0.0, 0.04, 0.0)
	ring.scale = Vector3(1.0, 0.16, 1.0)
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)

	var lbl := Label3D.new()
	lbl.name = "NameLabel"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 44
	lbl.pixel_size = 0.0094
	lbl.position = Vector3(0.0, 2.30, 0.0)
	lbl.outline_size = 12
	lbl.outline_modulate = Color(0.04, 0.03, 0.02, 1.0)
	lbl.modulate = tcol.lightened(0.32)
	var term_font: Font = load_cjk_terminal_font()
	if term_font != null:
		lbl.font = term_font
	lbl.text = display_name if display_name.begins_with("[") else "%s %s" % [_team_prefix(team_id), display_name]
	root.add_child(lbl)

	return {
		"root": root,
		"rig": rig,
		"body_mat": body_mat,
		"ring_mat": ring_mat,
		"label": lbl,
		"anim_player": anim_player,
	}
