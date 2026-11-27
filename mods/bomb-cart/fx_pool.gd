extends RefCounted

## Pre-allocated FX pool for Bomb Cart (炸彈推車).
## All nodes, meshes, and materials are allocated once in setup().
## Zero runtime new(), instantiate(), or queue_free() in spawn_*() or tick().

const SHOVE_POOL_SIZE := 6
const RAM_POOL_SIZE := 6
const STEAM_POOL_SIZE := 4
const SHOCKWAVE_POOL_SIZE := 3
const EXPLOSION_POOL_SIZE := 2
const SCORCH_POOL_SIZE := 6
const FLASH_LIGHT_POOL_SIZE := 2
const AMBIENT_MOTE_COUNT := 16
const RAIL_SPARK_POOL_SIZE := 6
const TEX_EXPLOSION_MARK := "res://textures/decals/explosion_mark.png"

var _initialized: bool = false
var _shove_pool: Array = []
var _ram_pool: Array = []
var _steam_pool: Array = []
var _shockwave_pool: Array = []
var _explosion_pool: Array = []
var _scorch_pool: Array = []
var _flash_pool: Array = []
var _motes: Array = []
var _rail_spark_pool: Array = []

var _shove_cursor: int = 0
var _ram_cursor: int = 0
var _steam_cursor: int = 0
var _shockwave_cursor: int = 0
var _explosion_cursor: int = 0
var _scorch_cursor: int = 0
var _flash_cursor: int = 0
var _rail_spark_cursor: int = 0
var _mote_time: float = 0.0

var _all_pools: Array = []


func _make_fx_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 2.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func clear() -> void:
	_initialized = false
	_shove_pool.clear()
	_ram_pool.clear()
	_steam_pool.clear()
	_shockwave_pool.clear()
	_explosion_pool.clear()
	_scorch_pool.clear()
	_flash_pool.clear()
	_motes.clear()
	_rail_spark_pool.clear()
	_all_pools.clear()
	_shove_cursor = 0
	_ram_cursor = 0
	_steam_cursor = 0
	_shockwave_cursor = 0
	_explosion_cursor = 0
	_scorch_cursor = 0
	_flash_cursor = 0
	_rail_spark_cursor = 0
	_mote_time = 0.0


