# 協作對抗小遊戲規劃與准入門檻規範

[English](../../en/development/coop-minigame-gating.md) · [简体中文](../../zh-CN/development/coop-minigame-gating.md) · **繁體中文**

本文件定義 `mpm-core` 與 `team-party` 之上的**協作對抗（Team vs. Team）自研小遊戲**規劃準則、遊玩模式相容宣告（支援純組隊、雙模式或純混戰），以及大廳列表、預設清單、街機隨機池與過場轉盤的統一准入門檻設計。

## 1. 背景與設計目標

隨著 [team-party](../../../mods/team-party/README.md) 完成大廳 2–4 隊分隊、原版小遊戲團隊掛接與共享團隊註冊表，第一方小遊戲已可原生支援組隊規則（如 `roller-carnival`、`bubble-blitz`、`spike-ring`）。然而，協作對抗類小遊戲與純生存亂鬥不同，面臨兩個核心問題：

1. **模式相容差異**：有些玩法可同時支援個人混戰（FFA）與組隊模式；有些玩法（如 2v2 拔河、強制分工流水線、雙人鎖鏈）若未開啟組隊便失去意義，甚至無法正常遊玩。
2. **預設清單與隨機池污染**：自研小遊戲在進入大廳時會加入 `Globals.default_playlist`。若不進行准入過濾，玩家在未開啟組隊、隊數不符或人數不足時開局，仍可能抽到無法遊玩的關卡。

本規範的設計目標如下：
- **不破壞既有模組**：未宣告門檻的舊模組預設視為支援雙模式且無額外限制。
- **不動態篡改 `Globals.default_playlist`**：保持 `Globals.default_playlist` 靜態完整，改在所有讀取與抽籤入口統一做動態資格判定。
- **單一事實來源**：由 `mpm-core` 的 [minigame_sdk.gd](../../../mods/mpm-core/minigame_sdk.gd) 統一收斂判定邏輯，大廳 UI、預設模式、街機模式、自訂清單、本地同屏與 CRT 轉盤共用同一套規則。

## 2. 遊玩模式支援矩陣（`mode_support`）

每個向 `mpm-core` 註冊的自研小遊戲應明確宣告自己的模式支援類型：

| `mode_support` | 適用玩法 | 個人混戰（FFA）行為 | 組隊模式（Team Party）行為 | 代表案例 |
| --- | --- | --- | --- | --- |
| `"both"`（預設） | 混戰與組隊皆可玩的關卡 | 各自為戰、獨立計分 | 啟用隊色、友軍免傷與協作加成（如連線、救援） | `roller-carnival`、`bubble-blitz`、`spike-ring`、能源搬運、電路塗裝 |
| `"team_only"` | 依賴隊伍對抗／分工的純組隊關卡 | **不開放**：大廳列表鎖定、不進預設／街機池 | 依 `min_teams`、`max_teams` 與 `min_players_per_team` 檢查後開放 | 2v2 重工拔河、超載產線分工、雙人電磁鎖鏈 |
| `"ffa_only"` | 嚴格限個人對抗的特殊關卡 | 開放遊玩 | **不開放**：開啟組隊時大廳鎖定、開局略過 | 未來純單人博弈／獨狼生存關卡 |

### 選用機制：局內臨時分隊（`auto_temp_teams`）

若某款小遊戲本質上是「團隊對抗」，但希望**即使房主在 FFA 模式下開局也能玩到**（類似《糖豆人》團隊賽或《瑪利歐派對》2v2 回合）：
- 可設為 `"mode_support": "both"` 並搭配 `"auto_temp_teams": true`。
- 當 `team-party` 已啟用時，直接沿用房主排好的隊伍。
- 當大廳為 FFA 且參賽人數符合條件（例如偶數人或 `>= 4` 人）時，僅在**該回合內臨時分成紅／藍兩隊**，結束後恢復個人積分結算。

## 3. `mpm-core` 宣告式准入門檻契約

### 註冊欄位擴充

