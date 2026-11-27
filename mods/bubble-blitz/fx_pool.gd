extends RefCounted

## Persistent FX, decal, OmniLight3D, and blast-cell object pools for Bubble Blitz.

const POOL_EXPLOSION_FX := 4
const POOL_HIT_BLOOD_FX := 3
const POOL_BLOODMIST_FX := 2
const POOL_EXPLOSION_DECALS := 16
const POOL_BLOOD_DECALS := 12
const POOL_BLAST_LIGHTS := 2
const POOL_BLAST_CENTER_CELLS := 12
const POOL_BLAST_ARM_CELLS := 48
const AMBIENT_MOTE_COUNT := 16
const EXPLOSION_SFX_MIN_INTERVAL_MS := 45

var explosion_fx_pool: Array[Dictionary] = []
var hit_blood_fx_pool: Array[Dictionary] = []
var bloodmist_fx_pool: Array[Dictionary] = []
var explosion_fx_cursor: int = 0
var hit_blood_fx_cursor: int = 0
var bloodmist_fx_cursor: int = 0

var explosion_decals: Array[Decal] = []
var blood_decals: Array[Decal] = []
var explosion_decal_cursor: int = 0
var blood_decal_cursor: int = 0

var blast_light_pool: Array[Dictionary] = []
var blast_light_cursor: int = 0

var blast_center_pool: Array[Node3D] = []
var blast_arm_pool: Array[Node3D] = []
var active_blast_visuals: Dictionary = {} # Vector2i -> { "node": Node3D, "is_center": bool, "timer": float }
var ambient_motes: Array[Dictionary] = []
var mote_time: float = 0.0
var _kept_blasts: Array = []
var _expired_cells: Array[Vector2i] = []

var last_explosion_sfx_ms: int = 0


func clear() -> void:
	explosion_fx_pool.clear()
	hit_blood_fx_pool.clear()
	bloodmist_fx_pool.clear()
	explosion_fx_cursor = 0
	hit_blood_fx_cursor = 0
	bloodmist_fx_cursor = 0
	explosion_decals.clear()
	blood_decals.clear()
	explosion_decal_cursor = 0
	blood_decal_cursor = 0
	blast_light_pool.clear()
	blast_light_cursor = 0
	blast_center_pool.clear()
	blast_arm_pool.clear()
	active_blast_visuals.clear()
	ambient_motes.clear()
	mote_time = 0.0
	_kept_blasts.clear()
	_expired_cells.clear()


func _collect_particles_recursive(node: Node, out: Array[Node], trim_smoke: bool) -> void:
	if node is GPUParticles3D:
		var gp: GPUParticles3D = node
		gp.emitting = false
		if trim_smoke and (gp.name == "Upsmoke" or gp.name == "CircleSmoke"):
			gp.amount = maxi(4, int(gp.amount / 2))
		out.append(gp)
	elif node is CPUParticles3D:
		var cp: CPUParticles3D = node
		cp.emitting = false
		out.append(cp)
	for child in node.get_children():
		_collect_particles_recursive(child, out, trim_smoke)


func _build_fx_pool(fx_root: Node3D, scene: PackedScene, count: int, trim_smoke: bool) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if scene == null or fx_root == null:
		return pool
	for _i in range(count):
		var inst = scene.instantiate()
		if inst is Node3D:
			var n3: Node3D = inst
			if n3.get_script() != null:
				n3.set_script(null)
			var emitters: Array[Node] = []
			_collect_particles_recursive(n3, emitters, trim_smoke)
			n3.position = Vector3(0.0, -50.0, 0.0)
			n3.visible = false
			fx_root.add_child(n3)
			pool.append({"node": n3, "emitters": emitters, "timer": 0.0})
		elif inst is Node:
			(inst as Node).queue_free()
	return pool


