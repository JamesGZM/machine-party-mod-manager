extends RefCounted

## Pre-allocated FX pool for Voltage Greed using mpm-core.create_fx_pool() when available
## plus procedural spark/arc/smoke/blood/overload-flash pools.
## Zero runtime allocations (new / instantiate / queue_free) after setup().

const KICK_ARC_POOL_SIZE := 6
const PARALLEL_ARC_POOL_SIZE := 10
const SPARK_BURST_POOL_SIZE := 8
const SMOKE_PUFF_POOL_SIZE := 8
const BLOOD_BURST_POOL_SIZE := 4
const BLAST_WAVE_POOL_SIZE := 3
const FLASH_LIGHT_POOL_SIZE := 2

var _initialized: bool = false
var _core_pool = null

var _kick_arcs: Array = []
var _parallel_arcs: Array = []
var _spark_bursts: Array = []
var _smoke_puffs: Array = []
var _blood_bursts: Array = []
var _blast_waves: Array = []
var _flash_lights: Array = []

var _kick_cursor: int = 0
var _spark_cursor: int = 0
var _smoke_cursor: int = 0
var _blood_cursor: int = 0
var _blast_cursor: int = 0
var _flash_cursor: int = 0

var _elapsed: float = 0.0


func _create_mpm_fx_pool():
	if Engine.has_meta(&"mpm_core"):
		var core = Engine.get_meta(&"mpm_core")
		if core is Dictionary:
			var mod_node = (core as Dictionary).get("node", null)
			if mod_node != null and mod_node.has_method("create_fx_pool"):
				return mod_node.call("create_fx_pool")
	return null


func _make_unshaded_mat(col: Color, energy: float = 2.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = Color(col.r, col.g, col.b, 1.0)
	mat.emission_energy_multiplier = energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _build_arc_node(mat: StandardMaterial3D, seg_mesh: BoxMesh, ring_mesh: TorusMesh, seg_count: int) -> Node3D:
	var root := Node3D.new()
	root.visible = false
	for i in range(seg_count):
		var seg := MeshInstance3D.new()
		seg.name = "Seg_%d" % i
		seg.mesh = seg_mesh
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(seg)
	if ring_mesh != null:
		var ring := MeshInstance3D.new()
		ring.name = "ImpactRing"
		ring.mesh = ring_mesh
		ring.scale = Vector3(1.0, 0.25, 1.0)
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ring)
	return root


