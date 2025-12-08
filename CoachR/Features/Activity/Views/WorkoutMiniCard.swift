import SwiftUI

/// A compact card showing workout summary details.
///
/// This view appears when a user taps a date in the calendar view.
/// It provides a quick overview before navigating to the full detail view.
struct WorkoutMiniCard: View {
    let workout: Workout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: workout.isHighIntensity ? "flame.fill" : "figure.run")
                        .foregroundColor(workout.isHighIntensity ? .warningOrange : .neonGreen)
                        .font(.title3)

                    Text(workout.endDate, style: .time)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }

                // Stats Grid
                HStack(spacing: 20) {
                    MiniStatItem(
                        icon: "figure.run",
                        value: String(format: "%.2f", workout.distanceInKilometers),
                        unit: "km"
                    )

                    MiniStatItem(
                        icon: "clock",
                        value: workout.formattedDuration,
                        unit: ""
                    )

                    MiniStatItem(
                        icon: "speedometer",
                        value: workout.formattedPace,
                        unit: "/km"
                    )

                    if let avgHR = workout.averageHeartRate {
                        MiniStatItem(
                            icon: "heart.fill",
                            value: "\(Int(avgHR))",
                            unit: "bpm"
                        )
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mini Stat Item

struct MiniStatItem: View {
    let icon: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.gray)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 8, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            WorkoutMiniCard(workout: MockData.longRunWithAdvancedMetrics) {
                print("Tapped mini card")
            }
            .padding()

            Spacer()
        }
    }
}