func init_pools(stage: Node3D) -> void:
	var fx_root: Node3D = stage._fx_root
	var blast_root: Node3D = stage._blast_root
	var cfg = stage.C
	var meshes = stage.M
	if fx_root == null or blast_root == null or meshes == null or cfg == null:
		return

	for _i in range(POOL_BLAST_CENTER_CELLS):
		var cn: Node3D = meshes.build_blast_cell(cfg.TILE_SIZE, true, false)
		cn.position = Vector3(0.0, -50.0, 0.0)
		cn.visible = false
		blast_root.add_child(cn)
		blast_center_pool.append(cn)
	for _i in range(POOL_BLAST_ARM_CELLS):
		var an: Node3D = meshes.build_blast_cell(cfg.TILE_SIZE, false, false)
		an.position = Vector3(0.0, -50.0, 0.0)
		an.visible = false
		blast_root.add_child(an)
		blast_arm_pool.append(an)

	if bool(stage._is_self_test):
		return

	explosion_fx_pool = _build_fx_pool(fx_root, stage._fx_explosion_scene, POOL_EXPLOSION_FX, true)
	hit_blood_fx_pool = _build_fx_pool(fx_root, stage._fx_hit_blood_scene, POOL_HIT_BLOOD_FX, false)
	bloodmist_fx_pool = _build_fx_pool(fx_root, stage._fx_bloodmist_scene, POOL_BLOODMIST_FX, false)

	var mark_tex: Texture2D = stage._explosion_mark_tex
	for _i in range(POOL_EXPLOSION_DECALS):
		var dec := Decal.new()
		dec.size = Vector3(cfg.TILE_SIZE * 2.10, 0.50, cfg.TILE_SIZE * 2.10)
		if mark_tex != null:
			dec.texture_albedo = mark_tex
		dec.modulate = Color(0.14, 0.11, 0.10, 0.94)
		dec.upper_fade = 0.35
		dec.lower_fade = 0.35
		dec.position = Vector3(0.0, -50.0, 0.0)
		dec.visible = false
		fx_root.add_child(dec)
		explosion_decals.append(dec)

	var btex1: Texture2D = stage._blood_tex_01
	var btex2: Texture2D = stage._blood_tex_02
	if btex1 != null or btex2 != null:
		for i in range(POOL_BLOOD_DECALS):
			var dec := Decal.new()
			dec.size = Vector3(1.15, 0.35, 1.15)
			dec.texture_albedo = btex2 if (i % 2 == 1 and btex2 != null) else (btex1 if btex1 != null else btex2)
			dec.position = Vector3(0.0, -50.0, 0.0)
			dec.visible = false
			fx_root.add_child(dec)
			blood_decals.append(dec)

	for _i in range(POOL_BLAST_LIGHTS):
		var flash := OmniLight3D.new()
		flash.light_color = Color(1.0, 0.55, 0.20)
		flash.light_energy = 0.0
		flash.omni_range = cfg.TILE_SIZE * 3.2
		flash.position = Vector3(0.0, -50.0, 0.0)
		flash.visible = false
		fx_root.add_child(flash)
		blast_light_pool.append({"light": flash, "timer": 0.0})

	# Pre-allocate subtle drifting warehouse dust motes across overhead light pools (zero runtime alloc).
	var mote_mesh := QuadMesh.new()
	mote_mesh.size = Vector2(0.075, 0.075)
	var mote_mat := StandardMaterial3D.new()
	mote_mat.albedo_color = Color(1.0, 0.84, 0.56, 0.34)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(1.0, 0.78, 0.42)
	mote_mat.emission_energy_multiplier = 1.25
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for m_i in range(AMBIENT_MOTE_COUNT):
		var mmi := MeshInstance3D.new()
		mmi.mesh = mote_mesh
		mmi.material_override = mote_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var bx: float = -7.6 + float(m_i % 4) * 5.0 + sin(float(m_i) * 2.1) * 1.1
		var by: float = 1.20 + float(m_i % 3) * 0.90
		var bz: float = -5.2 + float(m_i / 4) * 3.1 + cos(float(m_i) * 1.7) * 0.6
		var base_pos := Vector3(bx, by, bz)
		mmi.position = base_pos
		fx_root.add_child(mmi)
		ambient_motes.append({
			"node": mmi,
			"base": base_pos,
			"phase": float(m_i) * 0.83,
			"sx": 0.35 + float(m_i % 3) * 0.14,
			"sy": 0.52 + float(m_i % 4) * 0.11,
			"sz": 0.31 + float(m_i % 5) * 0.09,
			"scale": 0.72 + float(m_i % 4) * 0.16,
		})

	# Warm up shaders & GPU particle pipelines in camera frustum during intro so first real blast has zero hitch.
	if str(stage._screenshot_path).is_empty() and stage.is_inside_tree():
		var warm_pos := Vector3(0.0, 0.2, 0.0)
		for pool in [explosion_fx_pool, hit_blood_fx_pool, bloodmist_fx_pool]:
			if not pool.is_empty():
				trigger_fx_entry(pool[0], warm_pos, 0.01, 0.08)
		if not blast_center_pool.is_empty():
			var wc: Node3D = blast_center_pool[0]
			wc.position = warm_pos
			wc.scale = Vector3(0.01, 0.01, 0.01)
			wc.visible = true
		if not explosion_decals.is_empty():
			var wd: Decal = explosion_decals[0]
			wd.position = warm_pos
			wd.size = Vector3(0.05, 0.05, 0.05)
			wd.visible = true
		if not blast_light_pool.is_empty():
			var wl: OmniLight3D = blast_light_pool[0]["light"]
			wl.position = warm_pos
			wl.light_energy = 0.05
			wl.visible = true
			blast_light_pool[0]["timer"] = 0.08
		stage.get_tree().create_timer(0.08).timeout.connect(func():
			if not blast_center_pool.is_empty() and is_instance_valid(blast_center_pool[0]):
				blast_center_pool[0].visible = false
				blast_center_pool[0].scale = Vector3.ONE
				blast_center_pool[0].position = Vector3(0.0, -50.0, 0.0)
			if not explosion_decals.is_empty() and is_instance_valid(explosion_decals[0]):
				explosion_decals[0].visible = false
				explosion_decals[0].position = Vector3(0.0, -50.0, 0.0)
		)


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


