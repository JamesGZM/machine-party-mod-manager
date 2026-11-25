extends RefCounted

## Shared optional team-mode helper embedded in first-party minigame mods.
## Reads the room-level team registry from Engine meta `&"mpm_team_party"` when
## `team-party` is installed and active, and degrades cleanly to FFA otherwise.

const TEAM_COLORS := {
	1: Color(1.0, 0.30, 0.28, 1.0),
	2: Color(0.26, 0.68, 1.0, 1.0),
	3: Color(0.28, 0.92, 0.48, 1.0),
	4: Color(1.0, 0.84, 0.24, 1.0),
}

const KNOWN_PREFIXES := [
	"[RED] ", "[BLU] ", "[GRN] ", "[YEL] ",
	"[红] ", "[蓝] ", "[绿] ", "[黄] ",
	"[紅] ", "[藍] ", "[綠] ", "[黃] ",
]

var active: bool = false
var roster_teams: Dictionary = {}


func tp_node():
	if not Engine.has_meta(&"mpm_team_party"):
		return null
	var meta = Engine.get_meta(&"mpm_team_party")
	if typeof(meta) != TYPE_DICTIONARY or not bool((meta as Dictionary).get("enabled", false)):
		return null
	var tp = (meta as Dictionary).get("node", null)
	if tp != null and is_instance_valid(tp) and tp.has_method("get_team"):
		return tp
	return null


func resolve_roster_teams(roster: Array) -> void:
	roster_teams.clear()
	var tp = tp_node()
	var distinct: Dictionary = {}
	for raw in roster:
		if not (raw is Dictionary):
			continue
		var entry: Dictionary = raw as Dictionary
		var nid: int = int(entry.get("network_id", 0))
		var tid: int = int(entry.get("team_id", 0))
		if tid <= 0 and tp != null:
			tid = int(tp.call("get_team", nid))
		roster_teams[nid] = tid
		if tid > 0:
			distinct[tid] = true
	active = distinct.size() >= 2


func begin_match(stage: Node, roster: Array) -> void:
	resolve_roster_teams(roster)
	if stage == null or not is_instance_valid(stage):
		return
	stage.set_meta(&"mpm_native_team_stage", true)
	var parent := stage.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.set_meta(&"mpm_custom_team_game", active)
		parent.set_meta(&"mpm_team_scores_applied", false)
	var tp = tp_node()
	if tp != null and tp.has_method("register_native_team_stage"):
		tp.call("register_native_team_stage", stage)


func annotate_roster(roster: Array) -> Array:
	var out: Array = []
	for raw in roster:
		if not (raw is Dictionary):
			out.append(raw)
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate(false)
		var nid: int = int(entry.get("network_id", 0))
		var tid: int = player_team(nid)
		if tid > 0:
			entry["team_id"] = tid
		out.append(entry)
	return out


func is_active() -> bool:
	return active


func player_team(net_id: int) -> int:
	if not active:
		return 0
	return int(roster_teams.get(net_id, 0))


func are_teammates(id_a: int, id_b: int) -> bool:
	if not active or id_a == id_b:
		return false
	var ta: int = player_team(id_a)
	return ta > 0 and ta == player_team(id_b)


func team_color(tid: int) -> Color:
	return TEAM_COLORS.get(tid, Color.WHITE) as Color


func tp_font() -> Font:
	var tp = tp_node()
	if tp != null and tp.has_method("_get_cjk_badge_font"):
		return tp.call("_get_cjk_badge_font") as Font
	return null


func is_tw_locale() -> bool:
	var low: String = TranslationServer.get_locale().to_lower()
	return low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo")


func is_cn_locale() -> bool:
	var low: String = TranslationServer.get_locale().to_lower()
	return not is_tw_locale() and (low.begins_with("zh") or low == "zhs")


func team_tag(tid: int) -> String:
	var tp = tp_node()
	if tp != null and tp.has_method("get_team_tag"):
		return str(tp.call("get_team_tag", tid))
	var is_tw: bool = is_tw_locale()
	var is_cn: bool = is_cn_locale()
	match tid:
		1: return "[紅]" if is_tw else ("[红]" if is_cn else "[RED]")
		2: return "[藍]" if is_tw else ("[蓝]" if is_cn else "[BLU]")
		3: return "[綠]" if is_tw else ("[绿]" if is_cn else "[GRN]")
		4: return "[黃]" if is_tw else ("[黄]" if is_cn else "[YEL]")
		_: return ""


