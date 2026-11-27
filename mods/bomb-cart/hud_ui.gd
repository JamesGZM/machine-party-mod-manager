extends RefCounted

## Distinct Industrial Gauge HUD for Bomb Cart (炸彈推車):
## - Top-right kept 100% clear for team-party's frameless HUD
## - Bottom-center 0px-radius charcoal-steel / amber industrial gauge:
##     * 2-team mode: steel rail pressure gauge with active team names/colors & cart needle
##     * 3-4 team mode: compact Blast Door Status Strip (SAFE / threat % / OUT)
## - Official opening YOU bracket marker & large bold outlined 3-2-1-GO countdown
## - Frameless bold thick-outlined event & Steam Surge banners (zero rounded boxes)
## - CJK-safe FontVariation fallback (Terminal F4 + SystemFont)

const BAR_WIDTH := 280.0
const BAR_HEIGHT := 20.0
const MULTI_BAR_W := 74.0
const MULTI_BAR_H := 14.0

const TEAM_COLORS := {
	1: Color(1.0, 0.30, 0.28, 1.0),
	2: Color(0.26, 0.68, 1.0, 1.0),
	3: Color(0.28, 0.92, 0.48, 1.0),
	4: Color(1.0, 0.84, 0.24, 1.0),
}


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


var _layer: CanvasLayer = null
var _locale_pick: Callable = Callable()
var _team_helper = null
var _ui_font: Font = null

var _you_marker: YouMarkerOverlay = null
var _countdown_label: Label = null
var _surge_label: Label = null
var _banner_label: Label = null
var _hint_label: Label = null

var _gauge_panel: PanelContainer = null
var _gauge_2team: HBoxContainer = null
var _left_label: Label = null
var _right_label: Label = null
var _left_fill: ColorRect = null
var _right_fill: ColorRect = null
var _cart_marker: ColorRect = null
var _time_label_2t: Label = null

var _gauge_multi: HBoxContainer = null
var _door_slots: Array = []
var _time_label_multi: Label = null

var _banner_expire_ms: int = 0
var _go_flash_expire_ms: int = 0
var _last_countdown_num: int = 0
var _cached_texts: Dictionary = {}
var _cached_colors: Dictionary = {}


func _set_lbl_text(lbl: Label, key: StringName, text: String) -> void:
	if lbl == null:
		return
	if str(_cached_texts.get(key, "")) != text:
		_cached_texts[key] = text
		lbl.text = text


func _set_lbl_color(lbl: Label, key: StringName, col: Color) -> void:
	if lbl == null:
		return
	var prev = _cached_colors.get(key, null)
	if not (prev is Color) or not (prev as Color).is_equal_approx(col):
		_cached_colors[key] = col
		lbl.add_theme_color_override("font_color", col)


func _loc(en: String, cn: String, tw: String) -> String:
	if _locale_pick.is_valid():
		var res = _locale_pick.call(en, cn, tw)
		return str(res)
	var low: String = TranslationServer.get_locale().to_lower()
	if low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo"):
		return tw
	if low.begins_with("zh") or low == "zhs":
		return cn
	return en


func _build_cjk_font() -> Font:
	if _team_helper != null and _team_helper.has_method("tp_font"):
		var tpf = _team_helper.call("tp_font")
		if tpf is Font:
			return tpf as Font
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"PingFang TC", "PingFang SC", "Microsoft JhengHei", "Microsoft YaHei",
		"Noto Sans CJK TC", "Heiti TC", "Helvetica Neue", "Arial",
	])
	if ResourceLoader.exists("res://fonts/Terminal F4.ttf"):
		var raw = ResourceLoader.load("res://fonts/Terminal F4.ttf")
		if raw is Font:
			var fv := FontVariation.new()
			fv.base_font = raw as Font
			fv.fallbacks = [sys]
			return fv
	return sys


