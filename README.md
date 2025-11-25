# SwiftUI Table Environment Bug

## Summary

This project demonstrates a bug in SwiftUI where environment objects accessed via `@Environment(...)`, `@EnvironmentObject`, and standard environment values like `@Environment(\.colorScheme)` are not properly propagated to views inside `Table` rows when scrolling.

## Bug Description

- Using a `Button` with `.buttonStyle(.plain)` in `Table` cells causes environment objects to be lost during scrolling/view recycling
- The button doesn't need to do anything - empty action is enough
- Without `.buttonStyle(.plain)`, the same code works fine
- Other button styles (default, bordered, etc.) don't trigger the crash
- This seems to be a **SwiftUI bug** where `.plain` button style breaks environment propagation

**Minimal reproduction:**
- Simple `Table` with items
- Cell accesses environment values
- Cell has `Button` with `.buttonStyle(.plain)`
- Scroll → Crash!

### Error Message

```
SwiftUICore/Environment+Objects.swift:34: Fatal error: No Observable object of type [ViewModel] found.
A View.environmentObject(_:) for [ViewModel] may be missing as an ancestor of this view.
```

## Expected Behavior

Environment objects and values should be available throughout the view hierarchy, including inside `Table` row views, without requiring manual re-injection.

## Actual Behavior

The environment is lost somewhere between the `Table`/`TableColumn` and the cell views, causing crashes when scrolling triggers view recycling.

## Reproduction Steps

1. Open `TableEnvironmentBug.xcodeproj` in Xcode
2. Build and run the app (⌘R)
3. The app will launch showing a table with 100 rows
4. **Scroll down in the table** to trigger view recycling
5. **The app crashes immediately** while scrolling with this fatal error:
   ```
   SwiftUICore/Environment+Objects.swift:34: Fatal error: No Observable object of type ObservableViewModel found.
   A View.environmentObject(_:) for ObservableViewModel may be missing as an ancestor of this view.
   ```

**Note**: Initially visible rows display fine. The bug only manifests when scrolling triggers view recycling.

**Verification**: Comment out `.buttonStyle(.plain)` on line 28 of `TableCell.swift` and the crash disappears!

## Workarounds

Two workarounds are available:

### Option 1: Don't use `.buttonStyle(.plain)`
```swift
Button("Info") { }
// .buttonStyle(.plain)  // ← Remove this line
```

### Option 2: Manually re-inject environment (if you need plain buttons)
```swift
TableColumn("Item") { item in
    TableCell(item: item)
        .environment(observableViewModel)       // Manual re-injection
        .environmentObject(observableObjectViewModel)  // Manual re-injection
}
```

Both workarounds should not be necessary - this is clearly a SwiftUI bug.

## Project Structure

- **ViewModels.swift**: Both `@Observable` and `ObservableObject` view models
- **TableCell.swift**: Simple cell that:
  - Accesses environment values in body
  - Contains a `Button` with `.buttonStyle(.plain)` (the root cause!)
- **ContentView.swift**: Simple `Table` with 100 items
- **TableEnvironmentBugApp.swift**: Sets up environment

## Environment

- **macOS Version**: macOS 15.7.1 and 26.1
- **Xcode Version**: 26.1
- **Swift Version**: 6.0

## Additional Notes

This issue was discovered in production code where it only manifested during scrolling in a `Table` view, making it difficult to debug. The same pattern works correctly in `List` views and other SwiftUI containers.

The bug appears to be related to view recycling in `Table` when scrolling, as it doesn't crash immediately upon launch but only after scrolling begins.

### Critical Elements

The bug requires only these elements:

1. **Button with `.buttonStyle(.plain)` in cell** - This is the root cause:
   ```swift
   Button("Info") { }
   .buttonStyle(.plain)  // ← This single line causes the bug!
   ```

2. **Cell accesses environment values** - Anywhere in the cell body:
   ```swift
   Text("\(observableViewModel.name)")  // ← Crashes here after scrolling
   ```

3. **Scrolling** - Triggers view recycling where environment is lost
   - Initially visible rows: ✅ Work fine
   - After scrolling: 💥 Crash

**Key insight:** `.buttonStyle(.plain)` somehow breaks environment propagation in `Table` cells during view recycling. Other button styles work fine. The button doesn't even need to do anything - an empty action is enough to trigger the crash.