在 [minigame_sdk.gd](../../../mods/mpm-core/minigame_sdk.gd) 的 `register_minigame(spec)` 中新增選用的 `admission` 字典（省略時套用預設值）：

```gdscript
"admission": {
	"mode_support": "both",       # "both" | "team_only" | "ffa_only"
	"auto_temp_teams": false,     # 是否支援在 FFA 大廳局內臨時分隊
	"min_teams": 2,               # 組隊模式生效時的最少有效隊數
	"max_teams": 4,               # 組隊模式生效時的最多隊數（例如拔河限 2 隊）
	"min_total_players": 2,       # 房間最少總參賽人數（含 lobby-bots 機器人）
	"min_players_per_team": 1,    # 每支有效隊伍的最少人數（例如雙人鎖鏈／合抬為 2）
	"allow_local_couch": true,    # 本地同屏（local_game）是否支援
	"custom_check": Callable(),   # 選用的自訂檢查回呼（須為純函式）
}
```

### 統一判定函式：`evaluate_minigame_eligibility(spec, context)`

由 `mpm-core` 提供單一判定入口，讀入 `Engine.get_meta("mpm_team_party")`、當前房間參賽名單（含 `lobby-bots`）與是否為本地同屏模式，回傳結構化結果：

- `eligible: bool`：開局當下是否允許進入本局輪換池。
- `hard_blocked: bool`：是否為「設定／環境型硬門檻」未過（大廳左側列表應鎖定灰化）。
- `soft_warning: bool`：是否為「人數／隊伍尚未湊齊型軟門檻」未過（大廳允許先排入清單，但顯示提示標籤；開局時若仍未滿足則安全略過）。
- `reason_key: String`：三語本地化提示鍵，涵蓋：
  - `needs_team_mode`（需開啟組隊）
  - `ffa_only`（僅限個人混戰）
  - `team_count_out_of_range`（例如 `[限 2 隊]`）
  - `needs_more_players`（房間總人數不足）
  - `needs_more_per_team`（例如 `[需每隊 ≥2 人]`）
  - `local_unsupported`（不支援本地同屏）

## 4. 硬門檻 vs. 軟門檻與大廳列表互動（`override_playlist.gd`）

大廳的自訂播放清單由 [override_playlist.gd](../../../mods/mpm-core/override_playlist.gd) 接管，左側為「全部遊戲（`All`）」，右側為「已選清單（`Selected`）」。

### 顯示原則：灰化標註，不直接隱藏

未達門檻的關卡**不應從左側列表消失**，否則玩家在剛裝完模組進房時容易誤以為安裝失敗或載入器未生效。應保留項目顯示，透過 `MinigameListItem.set_inactive(true)` 灰化並在名稱旁附加簡短門檻標籤（例如 `超載產線 [需組隊]`、`重工拔河 [限 2 隊]`）。

### 硬門檻與軟門檻切分

房主常常在剛開房（僅自己 1 人）時就先排好遊戲清單，再等待好友或加入機器人。因此列表限制必須區分兩層：

1. **硬門檻（列表直接鎖定，禁止加入右側）**：與房間設定有關、房主當下即可切換的條件。
   - `mode_support == "team_only"` 但未開啟組隊（`team_party.enabled == false`）。
   - `mode_support == "ffa_only"` 但已開啟組隊。
   - 組隊已開啟，但目前設定隊數超出 `[min_teams, max_teams]`（例如設定 4 隊，但拔河限制 `max_teams = 2`）。
   - `allow_local_couch == false` 且目前處於本地同屏模式。
2. **軟門檻（列表黃字／標籤提示，允許預先加入右側）**：與目前即時人數有關的條件。
   - 總人數未達 `min_total_players`。
   - 目前有人的隊伍數少於 `min_teams`，或任一有效隊伍人數未達 `min_players_per_team`。
   - 房主可先把關卡排進右側清單；真正按下開局時若人數仍不足，由開局過濾器自動略過。

### 即時連動與切回混戰時的處理

