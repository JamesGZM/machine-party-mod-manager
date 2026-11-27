extends RefCounted

## Headless Tier-0 self-tests, 75s stress/smoke tests, and screenshot staging for Core Heist.


func _fail(stage: Node3D, msg: String) -> void:
	push_error("CORE_HEIST_SELF_TEST_FAIL: " + msg)
	stage.get_tree().quit(1)


func _expect(stage: Node3D, cond: bool, msg: String) -> bool:
	if not cond:
		_fail(stage, msg)
		return false
	return true


func stage_screenshot_action(stage: Node3D) -> void:
	var cfg = stage.C
	stage._phase = stage.PH_LIVE
	stage._prep_remaining = 0.0
	stage._elapsed_time = 48.0
	stage._time_remaining = 27.0
	if stage._hud != null:
		stage._hud.set_standalone_hint(false)

	var is_two_team: bool = stage._team_count <= 2
	var ids: Array = stage._players.keys()
	ids.sort()

	# Group player IDs by team so resonance always links genuine teammates.
	var by_team: Dictionary = {}
	for raw_id in ids:
		var nid: int = int(raw_id)
		var tid: int = int((stage._players[nid] as Dictionary).get("team_id", 1))
		if not by_team.has(tid):
			by_team[tid] = []
		(by_team[tid] as Array).append(nid)

	var spots_by_team: Dictionary = {}
	if is_two_team:
		# 4v4 mid-action choreography in 24m arena (clear of pylons at +/-5.04, dispenser, conveyors, and vault scoreboards)
		spots_by_team = {
			1: [
				[Vector3(-2.2, 0.0, 4.9), Vector2(-0.7, 0.7)],    # T1 Core carrier (off-center SW of reactor)
				[Vector3(0.2, 0.0, 4.5), Vector2(-0.9, 0.4)],     # T1 Core escort (resonance beam!)
				[Vector3(-3.0, 0.0, -2.5), Vector2(0.3, 0.95)],   # T1 West conveyor runner (clear of NW pylon)
				[Vector3(-8.4, 0.0, 2.2), Vector2(0.4, 0.9)],     # T1 West flank runner heading to Red vault
			],
			2: [
				[Vector3(2.9, 0.0, 3.1), Vector2(-0.9, 0.4)],     # T2 Midfield interceptor (clear of east conveyor)
				[Vector3(3.1, 0.0, -2.8), Vector2(-0.3, 0.95)],   # T2 East conveyor runner (clear of NE pylon)
				[Vector3(-0.6, 0.0, -5.6), Vector2(0.7, 0.7)],    # T2 North midfield flanker
				[Vector3(8.6, 0.0, -1.0), Vector2(-0.2, -0.98)],  # T2 East flank guard well clear of Blue vault
			],
		}
	else:
		# 2v2v2v2 mid-action choreography in 28m arena (clear of pylons at +/-5.88, dispenser, conveyors, and vault scoreboards)
		spots_by_team = {
			1: [
				[Vector3(-2.9, 0.0, 5.4), Vector2(-0.7, 0.7)],    # T1 Core carrier (cleanly off to SW of reactor)
				[Vector3(-0.5, 0.0, 4.9), Vector2(-0.85, 0.52)],  # T1 Core escort (resonance beam!)
			],
			2: [
				[Vector3(5.6, 0.0, 2.0), Vector2(-0.7, -0.7)],    # T2 Grabbing east conveyor Gold cell (clear of battery)
				[Vector3(2.6, 0.0, -5.4), Vector2(0.7, -0.7)],    # T2 North-east runner toward Blue vault
			],
			3: [
				[Vector3(-3.2, 0.0, -2.7), Vector2(0.25, 0.96)],  # T3 Grabbing west conveyor Standard cell (clear of NW pylon)
				[Vector3(-9.2, 0.0, -2.4), Vector2(0.4, -0.9)],   # T3 West flank guard well clear of Green vault
			],
			4: [
				[Vector3(2.8, 0.0, 6.4), Vector2(-0.85, -0.35)],  # T4 South midfield challenger
				[Vector3(9.4, 0.0, 4.0), Vector2(0.1, 0.99)],     # T4 East flank runner scoring toward Yellow vault
			],
		}

	for raw_tid in stage._active_team_ids:
		var tid: int = int(raw_tid)
		var members: Array = by_team.get(tid, []) as Array
		var spots: Array = spots_by_team.get(tid, []) as Array
		for m_i in range(members.size()):
			var nid: int = int(members[m_i])
			var p: Dictionary = stage._players[nid] as Dictionary
			if m_i < spots.size():
				var sp: Array = spots[m_i] as Array
				var pos3: Vector3 = sp[0] as Vector3
				p["pos"] = pos3
				p["render_pos"] = pos3
				p["facing"] = (sp[1] as Vector2).normalized()
			players_set(stage, nid, p)

	# Stage Heavy Core + live Teammate Resonance on Team 1
	var t1_members: Array = by_team.get(int(stage._active_team_ids[0]), []) as Array
	if t1_members.size() >= 2:
		var carrier_id: int = int(t1_members[0])
		var escort_id: int = int(t1_members[1])
		var cpos: Vector3 = (stage._players[carrier_id] as Dictionary)["pos"] as Vector3
		var core_idx: int = stage._spawn_battery(int(cfg.CELL_CORE), cpos + Vector3(0.0, 1.92, 0.0))
		if core_idx >= 0:
			(stage._batteries[core_idx] as Dictionary)["state"] = int(cfg.BAT_CARRIED)
			(stage._batteries[core_idx] as Dictionary)["carrier_id"] = carrier_id
			(stage._players[carrier_id] as Dictionary)["carried_battery"] = core_idx
			(stage._players[carrier_id] as Dictionary)["has_resonance"] = true
			stage._resonance_pairs = [[carrier_id, escort_id]]

	# Deposit realistic batteries into each active vault so vaults and 3D scoreboards look alive
	var deposit_patterns: Dictionary = {
		1: [int(cfg.CELL_GOLD), int(cfg.CELL_STANDARD), int(cfg.CELL_STANDARD)],
		2: [int(cfg.CELL_GOLD), int(cfg.CELL_STANDARD)],
		3: [int(cfg.CELL_STANDARD), int(cfg.CELL_STANDARD)],
		4: [int(cfg.CELL_GOLD)],
	}
	for raw_tid in stage._active_team_ids:
		var tid: int = int(raw_tid)
		var pat: Array = deposit_patterns.get(tid, [int(cfg.CELL_STANDARD)]) as Array
		for raw_ct in pat:
			var b_dep: int = stage._spawn_battery(int(raw_ct), Vector3.ZERO)
			if b_dep >= 0:
				stage._deposit_battery(b_dep, tid)
				if tid != int(stage._active_team_ids[0]):
					(stage._batteries[b_dep] as Dictionary)["lock_timer"] = 0.0
	# Clear transient deposit popups/bursts from staging so vault scoreboards & pads read crisply
	if stage._fx_pool != null:
		stage._fx_pool.tick(1.0)
		for raw_pop in stage._fx_pool._popup_pool:
			var pop: Dictionary = raw_pop as Dictionary
			pop["timer"] = 0.0
			var plbl := pop.get("label", null) as Label3D
			if plbl != null and is_instance_valid(plbl):
				plbl.visible = false
	stage._recompute_team_scores()

	# Populate conveyor belts and midfield lanes with active loose batteries
	stage._spawn_battery(int(cfg.CELL_GOLD), Vector3(3.8, 0.0, 0.0))
	stage._spawn_battery(int(cfg.CELL_STANDARD), Vector3(-3.8, 0.0, 0.0))
	stage._spawn_battery(int(cfg.CELL_STANDARD), Vector3(2.4, 0.0, -2.9))
	stage._spawn_battery(int(cfg.CELL_GOLD), Vector3(-2.5, 0.0, -3.4))
	stage._animate_visuals(0.016)


