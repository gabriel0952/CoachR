import Foundation
import CoreLocation

/// Mock data for SwiftUI Previews and development.
///
/// This enum provides static sample data representing various workout scenarios,
/// including workouts with full advanced metrics and workouts with basic data only,
/// to test graceful degradation in the UI.
enum MockData {

    // MARK: - Sample Workouts

    /// A collection of sample workouts for testing list views and calendar views.
    static let workouts: [Workout] = [
        // Workout 1: Full featured long run with all advanced metrics
        longRunWithAdvancedMetrics,

        // Workout 2: Easy run with basic metrics only (no power, no advanced form data)
        easyRunBasicMetrics,

        // Workout 3: Interval training with power data but no form metrics
        intervalRunWithPower,

        // Workout 4: Short recovery run with minimal data
        recoveryRunMinimalData,

        // Workout 5: Half marathon distance with full metrics
        halfMarathonRun,

        // Workout 6: Recent workout from yesterday
        yesterdayRun,

        // Workout 7: High intensity tempo run
        tempoRun,

        // Workout 8: Easy run from last week
        lastWeekEasyRun
    ]

    // MARK: - Individual Workout Samples

    /// A comprehensive long run with all advanced metrics available.
    /// Use this to test UI components that display power, form metrics, and charts.
    static let longRunWithAdvancedMetrics = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!.addingTimeInterval(5400), // 1h 30min
        distance: 18000, // 18 km
        duration: 5400, // 90 minutes
        activeEnergyBurned: 1200,
        averageHeartRate: 155,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            duration: 5400,
            baseHR: 155,
            variability: 15
        ),
        speedSamples: generateSpeedSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            duration: 5400,
            averageSpeed: 3.33 // 5:00/km pace
        ),
        averagePower: 285,
        powerSamples: generatePowerSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            duration: 5400,
            averagePower: 285
        ),
        metrics: RunningMetrics(
            verticalOscillation: 8.5,
            groundContactTime: 245,
            cadence: 178,
            strideLength: 1.12,
            groundContactTimeBalance: 50.5
        ),
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 18000)
    )

    /// An easy run with only basic metrics (distance, duration, calories).
    /// Use this to test graceful degradation when advanced metrics are unavailable.
    static let easyRunBasicMetrics = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!.addingTimeInterval(2100), // 35 min
        distance: 6000, // 6 km
        duration: 2100, // 35 minutes
        activeEnergyBurned: 420,
        averageHeartRate: 145,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            duration: 2100,
            baseHR: 145,
            variability: 10
        ),
        speedSamples: nil,
        averagePower: nil,
        powerSamples: nil,
        metrics: nil, // No advanced metrics
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 6000)
    )

    /// An interval training run with power data but no running form metrics.
    /// Tests partial advanced data availability.
    static let intervalRunWithPower = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!.addingTimeInterval(3000), // 50 min
        distance: 10000, // 10 km
        duration: 3000, // 50 minutes
        activeEnergyBurned: 750,
        averageHeartRate: 168,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            duration: 3000,
            baseHR: 168,
            variability: 25 // Higher variability for intervals
        ),
        speedSamples: generateSpeedSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            duration: 3000,
            averageSpeed: 3.33,
            isInterval: true
        ),
        averagePower: 310,
        powerSamples: generatePowerSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            duration: 3000,
            averagePower: 310,
            isInterval: true
        ),
        metrics: nil, // No form metrics
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 10000)
    )

    /// A short recovery run with minimal data.
    static let recoveryRunMinimalData = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!.addingTimeInterval(1800), // 30 min
        distance: 4500, // 4.5 km
        duration: 1800, // 30 minutes
        activeEnergyBurned: 300,
        averageHeartRate: nil, // No HR data
        heartRateSamples: nil,
        speedSamples: nil,
        averagePower: nil,
        powerSamples: nil,
        metrics: nil,
        route: nil // No GPS route
    )

    /// A half marathon distance run with full metrics.
    /// Tests high-intensity workout detection for calendar highlighting.
    static let halfMarathonRun = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!.addingTimeInterval(7200), // 2 hours
        distance: 21097, // Half marathon
        duration: 7200, // 2 hours
        activeEnergyBurned: 1500,
        averageHeartRate: 162,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            duration: 7200,
            baseHR: 162,
            variability: 12
        ),
        speedSamples: generateSpeedSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            duration: 7200,
            averageSpeed: 2.93 // 5:41/km pace
        ),
        averagePower: 270,
        powerSamples: generatePowerSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            duration: 7200,
            averagePower: 270
        ),
        metrics: RunningMetrics(
            verticalOscillation: 9.2,
            groundContactTime: 258,
            cadence: 175,
            strideLength: 1.08,
            groundContactTimeBalance: 49.8
        ),
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 21097)
    )

    /// Yesterday's run for testing "Latest Run" card.
    static let yesterdayRun = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(2700), // 45 min
        distance: 8000, // 8 km
        duration: 2700, // 45 minutes
        activeEnergyBurned: 560,
        averageHeartRate: 152,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            duration: 2700,
            baseHR: 152,
            variability: 10
        ),
        speedSamples: generateSpeedSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            duration: 2700,
            averageSpeed: 2.96 // 5:37/km pace
        ),
        averagePower: 265,
        powerSamples: generatePowerSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            duration: 2700,
            averagePower: 265
        ),
        metrics: RunningMetrics(
            verticalOscillation: 8.8,
            groundContactTime: 248,
            cadence: 176,
            strideLength: 1.10
        ),
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 8000)
    )

    /// A tempo run with sustained high effort.
    static let tempoRun = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -4, to: Date())!.addingTimeInterval(3300), // 55 min
        distance: 12000, // 12 km
        duration: 3300, // 55 minutes
        activeEnergyBurned: 900,
        averageHeartRate: 172,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            duration: 3300,
            baseHR: 172,
            variability: 8
        ),
        speedSamples: generateSpeedSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            duration: 3300,
            averageSpeed: 3.64 // 4:35/km pace
        ),
        averagePower: 320,
        powerSamples: generatePowerSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            duration: 3300,
            averagePower: 320
        ),
        metrics: RunningMetrics(
            verticalOscillation: 8.2,
            groundContactTime: 235,
            cadence: 182,
            strideLength: 1.18
        ),
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 12000)
    )

    /// An easy run from last week.
    static let lastWeekEasyRun = Workout(
        startDate: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -8, to: Date())!.addingTimeInterval(2400), // 40 min
        distance: 7000, // 7 km
        duration: 2400, // 40 minutes
        activeEnergyBurned: 490,
        averageHeartRate: 148,
        heartRateSamples: generateHeartRateSamples(
            startDate: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
            duration: 2400,
            baseHR: 148,
            variability: 10
        ),
        speedSamples: nil,
        averagePower: nil,
        powerSamples: nil,
        metrics: RunningMetrics(
            verticalOscillation: 9.0,
            groundContactTime: 250,
            cadence: 174,
            strideLength: 1.08
        ),
        route: generateSampleRoute(center: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), distance: 7000)
    )

    // MARK: - Helper Functions for Sample Data Generation

    /// Generates realistic heart rate samples for a workout.
    private static func generateHeartRateSamples(
        startDate: Date,
        duration: TimeInterval,
        baseHR: Double,
        variability: Double
    ) -> [HeartRateSample] {
        var samples: [HeartRateSample] = []
        let sampleInterval: TimeInterval = 5 // One sample every 5 seconds

        for offset in stride(from: 0, to: duration, by: sampleInterval) {
            let timestamp = startDate.addingTimeInterval(offset)
            // Add some randomness to simulate natural HR variation
            let variation = Double.random(in: -variability...variability)
            let hrValue = baseHR + variation
            samples.append(HeartRateSample(timestamp: timestamp, value: max(60, hrValue)))
        }

        return samples
    }

    /// Generates realistic speed samples for a workout.
    private static func generateSpeedSamples(
        startDate: Date,
        duration: TimeInterval,
        averageSpeed: Double,
        isInterval: Bool = false
    ) -> [SpeedSample] {
        var samples: [SpeedSample] = []
        let sampleInterval: TimeInterval = 10 // One sample every 10 seconds

        for offset in stride(from: 0, to: duration, by: sampleInterval) {
            let timestamp = startDate.addingTimeInterval(offset)
            var speed = averageSpeed

            if isInterval {
                // Simulate interval pattern: fast/slow alternating
                let intervalCycle = 300.0 // 5 minutes per cycle
                let positionInCycle = offset.truncatingRemainder(dividingBy: intervalCycle)
                if positionInCycle < 120 { // 2 min fast
                    speed = averageSpeed * 1.3
                } else { // 3 min slow
                    speed = averageSpeed * 0.7
                }
            }

            // Add natural variation
            let variation = Double.random(in: -0.2...0.2)
            samples.append(SpeedSample(timestamp: timestamp, value: speed + variation))
        }

        return samples
    }

    /// Generates realistic power samples for a workout.
    private static func generatePowerSamples(
        startDate: Date,
        duration: TimeInterval,
        averagePower: Double,
        isInterval: Bool = false
    ) -> [PowerSample] {
        var samples: [PowerSample] = []
        let sampleInterval: TimeInterval = 5 // One sample every 5 seconds

        for offset in stride(from: 0, to: duration, by: sampleInterval) {
            let timestamp = startDate.addingTimeInterval(offset)
            var power = averagePower

            if isInterval {
                let intervalCycle = 300.0
                let positionInCycle = offset.truncatingRemainder(dividingBy: intervalCycle)
                if positionInCycle < 120 { // High power interval
                    power = averagePower * 1.4
                } else { // Recovery
                    power = averagePower * 0.6
                }
            }

            // Add natural variation
            let variation = Double.random(in: -20...20)
            samples.append(PowerSample(timestamp: timestamp, value: max(0, power + variation)))
        }

        return samples
    }

    /// Generates a sample GPS route in a roughly circular pattern.
    /// This is simplified for preview purposes.
    private static func generateSampleRoute(
        center: CLLocationCoordinate2D,
        distance: Double
    ) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let numPoints = 100

        // Approximate radius in degrees (very rough conversion)
        let radiusInDegrees = (distance / 1000.0) / 111.0 / 4.0

        for i in 0..<numPoints {
            let angle = 2.0 * .pi * Double(i) / Double(numPoints)
            let lat = center.latitude + radiusInDegrees * cos(angle)
            let lon = center.longitude + radiusInDegrees * sin(angle)
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        return coordinates
    }

    // MARK: - Wellness Metrics Mock Data

    /// Sample resting heart rate value for dashboard.
    static let sampleRestingHeartRate: Double = 52

    /// Sample heart rate variability (SDNN) for dashboard.
    static let sampleHRV: Double = 65

    /// Sample VO2Max value for dashboard.
    static let sampleVO2Max: Double = 48.5

    /// Calculated body battery / readiness score (0-100).
    /// Based on RHR and HRV. Lower RHR and higher HRV = better readiness.
    static var sampleReadinessScore: Int {
        // Simplified calculation for demo purposes
        let rhrScore = max(0, min(100, 100 - Int((sampleRestingHeartRate - 40) * 2)))
        let hrvScore = min(100, Int(sampleHRV))
        return (rhrScore + hrvScore) / 2
    }

    // MARK: - Weekly Statistics

    /// Sample weekly distance in kilometers for the current week.
    static let weeklyDistances: [Double] = [6.0, 0, 8.0, 12.0, 7.0, 0, 18.0] // Mon-Sun

    /// Total weekly distance in kilometers.
    static var totalWeeklyDistance: Double {
        weeklyDistances.reduce(0, +)
    }
}
