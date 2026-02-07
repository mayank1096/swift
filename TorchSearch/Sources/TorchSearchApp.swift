import SwiftUI

/// The entry point of the app. This is where iOS starts running your code.
///
/// `@main` tells the system "this is the starting point."
/// `WindowGroup` creates the app window and loads ContentView into it.
@main
struct TorchSearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
