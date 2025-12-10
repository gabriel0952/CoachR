import Foundation

/// Training Load Engine using TRIMP and EWMA-based ATL/CTL calculations
/// Based on Banister's training impulse model and chronic/acute workload ratio
struct TrainingLoadEngine {

    // MARK: - Data Models

    /// User metrics required for TRIMP calculation
    struct UserMetrics {
        let maxHR: Double
        let restingHR: Double
        let gender: Gender

        enum Gender {
            case male
            case female

            var trimpConstant: Double {
                switch self {
                case .male: return 1.92
                case .female: return 1.67
                }
            }
        }
    }

    /// Training status with load metrics
    struct TrainingStatus {
        let currentATL: Double  // Acute Training Load (Fatigue) - 7 day
        let currentCTL: Double  // Chronic Training Load (Fitness) - 42 day
        let acwr: Double        // Acute:Chronic Workload Ratio
        let status: Status
        let history: [DailyLoad]  // Historical data for charting

        enum Status: String {
            case undertraining = "訓練不足"
            case optimal = "負荷適中"
            case overreaching = "負荷偏高"
            case hazardous = "過度訓練"

            var color: String {
                switch self {
                case .undertraining: return "#808080"  // Gray
                case .optimal: return "#00FF00"        // Green
                case .overreaching: return "#FF9500"   // Orange
                case .hazardous: return "#FF3B30"      // Red
                }
            }

            static func from(acwr: Double) -> Status {
                switch acwr {
                case 0..<0.8:
                    return .undertraining
                case 0.8..<1.3:
                    return .optimal
                case 1.3..<1.5:
                    return .overreaching
                default:
                    return .hazardous
                }
            }
        }
    }

    /// Daily load snapshot for historical tracking
    struct DailyLoad: Identifiable {
        let id = UUID()
        let date: Date
        let trimp: Double
        let atl: Double
        let ctl: Double
    }

    // MARK: - Public Interface

    /// Calculate training load metrics from workout history
    /// - Parameters:
    ///   - workouts: Array of workouts to analyze
    ///   - userMetrics: User's physiological metrics
    /// - Returns: TrainingStatus with current metrics and historical data
    static func calculateLoadMetrics(
        from workouts: [Workout],
        userMetrics: UserMetrics
    ) -> TrainingStatus {
        // Group workouts by date and calculate daily TRIMP
        let dailyTrimps = calculateDailyTrimps(workouts: workouts, userMetrics: userMetrics)

        // Calculate ATL and CTL using EWMA
        let history = calculateEWMAMetrics(dailyTrimps: dailyTrimps)

        // Get current values (most recent day)
        let currentATL = history.last?.atl ?? 0
        let currentCTL = history.last?.ctl ?? 0

        // Calculate ACWR
        let acwr = currentCTL > 0 ? currentATL / currentCTL : 0

        // Determine status
        let status = TrainingStatus.Status.from(acwr: acwr)

        return TrainingStatus(
            currentATL: currentATL,
            currentCTL: currentCTL,
            acwr: acwr,
            status: status,
            history: history
        )
    }

    // MARK: - Private Calculation Methods

    /// Calculate TRIMP for a single workout using Banister's formula
    /// - Parameters:
    ///   - workout: The workout to analyze
    ///   - userMetrics: User's physiological metrics
    /// - Returns: TRIMP value (0 if no heart rate data)
    private static func calculateTRIMP(
        for workout: Workout,
        userMetrics: UserMetrics
    ) -> Double {
        guard let avgHR = workout.averageHeartRate else {
            return 0
        }

        // Calculate HR reserve ratio
        let hrReserve = (avgHR - userMetrics.restingHR) / (userMetrics.maxHR - userMetrics.restingHR)

        // Ensure HR reserve is in valid range [0, 1]
        let clampedHRReserve = max(0, min(1, hrReserve))

        // Banister's TRIMP formula
        // TRIMP = duration × HR_reserve × 0.64 × e^(k × HR_reserve)
        let durationMinutes = workout.duration / 60.0
        let exponent = userMetrics.gender.trimpConstant * clampedHRReserve
        let trimp = durationMinutes * clampedHRReserve * 0.64 * exp(exponent)

        return trimp
    }

