extends RefCounted

## Enclosed Green-Pea-grade Industrial Electric-Test-Chamber stage, towering rear-center
## High-Voltage Transformer + Analog Dial, Upper-Left CRT Monitor, Upper-Right Automated
## Penalty Arc Emitter + Strobe Beacon, gritty bolted-iron electric chairs, and 128x128 CRT icon
## for Voltage Greed (贪婪电椅 / 貪婪電椅).
## Zero references to Coach/Deagle GLBs (no invalid UID warnings); uses authentic vanilla PNG
## textures with TEXTURE_FILTER_NEAREST and crisp procedural fallbacks for headless/macOS.

const TEX_WALL_PANEL_A := "res://minigames/green_pea/models/pea dinner scene4/pea dinner scene4_metal wall panel3.png"
const TEX_WALL_PANEL_B := "res://minigames/green_pea/models/pea dinner scene4/pea dinner scene4_metal wall panel4.png"
const TEX_CHAIR_METAL := "res://minigames/green_pea/models/pea dinner scene4/pea dinner scene4_metal sheet2 chair.png"
const TEX_TABLE_METAL := "res://minigames/green_pea/models/pea dinner scene4/pea dinner scene4_metal sheet2 table.png"
const TEX_SHELF_METAL := "res://minigames/green_pea/models/pea dinner scene4/pea dinner scene4_metal shelf sheet2.png"
const TEX_CARDBOARD := "res://minigames/green_pea/models/pea dinner scene4/pea dinner scene4_cardboard box2.png"
const TEX_CONSOLE := "res://minigames/burn_recycle/models/burn recycle visuals6/burn recycle visuals6_metal sheet console1.png"
const TEX_FLOOR_TILES := "res://minigames/burn_recycle/models/burn recycle visuals6/burn recycle visuals6_bnr floor tiles.png"
const TEX_THREADPLATE := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate albedo.png"
const TEX_CONTROL_PANEL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_chisel gauntlet control panel1.png"
const TEX_HEAVY_RUST := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust2.png"

const ANIM_CHAR_SIT := "res://minigames/green_pea/animations/sitting_on_dinner_chair_idle.res"
const GLB_PLAYER := "res://minigames/exploding_collar_race/models/main character2/main character2.glb"

