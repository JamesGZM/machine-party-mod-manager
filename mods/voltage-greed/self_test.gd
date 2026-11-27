extends RefCounted

## Deterministic headless --self-test and screenshot staging for Voltage Greed.


func _fail(stage: Node3D, msg: String) -> void:
	push_error("VOLTAGE_GREED_SELF_TEST_FAIL: " + msg)
	stage.get_tree().quit(1)


func _expect(stage: Node3D, cond: bool, msg: String) -> bool:
	if not cond:
		_fail(stage, msg)
		return false
	return true


func stage_screenshot_action(stage: Node3D) -> void:
	stage.stage_screenshot_scene(stage._cli_use_teams)
	if stage._hud != null:
		stage._hud.set_countdown("", false)


func run_self_tests(stage: Node3D) -> void:
	stage._load_helpers()
	var cfg = stage.C

	# ------------------------------------------------------------------
	# 1. Seat & Camera Layout across 2-8P
	# ------------------------------------------------------------------
	for count in range(2, 9):
		var seats: Array = cfg.compute_seat_layout(count) as Array
		if not _expect(stage, seats.size() == count, "Seat layout size mismatch for %dP" % count):
			return
		var has_back_row: bool = false
		for i in range(count):
			var si: Dictionary = seats[i] as Dictionary
			var pi: Vector3 = si["pos"] as Vector3
			var row_i: int = int(si["row"])
			var yaw_i: float = float(si["yaw"])
			if not _expect(stage, absf(yaw_i) < 0.45, "%dP seat %d must face forward (+Z toward camera)" % [count, i]):
				return
			if count <= 4:
				if not _expect(stage, row_i == 0 and is_zero_approx(pi.y), "%dP must use single front row at y=0" % count):
					return
			else:
				if row_i == 1:
					has_back_row = true
					if not _expect(stage, is_equal_approx(pi.y, 0.92), "%dP back row must be elevated at y=0.92" % count):
						return
			for j in range(i + 1, count):
				var sj: Dictionary = seats[j] as Dictionary
				var pj: Vector3 = sj["pos"] as Vector3
				if not _expect(stage, pi.distance_to(pj) > 0.8, "Seats %d and %d overlap in %dP layout" % [i, j, count]):
					return
		if count >= 5 and not _expect(stage, has_back_row, "%dP must include back riser row" % count):
			return

	var cam4: Dictionary = cfg.camera_pose_for_count(4) as Dictionary
	var cam8: Dictionary = cfg.camera_pose_for_count(8) as Dictionary
	if not _expect(stage, is_zero_approx((cam4["pos"] as Vector3).x) and is_zero_approx((cam8["pos"] as Vector3).x), "4P and 8P cameras must be dead-center symmetrical (x=0)"):
		return
	if not _expect(stage, (cam8["pos"] as Vector3).z > (cam4["pos"] as Vector3).z and float(cam8["fov"]) >= float(cam4["fov"]), "8P camera must pull back/widen vs 4P close-up"):
		return

	# ------------------------------------------------------------------
	# 2. Hold / Bail KPI, Accelerating Curve, Re-engage Lockout & Live-Only S Kick
	# ------------------------------------------------------------------
	var roster4 := [
		{"id": 0, "network_id": 1, "nickname": "P1", "team_id": 0, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "P2", "team_id": 0, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "P3", "team_id": 0, "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "P4", "team_id": 0, "is_ai": false, "customization": []},
	]
	stage.setup_headless_match(roster4, false, 20261127, false)
	stage.begin_round_for_test(0, 95.0, int(cfg.EVENT_NONE), 999.0)

	# Kick fails if not holding
	if not _expect(stage, not stage.trigger_player_kick(1), "S kick must fail while player is not holding lever"):
		return

	# Hold P1 & P2 and compare accelerating KPI gain at low vs high voltage
	if not _expect(stage, stage.set_player_holding(1, true) and stage.set_player_holding(2, true), "Holding lever must succeed in PH_LIVE"):
		return
	for _f in range(30):
		stage.step_simulation(1.0 / 60.0)
	var kpi_low_end: float = float(stage.get_player_state(1).get("round_kpi", 0.0))
	if not _expect(stage, kpi_low_end > 2.0, "Holding must farm positive round_kpi"):
		return

	# Raise public voltage to ~65% and measure 0.5s gain -> accelerating curve must yield more than low voltage
	stage._public_voltage = 65.0
	var kpi_before_high: float = float(stage.get_player_state(1).get("round_kpi", 0.0))
	for _f in range(30):
		stage.step_simulation(1.0 / 60.0)
	var kpi_high_gain: float = float(stage.get_player_state(1).get("round_kpi", 0.0)) - kpi_before_high
	if not _expect(stage, kpi_high_gain > kpi_low_end * 1.4, "Higher voltage must accelerate KPI curve (low=%.2f, high=%.2f)" % [kpi_low_end, kpi_high_gain]):
		return

	# Live-only S kick: +12% voltage, 1.8s surge, 1 charge per round
	var v_before_kick: float = stage._public_voltage
	if not _expect(stage, stage.trigger_player_kick(1), "Live player holding Space must be able to trigger S kick"):
		return
	if not _expect(stage, is_equal_approx(stage._public_voltage, v_before_kick + float(cfg.KICK_VOLTAGE_DELTA)), "S kick must add +12% voltage"):
		return
	var p1_after_kick: Dictionary = stage.get_player_state(1)
	if not _expect(stage, is_equal_approx(float(p1_after_kick["surge_timer"]), float(cfg.KICK_SURGE_DURATION)) and bool(p1_after_kick["kick_used"]), "S kick must grant 1.8s surge and consume round charge"):
		return
	if not _expect(stage, not stage.trigger_player_kick(1), "S kick must be limited to 1 charge per round"):
		return

	# Bail P2 -> locks score, blocks re-engage, AND locks out S kick permanently for round
	if not _expect(stage, stage.set_player_holding(2, false), "Releasing lever must bail P2"):
		return
	var p2_bailed: Dictionary = stage.get_player_state(2)
	if not _expect(stage, bool(p2_bailed["bailed"]) and not bool(p2_bailed["holding"]) and int(p2_bailed["round_banked"]) > 0 and int(p2_bailed["total_kpi"]) == int(p2_bailed["round_banked"]), "Bail must lock round_kpi into round_banked & total_kpi"):
		return
	if not _expect(stage, not stage.set_player_holding(2, true), "Bailed player must not be able to re-engage lever in same round"):
		return
	if not _expect(stage, not stage.trigger_player_kick(2), "Bailed player must be locked out of S kick"):
		return

	# ------------------------------------------------------------------
	# 3. 1st Overload Fry vs 2nd Elimination & S-Kick Self-Detonation + Early Victory
	# ------------------------------------------------------------------
	var roster2 := [
		{"id": 0, "network_id": 1, "nickname": "A", "team_id": 0, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "B", "team_id": 0, "is_ai": false, "customization": []},
	]
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(0, 75.0, int(cfg.EVENT_NONE), 999.0)
	stage.set_player_holding(1, true)
	stage.set_player_holding(2, true)
	for _f in range(30):
		stage.step_simulation(1.0 / 60.0)
	# P2 bails safely with banked KPI; P1 stays live and gets caught by S-kick overload
	stage.set_player_holding(2, false)
	var p2_safe_banked: int = int(stage.get_player_state(2)["total_kpi"])
	stage._public_voltage = 66.0
	stage.trigger_player_kick(1) # 66 + 12 = 78 >= 75 -> detonates!
	if not _expect(stage, int(stage._phase) == stage.PH_INTER_ROUND and bool(stage._detonated), "S kick crossing hidden threshold must detonate immediately"):
		return
	var p1_fry1: Dictionary = stage.get_player_state(1)
	if not _expect(stage, int(p1_fry1["lives"]) == 1 and bool(p1_fry1["alive"]) and bool(p1_fry1["charred"]) and int(p1_fry1["total_kpi"]) == 0, "1st fry must drop lives 2->1, char player, wipe unbanked KPI, keep alive"):
		return
	var p2_after_fry1: Dictionary = stage.get_player_state(2)
	if not _expect(stage, int(p2_after_fry1["lives"]) == 2 and int(p2_after_fry1["total_kpi"]) == p2_safe_banked, "Bailed player must remain unharmed with banked KPI"):
		return

	# Advance past inter-round into Round 2 (1.25x) and fry P1 a second time -> permanent elimination & early victory!
	while int(stage._phase) == stage.PH_INTER_ROUND:
		stage.step_simulation(0.1)
	if not _expect(stage, int(stage._phase) == stage.PH_LIVE and int(stage._round_idx) == 1, "Must advance to Round 2 after inter-round"):
		return
	stage.set_hidden_threshold(72.0)
	stage.set_player_holding(1, true)
	stage.set_player_holding(2, false) # P2 hasn't held yet, keep safe
	stage._public_voltage = 72.5
	stage.step_simulation(1.0 / 60.0)
	var p1_fry2: Dictionary = stage.get_player_state(1)
	if not _expect(stage, int(p1_fry2["lives"]) == 0 and not bool(p1_fry2["alive"]), "2nd fry must permanently eliminate player (lives=0, alive=false)"):
		return
	while int(stage._phase) == stage.PH_INTER_ROUND:
		stage.step_simulation(0.1)
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and bool(stage._early_victory), "<=1 survivor after Round 2 must trigger early victory without Round 3"):
		return

	# ------------------------------------------------------------------
	# 4. Factory Monitor Anti-Slacker Penalty (-50% on lowest earner / earliest bail tie-break)
	# ------------------------------------------------------------------
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(0, 95.0, int(cfg.EVENT_NONE), 999.0)
	stage.set_player_holding(1, true)
	stage.set_player_holding(2, true)
	for _f in range(30):
		stage.step_simulation(1.0 / 60.0)
	stage.set_player_holding(1, false)
	var p1_pre_slacker: int = int(stage.get_player_state(1)["round_banked"])
	for _f in range(45):
		stage.step_simulation(1.0 / 60.0)
	stage.set_player_holding(2, false) # All living bailed safely -> triggers Slacker Callout on P1!
	stage.step_simulation(1.0 / 60.0)
	if not _expect(stage, int(stage._phase) == stage.PH_INTER_ROUND and int(stage._slacker_nid) == 1, "All-bail safe end must call out lowest-KPI P1 as slacker"):
		return
	var p1_post_slacker: int = int(stage.get_player_state(1)["round_banked"])
	var expected_after_slacker: int = p1_pre_slacker - int(roundf(float(p1_pre_slacker) * float(cfg.SLACKER_PENALTY_RATIO)))
	if not _expect(stage, p1_post_slacker == expected_after_slacker and int(stage.get_player_state(1)["total_kpi"]) == expected_after_slacker, "Slacker callout must halve P1 round score"):
		return

	# Tie-break: if both bail with 0 KPI, earliest bail_time is penalized
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(0, 95.0, int(cfg.EVENT_NONE), 999.0)
	stage.set_player_holding(2, true)
	stage.set_player_holding(2, false) # P2 bails first at t=0.0
	for _f in range(5):
		stage.step_simulation(1.0 / 60.0)
	stage.set_player_holding(1, true)
	stage.set_player_holding(1, false) # P1 bails later
	stage.step_simulation(1.0 / 60.0)
	if not _expect(stage, int(stage._slacker_nid) == 2, "Slacker tie-break must punish earliest bail_time"):
		return

	# ------------------------------------------------------------------
	# 5. Three Round Multipliers (1.0x / 1.25x / 1.5x) & 3 Factory Monitor Industrial Events
	# ------------------------------------------------------------------
	var round_kpis: Array = []
	for r_idx in range(3):
		stage.setup_headless_match(roster2, false, 20261127, false)
		stage.begin_round_for_test(r_idx, 95.0, int(cfg.EVENT_NONE), 999.0)
		stage.set_player_holding(1, true)
		stage._public_voltage = 50.0
		stage.step_simulation(0.05) # fixed single step at 50%
		round_kpis.append(float(stage.get_player_state(1)["round_kpi"]))
	if not _expect(stage, float(round_kpis[1]) > float(round_kpis[0]) * 1.15 and float(round_kpis[2]) > float(round_kpis[1]) * 1.12, "Rounds 1/2/3 must scale by 1.0x / 1.25x / 1.5x"):
		return

	# False Alarm: pauses public voltage rise
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(1, 95.0, int(cfg.EVENT_FALSE_ALARM), 0.1)
	stage.set_player_holding(1, true)
	for _f in range(12):
		stage.step_simulation(1.0 / 60.0)
	if not _expect(stage, int(stage._event_id) == int(cfg.EVENT_FALSE_ALARM), "False Alarm must trigger at scheduled time"):
		return
	var v_fa_start: float = stage._public_voltage
	for _f in range(20):
		stage.step_simulation(1.0 / 60.0)
	if not _expect(stage, is_equal_approx(stage._public_voltage, v_fa_start), "False Alarm must pause true transformer voltage rise"):
		return

	# Glitching Meter: scrambles _display_voltage while _public_voltage keeps rising
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(1, 95.0, int(cfg.EVENT_GLITCH_METER), 0.05)
	stage.set_player_holding(1, true)
	for _f in range(10):
		stage.step_simulation(1.0 / 60.0)
	var v_gm_start: float = stage._public_voltage
	for _f in range(20):
		stage.step_simulation(1.0 / 60.0)
	if not _expect(stage, int(stage._event_id) == int(cfg.EVENT_GLITCH_METER) and stage._public_voltage > v_gm_start + 1.0, "Glitching Meter must keep rising true voltage underneath"):
		return

	# Double Overtime: 2.0x KPI rate
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(2, 95.0, int(cfg.EVENT_DOUBLE_OVERTIME), 0.0)
	stage.set_player_holding(1, true)
	stage.step_simulation(0.05)
	var kpi_double: float = float(stage.get_player_state(1)["round_kpi"])
	stage.setup_headless_match(roster2, false, 20261127, false)
	stage.begin_round_for_test(2, 95.0, int(cfg.EVENT_NONE), 999.0)
	stage.set_player_holding(1, true)
	stage.step_simulation(0.05)
	var kpi_normal: float = float(stage.get_player_state(1)["round_kpi"])
	if not _expect(stage, is_equal_approx(kpi_double, kpi_normal * float(cfg.DOUBLE_OVERTIME_MULT)), "Double Overtime must apply exact 2.0x KPI rate"):
		return

	# ------------------------------------------------------------------
	# 6. Team-Party: Parallel +20%, Solo +10%, and Kamikaze Sabotage
	# ------------------------------------------------------------------
	var roster_team_asym := [
		{"id": 0, "network_id": 1, "nickname": "R1", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "R2", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "B1", "team_id": 2, "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "B2", "team_id": 2, "is_ai": false, "customization": []},
		{"id": 4, "network_id": 5, "nickname": "G1", "team_id": 3, "is_ai": false, "customization": []},
	]
	stage.setup_headless_match(roster_team_asym, false, 20261127, false)
	stage.begin_round_for_test(0, 98.0, int(cfg.EVENT_NONE), 999.0)
	# Team 1: 2 holding (parallel +20%); Team 2: 1 holding of 2 alive (1.0x); Team 3: 1-player solo team (+10%)
	stage.set_player_holding(1, true)
	stage.set_player_holding(2, true)
	stage.set_player_holding(3, true)
	stage.set_player_holding(5, true)
	stage.step_simulation(0.05)
	var k_parallel: float = float(stage.get_player_state(1)["round_kpi"])
	var k_base: float = float(stage.get_player_state(3)["round_kpi"])
	var k_solo: float = float(stage.get_player_state(5)["round_kpi"])
	if not _expect(stage, is_equal_approx(k_parallel, k_base * float(cfg.TEAM_PARALLEL_MULT)), "Team parallel >=2 holders must earn +20% KPI"):
		return
	if not _expect(stage, is_equal_approx(k_solo, k_base * float(cfg.SOLO_TEAM_MULT)), "Solo team (1 living member) must earn +10% compensation"):
		return

	# Kamikaze AI scenario: R1 already banked a lead, R2 is live with 2 lives, B1 is live >= 68% -> R2 must choose S kick!
	var ai_cls = stage._ai_ctrl
	var ai_state_kamikaze := {
		"players": {
			1: {"network_id": 1, "team_id": 1, "alive": true, "holding": false, "bailed": true, "has_held": true, "lives": 2, "total_kpi": 420, "kick_used": false},
			2: {"network_id": 2, "team_id": 1, "alive": true, "holding": true, "bailed": false, "has_held": true, "lives": 2, "total_kpi": 80, "kick_used": false},
			3: {"network_id": 3, "team_id": 2, "alive": true, "holding": true, "bailed": false, "has_held": true, "lives": 2, "total_kpi": 200, "kick_used": false},
		},
		"public_voltage": 71.0,
		"round_elapsed": 5.0,
		"event_id": int(cfg.EVENT_NONE),
		"round_idx": 1,
		"team_active": true,
	}
	ai_cls.reset_match(ai_state_kamikaze["players"] as Dictionary, 777)
	ai_cls.reset_round(1, ai_state_kamikaze["players"] as Dictionary, 777)
	var dec_kamikaze: Dictionary = ai_cls.compute_bot_decision(2, ai_state_kamikaze, cfg) as Dictionary
	if not _expect(stage, bool(dec_kamikaze.get("kick", false)), "Kamikaze teammate with banked lead and live enemy >=68% must trigger S kick"):
		return

	# Snapshot security check: network _build_snapshot() must NEVER leak _hidden_threshold
	var net_snap: Dictionary = stage._build_snapshot()
	if not _expect(stage, not net_snap.has("hidden_threshold") and net_snap.has("dv") and net_snap.has("pl"), "Network snapshot must never expose hidden_threshold"):
		return

	# ------------------------------------------------------------------
	# 7. Full 3-Round AI Stress Simulations (4P FFA & 8P 4-Team)
	# ------------------------------------------------------------------
	stage.setup_headless_match(roster4, true, 20261127, false)
	for _frame in range(4200):
		stage.step_simulation(1.0 / 30.0)
		if int(stage._phase) == stage.PH_ENDED:
			break
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and stage._final_scores.size() == 4, "4P FFA full 3-round AI simulation must reach PH_ENDED"):
		return

	var roster8t := [
		{"id": 0, "network_id": 1, "nickname": "R1", "team_id": 1, "is_ai": true, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "R2", "team_id": 1, "is_ai": true, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "B1", "team_id": 2, "is_ai": true, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "B2", "team_id": 2, "is_ai": true, "customization": []},
		{"id": 4, "network_id": 5, "nickname": "G1", "team_id": 3, "is_ai": true, "customization": []},
		{"id": 5, "network_id": 6, "nickname": "G2", "team_id": 3, "is_ai": true, "customization": []},
		{"id": 6, "network_id": 7, "nickname": "Y1", "team_id": 4, "is_ai": true, "customization": []},
		{"id": 7, "network_id": 8, "nickname": "Y2", "team_id": 4, "is_ai": true, "customization": []},
	]
	stage.setup_headless_match(roster8t, true, 20261128, false)
	for _frame in range(4200):
		stage.step_simulation(1.0 / 30.0)
		if int(stage._phase) == stage.PH_ENDED:
			break
	if not _expect(stage, int(stage._phase) == stage.PH_ENDED and stage._final_scores.size() == 8, "8P 4-Team full 3-round AI simulation must reach PH_ENDED"):
		return
	if not _expect(stage, int(stage._final_scores[1]) == int(stage._final_scores[2]) and int(stage._final_scores[3]) == int(stage._final_scores[4]), "Team-party final scores must be synchronized per squad"):
		return

	print("SELF_TEST_PASSED (4p_ffa_scores=%s, 8p_team_scores=%s)" % [str(roster4.size()), str(stage._final_scores)])
	stage.get_tree().quit(0)
