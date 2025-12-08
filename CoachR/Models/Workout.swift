import Foundation
import CoreLocation

/// Represents a single running workout, containing essential performance data.
///
/// This structure serves as the primary domain model for representing
/// running activities fetched from HealthKit. It includes both basic metrics
/// (distance, duration, calories) and optional advanced metrics that may not
/// be available on all devices, implementing graceful degradation.
struct Workout: Identifiable {
    /// A unique identifier for the workout.
    let id: UUID

    /// The date and time when the workout started.
    let startDate: Date

    /// The date and time when the workout was completed.
    let endDate: Date

    /// The total distance of the run, in meters.
    let distance: Double

    /// The total duration of the run, in seconds.
    let duration: TimeInterval

    /// The total number of calories burned during the workout.
    let activeEnergyBurned: Double?

    // MARK: - Heart Rate Data

    /// The average heart rate during the run, in beats per minute (BPM).
    let averageHeartRate: Double?

    /// Heart rate samples collected throughout the workout.
    /// Used for charting heart rate over time.
    let heartRateSamples: [HeartRateSample]?

    // MARK: - Pace & Speed Data

    /// The average pace in seconds per kilometer.
    /// Calculated as duration / (distance / 1000)
    var averagePace: Double {
        guard distance > 0 else { return 0 }
        let kilometers = distance / 1000.0
        return duration / kilometers
    }

    /// The average speed in meters per second.
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return distance / duration
    }

    /// Speed samples collected throughout the workout.
    /// Used for charting pace over time.
    let speedSamples: [SpeedSample]?

    // MARK: - Advanced Running Metrics

    /// The average running power generated, in watts.
    /// Only available on devices that support power measurement.
    let averagePower: Double?

    /// Power samples collected throughout the workout.
    /// Used for power distribution charts.
    let powerSamples: [PowerSample]?

    /// Optional, advanced running form metrics.
    /// This property will be nil if the recording device does not support them.
    /// Implements graceful degradation as per PRD requirements.
    let metrics: RunningMetrics?

    // MARK: - Time-Series Running Metrics Data

    /// Elevation samples collected throughout the workout.
    /// Used for charting elevation changes over time.
    let elevationSamples: [ElevationSample]?

    /// Cadence samples collected throughout the workout.
    /// Used for charting cadence changes over time.
    let cadenceSamples: [CadenceSample]?

    /// Vertical oscillation samples collected throughout the workout.
    /// Used for charting vertical oscillation changes over time.
    let verticalOscillationSamples: [VerticalOscillationSample]?

    /// Ground contact time samples collected throughout the workout.
    /// Used for charting ground contact time changes over time.
    let groundContactTimeSamples: [GroundContactTimeSample]?

    /// Stride length samples collected throughout the workout.
    /// Used for charting stride length changes over time.
    let strideLengthSamples: [StrideLengthSample]?

    // MARK: - Location Data

    /// The route taken during the workout as an array of coordinates.
    /// Used for rendering the route on a map.
    let route: [CLLocationCoordinate2D]?

    // MARK: - Computed Properties

    /// Returns the distance in kilometers.
    var distanceInKilometers: Double {
        distance / 1000.0
    }

    /// Returns the formatted pace as MM:SS per kilometer.
    var formattedPace: String {
        let paceMinutes = Int(averagePace / 60)
        let paceSeconds = Int(averagePace.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", paceMinutes, paceSeconds)
    }

    /// Returns the formatted duration as HH:MM:SS.
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Determines if this workout qualifies as "high intensity" for calendar highlighting.
    /// Based on distance > 10km or active energy > 600 kcal.
    var isHighIntensity: Bool {
        if distanceInKilometers > 10.0 {
            return true
        }
        if let energy = activeEnergyBurned, energy > 600 {
            return true
        }
        return false
    }

    /// Calculates per-kilometer split statistics.
    ///
    /// - Returns: An array of KilometerSplit containing pace, elevation, and heart rate for each kilometer.
    func calculateKilometerSplits() -> [KilometerSplit] {
        let totalKilometers = Int(distanceInKilometers)
        guard totalKilometers > 0 else { return [] }

        var splits: [KilometerSplit] = []

        for km in 1...totalKilometers {
            let kmStartDistance = Double(km - 1) * 1000.0
            let kmEndDistance = Double(km) * 1000.0

            // Calculate pace for this kilometer
            let pace = calculatePaceForSegment(
                startDistance: kmStartDistance,
                endDistance: kmEndDistance
            )

            // Calculate average elevation for this kilometer
            let elevation = calculateElevationForSegment(
                startDistance: kmStartDistance,
                endDistance: kmEndDistance
            )

            // Calculate average heart rate for this kilometer
            let heartRate = calculateHeartRateForSegment(
                startDistance: kmStartDistance,
                endDistance: kmEndDistance
            )

            splits.append(KilometerSplit(
                kilometer: km,
                pace: pace,
                elevation: elevation,
                heartRate: heartRate
            ))
        }

        return splits
    }

    private func calculatePaceForSegment(startDistance: Double, endDistance: Double) -> Double? {
        guard let speedSamples = speedSamples, !speedSamples.isEmpty else { return nil }

        // Calculate the time range for this segment
        let totalDistance = distance
        let segmentStartTime = startDate.addingTimeInterval((startDistance / totalDistance) * duration)
        let segmentEndTime = startDate.addingTimeInterval((endDistance / totalDistance) * duration)

        // Find speed samples within this time range
        let relevantSamples = speedSamples.filter { sample in
            sample.timestamp >= segmentStartTime && sample.timestamp <= segmentEndTime
        }

        guard !relevantSamples.isEmpty else { return nil }

        // Calculate average pace (seconds per km)
        let averageSpeed = relevantSamples.map(\.value).reduce(0, +) / Double(relevantSamples.count)
        guard averageSpeed > 0 else { return nil }

        return 1000.0 / averageSpeed // Convert to seconds per km
    }

    private func calculateElevationForSegment(startDistance: Double, endDistance: Double) -> Double? {
        guard let elevationSamples = elevationSamples, !elevationSamples.isEmpty else { return nil }

        let totalDistance = distance
        let segmentStartTime = startDate.addingTimeInterval((startDistance / totalDistance) * duration)
        let segmentEndTime = startDate.addingTimeInterval((endDistance / totalDistance) * duration)

        let relevantSamples = elevationSamples.filter { sample in
            sample.timestamp >= segmentStartTime && sample.timestamp <= segmentEndTime
        }

        guard !relevantSamples.isEmpty else { return nil }

        return relevantSamples.map(\.value).reduce(0, +) / Double(relevantSamples.count)
    }

    private func calculateHeartRateForSegment(startDistance: Double, endDistance: Double) -> Double? {
        guard let heartRateSamples = heartRateSamples, !heartRateSamples.isEmpty else { return nil }

        let totalDistance = distance
        let segmentStartTime = startDate.addingTimeInterval((startDistance / totalDistance) * duration)
        let segmentEndTime = startDate.addingTimeInterval((endDistance / totalDistance) * duration)

        let relevantSamples = heartRateSamples.filter { sample in
            sample.timestamp >= segmentStartTime && sample.timestamp <= segmentEndTime
        }

        guard !relevantSamples.isEmpty else { return nil }

        return relevantSamples.map(\.value).reduce(0, +) / Double(relevantSamples.count)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        distance: Double,
        duration: TimeInterval,
        activeEnergyBurned: Double? = nil,
        averageHeartRate: Double? = nil,
        heartRateSamples: [HeartRateSample]? = nil,
        speedSamples: [SpeedSample]? = nil,
        averagePower: Double? = nil,
        powerSamples: [PowerSample]? = nil,
        metrics: RunningMetrics? = nil,
        elevationSamples: [ElevationSample]? = nil,
        cadenceSamples: [CadenceSample]? = nil,
        verticalOscillationSamples: [VerticalOscillationSample]? = nil,
        groundContactTimeSamples: [GroundContactTimeSample]? = nil,
        strideLengthSamples: [StrideLengthSample]? = nil,
        route: [CLLocationCoordinate2D]? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.distance = distance
        self.duration = duration
        self.activeEnergyBurned = activeEnergyBurned
        self.averageHeartRate = averageHeartRate
        self.heartRateSamples = heartRateSamples
        self.speedSamples = speedSamples
        self.averagePower = averagePower
        self.powerSamples = powerSamples
        self.metrics = metrics
        self.elevationSamples = elevationSamples
        self.cadenceSamples = cadenceSamples
        self.verticalOscillationSamples = verticalOscillationSamples
        self.groundContactTimeSamples = groundContactTimeSamples
        self.strideLengthSamples = strideLengthSamples
        self.route = route
    }
}

