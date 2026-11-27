extends RefCounted

## Industrial Electric-Test-Chamber stage, oversized analog High-Voltage Transformer,
## Coach Overseer podium, electric chair + seated character rigs, and 128x128 CRT icon
## for Voltage Greed (贪婪电椅 / 貪婪電椅).
## Clean-room runtime reuse of Machine Party.pck resources when mounted, with crisp
## procedural fallbacks for standalone macOS / headless execution.

const TEX_THREADPLATE := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate albedo.png"
const TEX_THREADPLATE_NORMAL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_threadplate normal 1024.png"
const TEX_CONTROL_PANEL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_chisel gauntlet control panel1.png"
const TEX_METAL_PLATE := "res://minigames/dvd_roomba/models/dvd roomba visuals1_metal plate1.png"
const TEX_WALL := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba walls1.png"
const TEX_SIDING := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba siding.png"
const TEX_PIPES := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_fc pipes2.png"
const TEX_HEAVY_RUST := "res://minigames/junk_platform/models/junk platform visuals2/junk platform visuals2_heavy rust2.png"
const GLB_WALL_LAMP := "res://models/elevator light2/elevator light2.glb"

const GLB_COACH := "res://minigames/green_pea/models/character coach1/character coach1.glb"
const GLB_COACH_DEAGLE := "res://minigames/green_pea/models/pea game coach with deagle1/pea game coach with deagle1.glb"
const ANIM_COACH_LOOK := "res://minigames/green_pea/animations/coach_looking_at_players.res"
const ANIM_COACH_DEAGLE := "res://minigames/green_pea/animations/coach_deagle_ready_up.res"
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
	metallic: float = 0.3,
	roughness: float = 0.55,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0,
	alpha: bool = false,
	unshaded: bool = false,
	tex_path: String = "",
	uv_scale: Vector3 = Vector3.ONE,
	normal_path: String = ""
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
	if not normal_path.is_empty():
		var ntex = load_optional(normal_path)
		if ntex is Texture2D:
			mat.normal_enabled = true
			mat.normal_texture = ntex as Texture2D
			mat.normal_scale = 0.72
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

	# Radial tungsten glow + riveted copper-amber border
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

			# Upper analog gauge dial arc (center at (64, 58), radius 38)
			var dx: float = float(x) - 64.0
			var dy: float = float(y) - 58.0
			var dist: float = sqrt(dx * dx + dy * dy)
			if dy <= 6.0 and dist >= 27.0 and dist <= 38.0:
				var ang: float = atan2(-dy, dx) # 0=right, PI=left
				if ang >= -0.15 and ang <= PI + 0.15:
					if ang < PI * 0.32:
						img.set_pixel(x, y, Color(1.0, 0.24, 0.14, 1.0)) # Red overload zone
					elif ang < PI * 0.62:
						img.set_pixel(x, y, Color(1.0, 0.72, 0.18, 1.0)) # Amber caution zone
					else:
						img.set_pixel(x, y, Color(0.45, 0.88, 0.44, 1.0)) # Safe green zone
			elif dy <= 6.0 and dist < 27.0:
				img.set_pixel(x, y, Color(0.13, 0.11, 0.10, 1.0))

			# Industrial electric chair silhouette at lower half
			if y >= 72 and y <= 104 and absf(float(x - 64)) <= 18.0:
				if y <= 84 and absf(float(x - 64)) <= 12.0:
					img.set_pixel(x, y, Color(0.32, 0.26, 0.22, 1.0))
				elif y >= 85 and y <= 93:
					img.set_pixel(x, y, Color(0.56, 0.44, 0.28, 1.0))
				elif y > 93 and (absf(float(x - 51)) <= 3.0 or absf(float(x - 77)) <= 3.0):
					img.set_pixel(x, y, Color(0.42, 0.36, 0.32, 1.0))
			# Electrode crown cap
			if y >= 63 and y <= 70 and absf(float(x - 64)) <= 10.0:
				img.set_pixel(x, y, Color(0.95, 0.68, 0.20, 1.0))
			# Hazard base strip under chair
			if y >= 105 and y <= 113 and x >= 18 and x <= w - 19:
				var stripe: bool = ((x + y) / 6) % 2 == 0
				img.set_pixel(x, y, Color(0.98, 0.72, 0.14, 1.0) if stripe else Color(0.15, 0.12, 0.10, 1.0))

	# Needle tilted fiercely into red danger zone
	_draw_line_px(img, Vector2(64.0, 58.0), Vector2(89.0, 34.0), Color(1.0, 0.24, 0.12, 1.0), 4.0)
	_draw_line_px(img, Vector2(64.0, 58.0), Vector2(64.0, 58.0), Color(1.0, 0.88, 0.34, 1.0), 8.0)

	#Twin electric lightning bolts flanking chair
	_draw_line_px(img, Vector2(24.0, 58.0), Vector2(36.0, 74.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(36.0, 74.0), Vector2(27.0, 78.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(27.0, 78.0), Vector2(40.0, 96.0), Color(1.0, 0.94, 0.45, 1.0), 3.0)

	_draw_line_px(img, Vector2(104.0, 58.0), Vector2(92.0, 74.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(92.0, 74.0), Vector2(101.0, 78.0), Color(0.45, 0.92, 1.0, 1.0), 3.0)
	_draw_line_px(img, Vector2(101.0, 78.0), Vector2(88.0, 96.0), Color(1.0, 0.94, 0.45, 1.0), 3.0)

	return ImageTexture.create_from_image(img)


static func _build_procedural_overseer() -> Dictionary:
	var coach := Node3D.new()
	coach.name = "ProceduralOverseer"

	var coat_mat: StandardMaterial3D = _make_mat(Color(0.20, 0.17, 0.16), 0.18, 0.64)
	var shirt_mat: StandardMaterial3D = _make_mat(Color(0.84, 0.78, 0.68), 0.05, 0.72)
	var tie_mat: StandardMaterial3D = _make_mat(Color(0.86, 0.22, 0.16), 0.12, 0.45)
	var skin_mat: StandardMaterial3D = _make_mat(Color(0.88, 0.72, 0.58), 0.04, 0.66)
	var hat_mat: StandardMaterial3D = _make_mat(Color(0.14, 0.12, 0.12), 0.24, 0.48)
	var brass_mat: StandardMaterial3D = _make_mat(Color(0.95, 0.72, 0.22), 0.76, 0.28)

	# Legs
	for lx in [-0.14, 0.14]:
		var leg := MeshInstance3D.new()
		leg.mesh = _cyl_mesh(0.10, 0.09, 0.78, 10)
		leg.position = Vector3(float(lx), 0.39, 0.0)
		leg.material_override = coat_mat
		coach.add_child(leg)

	# Broad industrial coat torso
	var torso := MeshInstance3D.new()
	torso.mesh = _cyl_mesh(0.32, 0.26, 0.88, 12)
	torso.position = Vector3(0.0, 1.15, 0.0)
	torso.material_override = coat_mat
	coach.add_child(torso)

	var chest_shirt := MeshInstance3D.new()
	chest_shirt.mesh = _box_mesh(Vector3(0.22, 0.44, 0.10))
	chest_shirt.position = Vector3(0.0, 1.28, 0.24)
	chest_shirt.material_override = shirt_mat
	coach.add_child(chest_shirt)

	var tie := MeshInstance3D.new()
	tie.mesh = _box_mesh(Vector3(0.07, 0.34, 0.06))
	tie.position = Vector3(0.0, 1.24, 0.28)
	tie.material_override = tie_mat
	coach.add_child(tie)

	# Head & peaked Overseer cap
	var head := MeshInstance3D.new()
	head.mesh = _box_mesh(Vector3(0.36, 0.34, 0.34))
	head.position = Vector3(0.0, 1.78, 0.0)
	head.material_override = skin_mat
	coach.add_child(head)

	for ex in [-0.09, 0.09]:
		var shades := MeshInstance3D.new()
		shades.mesh = _box_mesh(Vector3(0.12, 0.07, 0.06))
		shades.position = Vector3(float(ex), 1.81, 0.18)
		shades.material_override = hat_mat
		coach.add_child(shades)

	var cap_crown := MeshInstance3D.new()
	cap_crown.mesh = _cyl_mesh(0.24, 0.20, 0.16, 12)
	cap_crown.position = Vector3(0.0, 2.01, -0.02)
	cap_crown.material_override = hat_mat
	coach.add_child(cap_crown)

	var cap_brim := MeshInstance3D.new()
	cap_brim.mesh = _box_mesh(Vector3(0.34, 0.04, 0.20))
	cap_brim.position = Vector3(0.0, 1.94, 0.16)
	cap_brim.material_override = hat_mat
	coach.add_child(cap_brim)

	var badge := MeshInstance3D.new()
	badge.mesh = _cyl_mesh(0.05, 0.05, 0.04, 8)
	badge.rotation.x = PI * 0.5
	badge.position = Vector3(0.0, 2.02, 0.19)
	badge.material_override = brass_mat
	coach.add_child(badge)

	# Left resting arm
	var arm_l := MeshInstance3D.new()
	arm_l.mesh = _cyl_mesh(0.08, 0.07, 0.62, 10)
	arm_l.position = Vector3(-0.36, 1.15, 0.06)
	arm_l.rotation.z = 0.18
	arm_l.material_override = coat_mat
	coach.add_child(arm_l)

	# Right arm + raised Deagle execution pistol
	var arm_r := Node3D.new()
	arm_r.name = "RightArmPivot"
	arm_r.position = Vector3(0.34, 1.40, 0.08)
	arm_r.rotation_degrees = Vector3(-55.0, 0.0, -10.0)
	coach.add_child(arm_r)

	var arm_r_mesh := MeshInstance3D.new()
	arm_r_mesh.mesh = _cyl_mesh(0.08, 0.07, 0.56, 10)
	arm_r_mesh.position = Vector3(0.0, -0.24, 0.0)
	arm_r_mesh.material_override = coat_mat
	arm_r.add_child(arm_r_mesh)

	var deagle := Node3D.new()
	deagle.name = "CoachDeagle"
	deagle.position = Vector3(0.0, -0.52, 0.16)
	arm_r.add_child(deagle)

	var barrel := MeshInstance3D.new()
	barrel.mesh = _box_mesh(Vector3(0.06, 0.09, 0.42))
	barrel.position = Vector3(0.0, 0.05, 0.16)
	barrel.material_override = _make_mat(Color(0.68, 0.70, 0.72), 0.88, 0.24)
	deagle.add_child(barrel)

	var grip := MeshInstance3D.new()
	grip.mesh = _box_mesh(Vector3(0.05, 0.15, 0.08))
	grip.position = Vector3(0.0, -0.04, 0.02)
	grip.rotation_degrees.x = 18.0
	grip.material_override = _make_mat(Color(0.16, 0.13, 0.12), 0.15, 0.72)
	deagle.add_child(grip)

	return {"node": coach, "deagle": deagle}


static func build_stage(parent: Node3D, cfg_script) -> Dictionary:
	ensure_game_pck_mounted()

	var root := Node3D.new()
	root.name = "VoltageGreedStage"
	if parent != null:
		parent.add_child(root)

	var cjk_font: Font = load_cjk_terminal_font()

	# Warm tungsten & rust industrial chamber materials
	var floor_mat := _make_mat(Color(0.50, 0.45, 0.40), 0.34, 0.68, Color.BLACK, 0.0, false, false, TEX_THREADPLATE, Vector3(11.0, 9.0, 1.0), TEX_THREADPLATE_NORMAL)
	var subdeck_mat := _make_mat(Color(0.16, 0.13, 0.12), 0.36, 0.82, Color.BLACK, 0.0, false, false, TEX_HEAVY_RUST, Vector3(6.0, 6.0, 1.0))
	var wall_mat := _make_mat(Color(0.45, 0.39, 0.35), 0.40, 0.66, Color.BLACK, 0.0, false, false, TEX_WALL, Vector3(8.0, 2.0, 1.0))
	var rust_mat := _make_mat(Color(0.52, 0.40, 0.33), 0.46, 0.62, Color.BLACK, 0.0, false, false, TEX_HEAVY_RUST, Vector3(3.0, 2.0, 1.0))
	var pipes_mat := _make_mat(Color(0.56, 0.48, 0.42), 0.58, 0.44, Color.BLACK, 0.0, false, false, TEX_PIPES, Vector3(2.0, 2.0, 1.0))
	var trim_mat := _make_mat(Color(0.44, 0.40, 0.37), 0.68, 0.36, Color.BLACK, 0.0, false, false, TEX_METAL_PLATE, Vector3(2.0, 2.0, 1.0))
	var hazard_mat := _make_mat(Color(0.92, 0.64, 0.16), 0.22, 0.48, Color(0.86, 0.54, 0.12), 0.20, false, false, TEX_SIDING, Vector3(6.0, 1.0, 1.0))
	var panel_mat := _make_mat(Color(0.70, 0.64, 0.58), 0.42, 0.48, Color.BLACK, 0.0, false, false, TEX_CONTROL_PANEL, Vector3(1.0, 1.0, 1.0))
	var copper_mat := _make_mat(Color(0.82, 0.46, 0.24), 0.86, 0.28)
	var ceramic_mat := _make_mat(Color(0.84, 0.80, 0.72), 0.12, 0.26)
	var cable_mat := _make_mat(Color(0.11, 0.10, 0.10), 0.18, 0.74)

	# 1. Main Lab Floor & Sub-deck Foundation
	var sub_deck := MeshInstance3D.new()
	sub_deck.name = "ChamberSubDeck"
	sub_deck.mesh = _box_mesh(Vector3(30.0, 1.0, 22.0))
	sub_deck.position = Vector3(0.0, -0.78, -0.5)
	sub_deck.material_override = subdeck_mat
	root.add_child(sub_deck)

	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "ChamberFloor"
	floor_mi.mesh = _box_mesh(Vector3(26.0, 0.4, 21.0))
	floor_mi.position = Vector3(0.0, -0.20, 0.5)
	floor_mi.material_override = floor_mat
	root.add_child(floor_mi)

	# Rubberized safety apron beneath central stage
	var stage_pad := MeshInstance3D.new()
	stage_pad.name = "TestZoneMat"
	stage_pad.mesh = _cyl_mesh(7.2, 7.4, 0.04, 36)
	stage_pad.position = Vector3(0.0, 0.02, -0.8)
	stage_pad.material_override = _make_mat(Color(0.13, 0.12, 0.11), 0.16, 0.86)
	root.add_child(stage_pad)

	var stage_ring := MeshInstance3D.new()
	stage_ring.mesh = _torus_mesh(7.05, 7.35, 42)
	stage_ring.position = Vector3(0.0, 0.03, -0.8)
	stage_ring.scale = Vector3(1.0, 0.16, 1.0)
	stage_ring.material_override = hazard_mat
	root.add_child(stage_ring)

	# 2. Curved Rear Two-Tier Lab Riser (centered at STAGE_FOCUS (0,0,-5.2), r=6.65..9.15, top y=0.85)
	# Cleanly supports elevated back-row chairs (r=7.6, y=0.85) while keeping front-row (r=5.4..5.6) clear.
	var riser_root := Node3D.new()
	riser_root.name = "BackRowRiser"
	riser_root.position = Vector3(0.0, 0.0, -5.2)
	root.add_child(riser_root)

	var seg_deck_mesh: BoxMesh = _box_mesh(Vector3(1.55, 0.85, 2.50))
	var seg_lip_mesh: BoxMesh = _box_mesh(Vector3(1.58, 0.14, 0.16))
	var seg_step_mesh: BoxMesh = _box_mesh(Vector3(1.48, 0.42, 0.52))
	for si in range(11):
		var frac_s: float = float(si) / 10.0 - 0.5
		var ang_s: float = frac_s * deg_to_rad(104.0)
		var seg_node := Node3D.new()
		seg_node.rotation.y = ang_s
		riser_root.add_child(seg_node)

		var deck := MeshInstance3D.new()
		deck.mesh = seg_deck_mesh
		deck.position = Vector3(0.0, 0.425, 7.90)
		deck.material_override = trim_mat
		seg_node.add_child(deck)

		var lip := MeshInstance3D.new()
		lip.mesh = seg_lip_mesh
		lip.position = Vector3(0.0, 0.80, 6.68)
		lip.material_override = hazard_mat
		seg_node.add_child(lip)

		var step := MeshInstance3D.new()
		step.mesh = seg_step_mesh
		step.position = Vector3(0.0, 0.21, 6.42)
		step.material_override = rust_mat
		seg_node.add_child(step)

	# 3. Industrial Back Wall, Buttresses, Pipes & Flickering Fluorescent Tubes
	var back_z: float = -8.4
	var wall_w: float = 26.0
	var wall_h: float = 9.2

	var back_wall := MeshInstance3D.new()
	back_wall.name = "ChamberBackWall"
	back_wall.mesh = _box_mesh(Vector3(wall_w, wall_h, 0.7))
	back_wall.position = Vector3(0.0, wall_h * 0.5 - 0.3, back_z)
	back_wall.material_override = wall_mat
	root.add_child(back_wall)

	# Side angled wing walls to close peripheral camera angles cleanly
	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		wing.mesh = _box_mesh(Vector3(0.7, wall_h, 21.0))
		wing.position = Vector3(float(side) * 12.6, wall_h * 0.5 - 0.3, 0.5)
		wing.material_override = wall_mat
		root.add_child(wing)

	var col_mesh: BoxMesh = _box_mesh(Vector3(0.75, wall_h + 0.3, 0.95))
	for cx in [-10.5, -5.6, 5.6, 10.5]:
		var col := MeshInstance3D.new()
		col.mesh = col_mesh
		col.position = Vector3(float(cx), wall_h * 0.5 - 0.2, back_z + 0.35)
		col.material_override = rust_mat
		root.add_child(col)

	# Horizontal steam & high-voltage conduit pipes along back wall
	for py in [2.1, 4.4, 6.7]:
		var pipe := MeshInstance3D.new()
		pipe.mesh = _cyl_mesh(0.22, 0.22, wall_w - 1.0, 12)
		pipe.rotation_degrees.z = 90.0
		pipe.position = Vector3(0.0, float(py), back_z + 0.52)
		pipe.material_override = pipes_mat
		root.add_child(pipe)

	# Flickering industrial fluorescent tube fixtures + warm cage lamps
	var fluorescent_mats: Array = []
	var tube_housing_mat := _make_mat(Color(0.22, 0.20, 0.19), 0.55, 0.58)
	var tube_xs: Array = [-7.8, -3.4, 3.4, 7.8]
	for tx in tube_xs:
		var t_root := Node3D.new()
		t_root.position = Vector3(float(tx), 5.65, back_z + 0.62)
		root.add_child(t_root)

		var hood := MeshInstance3D.new()
		hood.mesh = _box_mesh(Vector3(2.4, 0.24, 0.32))
		hood.material_override = tube_housing_mat
		t_root.add_child(hood)

		var f_mat := _make_mat(Color(0.95, 0.90, 0.72), 0.05, 0.2, Color(1.0, 0.88, 0.56), 2.4)
		fluorescent_mats.append(f_mat)

		var tube := MeshInstance3D.new()
		tube.mesh = _cyl_mesh(0.075, 0.075, 2.15, 10)
		tube.rotation_degrees.z = 90.0
		tube.position = Vector3(0.0, -0.06, 0.10)
		tube.material_override = f_mat
		t_root.add_child(tube)

	# Warm tungsten wall cage lamps if GLB exists, else subtle sconces
	var lamp_packed = load_optional(GLB_WALL_LAMP)
	var lamp_glow := _make_mat(Color(1.0, 0.72, 0.30), 0.1, 0.25, Color(1.0, 0.62, 0.18), 1.9)
	for lx in [-8.2, 8.2]:
		if lamp_packed is PackedScene:
			var linst: Node3D = (lamp_packed as PackedScene).instantiate() as Node3D
			linst.position = Vector3(float(lx), 3.3, back_z + 0.56)
			linst.rotation_degrees.y = 90.0
			linst.scale = Vector3(0.75, 0.75, 0.75)
			root.add_child(linst)
			for c in linst.get_children():
				if c is MeshInstance3D:
					(c as MeshInstance3D).set_surface_override_material(0, lamp_glow)

	# Warm industrial chamber accent OmniLights (kept <= 2 static fills + 1 beacon)
	var tungsten_l := OmniLight3D.new()
	tungsten_l.name = "WarmTungstenLeft"
	tungsten_l.light_color = Color(1.0, 0.72, 0.38)
	tungsten_l.light_energy = 2.1
	tungsten_l.omni_range = 19.0
	tungsten_l.position = Vector3(-5.8, 5.2, -3.5)
	root.add_child(tungsten_l)

	var tungsten_r := OmniLight3D.new()
	tungsten_r.name = "WarmTungstenRight"
	tungsten_r.light_color = Color(1.0, 0.68, 0.34)
	tungsten_r.light_energy = 2.0
	tungsten_r.omni_range = 19.0
	tungsten_r.position = Vector3(5.8, 5.2, -3.5)
	root.add_child(tungsten_r)

	# 4. Central Oversized Analog High-Voltage Transformer at (0, 0, -5.2)
	var tf_pos := Vector3(0.0, 0.0, -5.2)
	var tf_root := Node3D.new()
	tf_root.name = "CentralTransformer"
	tf_root.position = tf_pos
	root.add_child(tf_root)

	# Heavy plinth & cooling fin cabinet
	var plinth := MeshInstance3D.new()
	plinth.mesh = _box_mesh(Vector3(3.4, 0.38, 2.2))
	plinth.position = Vector3(0.0, 0.19, 0.0)
	plinth.material_override = trim_mat
	tf_root.add_child(plinth)

	var plinth_hazard := MeshInstance3D.new()
	plinth_hazard.mesh = _box_mesh(Vector3(3.48, 0.14, 2.28))
	plinth_hazard.position = Vector3(0.0, 0.34, 0.0)
	plinth_hazard.material_override = hazard_mat
	tf_root.add_child(plinth_hazard)

	var cabinet := MeshInstance3D.new()
	cabinet.mesh = _box_mesh(Vector3(2.80, 1.65, 1.68))
	cabinet.position = Vector3(0.0, 1.20, 0.0)
	cabinet.material_override = rust_mat
	tf_root.add_child(cabinet)

	var front_ctrl := MeshInstance3D.new()
	front_ctrl.mesh = _box_mesh(Vector3(2.30, 0.82, 0.10))
	front_ctrl.position = Vector3(0.0, 0.92, 0.86)
	front_ctrl.material_override = panel_mat
	tf_root.add_child(front_ctrl)

	# Cooling radiator fins & twin copper HV coils
	for fx in [-1.50, 1.50]:
		for fi in range(4):
			var fin := MeshInstance3D.new()
			fin.mesh = _box_mesh(Vector3(0.22, 1.35, 0.14))
			fin.position = Vector3(float(fx), 1.18, -0.52 + float(fi) * 0.34)
			fin.material_override = trim_mat
			tf_root.add_child(fin)

	for cx in [-1.05, 1.05]:
		var insulator := MeshInstance3D.new()
		insulator.mesh = _cyl_mesh(0.22, 0.26, 0.62, 14)
		insulator.position = Vector3(float(cx), 2.34, 0.0)
		insulator.material_override = ceramic_mat
		tf_root.add_child(insulator)

		var coil := MeshInstance3D.new()
		coil.mesh = _cyl_mesh(0.16, 0.16, 0.38, 14)
		coil.position = Vector3(float(cx), 2.75, 0.0)
		coil.material_override = copper_mat
		tf_root.add_child(coil)

		var dome := MeshInstance3D.new()
		dome.mesh = _sphere_mesh(0.22, 0.28, 14)
		dome.position = Vector3(float(cx), 2.98, 0.0)
		dome.material_override = copper_mat
		tf_root.add_child(dome)

	# Central HV discharge crown top (kick arcs converge here; cleanly inside 4P & 8P camera FOV)
	var crown_mast := MeshInstance3D.new()
	crown_mast.mesh = _cyl_mesh(0.14, 0.20, 0.68, 14)
	crown_mast.position = Vector3(0.0, 3.50, 0.0)
	crown_mast.material_override = ceramic_mat
	tf_root.add_child(crown_mast)

	var crown_torus := MeshInstance3D.new()
	crown_torus.mesh = _torus_mesh(0.32, 0.48, 24)
	crown_torus.position = Vector3(0.0, 3.90, 0.0)
	crown_torus.material_override = copper_mat
	tf_root.add_child(crown_torus)

	var transformer_top: Vector3 = tf_pos + Vector3(0.0, 3.95, 0.0)

	# Oversized Analog Voltage Gauge Housing mounted prominently on front-top of transformer
	var dial_hub := Node3D.new()
	dial_hub.name = "AnalogDialAssembly"
	dial_hub.position = Vector3(0.0, 2.32, 0.88)
	tf_root.add_child(dial_hub)

	var dial_rim := MeshInstance3D.new()
	dial_rim.mesh = _cyl_mesh(1.16, 1.22, 0.28, 32)
	dial_rim.rotation.x = PI * 0.5
	dial_rim.material_override = trim_mat
	dial_hub.add_child(dial_rim)

	var gauge_glow_mat := _make_mat(Color(0.82, 0.76, 0.60), 0.05, 0.42, Color(0.55, 0.42, 0.16), 0.24)
	var dial_face := MeshInstance3D.new()
	dial_face.mesh = _cyl_mesh(1.02, 1.02, 0.06, 32)
	dial_face.rotation.x = PI * 0.5
	dial_face.position = Vector3(0.0, 0.0, 0.14)
	dial_face.material_override = gauge_glow_mat
	dial_hub.add_child(dial_face)

	# Graduated radial gauge tick marks (+0.95 rad = 0% left, -0.95 rad = 100% right)
	var safe_tick_mat := _make_mat(Color(0.14, 0.20, 0.14), 0.1, 0.5)
	var warn_tick_mat := _make_mat(Color(0.96, 0.56, 0.12), 0.1, 0.3, Color(0.96, 0.50, 0.10), 0.8)
	var danger_tick_mat := _make_mat(Color(0.98, 0.16, 0.12), 0.1, 0.2, Color(0.98, 0.14, 0.10), 1.4)
	for ti in range(11):
		var frac: float = float(ti) / 10.0
		var tick_ang: float = lerpf(-0.95, 0.95, frac)
		var tick_mat: StandardMaterial3D = safe_tick_mat
		if frac >= 0.70:
			tick_mat = danger_tick_mat
		elif frac >= 0.50:
			tick_mat = warn_tick_mat
		var tick := MeshInstance3D.new()
		tick.mesh = _box_mesh(Vector3(0.06, 0.22 if (ti % 2 == 0) else 0.14, 0.04))
		tick.position = Vector3(sin(tick_ang) * 0.78, cos(tick_ang) * 0.78 - 0.12, 0.18)
		tick.rotation.z = -tick_ang
		tick.material_override = tick_mat
		dial_hub.add_child(tick)

	var needle_pivot := Node3D.new()
	needle_pivot.name = "GaugeNeedlePivot"
	needle_pivot.position = Vector3(0.0, -0.14, 0.21)
	needle_pivot.rotation.z = 0.95 # 0% resting far left (+0.95 rad -> -0.95 rad at 100%)
	dial_hub.add_child(needle_pivot)

	var needle_blade := MeshInstance3D.new()
	needle_blade.mesh = _box_mesh(Vector3(0.06, 0.90, 0.04))
	needle_blade.position = Vector3(0.0, 0.38, 0.0)
	needle_blade.material_override = _make_mat(Color(0.98, 0.16, 0.10), 0.2, 0.2, Color(1.0, 0.22, 0.10), 1.3)
	needle_pivot.add_child(needle_blade)

	var needle_cap := MeshInstance3D.new()
	needle_cap.mesh = _cyl_mesh(0.14, 0.14, 0.08, 16)
	needle_cap.rotation.x = PI * 0.5
	needle_cap.material_override = trim_mat
	needle_pivot.add_child(needle_cap)

	# Warning Strobe Beacon on Transformer Crown
	var beacon_mat := _make_mat(Color(0.85, 0.18, 0.10), 0.15, 0.22, Color(1.0, 0.20, 0.10), 0.5)
	var beacon_dome := MeshInstance3D.new()
	beacon_dome.name = "OverloadBeaconMesh"
	beacon_dome.mesh = _cyl_mesh(0.18, 0.22, 0.32, 16)
	beacon_dome.position = Vector3(0.0, 4.18, 0.0)
	beacon_dome.material_override = beacon_mat
	tf_root.add_child(beacon_dome)

	var beacon_light := OmniLight3D.new()
	beacon_light.name = "OverloadBeaconLight"
	beacon_light.light_color = Color(1.0, 0.26, 0.14)
	beacon_light.light_energy = 0.0
	beacon_light.omni_range = 14.0
	beacon_light.shadow_enabled = false
	beacon_light.position = Vector3(0.0, 4.35, 0.35)
	tf_root.add_child(beacon_light)

	# Industrial CRT Telemetry Console Pedestal flanking right of Transformer (visible in both 4P & 8P shots)
	var crt_pedestal := Node3D.new()
	crt_pedestal.name = "CRTPedestal"
	crt_pedestal.position = Vector3(3.45, 0.0, -4.75)
	crt_pedestal.rotation.y = -0.24
	root.add_child(crt_pedestal)

	var crt_stand := MeshInstance3D.new()
	crt_stand.mesh = _box_mesh(Vector3(1.6, 1.35, 0.9))
	crt_stand.position = Vector3(0.0, 0.675, 0.0)
	crt_stand.material_override = trim_mat
	crt_pedestal.add_child(crt_stand)

	var crt_root := Node3D.new()
	crt_root.name = "OverheadCRT"
	crt_root.position = Vector3(0.0, 2.25, 0.0)
	crt_pedestal.add_child(crt_root)

	var crt_case := MeshInstance3D.new()
	crt_case.mesh = _box_mesh(Vector3(3.4, 1.65, 0.52))
	crt_case.material_override = rust_mat
	crt_root.add_child(crt_case)

	var crt_bezel := MeshInstance3D.new()
	crt_bezel.mesh = _box_mesh(Vector3(3.15, 1.40, 0.10))
	crt_bezel.position = Vector3(0.0, 0.0, 0.24)
	crt_bezel.material_override = _make_mat(Color(0.08, 0.07, 0.06), 0.35, 0.65)
	crt_root.add_child(crt_bezel)

	var crt_screen := MeshInstance3D.new()
	crt_screen.mesh = _box_mesh(Vector3(2.94, 1.20, 0.05))
	crt_screen.position = Vector3(0.0, 0.0, 0.29)
	crt_screen.material_override = _make_mat(Color(0.03, 0.04, 0.02), 0.12, 0.25, Color(0.16, 0.24, 0.06), 0.35)
	crt_root.add_child(crt_screen)

	var crt_label := Label3D.new()
	crt_label.name = "CRTMainLabel"
	crt_label.text = "0%"
	crt_label.font_size = 94
	crt_label.pixel_size = 0.0080
	crt_label.modulate = Color(1.0, 0.80, 0.24)
	crt_label.outline_modulate = Color(0.04, 0.03, 0.01)
	crt_label.outline_size = 14
	if cjk_font != null:
		crt_label.font = cjk_font
	crt_label.position = Vector3(0.0, 0.18, 0.34)
	crt_root.add_child(crt_label)

	var crt_sub_label := Label3D.new()
	crt_sub_label.name = "CRTSubLabel"
	crt_sub_label.text = "ROUND 1/3 · 1.0x"
	crt_sub_label.font_size = 40
	crt_sub_label.pixel_size = 0.0076
	crt_sub_label.modulate = Color(0.68, 0.94, 0.62)
	crt_sub_label.outline_modulate = Color(0.04, 0.03, 0.01)
	crt_sub_label.outline_size = 10
	if cjk_font != null:
		crt_sub_label.font = cjk_font
	crt_sub_label.position = Vector3(0.0, -0.34, 0.34)
	crt_root.add_child(crt_sub_label)

	# Heavy floor feeder cables snaking out toward chair rows
	for cx_off in [-1.8, -0.6, 0.6, 1.8]:
		var cable := MeshInstance3D.new()
		cable.mesh = _cyl_mesh(0.065, 0.065, 5.2, 8)
		cable.rotation.x = PI * 0.5
		cable.rotation.y = float(cx_off) * -0.18
		cable.position = Vector3(float(cx_off) * 0.75, 0.04, -2.6)
		cable.material_override = cable_mat
		root.add_child(cable)

	# 5. Coach Overseer Podium (flanking left of transformer, angled toward players)
	var podium_root := Node3D.new()
	podium_root.name = "CoachPodium"
	podium_root.position = Vector3(-4.1, 0.0, -4.5)
	podium_root.rotation.y = 0.28
	root.add_child(podium_root)

	var pod_base := MeshInstance3D.new()
	pod_base.mesh = _box_mesh(Vector3(1.9, 0.55, 1.7))
	pod_base.position = Vector3(0.0, 0.275, 0.0)
	pod_base.material_override = trim_mat
	podium_root.add_child(pod_base)

	var pod_trim := MeshInstance3D.new()
	pod_trim.mesh = _box_mesh(Vector3(1.96, 0.12, 1.76))
	pod_trim.position = Vector3(0.0, 0.52, 0.0)
	pod_trim.material_override = hazard_mat
	podium_root.add_child(pod_trim)

	var lectern := MeshInstance3D.new()
	lectern.mesh = _box_mesh(Vector3(1.25, 0.46, 0.24))
	lectern.position = Vector3(0.0, 0.78, 0.62)
	lectern.material_override = rust_mat
	podium_root.add_child(lectern)

	var lectern_top := MeshInstance3D.new()
	lectern_top.mesh = _box_mesh(Vector3(1.32, 0.07, 0.34))
	lectern_top.position = Vector3(0.0, 1.03, 0.62)
	lectern_top.rotation_degrees.x = 10.0
	lectern_top.material_override = panel_mat
	podium_root.add_child(lectern_top)

	var coach_mount := Node3D.new()
	coach_mount.name = "CoachMount"
	coach_mount.position = Vector3(0.0, 0.55, -0.05)
	podium_root.add_child(coach_mount)

	var coach_root: Node3D = null
	var coach_anim: AnimationPlayer = null
	var coach_deagle_node: Node3D = null

	var coach_packed = load_optional(GLB_COACH_DEAGLE)
	if not (coach_packed is PackedScene):
		coach_packed = load_optional(GLB_COACH)
	if coach_packed is PackedScene:
		coach_root = (coach_packed as PackedScene).instantiate() as Node3D
		coach_root.name = "CoachModel"
		coach_root.position = Vector3.ZERO
		coach_root.scale = Vector3(0.60, 0.60, 0.60)
		coach_mount.add_child(coach_root)
		coach_anim = coach_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if coach_anim != null:
			var clib := AnimationLibrary.new()
			var alook = load_optional(ANIM_COACH_LOOK)
			if alook is Animation:
				var dlook: Animation = (alook as Animation).duplicate()
				dlook.loop_mode = Animation.LOOP_LINEAR
				clib.add_animation(&"look", dlook)
			var adeagle = load_optional(ANIM_COACH_DEAGLE)
			if adeagle is Animation:
				clib.add_animation(&"deagle", (adeagle as Animation).duplicate())
			if not clib.get_animation_list().is_empty():
				coach_anim.add_animation_library(&"vg_coach", clib)
				if coach_anim.has_animation(&"vg_coach/look"):
					coach_anim.play(&"vg_coach/look")
		# Check for a deagle child mesh if using deagle GLB
		coach_deagle_node = coach_root.find_child("*deagle*", true, false) as Node3D
	else:
		var ov: Dictionary = _build_procedural_overseer()
		coach_root = ov["node"] as Node3D
		coach_deagle_node = ov["deagle"] as Node3D
		coach_mount.add_child(coach_root)

	if cfg_script != null:
		# Keep parameter referenced cleanly without warnings
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
		"fluorescent_mats": fluorescent_mats,
		"coach_root": coach_root,
		"coach_anim": coach_anim,
		"coach_deagle_node": coach_deagle_node,
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
			char_mesh.set_surface_override_material(0, suit_mat)
			overlay_mats.append(suit_mat)

			var hands_tex = load_optional("res://minigames/exploding_collar_race/models/main character2/main character2_main character hands boots.png")
			if hands_tex is Texture2D:
				var hands_mat := StandardMaterial3D.new()
				hands_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				hands_mat.albedo_texture = hands_tex as Texture2D
				hands_mat.roughness = 0.76
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

	var suit_mat := _make_mat(accent_color.lerp(Color(0.20, 0.18, 0.17), 0.25), 0.18, 0.56)
	var pants_mat := _make_mat(Color(0.18, 0.17, 0.18), 0.12, 0.72)
	var skin_mat := _make_mat(Color(0.90, 0.76, 0.62), 0.04, 0.65)
	var boot_mat := _make_mat(Color(0.12, 0.10, 0.09), 0.25, 0.62)
	var overlay_mats: Array = [suit_mat, skin_mat]

	# Seated thighs + shins + boots (+Z forward toward transformer)
	for sx in [-0.14, 0.14]:
		var thigh := MeshInstance3D.new()
		thigh.mesh = _cyl_mesh(0.095, 0.09, 0.42, 10)
		thigh.rotation.x = PI * 0.5
		thigh.position = Vector3(float(sx), 0.56, 0.18)
		thigh.material_override = pants_mat
		body_root.add_child(thigh)

		var shin := MeshInstance3D.new()
		shin.mesh = _cyl_mesh(0.085, 0.075, 0.44, 10)
		shin.position = Vector3(float(sx), 0.34, 0.36)
		shin.material_override = pants_mat
		body_root.add_child(shin)

		var boot := MeshInstance3D.new()
		boot.mesh = _box_mesh(Vector3(0.14, 0.10, 0.22))
		boot.position = Vector3(float(sx), 0.11, 0.40)
		boot.material_override = boot_mat
		body_root.add_child(boot)

	# Torso & collar
	var torso := MeshInstance3D.new()
	torso.mesh = _cyl_mesh(0.25, 0.23, 0.58, 12)
	torso.position = Vector3(0.0, 0.88, -0.04)
	torso.material_override = suit_mat
	body_root.add_child(torso)

	# Left (+X) lever-reaching arm + right (-X) resting arm
	var arm_l := MeshInstance3D.new()
	arm_l.mesh = _cyl_mesh(0.07, 0.065, 0.44, 10)
	arm_l.rotation = Vector3(-0.92, 0.0, -0.14)
	arm_l.position = Vector3(0.32, 0.84, 0.12)
	arm_l.material_override = suit_mat
	body_root.add_child(arm_l)

	var arm_r := MeshInstance3D.new()
	arm_r.mesh = _cyl_mesh(0.07, 0.065, 0.44, 10)
	arm_r.rotation = Vector3(-0.85, 0.0, 0.14)
	arm_r.position = Vector3(-0.32, 0.84, 0.10)
	arm_r.material_override = suit_mat
	body_root.add_child(arm_r)

	# Head + expressive eyes
	var head := MeshInstance3D.new()
	head.mesh = _box_mesh(Vector3(0.36, 0.34, 0.34))
	head.position = Vector3(0.0, 1.36, -0.02)
	head.material_override = skin_mat
	body_root.add_child(head)

	var eye_mat := _make_mat(Color(0.06, 0.06, 0.06), 0.1, 0.2)
	for ex in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		eye.mesh = _box_mesh(Vector3(0.055, 0.075, 0.04))
		eye.position = Vector3(float(ex), 1.38, 0.16)
		eye.material_override = eye_mat
		body_root.add_child(eye)

	# Stylized procedural glasses (based on customization or seat index)
	var show_glasses: bool = (absi(seat_index) % 2 == 0)
	if customization.size() >= 2:
		show_glasses = not str(customization[1]).strip_edges().is_empty()
	if show_glasses:
		var frame_mat := _make_mat(Color(0.14, 0.14, 0.16), 0.65, 0.28)
		var glasses := MeshInstance3D.new()
		glasses.mesh = _box_mesh(Vector3(0.30, 0.09, 0.06))
		glasses.position = Vector3(0.0, 1.39, 0.18)
		glasses.material_override = frame_mat
		body_root.add_child(glasses)

	# Procedural industrial hat variants
	var hat_idx: int = absi(seat_index) % 4
	if not customization.is_empty():
		var hname: String = str(customization[0]).strip_edges().to_lower()
		if HAT_COSMETIC_BY_NAME.has(hname):
			hat_idx = int(HAT_COSMETIC_BY_NAME[hname]) % 4
	var hat_node := Node3D.new()
	hat_node.name = "ProceduralHat"
	hat_node.position = Vector3(0.0, 1.54, -0.02)
	body_root.add_child(hat_node)

	match hat_idx:
		0: # Industrial Hard Hat
			var h_mat := _make_mat(Color(0.98, 0.74, 0.14), 0.22, 0.36)
			var dome := MeshInstance3D.new()
			dome.mesh = _sphere_mesh(0.22, 0.24, 12)
			dome.position = Vector3(0.0, 0.04, 0.0)
			dome.material_override = h_mat
			hat_node.add_child(dome)
			var brim := MeshInstance3D.new()
			brim.mesh = _box_mesh(Vector3(0.42, 0.04, 0.44))
			brim.position = Vector3(0.0, -0.01, 0.04)
			brim.material_override = h_mat
			hat_node.add_child(brim)
		1: # Traffic Cone Hat
			var c_mat := _make_mat(Color(0.96, 0.38, 0.10), 0.12, 0.46)
			var cone := MeshInstance3D.new()
			cone.mesh = _cyl_mesh(0.05, 0.19, 0.38, 12)
			cone.position = Vector3(0.0, 0.18, 0.0)
			cone.material_override = c_mat
			hat_node.add_child(cone)
		2: # Top Hat
			var t_mat := _make_mat(Color(0.14, 0.12, 0.14), 0.20, 0.48)
			var brim2 := MeshInstance3D.new()
			brim2.mesh = _cyl_mesh(0.27, 0.27, 0.03, 14)
			brim2.material_override = t_mat
			hat_node.add_child(brim2)
			var cyl := MeshInstance3D.new()
			cyl.mesh = _cyl_mesh(0.18, 0.17, 0.26, 14)
			cyl.position = Vector3(0.0, 0.14, 0.0)
			cyl.material_override = t_mat
			hat_node.add_child(cyl)
		_: # Foreman Visor Cap
			var f_mat := _make_mat(accent_color.darkened(0.22), 0.22, 0.48)
			var crown := MeshInstance3D.new()
			crown.mesh = _cyl_mesh(0.21, 0.20, 0.14, 12)
			crown.position = Vector3(0.0, 0.05, 0.0)
			crown.material_override = f_mat
			hat_node.add_child(crown)
			var peak := MeshInstance3D.new()
			peak.mesh = _box_mesh(Vector3(0.32, 0.035, 0.18))
			peak.position = Vector3(0.0, 0.01, 0.18)
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

	var iron_mat := _make_mat(Color(0.26, 0.24, 0.22), 0.72, 0.42, Color.BLACK, 0.0, false, false, TEX_METAL_PLATE, Vector3(1.0, 1.0, 1.0))
	var wood_mat := _make_mat(Color(0.36, 0.22, 0.14), 0.08, 0.74)
	var copper_mat := _make_mat(Color(0.84, 0.48, 0.22), 0.85, 0.30)
	var chair_base_mat := _make_mat(accent_color.lerp(Color(0.22, 0.20, 0.19), 0.22), 0.30, 0.42, accent_color, 0.65)

	# 1. Team/Slot-colored Insulated Base Plate
	var base_plate := MeshInstance3D.new()
	base_plate.mesh = _cyl_mesh(0.84, 0.90, 0.07, 20)
	base_plate.position = Vector3(0.0, 0.035, 0.0)
	base_plate.material_override = chair_base_mat
	root.add_child(base_plate)

	# Chair legs, seat pan & oak backrest
	for lx in [-0.34, 0.34]:
		for lz in [-0.28, 0.28]:
			var leg := MeshInstance3D.new()
			leg.mesh = _box_mesh(Vector3(0.08, 0.46, 0.08))
			leg.position = Vector3(float(lx), 0.26, float(lz))
			leg.material_override = iron_mat
			root.add_child(leg)

	var seat_pan := MeshInstance3D.new()
	seat_pan.mesh = _box_mesh(Vector3(0.78, 0.09, 0.70))
	seat_pan.position = Vector3(0.0, 0.50, 0.0)
	seat_pan.material_override = wood_mat
	root.add_child(seat_pan)

	var backrest := MeshInstance3D.new()
	backrest.mesh = _box_mesh(Vector3(0.74, 0.92, 0.10))
	backrest.position = Vector3(0.0, 0.98, -0.32)
	backrest.material_override = wood_mat
	root.add_child(backrest)

	# Iron armrests
	for ax in [-0.42, 0.42]:
		var arm_rest := MeshInstance3D.new()
		arm_rest.mesh = _box_mesh(Vector3(0.11, 0.08, 0.62))
		arm_rest.position = Vector3(float(ax), 0.78, 0.02)
		arm_rest.material_override = iron_mat
		root.add_child(arm_rest)

		var arm_post := MeshInstance3D.new()
		arm_post.mesh = _box_mesh(Vector3(0.08, 0.26, 0.10))
		arm_post.position = Vector3(float(ax), 0.63, 0.22)
		arm_post.material_override = iron_mat
		root.add_child(arm_post)

	# Overhead Copper Electrode Mast & Cable Anchor
	var mast := MeshInstance3D.new()
	mast.mesh = _cyl_mesh(0.045, 0.055, 0.85, 10)
	mast.position = Vector3(0.0, 1.78, -0.34)
	mast.material_override = iron_mat
	root.add_child(mast)

	var insulator_tip := MeshInstance3D.new()
	insulator_tip.mesh = _cyl_mesh(0.09, 0.11, 0.18, 12)
	insulator_tip.position = Vector3(0.0, 2.22, -0.34)
	insulator_tip.material_override = copper_mat
	root.add_child(insulator_tip)

	var local_anchor := Vector3(0.0, 2.30, -0.34)
	var cable_anchor: Vector3 = seat_pos + local_anchor.rotated(Vector3.UP, seat_yaw)

	# 2. Outer (+X, camera-facing) Armrest Mechanical Pull Lever (lever_pivot)
	# Idle: -0.25 rad; Pulled forward (+Z): +0.75 rad
	var lever_pivot := Node3D.new()
	lever_pivot.name = "LeverPivot"
	lever_pivot.position = Vector3(0.47, 0.82, 0.14)
	lever_pivot.rotation.x = -0.25
	root.add_child(lever_pivot)

	var lever_rod := MeshInstance3D.new()
	lever_rod.mesh = _cyl_mesh(0.025, 0.025, 0.44, 8)
	lever_rod.position = Vector3(0.0, 0.22, 0.0)
	lever_rod.material_override = copper_mat
	lever_pivot.add_child(lever_rod)

	var lever_grip := MeshInstance3D.new()
	lever_grip.mesh = _cyl_mesh(0.05, 0.05, 0.16, 10)
	lever_grip.rotation.z = PI * 0.5
	lever_grip.position = Vector3(0.04, 0.44, 0.0)
	lever_grip.material_override = _make_mat(Color(0.96, 0.28, 0.16), 0.2, 0.35)
	lever_pivot.add_child(lever_grip)

	# 3. Armrest: 2 Physical Fuse Bulbs & Red Sabotage Button
	var fuse_nodes: Array = []
	var fuse_mats: Array = []
	for fi in range(2):
		var f_mat := _make_mat(Color(0.74, 1.0, 0.45), 0.08, 0.18, Color(0.68, 1.0, 0.36), 2.3)
		var f_root := Node3D.new()
		f_root.name = "FuseBulb_%d" % fi
		f_root.position = Vector3(-0.46, 0.88, 0.02 - float(fi) * 0.18)
		root.add_child(f_root)

		var socket := MeshInstance3D.new()
		socket.mesh = _cyl_mesh(0.055, 0.065, 0.07, 10)
		socket.position = Vector3(0.0, -0.03, 0.0)
		socket.material_override = copper_mat
		f_root.add_child(socket)

		var bulb := MeshInstance3D.new()
		bulb.mesh = _sphere_mesh(0.072, 0.18, 12)
		bulb.position = Vector3(0.0, 0.08, 0.0)
		bulb.material_override = f_mat
		f_root.add_child(bulb)

		fuse_nodes.append(f_root)
		fuse_mats.append(f_mat)

	var kick_btn_mat := _make_mat(Color(0.98, 0.18, 0.14), 0.15, 0.25, Color(1.0, 0.16, 0.12), 1.8)
	var kick_housing := MeshInstance3D.new()
	kick_housing.mesh = _cyl_mesh(0.085, 0.095, 0.05, 12)
	kick_housing.position = Vector3(-0.44, 0.84, 0.24)
	kick_housing.material_override = iron_mat
	root.add_child(kick_housing)

	var kick_btn := MeshInstance3D.new()
	kick_btn.mesh = _cyl_mesh(0.068, 0.068, 0.05, 12)
	kick_btn.position = Vector3(-0.44, 0.88, 0.24)
	kick_btn.material_override = kick_btn_mat
	root.add_child(kick_btn)

	# 4. Insulated Safety Visor (snaps down over face on Bail Out: -1.05 rad raised -> 0.0 rad closed)
	var visor_pivot := Node3D.new()
	visor_pivot.name = "SafetyVisorPivot"
	visor_pivot.position = Vector3(0.0, 1.56, -0.22)
	visor_pivot.rotation.x = -1.05
	root.add_child(visor_pivot)

	var visor_bar := MeshInstance3D.new()
	visor_bar.mesh = _box_mesh(Vector3(0.50, 0.05, 0.05))
	visor_bar.position = Vector3(0.0, 0.0, 0.44)
	visor_bar.material_override = iron_mat
	visor_pivot.add_child(visor_bar)

	var visor_shield := MeshInstance3D.new()
	visor_shield.mesh = _box_mesh(Vector3(0.46, 0.26, 0.03))
	visor_shield.position = Vector3(0.0, -0.14, 0.44)
	visor_shield.material_override = _make_mat(Color(1.0, 0.76, 0.22, 0.48), 0.20, 0.15, Color(1.0, 0.72, 0.18), 0.45, true)
	visor_pivot.add_child(visor_shield)

	# 5. Seated Character Rig (Vanilla GLB + sitting anim or clean procedural fallback)
	var body_root := Node3D.new()
	body_root.name = "CharacterBodyRoot"
	root.add_child(body_root)

	var char_overlay_mats: Array = []
	var official_packed = load_optional(GLB_PLAYER)
	if official_packed is PackedScene:
		var inst: Node3D = (official_packed as PackedScene).instantiate() as Node3D
		inst.name = "OfficialSeatedRig"
		inst.position = Vector3(0.0, 0.22, -0.04)
		inst.rotation_degrees.y = 180.0
		inst.scale = Vector3(0.42, 0.42, 0.42)
		body_root.add_child(inst)
		var cust_res: Dictionary = _customize_official_seated_rig(inst, seat_index, accent_color, customization)
		char_overlay_mats = cust_res["mats"] as Array
	else:
		var proc_res: Dictionary = _build_procedural_seated_char(seat_index, accent_color, customization)
		body_root.add_child(proc_res["node"] as Node3D)
		char_overlay_mats = proc_res["mats"] as Array

	# 6. Diegetic Mini-LCD Score (footplate) & Player Nameplate (above hat) — compact & zero-overlap
	var lcd_panel := MeshInstance3D.new()
	lcd_panel.mesh = _box_mesh(Vector3(0.58, 0.16, 0.10))
	lcd_panel.position = Vector3(0.0, 0.12, 0.56)
	lcd_panel.material_override = _make_mat(Color(0.05, 0.05, 0.04), 0.35, 0.55)
	root.add_child(lcd_panel)

	var lcd_label := Label3D.new()
	lcd_label.name = "ChairLCDLabel"
	lcd_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lcd_label.no_depth_test = true
	lcd_label.font_size = 32
	lcd_label.pixel_size = 0.0056
	lcd_label.modulate = Color(1.0, 0.84, 0.28)
	lcd_label.outline_modulate = Color(0.03, 0.03, 0.02)
	lcd_label.outline_size = 9
	if cjk_font != null:
		lcd_label.font = cjk_font
	lcd_label.text = "0"
	lcd_label.position = Vector3(0.0, 0.18, 0.45)
	root.add_child(lcd_label)

	var name_label := Label3D.new()
	name_label.name = "ChairNameLabel"
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.font_size = 26
	name_label.pixel_size = 0.0062
	name_label.modulate = accent_color.lightened(0.35)
	name_label.outline_modulate = Color(0.03, 0.02, 0.02)
	name_label.outline_size = 8
	if cjk_font != null:
		name_label.font = cjk_font
	name_label.text = nickname if team_tag.is_empty() else "%s %s" % [team_tag, nickname]
	name_label.position = Vector3(0.0, 2.12, 0.0)
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