1. **即時刷新**：`team-party` 的 [team_registry.gd](../../../mods/team-party/team_registry.gd) 在 `publish_state()` 時，透過 `mpm-core` 的 [event_bus.gd](../../../mods/mpm-core/event_bus.gd) 廣播 `team_party.state_changed` 事件。`override_playlist.gd` 訂閱此事件並即時重新評估左側與右側列表的鎖定與標籤狀態。
2. **中途切回 FFA 時右側已選清單的處理**：若房主先在組隊模式把 `team_only` 關卡加入右側清單，隨後又將模式切回 FFA，建議**保留於右側但轉為灰化標註 `[需組隊]`，並在開局時自動略過**（避免房主誤觸切換後還得重排清單）；同時在點擊「恢復預設（`_on_default_button_pressed`）」與重新載入清單（`load_current_playlist`）時，自動只納入當前滿足硬門檻的項目。

## 5. 預設清單、街機、本地同屏與轉盤過濾

為解決「關卡在 `Globals.default_playlist` 裡，但當前不滿足條件」的問題，**不動態增刪 `Globals.default_playlist`**，而是在四個消費入口統一呼叫 `evaluate_minigame_eligibility()`：

1. **線上對局生成（[override_game.gd](../../../mods/mpm-core/override_game.gd)）**：
   - `generate_session_playlist()` 在「官方預設模式」、「街機隨機（Arcade）」與「自訂清單」三個分支組裝 `session_minigame_list` 時，逐一檢查 `eligible == true` 才納入，否則直接略過。
2. **本地同屏對局生成（[override_local_game.gd](../../../mods/mpm-core/override_local_game.gd)）**：
   - 同樣在 `generate_session_playlist()` 過濾，確保 `team_only` 或 `allow_local_couch == false` 的關卡不會在未支援組隊的單機同屏對局被抽中。
3. **大廳播放清單介面（[override_playlist.gd](../../../mods/mpm-core/override_playlist.gd)）**：
   - `load_current_playlist()` 與 `_on_default_button_pressed()` 依資格控制右側預設填充與左側按鈕鎖定狀態。
4. **過場 15 格 CRT 轉盤（[override_picker.gd](../../../mods/mpm-core/override_picker.gd)）**：
   - `setup_minigame_pick_host()` 在組裝 15 格圖示池時略過不符合當前門檻的自研關卡，避免轉盤出現卻永遠不會被選中。

### 空清單保底機制

若房主在自訂清單中**只勾選了 `team_only` 關卡**，接著在未開組隊的狀態下直接開局，過濾後 `minigames_shuffled` 會變為空陣列。因此 `generate_session_playlist()` 必須加入保底：當過濾後清單為空時，自動從 `Globals.default_playlist` 中篩選所有 `eligible == true` 的關卡補齊，嚴禁讓 `session_minigame_list` 為空而卡死過場。

## 6. 規劃缺口與邊界條件檢查清單

實作時須一併覆蓋以下容易遺漏的邊界情況：

1. **自由分隊（`FREE`）下的空隊與不對稱人數**：
   - 不能只看 `team-party` 的 `team_count` 設定值（例如設定 2 隊，但全體玩家都擠在第 1 隊形成 `2v0`）。
   - 判定必須以**實際有成員的隊伍數（`active_team_count`）**以及**各有效隊伍的最小人數（`min_active_team_size`）**為準；若僅有 1 支有效隊伍，對抗類關卡不得開局。
2. **連線主客機同步一致性**：
   - `generate_session_playlist()` 僅在房主（`multiplayer.is_server()`）權威執行並透過 `setup_icons_from_data_rpc` 廣播結果。
   - 客機端仍須透過 `team-party` 同步過來的房間狀態驅動大廳列表顯示，確保房主與客機看到的鎖定／提示標籤一致。
