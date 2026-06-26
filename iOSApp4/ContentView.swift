//
//  ContentView.swift
//  iOSApp4
//
//  Created by Etefworkie Melaku on 2026-06-24.
//
//  Event / Reminder Planner — visionOS SwiftUI app.
//  Week 6 features: TextField, DatePicker, Picker, Toggle, Slider, Alert + Local Notification.
//  visionOS touches: .glassBackgroundEffect() on every card, .ornament() for the action buttons.

import SwiftUI
import UserNotifications

// MARK: - Reusable Card View
// Generic wrapper that applies padding and the visionOS glass background to any content.
struct CardView<Content: View>: View {
    let content: Content

    // Accepts any SwiftUI view tree via @ViewBuilder.
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            // visionOS-only: renders the frosted-glass material, clipped to a rounded rectangle.
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Card Section Header
// Reusable header row with a tinted SF Symbol icon and a bold title.
struct CardHeader: View {
    let icon: String   // SF Symbol name
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .imageScale(.medium)
            Text(title)
                // Larger than .headline so section titles stand out from control labels.
                .font(.title3.bold())
                // Rounded letterforms complement the curved glass card shape.
                .fontDesign(.rounded)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {

    // User-entered event name.
    @State private var eventTitle: String = ""

    // Selected event date and time.
    @State private var eventDate: Date = Date()

    // Currently selected event category.
    @State private var selectedCategory: String = "Work"

    // When true, hides the time picker and omits time from the notification.
    @State private var isAllDay: Bool = false

    // Event priority 1–5; Double is required by Slider.
    @State private var priority: Double = 3

    // Set to true to trigger the confirmation or error Alert.
    @State private var showConfirmationAlert: Bool = false

    // Alert headline; set to reflect success or the specific error before showing.
    @State private var alertTitle: String = ""

    // Alert body text; set before showConfirmationAlert is flipped.
    @State private var alertMessage: String = ""

    // Available options for the segmented category Picker.
    let categories = ["Work", "Personal", "Health"]

    // Returns the typed title, or a "Category Event" fallback if the field is blank.
    var effectiveTitle: String {
        let trimmed = eventTitle.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "\(selectedCategory) Event" : trimmed
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // MARK: Event Title Card
                    // TextField bound to eventTitle; updates the @State on every keystroke.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "pencil", title: "Event Title")

                            // Rounded border makes the field visible against the glass background.
                            TextField("What is the event about?", text: $eventTitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)

                            // Live readout of the current TextField value.
                            Text("Title: \(effectiveTitle)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Date & Time Card
                    // Graphical DatePicker; shows the time scroll wheel unless all-day is on.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "calendar", title: "Date & Time")

                            DatePicker(
                                "Event Date",
                                selection: $eventDate,
                                displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            // Hides the built-in label; CardHeader already provides the title.
                            .labelsHidden()
                            .font(.body)

                            // Live readout; omits the time portion when all-day is on.
                            Text("Selected: \(eventDate.formatted(date: .long, time: isAllDay ? .omitted : .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Category Card
                    // Segmented Picker; ideal for a short, fixed list of options.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "tag.fill", title: "Category")

                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)

                            // Live readout of the selected segment.
                            Text("Category: \(selectedCategory)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: All-Day Toggle Card
                    // Toggling on also collapses the time wheel in the DatePicker above.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "sun.max.fill", title: "All-Day Event")

                            // Two-way binding: Toggle reads and writes isAllDay on each tap.
                            Toggle("All-day", isOn: $isAllDay)

                            // Live readout of the toggle state.
                            Text("All-day: \(isAllDay ? "On" : "Off")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Priority Slider Card
                    // step: 1 snaps to whole numbers; the label is read by Eye Tracking / VoiceOver.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "exclamationmark.triangle.fill", title: "Priority")

                            Slider(value: $priority, in: 1...5, step: 1) {
                                Text("Priority")
                            }

                            // Convert Double to Int for a clean whole-number display.
                            Text("Priority: \(Int(priority)) / 5")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .padding()
            }
            .navigationTitle("Event Planner")

            // MARK: Ornament — Action Buttons
            // visionOS-only: attaches a floating toolbar panel just below the window edge.
            .ornament(attachmentAnchor: .scene(.bottom)) {
                HStack(spacing: 16) {

                    // Schedules 4 reminders at the chosen date, 5 seconds apart.
                    Button(action: scheduleNotification) {
                        Label("Set Reminder", systemImage: "bell.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)

                    // Fires 4 test notifications at 10, 15, 20, 25 seconds from now.
                    Button(action: scheduleTestNotification) {
                        Label("Test · 10 s", systemImage: "timer")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                // Glass panel makes the ornament look like a native visionOS toolbar chip.
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
        // MARK: Confirmation / Error Alert
        // Shown after both schedule functions; alertTitle and alertMessage are set first.
        .alert(alertTitle, isPresented: $showConfirmationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Schedule Notification at Chosen Date
    // Validates the date is in the future, then schedules 4 notifications 5 seconds apart.
    func scheduleNotification() {

        // Reject past dates; a past calendar trigger fires silently with no user feedback.
        guard eventDate > Date() else {
            alertTitle = "Invalid Date"
            alertMessage = "The selected date and time is in the past. Please pick a future time."
            showConfirmationAlert = true
            return
        }

        let center = UNUserNotificationCenter.current()

        // Shows the permission prompt once; returns the cached answer on later calls.
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {

                if let error = error {
                    alertTitle = "Permission Error"
                    alertMessage = error.localizedDescription
                    showConfirmationAlert = true
                    return
                }

                guard granted else {
                    alertTitle = "Notifications Disabled"
                    alertMessage = "Enable notifications for this app in Settings to receive reminders."
                    showConfirmationAlert = true
                    return
                }

                // Four offsets in seconds: fires at chosen time, then +5 s, +10 s, +15 s.
                let offsets: [TimeInterval] = [0, 5, 10, 15]

                // Tracks all four async add() calls so we show exactly one Alert when done.
                let group = DispatchGroup()

                // Collects errors from individual add() calls.
                var addErrors: [Error] = []

                // Schedule one notification per offset.
                for (index, offset) in offsets.enumerated() {

                    // Shift the base date forward by the current offset.
                    let fireDate = eventDate.addingTimeInterval(offset)

                    // Include .second to preserve 5-second spacing; all-day drops hour/minute.
                    let calComponents: Set<Calendar.Component> = isAllDay
                        ? [.year, .month, .day, .second]
                        : [.year, .month, .day, .hour, .minute, .second]

                    let components = Calendar.current.dateComponents(calComponents, from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                    // Fresh content per iteration so the title can vary across repeats.
                    let content = buildNotificationContent()
                    // Label repeats 2–4 so Notification Center shows them as distinct entries.
                    if index > 0 {
                        content.title = "🔔 \(effectiveTitle) — reminder \(index + 1) of \(offsets.count)"
                    }

                    // Unique ID per request; reusing the same ID would silently replace earlier ones.
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: trigger
                    )

                    // Register one pending job with the group.
                    group.enter()
                    center.add(request) { error in
                        DispatchQueue.main.async {
                            if let error = error { addErrors.append(error) }
                            // Signal the group that this job is complete.
                            group.leave()
                        }
                    }
                }

                // Runs on the main queue only after all four leave() calls are received.
                group.notify(queue: .main) {
                    if let first = addErrors.first {
                        alertTitle = "Error"
                        alertMessage = "Could not schedule all reminders: \(first.localizedDescription)"
                    } else {
                        alertTitle = "Reminders Set"
                        alertMessage = """
                            Event: \(effectiveTitle)
                            Date: \(eventDate.formatted(date: .long, time: isAllDay ? .omitted : .shortened))
                            Category: \(selectedCategory)
                            Priority: \(Int(priority)) / 5

                            4 reminders will fire 5 seconds apart.
                            """
                    }
                    showConfirmationAlert = true
                }
            }
        }
    }

    // MARK: - Schedule Test Notifications (10, 15, 20, 25 seconds from now)
    // Ignores the picked date; uses time-interval triggers for quick pipeline verification.
    func scheduleTestNotification() {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {

                if let error = error {
                    alertTitle = "Permission Error"
                    alertMessage = error.localizedDescription
                    showConfirmationAlert = true
                    return
                }

                guard granted else {
                    alertTitle = "Notifications Disabled"
                    alertMessage = "Enable notifications for this app in Settings to receive reminders."
                    showConfirmationAlert = true
                    return
                }

                // Fire times: 10 s, 15 s, 20 s, 25 s from now.
                let intervals: [TimeInterval] = [10, 15, 20, 25]

                let group = DispatchGroup()
                var addErrors: [Error] = []

                // Schedule one notification per interval.
                for (index, interval) in intervals.enumerated() {

                    // Time-interval trigger is simpler than a calendar trigger for testing.
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

                    let content = buildNotificationContent()
                    // Sequence label so each test banner is identifiable.
                    content.title = "[TEST \(index + 1)/\(intervals.count)] \(effectiveTitle)"

                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: trigger
                    )

                    group.enter()
                    center.add(request) { error in
                        DispatchQueue.main.async {
                            if let error = error { addErrors.append(error) }
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    if let first = addErrors.first {
                        alertTitle = "Error"
                        alertMessage = "Could not schedule test: \(first.localizedDescription)"
                    } else {
                        alertTitle = "Test Scheduled"
                        alertMessage = """
                            Event: \(effectiveTitle)
                            Category: \(selectedCategory)
                            Priority: \(Int(priority)) / 5

                            4 test notifications will appear at 10 s, 15 s, 20 s, and 25 s.
                            Background the app now to see the banners.
                            """
                    }
                    showConfirmationAlert = true
                }
            }
        }
    }

    // MARK: - Build Notification Content
    // Builds notification content from the current form values; shared by both schedule functions.
    private func buildNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        // Use the typed title, or "Category Event" if the field was left blank.
        content.title = effectiveTitle
        content.body = "📅 \(eventDate.formatted(date: .long, time: isAllDay ? .omitted : .shortened)) · \(selectedCategory) · Priority \(Int(priority))/5"
        // Custom sound bundled with the app; falls back to default if alarm.wav is missing.
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
        return content
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