func setup(parent: Node3D) -> void:
	if parent == null:
		return
	if _initialized:
		var still_valid: bool = not _shove_pool.is_empty() and is_instance_valid((_shove_pool[0] as Dictionary).get("node", null))
		if still_valid:
			return
		clear()

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.55
	ring_mesh.outer_radius = 0.90
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 6

	var wide_ring_mesh := TorusMesh.new()
	wide_ring_mesh.inner_radius = 0.85
	wide_ring_mesh.outer_radius = 1.15
	wide_ring_mesh.rings = 28
	wide_ring_mesh.ring_segments = 6

	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.12, 0.12, 0.48)

	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 0.42
	puff_mesh.height = 0.78
	puff_mesh.radial_segments = 12
	puff_mesh.rings = 8

	var steam_ring_mesh := TorusMesh.new()
	steam_ring_mesh.inner_radius = 0.34
	steam_ring_mesh.outer_radius = 0.56
	steam_ring_mesh.rings = 20
	steam_ring_mesh.ring_segments = 6

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.75
	sphere_mesh.height = 1.5
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 10

	for _i in range(SHOVE_POOL_SIZE):
		var mat: StandardMaterial3D = _make_fx_mat()
		var n := Node3D.new()
		n.visible = false
		var mi := MeshInstance3D.new()
		mi.mesh = ring_mesh
		mi.scale = Vector3(1.0, 0.22, 1.0)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		parent.add_child(n)
		_shove_pool.append({
			"node": n, "mat": mat, "timer": 0.0, "duration": 0.35,
			"start_scale": 0.6, "end_scale": 2.2, "col": Color.WHITE, "stretch_z": false,
		})

	for _i in range(RAM_POOL_SIZE):
		var mat: StandardMaterial3D = _make_fx_mat()
		var n := Node3D.new()
		n.visible = false
		for s_idx in range(4):
			var ang: float = float(s_idx) * PI * 0.5 + PI * 0.25
			var sp := MeshInstance3D.new()
			sp.mesh = spark_mesh
			sp.position = Vector3(cos(ang) * 0.45, 0.25, sin(ang) * 0.45)
			sp.rotation.y = -ang
			sp.material_override = mat
			sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(sp)
		parent.add_child(n)
		_ram_pool.append({
			"node": n, "mat": mat, "timer": 0.0, "duration": 0.32,
			"start_scale": 0.7, "end_scale": 2.4, "col": Color.WHITE, "stretch_z": false,
		})

	var puff_specs: Array = [
		{"frac": 0.05, "ox": -0.10, "oy": 0.04, "sc": 0.72},
		{"frac": 0.14, "ox": 0.16, "oy": 0.08, "sc": 0.88},
		{"frac": 0.23, "ox": -0.18, "oy": 0.12, "sc": 0.98},
		{"frac": 0.32, "ox": 0.14, "oy": 0.07, "sc": 1.06},
		{"frac": 0.41, "ox": -0.20, "oy": 0.14, "sc": 1.14},
		{"frac": 0.50, "ox": 0.18, "oy": 0.10, "sc": 1.18},
		{"frac": 0.60, "ox": -0.16, "oy": 0.15, "sc": 1.24},
		{"frac": 0.70, "ox": 0.17, "oy": 0.11, "sc": 1.28},
		{"frac": 0.80, "ox": -0.14, "oy": 0.14, "sc": 1.34},
		{"frac": 0.89, "ox": 0.10, "oy": 0.16, "sc": 1.40},
		{"frac": 0.96, "ox": -0.04, "oy": 0.18, "sc": 1.48},
	]
	var ring_fracs: Array = [0.12, 0.34, 0.56, 0.78, 0.92]
	for _i in range(STEAM_POOL_SIZE):
		var puff_mat: StandardMaterial3D = _make_fx_mat()
		puff_mat.emission_energy_multiplier = 1.30
		var ring_mat: StandardMaterial3D = _make_fx_mat()
		ring_mat.emission_energy_multiplier = 1.95
		var n := Node3D.new()
		n.visible = false
		var puffs: Array = []
		for spec_raw in puff_specs:
			var spec: Dictionary = spec_raw as Dictionary
			var pm := MeshInstance3D.new()
			pm.mesh = puff_mesh
			pm.material_override = puff_mat
			pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(pm)
			puffs.append({
				"mi": pm,
				"frac": float(spec["frac"]),
				"ox": float(spec["ox"]),
				"oy": float(spec["oy"]),
				"sc": float(spec["sc"]),
			})
		var rings: Array = []
		for r_frac_raw in ring_fracs:
			var rm := MeshInstance3D.new()
			rm.mesh = steam_ring_mesh
			rm.rotation.x = PI * 0.5
			rm.material_override = ring_mat
			rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(rm)
			rings.append({"mi": rm, "frac": float(r_frac_raw)})
		var burst_ring := MeshInstance3D.new()
		burst_ring.mesh = wide_ring_mesh
		burst_ring.scale = Vector3(1.0, 0.26, 1.0)
		burst_ring.material_override = ring_mat
		burst_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(burst_ring)
		var burst_cloud := MeshInstance3D.new()
		burst_cloud.mesh = puff_mesh
		burst_cloud.material_override = puff_mat
		burst_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(burst_cloud)
		parent.add_child(n)
		_steam_pool.append({
			"node": n, "mat": puff_mat, "ring_mat": ring_mat,
			"puffs": puffs, "rings": rings,
			"burst_ring": burst_ring, "burst_cloud": burst_cloud,
			"timer": 0.0, "duration": 0.62, "dist": 6.0,
			"start_scale": 1.0, "end_scale": 1.0,
			"col": Color.WHITE, "puff_col": Color(0.95, 0.92, 0.86), "ring_col": Color(1.0, 0.84, 0.50),
			"stretch_z": false, "is_steam": true,
		})

	for _i in range(SHOCKWAVE_POOL_SIZE):
		var mat: StandardMaterial3D = _make_fx_mat()
		var n := Node3D.new()
		n.visible = false
		var mi := MeshInstance3D.new()
		mi.mesh = wide_ring_mesh
		mi.scale = Vector3(1.0, 0.20, 1.0)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		parent.add_child(n)
		_shockwave_pool.append({
			"node": n, "mat": mat, "timer": 0.0, "duration": 0.45,
			"start_scale": 0.8, "end_scale": 3.5, "col": Color(1.0, 0.28, 0.16), "stretch_z": false,
		})

	for _i in range(EXPLOSION_POOL_SIZE):
		var mat: StandardMaterial3D = _make_fx_mat()
		var n := Node3D.new()
		n.visible = false
		var orb := MeshInstance3D.new()
		orb.mesh = sphere_mesh
		orb.material_override = mat
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(orb)
		var ring := MeshInstance3D.new()
		ring.mesh = wide_ring_mesh
		ring.scale = Vector3(1.4, 0.22, 1.4)
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(ring)
		parent.add_child(n)
		_explosion_pool.append({
			"node": n, "mat": mat, "timer": 0.0, "duration": 0.85,
			"start_scale": 0.8, "end_scale": 5.2, "col": Color(1.0, 0.45, 0.14), "stretch_z": false,
		})

	# Pre-allocate persistent scorch decals (PCK Decal or clean quad fallback)
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
		scorch_fallback_mat.albedo_color = Color(0.08, 0.06, 0.05, 0.42)
		scorch_fallback_mat.roughness = 0.95
		scorch_fallback_mat.metallic = 0.0
		scorch_fallback_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for s_i in range(SCORCH_POOL_SIZE):
		if mark_tex != null:
			var dec := Decal.new()
			dec.size = Vector3(2.0, 0.45, 2.0)
			dec.texture_albedo = mark_tex
			dec.modulate = Color(0.22, 0.18, 0.15, 0.72)
			dec.upper_fade = 0.35
			dec.lower_fade = 0.35
			dec.position = Vector3(0.0, -50.0, 0.0)
			dec.visible = false
			parent.add_child(dec)
			_scorch_pool.append({"node": dec, "is_decal": true, "seed_ang": float(s_i) * 1.13})
		else:
			var smi := MeshInstance3D.new()
			smi.mesh = scorch_plane_mesh
			smi.material_override = scorch_fallback_mat
			smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			smi.position = Vector3(0.0, -50.0, 0.0)
			smi.visible = false
			parent.add_child(smi)
			_scorch_pool.append({"node": smi, "is_decal": false, "seed_ang": float(s_i) * 1.13})

	# Pre-allocate brief impact flash OmniLight3Ds (zero shadows)
	for _i in range(FLASH_LIGHT_POOL_SIZE):
		var fl := OmniLight3D.new()
		fl.shadow_enabled = false
		fl.light_color = Color(1.0, 0.56, 0.20)
		fl.light_energy = 0.0
		fl.omni_range = 6.0
		fl.position = Vector3(0.0, -50.0, 0.0)
		fl.visible = false
		parent.add_child(fl)
		_flash_pool.append({"light": fl, "timer": 0.0, "duration": 0.25, "peak_energy": 4.0})

	# Pre-allocate subtle warm dust/ember motes drifting in central light pools
	var mote_mesh := QuadMesh.new()
	mote_mesh.size = Vector2(0.075, 0.075)
	var mote_mat := StandardMaterial3D.new()
	mote_mat.albedo_color = Color(1.0, 0.82, 0.52, 0.36)
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
		var bx: float = -7.2 + float(m_i % 4) * 4.8 + sin(float(m_i) * 2.1) * 1.1
		var by: float = 1.25 + float(m_i % 3) * 0.95
		var bz: float = -2.8 + float(m_i / 4) * 1.85 + cos(float(m_i) * 1.7) * 0.5
		var base_pos := Vector3(bx, by, bz)
		mmi.position = base_pos
		parent.add_child(mmi)
		_motes.append({
			"node": mmi,
			"base": base_pos,
			"phase": float(m_i) * 0.83,
			"sx": 0.35 + float(m_i % 3) * 0.14,
			"sy": 0.52 + float(m_i % 4) * 0.11,
			"sz": 0.31 + float(m_i % 5) * 0.09,
			"scale": 0.72 + float(m_i % 4) * 0.16,
		})

	# Pre-allocate subtle wheel-rail spark bursts
	var rail_spark_mesh := BoxMesh.new()
	rail_spark_mesh.size = Vector3(0.26, 0.045, 0.045)
	for _i in range(RAIL_SPARK_POOL_SIZE):
		var rmat: StandardMaterial3D = _make_fx_mat()
		rmat.emission_energy_multiplier = 2.8
		var rn := Node3D.new()
		rn.visible = false
		for rs_idx in range(3):
			var rsp := MeshInstance3D.new()
			rsp.mesh = rail_spark_mesh
			rsp.position = Vector3(-0.18 - float(rs_idx) * 0.10, 0.08 + float(rs_idx) * 0.06, (float(rs_idx) - 1.0) * 0.08)
			rsp.rotation.z = -0.25 - float(rs_idx) * 0.14
			rsp.rotation.y = (float(rs_idx) - 1.0) * 0.28
			rsp.material_override = rmat
			rsp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rn.add_child(rsp)
		parent.add_child(rn)
		_rail_spark_pool.append({
			"node": rn, "mat": rmat, "timer": 0.0, "duration": 0.22,
			"start_scale": 0.55, "end_scale": 1.25, "col": Color(1.0, 0.72, 0.22), "stretch_z": false,
		})

	_all_pools = [_shove_pool, _ram_pool, _steam_pool, _shockwave_pool, _explosion_pool, _rail_spark_pool]
	_initialized = true


