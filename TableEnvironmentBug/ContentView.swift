import SwiftUI


struct ContentView: View {

	private let items: [Item] = (1...100).map { Item(id: $0, name: "Item \($0)") }

	var body: some View {
		VStack {
			Text("SwiftUI Table Environment Bug")
				.font(.title)
				.padding()

			Text("Scroll down, then click 'Info' to crash")
				.foregroundStyle(.secondary)

			Table(of: Item.self) {
				TableColumn("Item") { item in
					TableCell(
						item: item
					)
				}
			} rows: {
				ForEach(self.items) { item in
					TableRow(item)
				}
			}
		}
		.frame(minWidth: 500, minHeight: 600)
		.padding()
	}
}
