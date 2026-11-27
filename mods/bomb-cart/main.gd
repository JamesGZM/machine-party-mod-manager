extends Node

## MPML API v2 Entry Point for Bomb Cart (炸彈推車).
## Uses mpm-core Hub v2 dynamic slot allocation (>= 1000) with 2-4 team team_only admission.

const MOD_ID := "bomb-cart"
const REG_RES_DIR := "res://mods_bomb_cart/"
const DEFAULT_ROUNDS := 1

var _loader = null
var _mod_dir: String = ""
var _slot_id: int = -1
var _config_script = null
var _meshes_script = null
var _game_script = null
var _official_script: GDScript = null
var _registered_scripts: Dictionary = {}
var _packed_minigame_scene: PackedScene = null
var _icon_texture: Texture2D = null


static func _pick_loc(en: String, cn: String, tw: String) -> String:
	var low: String = TranslationServer.get_locale().to_lower()
	if low == "zht" or low.contains("tw") or low.contains("hk") or low.contains("hant") or low.contains("mo"):
		return tw
	if low.begins_with("zh") or low == "zhs":
		return cn
	return en


static func _display_name() -> String:
	return _pick_loc("BOMB CART", "炸弹推车", "炸彈推車")


static func _brief_content() -> String:
	return _pick_loc(
		"2-4 Team 75s adaptive rail assault! Step inside the 2.6m Push Aura to drive the Bomb Cart into a rival Blast Door (Straight rail for 2 teams, Y-turntable for 3, Cross-turntable for 4).\nFlank Steam Valves for a 2.5s Rocket Surge. Beware the 40s Shockwave Pulse & 60s Critical Overload!\n[WASD / Arrows] Move & Push  |  [Space] Shove rivals (no friendly fire) / Power Ram cart / Quick Valve Slam.",
		"2–4 队 75 秒自适应轨道攻防！进入 2.6 米推进光环即可将炸弹推车压向敌方防爆门（2 队直轨拔河、3 队 Y 型转盘、4 队十字转盘）。\n抢占侧翼蒸汽阀门触发 2.5 秒火箭助推！注意 40 秒震荡脉冲与 60 秒临界过载！\n[WASD / 方向键] 移动推进  |  [空格] 推搡敌人（友军免伤）/ 强力撞车 / 拍阀增压。",
		"2–4 隊 75 秒自適應軌道攻防！進入 2.6 公尺推進光環即可將炸彈推車壓向敵方防爆門（2 隊直軌拔河、3 隊 Y 型轉盤、4 隊十字轉盤）。\n搶佔側翼蒸氣閥門觸發 2.5 秒火箭助推！注意 40 秒震盪脈衝與 60 秒臨界過載！\n[WASD / 方向鍵] 移動推進  |  [空白鍵] 推搡敵人（友軍免傷）/ 強力撞車 / 拍閥增壓。"
	)


static func _controls_data() -> Array:
	return [
		{
			"control_text": _pick_loc("MOVE / PUSH [WASD / ARROWS]", "移动 / 推进 [WASD / 方向键]", "移動 / 推進 [WASD / 方向鍵]"),
			"controller_text": "MOVE",
			"keyboard_icons": ["KeyboardW"],
			"controller_icons": ["ControllerLeftStick"],
		},
		{
			"control_text": _pick_loc("SHOVE / RAM / VALVE [SPACE]", "推搡 / 撞车 / 拍阀 [空格]", "推搡 / 撞車 / 拍閥 [空白鍵]"),
			"controller_text": "ACTION",
			"keyboard_icons": ["KeyboardSpace"],
			"controller_icons": ["ControllerFaceSouth"],
		},
	]


func _mod_init(loader) -> void:
	_loader = loader
	_mod_dir = str(loader.dir_of(MOD_ID))
	_try_register(loader)


func _mod_ready(loader) -> void:
	_loader = loader
	if _mod_dir.is_empty():
		_mod_dir = str(loader.dir_of(MOD_ID))
	if _packed_minigame_scene == null:
		_try_register(loader)
	else:
		_register_into_hub(loader)
	_ensure_default_playlist_entry()


func _try_register(loader) -> void:
	if _packed_minigame_scene != null:
		return
	_official_script = loader.compile(_mod_dir.path_join("official_minigame.gd"))
	_register_mod_scripts(loader)
	if not _prepare_packed_minigame_scene():
		return
	if _meshes_script != null and _meshes_script.has_method("build_bomb_cart_icon"):
		_icon_texture = _meshes_script.build_bomb_cart_icon() as Texture2D

	_register_into_hub(loader)

	if loader.has_method("on_lobby"):
		loader.on_lobby(func(_lobby): _ensure_default_playlist_entry())
	if loader.has_method("on_scene_script"):
		loader.on_scene_script("res://scripts/scenes/game/game.gd", _on_game_entered)
		loader.on_scene_script("res://scenes/local_game/script/local_game.gd", _on_game_entered)

	if loader.has_method("has_api") and bool(loader.call("has_api", "registry")):
		var reg = loader.registry("minigames")
		if reg is Dictionary:
			(reg as Dictionary)[MOD_ID] = REG_RES_DIR + "bomb_cart_game.gd"

	loader.note("%s: initialized via mpm-core Hub v2 (slot=%d, mode=team_only, teams=2..4)" % [MOD_ID, _slot_id])


