extends RefCounted

## Pre-allocated FX pools for Spike Ring:
## GPU particles, scorch decals (explosion_mark.png), drifting warm pit motes,
## brief flash OmniLight3Ds (<= 2), pooled 3D score popups, and shockwave rings.
## Zero runtime node/mesh/material allocations in tick() or spawn_*().

const POOL_HIT_FX := 6
const POOL_DUST_FX := 4
const POOL_SCORCH := 6
const POOL_FLASH := 2
const POOL_POPUP := 8
const POOL_SHOCKWAVE := 3
const AMBIENT_MOTE_COUNT := 16
const TEX_EXPLOSION_MARK := "res://textures/decals/explosion_mark.png"

var hit_fx_pool: Array[Dictionary] = []
var dust_fx_pool: Array[Dictionary] = []
var scorch_pool: Array[Dictionary] = []
var flash_pool: Array[Dictionary] = []
var popup_pool: Array[Dictionary] = []
var shockwave_pool: Array[Dictionary] = []
var motes: Array[Dictionary] = []

var hit_fx_cursor: int = 0
var dust_fx_cursor: int = 0
var scorch_cursor: int = 0
var flash_cursor: int = 0
var popup_cursor: int = 0
var shockwave_cursor: int = 0
var _mote_time: float = 0.0
var _initialized: bool = false


func clear() -> void:
	_initialized = false
	hit_fx_pool.clear()
	dust_fx_pool.clear()
	scorch_pool.clear()
	flash_pool.clear()
	popup_pool.clear()
	shockwave_pool.clear()
	motes.clear()
	hit_fx_cursor = 0
	dust_fx_cursor = 0
	scorch_cursor = 0
	flash_cursor = 0
	popup_cursor = 0
	shockwave_cursor = 0
	_mote_time = 0.0


func _collect_particles_recursive(node: Node, out: Array[Node]) -> void:
	if node is GPUParticles3D:
		var gp: GPUParticles3D = node
		gp.emitting = false
		out.append(gp)
	elif node is CPUParticles3D:
		var cp: CPUParticles3D = node
		cp.emitting = false
		out.append(cp)
	for child in node.get_children():
		_collect_particles_recursive(child, out)