func setup(parent: Node3D) -> void:
	if parent == null:
		return
	if _initialized:
		if not _kick_arcs.is_empty() and is_instance_valid((_kick_arcs[0] as Dictionary).get("node", null)):
			return
		clear_all()

	_core_pool = _create_mpm_fx_pool()

	var seg_mesh := BoxMesh.new()
	seg_mesh.size = Vector3(0.085, 0.085, 1.0)

	var thin_seg_mesh := BoxMesh.new()
	thin_seg_mesh.size = Vector3(0.06, 0.06, 1.0)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.28
	ring_mesh.outer_radius = 0.46
	ring_mesh.rings = 20
	ring_mesh.ring_segments = 6

	var wide_ring_mesh := TorusMesh.new()
	wide_ring_mesh.inner_radius = 0.72
	wide_ring_mesh.outer_radius = 1.08
	wide_ring_mesh.rings = 28
	wide_ring_mesh.ring_segments = 6

	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.07, 0.07, 0.42)

	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 0.26
	puff_mesh.height = 0.48
	puff_mesh.radial_segments = 10
	puff_mesh.rings = 6

	var blood_mesh := SphereMesh.new()
	blood_mesh.radius = 0.14
	blood_mesh.height = 0.24
	blood_mesh.radial_segments = 8
	blood_mesh.rings = 6

	# Register core pool slots when mpm-core is mounted for lifecycle telemetry
	if _core_pool != null and _core_pool.has_method("register_pool"):
		_core_pool.call("register_pool", "vg_spark_markers", parent, func() -> Node3D:
			var marker := Node3D.new()
			marker.name = "VGPooledMarker"
			return marker
		, 2)

	# 1. Kick Arcs (from chair cable_anchor -> transformer_top)
	for _i in range(KICK_ARC_POOL_SIZE):
		var mat: StandardMaterial3D = _make_unshaded_mat(Color(1.0, 0.85, 0.30, 0.95), 3.4)
		var arc_node: Node3D = _build_arc_node(mat, seg_mesh, ring_mesh, 4)
		parent.add_child(arc_node)
		var segs: Array = []
		for si in range(4):
			segs.append(arc_node.get_node("Seg_%d" % si))
		_kick_arcs.append({
			"node": arc_node,
			"mat": mat,
			"segs": segs,
			"ring": arc_node.get_node("ImpactRing"),
			"timer": 0.0,
			"duration": 0.42,
			"col": Color(1.0, 0.85, 0.30),
			"from": Vector3.ZERO,
			"to": Vector3.FORWARD,
		})

	# 2. Team Parallel Bridge Arcs
	for _i in range(PARALLEL_ARC_POOL_SIZE):
		var mat: StandardMaterial3D = _make_unshaded_mat(Color(0.35, 0.88, 1.0, 0.85), 2.8)
		var arc_node: Node3D = _build_arc_node(mat, thin_seg_mesh, null, 3)
		parent.add_child(arc_node)
		var segs: Array = []
		for si in range(3):
			segs.append(arc_node.get_node("Seg_%d" % si))
		_parallel_arcs.append({
			"node": arc_node,
			"mat": mat,
			"segs": segs,
			"active": false,
			"from": Vector3.ZERO,
			"to": Vector3.FORWARD,
			"col": Color(0.35, 0.88, 1.0),
		})

	# 3. Radial Electric Spark Bursts
	for _i in range(SPARK_BURST_POOL_SIZE):
		var mat: StandardMaterial3D = _make_unshaded_mat(Color(1.0, 0.86, 0.34, 0.95), 3.2)
		var n := Node3D.new()
		n.visible = false
		var rays: Array = []
		for r_idx in range(6):
			var ang: float = float(r_idx) * (TAU / 6.0)
			var sp := MeshInstance3D.new()
			sp.mesh = spark_mesh
			sp.position = Vector3(cos(ang) * 0.35, 0.15 + float(r_idx % 2) * 0.18, sin(ang) * 0.35)
			sp.rotation = Vector3(-0.35, -ang, 0.0)
			sp.material_override = mat
			sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(sp)
			rays.append(sp)
		parent.add_child(n)
		_spark_bursts.append({
			"node": n,
			"mat": mat,
			"timer": 0.0,
			"duration": 0.38,
			"col": Color(1.0, 0.86, 0.34),
			"s0": 0.5,
			"s1": 2.4,
		})

	# 4. Char Smoke Puffs
	for _i in range(SMOKE_PUFF_POOL_SIZE):
		var mat: StandardMaterial3D = _make_unshaded_mat(Color(0.24, 0.22, 0.20, 0.82), 0.35)
		var n := Node3D.new()
		n.visible = false
		for pi in range(4):
			var pm := MeshInstance3D.new()
			pm.mesh = puff_mesh
			var a: float = float(pi) * (TAU * 0.25)
			pm.position = Vector3(cos(a) * 0.20, float(pi) * 0.22, sin(a) * 0.20)
			pm.material_override = mat
			pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(pm)
		parent.add_child(n)
		_smoke_puffs.append({
			"node": n,
			"mat": mat,
			"timer": 0.0,
			"duration": 0.95,
			"col": Color(0.24, 0.22, 0.20),
			"s0": 0.65,
			"s1": 2.1,
		})

	# 5. Lethal Execution Blood Bursts
	for _i in range(BLOOD_BURST_POOL_SIZE):
		var mat: StandardMaterial3D = _make_unshaded_mat(Color(0.82, 0.08, 0.08, 0.92), 0.8)
		var n := Node3D.new()
		n.visible = false
		for bi in range(6):
			var bm := MeshInstance3D.new()
			bm.mesh = blood_mesh
			var a: float = float(bi) * (TAU / 6.0) + 0.3
			bm.position = Vector3(cos(a) * 0.34, 0.12 + float(bi % 3) * 0.14, sin(a) * 0.34)
			bm.material_override = mat
			bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(bm)
		parent.add_child(n)
		_blood_bursts.append({
			"node": n,
			"mat": mat,
			"timer": 0.0,
			"duration": 0.55,
			"col": Color(0.82, 0.08, 0.08),
			"s0": 0.6,
			"s1": 2.5,
		})

	# 6. Transformer Overload Shockwave Rings
	for _i in range(BLAST_WAVE_POOL_SIZE):
		var mat: StandardMaterial3D = _make_unshaded_mat(Color(1.0, 0.42, 0.14, 0.92), 3.0)
		var n := Node3D.new()
		n.visible = false
		var ring := MeshInstance3D.new()
		ring.mesh = wide_ring_mesh
		ring.scale = Vector3(1.0, 0.22, 1.0)
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(ring)
		parent.add_child(n)
		_blast_waves.append({
			"node": n,
			"mat": mat,
			"timer": 0.0,
			"duration": 0.52,
			"col": Color(1.0, 0.42, 0.14),
			"s0": 0.6,
			"s1": 4.4,
		})

	# 7. Overload Flash OmniLight3D Pool (strictly <= 2)
	for _i in range(FLASH_LIGHT_POOL_SIZE):
		var lt := OmniLight3D.new()
		lt.light_color = Color(0.75, 0.90, 1.0)
		lt.light_energy = 0.0
		lt.omni_range = 10.0
		lt.shadow_enabled = false
		lt.visible = false
		parent.add_child(lt)
		_flash_lights.append({
			"light": lt,
			"timer": 0.0,
			"duration": 0.24,
			"peak_energy": 6.5,
		})

	_initialized = true


