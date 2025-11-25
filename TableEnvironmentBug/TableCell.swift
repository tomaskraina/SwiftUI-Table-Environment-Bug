import SwiftUI


struct TableCell: View {

	@Environment(ObservableViewModel.self) private var observableViewModel
	@EnvironmentObject private var observableObjectViewModel: ObservableObjectViewModel
	@Environment(\.colorScheme) private var colorScheme

	let item: Item

	var body: some View {
		HStack {
			Text("Row \(self.item.id)")

            // Pull objects or values from Environment
            Text("Observable: \(self.observableViewModel.name)")
            Text("ObservableObject: \(self.observableObjectViewModel.name)")
            Text("ColorScheme: \(self.colorScheme == .dark ? "Dark" : "Light")")

			Spacer()

            // Including a plain style button will make it crash on scroll:
            // SwiftUICore/Environment+Objects.swift:34: Fatal error: No Observable object of type ObservableViewModel found. A View.environmentObject(_:) for ObservableViewModel may be missing as an ancestor of this view.
			Button("Info") {
                // nothing
			}
            .buttonStyle(.plain) // comment out this line and it won't crash
		}
	}
}


// MARK: - Item Model

struct Item: Identifiable, Hashable {

	let id: Int
	let name: String
}
