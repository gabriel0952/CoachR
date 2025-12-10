import Foundation
import HealthKit
import CoreLocation
import Observation

@Observable
class DashboardViewModel {
    private let hkManager = HKManager.shared
    private let cache = DashboardCache.shared

    var workouts: [Workout] = []
    var restingHeartRate: Double?
    var heartRateVariability: Double?
    var vo2Max: Double?
    var racePredictions: [RacePredictor.RacePrediction]?
    var predictionSeedWorkout: Workout?
    var trainingStatus: TrainingLoadEngine.TrainingStatus?
    var errorMessage: String?
    var isLoading = false

    /// Load all dashboard data with caching strategy
    func loadAllData() async {
        // Step 1: Load cached data immediately (fast)
        loadCachedData()

        // Step 2: Request authorization
        do {
            try await hkManager.requestAuthorization()
        } catch {
            errorMessage = (error as? HKError)?.errorDescription ?? error.localizedDescription
            return
        }

        // Step 3: Fetch fresh data in background (slower but accurate)
        isLoading = true
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchBasicWorkouts() }
            group.addTask { await self.fetchWellnessMetrics() }
        }
        isLoading = false

        // Step 4: Save fresh data to cache
        saveCachedData()
    }

    /// Load cached data immediately for instant UI
    private func loadCachedData() {
        if let cachedWorkouts = cache.getCachedWorkouts() {
            self.workouts = cachedWorkouts
        }
        if let cachedMetrics = cache.getCachedMetrics() {
            self.restingHeartRate = cachedMetrics.rhr
            self.heartRateVariability = cachedMetrics.hrv
            self.vo2Max = cachedMetrics.vo2Max
        }
    }

    /// Save current data to cache
    private func saveCachedData() {
        cache.cacheWorkouts(workouts)
        cache.cacheMetrics(
            rhr: restingHeartRate,
            hrv: heartRateVariability,
            vo2Max: vo2Max
        )
    }

    /// Fetch basic workout data (fast) - only what Dashboard needs
    private func fetchBasicWorkouts() async {
        do {
            // Fetch last 60 workouts (approximately 8 weeks worth) for race predictions
            let hkWorkouts = try await hkManager.fetchRunningWorkouts(limit: 60)

            // Convert to basic Workout objects (no detailed samples)
            let basicWorkouts = hkWorkouts.map { Workout(from: $0) }

            self.workouts = basicWorkouts

            // Calculate race predictions based on recent workout history
            if let result = RacePredictor.predictRaces(from: basicWorkouts) {
                self.racePredictions = result.predictions
                self.predictionSeedWorkout = result.seedWorkout
            } else {
                self.racePredictions = nil
                self.predictionSeedWorkout = nil
            }

            // Calculate training load metrics
            calculateTrainingLoad()
        } catch {
            errorMessage = (error as? HKError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Load more workouts for Activity view (50 total instead of 10)
    func loadMoreWorkoutsForActivity() async {
        // If we already have more than 10 workouts, no need to reload
        if workouts.count > 10 {
            return
        }

        isLoading = true
        do {
            // Fetch more workouts (50) for Activity view
            let hkWorkouts = try await hkManager.fetchRunningWorkouts(limit: 50)
            let basicWorkouts = hkWorkouts.map { Workout(from: $0) }
            self.workouts = basicWorkouts
        } catch {
            errorMessage = (error as? HKError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
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

    /// Calculate training load metrics (ATL, CTL, ACWR)
    private func calculateTrainingLoad() {
        guard let rhr = restingHeartRate else {
            self.trainingStatus = nil
            return
        }

        // Estimate max HR using age-based formula (220 - age)
        // For now, use a reasonable estimate if we don't have age
        // TODO: Get actual user age from HealthKit
        let estimatedMaxHR = 190.0  // Conservative estimate for adult runners

        let userMetrics = TrainingLoadEngine.UserMetrics(
            maxHR: estimatedMaxHR,
            restingHR: rhr,
            gender: .male  // TODO: Get actual gender from HealthKit
        )

        self.trainingStatus = TrainingLoadEngine.calculateLoadMetrics(
            from: workouts,
            userMetrics: userMetrics
        )
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
