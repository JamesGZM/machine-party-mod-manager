import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { copyFile, mkdir, mkdtemp, readdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const local = p => fileURLToPath(new URL(p, import.meta.url));
const bundled = local("../../.agent/mod-dev/tools/Godot.app/Contents/MacOS/Godot");
const godot = process.env.GODOT_BIN || (existsSync(bundled) ? bundled : "godot");

test("bomb-cart integrates with mpm-core 2-4 team admission gating and team-party scoring/HUD", {
  skip: !!spawnSync(godot, ["--version"]).error && "Godot unavailable"
}, async t => {
  const project = await mkdtemp(path.join(os.tmpdir(), "bomb-cart-team-"));
  t.after(() => rm(project, { recursive: true, force: true }));

  for (const modId of ["mpm-core", "team-party", "bomb-cart"]) {
    await mkdir(path.join(project, "mods", modId), { recursive: true });
    const srcDir = local(`../../mods/${modId}`);
    for (const name of await readdir(srcDir)) {
      if (name.endsWith(".gd") || name === "mod.json") {
        await copyFile(path.join(srcDir, name), path.join(project, "mods", modId, name));
      }
    }
  }

  await mkdir(path.join(project, "scripts/resources"), { recursive: true });
  await mkdir(path.join(project, "scripts/scenes/game"), { recursive: true });
  await mkdir(path.join(project, "scenes/local_game/script"), { recursive: true });
  await mkdir(path.join(project, "scenes/lobby/components"), { recursive: true });
  await mkdir(path.join(project, "minigames/intermission_new/components"), { recursive: true });
  const fixtures = {
    "project.godot": [
      "config_version=5",
      "[application]",
      'config/name="BombCartTeamTest"',
      'config/features=PackedStringArray("4.5")',
      "[autoload]",
      'Globals="*res://globals.gd"',
      'GameManager="*res://manager.gd"',
      'PlayerManager="*res://players.gd"',
      'NetworkManager="*res://network.gd"',
      'DecalManager="*res://decal_manager.gd"',
      'PropManager="*res://prop_manager.gd"',
      ""
    ].join("\n"),
    "globals.gd": [
      "extends Node",
      "enum MinigameIdentifier { ChiselGauntlet = 0, EMPTY = 20 }",
      "const CustomMinigamesWhitelist: Array[MinigameIdentifier] = [MinigameIdentifier.ChiselGauntlet]",
      "const CutsceneMinigameIdentifiers: Array[MinigameIdentifier] = []",
      "const CutsceneGlitchedPickerMinigameIdentifiers: Array[MinigameIdentifier] = []",
      "const MinigamePaths: Dictionary[MinigameIdentifier, String] = {}",
      "const MinigameIconPaths: Dictionary[MinigameIdentifier, String] = {}",
      "var default_playlist: Array = []",
      "var session_playlist: Array = []",
      "var all_minigames_finished: bool = false",
      "var current_minigame_identifier: MinigameIdentifier = MinigameIdentifier.EMPTY",
      "var game_settings: Dictionary = {}",
      ""
    ].join("\n"),
    "manager.gd": [
      "extends Node",
      "signal minigame_loaded(id)",
      "var local_game: bool = false",
      "var can_set_cursor: bool = true",
      "var custom_game: bool = false",
      "var arcade_game: bool = false",
      "var custom_shuffled: bool = false",
      "var current_minigame_identifier: int = 0",
      ""
    ].join("\n"),
    "players.gd": [
      "extends Node",
      "var player_presences: Dictionary = {1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {}, 8: {}}",
      ""
    ].join("\n"),
    "decal_manager.gd": "extends Node\n@rpc func clear_rpc(): pass\n",
    "prop_manager.gd": "extends Node\n@rpc func clear_rpc(): pass\n",
    "network.gd": [
      "extends Node",
      "signal on_peer_connected(id)",
      "var active_backend: Dictionary = {\"self_data\": {}, \"connected_players\": {1: {\"name\": \"A1\"}, 2: {\"name\": \"A2\"}, 3: {\"name\": \"B1\"}, 4: {\"name\": \"B2\"}, 5: {\"name\": \"G1\"}, 6: {\"name\": \"G2\"}, 7: {\"name\": \"Y1\"}, 8: {\"name\": \"Y2\"}}}",
      ""
    ].join("\n"),
    "minigame_stub.gd": [
      "extends Node",
      "class_name Minigame",
      "signal host_loaded",
      "signal minigame_loaded",
      "signal minigame_ready(id)",
      "signal minigame_finished(id)",
      "signal player_scored(id, s)",
      "signal player_scores_finalized(scores)",
      "signal debug_player_specifics_initialized",
      "signal before_player_marker_show",
      "var round_number: int = 1",
      "var total_rounds: int = 1",
      "var players_loaded: Array = []",
      "var is_all_player_loaded: bool = false",
      "@rpc func cleanup_rpc(): pass",
      ""
    ].join("\n"),
    "state_machine_stub.gd": "extends Node\nclass_name StateMachine\nvar initial_state: NodePath\n",
    "state_stub.gd": "extends Node\nclass_name State\n",
    "minigame_list_item.gd": "extends Node\nclass_name MinigameListItem\nenum BehaviourType { All, Selected }\nvar minigame_identifier: int = 0\nvar name_label := Label.new()\nvar minigame_icon := TextureRect.new()\nvar modulate: Color = Color.WHITE\nfunc set_inactive(_v: bool): pass\nfunc set_rounds(_r: int): pass\n",
    "input_icon_mapping.gd": "extends Node\nclass_name InputIconMapping\nenum InputAction { KeyboardW, KeyboardS, KeyboardSpace, ControllerFaceSouth, ControllerFaceEast, ControllerLeftStick }\n",
    "intermission_icon_resource.gd": "extends Resource\nclass_name Intermission_IconResource\nvar identifier: int = 0\nvar icon_texture: Texture2D = null\nvar brief_instructions_header_pages: Array = []\nvar brief_instructions_content_pages: Array = []\nvar controls_data: Array = []\n",
    "intermission_control_input_label_data.gd": "extends Resource\nclass_name IntermissionControlInputLabelData\nvar control_text: String = \"\"\nvar controller_text: String = \"\"\nvar keyboard_icons: Array[InputIconMapping.InputAction] = []\nvar controller_icons: Array[InputIconMapping.InputAction] = []\n",
    "scripts/resources/minigame_list_resource.gd": [
      "extends Resource",
      "class_name MinigameListResource",
      "var game_identifier: int = 0",
      "var total_rounds: int = 1",
      "static func create(id: int, rounds: int = 1) -> MinigameListResource:",
      "\tvar r := MinigameListResource.new()",
      "\tr.game_identifier = id",
      "\tr.total_rounds = rounds",
      "\treturn r",
      ""
    ].join("\n"),
    "scripts/scenes/game/game.gd": [
      "extends Node",
      "var debug_no_shuffle := true",
      "var total_games_count := 0",
      "var session_current_minigame_round := 0",
      "var session_current_minigame_max_rounds := 0",
      "var minigame: Minigame = null",
      "var minigame_parent: Node = null",
      "var debug_player_handler = null",
      "var session_minigame_list: Array[Globals.MinigameIdentifier] = []",
      "var session_minigame_rounds: Dictionary[Globals.MinigameIdentifier, int] = {}",
      "func generate_session_playlist() -> void: pass",
      "func load_minigame(_id, _is_round, _total_rounds = -1): pass",
      "func _on_host_minigame_loaded(): pass",
      "func _on_minigame_loaded(_id): pass",
      "func _on_minigame_ready(_id): pass",
      "func _on_minigame_player_scored(_id, _s): pass",
      "func _on_minigame_player_score_finalized(_s): pass",
      "func _on_debug_specifics_initialized(): pass",
      ""
    ].join("\n"),
    "scenes/local_game/script/local_game.gd": "extends Node\nvar debug_no_shuffle := true\nvar total_games_count := 0\nvar session_current_minigame_round := 0\nvar session_current_minigame_max_rounds := 0\nvar minigame: Minigame = null\nvar minigame_parent: Node = null\nvar session_minigame_list: Array[Globals.MinigameIdentifier] = []\nvar session_minigame_rounds: Dictionary[Globals.MinigameIdentifier, int] = {}\nfunc generate_session_playlist() -> void: pass\nfunc load_minigame(_id, _is_round, _total_rounds = -1): pass\nfunc _on_minigame_loaded(_id): pass\nfunc _on_minigame_ready(_id): pass\nfunc _on_minigame_player_scored(_id, _s): pass\nfunc _on_minigame_player_score_finalized(_s): pass\n",
    "scenes/lobby/components/playlist_handler.gd": "extends Node\nvar all_minigames_list_items: Array = []\nvar selected_minigames_list_items: Array = []\nfunc _ready(): pass\nfunc add_minigame_button(_b, _id, _r = 1): pass\nfunc load_current_playlist(): pass\nfunc _on_reset_button_pressed(): pass\nfunc _on_minigame_add_pressed(_b, _s): pass\n",
    "minigames/intermission_new/components/intermission_game_picker.gd": "extends Node\nvar intermission_manager = null\nvar minigame_icon_spawn_parent = null\nvar active_icons: Array = []\nvar debug_active_identifier := 0\nvar next_minigame_label = null\nvar next_minigame_label_higher = null\nfunc _ready(): pass\n@rpc func setup_icons_from_data_rpc(_a, _b, _c, _d): pass\nfunc debug_update(): pass\nfunc pick_next_game(_i, _r): pass\nfunc set_viewfinder_for_briefing_screen(_id): pass\n"
  };

  for (const [rel, content] of Object.entries(fixtures)) {
    await writeFile(path.join(project, rel), content);
  }
  await copyFile(local("./bomb_cart_team_test.gd"), path.join(project, "bomb_cart_team_test.gd"));

  spawnSync(godot, ["--headless", "--path", project, "--import", "--quit"], { encoding: "utf8", timeout: 20000 });
  const res = spawnSync(godot, ["--headless", "--path", project, "--script", "res://bomb_cart_team_test.gd"], {
    encoding: "utf8",
    timeout: 25000
  });
  assert.equal(res.status, 0, res.stdout + res.stderr);
  assert.match(res.stdout, /BOMB_CART_TEAM_INTEGRATION_PASSED/);
});