const SUIT_TEXTURES := [
	"res://modules/character_customization/character_customization_textures/main character painted red.png",
	"res://modules/character_customization/character_customization_textures/main character painted blue.png",
	"res://modules/character_customization/character_customization_textures/main character painted green.png",
	"res://modules/character_customization/character_customization_textures/main character painted yellow.png",
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
		"Noto Sans CJK TC", "Noto Sans CJK SC", "Heiti TC", "Helvetica Neue", "Arial",
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
	metallic: float = 0.25,
	roughness: float = 0.86,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0,
	alpha: bool = false,
	unshaded: bool = false,
	tex_path: String = "",
	uv_scale: Vector3 = Vector3.ONE
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
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_scale = uv_scale
	return mat


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


static func _sphere_mesh(radius: float, height: float, segs: int = 14) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = segs
	m.rings = 8
	return m


static func _torus_mesh(inner_r: float, outer_r: float, rings: int = 28) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner_r
	m.outer_radius = outer_r
	m.rings = rings
	m.ring_segments = 8
	return m


static func _draw_line_px(img: Image, p0: Vector2, p1: Vector2, col: Color, thickness: float) -> void:
	var steps: int = maxi(4, int(ceil(p0.distance_to(p1) * 1.6)))
	var r: float = thickness * 0.5
	var r_ceil: int = int(ceil(r))
	var w: int = img.get_width()
	var h: int = img.get_height()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var pt: Vector2 = p0.lerp(p1, t)
		for dy in range(-r_ceil, r_ceil + 1):
			for dx in range(-r_ceil, r_ceil + 1):
				if float(dx * dx + dy * dy) <= r * r + 0.15:
					var px: int = int(round(pt.x)) + dx
					var py: int = int(round(pt.y)) + dy
					if px >= 0 and px < w and py >= 0 and py < h:
						img.set_pixel(px, py, col)


static func build_voltage_greed_icon() -> Texture2D:
	# 128x128 industrial electric-chair & analog overload needle-gauge CRT icon.
	var w: int = 128
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.06, 0.05, 1.0))

	for y in range(h):
		for x in range(w):
			if x < 5 or x >= w - 5 or y < 5 or y >= h - 5:
				var is_rivet: bool = ((x < 10 or x >= w - 10) and (y < 10 or y >= h - 10))
				img.set_pixel(x, y, Color(1.0, 0.80, 0.28, 1.0) if is_rivet else Color(0.68, 0.42, 0.14, 1.0))
				continue
			var gx: float = (float(x) - 64.0) / 56.0
			var gy: float = (float(y) - 52.0) / 56.0
			var gd2: float = gx * gx + gy * gy
			if gd2 < 1.0:
				var glow: float = (1.0 - gd2) * 0.24
				img.set_pixel(x, y, Color(0.08 + glow * 1.15, 0.06 + glow * 0.56, 0.05 + glow * 0.12, 1.0))

			var dx: float = float(x) - 64.0
			var dy: float = float(y) - 58.0
			var dist: float = sqrt(dx * dx + dy * dy)
			if dy <= 6.0 and dist >= 27.0 and dist <= 38.0:
				var ang: float = atan2(-dy, dx)
				if ang >= -0.15 and ang <= PI + 0.15:
					if ang < PI * 0.32:
						img.set_pixel(x, y, Color(1.0, 0.24, 0.14, 1.0))
					elif ang < PI * 0.62:
						img.set_pixel(x, y, Color(1.0, 0.72, 0.18, 1.0))
					else:
						img.set_pixel(x, y, Color(0.45, 0.88, 0.44, 1.0))
			elif dy <= 6.0 and dist < 27.0:
				img.set_pixel(x, y, Color(0.13, 0.11, 0.10, 1.0))

			if y >= 72 and y <= 104 and absf(float(x - 64)) <= 18.0:
				if y <= 84 and absf(float(x - 64)) <= 12.0:
					img.set_pixel(x, y, Color(0.32, 0.26, 0.22, 1.0))
				elif y >= 85 and y <= 93:
					img.set_pixel(x, y, Color(0.56, 0.44, 0.28, 1.0))
				elif y > 93 and (absf(float(x - 51)) <= 3.0 or absf(float(x - 77)) <= 3.0):
					img.set_pixel(x, y, Color(0.42, 0.36, 0.32, 1.0))
			if y >= 63 and y <= 70 and absf(float(x - 64)) <= 10.0:
				img.set_pixel(x, y, Color(0.95, 0.68, 0.20, 1.0))
			if y >= 105 and y <= 113 and x >= 18 and x <= w - 19:
				var stripe: bool = ((x + y) / 6) % 2 == 0
				img.set_pixel(x, y, Color(0.98, 0.72, 0.14, 1.0) if stripe else Color(0.15, 0.12, 0.10, 1.0))

	_draw_line_px(img, Vector2(64.0, 58.0), Vector2(89.0, 34.0), Color(1.0, 0.24, 0.12, 1.0), 4.0)
	_draw_line_px(img, Vector2(64.0, 58.0), Vector2(64.0, 58.0), Color(1.0, 0.88, 0.34, 1.0), 8.0)

	_draw_line_px(img, Vector2(24.0, 58.0), Vector2(36.0, 74.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(36.0, 74.0), Vector2(27.0, 78.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(27.0, 78.0), Vector2(40.0, 96.0), Color(1.0, 0.94, 0.45, 1.0), 3.0)

	_draw_line_px(img, Vector2(104.0, 58.0), Vector2(92.0, 74.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(92.0, 74.0), Vector2(101.0, 78.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(101.0, 78.0), Vector2(88.0, 96.0), Color(1.0, 0.94, 0.45, 1.0), 3.0)

	return ImageTexture.create_from_image(img)


static func build_stage(parent: Node3D, cfg_script) -> Dictionary:
	ensure_game_pck_mounted()

	var root := Node3D.new()
	root.name = "VoltageGreedStage"
	if parent != null:
		parent.add_child(root)

	var cjk_font: Font = load_cjk_terminal_font()

	# Authentic Green Pea / Burn Recycle enclosed industrial materials (NEAREST, matte-rough)
	var floor_tex_path: String = TEX_FLOOR_TILES if ResourceLoader.exists(TEX_FLOOR_TILES) else TEX_THREADPLATE
	var floor_mat := _make_mat(Color(0.84, 0.84, 0.82), 0.16, 0.88, Color.BLACK, 0.0, false, false, floor_tex_path, Vector3(6.0, 6.0, 1.0))
	var wall_mat := _make_mat(Color(0.86, 0.88, 0.88), 0.18, 0.89, Color.BLACK, 0.0, false, false, TEX_WALL_PANEL_A, Vector3(3.0, 2.0, 1.0))
	var door_wall_mat := _make_mat(Color(0.86, 0.88, 0.88), 0.18, 0.89, Color.BLACK, 0.0, false, false, TEX_WALL_PANEL_B, Vector3(1.0, 1.0, 1.0))
	var side_wall_mat := _make_mat(Color(0.82, 0.84, 0.85), 0.18, 0.89, Color.BLACK, 0.0, false, false, TEX_WALL_PANEL_A, Vector3(4.0, 2.0, 1.0))
	var ceiling_mat := _make_mat(Color(0.24, 0.25, 0.26), 0.30, 0.88, Color.BLACK, 0.0, false, false, TEX_TABLE_METAL, Vector3(4.0, 4.0, 1.0))
	var dark_steel_mat := _make_mat(Color(0.55, 0.56, 0.58), 0.36, 0.82, Color.BLACK, 0.0, false, false, TEX_TABLE_METAL, Vector3(2.0, 2.0, 1.0))
	var beam_mat := _make_mat(Color(0.32, 0.34, 0.36), 0.45, 0.78, Color.BLACK, 0.0, false, false, TEX_CHAIR_METAL, Vector3(3.0, 1.0, 1.0))
	var cabinet_mat := _make_mat(Color(0.72, 0.74, 0.74), 0.34, 0.82, Color.BLACK, 0.0, false, false, TEX_CHAIR_METAL, Vector3(2.0, 2.0, 1.0))
	var console_mat := _make_mat(Color(0.82, 0.82, 0.80), 0.28, 0.76, Color.BLACK, 0.0, false, false, TEX_CONSOLE if ResourceLoader.exists(TEX_CONSOLE) else TEX_CONTROL_PANEL, Vector3(1.0, 1.0, 1.0))
	var shelf_mat := _make_mat(Color(0.78, 0.78, 0.76), 0.32, 0.82, Color.BLACK, 0.0, false, false, TEX_SHELF_METAL, Vector3(1.5, 1.5, 1.0))
	var box_mat := _make_mat(Color(0.88, 0.84, 0.78), 0.05, 0.88, Color.BLACK, 0.0, false, false, TEX_CARDBOARD, Vector3(1.0, 1.0, 1.0))
	var hazard_mat := _make_mat(Color(0.86, 0.62, 0.16), 0.18, 0.74)
	var copper_mat := _make_mat(Color(0.78, 0.46, 0.24), 0.82, 0.34)
	var ceramic_mat := _make_mat(Color(0.84, 0.82, 0.76), 0.12, 0.32)
	var cable_mat := _make_mat(Color(0.11, 0.11, 0.12), 0.20, 0.78)

	# 1. Enclosed Green-Pea-Style Industrial Chamber (12.6m wide x 13.0m deep x 6.2m high)
	# Back wall z=-4.2, side walls x=+-6.3, front wall z=+8.8, floor y=0.0, ceiling y=6.2
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "ChamberFloor"
	floor_mi.mesh = _box_mesh(Vector3(12.6, 0.3, 13.0))
	floor_mi.position = Vector3(0.0, -0.15, 2.3)
	floor_mi.material_override = floor_mat
	root.add_child(floor_mi)

	var ceiling_mi := MeshInstance3D.new()
	ceiling_mi.name = "ChamberCeiling"
	ceiling_mi.mesh = _box_mesh(Vector3(12.8, 0.3, 13.2))
	ceiling_mi.position = Vector3(0.0, 6.35, 2.3)
	ceiling_mi.material_override = ceiling_mat
	root.add_child(ceiling_mi)

	# Dark ceiling steel I-beams (above y=5.55 so ceiling OmniLight3Ds at y=5.2 illuminate unhindered)
	for bz in [-2.6, -0.2, 2.2, 4.6]:
		var ibeam := MeshInstance3D.new()
		ibeam.mesh = _box_mesh(Vector3(12.6, 0.36, 0.28))
		ibeam.position = Vector3(0.0, 6.02, float(bz))
		ibeam.material_override = beam_mat
		root.add_child(ibeam)

	# Back wall z=-4.2 (composed of 3 riveted wall panels)
	for bpi in range(3):
		var px: float = (float(bpi) - 1.0) * 4.2
		var bpanel := MeshInstance3D.new()
		bpanel.name = "BackWallPanel_%d" % bpi
		bpanel.mesh = _box_mesh(Vector3(4.2, 6.2, 0.30))
		bpanel.position = Vector3(px, 3.1, -4.35)
		bpanel.material_override = door_wall_mat if bpi == 1 else wall_mat
		root.add_child(bpanel)

	# Front wall behind camera z=+8.8
	var front_wall := MeshInstance3D.new()
	front_wall.name = "FrontWall"
	front_wall.mesh = _box_mesh(Vector3(12.6, 6.2, 0.30))
	front_wall.position = Vector3(0.0, 3.1, 8.95)
	front_wall.material_override = wall_mat
	root.add_child(front_wall)

	# Side walls x=+-6.3
	for side in [-1.0, 1.0]:
		var sw := MeshInstance3D.new()
		sw.name = "SideWall_%s" % ("L" if side < 0.0 else "R")
		sw.mesh = _box_mesh(Vector3(0.30, 6.2, 13.0))
		sw.position = Vector3(float(side) * 6.45, 3.1, 2.3)
		sw.material_override = side_wall_mat
		root.add_child(sw)

	# Structural wall pillars & horizontal wall conduit pipes
	for px in [-6.10, -2.15, 2.15, 6.10]:
		var pil := MeshInstance3D.new()
		pil.mesh = _box_mesh(Vector3(0.32, 6.2, 0.32))
		pil.position = Vector3(float(px), 3.1, -4.10)
		pil.material_override = beam_mat
		root.add_child(pil)

	for py in [1.65, 4.95]:
		var pipe := MeshInstance3D.new()
		pipe.mesh = _cyl_mesh(0.11, 0.11, 12.2, 10)
		pipe.rotation.z = PI * 0.5
		pipe.position = Vector3(0.0, float(py), -4.02)
		pipe.material_override = beam_mat
		root.add_child(pipe)

	# Side industrial clutter (shelves, cardboard crates, consoles — tucked cleanly at x=+-5.1..5.7)
	for side in [-1.0, 1.0]:
		var sx: float = float(side) * 5.35
		# Steel shelf frame
		var shelf := Node3D.new()
		shelf.position = Vector3(sx, 0.0, -2.3)
		shelf.rotation.y = -float(side) * 0.12
		root.add_child(shelf)
		for lx in [-0.65, 0.65]:
			for lz in [-0.35, 0.35]:
				var post := MeshInstance3D.new()
				post.mesh = _box_mesh(Vector3(0.08, 2.6, 0.08))
				post.position = Vector3(float(lx), 1.3, float(lz))
				post.material_override = beam_mat
				shelf.add_child(post)
		for sy in [0.45, 1.35, 2.25]:
			var plank := MeshInstance3D.new()
			plank.mesh = _box_mesh(Vector3(1.42, 0.07, 0.80))
			plank.position = Vector3(0.0, float(sy), 0.0)
			plank.material_override = shelf_mat
			shelf.add_child(plank)

		# Cardboard boxes stacked along outer walls
		var crate_a := MeshInstance3D.new()
		crate_a.mesh = _box_mesh(Vector3(0.85, 0.72, 0.78))
		crate_a.position = Vector3(float(side) * 5.25, 0.36, 0.45)
		crate_a.rotation.y = float(side) * 0.25
		crate_a.material_override = box_mat
		root.add_child(crate_a)

		var crate_b := MeshInstance3D.new()
		crate_b.mesh = _box_mesh(Vector3(0.64, 0.56, 0.62))
		crate_b.position = Vector3(float(side) * 5.20, 1.00, 0.42)
		crate_b.rotation.y = -float(side) * 0.18
		crate_b.material_override = box_mat
		root.add_child(crate_b)

		var crate_top := MeshInstance3D.new()
		crate_top.mesh = _box_mesh(Vector3(0.58, 0.48, 0.54))
		crate_top.position = Vector3(sx - float(side) * 0.05, 1.62, -2.3)
		crate_top.material_override = box_mat
		root.add_child(crate_top)

		# Side breaker console
		var side_con := MeshInstance3D.new()
		side_con.mesh = _box_mesh(Vector3(0.75, 1.35, 1.15))
		side_con.position = Vector3(float(side) * 5.65, 0.675, -0.75)
		side_con.material_override = console_mat
		root.add_child(side_con)

	# Flickering ceiling fluorescent tube fixtures (cold industrial white-cyan tint)
	var fluorescent_mats: Array = []
	for fpos in [Vector3(-2.6, 5.88, -1.6), Vector3(2.6, 5.88, -1.6), Vector3(-2.6, 5.88, 2.2), Vector3(2.6, 5.88, 2.2)]:
		var p3: Vector3 = fpos as Vector3
		var hood := MeshInstance3D.new()
		hood.mesh = _box_mesh(Vector3(2.0, 0.14, 0.28))
		hood.position = p3
		hood.material_override = beam_mat
		root.add_child(hood)

		var f_mat := _make_mat(Color(0.86, 0.94, 0.94), 0.05, 0.25, Color(0.76, 0.90, 0.92), 1.35)
		fluorescent_mats.append(f_mat)

		var tube := MeshInstance3D.new()
		tube.mesh = _cyl_mesh(0.06, 0.06, 1.85, 10)
		tube.rotation.z = PI * 0.5
		tube.position = p3 + Vector3(0.0, -0.07, 0.0)
		tube.material_override = f_mat
		root.add_child(tube)

	# 2. Authentic Green-Pea Lighting: 2 cold-cyan shadow-casting overhead ceiling pools + 1 warm dial accent
	var pool_back := OmniLight3D.new()
	pool_back.name = "CeilingPoolBack"
	pool_back.position = Vector3(0.0, 5.2, -1.6)
	pool_back.light_color = Color(0.68, 0.81, 0.82)
	pool_back.light_energy = 9.0
	pool_back.omni_range = 12.0
	pool_back.shadow_enabled = true
	pool_back.shadow_bias = 0.075
	pool_back.shadow_blur = 1.5
	root.add_child(pool_back)

	var pool_front := OmniLight3D.new()
	pool_front.name = "CeilingPoolFront"
	pool_front.position = Vector3(0.0, 5.2, 2.6)
	pool_front.light_color = Color(0.68, 0.81, 0.82)
	pool_front.light_energy = 9.0
	pool_front.omni_range = 12.0
	pool_front.shadow_enabled = true
	pool_front.shadow_bias = 0.075
	pool_front.shadow_blur = 1.5
	root.add_child(pool_front)

	var dial_accent := OmniLight3D.new()
	dial_accent.name = "DialWarmAccent"
	dial_accent.position = Vector3(0.0, 3.2, -2.5)
	dial_accent.light_color = Color(1.0, 0.72, 0.34)
	dial_accent.light_energy = 1.4
	dial_accent.omni_range = 6.5
	dial_accent.shadow_enabled = false
	root.add_child(dial_accent)

	# 3. Back-Row Steel Grating Riser (y=0.92, z=-1.80..-0.78, x=-4.2..+4.2; clears front row cleanly)
	var riser_root := Node3D.new()
	riser_root.name = "BackRowRiser"
	root.add_child(riser_root)

	var riser_deck := MeshInstance3D.new()
	riser_deck.mesh = _box_mesh(Vector3(8.4, 0.92, 1.04))
	riser_deck.position = Vector3(0.0, 0.46, -1.30)
	riser_deck.material_override = dark_steel_mat
	riser_root.add_child(riser_deck)

	var riser_lip := MeshInstance3D.new()
	riser_lip.mesh = _box_mesh(Vector3(8.44, 0.09, 0.12))
	riser_lip.position = Vector3(0.0, 0.88, -0.80)
	riser_lip.material_override = hazard_mat
	riser_root.add_child(riser_lip)

	# 4. Towering Rear-Center High-Voltage Transformer at (0, 0, -3.55)
	var tf_root := Node3D.new()
	tf_root.name = "CentralTransformer"
	tf_root.position = Vector3(0.0, 0.0, -3.55)
	root.add_child(tf_root)

	var tf_plinth := MeshInstance3D.new()
	tf_plinth.mesh = _box_mesh(Vector3(3.1, 0.35, 1.25))
	tf_plinth.position = Vector3(0.0, 0.175, 0.0)
	tf_plinth.material_override = beam_mat
	tf_root.add_child(tf_plinth)

	var tf_cabinet := MeshInstance3D.new()
	tf_cabinet.mesh = _box_mesh(Vector3(2.65, 2.80, 0.96))
	tf_cabinet.position = Vector3(0.0, 1.75, 0.0)
	tf_cabinet.material_override = cabinet_mat
	tf_root.add_child(tf_cabinet)

	var tf_console := MeshInstance3D.new()
	tf_console.mesh = _box_mesh(Vector3(2.10, 1.35, 0.10))
	tf_console.position = Vector3(0.0, 1.25, 0.50)
	tf_console.material_override = console_mat
	tf_root.add_child(tf_console)

	# Cooling radiator fins & twin HV ceramic bushings + copper coils
	for fx in [-1.42, 1.42]:
		for fi in range(3):
			var fin := MeshInstance3D.new()
			fin.mesh = _box_mesh(Vector3(0.18, 2.0, 0.14))
			fin.position = Vector3(float(fx), 1.75, -0.26 + float(fi) * 0.26)
			fin.material_override = beam_mat
			tf_root.add_child(fin)

	for cx in [-0.95, 0.95]:
		var ins := MeshInstance3D.new()
		ins.mesh = _cyl_mesh(0.18, 0.22, 0.44, 12)
		ins.position = Vector3(float(cx), 3.38, 0.05)
		ins.material_override = ceramic_mat
		tf_root.add_child(ins)

		var coil := MeshInstance3D.new()
		coil.mesh = _cyl_mesh(0.14, 0.14, 0.26, 12)
		coil.position = Vector3(float(cx), 3.70, 0.05)
		coil.material_override = copper_mat
		tf_root.add_child(coil)

	# Overhead Copper HV Busbar spanning transformer crown & chair feeder conduits
	var busbar := MeshInstance3D.new()
	busbar.name = "OverheadHVBusbar"
	busbar.mesh = _cyl_mesh(0.085, 0.085, 7.6, 12)
	busbar.rotation.z = PI * 0.5
	busbar.position = Vector3(0.0, 3.92, 0.20)
	busbar.material_override = copper_mat
	tf_root.add_child(busbar)

	var center_terminal := MeshInstance3D.new()
	center_terminal.mesh = _torus_mesh(0.22, 0.34, 20)
	center_terminal.position = Vector3(0.0, 3.92, 0.20)
	center_terminal.material_override = copper_mat
	tf_root.add_child(center_terminal)

	var transformer_top := Vector3(0.0, 3.92, -3.35)

	# Giant Recessed Analog Overload Dial centered at world (0.0, 2.78, -3.10) — clearly ABOVE players' heads
	var dial_hub := Node3D.new()
	dial_hub.name = "AnalogDialAssembly"
	dial_hub.position = Vector3(0.0, 2.78, 0.45)
	tf_root.add_child(dial_hub)

	var dial_rim := MeshInstance3D.new()
	dial_rim.mesh = _cyl_mesh(0.92, 0.98, 0.24, 32)
	dial_rim.rotation.x = PI * 0.5
	dial_rim.material_override = beam_mat
	dial_hub.add_child(dial_rim)

	var gauge_glow_mat := _make_mat(Color(0.56, 0.52, 0.42), 0.04, 0.72, Color(0.28, 0.22, 0.10), 0.08)
	var dial_face := MeshInstance3D.new()
	dial_face.mesh = _cyl_mesh(0.80, 0.80, 0.06, 32)
	dial_face.rotation.x = PI * 0.5
	dial_face.position = Vector3(0.0, 0.0, 0.11)
	dial_face.material_override = gauge_glow_mat
	dial_hub.add_child(dial_face)

	var safe_tick_mat := _make_mat(Color(0.10, 0.14, 0.10), 0.1, 0.7)
	var warn_tick_mat := _make_mat(Color(0.96, 0.52, 0.10), 0.1, 0.4, Color(0.96, 0.48, 0.08), 0.55)
	var danger_tick_mat := _make_mat(Color(0.98, 0.14, 0.10), 0.1, 0.3, Color(0.98, 0.12, 0.08), 0.95)
	for ti in range(11):
		var frac: float = float(ti) / 10.0
		var tick_ang: float = lerpf(-0.95, 0.95, frac)
		var tick_mat: StandardMaterial3D = safe_tick_mat
		if frac >= 0.70:
			tick_mat = danger_tick_mat
		elif frac >= 0.50:
			tick_mat = warn_tick_mat
		var tick := MeshInstance3D.new()
		tick.mesh = _box_mesh(Vector3(0.05, 0.17 if (ti % 2 == 0) else 0.11, 0.04))
		tick.position = Vector3(sin(tick_ang) * 0.62, cos(tick_ang) * 0.62 - 0.10, 0.15)
		tick.rotation.z = -tick_ang
		tick.material_override = tick_mat
		dial_hub.add_child(tick)

	var needle_pivot := Node3D.new()
	needle_pivot.name = "GaugeNeedlePivot"
	needle_pivot.position = Vector3(0.0, -0.12, 0.17)
	needle_pivot.rotation.z = 0.95
	dial_hub.add_child(needle_pivot)

	var needle_blade := MeshInstance3D.new()
	needle_blade.mesh = _box_mesh(Vector3(0.055, 0.70, 0.035))
	needle_blade.position = Vector3(0.0, 0.29, 0.0)
	needle_blade.material_override = _make_mat(Color(0.96, 0.16, 0.10), 0.2, 0.25, Color(1.0, 0.22, 0.10), 1.0)
	needle_pivot.add_child(needle_blade)

	var needle_cap := MeshInstance3D.new()
	needle_cap.mesh = _cyl_mesh(0.11, 0.11, 0.07, 16)
	needle_cap.rotation.x = PI * 0.5
	needle_cap.material_override = beam_mat
	needle_pivot.add_child(needle_cap)

	# 5. Upper-Left Back Wall Industrial CRT Telemetry Monitor at (-3.35, 3.35, -3.65)
	var crt_root := Node3D.new()
	crt_root.name = "WallCRTMonitor"
	crt_root.position = Vector3(-3.35, 3.35, -3.65)
	crt_root.rotation.y = 0.18
	root.add_child(crt_root)

	var crt_bracket := MeshInstance3D.new()
	crt_bracket.mesh = _box_mesh(Vector3(0.32, 0.32, 0.70))
	crt_bracket.position = Vector3(0.0, 0.0, -0.35)
	crt_bracket.material_override = beam_mat
	crt_root.add_child(crt_bracket)

	var crt_case := MeshInstance3D.new()
	crt_case.mesh = _box_mesh(Vector3(2.45, 1.32, 0.42))
	crt_case.material_override = cabinet_mat
	crt_root.add_child(crt_case)

	var crt_bezel := MeshInstance3D.new()
	crt_bezel.mesh = _box_mesh(Vector3(2.26, 1.12, 0.08))
	crt_bezel.position = Vector3(0.0, 0.0, 0.20)
	crt_bezel.material_override = _make_mat(Color(0.07, 0.07, 0.06), 0.3, 0.7)
	crt_root.add_child(crt_bezel)

	var crt_screen := MeshInstance3D.new()
	crt_screen.mesh = _box_mesh(Vector3(2.10, 0.96, 0.04))
	crt_screen.position = Vector3(0.0, 0.0, 0.23)
	crt_screen.material_override = _make_mat(Color(0.03, 0.04, 0.02), 0.1, 0.3, Color(0.14, 0.22, 0.06), 0.30)
	crt_root.add_child(crt_screen)

	var crt_label := Label3D.new()
	crt_label.name = "CRTMainLabel"
	crt_label.text = "0%"
	crt_label.font_size = 76
	crt_label.pixel_size = 0.0072
	crt_label.modulate = Color(1.0, 0.80, 0.24)
	crt_label.outline_modulate = Color(0.03, 0.03, 0.01)
	crt_label.outline_size = 12
	if cjk_font != null:
		crt_label.font = cjk_font
	crt_label.position = Vector3(0.0, 0.14, 0.27)
	crt_root.add_child(crt_label)

	var crt_sub_label := Label3D.new()
	crt_sub_label.name = "CRTSubLabel"
	crt_sub_label.text = "R1/3  16.0s"
	crt_sub_label.font_size = 34
	crt_sub_label.pixel_size = 0.0068
	crt_sub_label.modulate = Color(0.66, 0.94, 0.62)
	crt_sub_label.outline_modulate = Color(0.03, 0.03, 0.01)
	crt_sub_label.outline_size = 9
	if cjk_font != null:
		crt_sub_label.font = cjk_font
	crt_sub_label.position = Vector3(0.0, -0.26, 0.27)
	crt_root.add_child(crt_sub_label)

	# 6. Upper-Right Back Wall Automated High-Voltage Penalty Arc Emitter & Red Strobe Beacon
	var emitter_pos := Vector3(3.35, 3.35, -3.65)
	var emitter_root := Node3D.new()
	emitter_root.name = "PenaltyArcEmitter"
	emitter_root.position = emitter_pos
	emitter_root.rotation.y = -0.18
	root.add_child(emitter_root)

	var em_mount := MeshInstance3D.new()
	em_mount.mesh = _box_mesh(Vector3(1.15, 1.15, 0.52))
	em_mount.position = Vector3(0.0, 0.0, -0.24)
	em_mount.material_override = beam_mat
	emitter_root.add_child(em_mount)

	var em_face := MeshInstance3D.new()
	em_face.mesh = _box_mesh(Vector3(0.96, 0.96, 0.08))
	em_face.position = Vector3(0.0, 0.0, 0.04)
	em_face.material_override = console_mat
	emitter_root.add_child(em_face)

	var em_coil := MeshInstance3D.new()
	em_coil.mesh = _cyl_mesh(0.14, 0.20, 0.42, 14)
	em_coil.rotation.x = PI * 0.5
	em_coil.position = Vector3(0.0, -0.12, 0.28)
	em_coil.material_override = copper_mat
	emitter_root.add_child(em_coil)

	var em_tip := MeshInstance3D.new()
	em_tip.mesh = _torus_mesh(0.14, 0.22, 16)
	em_tip.rotation.x = PI * 0.5
	em_tip.position = Vector3(0.0, -0.12, 0.50)
	em_tip.material_override = copper_mat
	emitter_root.add_child(em_tip)

	var penalty_emitter_pos: Vector3 = emitter_pos + Vector3(-0.08, -0.12, 0.50)

	var beacon_mat := _make_mat(Color(0.88, 0.18, 0.12), 0.15, 0.22, Color(1.0, 0.20, 0.10), 0.65)
	var beacon_dome := MeshInstance3D.new()
	beacon_dome.name = "OverloadBeaconMesh"
	beacon_dome.mesh = _cyl_mesh(0.16, 0.20, 0.30, 16)
	beacon_dome.position = Vector3(0.0, 0.72, 0.0)
	beacon_dome.material_override = beacon_mat
	emitter_root.add_child(beacon_dome)

	var beacon_light := OmniLight3D.new()
	beacon_light.name = "OverloadBeaconLight"
	beacon_light.light_color = Color(1.0, 0.24, 0.14)
	beacon_light.light_energy = 0.0
	beacon_light.omni_range = 10.0
	beacon_light.shadow_enabled = false
	beacon_light.position = Vector3(0.0, 0.85, 0.30)
	emitter_root.add_child(beacon_light)

	# Heavy floor conduit cables leading forward from transformer cabinet
	for cx_off in [-1.2, -0.4, 0.4, 1.2]:
		var cable := MeshInstance3D.new()
		cable.mesh = _cyl_mesh(0.045, 0.045, 2.8, 8)
		cable.rotation.x = PI * 0.5
		cable.position = Vector3(float(cx_off), 0.03, -2.0)
		cable.material_override = cable_mat
		root.add_child(cable)

	if cfg_script != null:
		pass

	return {
		"root": root,
		"needle_pivot": needle_pivot,
		"gauge_glow_mat": gauge_glow_mat,
		"beacon_light": beacon_light,
		"beacon_mat": beacon_mat,
		"crt_label": crt_label,
		"crt_sub_label": crt_sub_label,
		"transformer_top": transformer_top,
		"penalty_emitter_pos": penalty_emitter_pos,
		"fluorescent_mats": fluorescent_mats,
	}


static func _customize_official_seated_rig(
	rig: Node3D,
	seat_index: int,
	accent_color: Color,
	customization: Array
) -> Dictionary:
	var overlay_mats: Array = []
	var sk := rig.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if sk != null:
		var char_mesh := sk.get_node_or_null("character mesh") as MeshInstance3D
		if char_mesh != null:
			var suit_mat := StandardMaterial3D.new()
			suit_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			var suit_tex = load_optional(SUIT_TEXTURES[absi(seat_index) % SUIT_TEXTURES.size()])
			if suit_tex is Texture2D:
				suit_mat.albedo_texture = suit_tex as Texture2D
				suit_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			suit_mat.albedo_color = accent_color.lightened(0.25)
			suit_mat.metallic = 0.04
			suit_mat.roughness = 0.82
			char_mesh.set_surface_override_material(0, suit_mat)
			overlay_mats.append(suit_mat)

			var hands_tex = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2_main character hands boots.png")
			if hands_tex is Texture2D:
				var hands_mat := StandardMaterial3D.new()
				hands_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				hands_mat.albedo_texture = hands_tex as Texture2D
				hands_mat.roughness = 0.80
				hands_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				char_mesh.set_surface_override_material(1, hands_mat)
				overlay_mats.append(hands_mat)

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
			hat_cfg = HAT_COSMETICS[absi(seat_index) % HAT_COSMETICS.size()]
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
		elif GLASSES_COSMETICS.has(absi(seat_index) % 8):
			gl_cfg = GLASSES_COSMETICS[absi(seat_index) % 8]
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

	var ap := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap != null:
		var sit_anim = load_optional(ANIM_CHAR_SIT)
		if sit_anim is Animation:
			var lib := AnimationLibrary.new()
			var dup_sit: Animation = (sit_anim as Animation).duplicate()
			dup_sit.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation(&"sit", dup_sit)
			ap.add_animation_library(&"vg_sit", lib)
			ap.play(&"vg_sit/sit")

	return {"mats": overlay_mats}


static func _build_procedural_seated_char(
	seat_index: int,
	accent_color: Color,
	customization: Array
) -> Dictionary:
	var body_root := Node3D.new()
	body_root.name = "SeatedCharacter"

	var suit_mat := _make_mat(accent_color.lerp(Color(0.22, 0.20, 0.19), 0.28), 0.14, 0.68)
	var pants_mat := _make_mat(Color(0.18, 0.17, 0.18), 0.12, 0.78)
	var skin_mat := _make_mat(Color(0.90, 0.76, 0.62), 0.04, 0.70)
	var boot_mat := _make_mat(Color(0.12, 0.10, 0.09), 0.22, 0.68)
	var overlay_mats: Array = [suit_mat, skin_mat]

	# Seated thighs + shins + boots (+Z forward toward camera)
	for sx in [-0.14, 0.14]:
		var thigh := MeshInstance3D.new()
		thigh.mesh = _cyl_mesh(0.095, 0.09, 0.40, 10)
		thigh.rotation.x = PI * 0.5
		thigh.position = Vector3(float(sx), 0.55, 0.16)
		thigh.material_override = pants_mat
		body_root.add_child(thigh)

		var shin := MeshInstance3D.new()
		shin.mesh = _cyl_mesh(0.085, 0.075, 0.44, 10)
		shin.position = Vector3(float(sx), 0.32, 0.34)
		shin.material_override = pants_mat
		body_root.add_child(shin)

		var boot := MeshInstance3D.new()
		boot.mesh = _box_mesh(Vector3(0.14, 0.10, 0.22))
		boot.position = Vector3(float(sx), 0.08, 0.38)
		boot.material_override = boot_mat
		body_root.add_child(boot)

	var torso := MeshInstance3D.new()
	torso.mesh = _cyl_mesh(0.24, 0.22, 0.56, 12)
	torso.position = Vector3(0.0, 0.86, -0.02)
	torso.material_override = suit_mat
	body_root.add_child(torso)

	var arm_l := MeshInstance3D.new()
	arm_l.mesh = _cyl_mesh(0.068, 0.062, 0.42, 10)
	arm_l.rotation = Vector3(-0.92, 0.0, -0.14)
	arm_l.position = Vector3(0.31, 0.82, 0.12)
	arm_l.material_override = suit_mat
	body_root.add_child(arm_l)

	var arm_r := MeshInstance3D.new()
	arm_r.mesh = _cyl_mesh(0.068, 0.062, 0.42, 10)
	arm_r.rotation = Vector3(-0.85, 0.0, 0.14)
	arm_r.position = Vector3(-0.31, 0.82, 0.10)
	arm_r.material_override = suit_mat
	body_root.add_child(arm_r)

	var head := MeshInstance3D.new()
	head.mesh = _box_mesh(Vector3(0.35, 0.33, 0.33))
	head.position = Vector3(0.0, 1.34, -0.01)
	head.material_override = skin_mat
	body_root.add_child(head)

	var eye_mat := _make_mat(Color(0.06, 0.06, 0.06), 0.1, 0.2)
	for ex in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		eye.mesh = _box_mesh(Vector3(0.055, 0.075, 0.04))
		eye.position = Vector3(float(ex), 1.36, 0.16)
		eye.material_override = eye_mat
		body_root.add_child(eye)

	var show_glasses: bool = (absi(seat_index) % 2 == 0)
	if customization.size() >= 2:
		show_glasses = not str(customization[1]).strip_edges().is_empty()
	if show_glasses:
		var frame_mat := _make_mat(Color(0.14, 0.14, 0.16), 0.65, 0.30)
		var glasses := MeshInstance3D.new()
		glasses.mesh = _box_mesh(Vector3(0.30, 0.09, 0.06))
		glasses.position = Vector3(0.0, 1.37, 0.18)
		glasses.material_override = frame_mat
		body_root.add_child(glasses)

	var hat_idx: int = absi(seat_index) % 4
	if not customization.is_empty():
		var hname: String = str(customization[0]).strip_edges().to_lower()
		if HAT_COSMETIC_BY_NAME.has(hname):
			hat_idx = int(HAT_COSMETIC_BY_NAME[hname]) % 4
	var hat_node := Node3D.new()
	hat_node.name = "ProceduralHat"
	hat_node.position = Vector3(0.0, 1.52, -0.01)
	body_root.add_child(hat_node)

	match hat_idx:
		0:
			var h_mat := _make_mat(Color(0.92, 0.70, 0.16), 0.22, 0.42)
			var dome := MeshInstance3D.new()
			dome.mesh = _sphere_mesh(0.21, 0.22, 12)
			dome.position = Vector3(0.0, 0.04, 0.0)
			dome.material_override = h_mat
			hat_node.add_child(dome)
			var brim := MeshInstance3D.new()
			brim.mesh = _box_mesh(Vector3(0.40, 0.04, 0.42))
			brim.position = Vector3(0.0, -0.01, 0.04)
			brim.material_override = h_mat
			hat_node.add_child(brim)
		1:
			var c_mat := _make_mat(Color(0.92, 0.36, 0.12), 0.12, 0.52)
			var cone := MeshInstance3D.new()
			cone.mesh = _cyl_mesh(0.05, 0.18, 0.36, 12)
			cone.position = Vector3(0.0, 0.17, 0.0)
			cone.material_override = c_mat
			hat_node.add_child(cone)
		2:
			var t_mat := _make_mat(Color(0.14, 0.12, 0.14), 0.20, 0.54)
			var brim2 := MeshInstance3D.new()
			brim2.mesh = _cyl_mesh(0.26, 0.26, 0.03, 14)
			brim2.material_override = t_mat
			hat_node.add_child(brim2)
			var cyl := MeshInstance3D.new()
			cyl.mesh = _cyl_mesh(0.17, 0.16, 0.25, 14)
			cyl.position = Vector3(0.0, 0.13, 0.0)
			cyl.material_override = t_mat
			hat_node.add_child(cyl)
		_:
			var f_mat := _make_mat(accent_color.darkened(0.22), 0.22, 0.52)
			var crown := MeshInstance3D.new()
			crown.mesh = _cyl_mesh(0.20, 0.19, 0.13, 12)
			crown.position = Vector3(0.0, 0.05, 0.0)
			crown.material_override = f_mat
			hat_node.add_child(crown)
			var peak := MeshInstance3D.new()
			peak.mesh = _box_mesh(Vector3(0.30, 0.035, 0.17))
			peak.position = Vector3(0.0, 0.01, 0.17)
			peak.material_override = f_mat
			hat_node.add_child(peak)

	return {"node": body_root, "mats": overlay_mats}


static func build_chair_rig(
	parent: Node3D,
	seat_index: int,
	seat_pos: Vector3,
	seat_yaw: float,
	accent_color: Color,
	nickname: String,
	customization: Array,
	team_tag: String
) -> Dictionary:
	ensure_game_pck_mounted()
	var cjk_font: Font = load_cjk_terminal_font()

	var root := Node3D.new()
	root.name = "ElectricChair_%d" % seat_index
	root.position = seat_pos
	root.rotation.y = seat_yaw
	if parent != null:
		parent.add_child(root)

	# Gritty bolted-iron industrial chair materials (authentic green_pea dark steel)
	var steel_mat := _make_mat(Color(0.58, 0.60, 0.62), 0.40, 0.82, Color.BLACK, 0.0, false, false, TEX_CHAIR_METAL, Vector3(1.0, 1.0, 1.0))
	var frame_mat := _make_mat(Color(0.40, 0.42, 0.44), 0.48, 0.78, Color.BLACK, 0.0, false, false, TEX_TABLE_METAL, Vector3(1.0, 1.0, 1.0))
	var copper_mat := _make_mat(Color(0.76, 0.44, 0.22), 0.80, 0.36)
	var chair_base_mat := _make_mat(accent_color.lerp(Color(0.18, 0.18, 0.18), 0.35), 0.25, 0.68)

	# 1. Dark Bolted Steel Base Plate + Restrained Matte Team/Slot ID Footbar Stripe (no neon floor saucers)
	var base_plate := MeshInstance3D.new()
	base_plate.mesh = _box_mesh(Vector3(1.02, 0.05, 0.96))
	base_plate.position = Vector3(0.0, 0.025, 0.02)
	base_plate.material_override = frame_mat
	root.add_child(base_plate)

	var foot_stripe := MeshInstance3D.new()
	foot_stripe.mesh = _box_mesh(Vector3(0.96, 0.06, 0.12))
	foot_stripe.position = Vector3(0.0, 0.032, 0.44)
	foot_stripe.material_override = chair_base_mat
	root.add_child(foot_stripe)

	# Chair legs, seat pan & slatted steel backrest (+Z forward toward camera)
	for lx in [-0.32, 0.32]:
		for lz in [-0.24, 0.24]:
			var leg := MeshInstance3D.new()
			leg.mesh = _box_mesh(Vector3(0.075, 0.44, 0.075))
			leg.position = Vector3(float(lx), 0.25, float(lz))
			leg.material_override = frame_mat
			root.add_child(leg)

	var seat_pan := MeshInstance3D.new()
	seat_pan.mesh = _box_mesh(Vector3(0.76, 0.08, 0.64))
	seat_pan.position = Vector3(0.0, 0.49, 0.0)
	seat_pan.material_override = steel_mat
	root.add_child(seat_pan)

	var backrest := MeshInstance3D.new()
	backrest.mesh = _box_mesh(Vector3(0.70, 0.90, 0.08))
	backrest.position = Vector3(0.0, 0.96, -0.28)
	backrest.material_override = steel_mat
	root.add_child(backrest)

	# Riveted electrode headrest clamp/halo
	var head_clamp := MeshInstance3D.new()
	head_clamp.mesh = _box_mesh(Vector3(0.46, 0.14, 0.12))
	head_clamp.position = Vector3(0.0, 1.38, -0.23)
	head_clamp.material_override = frame_mat
	root.add_child(head_clamp)

	for hx in [-0.24, 0.24]:
		var electrode := MeshInstance3D.new()
		electrode.mesh = _cyl_mesh(0.055, 0.055, 0.10, 10)
		electrode.rotation.z = PI * 0.5
		electrode.position = Vector3(float(hx), 1.38, -0.14)
		electrode.material_override = copper_mat
		root.add_child(electrode)

	# Iron armrests
	for ax in [-0.41, 0.41]:
		var arm_rest := MeshInstance3D.new()
		arm_rest.mesh = _box_mesh(Vector3(0.11, 0.07, 0.58))
		arm_rest.position = Vector3(float(ax), 0.76, 0.02)
		arm_rest.material_override = frame_mat
		root.add_child(arm_rest)

		var arm_post := MeshInstance3D.new()
		arm_post.mesh = _box_mesh(Vector3(0.07, 0.24, 0.09))
		arm_post.position = Vector3(float(ax), 0.62, 0.20)
		arm_post.material_override = frame_mat
		root.add_child(arm_post)

	# Rear Steel Conduit Post & Shoulder-Level Cable Anchor (routes parallel arcs cleanly below nameplates & CRT)
	var mast := MeshInstance3D.new()
	mast.mesh = _cyl_mesh(0.04, 0.05, 0.36, 10)
	mast.position = Vector3(0.0, 1.28, -0.34)
	mast.material_override = frame_mat
	root.add_child(mast)

	var insulator_tip := MeshInstance3D.new()
	insulator_tip.mesh = _cyl_mesh(0.065, 0.08, 0.12, 12)
	insulator_tip.position = Vector3(0.0, 1.48, -0.34)
	insulator_tip.material_override = copper_mat
	root.add_child(insulator_tip)

	var local_anchor := Vector3(0.0, 1.50, -0.34)
	var cable_anchor: Vector3 = seat_pos + local_anchor.rotated(Vector3.UP, seat_yaw)

	# 2. Right-hand (+X) Armrest Mechanical Pull Lever (idle -0.25 rad -> pulled +0.75 rad)
	var lever_pivot := Node3D.new()
	lever_pivot.name = "LeverPivot"
	lever_pivot.position = Vector3(0.46, 0.80, 0.14)
	lever_pivot.rotation.x = -0.25
	root.add_child(lever_pivot)

	var lever_rod := MeshInstance3D.new()
	lever_rod.mesh = _cyl_mesh(0.022, 0.022, 0.42, 8)
	lever_rod.position = Vector3(0.0, 0.21, 0.0)
	lever_rod.material_override = copper_mat
	lever_pivot.add_child(lever_rod)

	var lever_grip := MeshInstance3D.new()
	lever_grip.mesh = _cyl_mesh(0.045, 0.045, 0.15, 10)
	lever_grip.rotation.z = PI * 0.5
	lever_grip.position = Vector3(0.03, 0.42, 0.0)
	lever_grip.material_override = _make_mat(Color(0.92, 0.26, 0.16), 0.2, 0.42)
	lever_pivot.add_child(lever_grip)

	# 3. Left-hand (-X) Armrest: 2 Physical Fuse Bulbs & Red Sabotage Button
	var fuse_nodes: Array = []
	var fuse_mats: Array = []
	for fi in range(2):
		var f_mat := _make_mat(Color(0.74, 1.0, 0.45), 0.08, 0.20, Color(0.68, 1.0, 0.36), 2.0)
		var f_root := Node3D.new()
		f_root.name = "FuseBulb_%d" % fi
		f_root.position = Vector3(-0.45, 0.84, 0.02 - float(fi) * 0.16)
		root.add_child(f_root)

		var socket := MeshInstance3D.new()
		socket.mesh = _cyl_mesh(0.05, 0.06, 0.06, 10)
		socket.position = Vector3(0.0, -0.025, 0.0)
		socket.material_override = copper_mat
		f_root.add_child(socket)

		var bulb := MeshInstance3D.new()
		bulb.mesh = _sphere_mesh(0.062, 0.15, 12)
		bulb.position = Vector3(0.0, 0.07, 0.0)
		bulb.material_override = f_mat
		f_root.add_child(bulb)

		fuse_nodes.append(f_root)
		fuse_mats.append(f_mat)

	var kick_btn_mat := _make_mat(Color(0.98, 0.18, 0.14), 0.15, 0.28, Color(1.0, 0.16, 0.12), 1.6)
	var kick_housing := MeshInstance3D.new()
	kick_housing.mesh = _cyl_mesh(0.08, 0.09, 0.045, 12)
	kick_housing.position = Vector3(-0.43, 0.80, 0.23)
	kick_housing.material_override = frame_mat
	root.add_child(kick_housing)

	var kick_btn := MeshInstance3D.new()
	kick_btn.mesh = _cyl_mesh(0.062, 0.062, 0.045, 12)
	kick_btn.position = Vector3(-0.43, 0.84, 0.23)
	kick_btn.material_override = kick_btn_mat
	root.add_child(kick_btn)

	# 4. Insulated Safety Visor (-1.05 rad raised -> 0.0 rad closed cleanly over eyes/face)
	var visor_pivot := Node3D.new()
	visor_pivot.name = "SafetyVisorPivot"
	visor_pivot.position = Vector3(0.0, 1.88, -0.22)
	visor_pivot.rotation.x = -1.05
	root.add_child(visor_pivot)

	var visor_bar := MeshInstance3D.new()
	visor_bar.mesh = _box_mesh(Vector3(0.42, 0.035, 0.035))
	visor_bar.position = Vector3(0.0, 0.0, 0.36)
	visor_bar.material_override = frame_mat
	visor_pivot.add_child(visor_bar)

	var visor_bottom_rim := MeshInstance3D.new()
	visor_bottom_rim.mesh = _box_mesh(Vector3(0.42, 0.025, 0.035))
	visor_bottom_rim.position = Vector3(0.0, -0.125, 0.36)
	visor_bottom_rim.material_override = frame_mat
	visor_pivot.add_child(visor_bottom_rim)

	for vx in [-0.20, 0.20]:
		var visor_strut := MeshInstance3D.new()
		visor_strut.mesh = _box_mesh(Vector3(0.025, 0.13, 0.035))
		visor_strut.position = Vector3(float(vx), -0.06, 0.36)
		visor_strut.material_override = frame_mat
		visor_pivot.add_child(visor_strut)

	var visor_shield := MeshInstance3D.new()
	visor_shield.mesh = _box_mesh(Vector3(0.38, 0.105, 0.02))
	visor_shield.position = Vector3(0.0, -0.06, 0.36)
	visor_shield.material_override = _make_mat(Color(0.24, 0.78, 0.88, 0.22), 0.15, 0.14, Color(0.22, 0.72, 0.84), 0.10, true)
	visor_pivot.add_child(visor_shield)

	# 5. Seated Character Rig (OfficialSeatedRig faces +Z toward camera when rotation_degrees.y = 180.0)
	var body_root := Node3D.new()
	body_root.name = "CharacterBodyRoot"
	root.add_child(body_root)

	var char_overlay_mats: Array = []
	var official_packed = load_optional(GLB_PLAYER)
	if official_packed is PackedScene:
		var inst: Node3D = (official_packed as PackedScene).instantiate() as Node3D
		inst.name = "OfficialSeatedRig"
		inst.position = Vector3(0.0, 0.06, -0.02)
		inst.rotation_degrees.y = 180.0
		inst.scale = Vector3(0.40, 0.40, 0.40)
		body_root.add_child(inst)
		var cust_res: Dictionary = _customize_official_seated_rig(inst, seat_index, accent_color, customization)
		char_overlay_mats = cust_res["mats"] as Array
	else:
		var proc_res: Dictionary = _build_procedural_seated_char(seat_index, accent_color, customization)
		body_root.add_child(proc_res["node"] as Node3D)
		char_overlay_mats = proc_res["mats"] as Array

	# 6. Diegetic Mini-LCD Score (chair apron, clear of bottom legend) & Compact Nameplate (above hats)
	var lcd_panel := MeshInstance3D.new()
	lcd_panel.mesh = _box_mesh(Vector3(0.56, 0.14, 0.08))
	lcd_panel.position = Vector3(0.0, 0.10, 0.50)
	lcd_panel.material_override = _make_mat(Color(0.05, 0.05, 0.04), 0.3, 0.6)
	root.add_child(lcd_panel)

	var lcd_label := Label3D.new()
	lcd_label.name = "ChairLCDLabel"
	lcd_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lcd_label.no_depth_test = true
	lcd_label.font_size = 24
	lcd_label.pixel_size = 0.0046
	lcd_label.modulate = Color(1.0, 0.84, 0.28)
	lcd_label.outline_modulate = Color(0.03, 0.03, 0.02)
	lcd_label.outline_size = 8
	if cjk_font != null:
		lcd_label.font = cjk_font
	lcd_label.text = "0"
	lcd_label.position = Vector3(0.0, 0.38, 0.48)
	root.add_child(lcd_label)

	var name_y: float = 2.22 + (0.10 if (seat_index % 2 == 1) else 0.0)
	var name_label := Label3D.new()
	name_label.name = "ChairNameLabel"
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.font_size = 22
	name_label.pixel_size = 0.0048
	name_label.modulate = accent_color.lightened(0.35)
	name_label.outline_modulate = Color(0.03, 0.02, 0.02)
	name_label.outline_size = 8
	if cjk_font != null:
		name_label.font = cjk_font
	name_label.text = nickname if team_tag.is_empty() else "%s %s" % [team_tag, nickname]
	name_label.position = Vector3(0.0, name_y, 0.0)
	root.add_child(name_label)

	return {
		"root": root,
		"lever_pivot": lever_pivot,
		"visor_pivot": visor_pivot,
		"fuse_mats": fuse_mats,
		"fuse_nodes": fuse_nodes,
		"kick_btn_mat": kick_btn_mat,
		"cable_anchor": cable_anchor,
		"lcd_label": lcd_label,
		"name_label": name_label,
		"body_root": body_root,
		"char_overlay_mats": char_overlay_mats,
		"chair_base_mat": chair_base_mat,
	}
