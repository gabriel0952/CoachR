import Foundation
import HealthKit
import CoreLocation

extension Workout {
    /// A convenience initializer to create a `Workout` instance from an `HKWorkout` object.
    ///
    /// This initializer extracts key information from the `HKWorkout` object, such as
    /// distance, duration, and energy burned, and populates the corresponding properties
    /// of the `Workout` model.
    ///
    /// Note: This initializer only extracts basic workout data. To populate detailed
    /// metrics like heart rate samples, power data, and running form metrics, additional
    /// queries to HealthKit are required using `HKManager.fetchQuantitySamples`.
    ///
    /// - Parameter hkWorkout: The `HKWorkout` object to convert.
    init(from hkWorkout: HKWorkout) {
        self.id = UUID()
        self.startDate = hkWorkout.startDate
        self.endDate = hkWorkout.endDate
        self.duration = hkWorkout.duration

        // Extract distance, converting it to meters
        self.distance = hkWorkout.totalDistance?.doubleValue(for: .meter()) ?? 0

        // Extract calories burned
        self.activeEnergyBurned = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())

        // Placeholders for properties that require additional queries
        // These need to be populated separately using HKManager methods
        self.averageHeartRate = nil
        self.heartRateSamples = nil
        self.speedSamples = nil
        self.averagePower = nil
        self.powerSamples = nil
        self.metrics = nil
        self.elevationSamples = nil
        self.cadenceSamples = nil
        self.verticalOscillationSamples = nil
        self.groundContactTimeSamples = nil
        self.strideLengthSamples = nil
        self.route = nil
    }
}

// MARK: - Repository / Mapper Extensions

extension Workout {
    /// Enriches a basic Workout instance with detailed heart rate data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing heart rate data.
    /// - Returns: A new Workout instance with heart rate data populated.
    func withHeartRateData(_ samples: [HKQuantitySample]) -> Workout {
        let hrSamples = samples.map { sample in
            HeartRateSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            )
        }

