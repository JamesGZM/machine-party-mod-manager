extends RefCounted

## 3-role tactical AI controller for Bomb Cart (2-4 teams):
## 1. Valve Flanker: sprint to an active Steam Valve unless cart is threatening own Blast Door.
## 2. Cart Pusher / Rammer: defend own arm or drive cart down an intact rival arm from rear side,
##    Power Ram with Space, and retreat > 3.6m during final 0.45s of Phase 2/3 shockwave telegraph.
## 3. Brawler / Blocker: intercept and shove enemies contesting the Push Aura or valves.


static func _to_vec2(raw_pos) -> Vector2:
	if raw_pos is Vector3:
		var v3: Vector3 = raw_pos as Vector3
		return Vector2(v3.x, v3.z)
	if raw_pos is Vector2:
		return raw_pos as Vector2
	return Vector2.ZERO


static func _steer_around_obstacles(
	pos2: Vector2,
	target2: Vector2,
	cart2: Vector2,
	cfg,
	avoid_cart: bool,
	team_count: int = 2
) -> Vector2:
	var to_t: Vector2 = target2 - pos2
	var dist: float = to_t.length()
	if dist < 0.05:
		return Vector2.ZERO
	var dir: Vector2 = to_t / dist

	var pillar_r: float = float(cfg.PILLAR_RADIUS)
	var pillars: Array = cfg.pillar_positions(team_count)
	for raw_pil in pillars:
		var pil: Vector2 = raw_pil as Vector2
		var away: Vector2 = pos2 - pil
		if away.length() < pillar_r + 1.05 and away.dot(dir) < 0.0:
			var perp := Vector2(-away.y, away.x)
			if perp.length_squared() < 0.0001:
				perp = Vector2(0.0, 1.0)
			else:
				perp = perp.normalized()
			if perp.dot(dir) < 0.0:
				perp = -perp
			dir = (dir + perp * 1.25).normalized()

	if avoid_cart:
		var away_cart: Vector2 = pos2 - cart2
		if away_cart.length() < float(cfg.CART_RADIUS) + 0.95 and away_cart.dot(dir) < 0.0:
			var perp_c := Vector2(-away_cart.y, away_cart.x)
			if perp_c.length_squared() < 0.0001:
				perp_c = Vector2(0.0, 1.0)
			else:
				perp_c = perp_c.normalized()
			if perp_c.dot(dir) < 0.0:
				perp_c = -perp_c
			dir = (dir + perp_c * 1.35).normalized()

	return dir


static func _apply_personal_space(move_dir: Vector2, pos2: Vector2, bot_id: int, players: Dictionary) -> Vector2:
	if move_dir.length_squared() < 0.0001:
		return move_dir
	var repulse := Vector2.ZERO
	for raw_oid in players.keys():
		var oid: int = int(raw_oid)
		if oid == bot_id:
			continue
		var other: Dictionary = players[raw_oid] as Dictionary
		if not bool(other.get("alive", true)):
			continue
		var op2: Vector2 = _to_vec2(other.get("pos", Vector2.ZERO))
		var diff: Vector2 = pos2 - op2
		var d: float = diff.length()
		if d < 1.25:
			var push_away: Vector2 = diff / d if d > 0.01 else Vector2(0.0, 1.0 if (bot_id % 2 == 0) else -1.0)
			repulse += push_away * ((1.25 - d) / 1.25) * 1.15
	if repulse.length_squared() > 0.0001:
		return (move_dir + repulse).normalized()
	return move_dir


static func _pick_push_dir_multi(
	my_team: int,
	pos2: Vector2,
	cart2: Vector2,
	branch_team: int,
	branch_dist: float,
	door_dirs: Dictionary,
	door_alive: Dictionary,
	active_teams: Array
) -> Vector2:
	var own_dir: Vector2 = door_dirs.get(my_team, Vector2(-1.0, 0.0)) as Vector2
	# If cart is on our own arm, urgently push back toward central hub (-own_dir)
	if branch_team == my_team and branch_dist > 0.45:
		return -own_dir
	# If cart is already on an intact rival arm, push straight down that rival arm
	if branch_team > 0 and branch_team != my_team and bool(door_alive.get(branch_team, true)) and branch_dist > 0.45:
		return door_dirs.get(branch_team, -own_dir) as Vector2
	# Otherwise at hub: choose intact rival arm most aligned with (-own_dir) and away from us
	var best_dir := -own_dir
	var best_score: float = -999.0
	var from_me: Vector2 = (cart2 - pos2).normalized() if cart2.distance_squared_to(pos2) > 0.01 else -own_dir
	for raw_tid in active_teams:
		var tid: int = int(raw_tid)
		if tid == my_team or not bool(door_alive.get(tid, true)):
			continue
		var d: Vector2 = door_dirs.get(tid, Vector2.RIGHT) as Vector2
		var sc: float = d.dot(-own_dir) * 0.65 + d.dot(from_me) * 0.35
		if sc > best_score:
			best_score = sc
			best_dir = d
	return best_dir.normalized() if best_dir.length_squared() > 0.001 else Vector2(1.0, 0.0)


