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
    @State private var viewModel: ActivityDetailViewModel

    init(workout: Workout) {
        _viewModel = State(initialValue: ActivityDetailViewModel(workout: workout))
    }

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
                    if let metrics = viewModel.workout.metrics {
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
                    Text(viewModel.workout.endDate, style: .date)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)

                    Text(viewModel.workout.endDate, style: .time)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
        .overlay {
            if viewModel.isLoadingDetails {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .neonGreen))
                            .scaleEffect(1.5)

                        Text("載入詳細資料...")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                }
            }
        }
        .task {
            await viewModel.loadDetailedDataIfNeeded()
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        GeometryReader { geometry in
            ZStack {
                if let route = viewModel.workout.route {
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
                            Text(String(format: "%.2f km", viewModel.workout.distanceInKilometers))
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
                    value: String(format: "%.2f", viewModel.workout.distanceInKilometers),
                    unit: "km",
                    color: .neonGreen
                )

                SummaryStatCard(
                    icon: "clock",
                    label: "時間",
                    value: viewModel.workout.formattedDuration,
                    unit: "",
                    color: .neonGreen
                )

                SummaryStatCard(
                    icon: "speedometer",
                    label: "配速",
                    value: viewModel.workout.formattedPace,
                    unit: "/km",
                    color: .neonGreen
                )
            }

            // Row 2
            HStack(spacing: 16) {
                if let avgHR = viewModel.workout.averageHeartRate {
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

                if let calories = viewModel.workout.activeEnergyBurned {
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

                if let avgPower = viewModel.workout.averagePower {
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
        let splits = viewModel.workout.calculateKilometerSplits()

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
            if let hrSamples = viewModel.workout.heartRateSamples, !hrSamples.isEmpty {
                ChartCard(title: "心率") {
                    heartRateChart(hrSamples: hrSamples)
                }
            } else {
                EmptyChartCard(title: "心率", icon: "heart.fill", color: .red)
            }

            // Chart 2: Pace
            if let speedSamples = viewModel.workout.speedSamples, !speedSamples.isEmpty {
                ChartCard(title: "配速") {
                    paceChart(speedSamples: speedSamples)
                }
            } else {
                EmptyChartCard(title: "配速", icon: "speedometer", color: .neonGreen)
            }

            // Chart 3: Power Distribution
            if let powerSamples = viewModel.workout.powerSamples, !powerSamples.isEmpty {
                ChartCard(title: "功率分佈") {
                    powerDistributionChart(powerSamples: powerSamples)
                }
            } else {
                EmptyChartCard(title: "功率", icon: "bolt.fill", color: .yellow)
            }

            // Chart 4: Elevation
            if let elevationSamples = viewModel.workout.elevationSamples, !elevationSamples.isEmpty {
                ChartCard(title: "高度變化") {
                    elevationChart(elevationSamples: elevationSamples)
                }
            } else {
                EmptyChartCard(title: "高度變化", icon: "mountain.2.fill", color: .brown)
            }

            // Chart 5: Cadence
            if let cadenceSamples = viewModel.workout.cadenceSamples, !cadenceSamples.isEmpty {
                ChartCard(title: "步頻") {
                    cadenceChart(cadenceSamples: cadenceSamples)
                }
            } else {
                EmptyChartCard(title: "步頻", icon: "metronome", color: .cyan)
            }

            // Chart 6: Vertical Oscillation
            if let voSamples = viewModel.workout.verticalOscillationSamples, !voSamples.isEmpty {
                ChartCard(title: "垂直振幅") {
                    verticalOscillationChart(voSamples: voSamples)
                }
            } else {
                EmptyChartCard(title: "垂直振幅", icon: "arrow.up.and.down", color: .purple)
            }

            // Chart 7: Ground Contact Time
            if let gctSamples = viewModel.workout.groundContactTimeSamples, !gctSamples.isEmpty {
                ChartCard(title: "觸地時間") {
                    groundContactTimeChart(gctSamples: gctSamples)
                }
            } else {
                EmptyChartCard(title: "觸地時間", icon: "timer", color: .orange)
            }

            // Chart 8: Stride Length
            if let strideSamples = viewModel.workout.strideLengthSamples, !strideSamples.isEmpty {
                ChartCard(title: "步長") {
                    strideLengthChart(strideSamples: strideSamples)
                }
            } else {
                EmptyChartCard(title: "步長", icon: "ruler", color: .green)
            }
        }
    }

    private func heartRateChart(hrSamples: [HeartRateSample]) -> some View {
        let avgHR = hrSamples.map(\.value).reduce(0, +) / Double(hrSamples.count)
        let maxHR = hrSamples.map(\.value).max() ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(hrSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    LineMark(
                        x: .value("Distance", distanceKm),
                        y: .value("Heart Rate", sample.value)
                    )
                    .foregroundStyle(Color.red)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            HStack(spacing: 16) {
                ChartStatItem(label: "平均心率", value: String(format: "%.0f", avgHR), unit: "bpm", color: .red)
                ChartStatItem(label: "最大心率", value: String(format: "%.0f", maxHR), unit: "bpm", color: .red)
            }
        }
    }

    private func paceChart(speedSamples: [SpeedSample]) -> some View {
        // Filter out anomalous pace values
        let filteredSamples = filterAnomalousPaceData(speedSamples)

        // Calculate statistics
        let avgPace = viewModel.workout.averagePace
        let bestPace = filteredSamples.map(\.pacePerKm).min() ?? 0
        let movingTime = viewModel.workout.formattedDuration
        let elapsedTime = viewModel.workout.formattedDuration // 如果有停止時間，這裡應該不同

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(filteredSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    LineMark(
                        x: .value("Distance", distanceKm),
                        y: .value("Pace", sample.pacePerKm)
                    )
                    .foregroundStyle(Color.neonGreen)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
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
            .chartYScale(domain: .automatic(includesZero: false, reversed: true))
            .padding(.leading, 8)

            // Statistics
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    ChartStatItem(label: "平均配速", value: formatPace(avgPace), unit: "/km", color: .neonGreen)
                    ChartStatItem(label: "最快配速", value: formatPace(bestPace), unit: "/km", color: .neonGreen)
                }
                HStack(spacing: 16) {
                    ChartStatItem(label: "移動時間", value: movingTime, unit: "", color: .neonGreen)
                    ChartStatItem(label: "經過時間", value: elapsedTime, unit: "", color: .neonGreen)
                }
            }
        }
    }

    private func powerDistributionChart(powerSamples: [PowerSample]) -> some View {
        let avgPower = powerSamples.map(\.value).reduce(0, +) / Double(powerSamples.count)
        let maxPower = powerSamples.map(\.value).max() ?? 0
        let totalWork = powerSamples.map(\.value).reduce(0, +) * (viewModel.workout.duration / Double(powerSamples.count)) // 簡化計算

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(powerSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    AreaMark(
                        x: .value("Distance", distanceKm),
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
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            HStack(spacing: 16) {
                ChartStatItem(label: "平均功率", value: String(format: "%.0f", avgPower), unit: "W", color: .yellow)
                ChartStatItem(label: "總工作量", value: String(format: "%.0f", totalWork / 1000), unit: "kJ", color: .yellow)
                ChartStatItem(label: "最大功率", value: String(format: "%.0f", maxPower), unit: "W", color: .yellow)
            }
        }
    }

    private func elevationChart(elevationSamples: [ElevationSample]) -> some View {
        let elevationGain = calculateElevationGain(elevationSamples)
        let maxElevation = elevationSamples.map(\.value).max() ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(elevationSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    AreaMark(
                        x: .value("Distance", distanceKm),
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
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            HStack(spacing: 16) {
                ChartStatItem(label: "爬升海拔", value: String(format: "%.0f", elevationGain), unit: "m", color: .brown)
                ChartStatItem(label: "最高海拔", value: String(format: "%.0f", maxElevation), unit: "m", color: .brown)
            }
        }
    }

    private func cadenceChart(cadenceSamples: [CadenceSample]) -> some View {
        let avgCadence = cadenceSamples.map(\.value).reduce(0, +) / Double(cadenceSamples.count)

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(cadenceSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    LineMark(
                        x: .value("Distance", distanceKm),
                        y: .value("Cadence", sample.value)
                    )
                    .foregroundStyle(Color.cyan)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            ChartStatItem(label: "平均步頻", value: String(format: "%.0f", avgCadence), unit: "spm", color: .cyan)
        }
    }

    private func verticalOscillationChart(voSamples: [VerticalOscillationSample]) -> some View {
        let avgVO = voSamples.map(\.value).reduce(0, +) / Double(voSamples.count)

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(voSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    LineMark(
                        x: .value("Distance", distanceKm),
                        y: .value("Vertical Oscillation", sample.value)
                    )
                    .foregroundStyle(Color.purple)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            ChartStatItem(label: "平均振幅", value: String(format: "%.1f", avgVO), unit: "cm", color: .purple)
        }
    }

    private func groundContactTimeChart(gctSamples: [GroundContactTimeSample]) -> some View {
        let avgGCT = gctSamples.map(\.value).reduce(0, +) / Double(gctSamples.count)

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(gctSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    LineMark(
                        x: .value("Distance", distanceKm),
                        y: .value("Ground Contact Time", sample.value)
                    )
                    .foregroundStyle(Color.orange)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            ChartStatItem(label: "平均時間", value: String(format: "%.0f", avgGCT), unit: "ms", color: .orange)
        }
    }

    private func strideLengthChart(strideSamples: [StrideLengthSample]) -> some View {
        let avgStride = strideSamples.map(\.value).reduce(0, +) / Double(strideSamples.count)

        return VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(strideSamples) { sample in
                    let distanceKm = calculateDistanceAtTime(sample.timestamp)
                    LineMark(
                        x: .value("Distance", distanceKm),
                        y: .value("Stride Length", sample.value)
                    )
                    .foregroundStyle(Color.green)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let km = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", km))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...viewModel.workout.distanceInKilometers)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.leading, 8)

            // Statistics
            ChartStatItem(label: "平均步長", value: String(format: "%.2f", avgStride), unit: "m", color: .green)
        }
    }

    // MARK: - Helper Functions

    /// Calculates the approximate distance (in kilometers) at a specific timestamp during the workout
    /// Uses linear interpolation based on the workout's total distance and duration
    private func calculateDistanceAtTime(_ timestamp: Date) -> Double {
        let elapsed = timestamp.timeIntervalSince(viewModel.workout.startDate)
        let progress = elapsed / viewModel.workout.duration
        return progress * viewModel.workout.distanceInKilometers
    }

    /// Filters out anomalous pace data points that would distort the chart
    /// Removes samples with unrealistic pace values (too fast or too slow)
    private func filterAnomalousPaceData(_ samples: [SpeedSample]) -> [SpeedSample] {
        guard !samples.isEmpty else { return samples }

        // Calculate median pace for robust central tendency
        let paces = samples.map { $0.pacePerKm }.sorted()
        let medianPace: Double
        if paces.count % 2 == 0 {
            medianPace = (paces[paces.count / 2 - 1] + paces[paces.count / 2]) / 2.0
        } else {
            medianPace = paces[paces.count / 2]
        }

        // Define reasonable pace bounds (in seconds per km)
        // Typical running pace: 3:00/km (180s) to 12:00/km (720s)
        let minReasonablePace: Double = 150  // Faster than 2:30/km is likely error
        let maxReasonablePace: Double = 900  // Slower than 15:00/km is likely error

        // Also use median-based filtering to catch outliers
        // Allow pace within 3x of median (catches walking/stopping)
        let medianBasedMax = medianPace * 3.0
        let medianBasedMin = medianPace / 2.0

        // Combine both filters
        let effectiveMax = min(maxReasonablePace, medianBasedMax)
        let effectiveMin = max(minReasonablePace, medianBasedMin)

        return samples.filter { sample in
            let pace = sample.pacePerKm
            return pace >= effectiveMin && pace <= effectiveMax
        }
    }

    /// Formats pace in seconds to MM:SS string
    private func formatPace(_ paceSeconds: Double) -> String {
        let minutes = Int(paceSeconds / 60)
        let seconds = Int(paceSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Calculates total elevation gain from elevation samples
    private func calculateElevationGain(_ samples: [ElevationSample]) -> Double {
        guard samples.count > 1 else { return 0 }

        var totalGain: Double = 0
        for i in 1..<samples.count {
            let elevationChange = samples[i].value - samples[i-1].value
            if elevationChange > 0 {
                totalGain += elevationChange
            }
        }
        return totalGain
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

/// Chart statistic item for displaying key metrics below charts
struct ChartStatItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.gray)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.cardBackground.opacity(0.5))
        .cornerRadius(8)
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
