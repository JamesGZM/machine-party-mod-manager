# 协作对抗小游戏规划与准入门槛规范

[English](../../en/development/coop-minigame-gating.md) · **简体中文** · [繁體中文](../../zh-TW/development/coop-minigame-gating.md)

本文档定义 `mpm-core` 与 `team-party` 之上的**协作对抗（Team vs. Team）自研小游戏**规划准则、游玩模式兼容声明（支持纯组队、双模式或纯混战），以及大厅列表、默认列表、街机随机池与过场转盘的统一准入门槛设计。

## 1. 背景与设计目标

随着 [team-party](../../../mods/team-party/README.md) 完成大厅 2–4 队分队、原版小游戏团队挂接与共享团队注册表，第一方小游戏已可原生支持组队规则（如 `roller-carnival`、`bubble-blitz`、`spike-ring`）。然而，协作对抗类小游戏与纯生存乱斗不同，面临两个核心问题：

1. **模式兼容差异**：有些玩法可同时支持个人混战（FFA）与组队模式；有些玩法（如 2v2 拔河、强制分工流水线、双人锁链）若未开启组队便失去意义，甚至无法正常游玩。
2. **默认列表与随机池污染**：自研小游戏在进入大厅时会加入 `Globals.default_playlist`。若不进行准入过滤，玩家在未开启组队、队数不符或人数不足时开局，仍可能抽到无法游玩的关卡。

本规范的设计目标如下：
- **不破坏既有模组**：未声明门槛的旧模组默认视为支持双模式且无额外限制。
- **不动态篡改 `Globals.default_playlist`**：保持 `Globals.default_playlist` 静态完整，改为在所有读取与抽签入口统一做动态资格判定。
- **单一事实来源**：由 `mpm-core` 的 [minigame_sdk.gd](../../../mods/mpm-core/minigame_sdk.gd) 统一收敛判定逻辑，大厅 UI、默认模式、街机模式、自定义列表、本地同屏与 CRT 转盘共用同一套规则。

## 2. 游玩模式支持矩阵（`mode_support`）

每个向 `mpm-core` 注册的自研小游戏应明确声明自己的模式支持类型：

| `mode_support` | 适用玩法 | 个人混战（FFA）行为 | 组队模式（Team Party）行为 | 代表案例 |
| --- | --- | --- | --- | --- |
| `"both"`（默认） | 混战与组队皆可玩的关卡 | 各自为战、独立计分 | 启用队色、友军免伤与协作加成（如连线、救援） | `roller-carnival`、`bubble-blitz`、`spike-ring`、能源搬运、电路涂装 |
| `"team_only"` | 依赖队伍对抗／分工的纯组队关卡 | **不开放**：大厅列表锁定、不进默认／街机池 | 依 `min_teams`、`max_teams` 与 `min_players_per_team` 检查后开放 | 2v2 重工拔河、超载产线分工、双人电磁锁链 |
| `"ffa_only"` | 严格限个人对抗的特殊关卡 | 开放游玩 | **不开放**：开启组队时大厅锁定、开局跳过 | 未来纯单人博弈／独狼生存关卡 |

### 可选机制：局内临时分队（`auto_temp_teams`）

若某款小游戏本质上是“团队对抗”，但希望**即使房主在 FFA 模式下开局也能玩到**（类似《糖豆人》团队赛或《马里奥派对》2v2 回合）：
- 可设为 `"mode_support": "both"` 并搭配 `"auto_temp_teams": true`。
- 当 `team-party` 已启用时，直接沿用房主排好的队伍。
- 当大厅为 FFA 且参赛人数符合条件（例如偶数人或 `>= 4` 人）时，仅在**该回合内临时分成红／蓝两队**，结束后恢复个人积分结算。

## 3. `mpm-core` 声明式准入门槛契约

### 注册字段扩展

在 [minigame_sdk.gd](../../../mods/mpm-core/minigame_sdk.gd) 的 `register_minigame(spec)` 中新增可选的 `admission` 字典（省略时套用默认值）：

```gdscript
"admission": {
	"mode_support": "both",       # "both" | "team_only" | "ffa_only"
	"auto_temp_teams": false,     # 是否支持在 FFA 大厅局内临时分队
	"min_teams": 2,               # 组队模式生效时的最少有效队数
	"max_teams": 4,               # 组队模式生效时的最多队数（例如拔河限 2 队）
	"min_total_players": 2,       # 房间最少总参赛人数（含 lobby-bots 机器人）
	"min_players_per_team": 1,    # 每支有效队伍的最少人数（例如双人锁链／合抬为 2）
	"allow_local_couch": true,    # 本地同屏（local_game）是否支持
	"custom_check": Callable(),   # 可选的自定义检查回调（须为纯函数）
}
```

### 统一判定函数：`evaluate_minigame_eligibility(spec, context)`

由 `mpm-core` 提供单一判定入口，读入 `Engine.get_meta("mpm_team_party")`、当前房间参赛名单（含 `lobby-bots`）与是否为本地同屏模式，返回结构化结果：