func _register_mod_scripts(loader) -> void:
	var helper_files: Array[String] = [
		"config.gd",
		"arena_meshes.gd",
		"team_support.gd",
		"fx_pool.gd",
		"hud_ui.gd",
		"ai_controller.gd",
		"self_test.gd",
		"bomb_cart_game.gd",
	]
	var use_register_api := false
	if loader.has_method("has_api"):
		use_register_api = bool(loader.call("has_api", "register_script"))
	if use_register_api and loader.has_method("register_script"):
		for rel in helper_files:
			var res_path: String = REG_RES_DIR + rel
			loader.register_script(MOD_ID, rel, res_path)
			_registered_scripts[rel] = ResourceLoader.load(res_path)
	elif loader.has_method("compile"):
		for rel in helper_files:
			var gd = loader.compile(_mod_dir.path_join(rel))
			if gd != null:
				gd.take_over_path(REG_RES_DIR + rel)
				_registered_scripts[rel] = gd
	_config_script = _registered_scripts.get("config.gd", null)
	_meshes_script = _registered_scripts.get("arena_meshes.gd", null)
	_game_script = _registered_scripts.get("bomb_cart_game.gd", null)


func _prepare_packed_minigame_scene() -> bool:
	if _game_script == null or _official_script == null or _meshes_script == null or _config_script == null:
		_loader.note(MOD_ID + ": missing runtime script, skipping registration")
		return false
	var dummy_root: Node = _official_script.new()
	dummy_root.name = "BombCart"
	var stage: Node3D = _game_script.new()
	stage.name = "Stage"
	dummy_root.add_child(stage)
	stage.owner = dummy_root

	var packed := PackedScene.new()
	var err: int = packed.pack(dummy_root)
	dummy_root.free()
	if err != OK:
		_loader.note(MOD_ID + ": failed to pack BombCart scene, err=" + str(err))
		return false
	_packed_minigame_scene = packed
	return true


func _register_into_hub(loader) -> void:
	var spec := {
		"mod_id": MOD_ID,
		"scene_path": "",
		"packed_scene": _packed_minigame_scene,
		"icon_texture": _icon_texture,
		"default_rounds": DEFAULT_ROUNDS,
		"display_name": Callable(self, "_display_name"),
		"brief_content": Callable(self, "_brief_content"),
		"controls_data": Callable(self, "_controls_data"),
		"admission": {
			"mode_support": "team_only",
			"min_teams": 2,
			"max_teams": 4,
			"min_total_players": 2,
			"min_players_per_team": 1,
			"allow_local_couch": false,
		},
	}
	if _slot_id > 0:
		spec["slot_id"] = _slot_id
	if Engine.has_meta(&"mpm_core"):
		var core = Engine.get_meta(&"mpm_core")
		if core is Dictionary:
			var sdk = (core as Dictionary).get("minigame_sdk", null)
			if sdk != null and sdk.has_method("register_minigame"):
				var res = sdk.register_minigame(spec, loader)
				if res is Dictionary and bool((res as Dictionary).get("ok", false)):
					_slot_id = int((res as Dictionary).get("slot_id", -1))
					return
	# Fallback if mpm-core is absent in isolated unit test
	var custom_map: Dictionary = {}
	if loader != null and loader.has_method("registry"):
		var raw = loader.registry("custom_minigames")
		if raw is Dictionary:
			custom_map = raw as Dictionary
	if _slot_id <= 0:
		_slot_id = 1000
		while custom_map.has(_slot_id):
			_slot_id += 1
	spec["slot_id"] = _slot_id
	custom_map[_slot_id] = spec
	Engine.set_meta("_mpm_custom_minigames", custom_map)


func _get_globals_node() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("Globals")


func _ensure_default_playlist_entry() -> void:
	if _packed_minigame_scene == null or _slot_id <= 0:
		return
	var glb := _get_globals_node()
	if glb == null:
		return
	var default_pl = glb.get("default_playlist")
	if default_pl is Array:
		var has_slot := false
		for item in default_pl:
			if item != null and int(item.get("game_identifier")) == _slot_id:
				has_slot = true
				break
		if not has_slot and ResourceLoader.exists("res://scripts/resources/minigame_list_resource.gd"):
			var mlr_script = ResourceLoader.load("res://scripts/resources/minigame_list_resource.gd")
			if mlr_script != null:
				var mlr = mlr_script.new()
				mlr.set("game_identifier", _slot_id)
				mlr.set("total_rounds", DEFAULT_ROUNDS)
				default_pl.append(mlr)


func _on_game_entered(game_node: Node) -> void:
	if game_node == null or _packed_minigame_scene == null:
		return
	_ensure_default_playlist_entry()


func _exit_tree() -> void:
	if Engine.has_meta(&"mpm_core"):
		var core = Engine.get_meta(&"mpm_core")
		if core is Dictionary:
			var sdk = (core as Dictionary).get("minigame_sdk", null)
			if sdk != null and sdk.has_method("unregister_minigame"):
				sdk.unregister_minigame(MOD_ID, _loader)
	if Engine.has_meta("_mpm_custom_minigames") and _slot_id > 0:
		var custom_map = Engine.get_meta("_mpm_custom_minigames")
		if custom_map is Dictionary:
			(custom_map as Dictionary).erase(_slot_id)
			if (custom_map as Dictionary).is_empty():
				Engine.remove_meta("_mpm_custom_minigames")
	_registered_scripts.clear()
	_config_script = null
	_meshes_script = null
	_game_script = null
	_official_script = null
	_packed_minigame_scene = null
	_icon_texture = null