static func compute_bot_input(bot_id: int, state: Dictionary, cfg) -> Dictionary:
	var players: Dictionary = state.get("players", {}) as Dictionary
	if not players.has(bot_id):
		return {"move": Vector2.ZERO, "action": false}

	var me: Dictionary = players[bot_id] as Dictionary
	if not bool(me.get("alive", true)) or float(me.get("stun", 0.0)) > 0.0:
		return {"move": Vector2.ZERO, "action": false}

	var my_team: int = int(me.get("team_id", 1))
	var pos2: Vector2 = _to_vec2(me.get("pos", Vector2.ZERO))
	var action_cd: float = float(me.get("action_cd", 0.0))

	var active_teams: Array = state.get("active_team_ids", [1, 2]) as Array
	if active_teams.size() < 2:
		active_teams = [1, 2]
	var team_count: int = active_teams.size()
	var is_multi: bool = team_count >= 3

	var cart_x: float = float(state.get("cart_x", 0.0))
	var cart2: Vector2 = _to_vec2(state.get("cart_pos", Vector2(cart_x, 0.0)))
	var track_len: float = float(cfg.track_length(team_count))
	var half_sz: Vector2 = cfg.arena_half_size(team_count)

	var door_dirs: Dictionary = state.get("door_dirs", {}) as Dictionary
	if door_dirs.is_empty():
		door_dirs = cfg.door_directions(active_teams)
	var door_alive: Dictionary = state.get("door_alive", {}) as Dictionary
	var branch_team: int = int(state.get("cart_branch_team", 0))
	var branch_dist: float = float(state.get("cart_branch_dist", absf(cart_x)))

	var own_door_dir: Vector2 = door_dirs.get(my_team, Vector2(-1.0, 0.0) if my_team == int(active_teams[0]) else Vector2(1.0, 0.0)) as Vector2
	var own_door_pos: Vector2 = own_door_dir * track_len
	var dist_to_own_door: float = cart2.distance_to(own_door_pos)

	var push_vec: Vector2 = -own_door_dir
	if is_multi:
		push_vec = _pick_push_dir_multi(my_team, pos2, cart2, branch_team, branch_dist, door_dirs, door_alive, active_teams)

	# Role 2b (highest survival priority): Retreat > 3.6m in final 0.45s of shockwave telegraph
	var pulse_active: bool = bool(state.get("pulse_active", false))
	var pulse_remaining: float = float(state.get("pulse_remaining", 99.0))
	if pulse_active and pulse_remaining <= 0.45:
		var away_from_cart: Vector2 = pos2 - cart2
		var d_cart: float = away_from_cart.length()
		if d_cart < 3.6:
			var escape_dir: Vector2 = away_from_cart.normalized() if d_cart > 0.05 else (-push_vec + Vector2(-push_vec.y, push_vec.x) * 0.4).normalized()
			var retreat_target: Vector2 = cart2 + escape_dir * 4.2
			retreat_target.x = clampf(retreat_target.x, -half_sz.x + 0.8, half_sz.x - 0.8)
			retreat_target.y = clampf(retreat_target.y, -half_sz.y + 0.8, half_sz.y - 0.8)
			return {
				"move": _apply_personal_space(_steer_around_obstacles(pos2, retreat_target, cart2, cfg, false, team_count), pos2, bot_id, players),
				"action": false,
			}

	# Role 3 (immediate): Shove enemy already within shove range
	var shove_range: float = float(cfg.SHOVE_RANGE)
	var nearest_enemy_dist: float = 999.0
	var nearest_enemy_pos := Vector2.ZERO
	var contesting_enemy_dist: float = 999.0
	var contesting_enemy_pos := Vector2.ZERO

	for raw_other in players.values():
		var other: Dictionary = raw_other as Dictionary
		if not bool(other.get("alive", true)):
			continue
		if int(other.get("team_id", 0)) == my_team:
			continue
		var op2: Vector2 = _to_vec2(other.get("pos", Vector2.ZERO))
		var d_me: float = pos2.distance_to(op2)
		if d_me < nearest_enemy_dist:
			nearest_enemy_dist = d_me
			nearest_enemy_pos = op2
		if op2.distance_to(cart2) <= float(cfg.PUSH_AURA_RADIUS) + 0.55 and d_me < contesting_enemy_dist:
			contesting_enemy_dist = d_me
			contesting_enemy_pos = op2

	if nearest_enemy_dist <= shove_range * 0.92:
		var to_enemy: Vector2 = (nearest_enemy_pos - pos2).normalized() if nearest_enemy_dist > 0.05 else push_vec
		return {
			"move": to_enemy,
			"action": action_cd <= 0.0,
		}

	# Role 1: Valve Flanker — sprint to active valve unless cart is dangerously close to own door
	var valves: Array = state.get("valves", []) as Array
	var flanker_assignments: Dictionary = state.get("flanker_assignments", {}) as Dictionary
	var assigned_flanker: int = int(flanker_assignments.get(my_team, -1))
	var is_flanker: bool = (assigned_flanker == bot_id)
	var emergency_dist: float = 3.6 if is_multi else 3.0

	if dist_to_own_door >= emergency_dist and not valves.is_empty():
		var best_valve_dist: float = 999.0
		var best_valve_pos := Vector2.ZERO
		var found_active_valve: bool = false
		for raw_v in valves:
			var v: Dictionary = raw_v as Dictionary
			if not bool(v.get("active", false)):
				continue
			var vp2: Vector2 = _to_vec2(v.get("pos", Vector2.ZERO))
			var dv: float = pos2.distance_to(vp2)
			if dv < best_valve_dist:
				best_valve_dist = dv
				best_valve_pos = vp2
				found_active_valve = true

		if found_active_valve and (is_flanker or best_valve_dist < 4.5):
			var valve_dir: Vector2 = _apply_personal_space(_steer_around_obstacles(pos2, best_valve_pos, cart2, cfg, true, team_count), pos2, bot_id, players)
			var slam_valve: bool = best_valve_dist <= float(cfg.VALVE_RADIUS) * 0.9 and action_cd <= 0.0
			return {
				"move": valve_dir,
				"action": slam_valve,
			}

	# Role 3b: Brawler / Blocker — intercept contesting enemy near cart when closer than pushing spot
	var teammate_ids: Array = []
	for raw_oid in players.keys():
		var oid: int = int(raw_oid)
		var other: Dictionary = players[raw_oid] as Dictionary
		if bool(other.get("alive", true)) and int(other.get("team_id", 0)) == my_team:
			teammate_ids.append(oid)
	teammate_ids.sort()
	var lane_idx: int = maxi(0, teammate_ids.find(bot_id))
	var lane_offsets: Array = [0.0, -1.30, 1.30, -2.0, 2.0]
	var lane_perp_amt: float = float(lane_offsets[lane_idx % lane_offsets.size()])
	var perp_vec := Vector2(-push_vec.y, push_vec.x)
	var rear_target: Vector2 = cart2 - push_vec * 1.90 + perp_vec * lane_perp_amt
	rear_target.x = clampf(rear_target.x, -half_sz.x + 0.9, half_sz.x - 0.9)
	rear_target.y = clampf(rear_target.y, -half_sz.y + 0.9, half_sz.y - 0.9)

	if contesting_enemy_dist < 4.2 and not is_flanker and pos2.distance_to(rear_target) > 1.8:
		var intercept_dir: Vector2 = _apply_personal_space(_steer_around_obstacles(pos2, contesting_enemy_pos, cart2, cfg, false, team_count), pos2, bot_id, players)
		return {
			"move": intercept_dir,
			"action": false,
		}

	# Role 2: Cart Pusher / Rammer — push from rear side along push_vec, Power Ram when in range
	var d_to_cart: float = pos2.distance_to(cart2)
	var d_to_rear: float = pos2.distance_to(rear_target)
	if d_to_cart <= float(cfg.RAM_RANGE) * 0.95 and d_to_rear <= 1.35 and action_cd <= 0.0:
		var ram_dir: Vector2 = _apply_personal_space((cart2 - pos2).normalized() if d_to_cart > 0.05 else push_vec, pos2, bot_id, players)
		return {
			"move": ram_dir,
			"action": true,
		}

	var avoid_cart_flag: bool = (pos2 - cart2).dot(push_vec) > 0.25
	return {
		"move": _apply_personal_space(_steer_around_obstacles(pos2, rear_target, cart2, cfg, avoid_cart_flag, team_count), pos2, bot_id, players),
		"action": false,
	}
