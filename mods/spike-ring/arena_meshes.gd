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
const TEX_SIDING := "res://minigames/dvd_roomba/models/dvd roomba visuals1_dvd roomba siding.png"
const TEX_CRATE_WOOD := "res://minigames/smoke_break/models/smoke break near final3/smoke break near final3_crate3.png"
const TEX_CRATE_SUPPLY := "res://minigames/forklift_certified/models/forklift certified visuals1/forklift certified visuals1_box2.png"
const TEX_BARREL := "res://minigames/chisel_gauntlet_multiplayer/models/chisel gauntlet art2/chisel gauntlet art2_barrel.jpg"
const TEX_SCORCH := "res://textures/particles/scorch_01.png"
const TEX_SMOKE := "res://textures/particles/smoke/smoke_07.png"
const TEX_EXPLOSION_MARK := "res://textures/decals/explosion_mark.png"
const TEX_DECAL_STAIN := "res://textures/decal stain masked1.png"

const GLB_FAN := "res://minigames/smoke_break/models/smoke break fan1/smoke break fan1.glb"
const GLB_SERVER_RACK := "res://minigames/intermission_new/models/intermission server rack temp1/intermission server rack temp1.glb"
const GLB_PALLET := "res://minigames/chisel_gauntlet_multiplayer/models/chisel game pallet1/chisel game pallet1.glb"
const GLB_DEBRIS := "res://minigames/junk_platform/models/junk platform debris1/junk platform debris1.glb"
const GLB_SYRINGE := "res://minigames/knife_at_the_office/models/kato syringe2/kato syringe2.glb"
const GLB_SHOE := "res://models/shared/shoe_gib.glb"
const GLB_SPRING := "res://models/manufacture gun prop spring1/manufacture gun prop spring1.glb"
const GLB_DETONATOR := "res://minigames/chisel_gauntlet_multiplayer/models/exploding collar radio1/exploding collar radio1.glb"

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
	normal_scale: float = 0.72,
	world_triplanar: bool = false
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if not tex_path.is_empty():
		var tex = load_optional(tex_path)
		if tex is Texture2D:
			mat.albedo_texture = tex as Texture2D
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_triplanar = true
			mat.uv1_world_triplanar = world_triplanar
			mat.uv1_scale = uv_scale
	if not normal_path.is_empty():
		var norm = load_optional(normal_path)
		if norm is Texture2D:
			mat.normal_enabled = true
			mat.normal_texture = norm as Texture2D
			mat.normal_scale = normal_scale
			mat.uv1_triplanar = true
			mat.uv1_world_triplanar = world_triplanar
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func _strip_prop_collisions(node: Node) -> void:
	if node == null:
		return
	var children: Array = node.get_children()
	for raw_c in children:
		var c: Node = raw_c as Node
		if c is CollisionObject3D or c is CollisionShape3D:
			node.remove_child(c)
			c.free()
		else:
			_strip_prop_collisions(c)


