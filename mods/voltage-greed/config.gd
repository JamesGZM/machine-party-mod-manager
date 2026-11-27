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
const STAGE_FOCUS := Vector3(0.0, 0.0, 7.0)

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
		var x_list: Array = []
		if count == 1:
			x_list = [0.0]
		elif count == 2:
			x_list = [-1.10, 1.10]
		elif count == 3:
			x_list = [-1.75, 0.0, 1.75]
		else:
			x_list = [-2.55, -0.85, 0.85, 2.55]
		var max_x: float = 2.55
		for raw_x in x_list:
			var px: float = float(raw_x)
			var norm_x: float = absf(px) / max_x
			var pz: float = -0.45 + 0.20 * (norm_x * norm_x)
			seats.append(_make_seat(Vector3(px, 0.0, pz), 0))
		return seats

	# 5-8+P: staggered two-tier interrogation bench, BOTH rows facing +Z toward camera
	var front_count: int = ceili(float(count) * 0.5)
	var back_count: int = count - front_count

	for i in range(front_count):
		var tf: float = 0.0 if front_count == 1 else (float(i) / float(front_count - 1) * 2.0 - 1.0)
		var fx: float = tf * 2.85
		var fz: float = 0.45 + 0.20 * (tf * tf)
		seats.append(_make_seat(Vector3(fx, 0.0, fz), 0))

	var back_xs: Array = []
	if back_count == 2:
		back_xs = [-1.55, 1.55]
	elif back_count == 3:
		back_xs = [-2.05, 0.0, 2.05]
	elif back_count == 4:
		back_xs = [-3.15, -1.50, 1.50, 3.15]
	else:
		for j in range(back_count):
			var tb: float = 0.0 if back_count == 1 else (float(j) / float(back_count - 1) * 2.0 - 1.0)
			back_xs.append(tb * 3.15)

	for raw_bx in back_xs:
		var bx: float = float(raw_bx)
		var norm_bx: float = clampf(absf(bx) / 3.15, 0.0, 1.0)
		var bz: float = -1.24 + 0.16 * (norm_bx * norm_bx)
		seats.append(_make_seat(Vector3(bx, 0.92, bz), 1))

	return seats


static func camera_pose_for_count(player_count: int) -> Dictionary:
	if player_count <= 4:
		return {
			"pos": Vector3(0.0, 2.75, 4.55),
			"look_at": Vector3(0.0, 1.52, -1.55),
			"fov": 44.0,
		}
	return {
		"pos": Vector3(0.0, 3.65, 5.95),
		"look_at": Vector3(0.0, 1.72, -1.45),
		"fov": 46.5,
	}


static func team_color(team_id: int) -> Color:
	return TEAM_COLORS.get(team_id, Color.WHITE) as Color


static func player_fallback_color(slot_index: int) -> Color:
	var idx: int = posmod(slot_index, FALLBACK_PLAYER_COLORS.size())
	return FALLBACK_PLAYER_COLORS[idx] as Color
