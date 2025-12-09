# CoachR APP 開發文檔 (v1.3)

CoachR 是一个 iOS Native APP，旨在深度整合 Apple HealthKit，為跑者提供從數據收集、視覺化分析到科學化訓練課表的一站式解決方案。

## 🎯 項目概述

### 核心功能
1.  **全方位數據同步 (Data Sync):**
    - 透過 HealthKit 自動讀取 Apple Watch 產生的跑步紀錄。
    - 支援讀取高階數據：垂直振幅、觸地時間、步長、跑步功率 (Running Power)。
    - 讀取身體狀態數據：靜止心率 (RHR)、心率變異度 (HRV/SDNN)、最大攝氧量 (VO2Max)。

2.  **視覺化分析 (Data Visualization):**
    - **互動式圖表:** 使用 Swift Charts 繪製心率區間、配速波動、步頻分析。
    - **軌跡熱力圖:** 使用 MapKit 繪製跑步路徑。
    - **跑姿儀表板:** 針對進階跑者顯示「垂直振幅比」與「觸地騰空比」等效率指標。
    - **優雅降級 (Graceful Degradation):** 若用戶設備不支援特定數據（如功率），UI 自動隱藏該區塊或顯示「無資料」，不影響整體使用。

3.  **智慧訓練系統 (Smart Coaching) [Phase 2]:**
    - 提供入門至進階的馬拉松訓練計畫。
    - 自動核對當日運動紀錄與目標。

## 🛠 技術棧

### 前端 (iOS Client)
- **Language:** Swift 6 (開啟 Strict Concurrency Checking)
- **UI Framework:** SwiftUI
- **State Management:** **@Observable Macro** (取代舊式 ObservableObject)
- **Navigation:** **NavigationStack** (路徑管理)
- **Data Visualization:** Swift Charts, MapKit
- **Concurrency:** **Swift Async/Await** (處理 HealthKit 非同步查詢)

### 數據與儲存 (Data & Storage)
- **Source of Truth:** HealthKit (Read-only for Phase 1)
- **Local Persistence:** SwiftData (預留給 Phase 2 儲存課表狀態)
- **Mocking:** 建立 Mock Data Manager 以利於模擬器開發與 UI 測試。

## 🏗 系統架構

1.  **HealthKit Manager (Service Layer):**
    - 封裝 `HKHealthStore`。
    - 提供 `async throws` 方法來獲取數據。
    - 負責處理權限請求與錯誤狀態（如：用戶拒絕授權）。

2.  **Repository / Mapper:**
    - 將 HealthKit 的 `HKQuantitySample` 轉換為 APP 內部的 `Workout` Domain Model。
    - 處理單位的統一轉換（如：m/s 轉 km/h）。

3.  **ViewModel (Presentation Layer):**
    - 使用 `@Observable` 標註。
    - 負責將 Domain Model 轉換為 View 需要的狀態（如：將心率陣列轉換為圖表座標點）。
    - 處理 UI 的 Loading 狀態與 Empty State。
    - 負責處理日曆邏輯，將 `[Workout]` 轉換為 `[Date: Workout]` 的字典以便快速查找。

## 🔄 用戶流程 (User Flow)

### A. Onboarding (首次啟動)
1.  **Welcome Screen:** 顯示 Logo 與 Slogan（例如：「科學化你的每一步」）。
2.  **HealthKit Authorization (關鍵):**
    - 顯示說明頁面（強調隱私、本地運算）。
    - 執行 `requestAuthorization` -> 彈出系統授權窗 -> 用戶全選 -> 返回 APP。
    - *系統檢查權限：若失敗，引導至設定頁。*
3.  **Initial Sync:**
    - 顯示 Loading 動畫：「正在分析跑步歷史...」。
    - 後台執行 `HKManager` 抓取最近 50 筆紀錄。
4.  **Dashboard:** 資料載入完成，進入主頁。

### B. Daily Loop (日常使用)
1.  **開啟 APP:** 進入 Dashboard (摘要頁)。
2.  **查看狀態:** 瀏覽今日「體能狀態環」與「本週跑量」。
3.  **查看紀錄 (活動頁):**
    - 預設顯示「日曆視圖」，查看當月訓練連續性。
    - 切換至「列表視圖」，查看詳細數據比較。
4.  **深度分析:** 進入 `ActivityDetailView`。
    - 查看地圖軌跡。
    - 滑動圖表檢視心率與配速。
    - (進階) 檢查垂直振幅與功率。
5.  **返回:** 回到 Dashboard。

## 📱 UI/UX 詳細規格

