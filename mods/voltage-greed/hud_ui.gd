extends RefCounted

## Industrial 0px-radius HUD for Voltage Greed (贪婪电椅 / 貪婪電椅):
## - Top-right kept 100% clear for team-party's HUD
## - Opening YOU corner bracket marker tracking the local player's electric chair
## - Large bold outlined 3-2-1-GO! countdown (Terminal F4 + CJK FontVariation fallback)
## - Centered bold Coach industrial event / slacker callout banner
## - Compact 0px charcoal-steel & amber bottom-center control legend
## - Standalone-only end-of-match CRT summary overlay


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
		var text_point := start_point + dir * 30.0 + Vector2(minf(dir.x, 0.0) * text_size.x, 0.0)
		var line_pts := PackedVector2Array([
			start_point,
			start_point + dir * 30.0,
			start_point + dir * 30.0 + Vector2(dir.x * text_size.x, 0.0),
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
var _ui_font: Font = null
var _num_font: Font = null

var _you_marker: YouMarkerOverlay = null
var _countdown_label: Label = null
var _banner_label: Label = null
var _legend_panel: PanelContainer = null
var _legend_label: Label = null
var _summary_panel: PanelContainer = null
var _summary_title: Label = null
var _summary_body: Label = null

var _cached_legend: String = ""
var _cached_legend_col: Color = Color.TRANSPARENT


static func _loc(en: String, cn: String, tw: String) -> String:
	var low: String = TranslationServer.get_locale().to_lower()
	if low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo"):
		return tw
	if low.begins_with("zh") or low == "zhs":
		return cn
	return en


static func _make_cjk_font() -> Dictionary:
	var raw_font: Font = null
	if ResourceLoader.exists("res://fonts/Terminal F4.ttf"):
		raw_font = ResourceLoader.load("res://fonts/Terminal F4.ttf") as Font
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"PingFang TC", "PingFang SC", "Microsoft JhengHei", "Microsoft YaHei",
		"Noto Sans CJK TC", "Noto Sans CJK SC", "Heiti TC", "Helvetica Neue", "Arial",
	])
	var ui_font: Font = sys
	if raw_font != null:
		var fv := FontVariation.new()
		fv.base_font = raw_font
		fv.fallbacks = [sys]
		ui_font = fv
	return {
		"ui": ui_font,
		"num": raw_font if raw_font != null else ui_font,
	}


