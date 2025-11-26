# macOS SwiftUI Table Environment Bug

**Apple Feedback:** FB21161857

## Summary

This project demonstrates a bug in SwiftUI where environment objects accessed via `@Environment(...)`, `@EnvironmentObject`, (as well as standard environment values like `@Environment(\.colorScheme)`) are not properly propagated to views inside `Table` rows when scrolling, causing the app to crash when accessing those environment objects:

<img width="1512" height="945" alt="Screenshot 2025-11-26 at 9 17 17" src="https://github.com/user-attachments/assets/9537e2a2-3103-4a22-8255-aa0646d20ba1" />

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

## Callstack

```
* thread #1, queue = 'com.apple.main-thread', stop reason = Fatal error: No Observable object of type ObservableViewModel found. A View.environmentObject(_:) for ObservableViewModel may be missing as an ancestor of this view.
  * frame #0: 0x00000001a38c6a20 libswiftCore.dylib`_swift_runtime_on_report
    frame #1: 0x00000001a399ec44 libswiftCore.dylib`_swift_stdlib_reportFatalErrorInFile + 208
    frame #2: 0x00000001a3566080 libswiftCore.dylib`closure #1 in _assertionFailure(_:_:file:line:flags:) + 512
    frame #3: 0x00000001a35651f8 libswiftCore.dylib`_assertionFailure(_:_:file:line:flags:) + 176
    frame #4: 0x00000001f8a292ec SwiftUICore`function signature specialization <Arg[0] = Dead> of SwiftUI.EnvironmentValues.subscript.getter : <τ_0_0 where τ_0_0: AnyObject>(forceUnwrapping: SwiftUI.EnvironmentObjectKey<τ_0_0>) -> τ_0_0 + 352
    frame #5: 0x00000001f90aeb78 SwiftUICore`key path getter for SwiftUI.EnvironmentValues.subscript<τ_0_0 where τ_0_0: AnyObject>(forceUnwrapping: SwiftUI.EnvironmentObjectKey<τ_0_0>) -> τ_0_0 : <τ_0_0 where τ_0_0: AnyObject, τ_0_0: Observation.Observable>SwiftUI.EnvironmentValuesτ_0_0 + 68
    frame #6: 0x00000001a3691054 libswiftCore.dylib`specialized project2 #1 (_:) in project #1 <τ_0_0, τ_0_1><τ_1_0>(_:) in closure #2 in KeyPath._projectReadOnly(from:) + 968
    frame #7: 0x00000001a3690950 libswiftCore.dylib`KeyPath._projectReadOnly(from:) + 1016
    frame #8: 0x00000001a3695544 libswiftCore.dylib`swift_getAtKeyPath + 24
    frame #9: 0x00000001f8eeeab0 SwiftUICore`closure #1 in EnvironmentBox.update(property:phase:) + 72
    frame #10: 0x00000001f8ef139c SwiftUICore`partial apply for closure #1 in EnvironmentBox.update(property:phase:) + 20
    frame #11: 0x00000001f8ef258c SwiftUICore`closure #1 in _withObservation(do:) + 48
    frame #12: 0x00000001f8b1f780 SwiftUICore`partial apply for closure #1 in _withObservation(do:) + 28
    frame #13: 0x00000001f8f5e5c4 SwiftUICore`withUnsafeMutablePointer(to:_:) + 160
    frame #14: 0x00000001f8eee4cc SwiftUICore`EnvironmentBox.update(property:phase:) + 1612
    frame #15: 0x00000001f8c7b4b8 SwiftUICore`static BoxVTable.update(elt:property:phase:) + 384
    frame #16: 0x00000001f8c7b008 SwiftUICore`_DynamicPropertyBuffer.update(container:phase:) + 144
    frame #17: 0x00000001f8d0349c SwiftUICore`closure #1 in closure #1 in DynamicBody.updateValue() + 304
    frame #18: 0x00000001f8d0547c SwiftUICore`partial apply for closure #1 in closure #1 in DynamicBody.updateValue() + 32
    frame #19: 0x00000001f8f5e5c4 SwiftUICore`withUnsafeMutablePointer(to:_:) + 160
    frame #20: 0x00000001f8d03250 SwiftUICore`closure #1 in DynamicBody.updateValue() + 424
    frame #21: 0x00000001f8d02d2c SwiftUICore`DynamicBody.updateValue() + 928
    frame #22: 0x00000001f8d90998 SwiftUICore`partial apply for implicit closure #1 in closure #1 in closure #1 in Attribute.init(_:) + 32
    frame #23: 0x00000001c32d9728 AttributeGraph`AG::Graph::UpdateStack::update() + 524
    frame #24: 0x00000001c32d9f94 AttributeGraph`AG::Graph::update_attribute(AG::data::ptr<AG::Node>, unsigned int) + 420
    frame #25: 0x00000001c32e17b0 AttributeGraph`AG::Graph::value_ref(AG::AttributeID, unsigned int, AGSwiftMetadata const*, unsigned char&) + 272
    frame #26: 0x00000001c32f8ed0 AttributeGraph`AGGraphGetWeakValue + 368
    frame #27: 0x00000001f8ed8d10 SwiftUICore`GraphHost.updatePreferences() + 68
    frame #28: 0x00000001f92960cc SwiftUICore`ViewGraph.updateOutputs(async:) + 436
    frame #29: 0x00000001f928bc70 SwiftUICore`closure #2 in closure #1 in ViewRendererHost.render(interval:updateDisplayList:targetTimestamp:) + 224
    frame #30: 0x00000001f928ba24 SwiftUICore`closure #1 in ViewRendererHost.render(interval:updateDisplayList:targetTimestamp:) + 772
    frame #31: 0x00000001f9288ebc SwiftUICore`ViewRendererHost.render(interval:updateDisplayList:targetTimestamp:) + 612
    frame #32: 0x00000001c249c868 SwiftUI`closure #1 in NSHostingView.layout() + 568
    frame #33: 0x00000001c24b5664 SwiftUI`partial apply forwarder for reabstraction thunk helper from @callee_guaranteed (@guaranteed __C.RBDisplayList) -> () to @escaping @callee_guaranteed (@guaranteed __C.RBDisplayList) -> () + 28
    frame #34: 0x00000001c2488c18 SwiftUI`reabstraction thunk helper from @escaping @callee_guaranteed (@guaranteed __C.RBDisplayList) -> () to @callee_unowned @convention(block) (@unowned __C.RBDisplayList) -> () + 44
    frame #35: 0x0000000195db8d18 AppKit`+[NSAnimationContext runAnimationGroup:] + 56
    frame #36: 0x00000001c249c5d4 SwiftUI`NSHostingView.layout() + 408
    frame #37: 0x00000001c249cc6c SwiftUI`@objc NSHostingView.layout() + 28
    frame #38: 0x00000001968ccfa8 AppKit`___NSViewLayout_block_invoke + 632
    frame #39: 0x0000000195de3000 AppKit`NSPerformVisuallyAtomicChange + 108
    frame #40: 0x0000000195de78d8 AppKit`_NSViewLayout + 96
    frame #41: 0x00000001968c32cc AppKit`__36-[NSView _layoutSubtreeWithOldSize:]_block_invoke + 372
    frame #42: 0x0000000195de3000 AppKit`NSPerformVisuallyAtomicChange + 108
    frame #43: 0x0000000195de786c AppKit`-[NSView _layoutSubtreeWithOldSize:] + 100
    frame #44: 0x00000001968c3410 AppKit`__36-[NSView _layoutSubtreeWithOldSize:]_block_invoke + 696
    frame #45: 0x0000000195de3000 AppKit`NSPerformVisuallyAtomicChange + 108
    frame #46: 0x0000000195de786c AppKit`-[NSView _layoutSubtreeWithOldSize:] + 100
    frame #47: 0x00000001968c3ea8 AppKit`__56-[NSView _layoutSubtreeIfNeededAndAllowTemporaryEngine:]_block_invoke + 908
    frame #48: 0x0000000195de3000 AppKit`NSPerformVisuallyAtomicChange + 108
    frame #49: 0x0000000195de7444 AppKit`-[NSView _layoutSubtreeIfNeededAndAllowTemporaryEngine:] + 100
    frame #50: 0x0000000195de3000 AppKit`NSPerformVisuallyAtomicChange + 108
    frame #51: 0x0000000195de73d4 AppKit`-[NSView layoutSubtreeIfNeeded] + 96
    frame #52: 0x0000000196bab9d4 AppKit`-[NSWindow(NSConstraintBasedLayoutInternal) _layoutViewTree] + 104
    frame #53: 0x0000000196babb5c AppKit`-[NSWindow(NSConstraintBasedLayoutInternal) layoutIfNeeded] + 240
    frame #54: 0x0000000195e44c34 AppKit`__NSWindowGetDisplayCycleObserverForLayout_block_invoke + 364
    frame #55: 0x0000000195e441b4 AppKit`NSDisplayCycleObserverInvoke + 168
    frame #56: 0x0000000195e43e30 AppKit`NSDisplayCycleFlush + 656
    frame #57: 0x000000019aedea50 QuartzCore`CA::Transaction::run_commit_handlers(CATransactionPhase) + 120
    frame #58: 0x000000019aedd260 QuartzCore`CA::Transaction::commit() + 316
    frame #59: 0x000000019666c804 AppKit`-[_NSScrollingConcurrentMainThreadSynchronizer _synchronize:preCommitHandler:completionHandler:] + 324
    frame #60: 0x000000019666c160 AppKit`__98-[_NSScrollingConcurrentMainThreadSynchronizer initWithSharedData:constantData:scrollingBehavior:]_block_invoke + 152
    frame #61: 0x00000001004812dc libdispatch.dylib`_dispatch_client_callout + 16
    frame #62: 0x0000000100468274 libdispatch.dylib`_dispatch_continuation_pop + 700
    frame #63: 0x000000010048115c libdispatch.dylib`_dispatch_source_latch_and_call + 456
    frame #64: 0x000000010047fa2c libdispatch.dylib`_dispatch_source_invoke + 880
    frame #65: 0x00000001004a4b88 libdispatch.dylib`_dispatch_main_queue_drain.cold.5 + 592
    frame #66: 0x0000000100475d98 libdispatch.dylib`_dispatch_main_queue_drain + 180
    frame #67: 0x0000000100475cd4 libdispatch.dylib`_dispatch_main_queue_callback_4CF + 44
    frame #68: 0x0000000191ebcbe0 CoreFoundation`__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 16
    frame #69: 0x0000000191e7d8dc CoreFoundation`__CFRunLoopRun + 1980
    frame #70: 0x0000000191e7ca98 CoreFoundation`CFRunLoopRunSpecific + 572
    frame #71: 0x000000019d91f27c HIToolbox`RunCurrentEventLoopInMode + 324
    frame #72: 0x000000019d9224e8 HIToolbox`ReceiveNextEventCommon + 676
    frame #73: 0x000000019daad484 HIToolbox`_BlockUntilNextEventMatchingListInModeWithFilter + 76
    frame #74: 0x0000000195da1a34 AppKit`_DPSNextEvent + 684
    frame #75: 0x0000000196740940 AppKit`-[NSApplication(NSEventRouting) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 688
    frame #76: 0x0000000195d94be4 AppKit`-[NSApplication run] + 480
    frame #77: 0x0000000195d6b2dc AppKit`NSApplicationMain + 880
    frame #78: 0x00000001c1bef878 SwiftUI`specialized runApp(_:) + 160
    frame #79: 0x00000001c204d658 SwiftUI`runApp(_:) + 108
    frame #80: 0x00000001c23ae5c0 SwiftUI`static App.main() + 224
    frame #82: 0x00000001004265cc TableEnvironmentBug.debug.dylib`main at TableEnvironmentBugApp.swift:0
    frame #83: 0x00000001919f2b98 dyld`start + 6076
```

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