static func _tint_prop_materials(node: Node, tint: Color, roughness_floor: float = 0.0) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			var surf_count: int = mi.mesh.get_surface_count()
			for s in range(surf_count):
				var base_mat := mi.get_active_material(s)
				if base_mat is StandardMaterial3D:
					var dup := (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					dup.albedo_color = dup.albedo_color * tint
					if roughness_floor > 0.0:
						dup.roughness = maxf(dup.roughness, roughness_floor)
					mi.set_surface_override_material(s, dup)
	for child in node.get_children():
		_tint_prop_materials(child as Node, tint, roughness_floor)


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


static func _resolve_player_color(idx: int, customization: Array) -> Color:
	if customization.size() >= 3:
		var suit_name: String = str(customization[2]).strip_edges().to_lower()
		if SUIT_COLOR_VALUES.has(suit_name):
			return SUIT_COLOR_VALUES[suit_name]
	return PLAYER_COLORS[idx % PLAYER_COLORS.size()]


static func build_worker_character(idx: int, net_id: int, nickname: String, customization: Array, is_local: bool, visual_scale: float = 0.90, label_y: float = 2.20) -> Dictionary:
	ensure_game_pck_mounted()
	var col: Color = _resolve_player_color(idx, customization)
	var root := Node3D.new()
	root.name = "Player_%d" % net_id

	# Ground drop shadow disc (cached mesh & material, proportional to player radius).
	var shadow := _build_ground_shadow()
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
		rig.scale = Vector3(visual_scale, visual_scale, visual_scale)
		avatar.add_child(rig)
		_customize_official_rig(rig, idx, customization)
		anim_player = _setup_official_animations(rig)
	else:
		_build_fallback_character(avatar, col)

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
	label.position = Vector3(0.0, label_y, 0.0)
	root.add_child(label)

	return {
		"root": root,
		"avatar": avatar,
		"shadow": shadow,
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


static var _shove_anim_cache: Animation = null
static var _shove_anim_checked: bool = false


static func _load_official_shove_anim() -> Animation:
	if _shove_anim_checked:
		return _shove_anim_cache
	_shove_anim_checked = true
	# 精确还原官方 Disco Dodge `shove_test` 骨骼姿态（不实例化含游戏 autoload 的 tscn，避免独立预览报错）
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
		lib.add_animation(&"shove", anim_shove)
	if anim_shoved is Animation:
		lib.add_animation(&"shoved", anim_shoved as Animation)
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


# ============================================================================
# Spike Ring / 尖刺圆环 —— 圆形竞技场与机关视觉
# ----------------------------------------------------------------------------
# 全部复用原版 Machine Party 工业纹理、Terminal F4 字体与官方角色 rig。
# 不引入任何外部素材；游戏 PCK 未挂载时 make_std_mat 自动退化为纯色材质。
# ============================================================================

static func _color_of(rgb: Array) -> Color:
	if rgb.size() >= 3:
		return Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
	return Color(0.96, 0.68, 0.22)


static func _disc(radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi


static func _box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi


static func _spike(height: float, base_radius: float, mat: Material) -> MeshInstance3D:
	## Godot 4 用 top_radius=0 的 CylinderMesh 作为圆锥尖刺。
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = base_radius
	mesh.height = height
	mesh.radial_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi


static func build_arena(radius: float, _accent_rgb: Array) -> Dictionary:
	## 构建《Machine Party》重工业车间的圆形尖刺竞技场：
	## 哑光混凝土地板 + 金属压花外警示环、高反光机械尖刺环、暗氧化铁环形井壁 + 北侧工业 CRT 控制台与排风扇。
	ensure_game_pck_mounted()
	var root := Node3D.new()
	root.name = "SpikeRingArena"

	var treadplate := make_std_mat(
		Color(0.56, 0.52, 0.48), 0.65, 0.42,
		Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.55, 0.55, 0.55), TEX_THREADPLATE_NORMAL, 0.88, true
	)
	var floor_mat := make_std_mat(
		Color(0.58, 0.55, 0.52), 0.10, 0.86,
		Color.BLACK, 0.0, false, TEX_FLOOR, Vector3(0.28, 0.28, 0.28), "", 0.72, true
	)
	var dark_iron := make_std_mat(
		Color(0.42, 0.40, 0.39), 0.62, 0.46,
		Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(0.42, 0.42, 0.42), "", 0.72, false
	)
	var rust := make_std_mat(
		Color(0.54, 0.42, 0.36), 0.50, 0.58,
		Color.BLACK, 0.0, false, TEX_RUST_PAINTED, Vector3(0.40, 0.40, 0.40), "", 0.72, false
	)
	var brass_dull := make_std_mat(
		Color(0.62, 0.48, 0.28), 0.76, 0.34,
		Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.55, 0.55, 0.55), TEX_THREADPLATE_NORMAL, 0.82, false
	)
	var spike_mat := make_std_mat(
		Color(0.82, 0.82, 0.84), 0.88, 0.22,
		Color.BLACK, 0.0, false, TEX_METAL_PLATE, Vector3(0.75, 0.75, 0.75)
	)
	var hazard_paint := make_std_mat(
		Color(0.88, 0.60, 0.18), 0.32, 0.52,
		Color(0.55, 0.34, 0.08), 0.14, false, TEX_THREADPLATE, Vector3(0.65, 0.65, 0.65), TEX_THREADPLATE_NORMAL, 0.80, true
	)
	var lamp_mat := make_std_mat(Color(0.95, 0.22, 0.10), 0.10, 0.30, Color(0.96, 0.20, 0.08), 1.8)
	var tube_mat := make_std_mat(Color(0.96, 0.94, 0.86), 0.0, 0.2, Color(0.98, 0.88, 0.70), 2.4)
	var pipe_mat := make_std_mat(
		Color(0.46, 0.42, 0.39), 0.64, 0.40,
		Color.BLACK, 0.0, false, TEX_PIPES, Vector3(0.50, 0.50, 0.50)
	)
	var nozzle_steel := make_std_mat(Color(0.76, 0.76, 0.78), 0.88, 0.22)
	var stain_tex := load_optional(TEX_DECAL_STAIN) as Texture2D

	# --- 中央圆形哑光混凝土地板（略低于 y=0，玩家站在 y=0）---
	var floor_node := _disc(radius, 0.30, floor_mat)
	floor_node.name = "Floor"
	floor_node.position = Vector3(0.0, -0.15, 0.0)
	root.add_child(floor_node)

	# 外警示环（拉丝花纹钢板 + 警示黄漆内嵌缘）与内圈同心工业刻度环（严格分层，绝不互相遮挡）
	var outer_tread := _disc(radius + 0.04, 0.012, treadplate)
	outer_tread.name = "OuterTreadplateRing"
	outer_tread.position = Vector3(0.0, 0.006, 0.0)
	root.add_child(outer_tread)

	var hazard_border := _disc(radius * 0.88, 0.014, hazard_paint)
	hazard_border.position = Vector3(0.0, 0.007, 0.0)
	root.add_child(hazard_border)

	var inner_concrete_cut := _disc(radius * 0.855, 0.016, floor_mat)
	inner_concrete_cut.position = Vector3(0.0, 0.008, 0.0)
	root.add_child(inner_concrete_cut)

	for raw_r in [radius * 0.62, radius * 0.36]:
		var ring_r: float = raw_r
		var ring := _disc(ring_r, 0.010, treadplate)
		ring.position = Vector3(0.0, 0.015, 0.0)
		root.add_child(ring)
		var inner := _disc(ring_r - 0.16, 0.012, floor_mat)
		inner.position = Vector3(0.0, 0.016, 0.0)
		root.add_child(inner)

	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		var rivet := _box(Vector3(0.14, 0.04, 0.36), dark_iron)
		rivet.position = Vector3(cos(a) * radius * 0.91, 0.02, sin(a) * radius * 0.91)
		rivet.rotation.y = -a
		root.add_child(rivet)

	# --- 外圈厚重暗氧化铁底座（顶部低于 y=0.0，避免遮挡地板压花环）---
	var wall_ring := _disc(radius + 0.42, 0.56, dark_iron)
	wall_ring.position = Vector3(0.0, -0.32, 0.0)
	root.add_child(wall_ring)
	var wall_inner := _disc(radius - 0.04, 0.58, floor_mat)
	wall_inner.position = Vector3(0.0, -0.32, 0.0)
	root.add_child(wall_inner)

	# --- 多功能环形重工业测试井壁（暗氧化铁与重锈交替，前缘保持低矮确保清晰视野）---
	var wall_segs: int = 24
	var wall_r: float = radius + 0.78
	var seg_len: float = TAU * wall_r / float(wall_segs) + 0.16
	var groove_mat := make_std_mat(Color(0.06, 0.04, 0.04), 0.7, 0.8, Color(0.55, 0.12, 0.06), 0.55)
	for wi in range(wall_segs):
		var wa: float = TAU * float(wi) / float(wall_segs)
		var is_front: bool = sin(wa) > 0.42
		var wh: float = 0.62 if is_front else 1.95
		var wpanel := _box(Vector3(0.56, wh, seg_len), dark_iron if wi % 2 == 0 else rust)
		wpanel.position = Vector3(cos(wa) * wall_r, wh * 0.5 - 0.12, sin(wa) * wall_r)
		wpanel.rotation.y = -wa
		root.add_child(wpanel)
		if not is_front:
			var slot := _box(Vector3(0.14, 0.24, seg_len), groove_mat)
			slot.position = Vector3(cos(wa) * (wall_r - 0.24), 1.02, sin(wa) * (wall_r - 0.24))
			slot.rotation.y = -wa
			root.add_child(slot)

	# 上下双层黄铜导轨卡在墙壁槽口上下沿
	for rail_y in [0.86, 1.18]:
		var laser_rail := TorusMesh.new()
		laser_rail.inner_radius = radius + 0.36
		laser_rail.outer_radius = radius + 0.52
		laser_rail.rings = 48
		laser_rail.ring_segments = 8
		var rail_mi := MeshInstance3D.new()
		rail_mi.mesh = laser_rail
		rail_mi.material_override = brass_dull
		rail_mi.position = Vector3(0.0, rail_y, 0.0)
		root.add_child(rail_mi)

	# --- 真实可收缩机械尖刺环（平时围在最外圈，最后 25 秒整体向圆心合拢）---
	var shrink_ring := Node3D.new()
	shrink_ring.name = "MechanicalSpikeRing"
	root.add_child(shrink_ring)

	var collar_torus := TorusMesh.new()
	collar_torus.inner_radius = radius - 0.10
	collar_torus.outer_radius = radius + 0.34
	collar_torus.rings = 48
	collar_torus.ring_segments = 10
	var collar_mesh := MeshInstance3D.new()
	collar_mesh.mesh = collar_torus
	collar_mesh.material_override = dark_iron
	collar_mesh.position = Vector3(0.0, 0.14, 0.0)
	shrink_ring.add_child(collar_mesh)

	var warn_strip := TorusMesh.new()
	warn_strip.inner_radius = radius - 0.18
	warn_strip.outer_radius = radius - 0.06
	warn_strip.rings = 48
	warn_strip.ring_segments = 8
	var warn_mesh := MeshInstance3D.new()
	warn_mesh.name = "ShrinkWarnRim"
	warn_mesh.mesh = warn_strip
	warn_mesh.material_override = make_std_mat(Color(0.75, 0.16, 0.08, 0.85), 0.1, 0.6, Color(0.85, 0.14, 0.05), 1.6, true)
	warn_mesh.position = Vector3(0.0, 0.04, 0.0)
	warn_mesh.visible = false
	shrink_ring.add_child(warn_mesh)

	var spike_count: int = 56
	for s in range(spike_count):
		var sa: float = TAU * float(s) / float(spike_count)
		var sp := _spike(0.95, 0.20, spike_mat)
		sp.position = Vector3(cos(sa) * (radius + 0.04), 0.38, sin(sa) * (radius + 0.04))
		sp.rotation_degrees = Vector3(0.0, -rad_to_deg(sa), 72.0)
		shrink_ring.add_child(sp)

	# --- 圆周喷嘴（12 个重型暗铁铸体 + 高反光精钢炮口）---
	var nozzles: Array = []
	for n_id in range(12):
		var na: float = TAU * float(n_id) / 12.0
		var nozzle := Node3D.new()
		nozzle.name = "Nozzle_%d" % n_id
		nozzle.position = Vector3(cos(na) * (radius + 0.48), 0.30, sin(na) * (radius + 0.48))
		nozzle.rotation.y = -na
		root.add_child(nozzle)
		var body := _box(Vector3(0.74, 0.48, 0.62), pipe_mat)
		nozzle.add_child(body)
		var muzzle := _disc(0.20, 0.46, nozzle_steel)
		muzzle.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		muzzle.position = Vector3(-0.38, 0.0, 0.0)
		nozzle.add_child(muzzle)
		var led := _box(Vector3(0.10, 0.08, 0.36), lamp_mat)
		led.position = Vector3(-0.36, 0.26, 0.0)
		nozzle.add_child(led)
		nozzles.append(nozzle)
		if n_id % 2 == 0:
			_add_floor_decal(root, stain_tex, Vector3(cos(na) * (radius - 0.55), 0.03, sin(na) * (radius - 0.55)), Vector3(2.2, 0.45, 2.2), Color(0.16, 0.13, 0.11, 0.52), na)

	# 中央环带油污/磨痕 Decal
	for ci in range(4):
		var ca: float = TAU * float(ci) / 4.0 + 0.45
		_add_floor_decal(root, stain_tex, Vector3(cos(ca) * (radius * 0.36), 0.03, sin(ca) * (radius * 0.36)), Vector3(2.6, 0.45, 2.0), Color(0.18, 0.14, 0.12, 0.46), ca + 0.7)

	# --- 北侧井壁一体式 CRT 倒计时控制台 + 两侧旋转排风扇 ---
	var crt_z: float = -radius - 0.85
	var crt_backing := _box(Vector3(14.8, 3.8, 0.92), dark_iron)
	crt_backing.position = Vector3(0.0, 2.20, crt_z - 0.54)
	root.add_child(crt_backing)
	for bx in [-7.1, 7.1]:
		var buttress := _box(Vector3(0.65, 4.1, 0.85), rust)
		buttress.position = Vector3(float(bx), 2.15, crt_z - 0.25)
		root.add_child(buttress)
	_add_floor_decal(root, stain_tex, Vector3(0.0, 0.03, -radius + 0.35), Vector3(3.6, 0.45, 2.4), Color(0.16, 0.13, 0.11, 0.55), 0.12)

	for sx in [-2.4, 2.4]:
		var strut := _box(Vector3(0.36, 2.2, 0.36), dark_iron)
		strut.position = Vector3(sx, 1.75, crt_z - 0.15)
		root.add_child(strut)
	for lx in [-4.8, 4.8]:
		var fixture := Node3D.new()
		fixture.position = Vector3(lx, 2.45, crt_z + 0.15)
		root.add_child(fixture)
		var hood := _box(Vector3(1.6, 0.14, 0.32), dark_iron)
		hood.position = Vector3(0.0, 0.08, 0.0)
		fixture.add_child(hood)
		var tube := _box(Vector3(1.4, 0.09, 0.14), tube_mat)
		fixture.add_child(tube)

	# 两侧旋转排风扇（smoke break fan1.glb，无 PCK 时回退到四叶工业扇）
	var fans: Array = []
	var fan_packed = load_optional(GLB_FAN)
	var fan_shroud_mesh := CylinderMesh.new()
	fan_shroud_mesh.top_radius = 1.02
	fan_shroud_mesh.bottom_radius = 1.08
	fan_shroud_mesh.height = 0.36
	fan_shroud_mesh.radial_segments = 20
	for fx in [-5.1, 5.1]:
		var fpos := Vector3(float(fx), 2.75, crt_z - 0.08)
		var shroud := MeshInstance3D.new()
		shroud.name = "ExhaustFanShroud_%d" % int(signf(float(fx)))
		shroud.mesh = fan_shroud_mesh
		shroud.rotation_degrees.x = 90.0
		shroud.position = fpos + Vector3(0.0, 0.0, -0.06)
		shroud.material_override = dark_iron
		root.add_child(shroud)

		var fan_mount := Node3D.new()
		fan_mount.position = fpos + Vector3(0.0, 0.0, 0.08)
		fan_mount.rotation_degrees.y = 180.0
		fan_mount.scale = Vector3(0.72, 0.72, 0.14)
		root.add_child(fan_mount)
		if fan_packed is PackedScene:
			var fan_inst: Node3D = (fan_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(fan_inst)
			var fan_mesh := fan_inst.get_node_or_null("fan_002") as Node3D
			if fan_mesh != null:
				fan_mesh.position = Vector3.ZERO
				fans.append(fan_mesh)
			else:
				fans.append(fan_inst)
			fan_mount.add_child(fan_inst)
		else:
			var hub_pivot := Node3D.new()
			for b_i in range(4):
				var blade := _box(Vector3(1.65, 0.24, 0.08), rust)
				blade.rotation_degrees.z = float(b_i) * 45.0
				hub_pivot.add_child(blade)
			fan_mount.add_child(hub_pivot)
			fans.append(hub_pivot)

	var term_font: Font = load_terminal_font()
	var crt_root := Node3D.new()
	crt_root.name = "CRTBackWall"
	crt_root.position = Vector3(0.0, 3.05, crt_z + 0.05)
	crt_root.rotation_degrees = Vector3(-30.0, 0.0, 0.0)
	root.add_child(crt_root)
	var crt_frame := _box(Vector3(6.8, 2.8, 0.45), dark_iron)
	crt_root.add_child(crt_frame)
	var crt_screen := _box(Vector3(6.2, 2.3, 0.08), make_std_mat(Color(0.03, 0.04, 0.03), 0.1, 0.65, Color(0.08, 0.14, 0.08), 0.30))
	crt_screen.position = Vector3(0.0, 0.0, 0.22)
	crt_root.add_child(crt_screen)

	var timer_label := Label3D.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "01:00"
	timer_label.font_size = 114
	timer_label.pixel_size = 0.014
	timer_label.modulate = Color(0.68, 1.0, 0.72)
	timer_label.outline_modulate = Color(0.0, 0.0, 0.0)
	timer_label.outline_size = 12
	timer_label.position = Vector3(0.0, 0.28, 0.30)
	if term_font != null:
		timer_label.font = term_font
	crt_root.add_child(timer_label)

	var phase_label := Label3D.new()
	phase_label.name = "PhaseLabel"
	phase_label.text = "SPIKE RING // BRASS FOUNDRY"
	phase_label.font_size = 32
	phase_label.pixel_size = 0.010
	phase_label.modulate = Color(0.56, 0.88, 0.62)
	phase_label.outline_modulate = Color(0.0, 0.0, 0.0)
	phase_label.outline_size = 8
	phase_label.position = Vector3(0.0, -0.68, 0.30)
	if term_font != null:
		phase_label.font = term_font
	crt_root.add_child(phase_label)

	# --- 舞台与北侧控制台暖炉轮廓补光（照亮 CRT 机壳、排风扇与井壁金属质感）---
	var fill := OmniLight3D.new()
	fill.name = "ForgeGlow"
	fill.position = Vector3(0.0, 8.0, 1.0)
	fill.light_color = Color(0.96, 0.70, 0.44)
	fill.light_energy = 1.65
	fill.omni_range = radius * 2.1
	fill.shadow_enabled = false
	root.add_child(fill)

	for fx_l in [-4.8, 4.8]:
		var crt_glow := OmniLight3D.new()
		crt_glow.name = "ForgeGlowNorth_%d" % int(signf(float(fx_l)))
		crt_glow.position = Vector3(float(fx_l), 3.6, crt_z + 1.8)
		crt_glow.light_color = Color(1.0, 0.74, 0.42)
		crt_glow.light_energy = 2.6
		crt_glow.omni_range = 11.0
		crt_glow.shadow_enabled = false
		root.add_child(crt_glow)

	return {
		"root": root,
		"timer_label": timer_label,
		"phase_label": phase_label,
		"shrink_ring": shrink_ring,
		"shrink_warn": warn_mesh,
		"nozzles": nozzles,
		"fans": fans,
	}


static func build_surroundings(radius: float, _accent_rgb: Array) -> Node3D:
	## 重工业坑底格栅与外围甲板装饰（机柜、风化木托盘、废铁堆与焦痕 Decal，绝不遮挡舞台视野）。
	ensure_game_pck_mounted()
	var root := Node3D.new()
	root.name = "Surroundings"
	var outer_r: float = radius * 2.40
	var deck_y: float = -0.37

	var pit_floor := make_std_mat(
		Color(0.46, 0.38, 0.32), 0.38, 0.72,
		Color.BLACK, 0.0, false, TEX_RUST_PAINTED, Vector3(0.24, 0.24, 0.24), "", 0.72, true
	)
	var grate := make_std_mat(
		Color(0.54, 0.50, 0.47), 0.48, 0.64,
		Color.BLACK, 0.0, false, TEX_GRATE, Vector3(0.55, 0.55, 0.55), "", 0.72, true
	)
	var dark_brass := make_std_mat(
		Color(0.54, 0.42, 0.26), 0.68, 0.46,
		Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.50, 0.50, 0.50), TEX_THREADPLATE_NORMAL, 0.85, false
	)
	var pipe := make_std_mat(
		Color(0.46, 0.42, 0.39), 0.62, 0.46,
		Color.BLACK, 0.0, false, TEX_PIPES, Vector3(0.45, 0.45, 0.45)
	)
	var dark_iron := make_std_mat(
		Color(0.40, 0.38, 0.37), 0.62, 0.46,
		Color.BLACK, 0.0, false, TEX_DARK_METAL, Vector3(0.42, 0.42, 0.42)
	)
	var rust_fallback := make_std_mat(
		Color(0.48, 0.36, 0.30), 0.45, 0.65,
		Color.BLACK, 0.0, false, TEX_RUST_PAINTED, Vector3(0.45, 0.45, 0.45)
	)
	var pallet_mat := make_std_mat(
		Color(0.36, 0.30, 0.25), 0.15, 0.85,
		Color.BLACK, 0.0, false, TEX_HEAVY_RUST, Vector3(0.75, 0.75, 0.75)
	)

	var ground := _disc(outer_r, 0.60, pit_floor)
	ground.position = Vector3(0.0, -0.75, 0.0)
	root.add_child(ground)
	var grating := _disc(radius + 4.80, 0.06, grate)
	grating.position = Vector3(0.0, -0.40, 0.0)
	root.add_child(grating)
	var deck_rim := TorusMesh.new()
	deck_rim.inner_radius = radius + 4.68
	deck_rim.outer_radius = radius + 4.96
	deck_rim.rings = 48
	deck_rim.ring_segments = 8
	var deck_rim_mi := MeshInstance3D.new()
	deck_rim_mi.mesh = deck_rim
	deck_rim_mi.material_override = dark_iron
	deck_rim_mi.position = Vector3(0.0, -0.35, 0.0)
	root.add_child(deck_rim_mi)

	# 12 条径向铸铁管道
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		var inner: float = radius + 0.90
		var outer: float = radius + 4.60
		var mid_r: float = (inner + outer) * 0.5
		var seg := _box(Vector3(outer - inner, 0.30, 0.36), pipe)
		seg.position = Vector3(cos(a) * mid_r, -0.22, sin(a) * mid_r)
		seg.rotation.y = -a
		root.add_child(seg)

	# 8 组深色静态大齿轮
	for g in range(8):
		var ga: float = TAU * float(g) / 8.0 + TAU / 16.0
		var gr: float = radius + 2.80
		var gr_root := Node3D.new()
		gr_root.position = Vector3(cos(ga) * gr, -0.28, sin(ga) * gr)
		root.add_child(gr_root)
		var plate := _disc(1.05, 0.20, dark_brass)
		gr_root.add_child(plate)
		for t in range(8):
			var ta: float = TAU * float(t) / 8.0
			var tooth := _box(Vector3(0.28, 0.22, 0.32), grate)
			tooth.position = Vector3(cos(ta) * 1.05, 0.0, sin(ta) * 1.05)
			tooth.rotation.y = -ta
			gr_root.add_child(tooth)
		var hub := _disc(0.26, 0.26, pipe)
		hub.position = Vector3(0.0, 0.14, 0.0)
		gr_root.add_child(hub)

	# --- 外围坑底甲板原版 .glb 工业道具（严禁进入竞技场内或遮挡前侧视线）---
	var rack_packed = load_optional(GLB_SERVER_RACK)
	var pallet_packed = load_optional(GLB_PALLET)
	var debris_packed = load_optional(GLB_DEBRIS)

	# 1) 工业控制机柜（紧贴北侧 CRT 护壁两侧钢柱，深色金属色调与结构融为一体）
	var rack_specs: Array = [
		[Vector3(-8.2, deck_y, -(radius + 0.55)), 16.0, 0.43],
		[Vector3(8.2, deck_y, -(radius + 0.55)), -16.0, 0.43],
	]
	for rs_raw in rack_specs:
		var rs: Array = rs_raw as Array
		var rpos: Vector3 = rs[0] as Vector3
		var ryaw: float = float(rs[1])
		var rscale: float = float(rs[2])
		if rack_packed is PackedScene:
			var rinst: Node3D = (rack_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(rinst)
			_tint_prop_materials(rinst, Color(0.62, 0.58, 0.54), 0.55)
			rinst.position = rpos
			rinst.rotation_degrees.y = ryaw
			rinst.scale = Vector3(rscale, rscale, rscale)
			root.add_child(rinst)
		else:
			var rbox := _box(Vector3(0.85, 2.35, 1.10), dark_iron)
			rbox.position = rpos + Vector3(0.0, 1.18, 0.0)
			rbox.rotation_degrees.y = ryaw
			root.add_child(rbox)

	# 2) 风化木/锈铁托盘（Cube_019 原点归零 + 深暗风化木色覆盖）
	var pallet_specs: Array = [
		[Vector3(-(radius + 2.05), deck_y + 0.13, -radius * 0.06), 14.0, 0.54],
		[Vector3(radius + 2.05, deck_y + 0.13, radius * 0.12), -16.0, 0.54],
	]
	for ps_raw in pallet_specs:
		var ps: Array = ps_raw as Array
		var ppos: Vector3 = ps[0] as Vector3
		var pyaw: float = float(ps[1])
		var pscale: float = float(ps[2])
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
			var pbox := _box(Vector3(1.4, 0.22, 1.1), pallet_mat)
			pbox.position = ppos
			pbox.rotation_degrees.y = pyaw
			root.add_child(pbox)

	# 3) 工业废铁堆（min.y = -0.725，按 0.725 * scale 抬高贴地，深锈暗铁着色并远离北侧机柜）
	var scrap_placements: Array = [
		[Vector3(-(radius + 2.15), 0.0, radius * 0.38), 26.0, 0.62],
		[Vector3(radius + 2.25, 0.0, -radius * 0.22), -34.0, 0.58],
		[Vector3(-(radius + 2.10), 0.0, -radius * 0.28), 108.0, 0.56],
	]
	for sp_raw in scrap_placements:
		var sp: Array = sp_raw as Array
		var spos: Vector3 = sp[0] as Vector3
		var syaw: float = float(sp[1])
		var sscale: float = float(sp[2])
		if debris_packed is PackedScene:
			var dinst: Node3D = (debris_packed as PackedScene).instantiate() as Node3D
			_strip_prop_collisions(dinst)
			_tint_prop_materials(dinst, Color(0.60, 0.52, 0.46), 0.68)
			dinst.position = Vector3(spos.x, deck_y + 0.725 * sscale, spos.z)
			dinst.rotation_degrees.y = syaw
			dinst.scale = Vector3(sscale, sscale, sscale)
			root.add_child(dinst)
		else:
			var dbox := _box(Vector3(0.95, 0.75, 0.95), rust_fallback)
			dbox.position = Vector3(spos.x, deck_y + 0.38, spos.z)
			dbox.rotation_degrees.y = syaw
			root.add_child(dbox)

	# 4) 外围坑底焦痕 Decal + 暖色边缘照明（防止外圈铁栅死黑）
	var scorch_tex := load_optional(TEX_EXPLOSION_MARK) as Texture2D
	for sc_i in range(4):
		var sa: float = TAU * float(sc_i) / 4.0 + 0.35
		var sr: float = radius + 2.35
		_add_floor_decal(root, scorch_tex, Vector3(cos(sa) * sr, deck_y + 0.02, sin(sa) * sr), Vector3(2.8, 0.5, 2.8), Color(0.16, 0.12, 0.10, 0.62), sa)

	for side_x in [-1.0, 1.0]:
		var deck_glow := OmniLight3D.new()
		deck_glow.name = "OuterDeckGlow_%s" % ("E" if side_x > 0.0 else "W")
		deck_glow.position = Vector3(side_x * (radius + 2.4), 4.6, -radius * 0.45)
		deck_glow.light_color = Color(1.0, 0.72, 0.40)
		deck_glow.light_energy = 3.5
		deck_glow.omni_range = 16.5
		deck_glow.shadow_enabled = false
		root.add_child(deck_glow)

	return root


static var _hazard_assets: Dictionary = {}
static var _saw_asset_cache: Dictionary = {}
static var _shadow_assets: Dictionary = {}
static var _item_assets: Dictionary = {}


static func clear_caches() -> void:
	_hazard_assets.clear()
	_saw_asset_cache.clear()
	_shadow_assets.clear()
	_item_assets.clear()
	_shove_anim_cache = null
	_shove_anim_checked = false


static func _build_ground_shadow() -> MeshInstance3D:
	if _shadow_assets.is_empty():
		var m := CylinderMesh.new()
		m.top_radius = 0.48
		m.bottom_radius = 0.48
		m.height = 0.012
		m.radial_segments = 16
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.02, 0.02, 0.02, 0.56)
		_shadow_assets = {"mesh": m, "mat": mat}
	var mi := MeshInstance3D.new()
	mi.name = "GroundShadow"
	mi.mesh = _shadow_assets["mesh"]
	mi.material_override = _shadow_assets["mat"]
	mi.position = Vector3(0.0, 0.03, 0.0)
	return mi


static func _get_hazard_assets() -> Dictionary:
	if not _hazard_assets.is_empty():
		return _hazard_assets
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3.ONE
	var floor_spike_mesh := CylinderMesh.new()
	floor_spike_mesh.top_radius = 0.015
	floor_spike_mesh.bottom_radius = 0.14
	floor_spike_mesh.height = 0.85
	floor_spike_mesh.radial_segments = 8
	var floor_spike_tip_mesh := CylinderMesh.new()
	floor_spike_tip_mesh.top_radius = 0.015
	floor_spike_tip_mesh.bottom_radius = 0.11
	floor_spike_tip_mesh.height = 0.18
	floor_spike_tip_mesh.radial_segments = 8
	var turret_housing_mesh := BoxMesh.new()
	turret_housing_mesh.size = Vector3(0.76, 0.44, 0.56)
	var turret_barrel_mesh := CylinderMesh.new()
	turret_barrel_mesh.top_radius = 0.14
	turret_barrel_mesh.bottom_radius = 0.18
	turret_barrel_mesh.height = 0.42
	turret_barrel_mesh.radial_segments = 12
	var pylon_lens_mesh := SphereMesh.new()
	pylon_lens_mesh.radius = 0.15
	pylon_lens_mesh.height = 0.30
	pylon_lens_mesh.radial_segments = 12
	pylon_lens_mesh.rings = 8
	var bearing_mesh := CylinderMesh.new()
	bearing_mesh.top_radius = 0.36
	bearing_mesh.bottom_radius = 0.36
	bearing_mesh.height = 0.30
	bearing_mesh.radial_segments = 16
	var push_arc_mesh := BoxMesh.new()
	push_arc_mesh.size = Vector3(1.45, 0.08, 0.28)
	_hazard_assets = {
		"unit_box": unit_box,
		"floor_spike_mesh": floor_spike_mesh,
		"floor_spike_tip_mesh": floor_spike_tip_mesh,
		"turret_housing_mesh": turret_housing_mesh,
		"turret_barrel_mesh": turret_barrel_mesh,
		"pylon_lens_mesh": pylon_lens_mesh,
		"bearing_mesh": bearing_mesh,
		"push_arc_mesh": push_arc_mesh,
		"warn_mat": make_std_mat(Color(0.95, 0.20, 0.08, 0.52), 0.0, 0.9, Color(1.0, 0.24, 0.06), 1.9, true),
		"rail_mat": make_std_mat(Color(1.0, 0.68, 0.14, 0.80), 0.0, 0.7, Color(1.0, 0.50, 0.08), 1.6, true),
		"saw_line_mat": make_std_mat(Color(1.0, 0.86, 0.30, 0.90), 0.0, 0.6, Color(1.0, 0.80, 0.20), 2.2, true),
		"spike_slot_mat": make_std_mat(Color(0.14, 0.13, 0.13), 0.78, 0.48, Color(0.55, 0.10, 0.05), 0.45, false, TEX_GRATE, Vector3(0.85, 0.85, 0.85)),
		"spike_steel_mat": make_std_mat(Color(0.84, 0.85, 0.88), 0.88, 0.22, Color(0.28, 0.10, 0.06), 0.28),
		"laser_glow_mat": make_std_mat(Color(0.75, 0.12, 0.06, 0.28), 0.0, 0.90, Color(0.85, 0.10, 0.04), 1.0, true, TEX_SCORCH, Vector3(1.0, 1.0, 1.0)),
		"laser_sight_mat": make_std_mat(Color(1.0, 0.18, 0.10, 0.65), 0.0, 0.30, Color(1.0, 0.14, 0.06), 2.4, true),
		"laser_sheath_mat": make_std_mat(Color(0.95, 0.14, 0.08, 0.72), 0.0, 0.50, Color(1.0, 0.12, 0.05), 3.0, true),
		"laser_core_mat": make_std_mat(Color(1.0, 0.88, 0.78, 1.0), 0.0, 0.25, Color(1.0, 0.48, 0.26), 4.6, true),
		"pylon_iron_mat": make_std_mat(Color(0.82, 0.82, 0.85), 0.88, 0.22, Color.BLACK, 0.0, false, TEX_METAL_PLATE, Vector3(0.8, 0.8, 0.8)),
		"pylon_brass_mat": make_std_mat(Color(0.76, 0.64, 0.44), 0.88, 0.22, Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.6, 0.6, 0.6)),
		"pylon_lens_mat": make_std_mat(Color(0.95, 0.18, 0.08), 0.1, 0.2, Color(1.0, 0.16, 0.06), 3.4),
		"track_mat": make_std_mat(Color(0.26, 0.25, 0.26), 0.80, 0.36, Color.BLACK, 0.0, false, TEX_GRATE, Vector3(0.8, 0.8, 0.8)),
		"bearing_mat": make_std_mat(Color(0.52, 0.42, 0.26), 0.82, 0.32, Color.BLACK, 0.0, false, TEX_THREADPLATE, Vector3(0.7, 0.7, 0.7)),
		"push_wave_mat": make_std_mat(Color(1.0, 0.78, 0.28, 0.72), 0.0, 0.4, Color(1.0, 0.68, 0.18), 2.8, true),
	}
	return _hazard_assets


