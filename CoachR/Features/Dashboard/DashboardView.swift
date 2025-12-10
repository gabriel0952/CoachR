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

                    // Race Predictor Card (Full Width)
                    if let predictions = viewModel.racePredictions {
                        RacePredictorCard(
                            predictions: predictions,
                            seedWorkout: viewModel.predictionSeedWorkout
                        )
                    }

                    // Training Status Card (Full Width)
                    if let trainingStatus = viewModel.trainingStatus {
                        TrainingStatusCard(status: trainingStatus)
                    }

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
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
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
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
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

// MARK: - Race Predictor Card

struct RacePredictorCard: View {
    let predictions: [RacePredictor.RacePrediction]
    let seedWorkout: Workout?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.neonGreen)
                    .font(.title3)

                Text("完賽預測")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            // Prediction Source Info
            if let seedWorkout = seedWorkout {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Text("基於 \(seedWorkout.endDate, style: .date) 的 \(String(format: "%.2f", seedWorkout.distanceInKilometers))km 跑步")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)

                    Spacer()

                    Text("近 8 週訓練")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.neonGreen.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.neonGreen.opacity(0.15))
                        .cornerRadius(6)
                }
            }

            // Predictions Grid - 2x2
            VStack(spacing: 12) {
                // Row 1: 5K and 10K
                HStack(spacing: 12) {
                    ForEach(predictions.prefix(2)) { prediction in
                        RacePredictionItem(prediction: prediction)
                    }
                }

                // Row 2: Half and Full Marathon
                HStack(spacing: 12) {
                    ForEach(predictions.suffix(2)) { prediction in
                        RacePredictionItem(prediction: prediction)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct RacePredictionItem: View {
    let prediction: RacePredictor.RacePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Distance label
            Text(prediction.distance.displayName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.gray)

            // Predicted time
            Text(prediction.formattedTime)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.neonGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Training Status Card

struct TrainingStatusCard: View {
    let status: TrainingLoadEngine.TrainingStatus

    // Show last 28 days of data
    private var recentHistory: [TrainingLoadEngine.DailyLoad] {
        let count = status.history.count
        if count > 28 {
            return Array(status.history.suffix(28))
        }
        return status.history
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.neonGreen)
                    .font(.title3)

                Text("訓練狀態")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            // Main Content: Gauge + Status
            HStack(spacing: 24) {
                // ACWR Gauge (Left side)
                VStack(spacing: 12) {
                    ZStack {
                        // Background arc
                        Circle()
                            .trim(from: 0, to: 0.5)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(180))

                        // Colored segments
                        GaugeSegments(acwr: status.acwr)

                        // Value display
                        VStack(spacing: 4) {
                            Text(String(format: "%.2f", status.acwr))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("A/C 比")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .offset(y: 20)
                    }

                    // Status label
                    Text(status.status.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: status.status.color))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: status.status.color).opacity(0.15))
                        .cornerRadius(8)
                }

                Spacer()

                // Load metrics (Right side)
                VStack(alignment: .trailing, spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("體能 (CTL)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.gray)

                        Text(String(format: "%.0f", status.currentCTL))
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("疲勞 (ATL)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.gray)

                        Text(String(format: "%.0f", status.currentATL))
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.pink)
                    }
                }
            }

            // Trend Chart
            if !recentHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("過去 4 週趨勢")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)

                    Chart {
                        ForEach(recentHistory) { load in
                            // CTL Line (Fitness - Blue)
                            LineMark(
                                x: .value("Date", load.date),
                                y: .value("CTL", load.ctl)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            // ATL Line (Fatigue - Pink)
                            LineMark(
                                x: .value("Date", load.date),
                                y: .value("ATL", load.atl)
                            )
                            .foregroundStyle(.pink)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 100)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 9, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisValueLabel()
                                .font(.system(size: 9, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }

                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.blue)
                                .frame(width: 16, height: 2)
                            Text("體能 (CTL)")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.gray)
                        }

                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.pink)
                                .frame(width: 16, height: 2)
                            Text("疲勞 (ATL)")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Gauge Segments for ACWR

struct GaugeSegments: View {
    let acwr: Double

    var body: some View {
        ZStack {
            // Gray zone: 0-0.8 (undertraining)
            Circle()
                .trim(from: 0, to: 0.13)  // 0.8/6.0 ≈ 0.13 (assuming max 6.0 for visualization)
                .stroke(Color.gray, lineWidth: 16)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))

            // Green zone: 0.8-1.3 (optimal)
            Circle()
                .trim(from: 0.13, to: 0.27)  // 1.3/6.0 ≈ 0.27
                .stroke(Color.neonGreen, lineWidth: 16)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))

            // Orange zone: 1.3-1.5 (overreaching)
            Circle()
                .trim(from: 0.27, to: 0.31)  // 1.5/6.0 ≈ 0.31
                .stroke(Color.warningOrange, lineWidth: 16)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))

            // Red zone: 1.5+ (hazardous)
            Circle()
                .trim(from: 0.31, to: 0.5)
                .stroke(Color.red, lineWidth: 16)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(180))

            // Indicator needle
            NeedleIndicator(value: acwr, maxValue: 3.0)
        }
    }
}

// MARK: - Needle Indicator

struct NeedleIndicator: View {
    let value: Double
    let maxValue: Double

    private var rotation: Double {
        // Map value to 0-180 degrees (half circle)
        let normalized = min(value / maxValue, 1.0)
        return normalized * 180
    }

    var body: some View {
        ZStack {
            // Needle
            Rectangle()
                .fill(.white)
                .frame(width: 3, height: 50)
                .offset(y: -25)
                .rotationEffect(.degrees(rotation), anchor: .bottom)
                .rotationEffect(.degrees(180))  // Start from left

            // Center dot
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
        }
        .offset(y: 20)
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
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
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
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
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
