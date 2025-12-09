import SwiftUI

/// The main activity view with segmented control for List/Calendar toggle.
///
/// This view implements the PRD specification for ActivityView:
/// - Segmented Picker at the top to switch between List and Calendar modes
/// - List Mode: Standard list with workout cells
/// - Calendar Mode: Monthly calendar grid with workout indicators
struct ActivityView: View {
    // View mode selection
    @State private var selectedMode: ViewMode = .calendar

    // Calendar state
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date?

    // Navigation
    @State private var selectedWorkout: Workout?
    @State private var showingWorkoutDetail = false

    // Shared ViewModel (same instance as Dashboard)
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker
                modePicker
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // Content
                Group {
                    switch selectedMode {
                    case .list:
                        listModeView

                    case .calendar:
                        calendarModeView
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("活動")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .navigationDestination(isPresented: $showingWorkoutDetail) {
                if let workout = selectedWorkout {
                    ActivityDetailView(workout: workout)
                }
            }
            .task {
                await viewModel.loadAllData()
                // Load more workouts for Activity view (50 instead of 10)
                await viewModel.loadMoreWorkoutsForActivity()
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("View Mode", selection: $selectedMode) {
            ForEach(ViewMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - List Mode

    private var listModeView: some View {
        WorkoutListView(workouts: viewModel.workouts) { workout in
            selectedWorkout = workout
            showingWorkoutDetail = true
        }
    }

    // MARK: - Calendar Mode

    private var calendarModeView: some View {
        ZStack(alignment: .bottom) {
            // Calendar Grid (fills available space)
            ScrollView {
                CalendarGridView(
                    displayedMonth: displayedMonth,
                    workouts: viewModel.workouts,
                    selectedDate: $selectedDate,
                    onMonthChange: { newMonth in
                        displayedMonth = newMonth
                        selectedDate = nil // Clear selection when changing months
                    }
                )
                .padding(.top, 8)
                .padding(.horizontal, 8)

                // Add bottom padding to prevent calendar from being hidden by mini card
                Color.clear
                    .frame(height: selectedDate != nil && workoutsForSelectedDate != nil ? 200 : 0)
            }

            // Mini Card overlay (doesn't push content)
            if selectedDate != nil,
               let workoutsForDate = workoutsForSelectedDate,
               !workoutsForDate.isEmpty {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 12) {
                        // Handle to indicate draggable sheet
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)

                        ForEach(workoutsForDate) { workout in
                            WorkoutMiniCard(workout: workout) {
                                selectedWorkout = workout
                                showingWorkoutDetail = true
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        Color.black.opacity(0.95)
                            .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
                    )
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDate)
    }

    // MARK: - Helper Properties

    private var workoutsForSelectedDate: [Workout]? {
        guard let date = selectedDate else { return nil }

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        return viewModel.workouts.filter { workout in
            calendar.isDate(workout.endDate, inSameDayAs: dayStart)
        }
    }
}

// MARK: - View Mode Enum

enum ViewMode: String, CaseIterable, Identifiable {
    case list = "列表"
    case calendar = "日曆"

    var id: String { rawValue }
}

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    ActivityView()
}
