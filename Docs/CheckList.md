## 階段一：專案建置與基礎建設
[ ] 1. 專案初始化：建立 Xcode 專案，設定 Minimum Deployment Target (建議 iOS 17.0+ 以使用新圖表功能)。

[ ] 2. 隱私權限設定 (Info.plist)：加入 NSHealthShareUsageDescription (讀取) 與 NSHealthUpdateUsageDescription (寫入，雖然 Phase 1 主要是讀，但為了未來擴充建議先加)。

[ ] 3. 架構搭建：建立資料夾結構 (Core, Features, Models, Utils)。

[ ] 4. HealthKit Manager (基礎)：建立單例 (Singleton) 或環境物件，實作 requestAuthorization，確認能彈出授權視窗。

## 階段二：數據讀取 (Model Layer)
[ ] 5. 數據模型定義：建立 Workout struct。除了基礎屬性外，針對高階數據使用 Optional 類型 (如 var runningPower: Double?) 以支援優雅降級。

[ ] 6. 讀取跑步列表：實作 HKSampleQuery (或 HKAnchoredObjectQuery) 抓取所有跑步類型的 Workout。

[ ] 7. 讀取詳細樣本 (非同步)：實作針對單次 Workout ID 查詢關聯樣本 (HeartRate, Power, Cadence) 的邏輯。

[ ] 8. 讀取路徑軌跡：實作 HKWorkoutRouteQuery，取得經緯度陣列。

## 階段三：UI 開發 (View Layer)
[ ] 9. 儀表板 (Dashboard)：使用 List 或 LazyVStack 顯示跑步歷史紀錄卡片 (日期、距離、時間)。

[ ] 10. 詳情頁導航：實作點擊卡片跳轉至 ActivityDetailView 的 NavigationStack 邏輯。

[ ] 11. 地圖整合：使用 MapKit (SwiftUI 原生 Map) 繪製軌跡線 (Polyline)。

[ ] 12. 基礎圖表：使用 Swift Charts 繪製「心率 vs 時間」折線圖。

[ ] 13. 優雅降級 UI：實作 ViewBuilder 或 if let 邏輯。例如：if let power = workout.power { showPowerChart() } else { showNoDataMessage() }。

## 階段四：高階分析與優化
[ ] 14. 跑姿儀表板：計算並顯示垂直振幅、觸地時間、步長等高階數據。

[ ] 15. 數據格式化：撰寫 Formatter，確保配速顯示為 5'30" 格式，距離顯示為 10.5 km。

[ ] 16. Mock Data 測試：建立一個包含完整數據的假 Workout 物件，用於 SwiftUI Preview，確保在沒有 Apple Watch 的模擬器上也能調整 UI。

[ ] 17. 錯誤處理：處理用戶「拒絕授權」或「裝置無數據」的邊界情況。