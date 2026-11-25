extends RefCounted

## Headless Tier-0 self-tests, 75s AI stress test, and screenshot staging for Bomb Cart.


func _fail(stage: Node3D, msg: String) -> void:
	push_error("BOMB_CART_SELF_TEST_FAIL: " + msg)
	stage.get_tree().quit(1)


func _expect(stage: Node3D, cond: bool, msg: String) -> bool:
	if not cond:
		_fail(stage, msg)
		return false
	return true


func stage_screenshot_action(stage: Node3D) -> void:
	var cfg = stage.C
	stage._phase = stage.PH_LIVE
	stage._match_phase = 2
	stage._prep_remaining = 0.0
	stage._elapsed_time = 46.0
	stage._time_remaining = 29.0
	stage._cart_x = 1.2
	stage._cart_vel = 2.6
	stage._cart_owner = 1
	stage._surge_team = 1
	stage._surge_timer = 1.4
	stage._pulse_active = true
	stage._pulse_remaining = 0.65

	if stage._valves.size() >= 2:
		(stage._valves[0] as Dictionary)["active"] = true
		(stage._valves[0] as Dictionary)["charge"] = 0.65
		(stage._valves[1] as Dictionary)["active"] = false

	var red_pos: Array = [
		Vector3(-1.8, 0.0, 1.4),
		Vector3(-2.4, 0.0, -1.2),
		Vector3(0.0, 0.0, -5.8),
	]
	var blue_pos: Array = [
		Vector3(3.6, 0.0, 1.4),
		Vector3(3.9, 0.0, -1.2),
		Vector3(3.5, 0.0, 4.2),
	]
	var r_idx: int = 0
	var b_idx: int = 0
	var ids: Array = stage._players.keys()
	ids.sort()
	for nid in ids:
		var p: Dictionary = stage._players[nid] as Dictionary
		var tid: int = int(p["team_id"])
		var raw3: Vector3 = red_pos[r_idx % red_pos.size()] if tid == 1 else blue_pos[b_idx % blue_pos.size()]
		if tid == 1:
			r_idx += 1
		else:
			b_idx += 1
		var resolved2: Vector2 = cfg.resolve_arena_obstacles(Vector2(raw3.x, raw3.z), float(cfg.PLAYER_RADIUS), float(stage._cart_x))
		p["pos"] = Vector3(resolved2.x, 0.0, resolved2.y)
		p["render_pos"] = p["pos"]
		p["facing"] = Vector2(1.0, 0.0) if tid == 1 else Vector2(-1.0, 0.0)
		stage._players[nid] = p

	stage._animate_visuals(0.016)


