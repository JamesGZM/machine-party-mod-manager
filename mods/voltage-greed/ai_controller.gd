extends RefCounted

## Personality-driven AI controller for Voltage Greed (電刑貪婪).
## Archetypes:
## - Cautious Clerk (0): conservative 52-67% bail, panics easily on False Alarm & rival S kicks.
## - Greedy Gambler (1): greedy 72-88% bail, ignores most False Alarms, kicks when behind.
## - Chaos Saboteur (2): 62-80% bail, loves FFA S kicks (55-75%) & team kamikaze detonations.

const ARCH_CAUTIOUS := 0
const ARCH_GAMBLER := 1
const ARCH_SABOTEUR := 2

var _brains: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func reset_match(players: Dictionary, seed_val: int) -> void:
	_brains.clear()
	_rng.seed = int(seed_val) ^ 0x51A7E21
	var nids: Array = players.keys()
	nids.sort()
	for raw_nid in nids:
		var nid: int = int(raw_nid)
		var arch: int = _rng.randi_range(0, 2)
		_brains[nid] = {
			"archetype": arch,
			"bail_target": 65.0,
			"start_delay": 0.25,
			"kick_volt": 62.0,
			"panic_bail_at": -1.0,
			"false_alarm_checked": false,
			"witnessed_kick_bail_at": -1.0,
			"glitch_hesitate_until": -1.0,
			"glitch_checked": false,
		}


func reset_round(round_idx: int, players: Dictionary, seed_val: int) -> void:
	_rng.seed = int(seed_val) + round_idx * 7919
	var nids: Array = players.keys()
	nids.sort()
	for raw_nid in nids:
		var nid: int = int(raw_nid)
		if not _brains.has(nid):
			_brains[nid] = {"archetype": _rng.randi_range(0, 2)}
		var b: Dictionary = _brains[nid] as Dictionary
		var arch: int = int(b.get("archetype", ARCH_CAUTIOUS))
		var target: float = 65.0
		if arch == ARCH_CAUTIOUS:
			target = _rng.randf_range(52.0, 67.0)
		elif arch == ARCH_GAMBLER:
			target = _rng.randf_range(72.0, 88.0)
		else:
			target = _rng.randf_range(62.0, 80.0)
		b["bail_target"] = clampf(target, 52.0, 88.0)
		b["start_delay"] = _rng.randf_range(0.16, 0.58)
		b["kick_volt"] = _rng.randf_range(55.0, 75.0)
		b["panic_bail_at"] = -1.0
		b["false_alarm_checked"] = false
		b["witnessed_kick_bail_at"] = -1.0
		b["glitch_hesitate_until"] = -1.0
		b["glitch_checked"] = false


func get_archetype(nid: int) -> int:
	if not _brains.has(nid):
		return ARCH_CAUTIOUS
	return int((_brains[nid] as Dictionary).get("archetype", ARCH_CAUTIOUS))


func notify_kick_witnessed(kicker_nid: int, round_elapsed: float, players: Dictionary) -> void:
	for raw_nid in players.keys():
		var nid: int = int(raw_nid)
		if nid == kicker_nid or not _brains.has(nid):
			continue
		var p: Dictionary = players[raw_nid] as Dictionary
		if not bool(p.get("is_ai", false)) or not bool(p.get("alive", true)) or bool(p.get("bailed", false)):
			continue
		var b: Dictionary = _brains[nid] as Dictionary
		var arch: int = int(b.get("archetype", ARCH_CAUTIOUS))
		var bail_prob: float = 0.65 if arch == ARCH_CAUTIOUS else (0.20 if arch == ARCH_SABOTEUR else 0.12)
		if float(b.get("witnessed_kick_bail_at", -1.0)) < 0.0 and _rng.randf() < bail_prob:
			b["witnessed_kick_bail_at"] = round_elapsed + _rng.randf_range(0.22, 0.52)


