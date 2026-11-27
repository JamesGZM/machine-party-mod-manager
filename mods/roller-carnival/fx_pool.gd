extends RefCounted

## Persistent blood/hit GPU particle pools, blood decal pool, and debris bursts for Roller Carnival.

const POOL_HIT_BLOOD_FX := 6
const POOL_BLOODMIST_FX := 4
const POOL_IMPACT_DECALS := 24
const LAVA_EMBER_COUNT := 24

var decals: Array[Node3D] = []
var particles: Array[Dictionary] = []
var hit_blood_pool: Array[Dictionary] = []
var bloodmist_pool: Array[Dictionary] = []
var lava_embers: Array[Dictionary] = []
var hit_blood_cursor: int = 0
var bloodmist_cursor: int = 0
var decal_cursor: int = 0
var _ember_time: float = 0.0
var burst_box_mesh: BoxMesh = null


func clear() -> void:
	decals.clear()
	particles.clear()
	hit_blood_pool.clear()
	bloodmist_pool.clear()
	lava_embers.clear()
	hit_blood_cursor = 0
	bloodmist_cursor = 0
	decal_cursor = 0
	_ember_time = 0.0


func _build_fx_pool(fx_layer: Node3D, packed: PackedScene, count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if packed == null or fx_layer == null:
		return pool
	for _i in range(count):
		var inst = packed.instantiate()
		if inst is Node3D:
			var n3 := inst as Node3D
			n3.set_script(null)
			var emitters: Array[GPUParticles3D] = []
			for child in n3.get_children():
				if child is GPUParticles3D:
					var gp := child as GPUParticles3D
					gp.one_shot = true
					gp.emitting = false
					emitters.append(gp)
			n3.position = Vector3(0.0, -50.0, 0.0)
			n3.visible = false
			fx_layer.add_child(n3)
			pool.append({"node": n3, "emitters": emitters, "timer": 0.0})
		elif inst is Node:
			(inst as Node).queue_free()
	return pool


func init_pools(stage: Node3D) -> void:
	var fx_layer: Node3D = stage._fx_layer
	if bool(stage._is_self_test) or fx_layer == null:
		return
	hit_blood_pool = _build_fx_pool(fx_layer, stage._fx_hit_blood_scene, POOL_HIT_BLOOD_FX)
	bloodmist_pool = _build_fx_pool(fx_layer, stage._fx_bloodmist_scene, POOL_BLOODMIST_FX)
	var bt1: Texture2D = stage._blood_tex_01
	var bt2: Texture2D = stage._blood_tex_02
	if bt1 != null or bt2 != null:
		for i in range(POOL_IMPACT_DECALS):
			var dec := Decal.new()
			dec.size = Vector3(1.4, 0.42, 1.4)
			dec.texture_albedo = bt2 if (i % 3 != 0 and bt2 != null) else (bt1 if bt1 != null else bt2)
			dec.modulate = Color(0.3809, 0.0189, 0.0, 1.0)
			dec.upper_fade = 0.3
			dec.lower_fade = 0.3
			dec.position = Vector3(0.0, -50.0, 0.0)
			dec.visible = false
			fx_layer.add_child(dec)
			decals.append(dec)
	# Pre-allocate drifting lava embers rising from left shredder pit (zero runtime alloc)
	var ember_mesh := QuadMesh.new()
	ember_mesh.size = Vector2(0.09, 0.09)
	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.68, 0.22, 0.85)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.50, 0.10)
	ember_mat.emission_energy_multiplier = 2.1
	ember_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var left_x: float = float(stage.config.stage_left_lava_x)
	for e_i in range(LAVA_EMBER_COUNT):
		var emi := MeshInstance3D.new()
		emi.mesh = ember_mesh
		emi.material_override = ember_mat
		emi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var bx: float = left_x - 0.35 - fposmod(float(e_i) * 1.37, 4.8)
		var bz: float = -4.0 + float(e_i % 8) * 1.12 + sin(float(e_i) * 1.9) * 0.28
		var e_pos := Vector3(bx, -0.45, bz)
		emi.position = e_pos
		fx_layer.add_child(emi)
		lava_embers.append({
			"node": emi,
			"base_x": bx,
			"base_z": bz,
			"phase": float(e_i) * 0.43,
			"speed": 0.24 + float(e_i % 5) * 0.06,
			"rise": 2.4 + float(e_i % 4) * 0.45,
			"drift": 0.26 + float(e_i % 3) * 0.10,
			"scale": 0.68 + float(e_i % 4) * 0.18,
		})

	if str(stage._screenshot_path).is_empty() and stage.is_inside_tree():
		var spawn_x: float = float(stage.config.player_spawn_x)
		var warm_pos := Vector3(spawn_x, 0.35, 0.0)
		for pool in [hit_blood_pool, bloodmist_pool]:
			if not pool.is_empty():
				trigger_fx_entry(pool[0], warm_pos, 0.01, 0.08)
		if not decals.is_empty() and decals[0] is Decal:
			var wd := decals[0] as Decal
			wd.position = warm_pos
			wd.size = Vector3(0.05, 0.05, 0.05)
			wd.visible = true
			stage.get_tree().create_timer(0.08).timeout.connect(func():
				if not decals.is_empty() and decals[0] is Decal and is_instance_valid(decals[0]):
					var d0 := decals[0] as Decal
					if d0.size.x <= 0.1:
						d0.visible = false
						d0.position = Vector3(0.0, -50.0, 0.0)
			)