func _team_color(tid: int) -> Color:
	if _team_helper != null and _team_helper.has_method("team_color"):
		return _team_helper.call("team_color", tid) as Color
	return TEAM_COLORS.get(tid, Color(0.92, 0.86, 0.74, 1.0)) as Color


func _team_name(tid: int) -> String:
	match tid:
		1: return _loc("RED", "红队", "紅隊")
		2: return _loc("BLUE", "蓝队", "藍隊")
		3: return _loc("GREEN", "绿队", "綠隊")
		4: return _loc("YELLOW", "黄队", "黃隊")
		_: return "T%d" % tid


func _team_short(tid: int) -> String:
	match tid:
		1: return _loc("RED", "红", "紅")
		2: return _loc("BLU", "蓝", "藍")
		3: return _loc("GRN", "绿", "綠")
		4: return _loc("YEL", "黄", "黃")
		_: return "T%d" % tid


func _apply_outlined_label(lbl: Label, size: int, col: Color, outline: int) -> void:
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", outline)
	if _ui_font != null:
		lbl.add_theme_font_override("font", _ui_font)


func setup(parent: Node, locale_pick: Callable, team_helper = null) -> void:
	_locale_pick = locale_pick
	_team_helper = team_helper
	if _layer != null and is_instance_valid(_layer):
		return
	if parent == null:
		return

	_ui_font = _build_cjk_font()

	_layer = CanvasLayer.new()
	_layer.name = "BombCartHud"
	_layer.layer = 10
	parent.add_child(_layer)

	var root_ctrl := Control.new()
	root_ctrl.name = "HudRoot"
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root_ctrl)

	# 1. Official opening YOU bracket marker
	_you_marker = YouMarkerOverlay.new()
	_you_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_you_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_you_marker.marker_font = _ui_font
	_you_marker.marker_text = _loc("YOU", "你", "你")
	_you_marker.visible = false
	root_ctrl.add_child(_you_marker)

	# 2. Large centered bold outlined 3-2-1-GO countdown
	_countdown_label = Label.new()
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined_label(_countdown_label, 72, Color(1.0, 0.92, 0.72), 14)
	_countdown_label.visible = false
	root_ctrl.add_child(_countdown_label)

	# 3. Frameless bold thick-outlined Steam Surge alert (sits cleanly just above bottom industrial gauge)
	_surge_label = Label.new()
	_surge_label.anchor_left = 0.15
	_surge_label.anchor_right = 0.85
	_surge_label.anchor_top = 1.0
	_surge_label.anchor_bottom = 1.0
	_surge_label.offset_top = -104.0
	_surge_label.offset_bottom = -68.0
	_surge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_surge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_surge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined_label(_surge_label, 23, Color(1.0, 0.80, 0.24), 8)
	_surge_label.visible = false
	root_ctrl.add_child(_surge_label)

	_banner_label = Label.new()
	_banner_label.anchor_left = 0.12
	_banner_label.anchor_right = 0.88
	_banner_label.anchor_top = 0.19
	_banner_label.anchor_bottom = 0.28
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined_label(_banner_label, 34, Color(1.0, 0.84, 0.26), 10)
	_banner_label.visible = false
	root_ctrl.add_child(_banner_label)

	# 4. Bottom-Center Hard-Edged Industrial Gauge (0px corners, charcoal-black steel + amber industrial border)
	var bottom_center := CenterContainer.new()
	bottom_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_center.offset_top = -64.0
	bottom_center.offset_bottom = -12.0
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bottom_center)

	_gauge_panel = PanelContainer.new()
	_gauge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g_sb := StyleBoxFlat.new()
	g_sb.bg_color = Color(0.03, 0.035, 0.03, 0.92)
	g_sb.border_color = Color(0.95, 0.68, 0.22, 0.92)
	g_sb.set_border_width_all(2)
	g_sb.set_corner_radius_all(0)
	g_sb.content_margin_left = 14.0
	g_sb.content_margin_right = 14.0
	g_sb.content_margin_top = 7.0
	g_sb.content_margin_bottom = 7.0
	_gauge_panel.add_theme_stylebox_override("panel", g_sb)
	bottom_center.add_child(_gauge_panel)

	var gauge_stack := VBoxContainer.new()
	gauge_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge_stack.add_theme_constant_override("separation", 0)
	_gauge_panel.add_child(gauge_stack)

	# 4a. 2-Team Steel Rail Pressure Gauge
	_gauge_2team = HBoxContainer.new()
	_gauge_2team.alignment = BoxContainer.ALIGNMENT_CENTER
	_gauge_2team.add_theme_constant_override("separation", 12)
	_gauge_2team.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge_stack.add_child(_gauge_2team)

	_left_label = Label.new()
	_apply_outlined_label(_left_label, 18, Color(1.0, 0.36, 0.32), 4)
	_gauge_2team.add_child(_left_label)

	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color(0.08, 0.08, 0.07, 1.0)
	bar_sb.border_color = Color(0.68, 0.56, 0.32, 0.95)
	bar_sb.set_border_width_all(1)
	bar_sb.set_corner_radius_all(0)
	bar_bg.add_theme_stylebox_override("panel", bar_sb)
	_gauge_2team.add_child(bar_bg)

	_left_fill = ColorRect.new()
	_left_fill.position = Vector2(1.0, 1.0)
	_left_fill.size = Vector2(BAR_WIDTH * 0.5 - 1.0, BAR_HEIGHT - 2.0)
	_left_fill.color = Color(1.0, 0.30, 0.28, 0.58)
	bar_bg.add_child(_left_fill)

	_right_fill = ColorRect.new()
	_right_fill.position = Vector2(BAR_WIDTH * 0.5, 1.0)
	_right_fill.size = Vector2(BAR_WIDTH * 0.5 - 1.0, BAR_HEIGHT - 2.0)
	_right_fill.color = Color(0.26, 0.68, 1.0, 0.58)
	bar_bg.add_child(_right_fill)

	var mid_tick := ColorRect.new()
	mid_tick.position = Vector2(BAR_WIDTH * 0.5 - 1.0, 0.0)
	mid_tick.size = Vector2(2.0, BAR_HEIGHT)
	mid_tick.color = Color(1.0, 0.86, 0.32, 0.95)
	bar_bg.add_child(mid_tick)

	_cart_marker = ColorRect.new()
	_cart_marker.position = Vector2(BAR_WIDTH * 0.5 - 4.0, -3.0)
	_cart_marker.size = Vector2(8.0, BAR_HEIGHT + 6.0)
	_cart_marker.color = Color(1.0, 0.84, 0.20, 1.0)
	bar_bg.add_child(_cart_marker)

	var needle_hi := ColorRect.new()
	needle_hi.position = Vector2(2.0, 2.0)
	needle_hi.size = Vector2(4.0, BAR_HEIGHT + 2.0)
	needle_hi.color = Color(1.0, 0.98, 0.86, 1.0)
	_cart_marker.add_child(needle_hi)

	_right_label = Label.new()
	_apply_outlined_label(_right_label, 18, Color(0.32, 0.72, 1.0), 4)
	_gauge_2team.add_child(_right_label)

	var sep_2t := ColorRect.new()
	sep_2t.custom_minimum_size = Vector2(2.0, 20.0)
	sep_2t.color = Color(0.55, 0.44, 0.22, 0.8)
	_gauge_2team.add_child(sep_2t)

	_time_label_2t = Label.new()
	_apply_outlined_label(_time_label_2t, 18, Color(1.0, 0.80, 0.26), 4)
	_gauge_2team.add_child(_time_label_2t)

	# 4b. 3-4 Team Compact Blast Door Status Strip (pre-allocated 4 slots, zero runtime allocation)
	_gauge_multi = HBoxContainer.new()
	_gauge_multi.alignment = BoxContainer.ALIGNMENT_CENTER
	_gauge_multi.add_theme_constant_override("separation", 12)
	_gauge_multi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_multi.visible = false
	gauge_stack.add_child(_gauge_multi)

	_door_slots.clear()
	for _i in range(4):
		var slot_box := HBoxContainer.new()
		slot_box.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_box.add_theme_constant_override("separation", 6)
		slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_gauge_multi.add_child(slot_box)

		var tag_lbl := Label.new()
		_apply_outlined_label(tag_lbl, 16, Color.WHITE, 4)
		slot_box.add_child(tag_lbl)

		var d_bar := Panel.new()
		d_bar.custom_minimum_size = Vector2(MULTI_BAR_W, MULTI_BAR_H)
		d_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d_sb := StyleBoxFlat.new()
		d_sb.bg_color = Color(0.09, 0.08, 0.07, 1.0)
		d_sb.border_color = Color(0.55, 0.46, 0.28, 0.90)
		d_sb.set_border_width_all(1)
		d_sb.set_corner_radius_all(0)
		d_bar.add_theme_stylebox_override("panel", d_sb)
		slot_box.add_child(d_bar)

		var d_fill := ColorRect.new()
		d_fill.position = Vector2(1.0, 1.0)
		d_fill.size = Vector2(MULTI_BAR_W - 2.0, MULTI_BAR_H - 2.0)
		d_fill.color = Color(0.8, 0.8, 0.8, 0.85)
		d_bar.add_child(d_fill)

		var status_lbl := Label.new()
		status_lbl.custom_minimum_size = Vector2(46.0, 0.0)
		_apply_outlined_label(status_lbl, 15, Color(0.86, 0.88, 0.78), 4)
		slot_box.add_child(status_lbl)

		_door_slots.append({
			"box": slot_box,
			"tag": tag_lbl,
			"fill": d_fill,
			"status": status_lbl,
			"tag_key": StringName("slot_tag_%d" % _i),
			"st_key": StringName("slot_st_%d" % _i),
		})

	var sep_m := ColorRect.new()
	sep_m.custom_minimum_size = Vector2(2.0, 20.0)
	sep_m.color = Color(0.55, 0.44, 0.22, 0.8)
	_gauge_multi.add_child(sep_m)

	_time_label_multi = Label.new()
	_apply_outlined_label(_time_label_multi, 17, Color(1.0, 0.80, 0.26), 4)
	_gauge_multi.add_child(_time_label_multi)

	# 5. Standalone-only subtle control hint (strictly hidden in official hosted matches & screenshots)
	_hint_label = Label.new()
	_hint_label.anchor_left = 0.0
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.offset_left = 14.0
	_hint_label.offset_right = 720.0
	_hint_label.offset_top = -32.0
	_hint_label.offset_bottom = -8.0
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined_label(_hint_label, 13, Color(0.86, 0.78, 0.62, 0.85), 3)
	_hint_label.text = _loc(
		"[WASD] Move  [Space] Shove/Ram/Valve  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4  [R] Reset",
		"[WASD] 移动  [空格] 推搡/撞车/阀门  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4  [R] 重置",
		"[WASD] 移動  [空白鍵] 推搡/撞車/閥門  [F2] 2v2  [F3] 2v2v2  [F4] 2v2v2v2  [F5] 4v4  [R] 重置"
	)
	_hint_label.visible = false
	root_ctrl.add_child(_hint_label)


