extends RefCounted

## Gameplay, arena geometry, and balance constants for Bomb Cart (炸彈推車).

const PREP_DURATION := 3.0
const MATCH_DURATION := 75.0
const PHASE2_START := 40.0
const PHASE3_START := 60.0
const OVERTIME_DURATION := 10.0

const ARENA_HALF_X := 13.0
const ARENA_HALF_Z := 8.0
const TRACK_HALF_LEN := 11.5
const TIE_DEADZONE_X := 0.15
const OVERTIME_WIN_X := 0.6

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
}


static func pillar_positions() -> Array:
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
	# Diminishing returns beyond +2 so 4v4 stays a tug-of-war instead of an instant slide
	if mag <= 2.0:
		return net_adv
	return sign_v * (2.0 + (mag - 2.0) * 0.35)


static func resolve_arena_obstacles(pos2: Vector2, radius: float, cart_x: float) -> Vector2:
	var p: Vector2 = pos2

	# Bomb Cart solid box collision (outer steel bumper)
	var hx: float = CART_HALF_X + radius
	var hz: float = CART_HALF_Z + radius
	var dx: float = p.x - cart_x
	var dz: float = p.y
	if absf(dx) < hx and absf(dz) < hz:
		var pen_x: float = hx - absf(dx)
		var pen_z: float = hz - absf(dz)
		if pen_x < pen_z:
			p.x = cart_x + (hx if dx >= 0.0 else -hx)
		else:
			p.y = hz if dz >= 0.0 else -hz

	# 4 symmetric bumper pillars
	var min_pil: float = PILLAR_RADIUS + radius
	for raw_pil in pillar_positions():
		var pil: Vector2 = raw_pil as Vector2
		var diff: Vector2 = p - pil
		var dist: float = diff.length()
		if dist < min_pil:
			if dist > 0.001:
				p = pil + diff.normalized() * min_pil
			else:
				p = pil + Vector2(min_pil, 0.0)

	# Guardrail bounds
	var limit_x: float = ARENA_HALF_X - radius - 0.35
	var limit_z: float = ARENA_HALF_Z - radius - 0.35
	p.x = clampf(p.x, -limit_x, limit_x)
	p.y = clampf(p.y, -limit_z, limit_z)
	return p
