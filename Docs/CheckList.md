## 階段一：專案建置與基礎建設
[x] 1. 專案初始化：建立 Xcode 專案，設定 Minimum Deployment Target (iOS 17.0+)。

[x] 2. 隱私權限設定 (Info.plist)：加入 NSHealthShareUsageDescription (讀取) 與 NSHealthUpdateUsageDescription (寫入)。

[x] 3. 架構搭建：建立資料夾結構 (App, Core, Features, Models, Preview Content)。

[x] 4. HealthKit Manager (基礎)：建立 HKManager.shared 單例，實作 requestAuthorization，確認能彈出授權視窗。

[x] 5. 錯誤處理機制：建立 HKError 結構，提供友善的錯誤訊息。

[x] 6. HealthKit 類型定義：建立 HKTypes 集中管理所有需要讀取的資料類型。

## 階段二：數據讀取 (Model Layer)
[x] 5. 數據模型定義：建立 Workout struct，針對高階數據使用 Optional 類型以支援優雅降級。
   - [x] 基礎屬性：id, startDate, endDate, distance, duration
   - [x] 進階屬性：heartRateSamples, speedSamples, powerSamples
   - [x] 跑姿指標：verticalOscillationSamples, groundContactTimeSamples, strideLengthSamples
   - [x] 路徑資料：route (coordinates), elevationSamples

[x] 6. 讀取跑步列表：實作 fetchRunningWorkouts(limit:) 方法抓取最近的跑步記錄。

[x] 7. 讀取詳細樣本 (非同步)：實作 fetchQuantitySamples(for:during:) 查詢各類樣本。
   - [x] 心率樣本 (HeartRate)
   - [x] 速度樣本 (RunningSpeed)
   - [x] 功率樣本 (RunningPower)
   - [x] 垂直振幅 (VerticalOscillation)
   - [x] 觸地時間 (GroundContactTime)
   - [x] 步長 (StrideLength)

[x] 8. 讀取路徑軌跡：實作 HKWorkoutRouteQuery，取得經緯度陣列。
   - [x] fetchRoute(for:) 取得路徑座標
   - [x] fetchRouteWithElevation(for:) 取得海拔資料

[x] 9. 讀取健康指標：
   - [x] fetchLatestRestingHeartRate() 靜止心率
   - [x] fetchLatestHeartRateVariability() 心率變異度
   - [x] fetchLatestVO2Max() 最大攝氧量

## 階段三：UI 開發 (View Layer)

### Dashboard (儀表板)
[x] 10. Dashboard 基礎 UI：使用 ScrollView + LazyVStack 顯示運動記錄。
[x] 11. 分層載入策略：Dashboard 只載入 10 筆基礎資料以加速啟動。
[x] 12. 快取機制：DashboardCache 使用 UserDefaults 實作 1 小時快取。
[x] 13. 三階段載入流程：快取 → 授權 → 背景更新。

### Activity View (活動頁)
[x] 14. 雙模式切換：使用 Picker (Segmented Control) 切換日曆/列表視圖。
[x] 15. 列表視圖：WorkoutListView 顯示運動卡片。
[x] 16. 日曆視圖：CalendarGridView 顯示月曆網格。
   - [x] 顯示運動指示器（綠點）
   - [x] 點擊日期彈出 WorkoutMiniCard
[x] 17. 載入更多資料：Activity View 載入 50 筆運動供日曆顯示。

### Activity Detail (詳情頁)
[x] 18. 詳情頁導航：實作 NavigationStack + navigationDestination 跳轉邏輯。
[x] 19. 地圖整合：使用 MapKit 繪製路徑 Polyline + 起終點標記。
[x] 20. Summary Grid：2x3 網格顯示基礎統計數據。
[x] 21. 分段配速表：計算並顯示每公里配速、海拔、心率。
[x] 22. Swift Charts 整合：實作 8 種圖表類型。
   - [x] 心率圖 (折線圖)
   - [x] 配速圖 (折線圖 + 異常值過濾)
   - [x] 功率分佈 (面積圖)
   - [x] 海拔變化 (面積圖)
   - [x] 步頻圖 (折線圖)
   - [x] 垂直振幅圖 (折線圖)
   - [x] 觸地時間圖 (折線圖)
   - [x] 步長圖 (折線圖)
[x] 23. 優雅降級 UI：所有進階指標使用 if let 檢查，無資料時顯示空白佔位符。
[x] 24. 按需載入：ActivityDetailViewModel 實作 loadDetailedDataIfNeeded()。
[x] 25. 載入指示器：顯示 ProgressView 直到資料載入完成。

## 階段四：高階分析與優化

### 數據分析
[x] 26. 跑姿儀表板：顯示垂直振幅、觸地時間、步長等 6 項高階數據。
[x] 27. 步頻計算：從步長與速度樣本計算步頻（cadence = speed / stride * 60）。
[x] 28. 分段配速計算：實作 calculateKilometerSplits() 方法。
[x] 29. 海拔爬升計算：從海拔樣本計算總爬升。
[x] 30. 異常值過濾：配速圖表過濾不合理的數據點（< 2:30/km 或 > 15:00/km）。

### 數據格式化
[x] 31. 配速格式化：實作 formattedPace 顯示為 "5'30\"" 格式。
[x] 32. 時間格式化：實作 formattedDuration 顯示為 "1:23:45" 格式。
[x] 33. 距離格式化：顯示為 "10.5 km" 格式。
[x] 34. 日期格式化：Toolbar 顯示日期與時間。

### 性能優化
[x] 35. 快取機制：DashboardCache 實作 1 小時有效期快取。
[x] 36. 分層載入：Dashboard 10 筆 → Activity 50 筆 → Detail 按需載入。
[x] 37. 競態條件處理：使用 async let 並行獲取後統一合併，避免資料遺失。
[x] 38. 資料豐富化策略：基礎資料與詳細樣本分離載入。

### 測試與開發工具
[x] 39. Mock Data：建立完整的測試資料（MockData.swift）。
   - [x] 包含所有類型的樣本資料
   - [x] 支援 SwiftUI Preview
[x] 40. 錯誤處理：處理用戶拒絕授權、無數據等邊界情況。
   - [x] HKError 提供友善錯誤訊息
   - [x] UI 優雅降級顯示空白佔位符

## 階段五：已知問題修復 ✅
[x] 41. 修復競態條件導致的資料遺失問題。
[x] 42. 修復步頻單位轉換錯誤（m 轉 count/min）。
[x] 43. 修復 ViewModel 雙重引用問題。
[x] 44. 修復方法名稱不匹配（fetchRoute vs fetchWorkoutRoute）。
[x] 45. 移除危險的 force unwrapping，改用 guard let。

## 階段六：未來規劃 📋
[ ] 46. 圖表降採樣：處理大量樣本點避免卡頓。
[ ] 47. Background Delivery：實作 HealthKit 背景更新。
[ ] 48. 訓練計畫系統：SwiftData 整合。
[ ] 49. 智能訓練建議：基於歷史數據分析。
[ ] 50. 社交分享功能：分享運動成果。