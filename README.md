# CoachR

CoachR 是一個專為跑者設計的 iOS 原生應用程式，深度整合 Apple HealthKit，提供從數據收集、視覺化分析到科學化訓練的一站式解決方案。

## 功能特色

### 全方位數據同步
- 透過 HealthKit 自動讀取 Apple Watch 產生的跑步紀錄
- 支援讀取高階數據：垂直振幅、觸地時間、步長、跑步功率
- 讀取身體狀態數據：靜止心率 (RHR)、心率變異度 (HRV)、最大攝氧量 (VO2Max)

### 視覺化分析
- **互動式圖表**：使用 Swift Charts 繪製心率區間、配速波動、步頻分析
- **軌跡熱力圖**：使用 MapKit 繪製跑步路徑
- **跑姿儀表板**：針對進階跑者顯示「垂直振幅」與「觸地時間」等效率指標
- **優雅降級**：若用戶設備不支援特定數據（如功率），UI 自動隱藏該區塊，不影響整體使用

### 智能數據呈現
- **摘要頁**：快速檢視體能狀態、本週跑量、最近一次跑步
- **活動頁**：提供日曆視圖與列表視圖兩種檢視模式
- **詳情頁**：深度分析單次運動的各項指標與配速分佈

## 技術棧

### 前端
- **語言**：Swift 6 (開啟 Strict Concurrency Checking)
- **UI 框架**：SwiftUI
- **狀態管理**：@Observable Macro
- **導航**：NavigationStack
- **數據視覺化**：Swift Charts, MapKit
- **並發處理**：Swift Async/Await, Structured Concurrency

### 數據與儲存
- **數據來源**：HealthKit (Read-only)
- **快取機制**：UserDefaults (1小時有效期)
- **本地持久化**：SwiftData (預留給未來版本儲存訓練計畫)
- **測試數據**：Mock Data Manager 用於模擬器開發與 UI 測試

### 性能優化
- **分層載入策略**：Dashboard 載入 10 筆基礎資料，Activity 載入 50 筆
- **按需載入**：詳情頁資料（圖表、GPS 軌跡）僅在進入時載入
- **競態條件處理**：使用 `async let` 並行獲取資料後統一合併，避免資料遺失
- **快取優先**：啟動時優先顯示快取資料，背景更新最新資料

## 系統架構

```
CoachR/
├── App/
│   ├── RunningCoachApp.swift      # App 入口點
│   ├── AppDependency.swift        # 依賴注入容器
│   └── MainTabView.swift          # 主頁籤導航
│
├── Core/
│   ├── HealthKit/
│   │   ├── HKManager.swift        # HealthKit API 封裝
│   │   ├── HKError.swift          # 錯誤處理
│   │   └── HKTypes.swift          # 數據類型定義
│   └── Cache/
│       └── DashboardCache.swift   # 數據快取管理
│
├── Models/
│   ├── Workout.swift              # 核心運動數據模型
│   ├── Workout+HKWorkout.swift    # HealthKit 轉換擴充
│   └── RunningMetrics.swift       # 跑姿分析指標
│
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   │
│   ├── Activity/
│   │   ├── ActivityView.swift
│   │   └── Views/
│   │       ├── CalendarGridView.swift
│   │       ├── WorkoutListView.swift
│   │       └── WorkoutMiniCard.swift
│   │
│   └── ActivityDetail/
│       ├── ActivityDetailView.swift
│       ├── ActivityDetailViewModel.swift
│       └── Views/
│           ├── ActivitySummaryView.swift
│           └── MapView.swift
│
└── Preview Content/
    └── MockData.swift             # 測試用假資料
```

### 架構層級

1. **HealthKit Manager (Service Layer)**
   - 封裝 `HKHealthStore`
   - 提供 `async throws` 方法來獲取數據
   - 處理權限請求與錯誤狀態

2. **Cache Layer**
   - 使用 UserDefaults 實作輕量級快取機制
   - 1 小時快取有效期，加速 App 啟動
   - 分離快取運動列表與健康指標

3. **Repository / Mapper**
   - 將 HealthKit 的 `HKQuantitySample` 轉換為 APP 內部的 `Workout` Domain Model
   - 處理單位的統一轉換（如：m/s 轉 km/h）
   - 實作資料豐富化（Data Enrichment）策略

4. **ViewModel (Presentation Layer)**
   - 使用 `@Observable` 標註
   - 負責將 Domain Model 轉換為 View 需要的狀態
   - 處理 UI 的 Loading 狀態與 Empty State
   - 實作分層載入策略（基礎資料 vs 詳細資料）

## 快速開始

### 前置需求

- macOS 14.0+
- Xcode 15.0+
- iOS 17.0+ 設備或模擬器
- Apple Developer 帳號（用於真機測試）

### 安裝步驟

1. 克隆專案

```bash
git clone <repository-url>
cd CoachR
```

2. 開啟 Xcode 專案

```bash
open CoachR.xcodeproj
```

3. 設定 HealthKit 權限

請參閱 [HEALTHKIT_SETUP.md](HEALTHKIT_SETUP.md) 取得詳細的 HealthKit 設定指南。

關鍵步驟：
- 在 Xcode 中啟用 HealthKit Capability
- 在 Info.plist 中新增隱私權限描述
- 在真實裝置上測試（HealthKit 在模擬器上功能有限）

4. 執行應用程式

選擇你的目標裝置，然後按下 Run (⌘R)

## 使用說明

### 首次啟動

