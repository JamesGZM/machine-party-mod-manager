extends RefCounted

## Diegetic-first HUD overlay for Core Heist:
## - 0px-radius dark CRT-framed top-left team-colored score row (top-right kept 100% clear for team-party HUD)
## - Official opening YOU bracket marker tracking the local player during prep & first 2.5s
## - Large centered bold outlined Terminal F4 3-2-1-GO countdown
## - Frameless event banners & 0px-radius CRT bottom resonance indicator
## - Standalone-only 0px-radius black/phosphor-green CRT results box (suppressed in official hosted matches)


class YouMarkerOverlay extends Control:
	var top_left: Vector2 = Vector2.ZERO
	var bound_size: Vector2 = Vector2.ZERO
	var marker_font: Font = null
	var marker_text: String = "YOU"
	var shake_offset: Vector2 = Vector2.ZERO
	var active: bool = false

	func _draw() -> void:
		if not active or bound_size.x <= 1.0 or bound_size.y <= 1.0:
			return
		var font_to_use: Font = marker_font if marker_font != null else ThemeDB.fallback_font
		var viewport_rect := get_viewport_rect()
		var bounds_center := top_left + bound_size * 0.5
		var viewport_center := viewport_rect.size * 0.5
		var dir := Vector2(1.0 if bounds_center.x < viewport_center.x else -1.0, 1.0 if bounds_center.y < viewport_center.y else -1.0)
		var start_point := Vector2(
			top_left.x + maxf(bound_size.x * dir.x, 0.0),
			top_left.y + maxf(bound_size.y * dir.y, 0.0)
		) - dir
		var text_size := font_to_use.get_string_size(marker_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		var text_point := start_point + dir * 32.0 + Vector2(minf(dir.x, 0.0) * text_size.x, 0.0)
		var line_pts := PackedVector2Array([
			start_point,
			start_point + dir * 32.0,
			start_point + dir * 32.0 + Vector2(dir.x * text_size.x, 0.0),
		])
		var corner := 16.0
		var shadow := Vector2(2.0, 2.0)
		for pass_idx in range(2):
			var off := (shadow if pass_idx == 0 else Vector2.ZERO) + shake_offset
			var col := Color.BLACK if pass_idx == 0 else Color.WHITE
			var p0 := top_left + off
			var p1 := top_left + Vector2(bound_size.x, 0.0) + off
			var p2 := top_left + bound_size + off
			var p3 := top_left + Vector2(0.0, bound_size.y) + off
			draw_line(p0, p0 + Vector2.RIGHT * corner, col, 2.0)
			draw_line(p0, p0 + Vector2.DOWN * corner, col, 2.0)
			draw_line(p1, p1 + Vector2.LEFT * corner, col, 2.0)
			draw_line(p1, p1 + Vector2.DOWN * corner, col, 2.0)
			draw_line(p2, p2 + Vector2.UP * corner, col, 2.0)
			draw_line(p2, p2 + Vector2.LEFT * corner, col, 2.0)
			draw_line(p3, p3 + Vector2.UP * corner, col, 2.0)
			draw_line(p3, p3 + Vector2.RIGHT * corner, col, 2.0)
			var s_pts := PackedVector2Array([line_pts[0] + off, line_pts[1] + off, line_pts[2] + off])
			draw_polyline(s_pts, col, 2.0, false)
			draw_string(font_to_use, text_point + Vector2(0.0, -4.0) + off, marker_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)


const TEAM_COLORS := {
	1: Color(1.0, 0.30, 0.28, 1.0),
	2: Color(0.26, 0.68, 1.0, 1.0),
	3: Color(0.28, 0.92, 0.48, 1.0),
	4: Color(1.0, 0.84, 0.24, 1.0),
}

var _layer: CanvasLayer = null
var _score_labels: Array = []
var _score_slot_tids: Array[int] = [-1, -1, -1, -1]
var _you_marker: YouMarkerOverlay = null
var _countdown_label: Label = null
var _banner_label: Label = null
var _resonance_panel: PanelContainer = null
var _resonance_label: Label = null
var _results_panel: PanelContainer = null
var _results_title: Label = null
var _results_label: Label = null
var _hint_label: Label = null
var _countdown_timer: float = 0.0
var _banner_timer: float = 0.0
var _is_standalone: bool = false


static func pick_loc(en: String, cn: String, tw: String) -> String:
	var low: String = TranslationServer.get_locale().to_lower()
	if low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo"):
		return tw
	if low.begins_with("zh") or low == "zhs":
		return cn
	return en


static func team_name(tid: int) -> String:
	match tid:
		1: return pick_loc("RED", "红队", "紅隊")
		2: return pick_loc("BLU", "蓝队", "藍隊")
		3: return pick_loc("GRN", "绿队", "綠隊")
		4: return pick_loc("YEL", "黄队", "黃隊")
		_: return "T%d" % tid


static func draw_banner() -> String:
	return pick_loc("DRAW!", "平局!", "平手!")


static func _make_cjk_fallback_font(base_font: Font) -> Font:
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"PingFang SC",
		"PingFang TC",
		"Microsoft YaHei",
		"Noto Sans CJK SC",
		"Noto Sans CJK TC",
		"Heiti SC",
		"Sans-Serif",
	])
	if base_font == null:
		return sys
	var fv := FontVariation.new()
	fv.base_font = base_font
	fv.fallbacks = [sys]
	return fv


