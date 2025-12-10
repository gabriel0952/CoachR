import Foundation

/// Race prediction using Riegel's Formula: T2 = T1 * (D2 / D1)^1.06
struct RacePredictor {

    /// Standard race distances in meters
    enum RaceDistance: Double, CaseIterable {
        case fiveK = 5000
        case tenK = 10000
        case halfMarathon = 21097.5
        case marathon = 42195

        var displayName: String {
            switch self {
            case .fiveK: return "5K"
            case .tenK: return "10K"
            case .halfMarathon: return "Half"
            case .marathon: return "Full"
            }
        }

        var distanceInKm: Double {
            rawValue / 1000.0
        }
    }

    /// Represents a predicted race time
    struct RacePrediction: Identifiable {
        let id = UUID()
        let distance: RaceDistance
        let predictedTime: TimeInterval

        var formattedTime: String {
            let hours = Int(predictedTime) / 3600
            let minutes = (Int(predictedTime) % 3600) / 60
            let seconds = Int(predictedTime) % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
    }

    /// Result containing predictions and the seed workout used
    struct PredictionResult {
        let predictions: [RacePrediction]
        let seedWorkout: Workout
    }

    // MARK: - Public Interface

    /// Generates race predictions based on recent workout history
    /// - Parameter workouts: Array of workouts to analyze
    /// - Returns: Prediction result with predictions and seed workout, or nil if insufficient data
    static func predictRaces(from workouts: [Workout]) -> PredictionResult? {
        guard let seedRun = findBestRecentRun(from: workouts) else {
            return nil
        }

        let seedDistance = seedRun.distance // in meters
        let seedTime = seedRun.duration // in seconds

        var predictions: [RacePrediction] = []

        for raceDistance in RaceDistance.allCases {
            let predictedTime = calculatePredictedTime(
                seedTime: seedTime,
                seedDistance: seedDistance,
                targetDistance: raceDistance.rawValue
            )

            predictions.append(RacePrediction(
                distance: raceDistance,
                predictedTime: predictedTime
            ))
        }

        return PredictionResult(predictions: predictions, seedWorkout: seedRun)
    }

    // MARK: - Private Helper Methods

    /// Finds the best recent run to use as the seed for predictions
    /// - Parameter workouts: Array of workouts to analyze
    /// - Returns: The best qualifying workout, or nil if none found
    private static func findBestRecentRun(from workouts: [Workout]) -> Workout? {
        let eightWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? Date()
        let minimumDistance: Double = 3000 // 3km in meters

        // Filter workouts from last 8 weeks with minimum distance
        let recentQualifyingRuns = workouts.filter { workout in
            workout.endDate >= eightWeeksAgo &&
            workout.distance >= minimumDistance &&
            workout.duration > 0 // Ensure valid duration
        }

        guard !recentQualifyingRuns.isEmpty else {
            return nil
        }

        // Sort by distance (descending), then by pace (fastest)
        let sortedRuns = recentQualifyingRuns.sorted { run1, run2 in
            // First priority: longer distance
            if run1.distance != run2.distance {
                return run1.distance > run2.distance
            }

            // Second priority: faster pace (lower pace value is faster)
            let pace1 = run1.averagePace
            let pace2 = run2.averagePace
            return pace1 < pace2
        }

        return sortedRuns.first
    }

    /// Calculates predicted time using Riegel's Formula
    /// - Parameters:
    ///   - seedTime: Time of the reference run (in seconds)
    ///   - seedDistance: Distance of the reference run (in meters)
    ///   - targetDistance: Distance to predict (in meters)
    /// - Returns: Predicted time in seconds
    private static func calculatePredictedTime(
        seedTime: TimeInterval,
        seedDistance: Double,
        targetDistance: Double
    ) -> TimeInterval {
        // Riegel's Formula: T2 = T1 * (D2 / D1)^1.06
        let distanceRatio = targetDistance / seedDistance
        let exponent = 1.06
        let timeFactor = pow(distanceRatio, exponent)

        return seedTime * timeFactor
    }
}
