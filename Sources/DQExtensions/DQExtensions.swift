import Foundation

// MARK: - Dispatch Queue Extensions

///
/// DQExtentions provides facilities to identify queues reliably and convenience methods to
/// provide for more powerful interactions with Grand Central Dispatch's core API.
///
public extension DispatchQueue {
    
    fileprivate enum Context: CaseIterable {
        case main
        case background
        case utility
        case `default`
        case userInitiated
        case userInteractive
        case custom(String)
        
        static var allCases: [Context] {
            [.main, .background, .utility, .default, .userInitiated, .userInteractive]
        }
        
        var name: String {
            switch self {
            case .main: return "main"
            case .background: return "background"
            case .utility: return "utility"
            case .default: return "default"
            case .userInitiated: return "userInitiated"
            case .userInteractive: return "userInteractive"
            case .custom(let name): return name
            }
        }
        
        var associatedQueue: DispatchQueue? {
            switch self {
            case .main: return DispatchQueue.main
            case .background: return DispatchQueue.background()
            case .utility: return DispatchQueue.utility()
            case .default: return DispatchQueue.default()
            case .userInitiated: return DispatchQueue.userInitiated()
            case .userInteractive: return DispatchQueue.userInteractive()
            case .custom: return nil
            }
        }
        
        static func from(name: String) -> Context {
            switch name {
            case "main": return .main
            case "background": return .background
            case "utility": return .utility
            case "default": return .default
            case "userInitiated": return .userInitiated
            case "userInteractive": return .userInteractive
            default: return .custom(name)
            }
        }
    }
    
    fileprivate static let contextKey = DispatchSpecificKey<Context>()
    
    fileprivate static var context: Context? { getSpecific(key: DispatchQueue.contextKey) }
    
    fileprivate static var name: String? { context?.name }
    
    ///
    /// The associated name of the queue.
    ///
    var name: String? { getSpecific(key: DispatchQueue.contextKey)?.name }
    
    ///
    /// Returns true if this queue is the currently executing queue.
    ///
    var isCurrent: Bool { name != nil && name == queueName }
    
    ///
    /// Returns the global dispatch queue with a quality of service of `.background`.
    ///
    static func background() -> DispatchQueue {
        global(qos: .background)
    }

    ///
    /// Returns the global dispatch queue with a quality of service of `.utility`.
    ///
    static func utility() -> DispatchQueue {
        global(qos: .utility)
    }

    ///
    /// Returns the global dispatch queue with a quality of service of `.default`.
    ///
    static func `default`() -> DispatchQueue {
        global(qos: .default)
    }

    ///
    /// Returns the global dispatch queue with a quality of service of `.userInitiated`.
    ///
    static func userInitiated() -> DispatchQueue {
        global(qos: .userInitiated)
    }
    
    ///
    /// Returns the global dispatch queue with a quality of service of `.userInteractive`.
    ///
    static func userInteractive() -> DispatchQueue {
        global(qos: .userInteractive)
    }
    
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
                     target: DispatchQueue? = nil) {
        self.init(label: name,
                  qos: qos,
                  attributes: attributes,
                  autoreleaseFrequency: autoreleaseFrequency,
                  target: target)
        set(name: name)
    }
    
    ///
    /// Set the name of the queue.
    ///
    /// - Parameter name: The name of the queue to set.
    ///
    func set(name: String) {
        set(context: Context.from(name: name))
    }
    
    fileprivate func set(context: Context) {
        setSpecific(key: DispatchQueue.contextKey, value: context)
    }
    
    ///
    /// Submits a closure for synchronous execution on this queue safely.
    ///
    /// If the queue is already executing, the `work` is executed inline without dispatching
    /// synchronously which would otherwise lead to a deadlock.
    ///
    /// - Parameter work: The closure to execute.
    ///
    func syncSafe(_ work: () -> ()) {
        guard !isCurrent else { work(); return }
        sync(execute: work)
    }
    
}

// MARK: - Global Properties & Methods

///
/// Checks if the main queue is currently executing.
///
public var isMainQueue: Bool { queueName != nil && queueName == DispatchQueue.main.name }

///
/// Get the currently executing queue's name.
///
/// This relies on standard GCD queues and any custom queues **must** use the convenience initializer
/// to create with a `name` attribute or use the `set(name:)` method to ensure queues are named.
///
public var queueName: String? { DispatchQueue.name }

///
/// Get the currently executing queue.
///
/// This relies on standard GCD queues which can be associated with names. Custom queues
/// cannot be fetched using this mechanism and will return `nil` if executing.
///
public var currentQueue: DispatchQueue? { DispatchQueue.context?.associatedQueue }

///
/// Bootstrap the `DispatchQueue` extensions using this method somewhere early in the lifecycle.
///
public func initialize() {
    DispatchQueue.Context.allCases.forEach { $0.associatedQueue?.set(context: $0) }
}