static func _resolve_fonts(team_helper) -> Dictionary:
	var num_font: Font = null
	if ResourceLoader.exists("res://fonts/Terminal F4.ttf"):
		num_font = ResourceLoader.load("res://fonts/Terminal F4.ttf") as Font
	var ui_font: Font = null
	if team_helper != null and team_helper.has_method("tp_font"):
		ui_font = team_helper.call("tp_font") as Font
	if ui_font == null:
		ui_font = _make_cjk_fallback_font(num_font)
	return {
		"ui": ui_font,
		"num": num_font if num_font != null else ui_font,
	}


static func _make_crt_panel(bg: Color, border: Color, pad_h: float = 16.0, pad_v: float = 10.0) -> PanelContainer:
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(2)
	st.corner_radius_top_left = 0
	st.corner_radius_top_right = 0
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	st.content_margin_left = pad_h
	st.content_margin_right = pad_h
	st.content_margin_top = pad_v
	st.content_margin_bottom = pad_v
	panel.add_theme_stylebox_override("panel", st)
	return panel


func build_hud(parent: Node, team_helper = null, is_standalone: bool = false) -> void:
	_is_standalone = is_standalone
	if _layer != null and is_instance_valid(_layer):
		if _results_panel != null and is_instance_valid(_results_panel) and not _is_standalone:
			_results_panel.visible = false
		return

	var fonts: Dictionary = _resolve_fonts(team_helper)
	var ui_font: Font = fonts["ui"] as Font
	var num_font: Font = fonts["num"] as Font

	_layer = CanvasLayer.new()
	_layer.name = "CoreHeistHud"
	_layer.layer = 10
	parent.add_child(_layer)

	var root_ctrl := Control.new()
	root_ctrl.name = "HudRoot"
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root_ctrl)

	# Opening YOU bracket marker (official Machine Party style)
	_you_marker = YouMarkerOverlay.new()
	_you_marker.name = "YouMarkerOverlay"
	_you_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_you_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_you_marker.marker_font = ui_font
	_you_marker.marker_text = pick_loc("YOU", "你", "你")
	_you_marker.visible = false
	root_ctrl.add_child(_you_marker)

	# 0px-radius dark CRT-framed top-left team score bar (top-right kept 100% clear for team-party HUD)
	var score_panel := _make_crt_panel(Color(0.03, 0.04, 0.03, 0.88), Color(0.53, 0.83, 0.50, 0.85), 14.0, 5.0)
	score_panel.name = "TopLeftScorePanel"
	score_panel.anchor_left = 0.0
	score_panel.anchor_right = 0.0
	score_panel.anchor_top = 0.0
	score_panel.anchor_bottom = 0.0
	score_panel.offset_left = 18.0
	score_panel.offset_top = 12.0
	score_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(score_panel)

	var score_row := HBoxContainer.new()
	score_row.name = "TopLeftTeamScores"
	score_row.add_theme_constant_override("separation", 18)
	score_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.add_child(score_row)

	_score_labels.clear()
	_score_slot_tids = [-1, -1, -1, -1]
	for i in range(4):
		var sl := Label.new()
		sl.name = "TeamScore_%d" % (i + 1)
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sl.add_theme_font_size_override("font_size", 24)
		sl.add_theme_color_override("font_outline_color", Color.BLACK)
		sl.add_theme_constant_override("outline_size", 6)
		if ui_font != null:
			sl.add_theme_font_override("font", ui_font)
		sl.visible = false
		score_row.add_child(sl)
		_score_labels.append(sl)

	# Large centered bold outlined Terminal F4 countdown (3, 2, 1, GO!)
	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_label.add_theme_font_size_override("font_size", 74)
	_countdown_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.72))
	_countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_countdown_label.add_theme_constant_override("outline_size", 14)
	if num_font != null:
		_countdown_label.add_theme_font_override("font", num_font)
	_countdown_label.visible = false
	root_ctrl.add_child(_countdown_label)

	# Frameless crisp outlined event banner (upper-middle, clear of corners & 3D CRT)
	_banner_label = Label.new()
	_banner_label.name = "EventBannerLabel"
	_banner_label.anchor_left = 0.08
	_banner_label.anchor_right = 0.92
	_banner_label.anchor_top = 0.14
	_banner_label.anchor_bottom = 0.24
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label.add_theme_font_size_override("font_size", 30)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	_banner_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner_label.add_theme_constant_override("outline_size", 8)
	if ui_font != null:
		_banner_label.add_theme_font_override("font", ui_font)
	_banner_label.visible = false
	root_ctrl.add_child(_banner_label)

	# Bottom-center 0px-radius CRT-bordered resonance indicator
	var res_center := CenterContainer.new()
	res_center.name = "ResonanceCenter"
	res_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	res_center.offset_top = -54.0
	res_center.offset_bottom = -12.0
	res_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(res_center)

	_resonance_panel = _make_crt_panel(Color(0.03, 0.05, 0.03, 0.88), Color(0.53, 0.83, 0.50, 0.92), 14.0, 5.0)
	_resonance_panel.name = "ResonancePanel"
	_resonance_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resonance_panel.visible = false
	res_center.add_child(_resonance_panel)

	_resonance_label = Label.new()
	_resonance_label.name = "ResonanceLabel"
	_resonance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resonance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resonance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resonance_label.add_theme_font_size_override("font_size", 18)
	_resonance_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.72))
	_resonance_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_resonance_label.add_theme_constant_override("outline_size", 4)
	if ui_font != null:
		_resonance_label.add_theme_font_override("font", ui_font)
	_resonance_panel.add_child(_resonance_label)

	# Standalone-only bottom-left control hint
	_hint_label = Label.new()
	_hint_label.name = "StandaloneHint"
	_hint_label.anchor_left = 0.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.anchor_top = 1.0
	_hint_label.offset_left = 14.0
	_hint_label.offset_right = 760.0
	_hint_label.offset_top = -32.0
	_hint_label.offset_bottom = -8.0
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.76, 0.88, 0.76, 0.88))
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 4)
	if ui_font != null:
		_hint_label.add_theme_font_override("font", ui_font)
	_hint_label.text = pick_loc(
		"[WASD] Move  [Space] Shove / Throw  [R] Restart  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4",
		"[WASD] 移动  [空格] 推搡/抛投  [R] 重开  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4",
		"[WASD] 移動  [空白鍵] 推搡/拋投  [R] 重開  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4"
	)
	_hint_label.visible = false
	root_ctrl.add_child(_hint_label)

	# Standalone-only 0px-radius black/phosphor-green CRT round summary box.
	# Official hosted matches hand off directly to Machine Party's native scoreboard.
	if not _is_standalone:
		return

	_results_panel = _make_crt_panel(Color(0.03, 0.04, 0.03, 0.96), Color(0.53, 0.83, 0.50, 0.88), 22.0, 16.0)
	_results_panel.name = "StandaloneResultsPanel"
	_results_panel.anchor_left = 0.5
	_results_panel.anchor_right = 0.5
	_results_panel.anchor_top = 0.5
	_results_panel.anchor_bottom = 0.5
	_results_panel.offset_left = -250.0
	_results_panel.offset_right = 250.0
	_results_panel.offset_top = -145.0
	_results_panel.offset_bottom = 145.0
	_results_panel.visible = false
	root_ctrl.add_child(_results_panel)

	var rvbox := VBoxContainer.new()
	rvbox.add_theme_constant_override("separation", 10)
	_results_panel.add_child(rvbox)

	_results_title = Label.new()
	_results_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_title.add_theme_font_size_override("font_size", 28)
	_results_title.add_theme_color_override("font_color", Color(0.53, 0.83, 0.50))
	_results_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_results_title.add_theme_constant_override("outline_size", 5)
	if ui_font != null:
		_results_title.add_theme_font_override("font", ui_font)
	rvbox.add_child(_results_title)

	_results_label = Label.new()
	_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_results_label.add_theme_font_size_override("font_size", 20)
	_results_label.add_theme_color_override("font_color", Color(0.80, 0.92, 0.78))
	_results_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_results_label.add_theme_constant_override("outline_size", 4)
	if ui_font != null:
		_results_label.add_theme_font_override("font", ui_font)
	rvbox.add_child(_results_label)


