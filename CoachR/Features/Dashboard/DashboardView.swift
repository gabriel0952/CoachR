import SwiftUI
import Charts
import CoreLocation

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Body Battery Card (Full Width)
                    BodyBatteryCard(
                        rhr: viewModel.restingHeartRate,
                        hrv: viewModel.heartRateVariability
                    )

                    // Weekly Volume Card (Full Width)
                    WeeklyVolumeCard(workouts: viewModel.workouts)

                    // Latest Run Card (Full Width)
                    if let latestWorkout = viewModel.workouts.first {
                        NavigationLink {
                            ActivityDetailView(workout: latestWorkout)
                        } label: {
                            LatestRunCard(workout: latestWorkout)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if viewModel.isLoading {
                        LoadingCard()
                    } else if viewModel.workouts.isEmpty {
                        EmptyWorkoutsCard()
                    }
                }
                .padding(16)
            }
            .background(Color.black)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .alert("HealthKit Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadAllData()
            }
        }
    }
}

// MARK: - Body Battery Card (Readiness Score)

struct BodyBatteryCard: View {
    let rhr: Double?
    let hrv: Double?

    private var readinessScore: Int {
        // Calculate readiness score from RHR and HRV
        guard let rhr = rhr, let hrv = hrv else {
            return 50 // Default neutral score
        }

        // Simple algorithm: Lower RHR and higher HRV = better readiness
        let rhrScore = max(0, min(100, 100 - Int((rhr - 40) * 2)))
        let hrvScore = min(100, Int(hrv))

        return (rhrScore + hrvScore) / 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("體能狀態")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(.white)

            // Main Content
            HStack(alignment: .center, spacing: 24) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(readinessScore) / 100.0)
                        .stroke(
                            readinessScore > 70 ? Color.neonGreen : Color.warningOrange,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: readinessScore)

                    VStack(spacing: 2) {
                        Text("\(readinessScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(readinessScore > 70 ? "準備充分" : "建議休息")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Metrics
                VStack(alignment: .trailing, spacing: 16) {
                    if let rhr = rhr {
                        MetricRow(
                            icon: "heart.fill",
                            label: "靜止心率",
                            value: "\(Int(rhr))",
                            unit: "bpm"
                        )
                    } else {
                        MetricRow(
                            icon: "heart.fill",
                            label: "靜止心率",
                            value: "--",
                            unit: "bpm"
                        )
                    }

                    if let hrv = hrv {
                        MetricRow(
                            icon: "waveform.path.ecg",
                            label: "心率變異",
                            value: "\(Int(hrv))",
                            unit: "ms"
                        )
                    } else {
                        MetricRow(
                            icon: "waveform.path.ecg",
                            label: "心率變異",
                            value: "--",
                            unit: "ms"
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Metric Row Component

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text(unit)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Weekly Volume Card

struct WeeklyVolumeCard: View {
    let workouts: [Workout]

    private var weeklyData: [Double] {
        calculateWeeklyDistances()
    }

    private var totalDistance: Double {
        weeklyData.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with total
            VStack(alignment: .leading, spacing: 8) {
                Text("本週跑量")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", totalDistance))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.neonGreen)

                    Text("km")
                        .font(.system(.title2, design: .rounded))
                        .foregroundColor(.gray)
                }
            }

            // Mini Bar Chart
            Chart {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, distance in
                    BarMark(
                        x: .value("Day", dayLabel(for: index)),
                        y: .value("Distance", distance)
                    )
                    .foregroundStyle(distance > 0 ? Color.neonGreen : Color.gray.opacity(0.2))
                    .cornerRadius(4)
                }
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis(.hidden)
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func dayLabel(for index: Int) -> String {
        ["一", "二", "三", "四", "五", "六", "日"][index]
    }

    private func calculateWeeklyDistances() -> [Double] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Set Monday as first day of week
        let today = Date()

        // Get start of week (Monday)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return Array(repeating: 0.0, count: 7)
        }

        var dailyDistances: [Double] = Array(repeating: 0.0, count: 7)

        for workout in workouts {
            // Calculate which day of the week (0 = Monday, 6 = Sunday)
            guard let daysSinceStart = calendar.dateComponents([.day], from: weekStart, to: workout.endDate).day,
                  daysSinceStart >= 0, daysSinceStart < 7 else {
                continue
            }

            dailyDistances[daysSinceStart] += workout.distanceInKilometers
        }

        return dailyDistances
    }
}

// MARK: - Latest Run Card

struct LatestRunCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("最近一次跑步")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.body)
            }

            // Date
            Text(workout.endDate, style: .date)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)

            // Map (if available)
            if let route = workout.route {
                MiniMapSnapshot(coordinates: route)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
            }

            // Stats Grid - 3 columns
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("距離")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.2f", workout.distanceInKilometers))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text("km")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("時間")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)

                    Text(workout.formattedDuration)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("配速")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(workout.formattedPace)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text("/km")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Mini Map Snapshot

struct MiniMapSnapshot: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        // Placeholder for map rendering
        // In production, you would use MapKit with MKMapSnapshotter
        ZStack {
            // Gradient background to simulate map
            LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Route path indicator
            VStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.neonGreen.opacity(0.6))

                Text("GPS 路徑已記錄")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let neonGreen = Color(hex: "#00FF00")
    static let warningOrange = Color(hex: "#FF9500")
    static let cardBackground = Color(hex: "#1C1C1E")
    static let darkBackground = Color(hex: "#000000")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Loading & Empty State Cards

struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.neonGreen)
                .scaleEffect(1.5)

            Text("載入中...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct EmptyWorkoutsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("尚無運動紀錄")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.white)

            Text("開始跑步來記錄你的第一次運動")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