func _build_fx_pool(fx_root: Node3D, scene: PackedScene, count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if scene == null or fx_root == null:
		return pool
	for _i in range(count):
		var inst: Node = scene.instantiate()
		if inst is Node3D:
			var n3: Node3D = inst as Node3D
			if n3.get_script() != null:
				n3.set_script(null)
			var emitters: Array[Node] = []
			_collect_particles_recursive(n3, emitters)
			n3.position = Vector3(0.0, -50.0, 0.0)
			n3.visible = false
			fx_root.add_child(n3)
			pool.append({"node": n3, "emitters": emitters, "timer": 0.0})
		elif inst != null:
			inst.queue_free()
	return pool


func init_pools(stage: Node3D) -> void:
	var fx_root: Node3D = stage._fx_root
	if bool(stage._is_self_test) or fx_root == null:
		return
	clear()

	hit_fx_pool = _build_fx_pool(fx_root, stage._fx_hit_scene, POOL_HIT_FX)
	dust_fx_pool = _build_fx_pool(fx_root, stage._fx_dust_scene, POOL_DUST_FX)

	# Pre-allocated scorch decals (PCK Decal or clean quad fallback)
	var mark_tex: Texture2D = null
	if ResourceLoader.exists(TEX_EXPLOSION_MARK):
		var loaded_tex = ResourceLoader.load(TEX_EXPLOSION_MARK)
		if loaded_tex is Texture2D:
			mark_tex = loaded_tex as Texture2D
	var scorch_plane_mesh: PlaneMesh = null
	var scorch_fallback_mat: StandardMaterial3D = null
	if mark_tex == null:
		scorch_plane_mesh = PlaneMesh.new()
		scorch_plane_mesh.size = Vector2(1.0, 1.0)
		scorch_fallback_mat = StandardMaterial3D.new()
		scorch_fallback_mat.albedo_color = Color(0.08, 0.06, 0.05, 0.45)
		scorch_fallback_mat.roughness = 0.95
		scorch_fallback_mat.metallic = 0.0
		scorch_fallback_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for s_i in range(POOL_SCORCH):
		if mark_tex != null:
			var dec := Decal.new()
			dec.size = Vector3(2.0, 0.45, 2.0)
			dec.texture_albedo = mark_tex
			dec.modulate = Color(0.22, 0.18, 0.15, 0.72)
			dec.upper_fade = 0.35
			dec.lower_fade = 0.35
			dec.position = Vector3(0.0, -50.0, 0.0)
			dec.visible = false
			fx_root.add_child(dec)
			scorch_pool.append({"node": dec, "is_decal": true, "seed_ang": float(s_i) * 1.13})
		else:
			var smi := MeshInstance3D.new()
			smi.mesh = scorch_plane_mesh
			smi.material_override = scorch_fallback_mat
			smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			smi.position = Vector3(0.0, -50.0, 0.0)
			smi.visible = false
			fx_root.add_child(smi)
			scorch_pool.append({"node": smi, "is_decal": false, "seed_ang": float(s_i) * 1.13})

	# Pre-allocated brief flash OmniLight3Ds (<= 2, shadowless)
	for _i in range(POOL_FLASH):
		var fl := OmniLight3D.new()
		fl.shadow_enabled = false
		fl.light_color = Color(1.0, 0.56, 0.20)
		fl.light_energy = 0.0
		fl.omni_range = 6.5
		fl.position = Vector3(0.0, -50.0, 0.0)
		fl.visible = false
		fx_root.add_child(fl)
		flash_pool.append({"light": fl, "timer": 0.0, "duration": 0.24, "peak_energy": 3.8})

	# Pre-allocated drifting warm pit dust/ember motes
	var mote_mesh := QuadMesh.new()
	mote_mesh.size = Vector2(0.075, 0.075)
	var mote_mat := StandardMaterial3D.new()
	mote_mat.albedo_color = Color(1.0, 0.82, 0.52, 0.38)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(1.0, 0.76, 0.38)
	mote_mat.emission_energy_multiplier = 1.25
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for m_i in range(AMBIENT_MOTE_COUNT):
		var mmi := MeshInstance3D.new()
		mmi.mesh = mote_mesh
		mmi.material_override = mote_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var bx: float = -6.8 + float(m_i % 4) * 4.5 + sin(float(m_i) * 2.1) * 1.0
		var by: float = 1.25 + float(m_i % 3) * 0.90
		var bz: float = -5.4 + float(m_i / 4) * 3.4 + cos(float(m_i) * 1.7) * 0.6
		var base_pos := Vector3(bx, by, bz)
		mmi.position = base_pos
		fx_root.add_child(mmi)
		motes.append({
			"node": mmi,
			"base": base_pos,
			"phase": float(m_i) * 0.83,
			"sx": 0.35 + float(m_i % 3) * 0.14,
			"sy": 0.52 + float(m_i % 4) * 0.11,
			"sz": 0.31 + float(m_i % 5) * 0.09,
			"scale": 0.74 + float(m_i % 4) * 0.16,
		})

	# Pre-allocated 3D score popups
	var term_font: Font = stage._term_font
	for _i in range(POOL_POPUP):
		var lbl := Label3D.new()
		lbl.font_size = 46
		lbl.outline_size = 10
		lbl.pixel_size = 0.011
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		if term_font != null:
			lbl.font = term_font
		lbl.position = Vector3(0.0, -50.0, 0.0)
		lbl.visible = false
		fx_root.add_child(lbl)
		popup_pool.append({"node": lbl, "age": 0.0, "max_age": 0.85, "base_col": Color.WHITE, "active": false})

	# Pre-allocated shockwave rings
	var meshes = stage.M
	var cfg = stage.C
	var max_r: float = float(cfg.SHOCKWAVE_RANGE) if cfg != null else 3.2
	if meshes != null:
		for _i in range(POOL_SHOCKWAVE):
			var ring: MeshInstance3D = meshes.build_shockwave_ring()
			ring.position = Vector3(0.0, -50.0, 0.0)
			ring.visible = false
			fx_root.add_child(ring)
			shockwave_pool.append({"node": ring, "age": 0.0, "max_age": 0.34, "max_r": max_r, "active": false})

	if str(stage._screenshot_path).is_empty():
		var warm_pos := Vector3(0.0, 0.3, 0.0)
		for pool in [hit_fx_pool, dust_fx_pool]:
			if not pool.is_empty():
				trigger_fx_entry(pool[0], warm_pos, 0.01, 0.08)

	_initialized = true


func trigger_fx_entry(entry: Dictionary, world_pos: Vector3, scale_val: float, lifetime: float) -> void:
	var n3: Node3D = entry["node"]
	if not is_instance_valid(n3):
		return
	n3.position = world_pos
	n3.scale = Vector3.ONE * scale_val
	n3.visible = true
	entry["timer"] = lifetime
	for em in entry["emitters"]:
		if em is GPUParticles3D:
			var gp: GPUParticles3D = em
			gp.restart()
			gp.emitting = true
		elif em is CPUParticles3D:
			var cp: CPUParticles3D = em
			cp.restart()
			cp.emitting = true


func step_fx_pools(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not _initialized:
		return
	_mote_time += delta
	for m_raw in motes:
		var md: Dictionary = m_raw
		var mn := md["node"] as MeshInstance3D
		if mn == null or not is_instance_valid(mn):
			continue
		var base_p: Vector3 = md["base"] as Vector3
		var ph: float = float(md["phase"])
		var ox: float = sin(_mote_time * float(md["sx"]) + ph) * 0.65
		var oy: float = sin(_mote_time * float(md["sy"]) + ph * 1.7) * 0.32
		var oz: float = cos(_mote_time * float(md["sz"]) + ph * 0.9) * 0.55
		mn.position = Vector3(base_p.x + ox, base_p.y + oy, base_p.z + oz)
		var ms: float = float(md["scale"]) * (0.78 + 0.22 * sin(_mote_time * 1.9 + ph))
		mn.scale = Vector3(ms, ms, ms)

	for f_raw in flash_pool:
		var fslot: Dictionary = f_raw
		var ft: float = float(fslot["timer"])
		if ft <= 0.0:
			continue
		ft = maxf(0.0, ft - delta)
		fslot["timer"] = ft
		var fl := fslot["light"] as OmniLight3D
		if fl == null or not is_instance_valid(fl):
			fslot["timer"] = 0.0
			continue
		if ft <= 0.0:
			fl.light_energy = 0.0
			fl.visible = false
			fl.position = Vector3(0.0, -50.0, 0.0)
		else:
			var fdur: float = maxf(0.001, float(fslot["duration"]))
			fl.light_energy = float(fslot["peak_energy"]) * clampf(ft / fdur, 0.0, 1.0)

	for pool in [hit_fx_pool, dust_fx_pool]:
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

	step_popups_and_shockwaves(delta)


func spawn_fx(stage: Node3D, scene: PackedScene, world_pos: Vector3, scale_val: float, lifetime: float) -> void:
	if bool(stage._is_self_test) or scene == null or not _initialized:
		return
	if scene == stage._fx_hit_scene and not hit_fx_pool.is_empty():
		var entry: Dictionary = hit_fx_pool[hit_fx_cursor % hit_fx_pool.size()]
		hit_fx_cursor = (hit_fx_cursor + 1) % hit_fx_pool.size()
		trigger_fx_entry(entry, world_pos, scale_val, lifetime)
	elif scene == stage._fx_dust_scene and not dust_fx_pool.is_empty():
		var entry: Dictionary = dust_fx_pool[dust_fx_cursor % dust_fx_pool.size()]
		dust_fx_cursor = (dust_fx_cursor + 1) % dust_fx_pool.size()
		trigger_fx_entry(entry, world_pos, scale_val, lifetime)


func spawn_scorch_decal(world_pos: Vector3, scale_r: float = 2.0) -> void:
	if not _initialized or scorch_pool.is_empty():
		return
	var slot: Dictionary = scorch_pool[scorch_cursor]
	scorch_cursor = (scorch_cursor + 1) % scorch_pool.size()
	var rot_y: float = fmod(absf(world_pos.x * 1.73 + world_pos.z * 2.31) + float(slot["seed_ang"]), TAU)
	if bool(slot["is_decal"]):
		var dec := slot["node"] as Decal
		if dec != null and is_instance_valid(dec):
			dec.size = Vector3(scale_r, 0.45, scale_r)
			dec.position = Vector3(world_pos.x, 0.03, world_pos.z)
			dec.rotation.y = rot_y
			dec.visible = true
	else:
		var mi := slot["node"] as MeshInstance3D
		if mi != null and is_instance_valid(mi):
			mi.position = Vector3(world_pos.x, 0.024, world_pos.z)
			mi.rotation.y = rot_y
			mi.scale = Vector3(scale_r * 0.85, 1.0, scale_r * 0.85)
			mi.visible = true


func spawn_flash_light(world_pos: Vector3, col: Color, peak_energy: float = 3.8, range_m: float = 6.5, dur: float = 0.24) -> void:
	if not _initialized or flash_pool.is_empty():
		return
	var slot: Dictionary = flash_pool[flash_cursor]
	flash_cursor = (flash_cursor + 1) % flash_pool.size()
	var fl := slot["light"] as OmniLight3D
	if fl == null or not is_instance_valid(fl):
		return
	fl.position = Vector3(world_pos.x, maxf(world_pos.y, 0.85), world_pos.z)
	fl.light_color = col
	fl.omni_range = range_m
	fl.light_energy = peak_energy
	fl.visible = true
	slot["timer"] = dur
	slot["duration"] = dur
	slot["peak_energy"] = peak_energy


func spawn_score_popup(stage: Node3D, world_pos: Vector3, text: String, color: Color) -> void:
	if bool(stage._is_self_test) or not _initialized or popup_pool.is_empty():
		return
	var pop: Dictionary = popup_pool[popup_cursor]
	popup_cursor = (popup_cursor + 1) % popup_pool.size()
	var lbl := pop["node"] as Label3D
	if lbl == null or not is_instance_valid(lbl):
		return
	lbl.text = text
	lbl.modulate = color
	lbl.position = world_pos
	lbl.visible = true
	pop["age"] = 0.0
	pop["max_age"] = 0.85
	pop["base_col"] = color
	pop["active"] = true


func spawn_shockwave(stage: Node3D, world_pos: Vector3) -> void:
	if bool(stage._is_self_test) or not _initialized or shockwave_pool.is_empty():
		return
	var sw: Dictionary = shockwave_pool[shockwave_cursor]
	shockwave_cursor = (shockwave_cursor + 1) % shockwave_pool.size()
	var ring := sw["node"] as MeshInstance3D
	if ring == null or not is_instance_valid(ring):
		return
	ring.position = world_pos
	ring.scale = Vector3(0.35, 1.0, 0.35)
	ring.visible = true
	sw["age"] = 0.0
	sw["active"] = true
	spawn_scorch_decal(world_pos, 2.2)
	spawn_flash_light(world_pos, Color(1.0, 0.45, 0.18), 4.2, 7.0, 0.25)


func step_popups_and_shockwaves(delta: float) -> void:
	for pop in popup_pool:
		if not bool(pop["active"]):
			continue
		var lbl := pop["node"] as Label3D
		pop["age"] = float(pop["age"]) + delta
		var t: float = float(pop["age"]) / maxf(0.001, float(pop["max_age"]))
		if lbl == null or not is_instance_valid(lbl) or t >= 1.0:
			if lbl != null and is_instance_valid(lbl):
				lbl.visible = false
				lbl.position = Vector3(0.0, -50.0, 0.0)
			pop["active"] = false
		else:
			lbl.position.y += delta * 1.45
			var col: Color = pop["base_col"] as Color
			col.a = clampf(1.0 - t * t, 0.0, 1.0)
			lbl.modulate = col

	for sw in shockwave_pool:
		if not bool(sw["active"]):
			continue
		var ring := sw["node"] as MeshInstance3D
		sw["age"] = float(sw["age"]) + delta
		var t: float = float(sw["age"]) / maxf(0.001, float(sw["max_age"]))
		if ring == null or not is_instance_valid(ring) or t >= 1.0:
			if ring != null and is_instance_valid(ring):
				ring.visible = false
				ring.position = Vector3(0.0, -50.0, 0.0)
			sw["active"] = false
		else:
			var r: float = lerpf(0.35, float(sw["max_r"]), 1.0 - pow(1.0 - t, 2.0))
			ring.scale = Vector3(r, maxf(0.15, 1.0 - t * 0.7), r)