func set_standalone_hint(visible_flag: bool) -> void:
	if _hint_label != null and is_instance_valid(_hint_label):
		_hint_label.visible = visible_flag


func show_results(team_ids: Array, team_scores: Dictionary, winners: Array, is_standalone: bool) -> void:
	if not is_standalone:
		hide_results()
		return
	if _results_panel == null or not is_instance_valid(_results_panel) or _results_label == null:
		return
	var rows: Array = []
	for raw_tid in team_ids:
		var tid: int = int(raw_tid)
		rows.append({"tid": tid, "score": int(team_scores.get(tid, 0))})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["score"]) > int(b["score"])
	)
	if _results_title != null and is_instance_valid(_results_title):
		if winners.size() > 1:
			_results_title.text = draw_banner()
		elif winners.size() == 1:
			_results_title.text = "%s %s" % [team_name(int(winners[0])), pick_loc("WINS!", "获胜!", "獲勝!")]
		else:
			_results_title.text = pick_loc("ROUND SUMMARY", "回合结算", "回合結算")

	var lines: Array[String] = []
	for i in range(rows.size()):
		var r: Dictionary = rows[i] as Dictionary
		lines.append("#%d  %s : %d" % [i + 1, team_name(int(r["tid"])), int(r["score"])])
	lines.append("")
	lines.append(pick_loc(
		"[R] Restart  |  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4",
		"[R] 重开  |  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4",
		"[R] 重開  |  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4"
	))
	_results_label.text = "\n".join(lines)
	_results_panel.visible = true


