import SwiftUI

/// A calendar grid view that displays a month of dates with workout indicators.
///
/// This view implements the PRD specification for Calendar Mode:
/// - 7 columns (Sunday-Saturday)
/// - Date numbers with workout indicators
/// - Green dot for regular workouts
/// - Special icon (flame) for high-intensity workouts
/// - Tap interaction to show workout details
struct CalendarGridView: View {
    let displayedMonth: Date
    let workouts: [Workout]
    @Binding var selectedDate: Date?
    var onMonthChange: ((Date) -> Void)?

    // Calendar helper
    private let calendar = Calendar.current

    // Computed property: All days in the displayed month
    private var daysInMonth: [Date?] {
        generateDaysInMonth()
    }

    // Computed property: Workouts grouped by date
    private var workoutsByDate: [String: [Workout]] {
        Dictionary(grouping: workouts) { workout in
            calendar.startOfDay(for: workout.endDate).ISO8601Format()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: Month/Year with navigation arrows
            monthHeader

            // Weekday labels
            weekdayLabels

            // Calendar grid
            calendarGrid
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button(action: {
                navigateToPreviousMonth()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gray)
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                navigateToNextMonth()
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Navigation Methods

    private func navigateToPreviousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            onMonthChange?(newMonth)
        }
    }

    private func navigateToNextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            onMonthChange?(newMonth)
        }
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
            spacing: 8
        ) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        workouts: workoutsForDate(date),
                        isSelected: isSelected(date),
                        onTap: {
                            selectedDate = date
                        }
                    )
                } else {
                    // Empty cell for days outside the current month
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Helper Methods

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 MM月"
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        // Sunday to Saturday
        ["日", "一", "二", "三", "四", "五", "六"]
    }

    private func generateDaysInMonth() -> [Date?] {
        var days: [Date?] = []

        // Get the first day of the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))
        else {
            return days
        }

        // Get the weekday of the first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Get the range of days in the month
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return days
        }

        // Add all days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func workoutsForDate(_ date: Date) -> [Workout] {
        let dayStart = calendar.startOfDay(for: date)
        let key = dayStart.ISO8601Format()
        return workoutsByDate[key] ?? []
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let workouts: [Workout]
    let isSelected: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(isToday ? .neonGreen : .white)
                    .fontWeight(isToday ? .bold : .regular)

                // Workout indicator
                if !workouts.isEmpty {
                    workoutIndicator
                } else {
                    Spacer()
                        .frame(height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.cardBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.neonGreen.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var hasHighIntensityWorkout: Bool {
        workouts.contains { $0.isHighIntensity }
    }

    private var workoutIndicator: some View {
        Group {
            if hasHighIntensityWorkout {
                // High intensity: flame icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.warningOrange)
            } else {
                // Regular workout: green dot
                Circle()
                    .fill(Color.neonGreen)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate: Date?

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                CalendarGridView(
                    displayedMonth: Date(),
                    workouts: MockData.workouts,
                    selectedDate: $selectedDate
                )
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