3. **局中斷線與機器人移除保底**：
   - 即使大廳檢查通過，對局中仍可能發生玩家斷線、導致某隊只剩 1 人甚至 0 人。
   - 所有協作對抗小遊戲本身必須具備兩項局內保底：
     - **互動降級**：需要雙人合抬或雙人觸發的機關，當該隊存活人數降至 1 人時自動調輕或允許單人觸發，避免卡關。
     - **團滅提前結算**：當場上只剩 1 支有效隊伍仍有存活成員（對手全數斷線或淘汰）時，正確觸發勝利結算與同步計分。
4. **目錄與安裝器相依規則（[catalog/mods.json](../../../catalog/mods.json)）**：
   - `mode_support == "team_only"` 的模組，在 `catalog/mods.json` 的 `requires` 中**必須同時宣告 `mpm-core` 與 `team-party`**，確保玩家透過桌面端安裝時自動帶入組隊依賴。
   - `mode_support == "both"` 的模組僅需依賴 `mpm-core`，並在三語 `detail` 中說明搭配 `team-party` 可解鎖的組隊玩法。
5. **共用 Hub 同步規範（`mods/_shared/minigame-hub/`）**：
   - `override_game.gd`、`override_local_game.gd`、`override_picker.gd`、`override_playlist.gd` 屬於共用覆寫腳本，修改後必須執行 `node scripts/pack-mod.mjs --sync-shared` 同步並通過 `npm run check:architecture`。
6. **驗證測試補齊**：
   - 實作 `mpm-core` 門檻過濾後，須補上對應的自動化測試：涵蓋 `both` / `team_only` / `ffa_only`、`2v0` 空隊判定、預設／街機／自訂清單過濾、以及全數被濾光時的空清單保底。

## 7. 熱門派對遊戲協作對抗原型參考

以下整理適合 Machine Party 重工業風格與純鍵盤操作（`WASD` + `Space` / `S`）的五大協作對抗原型，作為後續自研模組選題與 `mode_support` 定案參考：

| 類型原型 | 熱門參考遊戲 | 建議 `mode_support` | 適合隊數 | 核心協作與對抗機制 | Machine Party 工業改編方向 |
| --- | --- | --- | --- | --- | --- |
| **資源搬運與搶奪** | 《猛獸派對》棒棒糖工廠、《糖豆人》搶蛋大作戰 | `"both"` | 2–4 隊 | 隊內分工「搬運 / 守家 / 偷家」，重物雙人合抬加速，可衝進敵區搶料並推暈對手 | **能源搶奪戰**：搶中央電池與雙人重型反應爐核心送回自家回收爐 |
| **流水線分工競速** | 《胡鬧廚房 2》對戰、《瑪利歐派對》蛋糕工廠 | `"team_only"`（或 `auto_temp_teams`） | 2–4 隊 | 取料 → 加工 → 出貨分工；共用原料區搶料衝突，完成訂單對領先隊發動干擾 | **超載產線**：共用原料區搶料，交貨後反轉敵隊傳送帶或空投廢鐵堵路 |
| **電路塗裝領地** | 《斯普拉遁》塗地戰、《糖豆人》能量傳導 | `"both"` | 2–4 隊 | 踩踏染色計分；同隊近距離產生電弧連線整片上色，搶高壓電池炸開擴色 | **電路塗裝**：感應地板即時變色，隊友電弧共振拓色與縮圈爭奪 |
| **物理推車／軌道攻防** | 《糖豆人》足球賽、《猛獸派對》列車拔河 | `"team_only"` | 2–4 隊（自適應直軌／Y 型／十字轉盤） | 進攻推進與守門清場站位配合，倒數前將推車壓入敵方防爆門 | **重工炸彈推車（`bomb-cart`）**：2–4 隊自適應轉盤軌道炸彈推車攻防 |
| **電磁鎖鏈同步** | 《Chained Together》、《PICO PARK 2》、《瑪利歐派對》手搖車 | `"team_only"` | 2 人/隊最佳（`min_players_per_team: 2`） | 同隊被彈性鎖鏈綁定同步走位，一人失足全隊受牽連，鎖鏈可絆倒敵隊 | **鎖鏈搶旗**：帶電鎖鏈穿越旋轉臂與傳送帶搶分，同時絆倒敵隊 |