func hide_results() -> void:
	if _results_panel != null and is_instance_valid(_results_panel):
		_results_panel.visible = false


func show_countdown(text: String, color: Color = Color(0.76, 1.0, 0.72), duration: float = 0.85) -> void:
	if _countdown_label == null or not is_instance_valid(_countdown_label):
		return
	_countdown_label.text = text
	_countdown_label.add_theme_color_override("font_color", color)
	_countdown_label.visible = not text.is_empty()
	_countdown_timer = duration


func show_banner(text: String, color: Color = Color(1.0, 0.88, 0.35), duration: float = 2.4) -> void:
	if _banner_label == null or not is_instance_valid(_banner_label):
		return
	_banner_label.text = text
	_banner_label.add_theme_color_override("font_color", color)
	_banner_label.visible = not text.is_empty()
	_banner_timer = duration


func update_you_marker(camera: Camera3D, world_pos: Vector3, show_marker: bool, sim_time: float) -> void:
	if _you_marker == null or not is_instance_valid(_you_marker):
		return
	if not show_marker or camera == null or not is_instance_valid(camera):
		if _you_marker.active or _you_marker.visible:
			_you_marker.active = false
			_you_marker.visible = false
		return
	var center := world_pos + Vector3(0.0, 0.92, 0.0)
	var half := Vector3(0.45, 0.88, 0.45)
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var wp := center + Vector3(sx * half.x, sy * half.y, sz * half.z)
				if camera.is_position_behind(wp):
					_you_marker.active = false
					_you_marker.visible = false
					return
				var sp := camera.unproject_position(wp)
				min_pt.x = minf(min_pt.x, sp.x)
				min_pt.y = minf(min_pt.y, sp.y)
				max_pt.x = maxf(max_pt.x, sp.x)
				max_pt.y = maxf(max_pt.y, sp.y)
	_you_marker.top_left = min_pt
	_you_marker.bound_size = max_pt - min_pt
	var jitter_step: int = int(floor(sim_time * 15.0)) % 4
	var jitters: Array[Vector2] = [Vector2(0.5, 0.5), Vector2(-0.5, -0.5), Vector2(-0.5, 0.5), Vector2(0.5, -0.5)]
	_you_marker.shake_offset = jitters[jitter_step]
	_you_marker.active = true
	_you_marker.visible = true
	_you_marker.queue_redraw()