func warmup_in_frustum(cam: Camera3D) -> void:
	if not _initialized:
		return
	var warm_pos: Vector3 = Vector3(0.0, 0.5, 0.0)
	if cam != null and is_instance_valid(cam):
		warm_pos = cam.global_position + (-cam.global_transform.basis.z * 6.0)
	for pool_raw in _all_pools:
		var pool: Array = pool_raw as Array
		if pool.is_empty():
			continue
		var slot: Dictionary = pool[0] as Dictionary
		var n := slot["node"] as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var mat := slot["mat"] as StandardMaterial3D
		n.position = warm_pos
		n.scale = Vector3(0.01, 0.01, 0.01)
		n.visible = true
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.05)
		slot["timer"] = 0.05
		slot["duration"] = 0.05


func _activate_slot(pool: Array, cursor: int, pos: Vector3, col: Color, dur: float, s0: float, s1: float) -> int:
	if not _initialized or pool.is_empty():
		return cursor
	var slot: Dictionary = pool[cursor] as Dictionary
	var n := slot["node"] as Node3D
	if n == null or not is_instance_valid(n):
		return (cursor + 1) % pool.size()
	var mat := slot["mat"] as StandardMaterial3D
	n.position = pos
	n.rotation = Vector3.ZERO
	n.scale = Vector3(s0, s0, s0)
	n.visible = true
	mat.albedo_color = Color(col.r, col.g, col.b, 0.92)
	mat.emission = Color(col.r, col.g, col.b, 1.0)
	slot["timer"] = dur
	slot["duration"] = dur
	slot["start_scale"] = s0
	slot["end_scale"] = s1
	slot["col"] = col
	return (cursor + 1) % pool.size()


