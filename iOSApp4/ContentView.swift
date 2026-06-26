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
// CardView wraps any SwiftUI content in padding and the visionOS glass material.
// Using a RoundedRectangle shape gives the glass panel crisp, defined corners
// rather than the default behavior where the shape hugs the view bounds.
struct CardView<Content: View>: View {
    let content: Content

    // @ViewBuilder lets the caller write a multi-view block inside the braces,
    // the same way Group { } and VStack { } accept multiple children.
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            // .glassBackgroundEffect(in:) is visionOS-only. It renders the signature
            // frosted-glass material behind this view. Passing a RoundedRectangle
            // clips the glass to that shape so the card has clean rounded edges.
            // On device the glass adapts to real-world light seen by the headset cameras.
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Card Section Header
// A small reusable header row: a tinted SF Symbol icon next to a bold title.
// Using a consistent header across every card keeps the visual rhythm uniform.
struct CardHeader: View {
    let icon: String   // SF Symbol name
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .imageScale(.medium)
            Text(title)
                // .title3.bold() is noticeably larger than the old .headline,
                // making section titles stand out from the control labels below.
                .font(.title3.bold())
                // .rounded gives the letters slightly softer curves — a common
                // design choice in visionOS apps to complement the glass panels.
                .fontDesign(.rounded)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {

    // The short name or description the user types for this event.
    @State private var eventTitle: String = ""

    // The date and time the user picks for their event.
    @State private var eventDate: Date = Date()

    // Which category is selected in the Picker.
    @State private var selectedCategory: String = "Work"

    // True while the All-Day toggle is on; hides the time wheel in the DatePicker.
    @State private var isAllDay: Bool = false

    // Priority 1–5 as a Double (Slider requires Double, not Int).
    @State private var priority: Double = 3

    // Drives the confirmation or error Alert that appears after a button is tapped.
    @State private var showConfirmationAlert: Bool = false

    // Headline shown at the top of the Alert — changes for success vs. error.
    @State private var alertTitle: String = ""

    // Detail line shown inside the Alert.
    @State private var alertMessage: String = ""

    // Fixed category options for the segmented Picker.
    let categories = ["Work", "Personal", "Health"]

    // The notification title we'll use: the user's typed title, or a fallback
    // built from the category if they left the field blank.
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
                    // TextField gives the user a free-text field to name the event.
                    // The binding $eventTitle updates the @State variable on every keystroke.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "pencil", title: "Event Title")

                            // .textFieldStyle(.roundedBorder) draws a visible border
                            // so the field stands out against the glass background.
                            TextField("What is the event about?", text: $eventTitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)

                            // Live readout — shows whatever is currently in the TextField.
                            Text("Title: \(effectiveTitle)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Date & Time Card
                    // .graphical style renders a full month-grid calendar plus a time scroll wheel.
                    // The displayedComponents array is tied to isAllDay — when all-day is on,
                    // the hour/minute wheel disappears so you only pick a date.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "calendar", title: "Date & Time")

                            DatePicker(
                                "Event Date",
                                selection: $eventDate,
                                displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            // .labelsHidden() removes the built-in "Event Date" label
                            // since CardHeader already provides a section label above.
                            .labelsHidden()
                            .font(.body)

                            // Live readout that omits the time portion when all-day is on.
                            Text("Selected: \(eventDate.formatted(date: .long, time: isAllDay ? .omitted : .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Category Card
                    // Picker with .segmented style shows all three options as a pill row.
                    // It's the right choice here because the list is short and fixed.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "tag.fill", title: "Category")

                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)

                            // Live readout showing the currently selected segment.
                            Text("Category: \(selectedCategory)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: All-Day Toggle Card
                    // Flipping this on also collapses the time wheel in the DatePicker card above,
                    // which is a good demonstration of one @State variable controlling two views.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "sun.max.fill", title: "All-Day Event")

                            // $isAllDay is the two-way binding: Toggle reads it to
                            // set its starting position, and writes back on each tap.
                            Toggle("All-day", isOn: $isAllDay)

                            // Live readout of the toggle state.
                            Text("All-day: \(isAllDay ? "On" : "Off")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Priority Slider Card
                    // step: 1 snaps the thumb to whole-number positions.
                    // The label inside the trailing closure is read by Eye Tracking / VoiceOver.
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            CardHeader(icon: "exclamationmark.triangle.fill", title: "Priority")

                            Slider(value: $priority, in: 1...5, step: 1) {
                                Text("Priority")
                            }

                            // Int(priority) converts the Double to a whole number for display.
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
            // .ornament() is visionOS-only. It pins a floating panel to the outside
            // edge of the window. attachmentAnchor: .scene(.bottom) places it just
            // below the bottom edge — like a toolbar that hovers in space rather
            // than sitting inside the main panel. Users look at it and pinch to tap.
            .ornament(attachmentAnchor: .scene(.bottom)) {
                HStack(spacing: 16) {

                    // Main button: schedules 4 repeated reminders at the chosen date.
                    Button(action: scheduleNotification) {
                        Label("Set Reminder", systemImage: "bell.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)

                    // Test button: fires 4 notifications starting in 10 seconds,
                    // 5 seconds apart, so you can verify the pipeline without
                    // setting a real future date.
                    Button(action: scheduleTestNotification) {
                        Label("Test · 10 s", systemImage: "timer")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                // The ornament gets its own glass panel so it looks like a
                // standard visionOS toolbar chip floating below the window.
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
        // MARK: Confirmation / Error Alert
        // showConfirmationAlert is flipped to true at the end of both schedule
        // functions. alertTitle and alertMessage are always set before that flip.
        .alert(alertTitle, isPresented: $showConfirmationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Schedule Notification at Chosen Date
    // Validates that the picked date is in the future, then schedules 4 notifications
    // 5 seconds apart starting at eventDate so the reminder repeats rather than
    // firing once and being easy to miss.
    func scheduleNotification() {

        // Reject a past date immediately — a calendar trigger in the past never fires,
        // it would just silently do nothing with no feedback to the user.
        guard eventDate > Date() else {
            alertTitle = "Invalid Date"
            alertMessage = "The selected date and time is in the past. Please pick a future time."
            showConfirmationAlert = true
            return
        }

        let center = UNUserNotificationCenter.current()

        // requestAuthorization shows the system prompt the first time; on later calls
        // it returns the cached answer without prompting again.
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

                // The four time offsets (in seconds) relative to eventDate.
                // Notification 1 fires at the chosen time, then one every 5 seconds after.
                let offsets: [TimeInterval] = [0, 5, 10, 15]

                // DispatchGroup lets us know when all four center.add() callbacks
                // have finished so we can show exactly one Alert at the end.
                let group = DispatchGroup()

                // Collect any errors that come back from the four add() calls.
                var addErrors: [Error] = []

                // Loop: schedule one notification per offset.
                for (index, offset) in offsets.enumerated() {

                    // Shift the chosen date forward by the offset to get each fire time.
                    let fireDate = eventDate.addingTimeInterval(offset)

                    // Include .second in the date components so the 5-second gaps are
                    // preserved. Without .second, all four would round to the same minute.
                    // For all-day events we still include seconds so the offsets work,
                    // but drop hour/minute to keep the all-day semantic.
                    let calComponents: Set<Calendar.Component> = isAllDay
                        ? [.year, .month, .day, .second]
                        : [.year, .month, .day, .hour, .minute, .second]

                    let components = Calendar.current.dateComponents(calComponents, from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                    // Build fresh content for each notification so we can vary the title.
                    let content = buildNotificationContent()
                    // Label repeats 2–4 so Notification Center makes them distinct.
                    if index > 0 {
                        content.title = "🔔 \(effectiveTitle) — reminder \(index + 1) of \(offsets.count)"
                    }

                    // Each request needs a unique identifier — reusing the same ID
                    // would let a later request silently replace an earlier one.
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: trigger
                    )

                    // Tell the group one more async job is starting.
                    group.enter()
                    center.add(request) { error in
                        DispatchQueue.main.async {
                            if let error = error { addErrors.append(error) }
                            // Signal the group that this job is done.
                            group.leave()
                        }
                    }
                }

                // group.notify runs on the main queue only after all four leave() calls
                // have been received — i.e., after every center.add() has finished.
                group.notify(queue: .main) {
                    if let first = addErrors.first {
                        alertTitle = "Error"
                        alertMessage = "Could not schedule all reminders: \(first.localizedDescription)"
                    } else {
                        alertTitle = "Reminders Set"
                        alertMessage = "4 reminders for \"\(effectiveTitle)\" starting \(eventDate.formatted(date: .long, time: isAllDay ? .omitted : .shortened)), repeating every 5 seconds. (\(selectedCategory), Priority \(Int(priority))/5)"
                    }
                    showConfirmationAlert = true
                }
            }
        }
    }

    // MARK: - Schedule Test Notifications (10, 15, 20, 25 seconds from now)
    // Skips the picked date and uses UNTimeIntervalNotificationTrigger so you can
    // verify the banner + sound pipeline quickly without waiting for a real date.
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

                // Start the first test at 10 seconds; each subsequent one adds 5 more.
                let intervals: [TimeInterval] = [10, 15, 20, 25]

                let group = DispatchGroup()
                var addErrors: [Error] = []

                // Loop: one notification per interval.
                for (index, interval) in intervals.enumerated() {

                    // UNTimeIntervalNotificationTrigger fires after `interval` seconds.
                    // It's simpler than a calendar trigger and perfect for testing.
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

                    let content = buildNotificationContent()
                    // Label each test notification with its sequence number and countdown.
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
                        alertMessage = "4 test notifications for \"\(effectiveTitle)\" will appear at 10 s, 15 s, 20 s, and 25 s. Background the app now."
                    }
                    showConfirmationAlert = true
                }
            }
        }
    }

    // MARK: - Build Notification Content
    // Creates a UNMutableNotificationContent filled with the current form values.
    // Both schedule functions call this so the content is always consistent.
    private func buildNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        // Use the user's typed title, falling back to "Category Event" if blank.
        content.title = effectiveTitle
        content.body = "📅 \(eventDate.formatted(date: .long, time: isAllDay ? .omitted : .shortened)) · \(selectedCategory) · Priority \(Int(priority))/5"
        // Use the custom alarm sound bundled with the app.
        // The file must be named alarm.caf and added to the app target (see notes below).
        // If the file is missing the system falls back to the default sound automatically.
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.caf"))
        return content
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