func update_hud(team_ids: Array, team_scores: Dictionary, _time_remaining: float, _phase: int, _prep_remaining: float, resonance_active: bool, delta: float) -> void:
	for i in range(_score_labels.size()):
		var sl := _score_labels[i] as Label
		if sl == null or not is_instance_valid(sl):
			continue
		if i < team_ids.size():
			var tid: int = int(team_ids[i])
			var sc: int = int(team_scores.get(tid, 0))
			var txt: String = "%s %d" % [team_name(tid), sc]
			if sl.text != txt:
				sl.text = txt
			if i < _score_slot_tids.size() and _score_slot_tids[i] != tid:
				_score_slot_tids[i] = tid
				var tcol: Color = TEAM_COLORS.get(tid, Color.WHITE) as Color
				sl.add_theme_color_override("font_color", tcol)
			sl.visible = true
		else:
			sl.visible = false

	if _resonance_panel != null and is_instance_valid(_resonance_panel):
		_resonance_panel.visible = resonance_active
		if resonance_active and _resonance_label != null and is_instance_valid(_resonance_label):
			var rtxt: String = pick_loc(
				"RESONANCE ACTIVE (1.15x SPEED)",
				"双人电磁共振激活 (1.15x 移速)",
				"雙人電磁共振啟動 (1.15x 移速)"
			)
			if _resonance_label.text != rtxt:
				_resonance_label.text = rtxt

	if _countdown_timer > 0.0:
		_countdown_timer -= delta
		if _countdown_timer <= 0.0 and _countdown_label != null and is_instance_valid(_countdown_label):
			_countdown_label.visible = false

	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0 and _banner_label != null and is_instance_valid(_banner_label):
			_banner_label.visible = false
