import Foundation
import HealthKit
import CoreLocation
import Observation

@Observable
class DashboardViewModel {
    private let hkManager = HKManager.shared

    var workouts: [Workout] = []
    var restingHeartRate: Double?
    var heartRateVariability: Double?
    var vo2Max: Double?
    var errorMessage: String?
    var isLoading = false

    /// Load all dashboard data (authorization + workouts + wellness metrics)
    func loadAllData() async {
        isLoading = true
        defer { isLoading = false }

        // Step 1: Request authorization
        do {
            try await hkManager.requestAuthorization()
        } catch {
            errorMessage = (error as? HKError)?.errorDescription ?? error.localizedDescription
            return
        }

        // Step 2: Fetch all data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchWorkouts() }
            group.addTask { await self.fetchWellnessMetrics() }
        }
    }

    private func fetchWorkouts() async {
        do {
            let hkWorkouts = try await hkManager.fetchRunningWorkouts(limit: 50)

            // Enrich workouts with additional data
            var enrichedWorkouts: [Workout] = []

            for hkWorkout in hkWorkouts {
                var workout = Workout(from: hkWorkout)

                // Fetch heart rate samples
                if let hrType = HKTypes.heartRate {
                    let hrSamples = try? await hkManager.fetchQuantitySamples(for: hrType, during: hkWorkout)
                    workout = workout.withHeartRateData(hrSamples ?? [])
                }

                // Fetch speed samples
                var speedSamples: [HKQuantitySample]?
                if let speedType = HKTypes.runningSpeed {
                    speedSamples = try? await hkManager.fetchQuantitySamples(for: speedType, during: hkWorkout)
                    workout = workout.withSpeedData(speedSamples ?? [])
                }

                // Fetch power samples
                if let powerType = HKTypes.runningPower {
                    let powerSamples = try? await hkManager.fetchQuantitySamples(for: powerType, during: hkWorkout)
                    workout = workout.withPowerData(powerSamples ?? [])
                }

                // Fetch vertical oscillation time-series samples
                if let voType = HKTypes.verticalOscillation {
                    let voSamples = try? await hkManager.fetchQuantitySamples(for: voType, during: hkWorkout)
                    if let samples = voSamples, !samples.isEmpty {
                        workout = workout.withVerticalOscillationSamples(samples)
                    }
                }

                // Fetch ground contact time time-series samples
                if let gctType = HKTypes.groundContactTime {
                    let gctSamples = try? await hkManager.fetchQuantitySamples(for: gctType, during: hkWorkout)
                    if let samples = gctSamples, !samples.isEmpty {
                        workout = workout.withGroundContactTimeSamples(samples)
                    }
                }

                // Fetch stride length time-series samples
                var strideSamples: [HKQuantitySample]?
                if let strideType = HKTypes.strideLength {
                    strideSamples = try? await hkManager.fetchQuantitySamples(for: strideType, during: hkWorkout)
                    if let samples = strideSamples, !samples.isEmpty {
                        workout = workout.withStrideLengthSamples(samples)
                    }
                }

                // Calculate cadence from stride length and speed
                if let strideSamples = strideSamples, !strideSamples.isEmpty,
                   let speedSamples = speedSamples, !speedSamples.isEmpty {
                    workout = workout.withCalculatedCadence(
                        strideSamples: strideSamples,
                        speedSamples: speedSamples
                    )
                }

                // Fetch running form metrics (averages)
                workout = await fetchRunningMetrics(for: hkWorkout, into: workout)

                // Fetch GPS route with elevation data
                if let locations = try? await hkManager.fetchRouteWithElevation(for: hkWorkout) {
                    // Extract coordinates for route display
                    let coordinates = locations.map { $0.coordinate }
                    workout = workout.withRoute(coordinates)

                    // Extract elevation samples
                    workout = workout.withElevationSamples(locations)
                }

                enrichedWorkouts.append(workout)
            }

            self.workouts = enrichedWorkouts
        } catch {
            errorMessage = (error as? HKError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func fetchRunningMetrics(for hkWorkout: HKWorkout, into workout: Workout) async -> Workout {
        // Fetch all running form metrics
        let voSamples: [HKQuantitySample]? = if let voType = HKTypes.verticalOscillation {
            try? await hkManager.fetchQuantitySamples(for: voType, during: hkWorkout)
        } else {
            nil
        }

        let gctSamples: [HKQuantitySample]? = if let gctType = HKTypes.groundContactTime {
            try? await hkManager.fetchQuantitySamples(for: gctType, during: hkWorkout)
        } else {
            nil
        }

        let strideSamples: [HKQuantitySample]? = if let strideType = HKTypes.strideLength {
            try? await hkManager.fetchQuantitySamples(for: strideType, during: hkWorkout)
        } else {
            nil
        }

        // Note: Cadence is typically not available directly, calculated from stride and speed
        let cadenceSamples: [HKQuantitySample]? = nil

        return workout.withRunningMetrics(
            verticalOscillation: voSamples,
            groundContactTime: gctSamples,
            cadence: cadenceSamples,
            strideLength: strideSamples
        )
    }

    private func fetchWellnessMetrics() async {
        // Fetch RHR
        if let rhrSample = try? await hkManager.fetchLatestRestingHeartRate() {
            self.restingHeartRate = rhrSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }

        // Fetch HRV
        if let hrvSample = try? await hkManager.fetchLatestHeartRateVariability() {
            self.heartRateVariability = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        }

        // Fetch VO2 Max
        if let vo2Sample = try? await hkManager.fetchLatestVO2Max() {
            self.vo2Max = vo2Sample.quantity.doubleValue(for: HKUnit.literUnit(with: .milli)
                .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                .unitDivided(by: .minute()))
        }
    }
}

// MARK: - Helper Extensions

extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

extension RunningMetrics {
    var hasAnyData: Bool {
        verticalOscillation != nil ||
        groundContactTime != nil ||
        cadence != nil ||
        strideLength != nil ||
        groundContactTimeBalance != nil
    }
}
