extends RefCounted

## Shared gameplay constants, mid-round event IDs, 2-8+P seating geometry,
## adaptive close-up camera framing, and color helpers for Voltage Greed (電刑貪婪).

const TOTAL_ROUNDS := 3
const START_LIVES := 2
const PREP_DURATION := 3.0
const ROUND_DURATION := 16.0
const INTER_ROUND_DURATION := 2.6
const ROUND_MULTIPLIERS := [1.0, 1.25, 1.5]

const THRESHOLD_MIN := 70.0
const THRESHOLD_MAX := 100.0
const KICK_VOLTAGE_DELTA := 12.0
const KICK_SURGE_DURATION := 1.8
const KICK_SURGE_MULT := 1.35

const TEAM_PARALLEL_MULT := 1.20
const SOLO_TEAM_MULT := 1.10
const SLACKER_PENALTY_RATIO := 0.50

const DOUBLE_OVERTIME_MULT := 2.0
const FALSE_ALARM_DURATION := 1.2
const GLITCH_METER_DURATION := 1.5
const DOUBLE_OVERTIME_DURATION := 2.5

const EVENT_NONE := 0
const EVENT_FALSE_ALARM := 1
const EVENT_GLITCH_METER := 2
const EVENT_DOUBLE_OVERTIME := 3

const SNAPSHOT_INTERVAL := 0.05
const BASE_KPI_RATE := 18.0
const STAGE_FOCUS := Vector3(0.0, 0.0, -5.2)

const TEAM_COLORS := {
	1: Color(1.0, 0.30, 0.28, 1.0),
	2: Color(0.26, 0.68, 1.0, 1.0),
	3: Color(0.28, 0.92, 0.48, 1.0),
	4: Color(1.0, 0.84, 0.24, 1.0),
}

const FALLBACK_PLAYER_COLORS := [
	Color(0.95, 0.32, 0.26, 1.0),
	Color(0.24, 0.66, 0.98, 1.0),
	Color(0.28, 0.90, 0.46, 1.0),
	Color(0.98, 0.80, 0.22, 1.0),
	Color(0.96, 0.52, 0.18, 1.0),
	Color(0.22, 0.88, 0.86, 1.0),
	Color(0.84, 0.38, 0.96, 1.0),
	Color(0.76, 0.92, 0.28, 1.0),
]


static func _make_seat(pos: Vector3, row: int) -> Dictionary:
	var dx: float = STAGE_FOCUS.x - pos.x
	var dz: float = STAGE_FOCUS.z - pos.z
	return {
		"pos": pos,
		"yaw": atan2(dx, dz),
		"row": row,
	}


static func compute_seat_layout(player_count: int) -> Array:
	var count: int = maxi(1, player_count)
	var seats: Array = []
	if count <= 4:
		var radius: float = 5.4
		var span: float = 0.0
		if count == 2:
			span = 0.42
		elif count == 3:
			span = 0.72
		elif count == 4:
			span = 0.96
		for i in range(count):
			var t: float = 0.0 if count == 1 else (float(i) / float(count - 1) - 0.5)
			var ang: float = t * span
			var pos := Vector3(sin(ang) * radius, 0.0, STAGE_FOCUS.z + cos(ang) * radius)
			seats.append(_make_seat(pos, 0))
		return seats

	# 5-8+P: staggered two-tier semi-circular lab riser with back row elevated y=0.85
	var front_count: int = ceili(float(count) * 0.5)
	var back_count: int = count - front_count
	var r_front: float = 5.6
	var r_back: float = 7.6
	var span_front: float = minf(1.22, 0.32 * float(maxi(1, front_count - 1)))
	var span_back: float = minf(1.38, span_front + 0.28)

	for i in range(front_count):
		var tf: float = 0.0 if front_count == 1 else (float(i) / float(front_count - 1) - 0.5)
		var ang_f: float = tf * span_front
		var pos_f := Vector3(sin(ang_f) * r_front, 0.0, STAGE_FOCUS.z + cos(ang_f) * r_front)
		seats.append(_make_seat(pos_f, 0))

	for j in range(back_count):
		var tb: float = 0.0 if back_count == 1 else (float(j) / float(back_count - 1) - 0.5)
		var ang_b: float = tb * span_back
		if back_count == front_count and back_count % 2 == 1 and absf(ang_b) < 0.001:
			ang_b += 0.14
		var pos_b := Vector3(sin(ang_b) * r_back, 0.85, STAGE_FOCUS.z + cos(ang_b) * r_back)
		seats.append(_make_seat(pos_b, 1))

	return seats


static func camera_pose_for_count(player_count: int) -> Dictionary:
	if player_count <= 4:
		return {
			"pos": Vector3(2.8, 4.4, 4.8),
			"look_at": Vector3(-0.15, 1.35, -2.5),
			"fov": 44.0,
		}
	return {
		"pos": Vector3(3.6, 5.8, 7.2),
		"look_at": Vector3(-0.2, 1.35, -1.8),
		"fov": 48.0,
	}


static func team_color(team_id: int) -> Color:
	return TEAM_COLORS.get(team_id, Color.WHITE) as Color


static func player_fallback_color(slot_index: int) -> Color:
	var idx: int = posmod(slot_index, FALLBACK_PLAYER_COLORS.size())
	return FALLBACK_PLAYER_COLORS[idx] as Color