1. 啟動 App 後會自動請求 HealthKit 授權
2. 在系統對話框中選擇要分享的健康數據類型
3. 點擊「允許」完成授權
4. App 會自動載入最近 50 筆跑步紀錄

### 日常使用

**摘要頁 (Dashboard)**
- 檢視體能狀態環（基於 RHR 與 HRV 計算）
- 查看本週累積跑量
- 快速瀏覽最近一次跑步

**活動頁 (Activity)**
- 切換日曆視圖：檢視當月訓練連續性，高強度運動會顯示火焰圖示
- 切換列表視圖：查看詳細數據比較
- 點擊任一運動記錄進入詳情頁

**詳情頁 (Activity Detail)**
- 查看 GPS 軌跡地圖
- 檢視心率與配速圖表
- 分析跑姿數據（步頻、垂直振幅、觸地時間）

## 設計風格

- **色調**：深色背景 (#000000, #1C1C1E) 搭配螢光綠數據 (#00FF00)
- **佈局**：Bento Grid (便當盒網格) 佈局，強調卡片式設計
- **字體**：SF Pro Rounded (標題), SF Pro Condensed (數據顯示)

## 開發指南

### 使用 Mock Data 進行 UI 測試

如果你想快速測試 UI 但不想處理 HealthKit 權限：

在 [DashboardView.swift](CoachR/Features/Dashboard/DashboardView.swift) 中，暫時註解掉 `.task { await viewModel.loadAllData() }`，並使用 MockData：

```swift
@State private var viewModel = {
    let vm = DashboardViewModel()
    vm.workouts = MockData.workouts
    vm.restingHeartRate = 52
    vm.heartRateVariability = 65
    return vm
}()
```

### 資料流程

#### Dashboard 啟動流程
```
App Launch
    ↓
1. 載入快取資料 (DashboardCache) → 立即顯示 UI
    ↓
2. 請求 HealthKit 授權
    ↓
3. 並行獲取最新資料
   ├─ 運動列表 (10 筆基礎資料)
   └─ 健康指標 (RHR, HRV, VO2Max)
    ↓
4. 更新 UI + 儲存新快取
```

#### ActivityDetail 資料載入流程
```
進入詳情頁
    ↓
1. 顯示基礎資料 (距離、時間、配速)
    ↓
2. 查找對應的 HKWorkout
    ↓
3. 並行獲取所有詳細資料 (async let)
   ├─ 心率樣本
   ├─ 速度樣本
   ├─ 功率樣本
   ├─ 跑姿指標 (VO, GCT, Stride)
   └─ GPS 路徑與海拔
    ↓
4. 統一合併所有資料 → 一次性更新 UI
   (避免競態條件導致資料遺失)
```

### 優雅降級機制

App 設計為自動適應可用的數據：

- 如果沒有進階指標 (功率、垂直振幅)：不顯示該區塊
- 如果沒有心率資料：顯示「無資料」佔位符
- 如果沒有 GPS 路徑：顯示地圖佔位符

## 常見問題

### Q: 為什麼看不到任何運動數據？

A: 請檢查以下項目：
1. HealthKit capability 已在 Xcode 中啟用
2. Info.plist 包含隱私權描述
3. 已授予 App 讀取健康資料的權限
4. 「健康」App 中有跑步記錄

### Q: 可以在模擬器上測試嗎？

A: 可以，但 HealthKit 在模擬器上功能有限。建議：
1. 開啟「健康」App 手動新增測試運動記錄
2. 或使用專案內建的 MockData 進行 UI 測試
3. 最佳體驗請在真實裝置上測試

### Q: 為什麼部分進階指標沒有顯示？

A: 這是正常的優雅降級行為。進階指標（如跑步功率、垂直振幅）需要：
- Apple Watch Series 6 或更新機型
- watchOS 9.0 或更新版本
- 在戶外跑步時開啟 GPS

詳細的疑難排解請參閱 [HEALTHKIT_SETUP.md](HEALTHKIT_SETUP.md)

## 路線圖

### Phase 1 (已完成) ✅
- [x] HealthKit 數據讀取與授權管理
- [x] 運動記錄列表與日曆視圖雙模式切換
- [x] 運動詳情頁面（地圖、圖表、跑姿分析）
- [x] 進階跑姿指標分析（優雅降級機制）
- [x] GPS 路徑顯示與海拔變化圖表
- [x] 快取機制實作（1 小時有效期）
- [x] 分層載入策略（基礎/詳細資料分離）
- [x] 競態條件處理（資料完整性保證）
- [x] Swift Charts 整合（8 種圖表類型）
- [x] 步頻計算（從步長與速度推導）

### Phase 1.5 (優化中) 🔄
- [x] 啟動效能優化（快取優先載入）
- [x] 詳情頁按需載入
- [ ] 背景更新機制
- [ ] 圖表資料降採樣（處理大量樣本點）

### Phase 2 (規劃中) 📋
- [ ] 智慧訓練系統
- [ ] 馬拉松訓練計畫
- [ ] 自動核對訓練目標
- [ ] 訓練進度追蹤
- [ ] SwiftData 整合（課表持久化）

## 文件

- [HEALTHKIT_SETUP.md](HEALTHKIT_SETUP.md) - HealthKit 設定指南
- [Docs/PRD.md](Docs/PRD.md) - 產品需求文檔

## 授權

Copyright © 2025 CoachR. All rights reserved.

## 聯絡方式

如有問題或建議，請提交 Issue 或 Pull Request。