func _spawn_flash_light(pos: Vector3, col: Color, peak_energy: float, range_m: float, dur: float) -> void:
	if not _initialized or _flash_pool.is_empty():
		return
	var slot: Dictionary = _flash_pool[_flash_cursor] as Dictionary
	_flash_cursor = (_flash_cursor + 1) % _flash_pool.size()
	var fl := slot["light"] as OmniLight3D
	if fl == null or not is_instance_valid(fl):
		return
	fl.position = Vector3(pos.x, maxf(pos.y, 0.75), pos.z)
	fl.light_color = col
	fl.omni_range = range_m
	fl.light_energy = peak_energy
	fl.visible = true
	slot["timer"] = dur
	slot["duration"] = dur
	slot["peak_energy"] = peak_energy


func spawn_scorch_decal(pos: Vector3, scale_r: float = 2.0) -> void:
	if not _initialized or _scorch_pool.is_empty():
		return
	var slot: Dictionary = _scorch_pool[_scorch_cursor] as Dictionary
	_scorch_cursor = (_scorch_cursor + 1) % _scorch_pool.size()
	var rot_y: float = fmod(absf(pos.x * 1.73 + pos.z * 2.31) + float(slot["seed_ang"]), TAU)
	if bool(slot["is_decal"]):
		var dec := slot["node"] as Decal
		if dec != null and is_instance_valid(dec):
			dec.size = Vector3(scale_r, 0.45, scale_r)
			dec.position = Vector3(pos.x, 0.04, pos.z)
			dec.rotation.y = rot_y
			dec.visible = true
	else:
		var mi := slot["node"] as MeshInstance3D
		if mi != null and is_instance_valid(mi):
			mi.position = Vector3(pos.x, 0.024, pos.z)
			mi.rotation.y = rot_y
			mi.scale = Vector3(scale_r * 0.85, 1.0, scale_r * 0.85)
			mi.visible = true