func show_countdown(sec: int) -> void:
	if _countdown_label == null or not is_instance_valid(_countdown_label):
		return
	if sec > 0:
		_set_lbl_text(_countdown_label, &"countdown", str(sec))
		_set_lbl_color(_countdown_label, &"countdown", Color(1.0, 0.92, 0.72))
		_countdown_label.visible = true
		_last_countdown_num = sec
	else:
		_set_lbl_text(_countdown_label, &"countdown", _loc("GO!", "开始!", "開始!"))
		_set_lbl_color(_countdown_label, &"countdown", Color(1.0, 0.78, 0.22))
		_countdown_label.visible = true
		_go_flash_expire_ms = Time.get_ticks_msec() + 700
		_last_countdown_num = 0


func show_banner(text: String, col: Color, duration: float = 2.0) -> void:
	if _banner_label == null or not is_instance_valid(_banner_label):
		return
	_set_lbl_text(_banner_label, &"banner", text)
	_set_lbl_color(_banner_label, &"banner", col)
	_banner_label.visible = not text.is_empty()
	_banner_expire_ms = Time.get_ticks_msec() + int(maxf(0.0, duration) * 1000.0)


func update_you_marker(cam: Camera3D, local_pos: Vector3, alive: bool, time_sec: float, active_flag: bool) -> void:
	if _you_marker == null or not is_instance_valid(_you_marker):
		return
	if not active_flag or not alive or cam == null or not is_instance_valid(cam):
		if _you_marker.active:
			_you_marker.active = false
			_you_marker.visible = false
		return
	var center := local_pos + Vector3(0.0, 0.85, 0.0)
	var half := Vector3(0.42, 0.82, 0.42)
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var wp := center + Vector3(sx * half.x, sy * half.y, sz * half.z)
				if cam.is_position_behind(wp):
					_you_marker.active = false
					_you_marker.visible = false
					return
				var sp := cam.unproject_position(wp)
				min_pt.x = minf(min_pt.x, sp.x)
				min_pt.y = minf(min_pt.y, sp.y)
				max_pt.x = maxf(max_pt.x, sp.x)
				max_pt.y = maxf(max_pt.y, sp.y)
	_you_marker.top_left = min_pt
	_you_marker.bound_size = max_pt - min_pt
	var step_idx: int = int(floor(time_sec * 15.0)) % 4
	var jitters: Array = [Vector2(0.5, 0.5), Vector2(-0.5, -0.5), Vector2(-0.5, 0.5), Vector2(0.5, -0.5)]
	_you_marker.shake_offset = jitters[step_idx] as Vector2
	_you_marker.active = true
	_you_marker.visible = true
	_you_marker.queue_redraw()