func trigger_fx_entry(entry: Dictionary, origin: Vector3, eff_scale: float, lifetime: float) -> void:
	var n3: Node3D = entry["node"]
	if not is_instance_valid(n3):
		return
	n3.position = origin
	n3.scale = Vector3.ONE * eff_scale
	n3.visible = true
	entry["timer"] = lifetime
	for gp in entry["emitters"]:
		if is_instance_valid(gp):
			gp.restart()
			gp.emitting = true


func step_fx_pools(delta: float) -> void:
	_ember_time += delta
	for e_raw in lava_embers:
		var ed: Dictionary = e_raw as Dictionary
		var en := ed["node"] as MeshInstance3D
		if en == null or not is_instance_valid(en):
			continue
		var phase: float = float(ed["phase"])
		var cycle: float = fposmod(phase + _ember_time * float(ed["speed"]), 1.0)
		var ey: float = -0.52 + cycle * float(ed["rise"])
		var ex: float = float(ed["base_x"]) + sin(_ember_time * 1.4 + phase * 6.28) * float(ed["drift"])
		var ez: float = float(ed["base_z"]) + cos(_ember_time * 1.1 + phase * 5.1) * float(ed["drift"])
		en.position = Vector3(ex, ey, ez)
		var env_scale: float = sin(cycle * PI) * float(ed["scale"])
		en.scale = Vector3(env_scale, env_scale, env_scale)

	for pool in [hit_blood_pool, bloodmist_pool]:
		for entry in pool:
			var rem: float = float(entry["timer"])
			if rem > 0.0:
				rem -= delta
				entry["timer"] = rem
				if rem <= 0.0:
					var n3: Node3D = entry["node"]
					if is_instance_valid(n3):
						n3.visible = false
						n3.position = Vector3(0.0, -50.0, 0.0)


func spawn_vanilla_effect(stage: Node3D, scene_path: String, origin: Vector3, eff_scale: float, lifetime: float) -> bool:
	if bool(stage._is_self_test):
		return true
	if scene_path.ends_with("hit_blood.tscn") and not hit_blood_pool.is_empty():
		var entry: Dictionary = hit_blood_pool[hit_blood_cursor % hit_blood_pool.size()]
		hit_blood_cursor += 1
		trigger_fx_entry(entry, origin, eff_scale, lifetime)
		return true
	if scene_path.ends_with("bloodmist_01.tscn") and not bloodmist_pool.is_empty():
		var entry: Dictionary = bloodmist_pool[bloodmist_cursor % bloodmist_pool.size()]
		bloodmist_cursor += 1
		trigger_fx_entry(entry, origin, eff_scale, lifetime)
		return true
	return false


func spawn_impact_decal(stage: Node3D, pos: Vector3, scale_mul: float = 1.0) -> void:
	if bool(stage._is_self_test):
		return
	var rng: RandomNumberGenerator = stage._rng
	if not decals.is_empty() and decals[0] is Decal:
		var dec := decals[decal_cursor % decals.size()] as Decal
		decal_cursor += 1
		if is_instance_valid(dec):
			var sz: float = rng.randf_range(1.25, 1.75) * scale_mul
			dec.size = Vector3(sz, 0.42, sz)
			dec.position = Vector3(pos.x, 0.04, pos.z)
			dec.rotation.y = rng.randf_range(0.0, TAU)
			dec.visible = true
		return
	var meshes = stage._meshes
	var fx_layer: Node3D = stage._fx_layer
	if meshes == null or fx_layer == null:
		return
	var mark := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.34 * scale_mul
	cm.bottom_radius = 0.36 * scale_mul
	cm.height = 0.015
	mark.mesh = cm
	mark.material_override = meshes.make_toon_mat(Color(0.38, 0.02, 0.01, 0.80), 0.9, 0.0)
	mark.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark.position = pos
	fx_layer.add_child(mark)
	decals.append(mark)


func spawn_burst(stage: Node3D, origin: Vector3, color: Color, count: int) -> void:
	var meshes = stage._meshes
	var fx_layer: Node3D = stage._fx_layer
	var rng: RandomNumberGenerator = stage._rng
	if meshes == null or fx_layer == null:
		return
	if burst_box_mesh == null:
		burst_box_mesh = BoxMesh.new()
		burst_box_mesh.size = Vector3(0.14, 0.14, 0.14)
	var mat = meshes.make_toon_mat(color, 0.3, 0.0, color, 1.8)
	for _i in range(count):
		var part := MeshInstance3D.new()
		part.mesh = burst_box_mesh
		part.material_override = mat
		part.position = origin
		fx_layer.add_child(part)
		var vel := Vector3(rng.randf_range(-2.8, 1.8), rng.randf_range(2.2, 5.2), rng.randf_range(-2.2, 2.2))
		particles.append({"node": part, "vel": vel, "life": 0.55})


func update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var pt: Dictionary = particles[i]
		pt["life"] = float(pt["life"]) - delta
		if float(pt["life"]) <= 0.0:
			(pt["node"] as Node3D).queue_free()
			particles.remove_at(i)
		else:
			var vel: Vector3 = pt["vel"]
			vel.y -= 11.5 * delta
			pt["vel"] = vel
			var node: Node3D = pt["node"]
			node.position += vel * delta
			node.scale = Vector3.ONE * clampf(float(pt["life"]) * 1.8, 0.1, 1.0)
