import Foundation
import HealthKit
import CoreLocation
import Observation

/// ViewModel for ActivityDetailView that handles loading detailed workout data on-demand
@Observable
class ActivityDetailViewModel {
    private let hkManager = HKManager.shared

    var workout: Workout
    var isLoadingDetails = false
    var errorMessage: String?

    init(workout: Workout) {
        self.workout = workout
    }

    /// Loads detailed workout data if not already loaded
    func loadDetailedDataIfNeeded() async {
        // Check if we already have detailed data (samples)
        // If any sample arrays exist, we assume details are already loaded
        if workout.heartRateSamples != nil || workout.speedSamples != nil {
            return
        }

        isLoadingDetails = true
        await loadDetailedData()
        isLoadingDetails = false
    }

    /// Loads all detailed workout data from HealthKit
    private func loadDetailedData() async {
        // We need to fetch the HKWorkout first to query samples
        do {
            let hkWorkouts = try await hkManager.fetchRunningWorkouts(limit: 100)

            // Find the matching HKWorkout by date
            guard let hkWorkout = hkWorkouts.first(where: {
                $0.startDate == workout.startDate && $0.endDate == workout.endDate
            }) else {
                return
            }

            // Load all detailed data in parallel using structured approach
            // Fetch all data concurrently, then merge at the end to avoid race conditions
            async let heartRateSamples = fetchHeartRateSamples(for: hkWorkout)
            async let speedSamples = fetchSpeedSamples(for: hkWorkout)
            async let powerSamples = fetchPowerSamples(for: hkWorkout)
            async let runningMetrics = fetchRunningMetrics(for: hkWorkout)
            async let voSamples = fetchVerticalOscillationSamples(for: hkWorkout)
            async let gctSamples = fetchGroundContactTimeSamples(for: hkWorkout)
            async let strideSamples = fetchStrideLengthSamples(for: hkWorkout)
            async let routeData = fetchRouteData(for: hkWorkout)

            // Wait for all data to be fetched
            let hr = await heartRateSamples
            let speed = await speedSamples
            let power = await powerSamples
            let metrics = await runningMetrics
            let vo = await voSamples
            let gct = await gctSamples
            let stride = await strideSamples
            let (route, elevation) = await routeData

            // Now update workout once with all the data merged together
            var updatedWorkout = workout

            // Add heart rate data
            if let hr = hr {
                updatedWorkout = updatedWorkout.withHeartRateData(hr)
            }

            // Add speed data
            if let speed = speed {
                updatedWorkout = updatedWorkout.withSpeedData(speed)
            }

            // Add power data
            if let power = power {
                updatedWorkout = updatedWorkout.withPowerData(power)
            }

            // Add running metrics (VO, GCT, stride length)
            if let metrics = metrics {
                updatedWorkout = updatedWorkout.withRunningMetrics(
                    verticalOscillation: metrics.vo,
                    groundContactTime: metrics.gct,
                    cadence: nil,  // Will be calculated separately
                    strideLength: metrics.stride
                )
            }

            // Add time-series samples
            if let vo = vo {
                updatedWorkout = updatedWorkout.withVerticalOscillationSamples(vo)
            }
            if let gct = gct {
                updatedWorkout = updatedWorkout.withGroundContactTimeSamples(gct)
            }
            if let stride = stride {
                updatedWorkout = updatedWorkout.withStrideLengthSamples(stride)

                // Calculate cadence from stride and speed if both available
                if let speed = speed {
                    updatedWorkout = updatedWorkout.withCalculatedCadence(
                        strideSamples: stride,
                        speedSamples: speed
                    )
                }
            }

            // Add route and elevation
            if let route = route {
                updatedWorkout = updatedWorkout.withRoute(route)
            }
            if let elevation = elevation {
                updatedWorkout = updatedWorkout.withElevationSamples(elevation)
            }

            // Finally, update the workout property once with all data
            workout = updatedWorkout

        } catch {
            errorMessage = (error as? HKError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Individual Data Fetchers (return data instead of mutating state)

    private func fetchHeartRateSamples(for hkWorkout: HKWorkout) async -> [HKQuantitySample]? {
        guard let hrType = HKTypes.heartRate else { return nil }
        return try? await hkManager.fetchQuantitySamples(for: hrType, during: hkWorkout)
    }

    private func fetchSpeedSamples(for hkWorkout: HKWorkout) async -> [HKQuantitySample]? {
        guard let speedType = HKTypes.runningSpeed else { return nil }
        return try? await hkManager.fetchQuantitySamples(for: speedType, during: hkWorkout)
    }

    private func fetchPowerSamples(for hkWorkout: HKWorkout) async -> [HKQuantitySample]? {
        guard let powerType = HKTypes.runningPower else { return nil }
        return try? await hkManager.fetchQuantitySamples(for: powerType, during: hkWorkout)
    }

    private func fetchRunningMetrics(for hkWorkout: HKWorkout) async -> (vo: [HKQuantitySample]?, gct: [HKQuantitySample]?, stride: [HKQuantitySample]?)? {
        guard let voType = HKTypes.verticalOscillation,
              let gctType = HKTypes.groundContactTime,
              let strideType = HKTypes.runningStrideLength else { return nil }

        async let voSamples = try? hkManager.fetchQuantitySamples(for: voType, during: hkWorkout)
        async let gctSamples = try? hkManager.fetchQuantitySamples(for: gctType, during: hkWorkout)
        async let strideSamples = try? hkManager.fetchQuantitySamples(for: strideType, during: hkWorkout)

        let vo = await voSamples
        let gct = await gctSamples
        let stride = await strideSamples

        return (vo: vo, gct: gct, stride: stride)
    }

    private func fetchVerticalOscillationSamples(for hkWorkout: HKWorkout) async -> [HKQuantitySample]? {
        guard let voType = HKTypes.verticalOscillation else { return nil }
        return try? await hkManager.fetchQuantitySamples(for: voType, during: hkWorkout)
    }

    private func fetchGroundContactTimeSamples(for hkWorkout: HKWorkout) async -> [HKQuantitySample]? {
        guard let gctType = HKTypes.groundContactTime else { return nil }
        return try? await hkManager.fetchQuantitySamples(for: gctType, during: hkWorkout)
    }

    private func fetchStrideLengthSamples(for hkWorkout: HKWorkout) async -> [HKQuantitySample]? {
        guard let strideType = HKTypes.runningStrideLength else { return nil }
        return try? await hkManager.fetchQuantitySamples(for: strideType, during: hkWorkout)
    }

    private func fetchRouteData(for hkWorkout: HKWorkout) async -> (route: [CLLocationCoordinate2D]?, elevation: [CLLocation]?) {
        let route = try? await hkManager.fetchRoute(for: hkWorkout)
        let elevation = try? await hkManager.fetchRouteWithElevation(for: hkWorkout)
        return (route: route, elevation: elevation)
    }
}
