extends RefCounted

## Gameplay, arena geometry, and balance constants for Core Heist (能源搶奪戰).

const PREP_DURATION := 3.0
const MATCH_DURATION := 75.0
const PHASE2_START := 45.0
const PHASE3_START := 60.0
const SECOND_CORE_TIME := 62.0
const CORE_WARN_DURATION := 2.0

const BATTERY_POOL_SIZE := 32

const CELL_STANDARD := 1
const CELL_GOLD := 2
const CELL_CORE := 3

const BAT_LOOSE := 0
const BAT_CARRIED := 1
const BAT_DEPOSITED := 2
const BAT_THROWN := 3

const SPEED_STANDARD := 1.0
const SPEED_GOLD := 0.88
const SPEED_CORE_SOLO := 0.55
const SPEED_CORE_RESONANCE := 1.15
const SPEED_CORE_SOLO_TEAM := 0.85

const RESONANCE_RADIUS := 2.6
const VAULT_RADIUS := 2.35
const VAULT_LOCK_DURATION := 3.0

const SHOVE_RANGE := 2.1
const SHOVE_COS_HALF := 0.35
const SHOVE_COOLDOWN := 0.90
const STUN_DURATION := 0.45
const SHOVE_IMPULSE := 8.5

const THROW_DISTANCE := 2.5
const THROW_DURATION := 0.32
const THROW_ARC_HEIGHT := 1.35

const OVERDRIVE_STEAL_BONUS := 1

const PICKUP_RADIUS := 1.15
const PLAYER_RADIUS := 0.48
const BASE_MOVE_SPEED := 6.6
const DISPENSER_RADIUS := 1.55
const PILLAR_RADIUS := 1.05
const CONVEYOR_HALF_Z := 1.25
const CONVEYOR_START_X := 1.65
const CONVEYOR_END_X := 5.65
const CONVEYOR_SPEED := 2.35

const SPAWN_INTERVAL_P1 := 2.6
const SPAWN_INTERVAL_P3 := 1.3
const MAX_LOOSE_STANDARD := 10
const MAX_LOOSE_GOLD := 3


static func max_loose_standard(team_count: int, player_count: int) -> int:
	return clampi(MAX_LOOSE_STANDARD + maxi(0, team_count - 2) * 2 + maxi(0, player_count - 4), MAX_LOOSE_STANDARD, 18)


static func max_loose_gold(team_count: int, player_count: int) -> int:
	return clampi(MAX_LOOSE_GOLD + maxi(0, team_count - 2) + (1 if player_count >= 7 else 0), MAX_LOOSE_GOLD, 6)


static func spawn_interval(is_overdrive: bool, player_count: int) -> float:
	var base: float = SPAWN_INTERVAL_P3 if is_overdrive else SPAWN_INTERVAL_P1
	var scale_t: float = clampf(float(player_count - 4) / 4.0, 0.0, 1.0)
	return base * lerpf(1.0, 0.68, scale_t)

const SNAPSHOT_INTERVAL := 0.05

const TEAM_COLORS := {
	1: Color(1.0, 0.30, 0.28, 1.0),
	2: Color(0.26, 0.68, 1.0, 1.0),
	3: Color(0.28, 0.92, 0.48, 1.0),
	4: Color(1.0, 0.84, 0.24, 1.0),
}


static func arena_size_for_teams(team_count: int) -> float:
	return 24.0 if team_count <= 2 else 28.0


static func arena_half_for_teams(team_count: int) -> float:
	return arena_size_for_teams(team_count) * 0.5


static func base_positions_for_teams(team_count: int) -> Array:
	var n: int = clampi(team_count, 2, 4)
	if n == 2:
		return [
			Vector2(-8.2, 8.2),
			Vector2(8.2, -8.2),
		]
	if n == 3:
		var r: float = 10.2
		return [
			Vector2(0.0, -r),
			Vector2(r * cos(deg_to_rad(30.0)), r * sin(deg_to_rad(30.0))),
			Vector2(-r * cos(deg_to_rad(30.0)), r * sin(deg_to_rad(30.0))),
		]
	return [
		Vector2(-9.5, 9.5),
		Vector2(9.5, -9.5),
		Vector2(-9.5, -9.5),
		Vector2(9.5, 9.5),
	]


static func pillar_positions(arena_size: float) -> Array:
	var d: float = arena_size * 0.21
	return [
		Vector2(-d, -d),
		Vector2(d, -d),
		Vector2(-d, d),
		Vector2(d, d),
	]


static func battery_points(cell_type: int) -> int:
	match cell_type:
		CELL_STANDARD:
			return 1
		CELL_GOLD:
			return 3
		CELL_CORE:
			return 5
		_:
			return 0


static func battery_speed_mult(cell_type: int, has_resonance: bool, is_solo_team: bool) -> float:
	match cell_type:
		CELL_STANDARD:
			return SPEED_STANDARD
		CELL_GOLD:
			return SPEED_GOLD
		CELL_CORE:
			if has_resonance:
				return SPEED_CORE_RESONANCE
			if is_solo_team:
				return SPEED_CORE_SOLO_TEAM
			return SPEED_CORE_SOLO
		_:
			return 1.0


static func conveyor_velocity_at(pos2: Vector2) -> Vector2:
	if absf(pos2.y) <= CONVEYOR_HALF_Z:
		if pos2.x >= CONVEYOR_START_X and pos2.x <= CONVEYOR_END_X:
			return Vector2(CONVEYOR_SPEED, 0.0)
		if pos2.x <= -CONVEYOR_START_X and pos2.x >= -CONVEYOR_END_X:
			return Vector2(-CONVEYOR_SPEED, 0.0)
	return Vector2.ZERO


static func resolve_arena_obstacles(pos2: Vector2, radius: float, arena_half: float, pillars: Array) -> Vector2:
	var p: Vector2 = pos2
	# Central reactor dispenser
	var min_disp: float = DISPENSER_RADIUS + radius
	var d_disp: float = p.length()
	if d_disp < min_disp:
		if d_disp > 0.001:
			p = p.normalized() * min_disp
		else:
			p = Vector2(0.0, min_disp)

	# 4 buffer pillars
	var min_pil: float = PILLAR_RADIUS + radius
	for raw_pil in pillars:
		var pil: Vector2 = raw_pil as Vector2
		var diff: Vector2 = p - pil
		var dist: float = diff.length()
		if dist < min_pil:
			if dist > 0.001:
				p = pil + diff.normalized() * min_pil
			else:
				p = pil + Vector2(min_pil, 0.0)

	# Guardrail bounds
	var limit: float = arena_half - radius - 0.35
	p.x = clampf(p.x, -limit, limit)
	p.y = clampf(p.y, -limit, limit)
	return p
