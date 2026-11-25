extends RefCounted

## Pre-allocated FX pool for Bomb Cart (炸彈推車).
## All nodes, meshes, and materials are allocated once in setup().
## Zero runtime new(), instantiate(), or queue_free() in spawn_*() or tick().

const SHOVE_POOL_SIZE := 6
const RAM_POOL_SIZE := 6
const STEAM_POOL_SIZE := 4
const SHOCKWAVE_POOL_SIZE := 3
const EXPLOSION_POOL_SIZE := 2

var _initialized: bool = false
var _shove_pool: Array = []
var _ram_pool: Array = []
var _steam_pool: Array = []
var _shockwave_pool: Array = []
var _explosion_pool: Array = []

var _shove_cursor: int = 0
var _ram_cursor: int = 0
var _steam_cursor: int = 0
var _shockwave_cursor: int = 0
var _explosion_cursor: int = 0

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


func setup(parent: Node3D) -> void:
	if _initialized or parent == null:
		return

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

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.18
	beam_mesh.bottom_radius = 0.18
	beam_mesh.height = 1.0
	beam_mesh.radial_segments = 12

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

	for _i in range(STEAM_POOL_SIZE):
		var mat: StandardMaterial3D = _make_fx_mat()
		var n := Node3D.new()
		n.visible = false
		var mi := MeshInstance3D.new()
		mi.mesh = beam_mesh
		mi.rotation.x = PI * 0.5
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		parent.add_child(n)
		_steam_pool.append({
			"node": n, "mat": mat, "timer": 0.0, "duration": 0.55,
			"start_scale": 1.0, "end_scale": 1.0, "col": Color.WHITE, "stretch_z": true,
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

	_all_pools = [_shove_pool, _ram_pool, _steam_pool, _shockwave_pool, _explosion_pool]
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


func spawn_shove_burst(pos: Vector3, col: Color) -> void:
	_shove_cursor = _activate_slot(_shove_pool, _shove_cursor, pos + Vector3(0.0, 0.25, 0.0), col, 0.34, 0.55, 2.2)


func spawn_ram_sparks(pos: Vector3, col: Color) -> void:
	_ram_cursor = _activate_slot(_ram_pool, _ram_cursor, pos + Vector3(0.0, 0.45, 0.0), col, 0.32, 0.65, 2.3)


func spawn_steam_surge(valve_pos: Vector3, cart_pos: Vector3, col: Color) -> void:
	if not _initialized or _steam_pool.is_empty():
		return
	var slot: Dictionary = _steam_pool[_steam_cursor] as Dictionary
	_steam_cursor = (_steam_cursor + 1) % _steam_pool.size()
	var n := slot["node"] as Node3D
	var mat := slot["mat"] as StandardMaterial3D
	var a: Vector3 = valve_pos + Vector3(0.0, 0.35, 0.0)
	var b: Vector3 = cart_pos + Vector3(0.0, 0.35, 0.0)
	var dist: float = maxf(0.2, a.distance_to(b))
	n.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
	n.scale = Vector3(1.2, 1.2, dist)
	n.visible = true
	mat.albedo_color = Color(col.r, col.g, col.b, 0.90)
	mat.emission = Color(col.r, col.g, col.b, 1.0)
	slot["timer"] = 0.55
	slot["duration"] = 0.55
	slot["start_scale"] = dist
	slot["end_scale"] = dist
	slot["col"] = col


func spawn_shockwave(cart_pos: Vector3) -> void:
	_shockwave_cursor = _activate_slot(
		_shockwave_pool, _shockwave_cursor,
		cart_pos + Vector3(0.0, 0.12, 0.0),
		Color(1.0, 0.26, 0.16, 1.0), 0.45, 0.75, 3.6
	)


func spawn_door_explosion(door_pos: Vector3, col: Color) -> void:
	_explosion_cursor = _activate_slot(
		_explosion_pool, _explosion_cursor,
		door_pos + Vector3(0.0, 1.1, 0.0),
		col, 0.85, 0.8, 5.4
	)


func tick(delta: float) -> void:
	if not _initialized:
		return
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
			if t <= 0.0:
				n.visible = false
				continue
			var dur: float = maxf(0.001, float(slot["duration"]))
			var progress: float = 1.0 - (t / dur)
			var col: Color = slot["col"] as Color
			var mat := slot["mat"] as StandardMaterial3D
			mat.albedo_color = Color(col.r, col.g, col.b, clampf(1.0 - progress, 0.0, 1.0) * 0.92)
			if bool(slot["stretch_z"]):
				var w: float = lerpf(1.4, 0.25, progress)
				n.scale = Vector3(w, w, float(slot["start_scale"]))
			else:
				var s: float = lerpf(float(slot["start_scale"]), float(slot["end_scale"]), progress)
				n.scale = Vector3(s, s, s)
