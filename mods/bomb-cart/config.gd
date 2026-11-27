extends RefCounted

## Gameplay, adaptive 2-4 team arena geometry, and balance constants for Bomb Cart (炸彈推車).

const PREP_DURATION := 3.0
const MATCH_DURATION := 75.0
const PHASE2_START := 40.0
const PHASE3_START := 60.0
const OVERTIME_DURATION := 10.0

# 2-team straight rail arena (26m x 16m)
const ARENA_HALF_X := 13.0
const ARENA_HALF_Z := 8.0
const TRACK_HALF_LEN := 11.5
const TIE_DEADZONE_X := 0.15
const OVERTIME_WIN_X := 0.6

# 3-4 team turntable radial rail arena (26m x 26m)
const ARENA_HALF_MULTI := 13.0
const TRACK_LEN_MULTI := 10.5
const HUB_RADIUS := 0.45
const OVERTIME_WIN_MULTI := 0.8
const BREACH_RESET_PAUSE := 1.2

const PUSH_AURA_RADIUS := 2.6
const CART_RADIUS := 1.15
const CART_HALF_X := 1.25
const CART_HALF_Z := 0.85
const PLAYER_RADIUS := 0.48
const BASE_MOVE_SPEED := 6.6
const BASE_PUSH_SPEED := 1.85

const SHOVE_RANGE := 2.1
const SHOVE_COS_HALF := 0.35
const ACTION_COOLDOWN := 0.95
const STUN_DURATION := 0.45
const SHOVE_IMPULSE := 8.5

const RAM_RANGE := 2.4
const RAM_IMPULSE := 3.8

const VALVE_POS_NORTH := Vector2(0.0, -6.0)
const VALVE_POS_SOUTH := Vector2(0.0, 6.0)
const VALVE_RADIUS := 1.6
const VALVE_HOLD_TIME := 0.6
const VALVE_INTERVAL_P1 := 14.0
const VALVE_INTERVAL_P3 := 10.0

const SURGE_DURATION := 2.5
const SURGE_SPEED := 4.4
const SURGE_KNOCK_RADIUS := 2.8

const PULSE_INTERVAL := 8.0
const PULSE_WARN_TIME := 1.2
const PULSE_RADIUS := 3.2
const PULSE_STUN := 0.35
const PULSE_IMPULSE := 9.0

const PILLAR_RADIUS := 1.0
const SNAPSHOT_INTERVAL := 0.05

const TEAM_COLORS := {
	1: Color(1.0, 0.30, 0.28, 1.0),
	2: Color(0.26, 0.68, 1.0, 1.0),
	3: Color(0.28, 0.92, 0.48, 1.0),
	4: Color(1.0, 0.84, 0.24, 1.0),
}


static func arena_half_size(team_count: int = 2) -> Vector2:
	if team_count >= 3:
		return Vector2(ARENA_HALF_MULTI, ARENA_HALF_MULTI)
	return Vector2(ARENA_HALF_X, ARENA_HALF_Z)


static func track_length(team_count: int = 2) -> float:
	if team_count >= 3:
		return TRACK_LEN_MULTI
	return TRACK_HALF_LEN


static func door_directions(active_team_ids: Array) -> Dictionary:
	var out: Dictionary = {}
	var count: int = active_team_ids.size()
	if count <= 2:
		if count >= 1:
			out[int(active_team_ids[0])] = Vector2(-1.0, 0.0)
		if count >= 2:
			out[int(active_team_ids[1])] = Vector2(1.0, 0.0)
		return out
	if count == 3:
		# Symmetric Y-shaped 120-degree radial rails (SW, SE, North)
		var dirs3: Array = [
			Vector2(-0.8660254, 0.5),
			Vector2(0.8660254, 0.5),
			Vector2(0.0, -1.0),
		]
		for i in range(3):
			out[int(active_team_ids[i])] = dirs3[i]
		return out
	# 4-team Cross (+) radial rails (West, East, North, South)
	var dirs4: Array = [
		Vector2(-1.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, -1.0),
		Vector2(0.0, 1.0),
	]
	for i in range(mini(count, 4)):
		out[int(active_team_ids[i])] = dirs4[i]
	return out


static func branch_yaw_from_dir(dir2: Vector2) -> float:
	if dir2.length_squared() < 0.0001:
		return 0.0
	return atan2(-dir2.y, dir2.x)


