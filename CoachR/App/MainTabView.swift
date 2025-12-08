import SwiftUI

/// 主要的 Tab 導航視圖
///
/// 整合 Dashboard、活動頁等主要功能頁面，
/// 使用標準的 iOS TabView 提供底部導航列。
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard (摘要頁)
            DashboardView()
                .tabItem {
                    Label("摘要", systemImage: "house.fill")
                }
                .tag(0)

            // Tab 2: Activity (活動頁)
            ActivityView()
                .tabItem {
                    Label("活動", systemImage: "figure.run")
                }
                .tag(1)

            // Tab 3: Settings (設定頁 - 預留)
            SettingsPlaceholderView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.neonGreen) // Tab 選中時的顏色
        .preferredColorScheme(.dark)
    }
}

// MARK: - Settings Placeholder

/// 設定頁面佔位符
/// 未來可以實作 HealthKit 權限管理、主題設定等功能
struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("設定")
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)

                    Text("即將推出")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