func spawn_rail_spark(pos: Vector3, dir_x: float, yaw: float = 0.0) -> void:
	if not _initialized or _rail_spark_pool.is_empty():
		return
	var rail_side: float = 0.62 if (_rail_spark_cursor % 2 == 0) else -0.62
	var forward_sign: float = 1.0 if dir_x >= 0.0 else -1.0
	var local_off := Vector3(-forward_sign * 0.65, 0.14, rail_side)
	var world_off: Vector3 = local_off.rotated(Vector3.UP, yaw)
	var spark_pos := Vector3(pos.x + world_off.x, 0.14, pos.z + world_off.z)
	var slot_idx: int = _rail_spark_cursor
	_rail_spark_cursor = _activate_slot(
		_rail_spark_pool, _rail_spark_cursor,
		spark_pos, Color(1.0, 0.74, 0.24, 1.0), 0.22, 0.55, 1.25
	)
	var slot: Dictionary = _rail_spark_pool[slot_idx] as Dictionary
	var n := slot["node"] as Node3D
	if n != null and is_instance_valid(n):
		n.rotation.y = yaw + (0.0 if forward_sign >= 0.0 else PI)


func spawn_shove_burst(pos: Vector3, col: Color) -> void:
	_shove_cursor = _activate_slot(_shove_pool, _shove_cursor, pos + Vector3(0.0, 0.25, 0.0), col, 0.34, 0.55, 2.2)


func spawn_ram_sparks(pos: Vector3, col: Color) -> void:
	_ram_cursor = _activate_slot(_ram_pool, _ram_cursor, pos + Vector3(0.0, 0.45, 0.0), col, 0.32, 0.65, 2.3)
	_spawn_flash_light(pos, col.lerp(Color(1.0, 0.72, 0.28), 0.5), 3.2, 5.2, 0.20)


func _update_steam_layout(slot: Dictionary, progress: float) -> void:
	var dist: float = float(slot.get("dist", 6.0))
	var fade: float = clampf(1.0 - progress, 0.0, 1.0)
	var puff_col: Color = slot.get("puff_col", Color(0.95, 0.92, 0.86)) as Color
	var ring_col: Color = slot.get("ring_col", Color(1.0, 0.84, 0.50)) as Color
	var puff_mat := slot["mat"] as StandardMaterial3D
	var ring_mat := slot.get("ring_mat", null) as StandardMaterial3D
	if puff_mat != null:
		puff_mat.albedo_color = Color(puff_col.r, puff_col.g, puff_col.b, fade * 0.72)
		puff_mat.emission = puff_col
	if ring_mat != null:
		ring_mat.albedo_color = Color(ring_col.r, ring_col.g, ring_col.b, fade * 0.88)
		ring_mat.emission = ring_col

	var dist_scale: float = clampf(dist / 7.5, 0.90, 1.48)
	var puffs: Array = slot.get("puffs", []) as Array
	for p_raw in puffs:
		var pd: Dictionary = p_raw as Dictionary
		var pm := pd["mi"] as MeshInstance3D
		if pm == null or not is_instance_valid(pm):
			continue
		var frac: float = clampf(float(pd["frac"]) + progress * 0.12, 0.03, 1.03)
		var spread: float = (1.0 + progress * 1.45) * dist_scale
		pm.position = Vector3(float(pd["ox"]) * spread, float(pd["oy"]) + progress * 0.55, -frac * dist)
		var s: float = float(pd["sc"]) * lerpf(0.62, 1.48, progress) * dist_scale
		pm.scale = Vector3(s * 1.14, s * 0.88, s * 1.28)

	var rings: Array = slot.get("rings", []) as Array
	for r_raw in rings:
		var rd: Dictionary = r_raw as Dictionary
		var rm := rd["mi"] as MeshInstance3D
		if rm == null or not is_instance_valid(rm):
			continue
		var r_frac: float = clampf(float(rd["frac"]) + progress * 0.24, 0.08, 1.0)
		rm.position = Vector3(0.0, progress * 0.18, -r_frac * dist)
		var rs: float = lerpf(0.52, 1.48, clampf(progress + r_frac * 0.25, 0.0, 1.0))
		rm.scale = Vector3(rs, rs, rs)

	var burst_ring := slot.get("burst_ring", null) as MeshInstance3D
	if burst_ring != null and is_instance_valid(burst_ring):
		burst_ring.position = Vector3(0.0, 0.08, -dist)
		var brs: float = lerpf(0.75, 2.25, progress)
		burst_ring.scale = Vector3(brs, 0.28, brs)
	var burst_cloud := slot.get("burst_cloud", null) as MeshInstance3D
	if burst_cloud != null and is_instance_valid(burst_cloud):
		burst_cloud.position = Vector3(0.0, 0.24 + progress * 0.55, -dist)
		var bcs: float = lerpf(1.15, 2.55, progress)
		burst_cloud.scale = Vector3(bcs, bcs * 0.78, bcs)