func warmup_in_frustum(camera: Camera3D) -> void:
	if not _initialized:
		return
	var warm_pos := Vector3(0.0, 0.8, -1.5)
	if camera != null and is_instance_valid(camera):
		warm_pos = camera.global_position + (-camera.global_transform.basis.z * 5.0)

	for list in [_spark_bursts, _smoke_puffs, _blood_bursts, _blast_waves]:
		var arr: Array = list as Array
		if arr.is_empty():
			continue
		var slot: Dictionary = arr[0] as Dictionary
		var n := slot["node"] as Node3D
		if n != null and is_instance_valid(n):
			n.position = warm_pos
			n.scale = Vector3(0.01, 0.01, 0.01)
			n.visible = true
			slot["timer"] = 0.08
			slot["duration"] = 0.08

	if not _kick_arcs.is_empty():
		var kslot: Dictionary = _kick_arcs[0] as Dictionary
		var kn := kslot["node"] as Node3D
		if kn != null and is_instance_valid(kn):
			kn.position = warm_pos
			kn.scale = Vector3(0.01, 0.01, 0.01)
			kn.visible = true
			kslot["from"] = warm_pos
			kslot["to"] = warm_pos + Vector3(0.02, 0.02, 0.0)
			kslot["timer"] = 0.08
			kslot["duration"] = 0.08


