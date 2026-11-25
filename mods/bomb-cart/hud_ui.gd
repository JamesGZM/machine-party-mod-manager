extends RefCounted

## HUD overlay for Bomb Cart (炸彈推車):
## Top tug-of-war rail bar (RED [===💣===] BLUE), timer, phase badge,
## Rocket Surge indicator, and event banners.

const BAR_WIDTH := 300.0
const BAR_HEIGHT := 22.0
const MARKER_SIZE := 24.0

var _layer: CanvasLayer = null
var _locale_pick: Callable = Callable()

var _red_label: Label = null
var _blue_label: Label = null
var _timer_label: Label = null
var _phase_label: Label = null
var _surge_label: Label = null
var _banner_label: Label = null
var _hint_label: Label = null

var _bar_bg: Panel = null
var _red_fill: ColorRect = null
var _blue_fill: ColorRect = null
var _cart_marker: Panel = null

var _banner_expire_ms: int = 0


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


func setup(parent: Node, locale_pick: Callable) -> void:
	_locale_pick = locale_pick
	if _layer != null and is_instance_valid(_layer):
		return
	if parent == null:
		return

	var ui_font: Font = null
	if ResourceLoader.exists("res://fonts/Terminal F4.ttf"):
		ui_font = ResourceLoader.load("res://fonts/Terminal F4.ttf") as Font

	_layer = CanvasLayer.new()
	_layer.name = "BombCartHud"
	_layer.layer = 10
	parent.add_child(_layer)

	var top_panel := PanelContainer.new()
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.anchor_top = 0.0
	top_panel.offset_left = -410.0
	top_panel.offset_right = 410.0
	top_panel.offset_top = 12.0
	top_panel.offset_bottom = 66.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.88)
	sb.border_color = Color(0.32, 0.42, 0.56, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	top_panel.add_theme_stylebox_override("panel", sb)
	_layer.add_child(top_panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	top_panel.add_child(hbox)

	_red_label = Label.new()
	_red_label.add_theme_font_size_override("font_size", 18)
	if ui_font != null:
		_red_label.add_theme_font_override("font", ui_font)
	_red_label.modulate = Color(1.0, 0.36, 0.32)
	_red_label.text = _loc("RED", "红队", "紅隊")
	hbox.add_child(_red_label)

	_bar_bg = Panel.new()
	_bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	bar_sb.border_color = Color(0.42, 0.48, 0.58, 0.9)
	bar_sb.set_border_width_all(1)
	bar_sb.set_corner_radius_all(4)
	_bar_bg.add_theme_stylebox_override("panel", bar_sb)
	hbox.add_child(_bar_bg)

	_red_fill = ColorRect.new()
	_red_fill.color = Color(0.95, 0.25, 0.22, 0.55)
	_red_fill.position = Vector2(2.0, 2.0)
	_red_fill.size = Vector2(BAR_WIDTH * 0.5 - 2.0, BAR_HEIGHT - 4.0)
	_bar_bg.add_child(_red_fill)

	_blue_fill = ColorRect.new()
	_blue_fill.color = Color(0.22, 0.62, 0.98, 0.55)
	_blue_fill.position = Vector2(BAR_WIDTH * 0.5, 2.0)
	_blue_fill.size = Vector2(BAR_WIDTH * 0.5 - 2.0, BAR_HEIGHT - 4.0)
	_bar_bg.add_child(_blue_fill)

	var mid_tick := ColorRect.new()
	mid_tick.color = Color(1.0, 0.92, 0.45, 0.85)
	mid_tick.position = Vector2(BAR_WIDTH * 0.5 - 1.0, 0.0)
	mid_tick.size = Vector2(2.0, BAR_HEIGHT)
	_bar_bg.add_child(mid_tick)

	_cart_marker = Panel.new()
	_cart_marker.position = Vector2(BAR_WIDTH * 0.5 - 6.0, -3.0)
	_cart_marker.size = Vector2(12.0, BAR_HEIGHT + 6.0)
	var mk_sb := StyleBoxFlat.new()
	mk_sb.bg_color = Color(1.0, 0.84, 0.24, 1.0)
	mk_sb.border_color = Color(0.08, 0.10, 0.14, 1.0)
	mk_sb.set_border_width_all(2)
	mk_sb.set_corner_radius_all(3)
	_cart_marker.add_theme_stylebox_override("panel", mk_sb)
	_bar_bg.add_child(_cart_marker)

	var needle_core := ColorRect.new()
	needle_core.color = Color(1.0, 0.98, 0.86, 1.0)
	needle_core.position = Vector2(4.0, 3.0)
	needle_core.size = Vector2(4.0, BAR_HEIGHT)
	_cart_marker.add_child(needle_core)

	_blue_label = Label.new()
	_blue_label.add_theme_font_size_override("font_size", 18)
	if ui_font != null:
		_blue_label.add_theme_font_override("font", ui_font)
	_blue_label.modulate = Color(0.32, 0.72, 1.0)
	_blue_label.text = _loc("BLUE", "蓝队", "藍隊")
	hbox.add_child(_blue_label)

	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 22)
	if ui_font != null:
		_timer_label.add_theme_font_override("font", ui_font)
	_timer_label.modulate = Color(1.0, 0.90, 0.35)
	_timer_label.text = "75s"
	hbox.add_child(_timer_label)

	_phase_label = Label.new()
	_phase_label.add_theme_font_size_override("font_size", 15)
	if ui_font != null:
		_phase_label.add_theme_font_override("font", ui_font)
	_phase_label.modulate = Color(0.78, 0.86, 0.95)
	_phase_label.text = "P1"
	hbox.add_child(_phase_label)

	_surge_label = Label.new()
	_surge_label.anchor_left = 0.5
	_surge_label.anchor_right = 0.5
	_surge_label.anchor_top = 0.0
	_surge_label.offset_left = -240.0
	_surge_label.offset_right = 240.0
	_surge_label.offset_top = 70.0
	_surge_label.offset_bottom = 98.0
	_surge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_surge_label.add_theme_font_size_override("font_size", 18)
	if ui_font != null:
		_surge_label.add_theme_font_override("font", ui_font)
	_surge_label.visible = false
	_layer.add_child(_surge_label)

	_banner_label = Label.new()
	_banner_label.anchor_left = 0.5
	_banner_label.anchor_right = 0.5
	_banner_label.anchor_top = 0.0
	_banner_label.offset_left = -380.0
	_banner_label.offset_right = 380.0
	_banner_label.offset_top = 104.0
	_banner_label.offset_bottom = 152.0
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 28)
	if ui_font != null:
		_banner_label.add_theme_font_override("font", ui_font)
	_banner_label.modulate = Color(1.0, 0.88, 0.35)
	_banner_label.visible = false
	_layer.add_child(_banner_label)

	_hint_label = Label.new()
	_hint_label.anchor_left = 0.0
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.offset_left = 14.0
	_hint_label.offset_right = 560.0
	_hint_label.offset_top = -34.0
	_hint_label.offset_bottom = -10.0
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.modulate = Color(0.75, 0.82, 0.90, 0.85)
	if ui_font != null:
		_hint_label.add_theme_font_override("font", ui_font)
	_hint_label.text = _loc(
		"[WASD] Move  [Space] Shove / Ram / Valve",
		"[WASD] 移动  [空格] 推搡/冲撞/阀门",
		"[WASD] 移動  [空白鍵] 推搡/衝撞/閥門"
	)
	_layer.add_child(_hint_label)


