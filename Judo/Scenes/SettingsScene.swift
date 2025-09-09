import Everything
import JudoSupport
import Subprocess
import SwiftUI
import System

struct SettingsScene: Scene {
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            DebugSettingsView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
        }
        .windowResizeBehavior(.enabled)
        .frame(minWidth: 640, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
    }
}

