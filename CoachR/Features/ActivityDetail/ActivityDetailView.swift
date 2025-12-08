import SwiftUI
import Charts
import MapKit

/// 運動詳情頁面
///
/// 根據 PRD 規格實現：
/// - 頂部 35% 地圖區域顯示路徑
/// - 2x3 統計網格
/// - Swift Charts 圖表（心率、配速、功率）
/// - 跑姿分析（優雅降級）
struct ActivityDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header: Map Section (35% height)
                mapSection

                // Content sections
                VStack(spacing: 24) {
                    // Summary Grid (2x3)
                    summaryGrid
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Kilometer Splits Section
                    kilometerSplitsSection
                        .padding(.horizontal, 16)

                    // Charts Section
                    chartsSection
                        .padding(.horizontal, 16)

                    // Running Form Metrics (graceful degradation)
                    if let metrics = workout.metrics {
                        runningFormSection(metrics: metrics)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(workout.endDate, style: .date)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)

                    Text(workout.endDate, style: .time)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        GeometryReader { geometry in
            ZStack {
                if let route = workout.route {
                    RouteMapView(coordinates: route)
                } else {
                    // Placeholder when no route available
                    Color.gray.opacity(0.2)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)

                                Text("無路徑資料")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        )
                }

                // Distance overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                                .font(.caption)
                            Text(String(format: "%.2f km", workout.distanceInKilometers))
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding(16)
                    }
                }
            }
            .frame(height: geometry.size.height)
        }
        .frame(height: 300) // Fixed height instead of screen-based
    }

    // MARK: - Summary Grid

    private var summaryGrid: some View {
        VStack(spacing: 16) {
            // Row 1
            HStack(spacing: 16) {
                SummaryStatCard(
                    icon: "figure.run",
                    label: "距離",
                    value: String(format: "%.2f", workout.distanceInKilometers),
                    unit: "km",
                    color: .neonGreen
                )

                SummaryStatCard(
                    icon: "clock",
                    label: "時間",
                    value: workout.formattedDuration,
                    unit: "",
                    color: .neonGreen
                )

                SummaryStatCard(
                    icon: "speedometer",
                    label: "配速",
                    value: workout.formattedPace,
                    unit: "/km",
                    color: .neonGreen
                )
            }

            // Row 2
            HStack(spacing: 16) {
                if let avgHR = workout.averageHeartRate {
                    SummaryStatCard(
                        icon: "heart.fill",
                        label: "平均心率",
                        value: "\(Int(avgHR))",
                        unit: "bpm",
                        color: .red
                    )
                } else {
                    EmptyStatCard(label: "心率")
                }

                if let calories = workout.activeEnergyBurned {
                    SummaryStatCard(
                        icon: "flame.fill",
                        label: "卡路里",
                        value: "\(Int(calories))",
                        unit: "kcal",
                        color: .warningOrange
                    )
                } else {
                    EmptyStatCard(label: "卡路里")
                }

                if let avgPower = workout.averagePower {
                    SummaryStatCard(
                        icon: "bolt.fill",
                        label: "平均功率",
                        value: "\(Int(avgPower))",
                        unit: "W",
                        color: .yellow
                    )
                } else {
                    EmptyStatCard(label: "功率")
                }
            }
        }
    }

    // MARK: - Kilometer Splits Section

    private var kilometerSplitsSection: some View {
        let splits = workout.calculateKilometerSplits()

        guard !splits.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Section Title
                HStack {
                    Image(systemName: "list.number")
                        .foregroundColor(.neonGreen)
                        .font(.title3)

                    Text("分段配速")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()
                }

                // Table
                VStack(spacing: 0) {
                    // Header Row
                    HStack(spacing: 0) {
                        Text("公里")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(width: 60, alignment: .center)

                        Text("配速")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("海拔(m)")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("心率")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 12)
                    .background(Color.cardBackground.opacity(0.5))

                    // Data Rows
                    ForEach(splits) { split in
                        HStack(spacing: 0) {
                            Text("\(split.kilometer)")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60, alignment: .center)

                            Text(split.formattedPace)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.neonGreen)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Text(split.formattedElevation)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.brown)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Text(split.formattedHeartRate)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 10)
                        .background(
                            split.kilometer % 2 == 0
                                ? Color.cardBackground.opacity(0.3)
                                : Color.clear
                        )
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(16)
        )
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(spacing: 24) {
            // Chart 1: Heart Rate
            if let hrSamples = workout.heartRateSamples, !hrSamples.isEmpty {
                ChartCard(title: "心率") {
                    heartRateChart(hrSamples: hrSamples)
                }
            } else {
                EmptyChartCard(title: "心率", icon: "heart.fill", color: .red)
            }

            // Chart 2: Pace
            if let speedSamples = workout.speedSamples, !speedSamples.isEmpty {
                ChartCard(title: "配速") {
                    paceChart(speedSamples: speedSamples)
                }
            } else {
                EmptyChartCard(title: "配速", icon: "speedometer", color: .neonGreen)
            }

            // Chart 3: Power Distribution
            if let powerSamples = workout.powerSamples, !powerSamples.isEmpty {
                ChartCard(title: "功率分佈") {
                    powerDistributionChart(powerSamples: powerSamples)
                }
            } else {
                EmptyChartCard(title: "功率", icon: "bolt.fill", color: .yellow)
            }

            // Chart 4: Elevation
            if let elevationSamples = workout.elevationSamples, !elevationSamples.isEmpty {
                ChartCard(title: "高度變化") {
                    elevationChart(elevationSamples: elevationSamples)
                }
            } else {
                EmptyChartCard(title: "高度變化", icon: "mountain.2.fill", color: .brown)
            }

            // Chart 5: Cadence
            if let cadenceSamples = workout.cadenceSamples, !cadenceSamples.isEmpty {
                ChartCard(title: "步頻") {
                    cadenceChart(cadenceSamples: cadenceSamples)
                }
            } else {
                EmptyChartCard(title: "步頻", icon: "metronome", color: .cyan)
            }

            // Chart 6: Vertical Oscillation
            if let voSamples = workout.verticalOscillationSamples, !voSamples.isEmpty {
                ChartCard(title: "垂直振幅") {
                    verticalOscillationChart(voSamples: voSamples)
                }
            } else {
                EmptyChartCard(title: "垂直振幅", icon: "arrow.up.and.down", color: .purple)
            }

            // Chart 7: Ground Contact Time
            if let gctSamples = workout.groundContactTimeSamples, !gctSamples.isEmpty {
                ChartCard(title: "觸地時間") {
                    groundContactTimeChart(gctSamples: gctSamples)
                }
            } else {
                EmptyChartCard(title: "觸地時間", icon: "timer", color: .orange)
            }

            // Chart 8: Stride Length
            if let strideSamples = workout.strideLengthSamples, !strideSamples.isEmpty {
                ChartCard(title: "步長") {
                    strideLengthChart(strideSamples: strideSamples)
                }
            } else {
                EmptyChartCard(title: "步長", icon: "ruler", color: .green)
            }
        }
    }

    private func heartRateChart(hrSamples: [HeartRateSample]) -> some View {
        Chart {
            ForEach(hrSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                LineMark(
                    x: .value("Time", elapsed),
                    y: .value("Heart Rate", sample.value)
                )
                .foregroundStyle(Color.red)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func paceChart(speedSamples: [SpeedSample]) -> some View {
        Chart {
            ForEach(speedSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                LineMark(
                    x: .value("Time", elapsed),
                    y: .value("Pace", sample.pacePerKm)
                )
                .foregroundStyle(Color.neonGreen)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let paceSeconds = value.as(Double.self) {
                    let minutes = Int(paceSeconds / 60)
                    let seconds = Int(paceSeconds.truncatingRemainder(dividingBy: 60))
                    AxisValueLabel {
                        Text(String(format: "%d:%02d", minutes, seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
    }

    private func powerDistributionChart(powerSamples: [PowerSample]) -> some View {
        Chart {
            ForEach(powerSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                AreaMark(
                    x: .value("Time", elapsed),
                    y: .value("Power", sample.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.6), Color.yellow.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func elevationChart(elevationSamples: [ElevationSample]) -> some View {
        Chart {
            ForEach(elevationSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                AreaMark(
                    x: .value("Time", elapsed),
                    y: .value("Elevation", sample.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.6), Color.brown.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func cadenceChart(cadenceSamples: [CadenceSample]) -> some View {
        Chart {
            ForEach(cadenceSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                LineMark(
                    x: .value("Time", elapsed),
                    y: .value("Cadence", sample.value)
                )
                .foregroundStyle(Color.cyan)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func verticalOscillationChart(voSamples: [VerticalOscillationSample]) -> some View {
        Chart {
            ForEach(voSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                LineMark(
                    x: .value("Time", elapsed),
                    y: .value("Vertical Oscillation", sample.value)
                )
                .foregroundStyle(Color.purple)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func groundContactTimeChart(gctSamples: [GroundContactTimeSample]) -> some View {
        Chart {
            ForEach(gctSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                LineMark(
                    x: .value("Time", elapsed),
                    y: .value("Ground Contact Time", sample.value)
                )
                .foregroundStyle(Color.orange)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    private func strideLengthChart(strideSamples: [StrideLengthSample]) -> some View {
        Chart {
            ForEach(strideSamples.prefix(100)) { sample in
                let elapsed = sample.timestamp.timeIntervalSince(workout.startDate)
                LineMark(
                    x: .value("Time", elapsed),
                    y: .value("Stride Length", sample.value)
                )
                .foregroundStyle(Color.green)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if let seconds = value.as(TimeInterval.self) {
                    AxisValueLabel {
                        Text(formatElapsedTime(seconds))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.gray)
            }
        }
    }

    // MARK: - Helper Functions

    /// Formats elapsed time from workout start as HH:MM:SS or MM:SS
    private func formatElapsedTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    // MARK: - Running Form Section (Graceful Degradation)

    private func runningFormSection(metrics: RunningMetrics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .foregroundColor(.neonGreen)
                    .font(.title3)

                Text("跑姿分析")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // Metrics Grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                if let cadence = metrics.cadence {
                    RunningMetricCard(
                        icon: "metronome",
                        label: "步頻",
                        value: "\(Int(cadence))",
                        unit: "spm",
                        color: .cyan
                    )
                }

                if let vo = metrics.verticalOscillation {
                    RunningMetricCard(
                        icon: "arrow.up.and.down",
                        label: "垂直振幅",
                        value: String(format: "%.1f", vo),
                        unit: "cm",
                        color: .purple
                    )
                }

                if let gct = metrics.groundContactTime {
                    RunningMetricCard(
                        icon: "timer",
                        label: "觸地時間",
                        value: "\(Int(gct))",
                        unit: "ms",
                        color: .orange
                    )
                }

                if let stride = metrics.strideLength {
                    RunningMetricCard(
                        icon: "ruler",
                        label: "步長",
                        value: String(format: "%.2f", stride),
                        unit: "m",
                        color: .green
                    )
                }

                if let voRatio = metrics.verticalOscillationRatio {
                    RunningMetricCard(
                        icon: "percent",
                        label: "垂直振幅比",
                        value: String(format: "%.1f", voRatio),
                        unit: "%",
                        color: .pink
                    )
                }

                if let balance = metrics.groundContactTimeBalance {
                    RunningMetricCard(
                        icon: "scalemass",
                        label: "觸地平衡",
                        value: String(format: "%.1f", balance),
                        unit: "%",
                        color: .mint
                    )
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

/// Map view for displaying route
struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Map(initialPosition: .automatic) {
            // Draw route polyline
            MapPolyline(coordinates: coordinates)
                .stroke(Color.neonGreen, lineWidth: 3)

            // Start marker
            if let first = coordinates.first {
                Annotation("起點", coordinate: first) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }

            // End marker
            if let last = coordinates.last {
                Annotation("終點", coordinate: last) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

/// Summary statistic card
struct SummaryStatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

/// Empty stat card for unavailable data
struct EmptyStatCard: View {
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "minus.circle")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)

            Text("無資料")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

/// Chart container card
struct ChartCard<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            content()
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

/// Empty chart card for unavailable data
struct EmptyChartCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color.opacity(0.5))

                Text("無資料")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        }
        .padding(20)
        .background(Color.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }
}

/// Running metric card for form analysis
struct RunningMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            // Label
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.gray)

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActivityDetailView(workout: MockData.longRunWithAdvancedMetrics)
    }
}