func _layout_arc_segments(slot: Dictionary, jitter_amp: float) -> void:
	var n := slot["node"] as Node3D
	if n == null or not is_instance_valid(n):
		return
	var a: Vector3 = slot["from"] as Vector3
	var b: Vector3 = slot["to"] as Vector3
	var segs: Array = slot["segs"] as Array
	var count: int = segs.size()
	if count <= 0:
		return
	n.position = Vector3.ZERO
	n.rotation = Vector3.ZERO

	var dir: Vector3 = b - a
	var dist: float = dir.length()
	if dist < 0.01:
		n.visible = false
		return

	var prev_pt: Vector3 = a
	for i in range(count):
		var t_next: float = float(i + 1) / float(count)
		var next_pt: Vector3 = a.lerp(b, t_next)
		if i < count - 1:
			var phase: float = _elapsed * 38.0 + float(i) * 2.1
			next_pt += Vector3(sin(phase) * jitter_amp, cos(phase * 1.3) * jitter_amp, sin(phase * 0.7) * jitter_amp * 0.5)
		var seg := segs[i] as MeshInstance3D
		if seg != null:
			var seg_len: float = maxf(0.02, prev_pt.distance_to(next_pt))
			var mid: Vector3 = (prev_pt + next_pt) * 0.5
			seg.position = mid
			if prev_pt.distance_squared_to(next_pt) > 0.0001:
				var up_v := Vector3.UP if absf((next_pt - prev_pt).normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
				seg.look_at_from_position(mid, next_pt, up_v)
			seg.scale = Vector3(1.0, 1.0, seg_len)
		prev_pt = next_pt

	var ring = slot.get("ring", null)
	if ring is MeshInstance3D and is_instance_valid(ring):
		(ring as MeshInstance3D).position = b


func _spawn_flash(pos: Vector3, col: Color, energy: float, dur: float) -> void:
	if _flash_lights.is_empty():
		return
	var slot: Dictionary = _flash_lights[_flash_cursor] as Dictionary
	_flash_cursor = (_flash_cursor + 1) % _flash_lights.size()
	var lt := slot["light"] as OmniLight3D
	if lt == null or not is_instance_valid(lt):
		return
	lt.position = pos
	lt.light_color = col
	lt.light_energy = energy
	lt.visible = true
	slot["timer"] = dur
	slot["duration"] = dur
	slot["peak_energy"] = energy


func _spawn_pooled(pool: Array, cursor: int, pos: Vector3, col: Color, dur: float, s0: float, s1: float) -> int:
	if pool.is_empty():
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
	slot["col"] = col
	slot["s0"] = s0
	slot["s1"] = s1
	return (cursor + 1) % pool.size()


func trigger_kick_arc(from_pos: Vector3, to_pos: Vector3, color: Color) -> void:
	if not _initialized or _kick_arcs.is_empty():
		return
	var slot: Dictionary = _kick_arcs[_kick_cursor] as Dictionary
	_kick_cursor = (_kick_cursor + 1) % _kick_arcs.size()
	var n := slot["node"] as Node3D
	if n == null or not is_instance_valid(n):
		return
	var mat := slot["mat"] as StandardMaterial3D
	n.scale = Vector3.ONE
	n.visible = true
	mat.albedo_color = Color(color.r, color.g, color.b, 0.96)
	mat.emission = color
	slot["from"] = from_pos
	slot["to"] = to_pos
	slot["col"] = color
	slot["timer"] = 0.42
	slot["duration"] = 0.42
	_layout_arc_segments(slot, 0.22)
	_spark_cursor = _spawn_pooled(_spark_bursts, _spark_cursor, to_pos, color, 0.34, 0.65, 2.2)
	_spawn_flash(to_pos, color.lightened(0.25), 5.5, 0.22)


func update_parallel_arcs(pairs: Array) -> void:
	if not _initialized:
		return
	for i in range(_parallel_arcs.size()):
		var slot: Dictionary = _parallel_arcs[i] as Dictionary
		var n := slot["node"] as Node3D
		if i >= pairs.size():
			slot["active"] = false
			if n != null and is_instance_valid(n):
				n.visible = false
			continue
		var pair: Dictionary = pairs[i] as Dictionary
		var a: Vector3 = pair.get("a", Vector3.ZERO) as Vector3
		var b: Vector3 = pair.get("b", Vector3.ZERO) as Vector3
		var col: Color = pair.get("color", Color(0.35, 0.88, 1.0)) as Color
		slot["active"] = true
		slot["from"] = a
		slot["to"] = b
		slot["col"] = col
		if n != null and is_instance_valid(n):
			n.scale = Vector3.ONE
			n.visible = true
		var mat := slot["mat"] as StandardMaterial3D
		mat.albedo_color = Color(col.r, col.g, col.b, 0.86)
		mat.emission = col
		_layout_arc_segments(slot, 0.14)


func trigger_fry(pos: Vector3, lethal: bool) -> void:
	if not _initialized:
		return
	var spark_col: Color = Color(1.0, 0.36, 0.16) if lethal else Color(0.55, 0.92, 1.0)
	_spark_cursor = _spawn_pooled(_spark_bursts, _spark_cursor, pos, spark_col, 0.42, 0.7, 2.8 if lethal else 2.2)
	_smoke_cursor = _spawn_pooled(_smoke_puffs, _smoke_cursor, pos + Vector3(0.0, 0.30, 0.0), Color(0.22, 0.20, 0.18), 0.95, 0.7, 2.2)
	if lethal:
		_blood_cursor = _spawn_pooled(_blood_bursts, _blood_cursor, pos + Vector3(0.0, 0.05, 0.0), Color(0.84, 0.08, 0.08), 0.58, 0.65, 2.6)
		_blast_cursor = _spawn_pooled(_blast_waves, _blast_cursor, pos + Vector3(0.0, -0.72, 0.0), Color(1.0, 0.26, 0.12), 0.48, 0.4, 2.3)
		_spawn_flash(pos + Vector3(0.0, 0.6, 0.0), Color(1.0, 0.35, 0.18), 7.5, 0.28)
	else:
		_spawn_flash(pos + Vector3(0.0, 0.6, 0.0), Color(0.65, 0.92, 1.0), 5.5, 0.20)


func trigger_slacker_jolt(pos: Vector3) -> void:
	if not _initialized:
		return
	_spark_cursor = _spawn_pooled(_spark_bursts, _spark_cursor, pos, Color(1.0, 0.78, 0.18), 0.36, 0.55, 2.1)
	_smoke_cursor = _spawn_pooled(_smoke_puffs, _smoke_cursor, pos + Vector3(0.0, 0.25, 0.0), Color(0.32, 0.28, 0.24), 0.75, 0.55, 1.6)
	_spawn_flash(pos + Vector3(0.0, 0.4, 0.0), Color(1.0, 0.76, 0.22), 5.0, 0.18)


func trigger_transformer_blast(pos: Vector3) -> void:
	if not _initialized:
		return
	_blast_cursor = _spawn_pooled(_blast_waves, _blast_cursor, pos + Vector3(0.0, -1.6, 0.0), Color(1.0, 0.38, 0.14), 0.58, 0.8, 4.8)
	_spark_cursor = _spawn_pooled(_spark_bursts, _spark_cursor, pos, Color(1.0, 0.90, 0.42), 0.46, 0.9, 3.6)
	_smoke_cursor = _spawn_pooled(_smoke_puffs, _smoke_cursor, pos + Vector3(0.0, 0.3, 0.0), Color(0.20, 0.18, 0.18), 1.05, 1.0, 2.8)
	_spawn_flash(pos + Vector3(0.0, 0.4, 0.6), Color(1.0, 0.48, 0.20), 9.0, 0.32)


func _tick_burst_pool(pool: Array, delta: float, rise_speed: float = 0.0) -> void:
	for raw in pool:
		var slot: Dictionary = raw as Dictionary
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
		var s: float = lerpf(float(slot["s0"]), float(slot["s1"]), progress)
		n.scale = Vector3(s, s, s)
		if rise_speed > 0.0:
			n.position.y += delta * rise_speed
		var col: Color = slot["col"] as Color
		var mat := slot["mat"] as StandardMaterial3D
		mat.albedo_color = Color(col.r, col.g, col.b, clampf(1.0 - progress, 0.0, 1.0) * 0.90)


func tick(delta: float) -> void:
	if not _initialized:
		return
	_elapsed += delta

	for raw in _kick_arcs:
		var slot: Dictionary = raw as Dictionary
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
		var fade: float = clampf(t / dur, 0.0, 1.0)
		var col: Color = slot["col"] as Color
		var mat := slot["mat"] as StandardMaterial3D
		mat.albedo_color = Color(col.r, col.g, col.b, fade * 0.96)
		_layout_arc_segments(slot, 0.22 * fade)

	for raw_p in _parallel_arcs:
		var pslot: Dictionary = raw_p as Dictionary
		if bool(pslot["active"]):
			_layout_arc_segments(pslot, 0.14)

	_tick_burst_pool(_spark_bursts, delta, 0.0)
	_tick_burst_pool(_smoke_puffs, delta, 0.85)
	_tick_burst_pool(_blood_bursts, delta, 0.0)
	_tick_burst_pool(_blast_waves, delta, 0.0)

	for raw_f in _flash_lights:
		var fslot: Dictionary = raw_f as Dictionary
		var t: float = float(fslot["timer"])
		if t <= 0.0:
			continue
		t = maxf(0.0, t - delta)
		fslot["timer"] = t
		var lt := fslot["light"] as OmniLight3D
		if lt == null or not is_instance_valid(lt):
			fslot["timer"] = 0.0
			continue
		if t <= 0.0:
			lt.light_energy = 0.0
			lt.visible = false
		else:
			var dur: float = maxf(0.001, float(fslot["duration"]))
			lt.light_energy = float(fslot["peak_energy"]) * clampf(t / dur, 0.0, 1.0)

	if _core_pool != null and _core_pool.has_method("tick"):
		_core_pool.call("tick", delta)


func clear_all() -> void:
	if _core_pool != null and _core_pool.has_method("clear"):
		_core_pool.call("clear")
	_core_pool = null
	_kick_arcs.clear()
	_parallel_arcs.clear()
	_spark_bursts.clear()
	_smoke_puffs.clear()
	_blood_bursts.clear()
	_blast_waves.clear()
	_flash_lights.clear()
	_kick_cursor = 0
	_spark_cursor = 0
	_smoke_cursor = 0
	_blood_cursor = 0
	_blast_cursor = 0
	_flash_cursor = 0
	_initialized = false