func compute_bot_decision(nid: int, state: Dictionary, cfg) -> Dictionary:
	var players: Dictionary = state.get("players", {}) as Dictionary
	if not players.has(nid):
		return {"holding": false, "kick": false}
	var me: Dictionary = players[nid] as Dictionary
	if not bool(me.get("alive", true)) or bool(me.get("bailed", false)):
		return {"holding": false, "kick": false}

	if not _brains.has(nid):
		_brains[nid] = {
			"archetype": ARCH_CAUTIOUS,
			"bail_target": 65.0,
			"start_delay": 0.25,
			"kick_volt": 64.0,
			"panic_bail_at": -1.0,
			"false_alarm_checked": false,
			"witnessed_kick_bail_at": -1.0,
			"glitch_hesitate_until": -1.0,
			"glitch_checked": false,
		}
	var b: Dictionary = _brains[nid] as Dictionary
	var arch: int = int(b.get("archetype", ARCH_CAUTIOUS))
	var round_elapsed: float = float(state.get("round_elapsed", 0.0))
	var has_held: bool = bool(me.get("has_held", false))
	if not has_held and round_elapsed < float(b.get("start_delay", 0.25)):
		return {"holding": false, "kick": false}

	var volt: float = float(state.get("public_voltage", 0.0))
	var event_id: int = int(state.get("event_id", 0))
	var round_idx: int = int(state.get("round_idx", 0))
	var team_active: bool = bool(state.get("team_active", false))

	var ev_false: int = int(cfg.EVENT_FALSE_ALARM)
	var ev_glitch: int = int(cfg.EVENT_GLITCH_METER)
	var ev_double: int = int(cfg.EVENT_DOUBLE_OVERTIME)

	# React to False Alarm: Cautious bots frequently panic-bail.
	if event_id == ev_false:
		if not bool(b.get("false_alarm_checked", false)):
			b["false_alarm_checked"] = true
			var panic_p: float = 0.58 if arch == ARCH_CAUTIOUS else (0.30 if arch == ARCH_SABOTEUR else 0.16)
			if _rng.randf() < panic_p:
				b["panic_bail_at"] = round_elapsed + _rng.randf_range(0.18, 0.50)
	else:
		b["false_alarm_checked"] = false

	var panic_at: float = float(b.get("panic_bail_at", -1.0))
	if panic_at >= 0.0 and round_elapsed >= panic_at:
		return {"holding": false, "kick": false}

	var kick_bail_at: float = float(b.get("witnessed_kick_bail_at", -1.0))
	if kick_bail_at >= 0.0 and round_elapsed >= kick_bail_at:
		return {"holding": false, "kick": false}

	# React to Glitching Meter: brief hesitation before taking a bail/kick decision.
	if event_id == ev_glitch:
		if not bool(b.get("glitch_checked", false)):
			b["glitch_checked"] = true
			b["glitch_hesitate_until"] = round_elapsed + _rng.randf_range(0.35, 0.75)
	else:
		b["glitch_checked"] = false

	var hesitating: bool = round_elapsed < float(b.get("glitch_hesitate_until", -1.0))

	# Determine effective bail target with comeback / Double Overtime adjustments.
	var my_total: int = int(me.get("total_kpi", 0))
	var best_other_total: int = 0
	for raw_oid in players.keys():
		var oid: int = int(raw_oid)
		if oid == nid:
			continue
		var op: Dictionary = players[raw_oid] as Dictionary
		best_other_total = maxi(best_other_total, int(op.get("total_kpi", 0)))

	var target: float = float(b.get("bail_target", 65.0))
	if round_idx >= 2 and my_total < best_other_total and int(me.get("lives", 1)) >= 2:
		target = minf(88.0, target + 6.0)
	if event_id == ev_double:
		target = minf(88.0, target + 4.5)

	var want_kick: bool = false
	var is_holding: bool = bool(me.get("holding", false))
	var kick_used: bool = bool(me.get("kick_used", false))

	if is_holding and not kick_used and not hesitating:
		if team_active:
			var my_team: int = int(me.get("team_id", 0))
			var my_team_banked: int = 0
			var best_enemy_banked: int = 0
			var enemy_live_high: int = 0
			var team_totals: Dictionary = {}
			for raw_oid in players.keys():
				var op: Dictionary = players[raw_oid] as Dictionary
				var otid: int = int(op.get("team_id", 0))
				if otid <= 0:
					continue
				team_totals[otid] = int(team_totals.get(otid, 0)) + int(op.get("total_kpi", 0))
				if otid != my_team and bool(op.get("alive", true)) and bool(op.get("holding", false)) and not bool(op.get("bailed", false)):
					if volt >= 68.0:
						enemy_live_high += 1
			my_team_banked = int(team_totals.get(my_team, 0))
			for raw_tid in team_totals.keys():
				if int(raw_tid) != my_team:
					best_enemy_banked = maxi(best_enemy_banked, int(team_totals[raw_tid]))
			# Team kamikaze: teammate banked lead (or strong cushion) & enemy carries are live >= 68%
			if enemy_live_high >= 1 and my_team_banked > best_enemy_banked and int(me.get("lives", 1)) >= 2:
				want_kick = true
			elif enemy_live_high >= 1 and my_team_banked >= best_enemy_banked + 60:
				want_kick = true
		else:
			# FFA S kick: Chaos Saboteur (or behind Greedy Gambler) kicks between 55-75% when rivals are live
			var other_holding: int = 0
			for raw_oid in players.keys():
				if int(raw_oid) == nid:
					continue
				var op: Dictionary = players[raw_oid] as Dictionary
				if bool(op.get("alive", true)) and bool(op.get("holding", false)) and not bool(op.get("bailed", false)):
					other_holding += 1
			if other_holding >= 1 and volt >= float(b.get("kick_volt", 64.0)) and volt <= 76.0:
				if arch == ARCH_SABOTEUR or (arch == ARCH_GAMBLER and my_total <= best_other_total):
					want_kick = true

	if is_holding and not want_kick and not hesitating and volt >= target:
		return {"holding": false, "kick": false}

	return {"holding": true, "kick": want_kick}
