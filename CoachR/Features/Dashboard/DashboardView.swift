import SwiftUI
import Charts
import CoreLocation

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Row 1: Body Battery + Weekly Volume (2 columns)
                    HStack(spacing: 16) {
                        BodyBatteryCard(
                            rhr: viewModel.restingHeartRate,
                            hrv: viewModel.heartRateVariability
                        )
                        WeeklyVolumeCard(workouts: viewModel.workouts)
                    }

                    // Row 2: Latest Run Card (Full Width)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("體能狀態")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            // Main Score Display
            HStack(alignment: .center, spacing: 16) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(readinessScore) / 100.0)
                        .stroke(
                            readinessScore > 70 ? Color.neonGreen : Color.warningOrange,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: readinessScore)

                    Text("\(readinessScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Metrics
                VStack(alignment: .leading, spacing: 8) {
                    if let rhr = rhr {
                        MetricRow(
                            icon: "heart.fill",
                            label: "RHR",
                            value: "\(Int(rhr))",
                            unit: "bpm"
                        )
                    } else {
                        MetricRow(
                            icon: "heart.fill",
                            label: "RHR",
                            value: "--",
                            unit: ""
                        )
                    }

                    if let hrv = hrv {
                        MetricRow(
                            icon: "waveform.path.ecg",
                            label: "HRV",
                            value: "\(Int(hrv))",
                            unit: "ms"
                        )
                    } else {
                        MetricRow(
                            icon: "waveform.path.ecg",
                            label: "HRV",
                            value: "--",
                            unit: ""
                        )
                    }
                }
            }

            Spacer()

            // Status Text
            HStack {
                Circle()
                    .fill(readinessScore > 70 ? Color.neonGreen : Color.warningOrange)
                    .frame(width: 6, height: 6)

                Text(readinessScore > 70 ? "準備充分" : "建議休息")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)

                Spacer()
            }
        }
        .padding(16)
        .frame(height: 240)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("本週跑量")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            // Total Distance
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", totalDistance))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.neonGreen)

                Text("km")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Mini Bar Chart
            Chart {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, distance in
                    BarMark(
                        x: .value("Day", dayLabel(for: index)),
                        y: .value("Distance", distance)
                    )
                    .foregroundStyle(distance > 0 ? Color.neonGreen : Color.gray.opacity(0.3))
                    .cornerRadius(4)
                }
            }
            .frame(height: 80)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis(.hidden)
        }
        .padding(16)
        .frame(height: 240)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func dayLabel(for index: Int) -> String {
        ["一", "二", "三", "四", "五", "六", "日"][index]
    }

    private func calculateWeeklyDistances() -> [Double] {
        let calendar = Calendar.current
        let today = Date()

        // Get start of week (Monday)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return Array(repeating: 0.0, count: 7)
        }

        var dailyDistances: [Double] = Array(repeating: 0.0, count: 7)

        for workout in workouts {
            guard let dayIndex = calendar.dateComponents([.day], from: weekStart, to: workout.endDate).day,
                  dayIndex >= 0, dayIndex < 7 else {
                continue
            }

            dailyDistances[dayIndex] += workout.distanceInKilometers
        }

        return dailyDistances
    }
}

// MARK: - Latest Run Card

struct LatestRunCard: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 16) {
            // Left: Mini Map Snapshot
            if let route = workout.route {
                MiniMapSnapshot(coordinates: route)
                    .frame(width: 100, height: 100)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "map")
                            .foregroundColor(.gray)
                            .font(.title)
                    )
            }

            // Middle: Workout Details
            VStack(alignment: .leading, spacing: 8) {
                Text("最近一次跑步")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)

                Text(workout.endDate, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Stats Grid
                HStack(spacing: 16) {
                    StatItem(
                        label: "距離",
                        value: String(format: "%.2f", workout.distanceInKilometers),
                        unit: "km"
                    )

                    StatItem(
                        label: "時間",
                        value: workout.formattedDuration,
                        unit: ""
                    )

                    StatItem(
                        label: "配速",
                        value: workout.formattedPace,
                        unit: "/km"
                    )
                }
            }

            Spacer()

            // Right: Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.body)
        }
        .padding(16)
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
            Color.gray.opacity(0.2)

            VStack {
                Image(systemName: "map.fill")
                    .font(.title)
                    .foregroundColor(.neonGreen.opacity(0.7))

                Text("\(String(format: "%.1f", Double(coordinates.count) / 100.0))km")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.gray)
                }
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