func run_self_tests(stage: Node3D) -> void:
	stage._load_helpers()
	stage._is_server_sim = true
	stage._standalone_mode = true
	var cfg = stage.C

	var roster2v2 := [
		{"id": 0, "network_id": 1, "nickname": "R1", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "R2", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "B1", "team_id": 2, "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "B2", "team_id": 2, "is_ai": false, "customization": []},
	]
	stage.setup_headless_match(roster2v2, false)
	stage._phase = stage.PH_LIVE

	# 1. Phase speed multipliers & 0-40-60-75s transitions
	if not _expect(stage, is_equal_approx(float(cfg.phase_speed_mult(1)), 1.0), "Phase 1 speed mult must be 1.0"):
		return
	if not _expect(stage, is_equal_approx(float(cfg.phase_speed_mult(2)), 1.35), "Phase 2 speed mult must be 1.35"):
		return
	if not _expect(stage, is_equal_approx(float(cfg.phase_speed_mult(3)), 1.75), "Phase 3 speed mult must be 1.75"):
		return
	if not _expect(stage, float(cfg.push_advantage_factor(4.0)) < 4.0, "Push advantage > +2 must have diminishing returns"):
		return

	stage._elapsed_time = 40.1
	stage._step_phase_events(0.016)
	if not _expect(stage, int(stage._match_phase) == 2, "Must transition to Phase 2 at 40s"):
		return

	stage._elapsed_time = 60.1
	stage._step_phase_events(0.016)
	if not _expect(stage, int(stage._match_phase) == 3, "Must transition to Phase 3 at 60s"):
		return
	if not _expect(stage, bool((stage._valves[0] as Dictionary)["active"]) and bool((stage._valves[1] as Dictionary)["active"]), "Phase 3 must activate both North and South valves"):
		return

	# Reset to clean Phase 1 state for mechanics tests
	stage.setup_headless_match(roster2v2, false)
	stage._phase = stage.PH_LIVE

	# 2. Push aura: Team 1 inside 2.6m pushes cart toward +X
	var p1: Dictionary = stage._players[1] as Dictionary
	var p2: Dictionary = stage._players[2] as Dictionary
	var p3: Dictionary = stage._players[3] as Dictionary
	var p4: Dictionary = stage._players[4] as Dictionary
	p1["pos"] = Vector3(-1.5, 0.0, 0.0)
	p2["pos"] = Vector3(-8.0, 0.0, 4.0)
	p3["pos"] = Vector3(8.0, 0.0, 4.0)
	p4["pos"] = Vector3(8.0, 0.0, -4.0)
	var x_before: float = float(stage._cart_x)
	for _f in range(15):
		stage._step_cart(1.0 / 60.0)
	if not _expect(stage, float(stage._cart_x) > x_before + 0.05, "Team 1 inside Push Aura must push cart toward +X"):
		return

	# 3. Shove vs Power Ram & zero friendly fire
	stage._cart_x = 0.0
	stage._cart_vel = 0.0
	p1["pos"] = Vector3(-5.0, 0.0, 3.0)
	p1["facing"] = Vector2(1.0, 0.0)
	p1["action_cd"] = 0.0
	p1["stun_timer"] = 0.0
	p2["pos"] = Vector3(-3.8, 0.0, 3.0) # Friendly in front cone
	p2["stun_timer"] = 0.0
	p2["knockback_vel"] = Vector2.ZERO
	p3["pos"] = Vector3(-3.6, 0.0, 3.0) # Enemy in front cone
	p3["stun_timer"] = 0.0
	p3["knockback_vel"] = Vector2.ZERO
	stage._perform_action(1)
	if not _expect(stage, is_zero_approx(float(p2["stun_timer"])) and (p2["knockback_vel"] as Vector2).length() < 0.01, "Shove must have zero friendly fire"):
		return
	if not _expect(stage, is_equal_approx(float(p3["stun_timer"]), float(cfg.STUN_DURATION)) and (p3["knockback_vel"] as Vector2).length() > 1.0, "Shove must stun & knock back enemy"):
		return

	# Power Ram when no enemy in shove range and within RAM_RANGE of cart
	p1["pos"] = Vector3(-1.5, 0.0, 0.0)
	p1["facing"] = Vector2(1.0, 0.0)
	p1["action_cd"] = 0.0
	p3["pos"] = Vector3(8.0, 0.0, 4.0)
	stage._cart_x = 0.0
	stage._cart_vel = 0.0
	stage._perform_action(1)
	if not _expect(stage, is_equal_approx(float(stage._cart_vel), float(cfg.RAM_IMPULSE)), "Power Ram must apply +RAM_IMPULSE to cart"):
		return

	# 4. Steam Valve 2.5s Rocket Surge + knockback near cart
	var north_pos: Vector2 = cfg.VALVE_POS_NORTH as Vector2
	(stage._valves[0] as Dictionary)["active"] = true
	p1["pos"] = Vector3(north_pos.x, 0.0, north_pos.y)
	p1["action_cd"] = 0.0
	p3["pos"] = Vector3(1.5, 0.0, 0.0) # Near cart within SURGE_KNOCK_RADIUS (2.8m)
	p3["stun_timer"] = 0.0
	p3["knockback_vel"] = Vector2.ZERO
	stage._perform_action(1)
	if not _expect(stage, int(stage._surge_team) == 1 and is_equal_approx(float(stage._surge_timer), float(cfg.SURGE_DURATION)), "Valve slam must trigger 2.5s Rocket Surge for Team 1"):
		return
	if not _expect(stage, (p3["knockback_vel"] as Vector2).length() > 1.0, "Steam Surge must knock back nearby enemies at cart"):
		return
	stage._surge_team = 0
	stage._surge_timer = 0.0

	# 5. Phase 2/3 shockwave knockback
	stage._cart_x = 0.0
	p1["pos"] = Vector3(2.0, 0.0, 0.0) # Inside PULSE_RADIUS (3.2m)
	p1["stun_timer"] = 0.0
	p1["knockback_vel"] = Vector2.ZERO
	p2["pos"] = Vector3(4.0, 0.0, 0.0) # Outside PULSE_RADIUS
	p2["stun_timer"] = 0.0
	p2["knockback_vel"] = Vector2.ZERO
	stage._detonate_shockwave()
	if not _expect(stage, is_equal_approx(float(p1["stun_timer"]), float(cfg.PULSE_STUN)) and (p1["knockback_vel"] as Vector2).length() > 1.0, "Shockwave must stun & knock back players within 3.2m"):
		return
	if not _expect(stage, is_zero_approx(float(p2["stun_timer"])) and (p2["knockback_vel"] as Vector2).length() < 0.01, "Shockwave must not hit players outside 3.2m"):
		return

	# 6. Blast Door KO
	stage.setup_headless_match(roster2v2, false)
	stage._phase = stage.PH_LIVE
	stage._cart_x = float(cfg.TRACK_HALF_LEN)
	stage.step_headless(1.0 / 60.0)
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and int(stage._winner_team) == 1, "Reaching +11.5m East Blast Door must award Red instant KO"):
		return

	# 7. 75s detonation
	stage.setup_headless_match(roster2v2, false)
	stage._phase = stage.PH_LIVE
	stage._cart_x = 1.2
	stage._elapsed_time = 74.99
	stage._time_remaining = 0.01
	stage.step_headless(0.02)
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and int(stage._winner_team) == 1, "75s detonation at x=+1.2 must award Red win"):
		return

	# 8. 10s Sudden Death overtime
	stage.setup_headless_match(roster2v2, false)
	stage._phase = stage.PH_LIVE
	stage._cart_x = 0.05 # Within TIE_DEADZONE_X (0.15m)
	stage._elapsed_time = 74.99
	stage._time_remaining = 0.01
	stage.step_headless(0.02)
	if not _expect(stage, int(stage._phase) == stage.PH_LIVE and bool(stage._overtime), "Tie within 0.15m at 75s must enter Sudden Death overtime"):
		return
	stage._cart_x = float(cfg.OVERTIME_WIN_X) + 0.05
	stage.step_headless(1.0 / 60.0)
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and int(stage._winner_team) == 1, "Pushing past +0.6m in Sudden Death must win immediately"):
		return

	# 9. 1v2 underdog compensation + disconnect fallback
	var roster1v2 := [
		{"id": 0, "network_id": 1, "nickname": "Solo", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "DuoA", "team_id": 2, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "DuoB", "team_id": 2, "is_ai": false, "customization": []},
	]
	if not _expect(stage, is_equal_approx(float(cfg.underdog_weight(1, 2)), 1.5), "1v2 underdog weight must be 1.5"):
		return
	stage.setup_headless_match(roster1v2, false)
	stage._phase = stage.PH_LIVE
	(stage._players[1] as Dictionary)["pos"] = Vector3(-1.0, 0.0, 0.0)
	(stage._players[2] as Dictionary)["pos"] = Vector3(1.0, 0.0, 0.0)
	(stage._players[3] as Dictionary)["pos"] = Vector3(8.0, 0.0, 4.0)
	stage._cart_x = 0.0
	stage._step_cart(1.0 / 60.0)
	if not _expect(stage, float(stage._cart_vel) > 0.0, "1v2 underdog Red player vs 1 Blue player must have net push advantage"):
		return
	stage.player_disconnected(2)
	if not _expect(stage, int(stage._phase) == stage.PH_LIVE, "Disconnecting 1 of 2 on Team 2 keeps match live"):
		return
	stage.player_disconnected(3)
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and int(stage._winner_team) == 1, "Disconnecting last Team 2 player must award Team 1 immediate win"):
		return

	# 10. AI input sanity (Flanker, Shockwave Dodge, Brawler Shove)
	var ai_cls = stage._ai_ctrl
	var ai_state_flank := {
		"players": {
			1: {"id": 1, "team_id": 1, "pos": Vector3(0.0, 0.0, -2.0), "yaw": 0.0, "stun": 0.0, "action_cd": 0.0, "alive": true},
			2: {"id": 2, "team_id": 2, "pos": Vector3(8.0, 0.0, 0.0), "yaw": 0.0, "stun": 0.0, "action_cd": 0.0, "alive": true},
		},
		"cart_x": 0.0,
		"cart_vel": 0.0,
		"valves": [{"pos": north_pos, "active": true, "charge": 0.0}],
		"pulse_active": false,
		"pulse_remaining": 0.0,
		"flanker_assignments": {1: 1},
	}
	var out_flank: Dictionary = ai_cls.compute_bot_input(1, ai_state_flank, cfg)
	if not _expect(stage, (out_flank["move"] as Vector2).y < -0.5, "Flanker AI must sprint North toward active valve"):
		return

	# Shockwave dodge (< 0.45s remaining, within 3.4m)
	var ai_state_dodge := {
		"players": {
			1: {"id": 1, "team_id": 1, "pos": Vector3(-1.5, 0.0, 0.0), "yaw": 0.0, "stun": 0.0, "action_cd": 0.0, "alive": true},
		},
		"cart_x": 0.0,
		"cart_vel": 0.0,
		"valves": [],
		"pulse_active": true,
		"pulse_remaining": 0.3,
		"flanker_assignments": {},
	}
	var out_dodge: Dictionary = ai_cls.compute_bot_input(1, ai_state_dodge, cfg)
	if not _expect(stage, (out_dodge["move"] as Vector2).x < -0.5 and not bool(out_dodge["action"]), "AI must retreat away from cart in final 0.45s of shockwave"):
		return

	# Brawler shove when enemy is within SHOVE_RANGE
	var ai_state_shove := {
		"players": {
			1: {"id": 1, "team_id": 1, "pos": Vector3(-1.5, 0.0, 0.0), "yaw": 0.0, "stun": 0.0, "action_cd": 0.0, "alive": true},
			2: {"id": 2, "team_id": 2, "pos": Vector3(-0.3, 0.0, 0.0), "yaw": 0.0, "stun": 0.0, "action_cd": 0.0, "alive": true},
		},
		"cart_x": 0.0,
		"cart_vel": 0.0,
		"valves": [],
		"pulse_active": false,
		"pulse_remaining": 0.0,
		"flanker_assignments": {},
	}
	var out_shove: Dictionary = ai_cls.compute_bot_input(1, ai_state_shove, cfg)
	if not _expect(stage, bool(out_shove["action"]), "AI must trigger shove when enemy is within shove range"):
		return

	# 11. Collision separation & cart AABB bumper regression
	stage.setup_headless_match(roster2v2, false)
	stage._phase = stage.PH_LIVE
	stage._cart_x = 0.0
	(stage._players[1] as Dictionary)["pos"] = Vector3(-3.0, 0.0, 0.0)
	(stage._players[2] as Dictionary)["pos"] = Vector3(-3.0, 0.0, 0.0)
	(stage._players[3] as Dictionary)["pos"] = Vector3(8.0, 0.0, 4.0)
	(stage._players[4] as Dictionary)["pos"] = Vector3(8.0, 0.0, -4.0)
	for _f in range(15):
		stage.set_player_input(1, Vector2(1.0, 0.0), false)
		stage.set_player_input(2, Vector2(1.0, 0.0), false)
		stage.step_headless(1.0 / 60.0)
	var sep_p1: Vector3 = (stage._players[1] as Dictionary)["pos"] as Vector3
	var sep_p2: Vector3 = (stage._players[2] as Dictionary)["pos"] as Vector3
	var sep_dist: float = Vector2(sep_p1.x, sep_p1.z).distance_to(Vector2(sep_p2.x, sep_p2.z))
	if not _expect(stage, sep_dist >= float(cfg.PLAYER_RADIUS) * 1.9, "Overlapping players must separate >= PLAYER_RADIUS * 1.9, got %.3f" % sep_dist):
		return
	for pid in [1, 2]:
		var pp3: Vector3 = (stage._players[pid] as Dictionary)["pos"] as Vector3
		var dx_cart: float = absf(pp3.x - float(stage._cart_x))
		var dz_cart: float = absf(pp3.z)
		var inside_cart: bool = dx_cart < float(cfg.CART_HALF_X) + float(cfg.PLAYER_RADIUS) * 0.85 and dz_cart < float(cfg.CART_HALF_Z) + float(cfg.PLAYER_RADIUS) * 0.85
		if not _expect(stage, not inside_cart, "Player %d must not clip inside cart bumper box" % pid):
			return

	# 12. Full 75s 2v2 AI stress simulation
	stage.setup_headless_match(roster2v2, true)
	var dt: float = 1.0 / 60.0
	for _frame in range(5400):
		stage.step_headless(dt)
		if int(stage._phase) == stage.PH_ENDED:
			break
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED, "75s 2v2 AI stress sim must reach PH_ENDED"):
		return

	print("SELF_TEST_PASSED (winner_team=%d, cart_x=%.2f, elapsed=%.1f)" % [stage._winner_team, stage._cart_x, stage._elapsed_time])
	stage.get_tree().quit(0)
