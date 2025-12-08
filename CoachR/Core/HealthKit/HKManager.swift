import Foundation
import HealthKit
import CoreLocation

/// Manages all interactions with the HealthKit store.
///
/// This class encapsulates the logic for requesting authorization, fetching,
/// and processing health data from HealthKit. It provides a clean, async/await
/// interface for the rest of the application to consume.
///
/// The manager follows a singleton pattern to ensure a single point of access
/// to the HealthKit store throughout the application lifecycle.
@Observable
final class HKManager {

    // MARK: - Singleton

    /// Shared instance for singleton access pattern.
    static let shared = HKManager()

    // MARK: - Properties

    /// The shared HealthKit store.
    private let healthStore = HKHealthStore()

    /// Current authorization status for easier debugging and state management.
    private(set) var isAuthorized = false

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern.
    /// For dependency injection scenarios, can be made internal for testing.
    init() {}

    // MARK: - Authorization

    /// Requests authorization from the user to read health data.
    ///
    /// This method presents the user with the HealthKit authorization sheet,
    /// requesting permission to read all workout-related and wellness metrics
    /// defined in `HKTypes`.
    ///
    /// The requested data types include:
    /// - Workout data (running sessions)
    /// - Heart rate metrics (active HR, resting HR, HRV)
    /// - Running metrics (distance, speed, power)
    /// - Advanced form metrics (vertical oscillation, ground contact time)
    /// - Wellness metrics (VO2Max, active energy)
    ///
    /// - Throws: `HKError.healthDataNotAvailable` if HealthKit is not available on the device.
    ///           `HKError.authorizationFailed` if the authorization request fails.
    func requestAuthorization() async throws {
        // Check if HealthKit is available on the device
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HKError.healthDataNotAvailable
        }

        // Define the complete set of data types to read from HealthKit
        let typesToRead: Set<HKObjectType> = HKTypes.allReadTypes