- `eligible: bool`：开局当下是否允许进入本局轮换池。
- `hard_blocked: bool`：是否为“设定／环境型硬门槛”未通过（大厅左侧列表应锁定灰化）。
- `soft_warning: bool`：是否为“人数／队伍尚未凑齐型软门槛”未通过（大厅允许先排入列表，但显示提示标签；开局时若仍未满足则安全跳过）。
- `reason_key: String`：三语本地化提示键，涵盖：
  - `needs_team_mode`（需开启组队）
  - `ffa_only`（仅限个人混战）
  - `team_count_out_of_range`（例如 `[限 2 队]`）
  - `needs_more_players`（房间总人数不足）
  - `needs_more_per_team`（例如 `[需每队 ≥2 人]`）
  - `local_unsupported`（不支持本地同屏）

## 4. 硬门槛 vs. 软门槛与大厅列表交互（`override_playlist.gd`）

大厅的自定义播放列表由 [override_playlist.gd](../../../mods/mpm-core/override_playlist.gd) 接管，左侧为“全部游戏（`All`）”，右侧为“已选列表（`Selected`）”。

### 显示原则：灰化标注，不直接隐藏

未达门槛的关卡**不应从左侧列表消失**，否则玩家在刚装完模组进房时容易误以为安装失败或加载器未生效。应保留项目显示，通过 `MinigameListItem.set_inactive(true)` 灰化并在名称旁附加简短门槛标签（例如 `超载产线 [需组队]`、`重工拔河 [限 2 队]`）。

### 硬门槛与软门槛切分

房主常常在刚开房（仅自己 1 人）时就先排好游戏列表，再等待好友或加入机器人。因此列表限制必须区分两层：

1. **硬门槛（列表直接锁定，禁止加入右侧）**：与房间设定有关、房主当下即可切换的条件。
   - `mode_support == "team_only"` 但未开启组队（`team_party.enabled == false`）。
   - `mode_support == "ffa_only"` 但已开启组队。
   - 组队已开启，但目前设定队数超出 `[min_teams, max_teams]`（例如设定 4 队，但拔河限制 `max_teams = 2`）。
   - `allow_local_couch == false` 且目前处于本地同屏模式。
2. **软门槛（列表黄字／标签提示，允许预先加入右侧）**：与目前实时人数有关的条件。
   - 总人数未达 `min_total_players`。
   - 目前有人的队伍数少于 `min_teams`，或任一有效队伍人数未达 `min_players_per_team`。
   - 房主可先把关卡排进右侧列表；真正按下开局时若人数仍不足，由开局过滤器自动跳过。

### 实时联动与切回混战时的处理

1. **实时刷新**：`team-party` 的 [team_registry.gd](../../../mods/team-party/team_registry.gd) 在 `publish_state()` 时，通过 `mpm-core` 的 [event_bus.gd](../../../mods/mpm-core/event_bus.gd) 广播 `team_party.state_changed` 事件。`override_playlist.gd` 订阅此事件并实时重新评估左侧与右侧列表的锁定与标签状态。
2. **中途切回 FFA 时右侧已选列表的处理**：若房主先在组队模式把 `team_only` 关卡加入右侧列表，随后又将模式切回 FFA，建议**保留于右侧但转为灰化标注 `[需组队]`，并在开局时自动跳过**（避免房主误触切换后还得重排列表）；同时在点击“恢复默认（`_on_default_button_pressed`）”与重新加载列表（`load_current_playlist`）时，自动只纳入当前满足硬门槛的项目。

## 5. 默认列表、街机、本地同屏与转盘过滤

为解决“关卡在 `Globals.default_playlist` 里，但当前不满足条件”的问题，**不动态增删 `Globals.default_playlist`**，而是在四个消费入口统一调用 `evaluate_minigame_eligibility()`：

1. **线上对局生成（[override_game.gd](../../../mods/mpm-core/override_game.gd)）**：
   - `generate_session_playlist()` 在“官方默认模式”、“街机随机（Arcade）”与“自定义列表”三个分支组装 `session_minigame_list` 时，逐一检查 `eligible == true` 才纳入，否则直接跳过。
2. **本地同屏对局生成（[override_local_game.gd](../../../mods/mpm-core/override_local_game.gd)）**：
   - 同样在 `generate_session_playlist()` 过滤，确保 `team_only` 或 `allow_local_couch == false` 的关卡不会在未支持组队的单机同屏对局被抽中。
3. **大厅播放列表界面（[override_playlist.gd](../../../mods/mpm-core/override_playlist.gd)）**：
   - `load_current_playlist()` 与 `_on_default_button_pressed()` 依资格控制右侧默认填充与左侧按钮锁定状态。
4. **过场 15 格 CRT 转盘（[override_picker.gd](../../../mods/mpm-core/override_picker.gd)）**：
   - `setup_minigame_pick_host()` 在组装 15 格图标池时跳过不符合当前门槛的自研关卡，避免转盘出现却永远不会被选中。

### 空列表保底机制

若房主在自定义列表中**只勾选了 `team_only` 关卡**，接着在未开组队的状态下直接开局，过滤后 `minigames_shuffled` 会变为空数组。因此 `generate_session_playlist()` 必须加入保底：当过滤后列表为空时，自动从 `Globals.default_playlist` 中筛选所有 `eligible == true` 的关卡补齐，严禁让 `session_minigame_list` 为空而卡死过场。