func players_set(stage: Node3D, nid, p: Dictionary) -> void:
	stage._players[nid] = p


func run_smoke_test(stage: Node3D) -> void:
	stage._load_helpers()
	stage._is_server_sim = true
	stage._standalone_mode = true
	var roster: Array = stage._build_standalone_roster(4, 2)
	stage._setup_match_local(0, 20261123, roster, true)
	var dt: float = 1.0 / 60.0
	for _frame in range(3100):
		stage._srv_time += dt
		if int(stage._phase) == stage.PH_PREP:
			stage._step_prep(dt)
		elif int(stage._phase) == stage.PH_LIVE:
			stage._step_simulation(dt)
		else:
			break
	if not _expect(stage, stage._core1_dropped, "smoke: Core #1 did not drop"):
		return
	print("CORE_HEIST_SMOKE_OK elapsed=%.1f phase=%d scores=%s" % [stage._elapsed_time, stage._phase, str(stage._team_scores)])
	stage.get_tree().quit(0)


func run_self_tests(stage: Node3D) -> void:
	stage._load_helpers()
	stage._is_server_sim = true
	stage._standalone_mode = true
	var cfg = stage.C

	# 1. Dynamic arena sizes & symmetric base layouts (2, 3, 4 teams)
	if not _expect(stage, is_equal_approx(float(cfg.arena_size_for_teams(2)), 24.0), "2 teams arena must be 24m"):
		return
	if not _expect(stage, is_equal_approx(float(cfg.arena_size_for_teams(3)), 28.0), "3 teams arena must be 28m"):
		return
	if not _expect(stage, is_equal_approx(float(cfg.arena_size_for_teams(4)), 28.0), "4 teams arena must be 28m"):
		return
	var b3: Array = cfg.base_positions_for_teams(3)
	if not _expect(stage, b3.size() == 3, "3 teams must have 3 base positions"):
		return
	var d01: float = (b3[0] as Vector2).distance_to(b3[1] as Vector2)
	var d12: float = (b3[1] as Vector2).distance_to(b3[2] as Vector2)
	if not _expect(stage, absf(d01 - d12) < 0.1, "3-team bases must be equilateral"):
		return

	# Setup 2v2 match (Team 1: 1, 2; Team 2: 3, 4)
	var roster2v2 := [
		{"id": 0, "network_id": 1, "nickname": "T1A", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "T1B", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "T2A", "team_id": 2, "is_ai": false, "customization": []},
		{"id": 3, "network_id": 4, "nickname": "T2B", "team_id": 2, "is_ai": false, "customization": []},
	]
	stage._setup_match_local(0, 1001, roster2v2, false)
	stage._phase = stage.PH_LIVE

	# 2. Friendly-fire immunity vs enemy shove
	var p1: Dictionary = stage._players[1] as Dictionary
	var p2: Dictionary = stage._players[2] as Dictionary
	var p3: Dictionary = stage._players[3] as Dictionary
	p1["pos"] = Vector3(0.0, 0.0, 3.0)
	p1["facing"] = Vector2(1.0, 0.0)
	p2["pos"] = Vector3(1.2, 0.0, 3.0)
	p3["pos"] = Vector3(1.4, 0.0, 3.0)
	var std_idx: int = stage._spawn_battery(int(cfg.CELL_STANDARD), Vector3(1.4, 1.55, 3.0))
	(stage._batteries[std_idx] as Dictionary)["state"] = int(cfg.BAT_CARRIED)
	(stage._batteries[std_idx] as Dictionary)["carrier_id"] = 3
	p3["carried_battery"] = std_idx
	stage._perform_shove(1)
	if not _expect(stage, is_zero_approx(float(p2["stun_timer"])) and (p2["knockback_vel"] as Vector2).length() < 0.01, "friendly shove must deal 0 stun & 0 knockback"):
		return
	if not _expect(stage, is_equal_approx(float(p3["stun_timer"]), float(cfg.STUN_DURATION)), "enemy shove must apply 0.45s stun"):
		return
	if not _expect(stage, int(p3["carried_battery"]) == -1 and int((stage._batteries[std_idx] as Dictionary)["state"]) == int(cfg.BAT_LOOSE), "enemy shove must drop carried battery"):
		return

	# 3. Heavy Core dual-team resonance (0.55x -> 1.15x within 2.6m + shove drop resistance -> 0.55x when separated)
	var core_idx: int = stage._spawn_battery(int(cfg.CELL_CORE), Vector3(0.0, 1.55, 3.0))
	(stage._batteries[core_idx] as Dictionary)["state"] = int(cfg.BAT_CARRIED)
	(stage._batteries[core_idx] as Dictionary)["carrier_id"] = 1
	p1["carried_battery"] = core_idx
	p1["pos"] = Vector3(0.0, 0.0, 3.0)
	p2["pos"] = Vector3(5.0, 0.0, 3.0) # Far (> 2.6m)
	stage._update_resonance_state()
	if not _expect(stage, not bool(p1["has_resonance"]), "resonance must be false when teammate is > 2.6m away"):
		return
	var m_solo: float = float(cfg.battery_speed_mult(int(cfg.CELL_CORE), false, false))
	if not _expect(stage, is_equal_approx(m_solo, 0.55), "solo core speed must be 0.55x"):
		return

	p2["pos"] = Vector3(1.8, 0.0, 3.0) # Close (<= 2.6m)
	p2["stun_timer"] = 0.0
	stage._update_resonance_state()
	if not _expect(stage, bool(p1["has_resonance"]), "resonance must activate within 2.6m"):
		return
	var m_res: float = float(cfg.battery_speed_mult(int(cfg.CELL_CORE), true, false))
	if not _expect(stage, is_equal_approx(m_res, 1.15), "resonance core speed must be 1.15x"):
		return

	# Enemy shoving resonant carrier must NOT drop Core
	p3["pos"] = Vector3(0.0, 0.0, 4.2)
	p3["facing"] = Vector2(0.0, -1.0)
	p3["stun_timer"] = 0.0
	p3["shove_cooldown"] = 0.0
	stage._perform_shove(3)
	if not _expect(stage, int(p1["carried_battery"]) == core_idx, "resonant Core carrier must resist shove drop"):
		return

	# 4. Vault 3.0s magnetic lock, steal priority (Gold over Standard), and Core permanent lock
	var b_std: int = stage._spawn_battery(int(cfg.CELL_STANDARD), Vector3.ZERO)
	var b_gold: int = stage._spawn_battery(int(cfg.CELL_GOLD), Vector3.ZERO)
	stage._deposit_battery(b_std, 2)
	stage._deposit_battery(b_gold, 2)
	# Early steal blocked by 3.0s lock
	p1["carried_battery"] = -1
	var v2: Vector2 = stage._base_positions[1] as Vector2
	p1["pos"] = Vector3(v2.x, 0.0, v2.y)
	stage._try_auto_pickup(1)
	if not _expect(stage, int(p1["carried_battery"]) == -1, "locked vault battery must not be stealable before 3.0s"):
		return
	# Expire locks -> must steal Gold (+3) over Standard (+1)
	(stage._batteries[b_std] as Dictionary)["lock_timer"] = 0.0
	(stage._batteries[b_gold] as Dictionary)["lock_timer"] = 0.0
	stage._try_auto_pickup(1)
	if not _expect(stage, int(p1["carried_battery"]) == b_gold, "steal must prioritize Gold (+3) over Standard (+1)"):
		return
	# Core permanent lock
	stage._deposit_battery(core_idx, 1)
	if not _expect(stage, bool((stage._batteries[core_idx] as Dictionary)["perm_locked"]), "Core must be permanently locked on deposit"):
		return
	p3["carried_battery"] = -1
	var v1: Vector2 = stage._base_positions[0] as Vector2
	p3["pos"] = Vector3(v1.x, 0.0, v1.y)
	stage._try_auto_pickup(3)
	if not _expect(stage, int(p3["carried_battery"]) == -1, "permanently locked Core must never be stealable"):
		return

	# 5. Overdrive (+1 steal bonus in Phase 3 >= 60s)
	stage._elapsed_time = 61.0
	p1["carried_battery"] = -1
	stage._deposit_battery(b_gold, 1) # b_gold had stolen_from_team = 2
	if not _expect(stage, int(stage._team_steal_bonus.get(1, 0)) == 1, "Overdrive steal deposit must award +1 steal bonus"):
		return

	# 6. Teammate relay throw (2.5m)
	var b_pass: int = stage._spawn_battery(int(cfg.CELL_STANDARD), Vector3.ZERO)
	(stage._batteries[b_pass] as Dictionary)["state"] = int(cfg.BAT_CARRIED)
	(stage._batteries[b_pass] as Dictionary)["carrier_id"] = 1
	p1["carried_battery"] = b_pass
	p1["pos"] = Vector3(0.0, 0.0, 5.0)
	p1["facing"] = Vector2(1.0, 0.0)
	p2["carried_battery"] = -1
	p2["stun_timer"] = 0.0
	p2["pos"] = Vector3(2.2, 0.0, 5.0)
	stage._throw_battery(1, b_pass)
	for _f in range(25):
		stage._step_batteries(1.0 / 60.0)
		if int(p2["carried_battery"]) == b_pass:
			break
	if not _expect(stage, int(p2["carried_battery"]) == b_pass, "teammate must catch relay throw"):
		return

	# 7. Asymmetric 1v2 & mid-match disconnect -> 0.85x solo-team fallback + early finish
	var roster1v2 := [
		{"id": 0, "network_id": 1, "nickname": "Solo", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "DuoA", "team_id": 2, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "DuoB", "team_id": 2, "is_ai": false, "customization": []},
	]
	stage._setup_match_local(0, 2002, roster1v2, false)
	stage._phase = stage.PH_LIVE
	var m_1v2_solo: float = float(cfg.battery_speed_mult(int(cfg.CELL_CORE), false, stage._active_members_in_team(1) <= 1))
	if not _expect(stage, is_equal_approx(m_1v2_solo, 0.85), "1-member team must get 0.85x Core fallback speed"):
		return
	stage.player_disconnected(3)
	if not _expect(stage, stage._active_members_in_team(2) == 1 and stage._phase == stage.PH_LIVE, "disconnecting 1 of 2 on Team 2 keeps match live with 1v1"):
		return
	stage.player_disconnected(2)
	if not _expect(stage, stage._phase == stage.PH_ENDED, "match must end early when <= 1 active team remains"):
		return

	# 7b. Sparse team IDs (Team 1 vs Team 3 only) & escort resonance & tie/draw detection
	var roster1v3 := [
		{"id": 0, "network_id": 1, "nickname": "R1", "team_id": 1, "is_ai": false, "customization": []},
		{"id": 1, "network_id": 2, "nickname": "G1", "team_id": 3, "is_ai": false, "customization": []},
		{"id": 2, "network_id": 3, "nickname": "G2", "team_id": 3, "is_ai": false, "customization": []},
	]
	stage._setup_match_local(0, 2500, roster1v3, false)
	stage._phase = stage.PH_LIVE
	if not _expect(stage, stage._active_team_ids == [1, 3], "sparse teams must preserve [1, 3]"):
		return
	var bg_sparse: int = stage._spawn_battery(int(cfg.CELL_GOLD), Vector3.ZERO)
	stage._deposit_battery(bg_sparse, 3)
	stage._recompute_team_scores()
	if not _expect(stage, int(stage._team_scores.get(3, 0)) == 3 and stage._winning_teams() == [3], "sparse Team 3 must score 3 and win"):
		return
	# Tie / draw check
	var bg_tie: int = stage._spawn_battery(int(cfg.CELL_GOLD), Vector3.ZERO)
	stage._deposit_battery(bg_tie, 1)
	stage._recompute_team_scores()
	if not _expect(stage, stage._winning_teams().size() == 2, "equal team scores must report 2 tied winners (draw)"):
		return
	# Escort resonance HUD check (local peer is escort pair[1])
	stage._local_net_id = 3
	stage._resonance_pairs = [[2, 3]]
	if not _expect(stage, stage._is_local_in_resonance(), "escort teammate must also see resonance HUD active"):
		return
	stage._local_net_id = 1

	# 8. Battery pool scaling (32 pool + scaled loose caps) & spawn non-overlap checks (2v2, 2v2v2, 2v2v2v2, 4v4)
	if not _expect(stage, int(cfg.BATTERY_POOL_SIZE) == 32, "BATTERY_POOL_SIZE must be 32"):
		return
	if not _expect(stage, int(cfg.max_loose_standard(4, 8)) > int(cfg.max_loose_standard(2, 4)), "4-team 8p standard loose cap must scale above 2v2"):
		return
	if not _expect(stage, int(cfg.max_loose_gold(4, 8)) > int(cfg.max_loose_gold(2, 4)), "4-team 8p gold loose cap must scale above 2v2"):
		return
	if not _expect(stage, int(cfg.max_loose_standard(2, 8)) > int(cfg.max_loose_standard(2, 4)), "4v4 8p standard loose cap must scale above 2v2"):
		return

	for layout in [[2, 2], [3, 2], [4, 2], [2, 4]]:
		var tc: int = int(layout[0])
		var pt: int = int(layout[1])
		var r_check: Array = stage._build_standalone_roster(tc, pt)
		stage._setup_match_local(0, 4000 + tc * 10 + pt, r_check, true)
		var spawn_pts: Array = []
		for raw_p in stage._players.values():
			var sp3: Vector3 = (raw_p as Dictionary)["pos"] as Vector3
			var sp2 := Vector2(sp3.x, sp3.z)
			if not _expect(stage, absf(sp2.x) <= stage._arena_half - float(cfg.PLAYER_RADIUS) and absf(sp2.y) <= stage._arena_half - float(cfg.PLAYER_RADIUS), "spawn out of arena bounds for %dx%d" % [tc, pt]):
				return
			if not _expect(stage, sp2.length() >= float(cfg.DISPENSER_RADIUS) + float(cfg.PLAYER_RADIUS) - 0.01, "spawn overlaps dispenser for %dx%d" % [tc, pt]):
				return
			for raw_pil in stage._pillars:
				var pil: Vector2 = raw_pil as Vector2
				if not _expect(stage, sp2.distance_to(pil) >= float(cfg.PILLAR_RADIUS) + float(cfg.PLAYER_RADIUS) - 0.01, "spawn overlaps pillar for %dx%d" % [tc, pt]):
					return
			for raw_v in stage._vault_by_team.values():
				var v2_chk: Vector2 = raw_v as Vector2
				if not _expect(stage, sp2.distance_to(v2_chk) >= float(cfg.VAULT_RADIUS) + 0.1, "spawn overlaps vault for %dx%d" % [tc, pt]):
					return
			for prev_raw in spawn_pts:
				var prev2: Vector2 = prev_raw as Vector2
				if not _expect(stage, sp2.distance_to(prev2) >= float(cfg.PLAYER_RADIUS) * 1.9, "spawn overlaps teammate for %dx%d" % [tc, pt]):
					return
			spawn_pts.append(sp2)

	# 8b. Non-standalone HUD results panel suppression vs standalone CRT results display
	var hud_cls = stage._load_script_res(stage.HUD_RES, "hud_ui.gd")
	if not _expect(stage, hud_cls != null, "hud_ui.gd must load"):
		return
	var hosted_hud = hud_cls.new()
	hosted_hud.build_hud(stage, stage._team, false)
	hosted_hud.show_results([1, 2], {1: 5, 2: 3}, [1], false)
	var hosted_visible: bool = hosted_hud._results_panel != null and is_instance_valid(hosted_hud._results_panel) and bool(hosted_hud._results_panel.visible)
	if not _expect(stage, not hosted_visible, "hosted non-standalone match must NOT show custom results panel"):
		return
	if hosted_hud._layer != null and is_instance_valid(hosted_hud._layer):
		hosted_hud._layer.queue_free()

	var solo_hud = hud_cls.new()
	solo_hud.build_hud(stage, stage._team, true)
	solo_hud.show_results([1, 2], {1: 5, 2: 3}, [1], true)
	var solo_visible: bool = solo_hud._results_panel != null and is_instance_valid(solo_hud._results_panel) and bool(solo_hud._results_panel.visible)
	if not _expect(stage, solo_visible, "standalone match must show CRT results panel"):
		return
	if solo_hud._layer != null and is_instance_valid(solo_hud._layer):
		solo_hud._layer.queue_free()

	# 9. Full 75s stress simulations for BOTH 4v4 (2x4) and 2v2v2v2 (4x2)
	var dt: float = 1.0 / 60.0
	var last_total_pts: int = 0
	var last_saw_resonance: bool = false
	for sim_case in [{"label": "4v4", "teams": 2, "per": 4, "seed": 3001}, {"label": "2v2v2v2", "teams": 4, "per": 2, "seed": 3003}]:
		var lbl: String = str(sim_case["label"])
		var roster_sim: Array = stage._build_standalone_roster(int(sim_case["teams"]), int(sim_case["per"]))
		stage._setup_match_local(0, int(sim_case["seed"]), roster_sim, true)
		var saw_core1: bool = false
		var saw_core2: bool = false
		var saw_overdrive: bool = false
		var saw_resonance: bool = false
		for _frame in range(4800):
			stage._srv_time += dt
			if int(stage._phase) == stage.PH_PREP:
				stage._step_prep(dt)
			elif int(stage._phase) == stage.PH_LIVE:
				stage._step_simulation(dt)
				if stage._core1_dropped:
					saw_core1 = true
				if stage._core2_dropped:
					saw_core2 = true
				if stage._overdrive_announced:
					saw_overdrive = true
				if not stage._resonance_pairs.is_empty():
					saw_resonance = true
			else:
				break
		if not _expect(stage, stage._phase == stage.PH_ENDED, "%s 75s stress sim must reach PH_ENDED" % lbl):
			return
		if not _expect(stage, saw_core1 and saw_core2 and saw_overdrive, "%s phase transitions (45s Core1, 60s Overdrive, 62s Core2) must all trigger" % lbl):
			return
		if not _expect(stage, stage._batteries.size() == int(cfg.BATTERY_POOL_SIZE), "%s battery pool size must remain fixed at 32" % lbl):
			return
		var total_pts: int = 0
		for sc in stage._team_scores.values():
			total_pts += int(sc)
		if not _expect(stage, total_pts > 0, "%s AI match must score points" % lbl):
			return
		last_total_pts = total_pts
		last_saw_resonance = last_saw_resonance or saw_resonance

	print("SELF_TEST_PASSED (4v4 + 2v2v2v2 stress total_pts=%d, ai_resonance=%s)" % [last_total_pts, str(last_saw_resonance)])
	stage.get_tree().quit(0)
