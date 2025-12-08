import SwiftUI

/// A list view displaying workouts in chronological order.
///
/// This view implements the PRD specification for List Mode:
/// - Date display
/// - Large font for distance
/// - Small font for time and pace
/// - Intensity indicator icon
struct WorkoutListView: View {
    let workouts: [Workout]
    let onWorkoutTap: (Workout) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(workouts) { workout in
                    WorkoutListCell(workout: workout)
                        .onTapGesture {
                            onWorkoutTap(workout)
                        }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Workout List Cell

struct WorkoutListCell: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 16) {
            // Left: Intensity indicator
            VStack {
                intensityIcon
                    .font(.title2)
                    .foregroundColor(workout.isHighIntensity ? .warningOrange : .neonGreen)
            }
            .frame(width: 40)

            // Middle: Workout details
            VStack(alignment: .leading, spacing: 6) {
                // Date
                Text(workout.endDate, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)

                // Distance (large)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", workout.distanceInKilometers))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("km")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                }

                // Time and Pace (small)
                HStack(spacing: 16) {
                    Label(workout.formattedDuration, systemImage: "clock")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)

                    Label("\(workout.formattedPace)/km", systemImage: "speedometer")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Right: Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.body)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var intensityIcon: Image {
        if workout.isHighIntensity {
            return Image(systemName: "flame.fill")
        } else if let avgHR = workout.averageHeartRate, avgHR > 160 {
            return Image(systemName: "bolt.fill")
        } else {
            return Image(systemName: "figure.run")
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        WorkoutListView(workouts: MockData.workouts) { workout in
            print("Tapped workout: \(workout.id)")
        }
    }
}
