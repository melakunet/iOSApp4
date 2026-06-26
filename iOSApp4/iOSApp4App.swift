//
//  iOSApp4App.swift
//  iOSApp4
//
//  Created by Etefworkie Melaku on 2026-06-24.
//

import SwiftUI
import UserNotifications

// MARK: - Notification Delegate
// By default, visionOS (and iOS) silently swallow any notification that
// arrives while the app is open in the foreground — the user never sees it.
// This delegate class overrides that: whenever a notification would fire,
// the system asks us what to do, and we say "show the banner and play the sound."
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // Called every time a notification is about to be delivered while the app
    // is running in the foreground. completionHandler is a callback we must
    // call to tell the system which parts of the notification to present.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // .banner shows the drop-down banner, .sound plays the alert tone.
        // Without this the notification would be delivered silently with no UI.
        completionHandler([.banner, .sound])
    }
}

// MARK: - App Entry Point
@main
struct iOSApp4App: App {

    // The delegate must be stored as a property so it stays alive for the
    // entire app session. A local variable would be released immediately
    // and the delegate connection would silently break.
    private let notificationDelegate = NotificationDelegate()

    init() {
        // Register the delegate before any other code runs so we never miss
        // a notification that arrives early in the app lifecycle.
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