static func build_push_wave() -> Node3D:
	var assets := _get_hazard_assets()
	var root := Node3D.new()
	root.name = "PushWave"
	var arc := MeshInstance3D.new()
	arc.mesh = assets["push_arc_mesh"]
	arc.material_override = assets["push_wave_mat"]
	arc.position = Vector3(0.0, 0.85, 0.95)
	root.add_child(arc)
	return root


static func _scaled_box(size: Vector3, mat: Material, unit_box: BoxMesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = unit_box
	mi.scale = size
	mi.material_override = mat
	return mi


static func _get_saw_assets(radius: float) -> Dictionary:
	var key := int(round(radius * 1000.0))
	if _saw_asset_cache.has(key):
		return _saw_asset_cache[key]
	var blade_mesh := CylinderMesh.new()
	blade_mesh.top_radius = radius
	blade_mesh.bottom_radius = radius
	blade_mesh.height = 0.16
	blade_mesh.radial_segments = 24
	var tooth_mesh := BoxMesh.new()
	tooth_mesh.size = Vector3(0.16, 0.18, 0.20)
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.18
	hub_mesh.bottom_radius = 0.18
	hub_mesh.height = 0.22
	hub_mesh.radial_segments = 16
	var assets := {
		"blade_mesh": blade_mesh,
		"blade_mat": make_std_mat(Color(0.76, 0.78, 0.82), 0.88, 0.22, Color(0.25, 0.28, 0.32), 0.22),
		"tooth_mesh": tooth_mesh,
		"tooth_mat": make_std_mat(Color(0.90, 0.92, 0.94), 0.88, 0.22),
		"hub_mesh": hub_mesh,
		"hub_mat": make_std_mat(Color(0.92, 0.62, 0.16), 0.78, 0.26, Color(0.9, 0.5, 0.1), 0.8),
	}
	_saw_asset_cache[key] = assets
	return assets


static func build_hazard_warning(type: int, a: Vector2, b: Vector2, width: float) -> Node3D:
	## 地面红色警示带 + 喷火口亮灯 / 轨迹预警线。
	var assets := _get_hazard_assets()
	var unit_box: BoxMesh = assets["unit_box"]
	var root := Node3D.new()
	root.name = "HazardWarning"
	var mid: Vector2 = (a + b) * 0.5
	var length: float = a.distance_to(b)
	var angle: float = atan2(b.y - a.y, b.x - a.x)
	var strip := _scaled_box(Vector3(length, 0.02, maxf(0.10, width)), assets["warn_mat"], unit_box)
	strip.position = Vector3(mid.x, 0.045, mid.y)
	strip.rotation.y = -angle
	root.add_child(strip)
	# 两侧虚线导轨，机械风格的路标感
	var rail_mat: Material = assets["rail_mat"]
	for raw_side in [-1.0, 1.0]:
		var side: float = raw_side
		var off: Vector2 = Vector2(-sin(angle), cos(angle)) * (width * 0.5 + 0.06) * side
		var rail := _scaled_box(Vector3(length, 0.02, 0.06), rail_mat, unit_box)
		rail.position = Vector3(mid.x + off.x, 0.055, mid.y + off.y)
		rail.rotation.y = -angle
		root.add_child(rail)
	if type == 0:  # 伸缩地刺带预警：格栅槽口 + 微微探头的金属刺尖
		var tip_mesh: CylinderMesh = assets["floor_spike_tip_mesh"]
		var tip_mat: Material = assets["spike_steel_mat"]
		var count: int = maxi(4, int(length / 0.85))
		var perp := Vector2(-sin(angle), cos(angle)) * (width * 0.22)
		for i in range(count):
			var t: float = (float(i) + 0.5) / float(count)
			var p: Vector2 = a.lerp(b, t)
			for side in [-1.0, 1.0]:
				var tip := MeshInstance3D.new()
				tip.mesh = tip_mesh
				tip.material_override = tip_mat
				var sp: Vector2 = p + perp * side
				tip.position = Vector3(sp.x, 0.09, sp.y)
				root.add_child(tip)
	elif type == 1:  # HZ_SAW
		# 电锯额外画一条细轨迹中心线
		var line := _scaled_box(Vector3(length, 0.02, 0.05), assets["saw_line_mat"], unit_box)
		line.position = Vector3(mid.x, 0.065, mid.y)
		line.rotation.y = -angle
		root.add_child(line)
	return root


static func build_hazard_active(type: int, a: Vector2, b: Vector2, width: float) -> Node3D:
	## 激活视觉：伸缩机械地刺带 / 电锯轨道。
	var assets := _get_hazard_assets()
	var unit_box: BoxMesh = assets["unit_box"]
	var root := Node3D.new()
	root.name = "HazardActive"
	var mid: Vector2 = (a + b) * 0.5
	var length: float = a.distance_to(b)
	var angle: float = atan2(b.y - a.y, b.x - a.x)
	if type == 0:  # 伸缩机械地刺带：深铁格栅槽 + 双排高耸钢刺猛然向上刺出
		var slot := _scaled_box(Vector3(length, 0.05, width), assets["spike_slot_mat"], unit_box)
		slot.position = Vector3(mid.x, 0.035, mid.y)
		slot.rotation.y = -angle
		root.add_child(slot)
		var spike_mesh: CylinderMesh = assets["floor_spike_mesh"]
		var spike_mat: Material = assets["spike_steel_mat"]
		var seg_count: int = maxi(5, int(length / 0.72))
		var perp := Vector2(-sin(angle), cos(angle)) * (width * 0.24)
		for i in range(seg_count):
			var t: float = (float(i) + 0.5) / float(seg_count)
			var p: Vector2 = a.lerp(b, t)
			for side in [-1.0, 1.0]:
				var sp := MeshInstance3D.new()
				sp.mesh = spike_mesh
				sp.material_override = spike_mat
				var q: Vector2 = p + perp * side
				sp.position = Vector3(q.x, 0.43, q.y)
				root.add_child(sp)
	else:
		# 电锯轨道：贴地细长金属轨 + 两端轴承
		var track := _scaled_box(Vector3(length, 0.06, width * 0.55), assets["track_mat"], unit_box)
		track.position = Vector3(mid.x, 0.05, mid.y)
		track.rotation.y = -angle
		root.add_child(track)
		for raw_endp in [a, b]:
			var endp: Vector2 = raw_endp
			var bearing := MeshInstance3D.new()
			bearing.mesh = assets["bearing_mesh"]
			bearing.material_override = assets["bearing_mat"]
			bearing.position = Vector3(endp.x, 0.14, endp.y)
			root.add_child(bearing)
	return root


static func _set_seg(node: Node3D, p0: Vector2, p1: Vector2, y: float, h: float, thick: float) -> void:
	if node == null:
		return
	var seg_len: float = p0.distance_to(p1)
	if seg_len < 0.12:
		node.visible = false
		return
	node.visible = true
	var mid: Vector2 = (p0 + p1) * 0.5
	var ang: float = atan2(p1.y - p0.y, p1.x - p0.x)
	node.position = Vector3(mid.x, y, mid.y)
	node.rotation.y = -ang
	node.scale = Vector3(seg_len, h, thick)


static func build_laser_rig(a: Vector2, b: Vector2, width: float, gap_t: float, gap_width: float) -> Node3D:
	## 一体化带缺口激光组：预警阶段滑车即就位并拉出同高度(y=1.02m)细红瞄准线，
	## 激活阶段无缝膨胀点燃为两段深红切割光束，中间保留清晰可钻过的安全缺口。
	var assets := _get_hazard_assets()
	var unit_box: BoxMesh = assets["unit_box"]
	var root := Node3D.new()
	root.name = "LaserRig"

	for seg_name in ["Sight1", "Sight2"]:
		var sight := _scaled_box(Vector3(1.0, 0.025, 0.03), assets["laser_sight_mat"], unit_box)
		sight.name = seg_name
		root.add_child(sight)
	for seg_name in ["Sheath1", "Sheath2"]:
		var sh := _scaled_box(Vector3(1.0, 0.10, maxf(0.10, width * 0.24)), assets["laser_sheath_mat"], unit_box)
		sh.name = seg_name
		sh.visible = false
		root.add_child(sh)
	for seg_name in ["Core1", "Core2"]:
		var co := _scaled_box(Vector3(1.0, 0.045, 0.05), assets["laser_core_mat"], unit_box)
		co.name = seg_name
		co.visible = false
		root.add_child(co)
	for seg_name in ["Glow1", "Glow2"]:
		var gg := _scaled_box(Vector3(1.0, 0.02, maxf(0.45, width * 1.1)), assets["laser_glow_mat"], unit_box)
		gg.name = seg_name
		gg.visible = false
		root.add_child(gg)

	# 嵌入式墙壁雷射炮台（卡在环形井壁 y=1.02m 凹槽内，炮管水平向场地内对射）
	var pylon_names := ["PylonA", "PylonB"]
	for pi in range(2):
		var turret := Node3D.new()
		turret.name = pylon_names[pi]
		var housing := MeshInstance3D.new()
		housing.mesh = assets["turret_housing_mesh"]
		housing.material_override = assets["pylon_iron_mat"]
		housing.position = Vector3(0.0, 1.02, -0.22)
		turret.add_child(housing)
		var barrel := MeshInstance3D.new()
		barrel.mesh = assets["turret_barrel_mesh"]
		barrel.material_override = assets["pylon_brass_mat"]
		barrel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		barrel.position = Vector3(0.0, 1.02, 0.16)
		turret.add_child(barrel)
		var lens := MeshInstance3D.new()
		lens.mesh = assets["pylon_lens_mesh"]
		lens.material_override = assets["pylon_lens_mat"]
		lens.position = Vector3(0.0, 1.02, 0.36)
		turret.add_child(lens)
		root.add_child(turret)

	update_laser_rig(root, a, b, width, gap_t, gap_width, 0, 0.0)
	return root


static func update_laser_rig(
	rig: Node3D, a: Vector2, b: Vector2, width: float,
	gap_t: float, gap_width: float, state: int, pulse: float
) -> void:
	if rig == null or not is_instance_valid(rig):
		return
	var total_len: float = a.distance_to(b)
	if total_len < 0.2 or state == 2:
		rig.visible = false
		return
	rig.visible = true
	var dir: Vector2 = (b - a) / total_len
	var gap_center_dist: float = clampf(gap_t * total_len, gap_width * 0.65, total_len - gap_width * 0.65)
	var g0: float = maxf(0.0, gap_center_dist - gap_width * 0.5)
	var g1: float = minf(total_len, gap_center_dist + gap_width * 0.5)
	var p_g0: Vector2 = a + dir * g0
	var p_g1: Vector2 = a + dir * g1

	# 将两端炮台嵌进环形井壁（外推 0.48m 到墙壁发射槽），炮口朝向彼此
	var wall_a: Vector2 = a + a.normalized() * 0.48
	var wall_b: Vector2 = b + b.normalized() * 0.48
	var pa := rig.get_node_or_null("PylonA") as Node3D
	if pa != null:
		pa.position = Vector3(wall_a.x, 0.0, wall_a.y)
		pa.rotation.y = atan2(dir.x, dir.y)
	var pb := rig.get_node_or_null("PylonB") as Node3D
	if pb != null:
		pb.position = Vector3(wall_b.x, 0.0, wall_b.y)
		pb.rotation.y = atan2(-dir.x, -dir.y)

	var is_warn: bool = (state == 0)
	var is_active: bool = (state == 1)
	var s1 := rig.get_node_or_null("Sight1") as Node3D
	var s2 := rig.get_node_or_null("Sight2") as Node3D
	var sh1 := rig.get_node_or_null("Sheath1") as Node3D
	var sh2 := rig.get_node_or_null("Sheath2") as Node3D
	var co1 := rig.get_node_or_null("Core1") as Node3D
	var co2 := rig.get_node_or_null("Core2") as Node3D
	var gg1 := rig.get_node_or_null("Glow1") as Node3D
	var gg2 := rig.get_node_or_null("Glow2") as Node3D

	if is_warn:
		var sight_thick: float = 0.025 + 0.035 * pulse
		_set_seg(s1, a, p_g0, 1.02, sight_thick, sight_thick)
		_set_seg(s2, p_g1, b, 1.02, sight_thick, sight_thick)
		for n in [sh1, sh2, co1, co2, gg1, gg2]:
			if n != null:
				n.visible = false
	elif is_active:
		for n in [s1, s2]:
			if n != null:
				n.visible = false
		var sh_w: float = maxf(0.10, width * 0.24)
		var gg_w: float = maxf(0.42, width * 1.05)
		_set_seg(sh1, a, p_g0, 1.02, 0.10, sh_w)
		_set_seg(sh2, p_g1, b, 1.02, 0.10, sh_w)
		_set_seg(co1, a, p_g0, 1.02, 0.045, 0.05)
		_set_seg(co2, p_g1, b, 1.02, 0.045, 0.05)
		_set_seg(gg1, a, p_g0, 0.035, 0.02, gg_w)
		_set_seg(gg2, p_g1, b, 0.035, 0.02, gg_w)


static func _get_item_assets() -> Dictionary:
	if not _item_assets.is_empty():
		return _item_assets
	var ring_m := TorusMesh.new()
	ring_m.inner_radius = 0.60
	ring_m.outer_radius = 0.72
	ring_m.rings = 24
	ring_m.ring_segments = 8
	var shield_ring_m := TorusMesh.new()
	shield_ring_m.inner_radius = 0.64
	shield_ring_m.outer_radius = 0.72
	shield_ring_m.rings = 28
	shield_ring_m.ring_segments = 8
	var item_ring_m := TorusMesh.new()
	item_ring_m.inner_radius = 0.34
	item_ring_m.outer_radius = 0.42
	item_ring_m.rings = 20
	item_ring_m.ring_segments = 8
	var core_cyl := CylinderMesh.new()
	core_cyl.top_radius = 0.18
	core_cyl.bottom_radius = 0.18
	core_cyl.height = 0.52
	core_cyl.radial_segments = 12
	var hammer_head := BoxMesh.new()
	hammer_head.size = Vector3(0.64, 0.34, 0.34)
	var hammer_handle := CylinderMesh.new()
	hammer_handle.top_radius = 0.08
	hammer_handle.bottom_radius = 0.09
	hammer_handle.height = 0.54
	hammer_handle.radial_segments = 10
	var coil_m := CylinderMesh.new()
	coil_m.top_radius = 0.22
	coil_m.bottom_radius = 0.28
	coil_m.height = 0.62
	coil_m.radial_segments = 14
	var aura_ring_m := TorusMesh.new()
	aura_ring_m.inner_radius = 0.56
	aura_ring_m.outer_radius = 0.68
	aura_ring_m.rings = 28
	aura_ring_m.ring_segments = 8
	var shock_torus := TorusMesh.new()
	shock_torus.inner_radius = 0.88
	shock_torus.outer_radius = 1.02
	shock_torus.rings = 32
	shock_torus.ring_segments = 8
	_item_assets = {
		"drop_ring_mesh": ring_m,
		"drop_ring_mat": make_std_mat(Color(0.95, 0.72, 0.22, 0.80), 0.0, 0.4, Color(1.0, 0.64, 0.16), 2.2, true),
		"shield_ring_mesh": shield_ring_m,
		"item_ring_mesh": item_ring_m,
		"core_cyl": core_cyl,
		"shield_mat": make_std_mat(Color(0.32, 0.90, 1.0, 0.85), 0.2, 0.2, Color(0.24, 0.82, 1.0), 2.6, true),
		"iron_hub_mat": make_std_mat(Color(0.22, 0.24, 0.26), 0.85, 0.35),
		"hammer_head": hammer_head,
		"hammer_handle": hammer_handle,
		"fist_mat": make_std_mat(Color(1.0, 0.68, 0.16), 0.82, 0.26, Color(1.0, 0.50, 0.08), 1.8),
		"coil_mesh": coil_m,
		"coil_mat": make_std_mat(Color(0.95, 0.26, 0.18), 0.75, 0.28, Color(1.0, 0.22, 0.14), 2.2),
		"copper_mat": make_std_mat(Color(0.86, 0.52, 0.22), 0.85, 0.25, Color(0.9, 0.42, 0.12), 1.0),
		"aura_ring_mesh": aura_ring_m,
		"aura_gold_mat": make_std_mat(Color(1.0, 0.72, 0.18, 0.85), 0.0, 0.3, Color(1.0, 0.62, 0.12), 2.6, true),
		"aura_red_mat": make_std_mat(Color(1.0, 0.32, 0.18, 0.85), 0.0, 0.3, Color(1.0, 0.24, 0.12), 2.8, true),
		"shock_mesh": shock_torus,
		"shock_mat": make_std_mat(Color(1.0, 0.42, 0.18, 0.82), 0.0, 0.3, Color(1.0, 0.34, 0.12), 3.4, true),
	}
	return _item_assets


static func build_airdrop_item(item_type: int) -> Node3D:
	## 直接空投可见的 3D 工业消耗品道具（无盲盒箱子）：地面落点环 + 机械造型道具与标签。
	var assets := _get_item_assets()
	var root := Node3D.new()
	root.name = "AirdropItem"

	var drop_ring := MeshInstance3D.new()
	drop_ring.name = "DropRing"
	drop_ring.mesh = assets["drop_ring_mesh"]
	drop_ring.material_override = assets["drop_ring_mat"]
	drop_ring.position = Vector3(0.0, 0.05, 0.0)
	root.add_child(drop_ring)

	var visual := Node3D.new()
	visual.name = "ItemVisual"
	root.add_child(visual)

	var tag_text := "護盾"
	var tag_col := Color(0.48, 0.94, 1.0)
	if item_type == 1:
		# 双环工业力场核心
		var core := MeshInstance3D.new()
		core.mesh = assets["core_cyl"]
		core.material_override = assets["iron_hub_mat"]
		core.position = Vector3(0.0, 0.56, 0.0)
		visual.add_child(core)
		for rot in [Vector3(35.0, 0.0, 25.0), Vector3(-35.0, 0.0, -25.0)]:
			var r := MeshInstance3D.new()
			r.mesh = assets["item_ring_mesh"]
			r.material_override = assets["shield_mat"]
			r.position = Vector3(0.0, 0.56, 0.0)
			r.rotation_degrees = rot
			visual.add_child(r)
		tag_text = "護盾"
		tag_col = Color(0.48, 0.94, 1.0)
	elif item_type == 2:
		# 工业液压重锤（2x 重推）
		var handle := MeshInstance3D.new()
		handle.mesh = assets["hammer_handle"]
		handle.material_override = assets["iron_hub_mat"]
		handle.position = Vector3(0.0, 0.42, 0.0)
		visual.add_child(handle)
		var head := MeshInstance3D.new()
		head.mesh = assets["hammer_head"]
		head.material_override = assets["fist_mat"]
		head.position = Vector3(0.0, 0.74, 0.0)
		visual.add_child(head)
		tag_text = "重推 2x"
		tag_col = Color(1.0, 0.78, 0.28)
	else:
		# 高压电容线圈（360° 冲击波）
		var coil := MeshInstance3D.new()
		coil.mesh = assets["coil_mesh"]
		coil.material_override = assets["coil_mat"]
		coil.position = Vector3(0.0, 0.56, 0.0)
		visual.add_child(coil)
		for cy in [0.42, 0.70]:
			var cr := MeshInstance3D.new()
			cr.mesh = assets["item_ring_mesh"]
			cr.material_override = assets["copper_mat"]
			cr.position = Vector3(0.0, cy, 0.0)
			visual.add_child(cr)
		tag_text = "衝擊波"
		tag_col = Color(1.0, 0.48, 0.38)

	var lbl := Label3D.new()
	lbl.text = tag_text
	lbl.font_size = 34
	lbl.pixel_size = 0.0082
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.modulate = tag_col
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 10
	var tf := load_terminal_font()
	if tf != null:
		lbl.font = tf
	lbl.position = Vector3(0.0, 1.38, 0.0)
	visual.add_child(lbl)
	return root


static func build_player_shield() -> Node3D:
	## 角色腰际双环工业力场护盾（取代不透明青色气球，绝不遮挡人物本体）
	var assets := _get_item_assets()
	var root := Node3D.new()
	root.name = "PlayerShield"
	root.position = Vector3(0.0, 0.92, 0.0)
	root.visible = false
	var ra := MeshInstance3D.new()
	ra.name = "RingA"
	ra.mesh = assets["shield_ring_mesh"]
	ra.material_override = assets["shield_mat"]
	ra.rotation_degrees = Vector3(26.0, 0.0, 18.0)
	root.add_child(ra)
	var rb := MeshInstance3D.new()
	rb.name = "RingB"
	rb.mesh = assets["shield_ring_mesh"]
	rb.material_override = assets["shield_mat"]
	rb.rotation_degrees = Vector3(-26.0, 0.0, -18.0)
	root.add_child(rb)
	return root


static func build_player_power_aura() -> Node3D:
	## 角色脚下蓄力光环（持重推 2x 显琥珀金环，持 360° 冲击波显红橘环，双方一眼可见）
	var assets := _get_item_assets()
	var root := Node3D.new()
	root.name = "PlayerPowerAura"
	root.position = Vector3(0.0, 0.08, 0.0)
	var gold := MeshInstance3D.new()
	gold.name = "GoldRing"
	gold.mesh = assets["aura_ring_mesh"]
	gold.material_override = assets["aura_gold_mat"]
	gold.visible = false
	root.add_child(gold)
	var red := MeshInstance3D.new()
	red.name = "RedRing"
	red.mesh = assets["aura_ring_mesh"]
	red.material_override = assets["aura_red_mat"]
	red.visible = false
	root.add_child(red)
	return root


static func build_shockwave_ring() -> MeshInstance3D:
	var assets := _get_item_assets()
	var mi := MeshInstance3D.new()
	mi.name = "ShockwaveRing"
	mi.mesh = assets["shock_mesh"]
	mi.material_override = assets["shock_mat"]
	mi.position = Vector3(0.0, 0.35, 0.0)
	return mi


static func build_saw_body(radius: float, with_light: bool = false) -> Node3D:
	## 旋转电锯盘：黄铜齿盘 + 冷钢锯齿，运行时由 game.gd 驱动 rotation.y。
	var assets := _get_saw_assets(radius)
	var root := Node3D.new()
	root.name = "SawBody"
	var blade := MeshInstance3D.new()
	blade.mesh = assets["blade_mesh"]
	blade.material_override = assets["blade_mat"]
	root.add_child(blade)
	var tooth_mesh: BoxMesh = assets["tooth_mesh"]
	var tooth_mat: Material = assets["tooth_mat"]
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		var tooth := MeshInstance3D.new()
		tooth.mesh = tooth_mesh
		tooth.material_override = tooth_mat
		tooth.position = Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		tooth.rotation.y = -a
		root.add_child(tooth)
	var hub := MeshInstance3D.new()
	hub.mesh = assets["hub_mesh"]
	hub.material_override = assets["hub_mat"]
	hub.position = Vector3(0.0, 0.10, 0.0)
	root.add_child(hub)
	if with_light:
		var spark := OmniLight3D.new()
		spark.light_color = Color(1.0, 0.72, 0.24)
		spark.light_energy = 1.6
		spark.omni_range = 3.0
		root.add_child(spark)
	return root


static func build_slap_icon() -> ImageTexture:
	## 推人技能巴掌图示（64x64 高对比工业剪影 + 挥击弧线），用于冷却进度 HUD。
	var image := Image.new()
	image.load_svg_from_string("""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
	  <g fill="#e8ffe8">
	    <!-- 挥击冲击弧线 -->
	    <path d="M8 22c3-7 9-12 16-14l2 5c-5 2-10 5-12 11z" opacity="0.85"/>
	    <path d="M5 32c1-5 3-10 6-14l4 3c-2 3-4 7-5 11z" opacity="0.55"/>
	    <!-- 张开的巴掌（五指 + 掌心） -->
	    <rect x="22" y="13" width="6" height="22" rx="3"/>
	    <rect x="30" y="9" width="6" height="25" rx="3"/>
	    <rect x="38" y="11" width="6" height="24" rx="3"/>
	    <rect x="46" y="16" width="5.5" height="20" rx="2.75"/>
	    <path d="M16 33c-2.5-2-2.5-5.5 0-7.5 2-1.5 5-1 7 1.5l3 4v14l-10-12z"/>
	    <rect x="22" y="30" width="29.5" height="19" rx="7"/>
	    <rect x="27" y="47" width="18" height="8" rx="4"/>
	  </g>
	</svg>""")
	return ImageTexture.create_from_image(image)


static func build_spike_ring_icon() -> ImageTexture:
	## 与原版小游戏一致的 256×256 单色 CRT 剪影：尖刺圆环 + 中心齿轮 + 警示箭头。
	var image := Image.new()
	image.load_svg_from_string("""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
	  <rect width="256" height="256" fill="#000"/>
	  <g fill="#e5e5e5">
	    <!-- 外圈尖刺 -->
	    <g>
	      <polygon points="128,6 138,34 118,34"/>
	      <polygon points="128,250 138,222 118,222"/>
	      <polygon points="6,128 34,118 34,138"/>
	      <polygon points="250,128 222,118 222,138"/>
	      <polygon points="42,42 70,52 52,70"/>
	      <polygon points="214,42 204,70 186,52"/>
	      <polygon points="42,214 52,186 70,204"/>
	      <polygon points="214,214 186,204 204,186"/>
	      <polygon points="88,14 106,38 88,44"/>
	      <polygon points="168,14 168,44 150,38"/>
	      <polygon points="88,242 88,212 106,218"/>
	      <polygon points="168,242 150,218 168,212"/>
	      <polygon points="14,88 44,88 38,106"/>
	      <polygon points="242,88 218,106 212,88"/>
	      <polygon points="14,168 38,150 44,168"/>
	      <polygon points="242,168 212,168 218,150"/>
	    </g>
	    <!-- 主圆环（黄铜齿环剪影） -->
	    <path d="M128 44a84 84 0 1 0 0 168a84 84 0 1 0 0-168zm0 22a62 62 0 1 1 0 124a62 62 0 1 1 0-124z"/>
	    <!-- 环上铆钉 -->
	    <circle cx="128" cy="52" r="6"/><circle cx="128" cy="204" r="6"/>
	    <circle cx="52" cy="128" r="6"/><circle cx="204" cy="128" r="6"/>
	    <circle cx="74" cy="74" r="5"/><circle cx="182" cy="74" r="5"/>
	    <circle cx="74" cy="182" r="5"/><circle cx="182" cy="182" r="5"/>
	    <!-- 中心齿轮 -->
	    <circle cx="128" cy="128" r="34"/>
	    <g fill="#000">
	      <rect x="122" y="84" width="12" height="18"/>
	      <rect x="122" y="154" width="12" height="18"/>
	      <rect x="84" y="122" width="18" height="12"/>
	      <rect x="154" y="122" width="18" height="12"/>
	      <circle cx="128" cy="128" r="15"/>
	    </g>
	    <circle cx="128" cy="128" r="8" fill="#e5e5e5"/>
	    <!-- 顶部红色警示灯（剪影用留白三角表示） -->
	    <polygon points="128,26 120,40 136,40"/>
	  </g>
	</svg>""")
	return ImageTexture.create_from_image(image)