static func _make_industrial_panel(bg: Color, border: Color, pad_h: float, pad_v: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _apply_outlined(lbl: Label, size: int, col: Color, outline: int, use_num: bool = false) -> void:
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", outline)
	var f: Font = _num_font if (use_num and _num_font != null) else _ui_font
	if f != null:
		lbl.add_theme_font_override("font", f)


func setup(parent: Node) -> void:
	if parent == null:
		return
	if _layer != null and is_instance_valid(_layer):
		return

	var fonts: Dictionary = _make_cjk_font()
	_ui_font = fonts["ui"] as Font
	_num_font = fonts["num"] as Font

	_layer = CanvasLayer.new()
	_layer.name = "VoltageGreedHud"
	_layer.layer = 10
	parent.add_child(_layer)

	var root_ctrl := Control.new()
	root_ctrl.name = "HudRoot"
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root_ctrl)

	# 1. Opening YOU corner bracket
	_you_marker = YouMarkerOverlay.new()
	_you_marker.name = "YouMarkerOverlay"
	_you_marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_you_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_you_marker.marker_font = _ui_font
	_you_marker.marker_text = _loc("YOU", "你", "你")
	_you_marker.visible = false
	root_ctrl.add_child(_you_marker)

	# 2. Large centered outlined 3-2-1-GO! countdown
	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined(_countdown_label, 76, Color(1.0, 0.90, 0.56), 14, true)
	_countdown_label.visible = false
	root_ctrl.add_child(_countdown_label)

	# 3. Centered bold Coach event / slacker callout banner (upper-middle, clear of top-right team-party HUD)
	_banner_label = Label.new()
	_banner_label.name = "CoachBannerLabel"
	_banner_label.anchor_left = 0.10
	_banner_label.anchor_right = 0.90
	_banner_label.anchor_top = 0.12
	_banner_label.anchor_bottom = 0.22
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined(_banner_label, 32, Color(1.0, 0.82, 0.24), 10)
	_banner_label.visible = false
	root_ctrl.add_child(_banner_label)

	# 4. Compact 0px charcoal-steel & amber bottom-center key legend
	var bottom_center := CenterContainer.new()
	bottom_center.name = "BottomLegendCenter"
	bottom_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_center.offset_top = -54.0
	bottom_center.offset_bottom = -12.0
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(bottom_center)

	_legend_panel = _make_industrial_panel(Color(0.04, 0.04, 0.035, 0.90), Color(0.95, 0.68, 0.20, 0.92), 16.0, 6.0)
	_legend_panel.name = "KeyLegendPanel"
	_legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_center.add_child(_legend_panel)

	_legend_label = Label.new()
	_legend_label.name = "KeyLegendLabel"
	_legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legend_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_legend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_outlined(_legend_label, 18, Color(1.0, 0.86, 0.42), 4)
	_legend_panel.add_child(_legend_label)
	set_key_legend(false, false, false, true)

	# 5. Standalone end-of-match CRT summary overlay
	_summary_panel = _make_industrial_panel(Color(0.03, 0.04, 0.03, 0.96), Color(0.95, 0.68, 0.22, 0.92), 24.0, 18.0)
	_summary_panel.name = "StandaloneSummaryPanel"
	_summary_panel.anchor_left = 0.5
	_summary_panel.anchor_right = 0.5
	_summary_panel.anchor_top = 0.5
	_summary_panel.anchor_bottom = 0.5
	_summary_panel.offset_left = -260.0
	_summary_panel.offset_right = 260.0
	_summary_panel.offset_top = -155.0
	_summary_panel.offset_bottom = 155.0
	_summary_panel.visible = false
	root_ctrl.add_child(_summary_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_summary_panel.add_child(vbox)

	_summary_title = Label.new()
	_summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_outlined(_summary_title, 28, Color(1.0, 0.80, 0.26), 5)
	vbox.add_child(_summary_title)

	_summary_body = Label.new()
	_summary_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_outlined(_summary_body, 19, Color(0.84, 0.92, 0.78), 4)
	vbox.add_child(_summary_body)


func set_you_marker(camera: Camera3D, world_pos: Vector3, visible: bool) -> void:
	if _you_marker == null or not is_instance_valid(_you_marker):
		return
	if not visible or camera == null or not is_instance_valid(camera):
		if _you_marker.active or _you_marker.visible:
			_you_marker.active = false
			_you_marker.visible = false
		return

	var center := world_pos + Vector3(0.0, 0.95, 0.0)
	var half := Vector3(0.48, 0.92, 0.48)
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
	var tick_idx: int = int(Time.get_ticks_msec() / 66) % 4
	var jitters: Array[Vector2] = [Vector2(0.5, 0.5), Vector2(-0.5, -0.5), Vector2(-0.5, 0.5), Vector2(0.5, -0.5)]
	_you_marker.shake_offset = jitters[tick_idx]
	_you_marker.active = true
	_you_marker.visible = true
	_you_marker.queue_redraw()


func set_countdown(text: String, visible: bool) -> void:
	if _countdown_label == null or not is_instance_valid(_countdown_label):
		return
	if not visible or text.is_empty():
		_countdown_label.visible = false
		return
	if _countdown_label.text != text:
		_countdown_label.text = text
	var is_go: bool = text.to_upper().contains("GO") or text.contains("开始") or text.contains("開始")
	var col: Color = Color(1.0, 0.78, 0.22) if is_go else Color(1.0, 0.92, 0.68)
	_countdown_label.add_theme_color_override("font_color", col)
	_countdown_label.visible = true


func set_banner(text: String, color: Color, visible: bool) -> void:
	if _banner_label == null or not is_instance_valid(_banner_label):
		return
	if not visible or text.is_empty():
		_banner_label.visible = false
		return
	if _banner_label.text != text:
		_banner_label.text = text
	_banner_label.add_theme_color_override("font_color", color)
	_banner_label.visible = true


func set_key_legend(holding: bool, bailed: bool, kick_used: bool, alive: bool) -> void:
	if _legend_label == null or not is_instance_valid(_legend_label):
		return
	var txt: String = ""
	var col: Color = Color(1.0, 0.86, 0.42)
	if not alive:
		txt = _loc("ELIMINATED — WATCHING SURVIVORS", "已淘汰 — 观战中", "已淘汰 — 觀戰中")
		col = Color(0.88, 0.34, 0.28)
	elif bailed:
		txt = _loc("SAFE — VISOR LOCKED FOR ROUND", "已收手 — 本轮锁定安全分数", "已收手 — 本輪鎖定安全分數")
		col = Color(0.52, 0.94, 0.56)
	elif holding:
		if kick_used:
			txt = _loc("HOLDING [SPACE] FARMING KPI   ·   [RELEASE] BANK SCORE", "按住 [空格] 刷取KPI   ·   [松开] 锁定收手", "按住 [空白鍵] 刷取KPI   ·   [放開] 鎖定收手")
		else:
			txt = _loc("FARMING KPI   ·   [RELEASE SPACE] BANK   ·   [S] +12% KICK!", "正在发电   ·   [松开空格] 锁定收手   ·   [S] +12% 加压踢闸!", "正在發電   ·   [放開空白鍵] 鎖定收手   ·   [S] +12% 加壓踢閘!")
		col = Color(1.0, 0.78, 0.22)
	else:
		txt = _loc("HOLD [SPACE] FARM KPI   ·   RELEASE BANK   ·   [S] +12% KICK (LIVE ONLY)", "按住 [空格] 刷KPI   ·   松开锁定   ·   [S] +12% 踢闸(仅限接通中)", "按住 [空白鍵] 刷KPI   ·   放開鎖定   ·   [S] +12% 踢閘(僅限接通中)")
		col = Color(0.95, 0.86, 0.64)

	if _cached_legend != txt:
		_cached_legend = txt
		_legend_label.text = txt
	if not _cached_legend_col.is_equal_approx(col):
		_cached_legend_col = col
		_legend_label.add_theme_color_override("font_color", col)


func show_summary(title: String, rows: Array, visible: bool) -> void:
	if _summary_panel == null or not is_instance_valid(_summary_panel):
		return
	if not visible:
		_summary_panel.visible = false
		return
	if _summary_title != null and is_instance_valid(_summary_title):
		_summary_title.text = title
	if _summary_body != null and is_instance_valid(_summary_body):
		var lines: Array[String] = []
		for idx in range(rows.size()):
			var item = rows[idx]
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				if d.has("kpi"):
					var rnk: int = int(d.get("rank", idx + 1))
					var nick: String = str(d.get("nickname", "P%d" % rnk))
					var ttag: String = str(d.get("team_tag", ""))
					var kpi_val: int = int(d.get("kpi", 0))
					var is_alive: bool = bool(d.get("alive", true))
					var lives_cnt: int = int(d.get("lives", 0))
					var you_tag: String = _loc(" (YOU)", " (你)", " (你)") if bool(d.get("is_local", false)) else ""
					var life_str: String = ("%d♥" % lives_cnt) if is_alive else _loc("OUT", "淘汰", "淘汰")
					var prefix: String = ("%s " % ttag) if not ttag.is_empty() else ""
					lines.append("#%d  %s%s%s  —  %d KPI  [%s]" % [rnk, prefix, nick, you_tag, kpi_val, life_str])
				else:
					var label_str: String = str(d.get("label", d.get("name", "#%d" % (idx + 1))))
					if d.has("score"):
						lines.append("%s  —  %s" % [label_str, str(d["score"])])
					else:
						lines.append(label_str)
			else:
				lines.append(str(item))
		_summary_body.text = "\n".join(lines)
	_summary_panel.visible = true