// MARK: - Sample Data Structures

/// Represents a heart rate measurement at a specific point in time.
struct HeartRateSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // BPM
}

/// Represents a speed measurement at a specific point in time.
struct SpeedSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // meters per second

    /// Returns the pace in seconds per kilometer.
    var pacePerKm: Double {
        guard value > 0 else { return 0 }
        return 1000.0 / value
    }
}

/// Represents a power measurement at a specific point in time.
struct PowerSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // watts
}

/// Represents an elevation measurement at a specific point in time.
struct ElevationSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // meters
}

/// Represents a cadence measurement at a specific point in time.
struct CadenceSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // steps per minute
}

/// Represents a vertical oscillation measurement at a specific point in time.
struct VerticalOscillationSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // centimeters
}

/// Represents a ground contact time measurement at a specific point in time.
struct GroundContactTimeSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // milliseconds
}

/// Represents a stride length measurement at a specific point in time.
struct StrideLengthSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double // meters
}

/// Represents statistics for a single kilometer segment.
struct KilometerSplit: Identifiable {
    let id = UUID()
    let kilometer: Int
    let pace: Double? // seconds per kilometer
    let elevation: Double? // meters
    let heartRate: Double? // bpm

    /// Returns the formatted pace as MM:SS.
    var formattedPace: String {
        guard let pace = pace else { return "--:--" }
        let minutes = Int(pace / 60)
        let seconds = Int(pace.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Returns the formatted elevation with one decimal place.
    var formattedElevation: String {
        guard let elevation = elevation else { return "--" }
        return String(format: "%.0f", elevation)
    }

    /// Returns the formatted heart rate as an integer.
    var formattedHeartRate: String {
        guard let heartRate = heartRate else { return "--" }
        return String(format: "%.0f", heartRate)
    }
}

// MARK: - Hashable Conformance

extension Workout: Hashable {
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