        // Request authorization
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
        } catch {
            isAuthorized = false
            throw HKError.authorizationFailed(error.localizedDescription)
        }
    }

    // MARK: - Authorization Status

    /// Checks the authorization status for a specific type.
    ///
    /// - Parameter type: The HKObjectType to check authorization for.
    /// - Returns: The authorization status for the specified type.
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    // MARK: - Workout Queries

    /// Fetches the most recent running workouts from HealthKit.
    ///
    /// This method queries for workouts with activity type `.running`,
    /// sorted by end date in descending order (most recent first).
    ///
    /// - Parameter limit: Maximum number of workouts to fetch. Default is 50.
    /// - Returns: An array of `HKWorkout` objects representing running workouts.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchRunningWorkouts(limit: Int = 50) async throws -> [HKWorkout] {
        return try await withCheckedThrowingContinuation { continuation in
            // Predicate to fetch only running workouts
            let predicate = HKQuery.predicateForWorkouts(with: .running)

            // Sort by end date, descending (most recent first)
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate,
                ascending: false
            )

            // Create the query
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                // Handle potential errors
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                // Ensure samples can be cast to HKWorkout
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(throwing: HKError.queryError("Could not cast samples to HKWorkout."))
                    return
                }

                // Return the fetched workouts
                continuation.resume(returning: workouts)
            }

            // Execute the query
            healthStore.execute(query)
        }
    }

    // MARK: - Quantity Sample Queries

    /// Fetches quantity samples for a specific workout and quantity type.
    ///
    /// This is used to retrieve detailed metrics like heart rate, running power,
    /// vertical oscillation, etc., associated with a specific workout session.
    ///
    /// - Parameters:
    ///   - quantityType: The type of quantity to fetch (e.g., heart rate, running power).
    ///   - workout: The workout to fetch samples for.
    /// - Returns: An array of `HKQuantitySample` objects.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchQuantitySamples(
        for quantityType: HKQuantityType,
        during workout: HKWorkout
    ) async throws -> [HKQuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            // Predicate for samples within the workout time range
            let predicate = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate,
                options: .strictStartDate
            )

            // Sort by start date
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: true
            )

            // Create the query
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(throwing: HKError.queryError("Could not cast samples to HKQuantitySample."))
                    return
                }

                continuation.resume(returning: quantitySamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Statistics Queries

    /// Fetches statistics for a specific quantity type within a date range.
    ///
    /// This is useful for aggregating data like total distance, average heart rate,
    /// or total active energy burned over a period.
    ///
    /// - Parameters:
    ///   - quantityType: The type of quantity to fetch statistics for.
    ///   - startDate: The start of the date range.
    ///   - endDate: The end of the date range.
    ///   - options: The statistical options (e.g., sum, average, min, max).
    /// - Returns: An `HKStatistics` object containing the requested statistics.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchStatistics(
        for quantityType: HKQuantityType,
        startDate: Date,
        endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                continuation.resume(returning: statistics)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Wellness Metrics

    /// Fetches the most recent resting heart rate sample.
    ///
    /// - Returns: The most recent `HKQuantitySample` for resting heart rate, or `nil` if none exists.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchLatestRestingHeartRate() async throws -> HKQuantitySample? {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HKError.queryError("Resting heart rate type not available.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent heart rate variability (HRV/SDNN) sample.
    ///
    /// - Returns: The most recent `HKQuantitySample` for HRV, or `nil` if none exists.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchLatestHeartRateVariability() async throws -> HKQuantitySample? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HKError.queryError("Heart rate variability type not available.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches the most recent VO2Max sample.
    ///
    /// - Returns: The most recent `HKQuantitySample` for VO2Max, or `nil` if none exists.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchLatestVO2Max() async throws -> HKQuantitySample? {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            throw HKError.queryError("VO2Max type not available.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: vo2MaxType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery

    /// Enables background delivery for a specific quantity type.
    ///
    /// This allows the app to receive updates when new data is available,
    /// even when the app is not actively running.
    ///
    /// - Parameters:
    ///   - quantityType: The type of quantity to enable background delivery for.
    ///   - frequency: How often to receive updates (immediate, hourly, daily, weekly).
    /// - Throws: `HKError.queryError` if enabling background delivery fails.
    func enableBackgroundDelivery(
        for quantityType: HKQuantityType,
        frequency: HKUpdateFrequency
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.enableBackgroundDelivery(
                for: quantityType,
                frequency: frequency
            ) { success, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HKError.queryError("Failed to enable background delivery."))
                }
            }
        }
    }

    // MARK: - Workout Route

    /// Fetches the GPS route data for a workout.
    ///
    /// - Parameter workout: The HKWorkout to fetch the route for.
    /// - Returns: An array of CLLocationCoordinate2D representing the route, or nil if no route exists.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchRoute(for workout: HKWorkout) async throws -> [CLLocationCoordinate2D]? {
        // First, query for the HKWorkoutRoute associated with this workout
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
            let query = HKAnchoredObjectQuery(
                type: routeType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, _, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                guard let routes = samples as? [HKWorkoutRoute] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: routes)
            }

            healthStore.execute(query)
        }

        // If no routes found, return nil
        guard let route = routes.first else {
            return nil
        }

        // Now fetch the location data from the route
        let fullLocations = try await fetchFullLocations(from: route)
        return fullLocations.map { $0.coordinate }
    }

    /// Fetches the GPS route data with elevation for a workout.
    ///
    /// - Parameter workout: The HKWorkout to fetch the route for.
    /// - Returns: An array of CLLocation with full location data including altitude, or nil if no route exists.
    /// - Throws: `HKError.queryError` if the query fails.
    func fetchRouteWithElevation(for workout: HKWorkout) async throws -> [CLLocation]? {
        // First, query for the HKWorkoutRoute associated with this workout
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
            let query = HKAnchoredObjectQuery(
                type: routeType,
                predicate: predicate,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, _, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                guard let routes = samples as? [HKWorkoutRoute] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: routes)
            }

            healthStore.execute(query)
        }

        // If no routes found, return nil
        guard let route = routes.first else {
            return nil
        }

        // Now fetch the full location data from the route
        return try await fetchFullLocations(from: route)
    }

    private func fetchFullLocations(from route: HKWorkoutRoute) async throws -> [CLLocation] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
            var locations: [CLLocation] = []

            let query = HKWorkoutRouteQuery(route: route) { _, routeData, done, error in
                if let error = error {
                    continuation.resume(throwing: HKError.queryError(error.localizedDescription))
                    return
                }

                if let routeData = routeData {
                    locations.append(contentsOf: routeData)
                }

                if done {
                    continuation.resume(returning: locations)
                }
            }

            healthStore.execute(query)
        }
    }
}