static func valve_positions_for_teams(team_count: int = 2) -> Array:
	if team_count == 3:
		# Symmetrically placed between Y branches at 90 deg (South), -30 deg (NE), -150 deg (NW)
		var r: float = 7.6
		return [
			Vector2(0.0, r),
			Vector2(r * 0.8660254, -r * 0.5),
			Vector2(-r * 0.8660254, -r * 0.5),
		]
	if team_count >= 4:
		# Symmetrically placed in the 4 diagonal flanking zones
		return [
			Vector2(-8.0, -8.0),
			Vector2(8.0, -8.0),
			Vector2(-8.0, 8.0),
			Vector2(8.0, 8.0),
		]
	return [VALVE_POS_NORTH, VALVE_POS_SOUTH]


static func pillar_positions(team_count: int = 2) -> Array:
	if team_count == 3:
		# Mid-sector buffer pillars clear of Y-rails, doors, spawns, and valves
		var r: float = 4.3
		return [
			Vector2(0.0, r),
			Vector2(r * 0.8660254, -r * 0.5),
			Vector2(-r * 0.8660254, -r * 0.5),
		]
	if team_count >= 4:
		# Mid-diagonal buffer pillars clear of Cross rails, valves, and spawns
		return [
			Vector2(-4.2, -4.2),
			Vector2(4.2, -4.2),
			Vector2(-4.2, 4.2),
			Vector2(4.2, 4.2),
		]
	return [
		Vector2(-5.5, -3.8),
		Vector2(5.5, -3.8),
		Vector2(-5.5, 3.8),
		Vector2(5.5, 3.8),
	]


static func phase_speed_mult(phase: int) -> float:
	match phase:
		1:
			return 1.0
		2:
			return 1.35
		3:
			return 1.75
		_:
			return 1.0


static func underdog_weight(my_alive: int, enemy_alive: int) -> float:
	if my_alive < enemy_alive:
		return clampf(float(enemy_alive) / float(maxi(1, my_alive)), 1.0, 1.5)
	return 1.0


static func push_advantage_factor(net_adv: float) -> float:
	var mag: float = absf(net_adv)
	if mag <= 0.001:
		return 0.0
	var sign_v: float = 1.0 if net_adv > 0.0 else -1.0
	# Diminishing returns beyond +2 so 4v4 & 2v2v2v2 stay a tug-of-war instead of an instant slide
	if mag <= 2.0:
		return net_adv
	return sign_v * (2.0 + (mag - 2.0) * 0.35)


static func resolve_arena_obstacles(
	pos2: Vector2,
	radius: float,
	cart_x_or_pos,
	cart_angle: float = 0.0,
	team_count: int = 2
) -> Vector2:
	var p: Vector2 = pos2
	var cart_pos := Vector2(float(cart_x_or_pos), 0.0) if not (cart_x_or_pos is Vector2) else (cart_x_or_pos as Vector2)

	# Bomb Cart solid oriented box collision (outer steel bumper)
	var hx: float = CART_HALF_X + radius
	var hz: float = CART_HALF_Z + radius
	var rel: Vector2 = p - cart_pos
	# In XZ plane, yaw `cart_angle` rotates local +X to (cos(a), -sin(a)) and local +Z to (sin(a), cos(a)).
	var ca: float = cos(cart_angle)
	var sa: float = sin(cart_angle)
	var lx: float = rel.x * ca - rel.y * sa
	var lz: float = rel.x * sa + rel.y * ca
	if absf(lx) < hx and absf(lz) < hz:
		var pen_x: float = hx - absf(lx)
		var pen_z: float = hz - absf(lz)
		if pen_x < pen_z:
			lx = hx if lx >= 0.0 else -hx
		else:
			lz = hz if lz >= 0.0 else -hz
		p.x = cart_pos.x + (lx * ca + lz * sa)
		p.y = cart_pos.y + (-lx * sa + lz * ca)

	# Symmetric industrial bumper pillars
	var min_pil: float = PILLAR_RADIUS + radius
	for raw_pil in pillar_positions(team_count):
		var pil: Vector2 = raw_pil as Vector2
		var diff: Vector2 = p - pil
		var dist: float = diff.length()
		if dist < min_pil:
			if dist > 0.001:
				p = pil + diff.normalized() * min_pil
			else:
				p = pil + Vector2(min_pil, 0.0)

	# Guardrail bounds
	var half_sz: Vector2 = arena_half_size(team_count)
	var limit_x: float = half_sz.x - radius - 0.35
	var limit_z: float = half_sz.y - radius - 0.35
	p.x = clampf(p.x, -limit_x, limit_x)
	p.y = clampf(p.y, -limit_z, limit_z)
	return p
