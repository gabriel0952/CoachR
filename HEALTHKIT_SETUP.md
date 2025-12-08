# HealthKit 設定指南

## 已完成的變更

✅ **DashboardView** - 已更新為使用 `DashboardViewModel` 讀取真實 HealthKit 資料
✅ **ActivityView** - 已更新為使用 `DashboardViewModel` 讀取真實 HealthKit 資料
✅ **DashboardViewModel** - 已實作完整的資料載入邏輯
✅ **HKTypes** - 已新增便利屬性以便存取量化類型

---

## 步驟 1: 新增 HealthKit Privacy 權限

在 Xcode 中進行以下設定：

### 方法 A: 透過 Xcode UI (推薦)

1. 在 Xcode 中選擇專案根目錄的 **CoachR** 專案檔
2. 選擇 **CoachR** target
3. 點擊 **Info** 標籤頁
4. 在 **Custom iOS Target Properties** 區域，點擊 **+** 按鈕新增以下項目：

| Key | Type | Value |
|-----|------|-------|
| `Privacy - Health Share Usage Description` | String | `CoachR 需要存取您的健康資料以顯示運動記錄和分析您的跑步表現` |
| `Privacy - Health Update Usage Description` | String | `CoachR 需要更新您的健康資料以記錄運動資訊` |

### 方法 B: 直接編輯 Info.plist (如果專案有獨立的 Info.plist 檔案)

如果專案中有獨立的 `Info.plist` 檔案，新增以下內容：

```xml
<key>NSHealthShareUsageDescription</key>
<string>CoachR 需要存取您的健康資料以顯示運動記錄和分析您的跑步表現</string>
<key>NSHealthUpdateUsageDescription</key>
<string>CoachR 需要更新您的健康資料以記錄運動資訊</string>
```

---

## 步驟 2: 啟用 HealthKit Capability

1. 在 Xcode 中選擇 **CoachR** target
2. 點擊 **Signing & Capabilities** 標籤頁
3. 點擊 **+ Capability** 按鈕
4. 搜尋並選擇 **HealthKit**
5. 確認 **HealthKit** capability 已被新增到專案中

---

## 步驟 3: 測試應用程式

### 在真實裝置上測試 (推薦)

**重要：HealthKit 在模擬器上功能有限，建議使用真實 iPhone 進行測試**

1. 連接你的 iPhone 到電腦
2. 在 Xcode 中選擇你的裝置作為執行目標
3. 點擊 **Run** 按鈕 (或按 Cmd+R)
4. 首次啟動時，系統會詢問 HealthKit 權限：
   - 選擇要分享的資料類型
   - 點擊「允許」

### 在模擬器上測試

模擬器上的 HealthKit 有以下限制：
- 沒有預設的運動資料
- 某些進階指標可能無法使用

如果你想在模擬器中測試：

1. 開啟「健康」App
2. 點擊「瀏覽」→「活動」→「體能訓練」
3. 手動新增一些測試運動記錄
4. 重新開啟 CoachR

---

## 步驟 4: 驗證資料載入

啟動 App 後，你應該會看到：

### Dashboard 頁面
- **體能狀態卡片**：顯示 RHR (靜止心率) 和 HRV (心率變異)
  - 如果沒有資料，會顯示 `--`
- **本週跑量卡片**：根據本週的運動記錄計算距離
- **最近一次跑步卡片**：顯示最新的跑步記錄
  - 如果沒有資料，會顯示「尚無運動紀錄」

### 活動頁面
- **列表模式**：顯示所有跑步記錄的清單
- **日曆模式**：
  - 有運動的日期會顯示綠點
  - 高強度運動會顯示火焰圖示
  - 點擊日期可查看該日的運動詳情

### 運動詳情頁面
- **地圖區域**：顯示跑步路徑 (如果有 GPS 資料)
- **統計網格**：距離、時間、配速、心率、卡路里、功率
- **圖表區域**：心率與配速、功率分佈
- **跑姿分析**：步頻、垂直振幅、觸地時間等 (如果有進階指標)

---

## 步驟 5: 偵錯常見問題

### 問題 1: 權限對話框沒有出現

