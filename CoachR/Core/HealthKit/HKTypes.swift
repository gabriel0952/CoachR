import Foundation
import HealthKit

/// A centralized definition of all HealthKit types the app will interact with.
///
/// This enum provides a single source of truth for the HKQuantityTypeIdentifiers
/// and other HealthKit object types that the application needs to read. This approach
/// avoids string literals scattered throughout the codebase and simplifies permission requests.
enum HKTypes {
    
    /// All the HealthKit types that the app needs permission to read.
    static var allReadTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            // Primary workout type
            .workoutType(),

            // Workout route (GPS data)
            HKSeriesType.workoutRoute()
        ]

        // Add all quantity types
        let quantityTypes = quantityTypesToRead.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
        types.formUnion(quantityTypes)

        return types
    }

    /// Specific quantity types to read from HealthKit.
    /// These identifiers correspond to various metrics recorded during a workout.
    static let quantityTypesToRead: Set<HKQuantityTypeIdentifier> = [
        .distanceWalkingRunning,
        .activeEnergyBurned,
        .heartRate,

        // Advanced running metrics
        .runningPower,
        .runningSpeed,
        .runningVerticalOscillation,
        .runningGroundContactTime,
        .runningStrideLength,

        // General wellness metrics
        .restingHeartRate,
        .heartRateVariabilitySDNN,
        .vo2Max
    ]

    // MARK: - Convenience Properties

    static var heartRate: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .heartRate)
    }

    static var runningSpeed: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningSpeed)
    }

    static var runningPower: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningPower)
    }

    static var verticalOscillation: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningVerticalOscillation)
    }

    static var groundContactTime: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningGroundContactTime)
    }

    static var strideLength: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningStrideLength)
    }

    static var runningStrideLength: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningStrideLength)
    }

    // Note: Cadence is typically calculated from stride length and speed
    // Some devices may provide it directly, but it's not always available
    static var runningCadence: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .runningStrideLength)
    }
}