func spawn_steam_surge(valve_pos: Vector3, cart_pos: Vector3, col: Color) -> void:
	if not _initialized or _steam_pool.is_empty():
		return
	var slot: Dictionary = _steam_pool[_steam_cursor] as Dictionary
	_steam_cursor = (_steam_cursor + 1) % _steam_pool.size()
	var n := slot["node"] as Node3D
	if n == null or not is_instance_valid(n):
		return
	var a: Vector3 = valve_pos + Vector3(0.0, 0.52, 0.0)
	var b: Vector3 = cart_pos + Vector3(0.0, 0.62, 0.0)
	var dist: float = maxf(0.4, a.distance_to(b))
	if a.distance_squared_to(b) > 0.001:
		n.look_at_from_position(a, b, Vector3.UP)
	else:
		n.position = a
		n.rotation = Vector3.ZERO
	n.scale = Vector3.ONE
	n.visible = true
	var puff_col: Color = Color(0.96, 0.94, 0.89, 1.0).lerp(col, 0.10)
	var ring_col: Color = Color(1.0, 0.84, 0.46, 1.0).lerp(col, 0.24)
	slot["timer"] = 0.62
	slot["duration"] = 0.62
	slot["dist"] = dist
	slot["col"] = puff_col
	slot["puff_col"] = puff_col
	slot["ring_col"] = ring_col
	_update_steam_layout(slot, 0.08)


func spawn_shockwave(cart_pos: Vector3) -> void:
	_shockwave_cursor = _activate_slot(
		_shockwave_pool, _shockwave_cursor,
		cart_pos + Vector3(0.0, 0.12, 0.0),
		Color(1.0, 0.26, 0.16, 1.0), 0.45, 0.75, 3.6
	)
	_spawn_flash_light(cart_pos, Color(1.0, 0.36, 0.16), 5.2, 7.5, 0.32)


func spawn_door_explosion(door_pos: Vector3, col: Color) -> void:
	_explosion_cursor = _activate_slot(
		_explosion_pool, _explosion_cursor,
		door_pos + Vector3(0.0, 1.1, 0.0),
		col, 0.85, 0.8, 5.4
	)
	_spawn_flash_light(door_pos, col.lerp(Color(1.0, 0.52, 0.18), 0.45), 6.5, 9.5, 0.45)


func tick(delta: float) -> void:
	if not _initialized:
		return
	_mote_time += delta
	for m_raw in _motes:
		var md: Dictionary = m_raw as Dictionary
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

	for f_raw in _flash_pool:
		var fslot: Dictionary = f_raw as Dictionary
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
	for pool_raw in _all_pools:
		var pool: Array = pool_raw as Array
		for slot_raw in pool:
			var slot: Dictionary = slot_raw as Dictionary
			var t: float = float(slot["timer"])
			if t <= 0.0:
				continue
			t = maxf(0.0, t - delta)
			slot["timer"] = t
			var n := slot["node"] as Node3D
			if n == null or not is_instance_valid(n):
				slot["timer"] = 0.0
				continue
			if t <= 0.0:
				n.visible = false
				continue
			var dur: float = maxf(0.001, float(slot["duration"]))
			var progress: float = 1.0 - (t / dur)
			if bool(slot.get("is_steam", false)):
				_update_steam_layout(slot, progress)
				continue
			var col: Color = slot["col"] as Color
			var mat := slot["mat"] as StandardMaterial3D
			mat.albedo_color = Color(col.r, col.g, col.b, clampf(1.0 - progress, 0.0, 1.0) * 0.92)
			if bool(slot["stretch_z"]):
				var w: float = lerpf(1.4, 0.25, progress)
				n.scale = Vector3(w, w, float(slot["start_scale"]))
			else:
				var s: float = lerpf(float(slot["start_scale"]), float(slot["end_scale"]), progress)
				n.scale = Vector3(s, s, s)
