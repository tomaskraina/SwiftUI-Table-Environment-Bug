import Foundation
import SwiftUI


// MARK: - Observable ViewModel (new API)

@Observable
final class ObservableViewModel {

	var name: String = "Observable ViewModel"
	var counter: Int = 0

	func increment() {
		self.counter += 1
	}
}


// MARK: - ObservableObject ViewModel (old API)

final class ObservableObjectViewModel: ObservableObject {

	@Published var name: String = "ObservableObject ViewModel"
	@Published var counter: Int = 0

	func increment() {
		self.counter += 1
	}
}
