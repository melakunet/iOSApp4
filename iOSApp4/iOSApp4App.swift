//
//  iOSApp4App.swift
//  iOSApp4
//
//  Created by Etefworkie Melaku on 2026-06-24.
//

import SwiftUI
import UserNotifications

// MARK: - Notification Delegate
// Shows notifications as banners while the app is in the foreground.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // Called when a notification arrives while the app is running; we specify what to present.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // .banner — drop-down banner overlay.
        // .list   — persists in Notification Center.
        // .sound  — plays the alert tone.
        // Note: .alert is the deprecated predecessor of .banner; use .banner instead.
        completionHandler([.banner, .list, .sound])
    }
}

// MARK: - App Entry Point
@main
struct iOSApp4App: App {

    // Stored as a property so the delegate stays alive for the full app session.
    private let notificationDelegate = NotificationDelegate()

    init() {
        // Register the delegate before any notifications can arrive.
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