func _phase_name(phase: int) -> String:
	match clampi(phase, 1, 3):
		1: return _loc("PUSH", "推进", "推進")
		2: return _loc("FUSE", "引信", "引信")
		_: return _loc("OVERLOAD", "过载", "過載")


func _format_clock(time_left: float, prep_left: float, overtime: bool, phase: int) -> String:
	if prep_left > 0.0:
		return "%s %ds" % [_loc("PREP", "准备", "準備"), ceili(prep_left)]
	if overtime:
		return "%s %ds" % [_loc("OT", "加时", "加時"), ceili(maxf(0.0, time_left))]
	var sec: int = ceili(maxf(0.0, time_left))
	return "%02d:%02d | %s" % [sec / 60, sec % 60, _phase_name(phase)]


func update_hud(state: Dictionary) -> void:
	if _layer == null or not is_instance_valid(_layer):
		return

	var active_teams: Array = state.get("active_team_ids", [1, 2]) as Array
	if active_teams.size() < 2:
		active_teams = [1, 2]
	var is_multi: bool = active_teams.size() >= 3
	var cart_x: float = float(state.get("cart_x", 0.0))
	var track_len: float = maxf(0.01, float(state.get("track_len", 11.5)))
	var branch_team: int = int(state.get("cart_branch_team", 0))
	var branch_dist: float = float(state.get("cart_branch_dist", 0.0))
	var door_alive: Dictionary = state.get("door_alive", {}) as Dictionary
	var team_alive_counts: Dictionary = state.get("team_alive_counts", {}) as Dictionary
	var time_left: float = float(state.get("time_left", 75.0))
	var phase: int = int(state.get("phase", 1))
	var overtime: bool = bool(state.get("overtime", false))
	var surge_team: int = int(state.get("surge_team", 0))
	var surge_timer: float = float(state.get("surge_timer", 0.0))
	var prep_left: float = float(state.get("prep_left", 0.0))
	var banner_text: String = str(state.get("banner_text", ""))
	var winner_team: int = int(state.get("winner_team", 0))
	var standalone_mode: bool = bool(state.get("standalone_mode", false))
	var screenshot_mode: bool = bool(state.get("screenshot_mode", false))

	var now_ms: int = Time.get_ticks_msec()
	if _countdown_label != null:
		if prep_left > 0.0:
			var cur_sec: int = ceili(prep_left)
			_set_lbl_text(_countdown_label, &"countdown", str(cur_sec))
			_set_lbl_color(_countdown_label, &"countdown", Color(1.0, 0.92, 0.72))
			_countdown_label.visible = not screenshot_mode
		elif now_ms < _go_flash_expire_ms and not screenshot_mode:
			_countdown_label.visible = true
		else:
			_countdown_label.visible = false

	var clock_text: String = _format_clock(time_left, prep_left, overtime, phase)
	var clock_col: Color = Color(1.0, 0.34, 0.24) if (overtime or (prep_left <= 0.0 and time_left <= 15.0)) else Color(1.0, 0.80, 0.26)

	if _gauge_2team != null and _gauge_multi != null:
		_gauge_2team.visible = not is_multi
		_gauge_multi.visible = is_multi

	if not is_multi:
		var left_tid: int = int(active_teams[0])
		var right_tid: int = int(active_teams[1])
		var left_col: Color = _team_color(left_tid)
		var right_col: Color = _team_color(right_tid)
		var left_alive: int = int(team_alive_counts.get(left_tid, 0))
		var right_alive: int = int(team_alive_counts.get(right_tid, 0))

		if _left_label != null:
			_set_lbl_text(_left_label, &"left", "%s (%d)" % [_team_name(left_tid), left_alive])
			_set_lbl_color(_left_label, &"left", left_col)
		if _right_label != null:
			_set_lbl_text(_right_label, &"right", "%s (%d)" % [_team_name(right_tid), right_alive])
			_set_lbl_color(_right_label, &"right", right_col)

		var norm: float = clampf((cart_x / track_len) * 0.5 + 0.5, 0.0, 1.0)
		var split_x: float = clampf(norm * BAR_WIDTH, 1.0, BAR_WIDTH - 1.0)
		if _left_fill != null:
			_left_fill.color = Color(left_col.r, left_col.g, left_col.b, 0.62)
			_left_fill.size = Vector2(split_x - 1.0, BAR_HEIGHT - 2.0)
		if _right_fill != null:
			_right_fill.color = Color(right_col.r, right_col.g, right_col.b, 0.62)
			_right_fill.position = Vector2(split_x, 1.0)
			_right_fill.size = Vector2(BAR_WIDTH - split_x - 1.0, BAR_HEIGHT - 2.0)
		if _cart_marker != null:
			_cart_marker.position = Vector2(clampf(norm * (BAR_WIDTH - 8.0), 0.0, BAR_WIDTH - 8.0), -3.0)
		if _time_label_2t != null:
			_set_lbl_text(_time_label_2t, &"time_2t", clock_text)
			_set_lbl_color(_time_label_2t, &"time_2t", clock_col)
	else:
		var safe_str: String = _loc("SAFE", "完好", "完好")
		var out_str: String = _loc("OUT", "炸毁", "炸毀")
		for i in range(_door_slots.size()):
			var slot: Dictionary = _door_slots[i] as Dictionary
			var box: HBoxContainer = slot["box"] as HBoxContainer
			if i >= active_teams.size():
				box.visible = false
				continue
			box.visible = true
			var tid: int = int(active_teams[i])
			var tcol: Color = _team_color(tid)
			var intact: bool = bool(door_alive.get(tid, true))
			var tag_lbl: Label = slot["tag"] as Label
			var fill_rect: ColorRect = slot["fill"] as ColorRect
			var st_lbl: Label = slot["status"] as Label
			var tag_key: StringName = slot["tag_key"] as StringName
			var st_key: StringName = slot["st_key"] as StringName

			_set_lbl_text(tag_lbl, tag_key, _team_short(tid))
			if not intact:
				_set_lbl_color(tag_lbl, tag_key, Color(0.45, 0.44, 0.42))
				fill_rect.size = Vector2(0.0, MULTI_BAR_H - 2.0)
				fill_rect.color = Color(0.28, 0.24, 0.22, 0.65)
				_set_lbl_text(st_lbl, st_key, out_str)
				_set_lbl_color(st_lbl, st_key, Color(0.72, 0.42, 0.36))
			elif branch_team == tid and branch_dist > 0.45:
				var threat: float = clampf(branch_dist / track_len, 0.0, 1.0)
				var pct: int = clampi(int(round(threat * 100.0)), 1, 99)
				_set_lbl_color(tag_lbl, tag_key, tcol)
				fill_rect.size = Vector2((MULTI_BAR_W - 2.0) * threat, MULTI_BAR_H - 2.0)
				fill_rect.color = Color(1.0, 0.28, 0.16, 0.95) if threat >= 0.65 else Color(1.0, 0.68, 0.18, 0.95)
				_set_lbl_text(st_lbl, st_key, "%d%%!" % pct)
				_set_lbl_color(st_lbl, st_key, Color(1.0, 0.36, 0.20) if threat >= 0.65 else Color(1.0, 0.78, 0.24))
			else:
				_set_lbl_color(tag_lbl, tag_key, tcol)
				fill_rect.size = Vector2(MULTI_BAR_W - 2.0, MULTI_BAR_H - 2.0)
				fill_rect.color = Color(tcol.r, tcol.g, tcol.b, 0.78)
				_set_lbl_text(st_lbl, st_key, safe_str)
				_set_lbl_color(st_lbl, st_key, Color(0.76, 0.92, 0.74))

		if _time_label_multi != null:
			_set_lbl_text(_time_label_multi, &"time_multi", clock_text)
			_set_lbl_color(_time_label_multi, &"time_multi", clock_col)

	if _surge_label != null:
		if surge_team > 0 and surge_timer > 0.0:
			var scol: Color = _team_color(surge_team)
			_set_lbl_text(_surge_label, &"surge", "%s %s (%.1fs)" % [_team_name(surge_team), _loc("STEAM SURGE!", "蒸汽助推!", "蒸氣助推!"), surge_timer])
			_set_lbl_color(_surge_label, &"surge", scol)
			_surge_label.visible = true
		else:
			_surge_label.visible = false

	if _hint_label != null:
		_hint_label.visible = standalone_mode and not screenshot_mode

	if _banner_label != null:
		if now_ms >= _banner_expire_ms:
			if winner_team > 0:
				var win_msg: String = _team_helper.team_win_banner(winner_team) if (_team_helper != null and _team_helper.has_method("team_win_banner")) else ("%s %s" % [_team_name(winner_team), _loc("WINS!", "获胜!", "獲勝!")])
				_set_lbl_text(_banner_label, &"banner", win_msg)
				_set_lbl_color(_banner_label, &"banner", _team_color(winner_team))
				_banner_label.visible = true
			elif not banner_text.is_empty():
				_set_lbl_text(_banner_label, &"banner", banner_text)
				_set_lbl_color(_banner_label, &"banner", Color(1.0, 0.84, 0.26))
				_banner_label.visible = true
			else:
				_banner_label.visible = false