        let avgHeartRate = hrSamples.isEmpty ? nil : hrSamples.map(\.value).reduce(0, +) / Double(hrSamples.count)

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: avgHeartRate,
            heartRateSamples: hrSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with detailed speed/pace data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing running speed data.
    /// - Returns: A new Workout instance with speed data populated.
    func withSpeedData(_ samples: [HKQuantitySample]) -> Workout {
        let speedSamples = samples.map { sample in
            SpeedSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: .second()))
            )
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with detailed power data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing running power data.
    /// - Returns: A new Workout instance with power data populated.
    func withPowerData(_ samples: [HKQuantitySample]) -> Workout {
        let pwrSamples = samples.map { sample in
            PowerSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: .watt())
            )
        }

        let avgPower = pwrSamples.isEmpty ? nil : pwrSamples.map(\.value).reduce(0, +) / Double(pwrSamples.count)

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: avgPower,
            powerSamples: pwrSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with advanced running form metrics.
    ///
    /// - Parameters:
    ///   - verticalOscillation: Array of vertical oscillation samples.
    ///   - groundContactTime: Array of ground contact time samples.
    ///   - cadence: Array of cadence samples.
    ///   - strideLength: Array of stride length samples.
    /// - Returns: A new Workout instance with running metrics populated.
    func withRunningMetrics(
        verticalOscillation: [HKQuantitySample]?,
        groundContactTime: [HKQuantitySample]?,
        cadence: [HKQuantitySample]?,
        strideLength: [HKQuantitySample]?
    ) -> Workout {
        // Calculate averages for each metric if samples exist
        let avgVO = verticalOscillation?.isEmpty == false
            ? verticalOscillation!.map { $0.quantity.doubleValue(for: .meterUnit(with: .centi)) }.reduce(0, +) / Double(verticalOscillation!.count)
            : nil

        let avgGCT = groundContactTime?.isEmpty == false
            ? groundContactTime!.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }.reduce(0, +) / Double(groundContactTime!.count)
            : nil

        let avgCadence = cadence?.isEmpty == false
            ? cadence!.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }.reduce(0, +) / Double(cadence!.count)
            : nil

        let avgStrideLength = strideLength?.isEmpty == false
            ? strideLength!.map { $0.quantity.doubleValue(for: .meter()) }.reduce(0, +) / Double(strideLength!.count)
            : nil

        let metrics = RunningMetrics(
            verticalOscillation: avgVO,
            groundContactTime: avgGCT,
            cadence: avgCadence,
            strideLength: avgStrideLength
        )

        // Only attach metrics if at least one value is non-nil (graceful degradation)
        let finalMetrics = (avgVO != nil || avgGCT != nil || avgCadence != nil || avgStrideLength != nil) ? metrics : nil

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: finalMetrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with GPS route data.
    ///
    /// - Parameter route: Array of CLLocationCoordinate2D representing the GPS route.
    /// - Returns: A new Workout instance with route data populated.
    func withRoute(_ route: [CLLocationCoordinate2D]) -> Workout {
        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: route
        )
    }

    /// Enriches a basic Workout instance with time-series cadence data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing cadence data.
    /// - Returns: A new Workout instance with cadence samples populated.
    func withCadenceSamples(_ samples: [HKQuantitySample]) -> Workout {
        let cadenceSamples = samples.map { sample in
            CadenceSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            )
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with time-series vertical oscillation data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing vertical oscillation data.
    /// - Returns: A new Workout instance with vertical oscillation samples populated.
    func withVerticalOscillationSamples(_ samples: [HKQuantitySample]) -> Workout {
        let voSamples = samples.map { sample in
            VerticalOscillationSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: HKUnit.meterUnit(with: .centi))
            )
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: voSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with time-series ground contact time data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing ground contact time data.
    /// - Returns: A new Workout instance with ground contact time samples populated.
    func withGroundContactTimeSamples(_ samples: [HKQuantitySample]) -> Workout {
        let gctSamples = samples.map { sample in
            GroundContactTimeSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            )
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: gctSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with time-series stride length data.
    ///
    /// - Parameter samples: Array of HKQuantitySample containing stride length data.
    /// - Returns: A new Workout instance with stride length samples populated.
    func withStrideLengthSamples(_ samples: [HKQuantitySample]) -> Workout {
        let strideSamples = samples.map { sample in
            StrideLengthSample(
                timestamp: sample.startDate,
                value: sample.quantity.doubleValue(for: .meter())
            )
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: strideSamples,
            route: self.route
        )
    }

    /// Enriches a basic Workout instance with elevation data extracted from GPS route.
    ///
    /// - Parameter locations: Array of CLLocation containing altitude data.
    /// - Returns: A new Workout instance with elevation samples populated.
    func withElevationSamples(_ locations: [CLLocation]) -> Workout {
        let elevationSamples = locations.map { location in
            ElevationSample(
                timestamp: location.timestamp,
                value: location.altitude
            )
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: elevationSamples,
            cadenceSamples: self.cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Calculates and enriches a Workout with cadence data derived from stride length and speed.
    ///
    /// Cadence (steps per minute) is calculated as: (speed / stride_length) * 60
    ///
    /// - Parameters:
    ///   - strideSamples: Array of HKQuantitySample containing stride length data.
    ///   - speedSamples: Array of HKQuantitySample containing speed data.
    /// - Returns: A new Workout instance with calculated cadence samples populated.
    func withCalculatedCadence(
        strideSamples: [HKQuantitySample],
        speedSamples: [HKQuantitySample]
    ) -> Workout {
        // Create a dictionary of speed samples keyed by timestamp for quick lookup
        var speedByTime: [Date: Double] = [:]
        for speedSample in speedSamples {
            let speed = speedSample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: .second()))
            speedByTime[speedSample.startDate] = speed
        }

        var cadenceSamples: [CadenceSample] = []

        for strideSample in strideSamples {
            let strideLength = strideSample.quantity.doubleValue(for: .meter())
            let timestamp = strideSample.startDate

            // Find the closest speed sample
            if let speed = speedByTime[timestamp] ?? findClosestSpeed(at: timestamp, in: speedByTime) {
                // Cadence = (speed / stride_length) * 60
                // speed is in m/s, stride_length is in meters
                // This gives steps per second, multiply by 60 for steps per minute
                if strideLength > 0 {
                    let cadence = (speed / strideLength) * 60.0
                    cadenceSamples.append(CadenceSample(
                        timestamp: timestamp,
                        value: cadence
                    ))
                }
            }
        }

        return Workout(
            id: self.id,
            startDate: self.startDate,
            endDate: self.endDate,
            distance: self.distance,
            duration: self.duration,
            activeEnergyBurned: self.activeEnergyBurned,
            averageHeartRate: self.averageHeartRate,
            heartRateSamples: self.heartRateSamples,
            speedSamples: self.speedSamples,
            averagePower: self.averagePower,
            powerSamples: self.powerSamples,
            metrics: self.metrics,
            elevationSamples: self.elevationSamples,
            cadenceSamples: cadenceSamples,
            verticalOscillationSamples: self.verticalOscillationSamples,
            groundContactTimeSamples: self.groundContactTimeSamples,
            strideLengthSamples: self.strideLengthSamples,
            route: self.route
        )
    }

    /// Helper function to find the closest speed value to a given timestamp.
    private func findClosestSpeed(at targetTime: Date, in speedByTime: [Date: Double]) -> Double? {
        var closestTime: Date?
        var minTimeDiff: TimeInterval = .infinity

        for (time, _) in speedByTime {
            let timeDiff = abs(time.timeIntervalSince(targetTime))
            if timeDiff < minTimeDiff {
                minTimeDiff = timeDiff
                closestTime = time
            }
        }

        if let closestTime = closestTime, minTimeDiff < 10 { // Within 10 seconds
            return speedByTime[closestTime]
        }

        return nil
    }
}
