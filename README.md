![DQExtensions](Resources/DQExtensions.png)

# DQExtensions

`DispatchQueue` Extensions: The Missing Parts

## Features

This library adds several useful extensions and conveniences for managing `DispatchQueue` types in Grand Central Dispatch.

Apple provides powerful functionality to boot, but there's some things that this library helps solve:

- Unified mechanism to create named dispatch queues
- Ability to identify the currently running queue
- Ability to check if running on the main queue or any specific queue
- Safer `sync` calls that execute inline if same queue detected
- Simplified API for common operations

## Installation

### Swift Package Manager

The project supports SPM and can be added to projects targeting Swift 5.3 and higher.

From Xcode, go to the menu item File -> Swift Packages and select Add Package Dependency. Paste in this github location into the text field and proceed to add the target into your project.

### Carthage

Update your [`Cartfile`](https://github.com/Carthage/Carthage) and run `carthage update`:

```
github "pokanop/dqe"
```

## API

### Global Variables & Methods

DQExtensions **requires** a method call to bootstrap its facilities. From somewhere early in the lifecycle, `initialize` should be called.

```swift
DQExtensions.initialize()
```

To check if running on the **main** queue use the `isMainQueue` global property:

```swift
guard isMainQueue else { return }
```

To get the name of a queue, callers can use the `queueName` global property:

```swift
print("running on queue: \(queueName)")
```

To access the currently running queue _if possible_ use the `currentQueue` global property:

```
guard let currentQueue = currentQueue else { return }

currentQueue.async {
    // Do work
}
```

> Note that this property only works on GCD vended queues and not custom queues since those are not tracked as associated queues to the names.

### DispatchQueue Extensions

To utilize DQExtensions at its fullest capacity, users should use the convenience initializer or use the `set(name:)` method on a private queue that's been created. This allows the extension to be able to deterministically identify queues and make decisioning for things like safe synchronous dispatches and comparing queues.

The convenience init:

```swift
///
/// Create a custom `DispatchQueue` with a name and associated attributes.
///
/// - Parameters:
///   - name: The name of the queue to set.
///   - label: A unique label to set on the queue for debugging purposes.
///   - qos: The quality-of-service level to associate with the queue.
///   - attributes: The attributes to associate with the queue
///   - autoreleaseFrequency: The frequency with which to autorelease objects created by the blocks that the queue schedules
///   - target: The target queue on which to execute block.
///
convenience init(name: String,
                 label: String = "",
                 qos: DispatchQoS = .unspecified,
                 attributes: DispatchQueue.Attributes = [],
                 autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
                 target: DispatchQueue? = nil)
```

Setting a queue name:

```swift
///
/// Set the name of the queue.
///
/// - Parameter name: The name of the queue to set.
///
func set(name: String)
```

DQExtensions provides several static accessors similar to the `DispatchQueue.global()` method for other QoS concurrent queues.

```swift
static func background() -> DispatchQueue
static func utility() -> DispatchQueue
static func `default`() -> DispatchQueue
static func userInitiated() -> DispatchQueue
static func userInteractive() -> DispatchQueue
```

Provided that the extension is initialized and queues are being created with names or set afterwards, DQExtensions provides properties to check for whether the queue is the currently executing one and the name as well.

```swift
///
/// The associated name of the queue.
///
var name: String?

///
/// Returns true if this queue is the currently executing queue.
///
var isCurrent: Bool
```

Dispatching sync on a queue can be disastrous normally if calling from the same queue. The intention of executing in a blocking fashion will deadlock if already on the same queue. DQExtensions provides a `syncSafe(work:)` method that will short circuit this dangerous behavior by running the closure inline, as intended.

```swift
///
/// Submits a closure for synchronous execution on this queue safely.
///
/// If the queue is already executing, the `work` is executed inline without dispatching
/// synchronously which would otherwise lead to a deadlock.
///
/// - Parameter work: The closure to execute.
///
func syncSafe(_ work: () -> ())
```

## Contibuting

Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License.
