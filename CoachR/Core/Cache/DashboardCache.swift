import Foundation

/// Manages caching of Dashboard data for fast startup
class DashboardCache {
    static let shared = DashboardCache()

    private let userDefaults = UserDefaults.standard
    private let workoutsCacheKey = "dashboard.workouts.cache"
    private let metricsCacheKey = "dashboard.metrics.cache"
    private let cacheTimestampKey = "dashboard.cache.timestamp"
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour

    private init() {}

    // MARK: - Workouts Cache

    func cacheWorkouts(_ workouts: [Workout]) {
        guard let encoded = try? JSONEncoder().encode(workouts.map { CachedWorkout(from: $0) }) else {
            return
        }

        userDefaults.set(encoded, forKey: workoutsCacheKey)
        userDefaults.set(Date(), forKey: cacheTimestampKey)
    }

    func getCachedWorkouts() -> [Workout]? {
        // Check if cache is still valid
        guard isCacheValid() else {
            clearCache()
            return nil
        }

        guard let data = userDefaults.data(forKey: workoutsCacheKey),
              let cachedWorkouts = try? JSONDecoder().decode([CachedWorkout].self, from: data) else {
            return nil
        }

        return cachedWorkouts.map { $0.toWorkout() }
    }

    // MARK: - Wellness Metrics Cache

    func cacheMetrics(rhr: Double?, hrv: Double?, vo2Max: Double?) {
        let metrics = CachedMetrics(rhr: rhr, hrv: hrv, vo2Max: vo2Max)

        guard let encoded = try? JSONEncoder().encode(metrics) else {
            return
        }

        userDefaults.set(encoded, forKey: metricsCacheKey)
    }

    func getCachedMetrics() -> CachedMetrics? {
        guard isCacheValid() else {
            return nil
        }

        guard let data = userDefaults.data(forKey: metricsCacheKey),
              let metrics = try? JSONDecoder().decode(CachedMetrics.self, from: data) else {
            return nil
        }

        return metrics
    }

    // MARK: - Cache Management

    private func isCacheValid() -> Bool {
        guard let timestamp = userDefaults.object(forKey: cacheTimestampKey) as? Date else {
            return false
        }

        let age = Date().timeIntervalSince(timestamp)
        return age < cacheValidityDuration
    }

    func clearCache() {
        userDefaults.removeObject(forKey: workoutsCacheKey)
        userDefaults.removeObject(forKey: metricsCacheKey)
        userDefaults.removeObject(forKey: cacheTimestampKey)
    }
}

// MARK: - Cached Data Models

/// Lightweight workout representation for caching
struct CachedWorkout: Codable {
    let id: String
    let startDate: Date
    let endDate: Date
    let distance: Double
    let duration: Double
    let activeEnergyBurned: Double?
    let averageHeartRate: Double?

    init(from workout: Workout) {
        self.id = workout.id.uuidString
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.distance = workout.distance
        self.duration = workout.duration
        self.activeEnergyBurned = workout.activeEnergyBurned
        self.averageHeartRate = workout.averageHeartRate
    }

    func toWorkout() -> Workout {
        Workout(
            id: UUID(uuidString: id) ?? UUID(),
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            duration: duration,
            activeEnergyBurned: activeEnergyBurned,
            averageHeartRate: averageHeartRate
        )
    }
}

/// Cached wellness metrics
struct CachedMetrics: Codable {
    let rhr: Double?
    let hrv: Double?
    let vo2Max: Double?
}