func team_win_banner(tid: int) -> String:
	var is_tw: bool = is_tw_locale()
	var is_cn: bool = is_cn_locale()
	match tid:
		1: return "紅隊獲勝!" if is_tw else ("红队获胜!" if is_cn else "RED TEAM WINS!")
		2: return "藍隊獲勝!" if is_tw else ("蓝队获胜!" if is_cn else "BLUE TEAM WINS!")
		3: return "綠隊獲勝!" if is_tw else ("绿队获胜!" if is_cn else "GREEN TEAM WINS!")
		4: return "黃隊獲勝!" if is_tw else ("黄队获胜!" if is_cn else "YELLOW TEAM WINS!")
		_: return "ROUND COMPLETE!"


func strip_prefix(text: String) -> String:
	for p in KNOWN_PREFIXES:
		if text.begins_with(p):
			return text.substr(p.length())
	return text


func attach_foot_ring(pnode: Node3D, tid: int, inner_r: float = 0.48, outer_r: float = 0.58) -> void:
	if pnode == null or not is_instance_valid(pnode) or tid <= 0:
		return
	var ring := pnode.get_node_or_null("MpmTeamRing") as MeshInstance3D
	if ring == null:
		ring = MeshInstance3D.new()
		ring.name = "MpmTeamRing"
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var torus := TorusMesh.new()
		torus.inner_radius = inner_r
		torus.outer_radius = outer_r
		torus.rings = 20
		torus.ring_segments = 4
		ring.mesh = torus
		ring.scale = Vector3(1.0, 0.14, 1.0)
		ring.position = Vector3(0.0, 0.04, 0.0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = mat
		pnode.add_child(ring)
	var tcol: Color = team_color(tid)
	var rmat := ring.material_override as StandardMaterial3D
	if rmat != null:
		rmat.albedo_color = Color(tcol.r, tcol.g, tcol.b, 0.72)
	ring.visible = true


func apply_nameplate(label_node: Label3D, base_nick: String, tid: int, truncate_len: int = 0) -> String:
	var clean: String = strip_prefix(base_nick)
	if tid <= 0:
		return clean
	var tag: String = team_tag(tid)
	var full_nick: String = "%s %s" % [tag, clean]
	if label_node != null and is_instance_valid(label_node):
		var shown: String = clean
		if truncate_len > 0 and clean.length() > truncate_len:
			shown = clean.left(truncate_len) + "-"
		label_node.text = "%s %s" % [tag, shown]
		label_node.modulate = team_color(tid)
		var cjk_font: Font = tp_font()
		if cjk_font != null and label_node.font != cjk_font:
			label_node.font = cjk_font
	return full_nick


func group_radial_spawns(players_dict: Dictionary, roster: Array, pos_history: Dictionary = {}) -> void:
	if not active or players_dict.is_empty():
		return
	var slots: Array = []
	var order_ids: Array = []
	for raw in roster:
		if not (raw is Dictionary):
			continue
		var nid: int = int((raw as Dictionary).get("network_id", 0))
		if players_dict.has(nid):
			order_ids.append(nid)
			slots.append((players_dict[nid] as Dictionary)["pos"])
	for raw_nid in players_dict.keys():
		var nid: int = int(raw_nid)
		if not order_ids.has(nid):
			order_ids.append(nid)
			slots.append((players_dict[raw_nid] as Dictionary)["pos"])

	slots.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return atan2(a.z, a.x) < atan2(b.z, b.x)
	)
	var keyed: Array = []
	for idx in range(order_ids.size()):
		var nid: int = int(order_ids[idx])
		var tid: int = player_team(nid)
		keyed.append({"team": tid if tid > 0 else 999, "idx": idx, "nid": nid})
	keyed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["team"]) != int(b["team"]):
			return int(a["team"]) < int(b["team"])
		return int(a["idx"]) < int(b["idx"])
	)

	for idx in range(keyed.size()):
		var nid: int = int((keyed[idx] as Dictionary)["nid"])
		var p: Dictionary = players_dict[nid] as Dictionary
		if idx < slots.size():
			var wp: Vector3 = slots[idx] as Vector3
			p["pos"] = wp
			if p.has("render_pos"):
				p["render_pos"] = wp
			if pos_history.has(nid):
				pos_history[nid] = [[0.0, wp]]
			var node: Node3D = p.get("node", null) as Node3D
			if node != null and is_instance_valid(node):
				node.position = wp


