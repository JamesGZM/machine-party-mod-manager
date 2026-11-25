extends RefCounted

## 3-role tactical AI controller for Bomb Cart:
## 1. Valve Flanker: sprint to an active Steam Valve unless cart is < 3.0m from own Blast Door.
## 2. Cart Pusher / Rammer: push from friendly rear side, Power Ram with Space,
##    and retreat > 3.4m during the final 0.45s of a Phase 2/3 shockwave telegraph.
## 3. Brawler / Blocker: intercept and shove enemies contesting the Push Aura or valves.


static func _to_vec2(raw_pos) -> Vector2:
	if raw_pos is Vector3:
		var v3: Vector3 = raw_pos as Vector3
		return Vector2(v3.x, v3.z)
	if raw_pos is Vector2:
		return raw_pos as Vector2
	return Vector2.ZERO


static func _steer_around_obstacles(pos2: Vector2, target2: Vector2, cart_x: float, cfg, avoid_cart: bool) -> Vector2:
	var to_t: Vector2 = target2 - pos2
	var dist: float = to_t.length()
	if dist < 0.05:
		return Vector2.ZERO
	var dir: Vector2 = to_t / dist

	var pillar_r: float = float(cfg.PILLAR_RADIUS)
	var pillars: Array = cfg.pillar_positions()
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
		var cart2 := Vector2(cart_x, 0.0)
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
	var cart_x: float = float(state.get("cart_x", 0.0))
	var cart2 := Vector2(cart_x, 0.0)
	var track_half: float = float(cfg.TRACK_HALF_LEN)

	# Team 1 (Red) defends West (-track_half) and pushes +X; Team 2 (Blue) defends East (+track_half) and pushes -X.
	var push_dir: float = 1.0 if my_team == 1 else -1.0
	var own_door_x: float = -push_dir * track_half
	var dist_to_own_door: float = absf(cart_x - own_door_x)

	# Role 2b (highest survival priority): Retreat > 3.4m in final 0.45s of shockwave telegraph
	var pulse_active: bool = bool(state.get("pulse_active", false))
	var pulse_remaining: float = float(state.get("pulse_remaining", 99.0))
	if pulse_active and pulse_remaining <= 0.45:
		var away_from_cart: Vector2 = pos2 - cart2
		var d_cart: float = away_from_cart.length()
		if d_cart < 3.6:
			var escape_dir: Vector2 = away_from_cart.normalized() if d_cart > 0.05 else Vector2(-push_dir, 0.5).normalized()
			var retreat_target: Vector2 = cart2 + escape_dir * 4.2
			retreat_target.x = clampf(retreat_target.x, -float(cfg.ARENA_HALF_X) + 0.8, float(cfg.ARENA_HALF_X) - 0.8)
			retreat_target.y = clampf(retreat_target.y, -float(cfg.ARENA_HALF_Z) + 0.8, float(cfg.ARENA_HALF_Z) - 0.8)
			return {
				"move": _apply_personal_space(_steer_around_obstacles(pos2, retreat_target, cart_x, cfg, false), pos2, bot_id, players),
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
		var to_enemy: Vector2 = (nearest_enemy_pos - pos2).normalized() if nearest_enemy_dist > 0.05 else Vector2(push_dir, 0.0)
		return {
			"move": to_enemy,
			"action": action_cd <= 0.0,
		}

	# Role 1: Valve Flanker — sprint to active valve unless cart < 3.0m from own door
	var valves: Array = state.get("valves", []) as Array
	var flanker_assignments: Dictionary = state.get("flanker_assignments", {}) as Dictionary
	var assigned_flanker: int = int(flanker_assignments.get(my_team, -1))
	var is_flanker: bool = (assigned_flanker == bot_id)

	if dist_to_own_door >= 3.0 and not valves.is_empty():
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
			var valve_dir: Vector2 = _apply_personal_space(_steer_around_obstacles(pos2, best_valve_pos, cart_x, cfg, true), pos2, bot_id, players)
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
	var lane_offsets: Array = [0.0, -1.35, 1.35, -2.1, 2.1]
	var lane_z: float = float(lane_offsets[lane_idx % lane_offsets.size()])
	var rear_x: float = clampf(cart_x - push_dir * 1.95, -track_half + 0.6, track_half - 0.6)
	var rear_target := Vector2(rear_x, lane_z)
	if contesting_enemy_dist < 4.2 and not is_flanker and pos2.distance_to(rear_target) > 1.8:
		var intercept_dir: Vector2 = _apply_personal_space(_steer_around_obstacles(pos2, contesting_enemy_pos, cart_x, cfg, false), pos2, bot_id, players)
		return {
			"move": intercept_dir,
			"action": false,
		}

	# Role 2: Cart Pusher / Rammer — push from friendly rear side, Power Ram when in range
	var d_to_cart: float = pos2.distance_to(cart2)
	var d_to_rear: float = pos2.distance_to(rear_target)
	if d_to_cart <= float(cfg.RAM_RANGE) * 0.92 and d_to_rear <= 1.25 and action_cd <= 0.0:
		var ram_dir: Vector2 = _apply_personal_space((cart2 - pos2).normalized() if d_to_cart > 0.05 else Vector2(push_dir, 0.0), pos2, bot_id, players)
		return {
			"move": ram_dir,
			"action": true,
		}

	var avoid_cart_flag: bool = (pos2.x - cart_x) * push_dir > 0.2
	return {
		"move": _apply_personal_space(_steer_around_obstacles(pos2, rear_target, cart_x, cfg, avoid_cart_flag), pos2, bot_id, players),
		"action": false,
	}