func step_fx_pools(stage: Node3D, delta: float) -> void:
	mote_time += delta
	for m_raw in ambient_motes:
		var md: Dictionary = m_raw
		var mn: MeshInstance3D = md["node"]
		if mn == null or not is_instance_valid(mn):
			continue
		var base_p: Vector3 = md["base"]
		var ph: float = float(md["phase"])
		var ox: float = sin(mote_time * float(md["sx"]) + ph) * 0.65
		var oy: float = sin(mote_time * float(md["sy"]) + ph * 1.7) * 0.32
		var oz: float = cos(mote_time * float(md["sz"]) + ph * 0.9) * 0.55
		mn.position = Vector3(base_p.x + ox, base_p.y + oy, base_p.z + oz)
		var ms: float = float(md["scale"]) * (0.78 + 0.22 * sin(mote_time * 1.9 + ph))
		mn.scale = Vector3(ms, ms, ms)

	for pool in [explosion_fx_pool, hit_blood_fx_pool, bloodmist_fx_pool]:
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
	var blast_dur: float = maxf(0.05, float(stage.C.BLAST_DURATION_SEC))
	for entry in blast_light_pool:
		var rem: float = float(entry["timer"])
		if rem > 0.0:
			rem -= delta
			entry["timer"] = rem
			var fl: OmniLight3D = entry["light"]
			if is_instance_valid(fl):
				if rem <= 0.0:
					fl.light_energy = 0.0
					fl.visible = false
				else:
					fl.light_energy = 4.5 * clampf(rem / blast_dur, 0.0, 1.0)


func trigger_blast_light(stage: Node3D, world_pos: Vector3) -> void:
	if bool(stage._is_self_test) or blast_light_pool.is_empty():
		return
	var entry: Dictionary = blast_light_pool[blast_light_cursor % blast_light_pool.size()]
	blast_light_cursor += 1
	var fl: OmniLight3D = entry["light"]
	if is_instance_valid(fl):
		fl.position = Vector3(world_pos.x, 0.65, world_pos.z)
		fl.light_energy = 4.5
		fl.visible = true
		entry["timer"] = float(stage.C.BLAST_DURATION_SEC)


func spawn_vanilla_fx(stage: Node3D, scene: PackedScene, world_pos: Vector3, scale_val: float, lifetime: float) -> void:
	if bool(stage._is_self_test) or scene == null:
		return
	if scene == stage._fx_explosion_scene and not explosion_fx_pool.is_empty():
		var entry: Dictionary = explosion_fx_pool[explosion_fx_cursor % explosion_fx_pool.size()]
		explosion_fx_cursor += 1
		trigger_fx_entry(entry, world_pos, scale_val, lifetime)
	elif scene == stage._fx_hit_blood_scene and not hit_blood_fx_pool.is_empty():
		var entry: Dictionary = hit_blood_fx_pool[hit_blood_fx_cursor % hit_blood_fx_pool.size()]
		hit_blood_fx_cursor += 1
		trigger_fx_entry(entry, world_pos, scale_val, lifetime)
	elif scene == stage._fx_bloodmist_scene and not bloodmist_fx_pool.is_empty():
		var entry: Dictionary = bloodmist_fx_pool[bloodmist_fx_cursor % bloodmist_fx_pool.size()]
		bloodmist_fx_cursor += 1
		trigger_fx_entry(entry, world_pos, scale_val, lifetime)