func group_lane_spawns(players_arr: Array) -> void:
	if not active or players_arr.is_empty():
		return
	var lanes: Array = []
	for raw_p in players_arr:
		lanes.append(float((raw_p as Dictionary)["z"]))
	lanes.sort()

	players_arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ta: int = player_team(int(a["network_id"]))
		var tb: int = player_team(int(b["network_id"]))
		var ka: int = ta if ta > 0 else 999
		var kb: int = tb if tb > 0 else 999
		if ka != kb:
			return ka < kb
		return int(a["id"]) < int(b["id"])
	)
	for i in range(players_arr.size()):
		var p: Dictionary = players_arr[i] as Dictionary
		if i < lanes.size():
			p["z"] = float(lanes[i])
			var pnode: Node3D = p.get("node", null) as Node3D
			if pnode != null and is_instance_valid(pnode):
				pnode.position.z = float(lanes[i])


func count_alive_teams_dict(players_dict: Dictionary) -> Dictionary:
	var alive_ids: Array = []
	var alive_teams: Dictionary = {}
	for raw_nid in players_dict.keys():
		var nid: int = int(raw_nid)
		var p: Dictionary = players_dict[raw_nid] as Dictionary
		if bool(p.get("alive", false)):
			alive_ids.append(nid)
			var tid: int = player_team(nid)
			alive_teams[tid if tid > 0 else -nid] = true
	return {"alive_ids": alive_ids, "alive_teams": alive_teams}


func count_alive_teams_array(players_arr: Array) -> Dictionary:
	var alive_count: int = 0
	var alive_ids: Array = []
	var alive_teams: Dictionary = {}
	for raw_p in players_arr:
		var p: Dictionary = raw_p as Dictionary
		if bool(p.get("alive", false)):
			var nid: int = int(p["network_id"])
			alive_count += 1
			alive_ids.append(nid)
			var tid: int = player_team(nid)
			alive_teams[tid if tid > 0 else -nid] = true
	return {"alive_count": alive_count, "alive_ids": alive_ids, "alive_teams": alive_teams}


func sync_scores(raw_scores: Dictionary, alive_ids: Array) -> Dictionary:
	if not active or raw_scores.is_empty():
		return raw_scores.duplicate()
	var tp = tp_node()
	if tp != null and tp.has_method("compute_team_synchronized_scores"):
		return tp.call("compute_team_synchronized_scores", raw_scores, alive_ids) as Dictionary
	var alive_map: Dictionary = {}
	for raw_id in alive_ids:
		alive_map[int(raw_id)] = true
	var members_by_team: Dictionary = {}
	for raw_nid in raw_scores.keys():
		var nid: int = int(raw_nid)
		var tid: int = player_team(nid)
		if tid <= 0:
			continue
		if not members_by_team.has(tid):
			members_by_team[tid] = []
		(members_by_team[tid] as Array).append(nid)
	var out: Dictionary = raw_scores.duplicate()
	for raw_tid in members_by_team.keys():
		var members: Array = members_by_team[raw_tid] as Array
		var best_score: int = 0
		var all_alive: bool = not alive_map.is_empty() and not members.is_empty()
		for nid_v in members:
			var nid: int = int(nid_v)
			best_score = maxi(best_score, int(raw_scores.get(nid, 0)))
			if not alive_map.has(nid):
				all_alive = false
		var team_score: int = best_score + (1 if all_alive else 0)
		for nid_v in members:
			out[int(nid_v)] = team_score
	return out


func notify_round_win(scores: Dictionary, stage_node: Node) -> void:
	var tp = tp_node()
	if tp != null and tp.has_method("record_team_win"):
		tp.call("record_team_win", scores, stage_node)


func mark_scores_applied(stage_node: Node) -> void:
	if stage_node == null or not is_instance_valid(stage_node):
		return
	var parent := stage_node.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.set_meta(&"mpm_team_scores_applied", true)
