import SwiftUI


@main
struct TableEnvironmentBugApp: App {

	@State private var observableViewModel = ObservableViewModel()
	@StateObject private var observableObjectViewModel = ObservableObjectViewModel()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(self.observableViewModel)
				.environmentObject(self.observableObjectViewModel)
		}
	}
}