### 設計風格 (Design System)
- **色調:** 深色背景 (#000000, #1C1C1E) 搭配 螢光色數據 (螢光綠 #00FF00 為主色, 橘色 #FF9500 為警示色)。
- **排版:** 使用 **Bento Grid (便當盒網格)** 佈局，強調卡片式設計。
- **字體:** SF Pro Rounded (標題), SF Pro Condensed (數據顯示)。

### 1. 摘要頁 (SummaryView / Dashboard)
* **佈局:** ScrollView + LazyVGrid (Bento Grid 風格)。
* **區塊 A - 身體電量 (Body Battery):**
    * 大正方形卡片。
    * 內容：圓環進度條 (0-100)，基於 RHR 與 HRV 計算。
* **區塊 B - 本週跑量 (Weekly Volume):**
    * 長方形卡片。
    * 內容：本週累積公里數 + 微型長條圖 (Bar Chart) 顯示 Mon-Sun 趨勢。
* **區塊 C - 最近一次跑步 (Latest Run):**
    * 橫跨螢幕寬度卡片。
    * 內容：左側微型地圖 (Map Snapshot)，右側顯示日期、距離、時間、平均配速。
    * 互動：點擊導航至 `ActivityDetailView`。

### 2. 活動頁 (ActivityView)
* **頂部切換器:** 使用 `Picker` (Segmented Control style) 切換 **[日曆]** 與 **[列表]**。
* **模式 A：列表視圖 (List Mode)**
    * 標準 List 視圖。
    * Cell 顯示：日期、大字體距離、小字體時間與配速、強度圖示。
* **模式 B：日曆視圖 (Calendar Mode)**
    * **Header:** 顯示「YYYY年 MM月」與切換月份的箭頭。
    * **Grid:** 7 列 (週日-週六) 的網格。
    * **Cell (每日格子):**
        * 顯示日期數字。
        * **狀態標示 (Indicator):**
            * 無運動：空白或僅顯示日期。
            * 有運動 (一般)：日期下方顯示一個**螢光綠小圓點**。
            * 有運動 (長距離/高強度)：日期下方顯示一個**特殊 Icon** (如火焰或獎盃)，依據 XML 中的 `distance` 或 `activeEnergyBurned` 判斷。
    * **互動:** 點擊有運動的日期，下方彈出該次運動的簡歷卡片 (Mini Card)，再次點擊卡片進入詳情頁。

### 3. 運動詳情頁 (ActivityDetailView)

#### 已實作功能 ✅

* **Header (地圖區):** 固定高度 300pt，使用 MapKit 顯示路徑 Polyline + 起終點標記
* **Summary Grid (數據網格):** 2x3 網格，顯示：
    - 距離 (km)、時間、配速 (/km)
    - 平均心率 (bpm)、卡路里 (kcal)、平均功率 (W)
    - 使用優雅降級：無數據時顯示「無資料」佔位符

* **分段配速表 (Kilometer Splits):**
    - 表格顯示每公里的配速、海拔變化、平均心率
    - 自動計算分段數據

* **Charts Section (圖表區) - 8 種圖表:**
    1. **心率圖** (Heart Rate): 紅色折線圖，顯示平均/最大心率
    2. **配速圖** (Pace): 綠色折線圖，過濾異常值，顯示平均/最快配速
    3. **功率分佈** (Power): 黃色面積圖，顯示平均/最大功率與總功
    4. **海拔變化** (Elevation): 棕色面積圖，顯示爬升與最高海拔
    5. **步頻** (Cadence): 青色折線圖，從步長與速度計算
    6. **垂直振幅** (Vertical Oscillation): 紫色折線圖
    7. **觸地時間** (Ground Contact Time): 橘色折線圖
    8. **步長** (Stride Length): 綠色折線圖
    - 所有圖表使用 **優雅降級**：無資料時顯示空白佔位符

* **Running Form (跑姿分析 - 優雅降級):**
    * 邏輯：使用 `if let metrics = workout.metrics` 檢查數據
    * 2x3 網格顯示跑姿指標：
      - 步頻 (spm)
      - 垂直振幅 (cm)
      - 觸地時間 (ms)
      - 步長 (m)
      - 垂直振幅比 (%)
      - 觸地平衡 (%)
    * *若無數據則自動隱藏整個區塊*

#### 技術實作細節

**按需載入策略:**
```swift
.task {
    await viewModel.loadDetailedDataIfNeeded()
}
```
- 檢查是否已有詳細資料（心率樣本、速度樣本等）
- 若無則觸發完整資料載入
- 顯示載入指示器直到完成

**資料完整性保證:**
- 使用 `async let` 並行獲取 8 種不同類型的資料
- 統一合併所有資料後一次性更新 UI
- 避免競態條件導致的資料遺失

## 🤖 AI 開發提示詞 (Prompt Templates)

在使用 AI Coding 工具 (如 Cursor, Windsurf) 時，可使用以下 Prompt 結構：

### 專案情境 (Context)
> "I am building a SwiftUI app for runners called 'CoachR'. The app connects to HealthKit using `HKManager`. The app architecture is MVVM with Swift Concurrency. Focus on iOS 17+ features."

### 任務：建立 Dashboard (Task - Dashboard)
> "Create a `DashboardView` using SwiftUI.
> 1. Use a ScrollView with a visually appealing 'Bento Grid' layout.
> 2. Include a 'Readiness Card' showing a circular progress view for Daily Readiness (0-100%).
> 3. Include a 'Weekly Volume Card' showing total distance and a mini BarChart for the last 7 days using Swift Charts.
> 4. Include a 'Last Run Card' that takes a `Workout` model and displays date, distance, duration, and pace.
> 5. Use `NavigationLink` on the 'Last Run Card' to navigate to `ActivityDetailView`.
> 6. Style it using a dark theme with neon green accents."

### 任務：建立詳情頁 (Task - Activity Detail)
> "Create an `ActivityDetailView` that takes a `Workout` model.
> 1. Top section: A MapView showing the route (use MapKit).
> 2. Stats Grid: Display distance, duration, avg heart rate, and avg power in a LazyVGrid.
> 3. **Crucial:** Implement a 'Running Metrics' section for advanced form data. Only display this section if `workout.verticalOscillation` and `workout.groundContactTime` are not nil (Graceful Degradation).
> 4. Use Swift Charts to show a Heart Rate graph over time."

## 📦 專案架構

實際結構：
```
CoachR/
 ├── App/
 │ ├── RunningCoachApp.swift       # App 入口
 │ ├── AppDependency.swift         # 依賴注入容器
 │ └── MainTabView.swift           # 主頁籤導航
 │
 ├── Core/
 │ ├── HealthKit/
 │ │ ├── HKManager.swift           # 核心讀取邏輯
 │ │ ├── HKError.swift             # 錯誤處理
 │ │ └── HKTypes.swift             # 定義需要讀取的類型
 │ └── Cache/
 │   └── DashboardCache.swift      # 快取管理 (UserDefaults)
 │
 ├── Models/
 │ ├── Workout.swift               # 核心實體 (含 Optional 屬性)
 │ ├── Workout+HKWorkout.swift     # HealthKit 轉換擴充
 │ └── RunningMetrics.swift        # 跑姿數據結構
 │
 ├── Features/
 │ ├── Dashboard/
 │ │ ├── DashboardView.swift
 │ │ └── DashboardViewModel.swift  # 快取 + 分層載入策略
 │ │
 │ ├── Activity/
 │ │ ├── ActivityView.swift        # 日曆/列表雙模式
 │ │ └── Views/
 │ │   ├── CalendarGridView.swift
 │ │   ├── WorkoutListView.swift
 │ │   └── WorkoutMiniCard.swift
 │ │
 │ └── ActivityDetail/
 │   ├── ActivityDetailView.swift  # 詳情頁主視圖
 │   ├── ActivityDetailViewModel.swift  # 按需載入 + 競態處理
 │   └── Views/
 │     ├── ActivitySummaryView.swift
 │     └── MapView.swift
 │
 ├── Preview Content/
 │ └── MockData.swift              # 測試用假資料
 │
 └── Resources/
   └── Info.plist                  # 隱私權限描述
```

## 🧪 測試策略

### 單元測試 (Unit Tests)
- **HealthKit Parsing:** 測試從 XML/Mock Data 轉換為 Workout Model 的準確性。
- **Algorithm:** 測試訓練達成率計算邏輯、配速區間計算邏輯。
- **JSON Decoding:** 確保訓練課表 JSON 檔案能被正確讀取。

## 📈 性能優化

### 已實作優化 ✅

#### 1. 分層載入策略 (Tiered Loading)
- **Dashboard**: 只載入 10 筆基礎運動資料（距離、時間、日期）
- **Activity View**: 載入 50 筆運動資料供日曆與列表顯示
- **Detail View**: 按需載入詳細資料（心率樣本、GPS 軌跡、跑姿指標）

#### 2. 快取機制 (Caching)
- 使用 `UserDefaults` 實作輕量級快取
- 快取有效期：1 小時
- **啟動流程**：
  1. 立即載入快取資料 → UI 快速顯示
  2. 背景獲取最新資料 → 無感更新
  3. 儲存新快取供下次使用

#### 3. 競態條件處理 (Race Condition Prevention)
- 使用 `async let` 並行獲取所有資料
- 統一合併後一次性更新 `workout` 屬性
- 避免多個任務同時修改共享狀態導致資料遺失

**實作範例** (ActivityDetailViewModel):
```swift
// 並行獲取所有資料
async let heartRateSamples = fetchHeartRateSamples(for: hkWorkout)
async let speedSamples = fetchSpeedSamples(for: hkWorkout)
async let powerSamples = fetchPowerSamples(for: hkWorkout)
// ... 其他資料

// 等待所有資料完成
let hr = await heartRateSamples
let speed = await speedSamples
// ...

// 統一合併並一次性更新
var updatedWorkout = workout
if let hr = hr { updatedWorkout = updatedWorkout.withHeartRateData(hr) }
if let speed = speed { updatedWorkout = updatedWorkout.withSpeedData(speed) }
// ...
workout = updatedWorkout  // 只更新一次
```

### 規劃中優化 📋
- **Lazy Loading:** 列表頁面使用 `LazyVStack`，避免一次渲染過多歷史紀錄
- **Chart Downsampling:** 針對大量採樣點的圖表進行降採樣處理，避免卡頓
- **Background Delivery:** 使用 HealthKit Background Delivery 在背景更新數據
