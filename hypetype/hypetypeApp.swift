//
//  hypetypeApp.swift
//  hypetype
//
//  Created by Ruslan Mamedov on 25.12.2025.
//

import SwiftUI

@main
struct hypetypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