**解決方法**：
1. 刪除 App 並重新安裝
2. 到「設定」→「隱私權」→「健康」→ 確認 CoachR 有被列出

### 問題 2: 資料顯示為空

**檢查清單**：
- ✅ HealthKit capability 已啟用
- ✅ Info.plist 包含隱私權描述
- ✅ 已授予 App 讀取健康資料的權限
- ✅ 「健康」App 中有運動記錄

**偵錯步驟**：
1. 檢查 Xcode Console 是否有錯誤訊息
2. 確認「健康」App 中確實有跑步資料
3. 嘗試在 App 中下拉刷新 (如果實作了)

### 問題 3: 編譯錯誤

**常見錯誤**：
- `Type 'HKManager' has no member 'shared'`
  - **解決**：確認 [HKManager.swift](CoachR/Core/HealthKit/HKManager.swift) 中有 `static let shared = HKManager()`

- `Cannot find type 'DashboardViewModel' in scope`
  - **解決**：確認 [DashboardViewModel.swift](CoachR/Features/Dashboard/DashboardViewModel.swift) 已被加入到 Xcode 專案中

- Missing import statements
  - **解決**：確認所有檔案都有必要的 import：
    ```swift
    import Foundation
    import HealthKit
    import Observation
    ```

---

## 程式碼架構說明

### 資料流程

```
HealthKit (真實裝置上的資料)
    ↓
HKManager.swift (HealthKit API 封裝)
    ↓
DashboardViewModel.swift (資料處理與轉換)
    ↓
DashboardView.swift / ActivityView.swift (UI 顯示)
```

### 關鍵檔案

| 檔案 | 功能 |
|------|------|
| [HKManager.swift](CoachR/Core/HealthKit/HKManager.swift) | HealthKit API 封裝，單例模式 |
| [HKTypes.swift](CoachR/Core/HealthKit/HKTypes.swift) | HealthKit 類型定義 |
| [DashboardViewModel.swift](CoachR/Features/Dashboard/DashboardViewModel.swift) | 資料載入邏輯，使用 @Observable |
| [Workout.swift](CoachR/Models/Workout.swift) | 運動資料模型 |
| [Workout+HKWorkout.swift](CoachR/Models/Workout+HKWorkout.swift) | HKWorkout 轉換擴充 |
| [RunningMetrics.swift](CoachR/Models/RunningMetrics.swift) | 跑姿分析指標 |

### 優雅降級 (Graceful Degradation)

App 設計為自動適應可用的資料：

- ✅ 如果沒有進階指標 (功率、垂直振幅)：不顯示該區塊
- ✅ 如果沒有心率資料：顯示 "無資料" 佔位符
- ✅ 如果沒有 GPS 路徑：顯示地圖佔位符

---

## 開發測試技巧

### 使用 MockData 進行 UI 測試

如果你想快速測試 UI 但不想處理 HealthKit：

在 [DashboardView.swift](CoachR/Features/Dashboard/DashboardView.swift:48) 中，暫時註解掉 `.task { await viewModel.loadAllData() }`，並使用 MockData：

```swift
// 暫時用於 UI 測試
@State private var viewModel = {
    let vm = DashboardViewModel()
    vm.workouts = MockData.workouts
    vm.restingHeartRate = 52
    vm.heartRateVariability = 65
    return vm
}()
```

### 切換回真實資料

完成 UI 測試後，恢復原本的程式碼即可使用真實 HealthKit 資料。

---

## 下一步

完成 HealthKit 設定後，你可以：

1. **在真實裝置上跑步**，讓 Apple Watch 或 iPhone 記錄運動
2. **開啟 CoachR**，查看你的運動記錄和分析
3. **自訂介面**，根據你的需求調整 UI
4. **新增更多功能**，例如：
   - 運動目標設定
   - 訓練計畫
   - 社交分享
   - 運動提醒

---

## 需要協助？

如果遇到問題，請檢查：

1. Xcode Console 的錯誤訊息
2. 「健康」App 中的資料權限設定
3. App 的 HealthKit capability 是否正確啟用
4. Info.plist 的隱私權描述是否已設定

祝你使用愉快！ 🏃‍♂️