    /// Group workouts by date and sum TRIMP values
    /// - Parameters:
    ///   - workouts: Array of workouts
    ///   - userMetrics: User metrics for TRIMP calculation
    /// - Returns: Dictionary mapping dates to total TRIMP values
    private static func calculateDailyTrimps(
        workouts: [Workout],
        userMetrics: UserMetrics
    ) -> [Date: Double] {
        var dailyTrimps: [Date: Double] = [:]
        let calendar = Calendar.current

        for workout in workouts {
            let date = calendar.startOfDay(for: workout.endDate)
            let trimp = calculateTRIMP(for: workout, userMetrics: userMetrics)
            dailyTrimps[date, default: 0] += trimp
        }

        return dailyTrimps
    }

    /// Calculate ATL and CTL using Exponential Weighted Moving Average
    /// - Parameter dailyTrimps: Dictionary of daily TRIMP values
    /// - Returns: Array of DailyLoad with ATL/CTL history
    private static func calculateEWMAMetrics(dailyTrimps: [Date: Double]) -> [DailyLoad] {
        guard !dailyTrimps.isEmpty else {
            return []
        }

        // Sort dates chronologically
        let sortedDates = dailyTrimps.keys.sorted()

        // EWMA decay factors
        let atlDecay = 2.0 / (7.0 + 1.0)   // 7-day window
        let ctlDecay = 2.0 / (42.0 + 1.0)  // 42-day window

        var history: [DailyLoad] = []
        var previousATL = 0.0
        var previousCTL = 0.0

        // Cold start: Use simple average for first 7 days
        let coldStartPeriod = min(7, sortedDates.count)
        var coldStartSum = 0.0

        for (index, date) in sortedDates.enumerated() {
            let trimp = dailyTrimps[date] ?? 0

            if index < coldStartPeriod {
                // Cold start phase: accumulate values
                coldStartSum += trimp
                let avg = coldStartSum / Double(index + 1)
                previousATL = avg
                previousCTL = avg
            } else {
                // EWMA calculation
                previousATL = previousATL * (1 - atlDecay) + trimp * atlDecay
                previousCTL = previousCTL * (1 - ctlDecay) + trimp * ctlDecay
            }

            history.append(DailyLoad(
                date: date,
                trimp: trimp,
                atl: previousATL,
                ctl: previousCTL
            ))
        }

        // Fill gaps with zero TRIMP days (maintaining EWMA decay)
        return fillDateGaps(history: history, atlDecay: atlDecay, ctlDecay: ctlDecay)
    }

    /// Fill gaps in workout history with zero-TRIMP days
    /// This ensures ATL/CTL decay properly on rest days
    /// - Parameters:
    ///   - history: Existing daily load history
    ///   - atlDecay: ATL decay factor
    ///   - ctlDecay: CTL decay factor
    /// - Returns: Complete history with all days filled
    private static func fillDateGaps(
        history: [DailyLoad],
        atlDecay: Double,
        ctlDecay: Double
    ) -> [DailyLoad] {
        guard let firstDate = history.first?.date,
              let lastDate = history.last?.date else {
            return history
        }

        var filledHistory: [DailyLoad] = []
        var previousATL = 0.0
        var previousCTL = 0.0

        let calendar = Calendar.current
        var currentDate = firstDate
        var historyIndex = 0

        while currentDate <= lastDate {
            if historyIndex < history.count && calendar.isDate(history[historyIndex].date, inSameDayAs: currentDate) {
                // We have data for this day
                let load = history[historyIndex]
                previousATL = load.atl
                previousCTL = load.ctl
                filledHistory.append(load)
                historyIndex += 1
            } else {
                // Gap day - decay ATL/CTL with zero TRIMP
                previousATL = previousATL * (1 - atlDecay)
                previousCTL = previousCTL * (1 - ctlDecay)
                filledHistory.append(DailyLoad(
                    date: currentDate,
                    trimp: 0,
                    atl: previousATL,
                    ctl: previousCTL
                ))
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return filledHistory
    }
}