func show_banner(text: String, col: Color, duration: float = 2.0) -> void:
	if _banner_label == null or not is_instance_valid(_banner_label):
		return
	_banner_label.text = text
	_banner_label.modulate = col
	_banner_label.visible = not text.is_empty()
	_banner_expire_ms = Time.get_ticks_msec() + int(maxf(0.0, duration) * 1000.0)


func update_hud(state: Dictionary) -> void:
	if _layer == null or not is_instance_valid(_layer):
		return

	var cart_x: float = float(state.get("cart_x", 0.0))
	var track_half: float = maxf(0.01, float(state.get("track_half", 11.5)))
	var time_left: float = float(state.get("time_left", 75.0))
	var phase: int = int(state.get("phase", 1))
	var overtime: bool = bool(state.get("overtime", false))
	var surge_team: int = int(state.get("surge_team", 0))
	var surge_timer: float = float(state.get("surge_timer", 0.0))
	var prep_left: float = float(state.get("prep_left", 0.0))
	var banner_text: String = str(state.get("banner_text", ""))
	var winner_team: int = int(state.get("winner_team", -1))
	var red_count: int = int(state.get("red_count", 0))
	var blue_count: int = int(state.get("blue_count", 0))

	if _red_label != null:
		_red_label.text = "%s (%d)" % [_loc("RED", "红队", "紅隊"), red_count]
	if _blue_label != null:
		_blue_label.text = "%s (%d)" % [_loc("BLUE", "蓝队", "藍隊"), blue_count]

	var norm: float = clampf((cart_x / track_half) * 0.5 + 0.5, 0.0, 1.0)
	var marker_x: float = norm * (BAR_WIDTH - 12.0)
	if _cart_marker != null:
		_cart_marker.position = Vector2(marker_x, -3.0)
	if _red_fill != null and _blue_fill != null:
		var split_x: float = clampf(norm * BAR_WIDTH, 2.0, BAR_WIDTH - 2.0)
		_red_fill.size = Vector2(split_x - 2.0, BAR_HEIGHT - 4.0)
		_blue_fill.position = Vector2(split_x, 2.0)
		_blue_fill.size = Vector2(BAR_WIDTH - split_x - 2.0, BAR_HEIGHT - 4.0)

	if _timer_label != null:
		if prep_left > 0.0:
			_timer_label.text = "%ds" % ceili(prep_left)
			_timer_label.modulate = Color(0.55, 0.92, 1.0)
		elif overtime:
			_timer_label.text = "OT %ds" % ceili(maxf(0.0, time_left))
			_timer_label.modulate = Color(1.0, 0.35, 0.25)
		else:
			_timer_label.text = "%ds" % ceili(maxf(0.0, time_left))
			_timer_label.modulate = Color(1.0, 0.38, 0.28) if time_left <= 15.0 else Color(1.0, 0.90, 0.35)

	if _phase_label != null:
		if prep_left > 0.0:
			_phase_label.text = _loc("PREP", "准备", "準備")
			_phase_label.modulate = Color(0.55, 0.92, 1.0)
		elif overtime:
			_phase_label.text = _loc("SUDDEN DEATH", "突然死亡", "驟死賽")
			_phase_label.modulate = Color(1.0, 0.38, 0.28)
		elif phase == 3:
			_phase_label.text = _loc("P3 OVERLOAD", "P3 过载", "P3 過載")
			_phase_label.modulate = Color(1.0, 0.32, 0.26)
		elif phase == 2:
			_phase_label.text = _loc("P2 FUSE", "P2 引爆", "P2 引爆")
			_phase_label.modulate = Color(1.0, 0.72, 0.24)
		else:
			_phase_label.text = _loc("P1 PUSH", "P1 推进", "P1 推進")
			_phase_label.modulate = Color(0.78, 0.86, 0.95)

	if _surge_label != null:
		if surge_team > 0 and surge_timer > 0.0:
			var t_str: String = _loc("RED", "红队", "紅隊") if surge_team == 1 else _loc("BLUE", "蓝队", "藍隊")
			_surge_label.text = "%s %s (%.1fs)" % [t_str, _loc("STEAM SURGE!", "蒸汽加速!", "蒸汽加速!"), surge_timer]
			_surge_label.modulate = Color(1.0, 0.38, 0.32) if surge_team == 1 else Color(0.32, 0.72, 1.0)
			_surge_label.visible = true
		else:
			_surge_label.visible = false

	if _hint_label != null:
		_hint_label.visible = not bool(state.get("screenshot_mode", false))

	if _banner_label != null:
		var now_ms: int = Time.get_ticks_msec()
		if now_ms >= _banner_expire_ms:
			if winner_team == 1:
				_banner_label.text = _loc("RED TEAM WINS!", "红队获胜!", "紅隊獲勝!")
				_banner_label.modulate = Color(1.0, 0.36, 0.32)
				_banner_label.visible = true
			elif winner_team == 2:
				_banner_label.text = _loc("BLUE TEAM WINS!", "蓝队获胜!", "藍隊獲勝!")
				_banner_label.modulate = Color(0.32, 0.72, 1.0)
				_banner_label.visible = true
			elif not banner_text.is_empty():
				_banner_label.text = banner_text
				_banner_label.modulate = Color(1.0, 0.88, 0.35)
				_banner_label.visible = true
			else:
				_banner_label.visible = false