func spawn_explosion_mark(stage: Node3D, world_pos: Vector3, size_val: float) -> void:
	if bool(stage._is_self_test) or explosion_decals.is_empty():
		return
	var dec: Decal = explosion_decals[explosion_decal_cursor % explosion_decals.size()]
	explosion_decal_cursor += 1
	if is_instance_valid(dec) and dec.texture_albedo != null:
		dec.size = Vector3(size_val, 0.45, size_val)
		dec.position = Vector3(world_pos.x, 0.04, world_pos.z)
		dec.rotation_degrees.y = (stage._rng as RandomNumberGenerator).randf_range(0.0, 360.0)
		dec.visible = true


func spawn_blood_decal(stage: Node3D, world_pos: Vector3) -> void:
	if bool(stage._is_self_test) or blood_decals.is_empty():
		return
	var dec: Decal = blood_decals[blood_decal_cursor % blood_decals.size()]
	blood_decal_cursor += 1
	if is_instance_valid(dec):
		dec.size = Vector3(1.15, 0.35, 1.15)
		dec.position = Vector3(world_pos.x, 0.04, world_pos.z)
		dec.rotation_degrees.y = (stage._rng as RandomNumberGenerator).randf_range(0.0, 360.0)
		dec.visible = true


func spawn_blast_visual(stage: Node3D, cells: Array, owner_id: int) -> void:
	var cfg = stage.C
	var map_w: int = int(stage._map_width)
	var map_h: int = int(stage._map_height)
	var blast_dur: float = float(cfg.BLAST_DURATION_SEC)
	for i in range(cells.size()):
		var c: Vector2i = cells[i]
		var wpos: Vector3 = cfg.grid_to_world(c, map_w, map_h)
		var is_center: bool = (i == 0)
		if active_blast_visuals.has(c):
			var existing: Dictionary = active_blast_visuals[c]
			existing["timer"] = maxf(float(existing["timer"]), blast_dur)
		else:
			var pool: Array[Node3D] = blast_center_pool if is_center else blast_arm_pool
			if not pool.is_empty():
				var n: Node3D = pool.pop_back()
				if is_instance_valid(n):
					n.position = wpos
					n.scale = Vector3.ONE
					n.visible = true
					active_blast_visuals[c] = {
						"node": n,
						"is_center": is_center,
						"timer": blast_dur,
					}
		if is_center:
			spawn_vanilla_fx(stage, stage._fx_explosion_scene, Vector3(wpos.x, 0.25, wpos.z), 0.22, 1.8)
			spawn_explosion_mark(stage, wpos, float(cfg.TILE_SIZE) * 2.10)
			trigger_blast_light(stage, wpos)

	var sfx_exp: AudioStreamPlayer = stage._sfx_explosion
	if sfx_exp != null and str(stage._screenshot_path).is_empty():
		var now_ms: int = Time.get_ticks_msec()
		if now_ms - last_explosion_sfx_ms >= EXPLOSION_SFX_MIN_INTERVAL_MS:
			last_explosion_sfx_ms = now_ms
			sfx_exp.play()

	(stage._blasts as Array).append({
		"cells": cells,
		"owner_id": owner_id,
		"timer": blast_dur,
	})


func step_blasts(stage: Node3D, delta: float) -> void:
	var cfg = stage.C
	var map_w: int = int(stage._map_width)
	var map_h: int = int(stage._map_height)
	var players: Dictionary = stage._players
	var blasts: Array = stage._blasts
	_kept_blasts.clear()
	for b_raw in blasts:
		var b: Dictionary = b_raw
		b["timer"] = float(b["timer"]) - delta
		var cells: Array = b["cells"]
		var owner_id: int = int(b["owner_id"])

		if bool(stage._is_server_sim):
			for net_id in players.keys():
				var p: Dictionary = players[net_id]
				if not bool(p["alive"]):
					continue
				var p_cell: Vector2i = cfg.world_to_grid(p["pos"], map_w, map_h)
				if cells.has(p_cell):
					stage._hit_player_by_blast(p, owner_id)

		if float(b["timer"]) > 0.0:
			_kept_blasts.append(b)
	blasts.clear()
	for kb in _kept_blasts:
		blasts.append(kb)

	_expired_cells.clear()
	for cell_key in active_blast_visuals.keys():
		var entry: Dictionary = active_blast_visuals[cell_key]
		entry["timer"] = float(entry["timer"]) - delta
		if float(entry["timer"]) <= 0.0:
			_expired_cells.append(cell_key)
	for c in _expired_cells:
		var entry: Dictionary = active_blast_visuals[c]
		active_blast_visuals.erase(c)
		var n: Node3D = entry["node"]
		if is_instance_valid(n):
			n.visible = false
			n.position = Vector3(0.0, -50.0, 0.0)
			if bool(entry["is_center"]):
				blast_center_pool.append(n)
			else:
				blast_arm_pool.append(n)
