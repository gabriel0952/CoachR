import Foundation

/// A structure to hold advanced running metrics related to form and efficiency.
///
/// These metrics are often available from advanced running watches and sensors.
/// All properties are optional as their availability depends on the user's equipment.
/// Implements graceful degradation - UI components should check for nil values.
struct RunningMetrics {
    /// Vertical oscillation, in centimeters (cm).
    /// Represents the vertical bounce in a runner's stride.
    /// Lower values typically indicate more efficient running form.
    var verticalOscillation: Double?

    /// Ground contact time, in milliseconds (ms).
    /// The amount of time per stride that a runner's foot is in contact with the ground.
    /// Elite runners typically have shorter ground contact times.
    var groundContactTime: Double?

    /// Running cadence, in steps per minute (spm).
    /// The number of steps a runner takes per minute.
    /// Optimal cadence is typically around 170-180 spm.
    var cadence: Double?

    /// Stride length, in meters.
    /// The distance covered in a single stride.
    var strideLength: Double?

    // MARK: - Computed Efficiency Metrics

    /// Vertical oscillation ratio (%).
    /// Calculated as (vertical oscillation / stride length) * 100
    /// Lower values indicate better running efficiency.
    var verticalOscillationRatio: Double? {
        guard let vo = verticalOscillation,
              let sl = strideLength,
              sl > 0 else { return nil }
        return (vo / 100.0) / sl * 100.0 // Convert cm to meters
    }

    /// Ground contact time balance (%).
    /// A measure of symmetry between left and right foot contact.
    /// Ideally should be close to 50/50.
    let groundContactTimeBalance: Double?

    // MARK: - Initialization

    init(
        verticalOscillation: Double? = nil,
        groundContactTime: Double? = nil,
        cadence: Double? = nil,
        strideLength: Double? = nil,
        groundContactTimeBalance: Double? = nil
    ) {
        self.verticalOscillation = verticalOscillation
        self.groundContactTime = groundContactTime
        self.cadence = cadence
        self.strideLength = strideLength
        self.groundContactTimeBalance = groundContactTimeBalance
    }
}