## 6. 规划缺口与边界条件检查清单

实现时须一并覆盖以下容易遗漏的边界情况：

1. **自由分队（`FREE`）下的空队与不对称人数**：
   - 不能只看 `team-party` 的 `team_count` 设定值（例如设定 2 队，但全体玩家都挤在第 1 队形成 `2v0`）。
   - 判定必须以**实际有成员的队伍数（`active_team_count`）**以及**各有效队伍的最小人数（`min_active_team_size`）**为准；若仅有 1 支有效队伍，对抗类关卡不得开局。
2. **联机主客机同步一致性**：
   - `generate_session_playlist()` 仅在房主（`multiplayer.is_server()`）权威执行并通过 `setup_icons_from_data_rpc` 广播结果。
   - 客机端仍须通过 `team-party` 同步过来的房间状态驱动大厅列表显示，确保房主与客机看到的锁定／提示标签一致。
3. **局中掉线与机器人移除保底**：
   - 即使大厅检查通过，对局中仍可能发生玩家掉线、导致某队只剩 1 人甚至 0 人。
   - 所有协作对抗小游戏本身必须具备两项局内保底：
     - **交互降级**：需要双人合抬或双人触发的机关，当该队存活人数降至 1 人时自动调轻或允许单人触发，避免卡关。
     - **团灭提前结算**：当场上只剩 1 支有效队伍仍有存活成员（对手全数掉线或淘汰）时，正确触发胜利结算与同步计分。
4. **目录与安装器依赖规则（[catalog/mods.json](../../../catalog/mods.json)）**：
   - `mode_support == "team_only"` 的模组，在 `catalog/mods.json` 的 `requires` 中**必须同时声明 `mpm-core` 与 `team-party`**，确保玩家通过桌面端安装时自动带入组队依赖。
   - `mode_support == "both"` 的模组仅需依赖 `mpm-core`，并在三语 `detail` 中说明搭配 `team-party` 可解锁的组队玩法。
5. **共用 Hub 同步规范（`mods/_shared/minigame-hub/`）**：
   - `override_game.gd`、`override_local_game.gd`、`override_picker.gd`、`override_playlist.gd` 属于共用覆写脚本，修改后必须执行 `node scripts/pack-mod.mjs --sync-shared` 同步并通过 `npm run check:architecture`。
6. **验证测试补齐**：
   - 实现 `mpm-core` 门槛过滤后，须补上对应的自动化测试：涵盖 `both` / `team_only` / `ffa_only`、`2v0` 空队判定、默认／街机／自定义列表过滤、以及全数被滤光时的空列表保底。

## 7. 热门派对游戏协作对抗原型参考

以下整理适合 Machine Party 重工业风格与纯键盘操作（`WASD` + `Space` / `S`）的五大协作对抗原型，作为后续自研模组选题与 `mode_support` 定案参考：

| 类型原型 | 热门参考游戏 | 建议 `mode_support` | 适合队数 | 核心协作与对抗机制 | Machine Party 工业改编方向 |
| --- | --- | --- | --- | --- | --- |
| **资源搬运与抢夺** | 《猛兽派对》棒棒糖工厂、《糖豆人》抢蛋大作战 | `"both"` | 2–4 队 | 队内分工“搬运 / 守家 / 偷家”，重物双人合抬加速，可冲进敌区抢料并推晕对手 | **能源抢夺战**：抢中央电池与双人重型反应炉核心送回自家回收炉 |
| **流水线分工竞速** | 《胡闹厨房 2》对战、《马里奥派对》蛋糕工厂 | `"team_only"`（或 `auto_temp_teams`） | 2–4 队 | 取料 → 加工 → 出货分工；共用原料区抢料冲突，完成订单对领先队发动干扰 | **超载产线**：共用原料区抢料，交货后反转敌队传送带或空投废铁堵路 |
| **电路涂装领地** | 《斯普拉遁》涂地战、《糖豆人》能量传导 | `"both"` | 2–4 队 | 踩踏染色计分；同队近距离产生电弧连线整片上色，抢高压电池炸开扩色 | **电路涂装**：感应地板实时变色，队友电弧共振拓色与缩圈争夺 |
| **物理推车／轨道攻防** | 《糖豆人》足球赛、《猛兽派对》列车拔河 | `"team_only"` | 2–4 队（自适应直轨／Y 型／十字转盘） | 进攻推进与守门清场站位配合，倒数前将推车压入敌方防爆门 | **重工炸弹推车（`bomb-cart`）**：2–4 队自适应转盘轨道炸弹推车攻防 |
| **电磁锁链同步** | 《Chained Together》、《PICO PARK 2》、《马里奥派对》手摇车 | `"team_only"` | 2 人/队最佳（`min_players_per_team: 2`） | 同队被弹性锁链绑定同步走位，一人失足全队受牵连，锁链可绊倒敌队 | **锁链抢旗**：带电锁链穿越旋转臂与传送带抢分，同时绊倒敌队 |
