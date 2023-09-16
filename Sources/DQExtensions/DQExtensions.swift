import Foundation

// MARK: - Dispatch Queue Extensions

///
/// DQExtensions provides facilities to identify queues reliably and convenience methods to
/// provide for more powerful interactions with Grand Central Dispatch's core API.
///
public extension DispatchQueue {
    
    fileprivate enum Kind: CaseIterable {
        
        case main
        case background
        case utility
        case `default`
        case userInitiated
        case userInteractive
        case custom(String)
        
        static var allCases: [Kind] {
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
        
        var queue: DispatchQueue? {
            switch self {
            case .main: return .main
            case .background: return .background()
            case .utility: return .utility()
            case .default: return .default()
            case .userInitiated: return .userInitiated()
            case .userInteractive: return .userInteractive()
            case .custom: return nil
            }
        }
        
        static func from(name: String) -> Kind {
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
    
    fileprivate struct Context {
        
        var kind: Kind
        var debounce: [AnyHashable: DispatchWorkItem] = [:]
        var throttle: Set<AnyHashable> = Set()
        
        var name: String? { kind.name }
        var queue: DispatchQueue? { kind.queue }
        
        init(kind: Kind) {
            self.kind = kind
        }
        
    }
    
    fileprivate static let contextKey = DispatchSpecificKey<Context>()
    
    fileprivate static var context: Context? { getSpecific(key: DispatchQueue.contextKey) }
    
    fileprivate var context: Context? { getSpecific(key: DispatchQueue.contextKey) }
    
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
        let kind: Kind = .from(name: name)
        if var context = self.context {
            context.kind = kind
            set(context: context)
        } else {
            set(context: Context(kind: kind))
        }
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
    func safeSync(_ work: () -> ()) {
        guard !isCurrent else { work(); return }
        dispatchPrecondition(condition: .notOnQueue(self))
        sync(execute: work)
    }
    
    ///
    /// Submits a `DispatchWorkItem` for synchronous execution on this queue safely.
    ///
    /// If the queue is already executing, the `workItem` is performed inline without dispatching
    /// synchronously which would otherwise lead to a deadlock.
    ///
    /// - Parameter workItem: The `DispatchWorkItem` to execute.
    ///
    func safeSync(execute workItem: DispatchWorkItem) {
        guard !isCurrent else { workItem.perform(); return }
        dispatchPrecondition(condition: .notOnQueue(self))
        sync(execute: workItem)
    }
    
    ///
    /// Debounce execution of work based on a deadline for the given identifier.
    ///
    /// Executes the work **later** by debouncing calls until deadline is exceeded. Keyed
    /// by identifier for associating unique work items to be debounced.
    ///
    /// - Parameters:
    ///   - interval: Time to wait before execution.
    ///   - identifier: A unique hashable identifier.
    ///   - work: The work item to execute after deadline.
    ///
    func debounce(for interval: TimeInterval,
                  identifier: AnyHashable,
                  execute work: @escaping () -> ()) {
        guard var context = self.context else { assertionFailure(); return }
        
        // Cancel previous work and update context
        if let workItem = context.debounce[identifier] {
            workItem.cancel()
            context.debounce[identifier] = nil
        }
        
        // Create self removing work item
        let workItem = DispatchWorkItem { [weak self] in
            work()
            context.debounce[identifier] = nil
            self?.set(context: context)
        }
        
        // Insert work item into context
        context.debounce[identifier] = workItem
        set(context: context)
        
        // Queue the work item after interval
        asyncAfter(deadline: .now() + interval, execute: workItem)
    }
    
    ///
    /// Throttle execution of work based on an interval for the given identifier.
    ///
    /// Executes the work **immediately** and throttles calls until deadline is exceeded. Keyed
    /// by identifier for associating unique work items to be throttled.
    ///
    /// - Parameters:
    ///   - interval: Time to wait after execution.
    ///   - identifier: A unique hashable identifier.
    ///   - async: Whether to execute work asynchronously or not.
    ///   - work: The work item to execute before deadline.
    ///
    func throttle(for interval: TimeInterval,
                  identifier: AnyHashable,
                  async: Bool = true,
                  execute work: @escaping () -> ()) {
        // Create the work item that will update deadline
        let workItem = DispatchWorkItem { [weak self] in
            // Execute the work
            work()
            
            // Remove from context after deadline
            self?.asyncAfter(deadline: .now() + interval) { [weak self] in
                guard var context = self?.context else { return }
                
                context.throttle.remove(identifier)
                self?.set(context: context)
            }
        }
        
        // Deadline not exceeded so return
        guard context?.throttle.contains(identifier) == false else { return }
        
        guard var context = self.context else { return }
        
        // No throttle time so execute immediately and update deadline
        context.throttle.insert(identifier)
        set(context: context)
        
        // Execute the work
        async ? self.async(execute: workItem) : self.safeSync(execute: workItem)
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
public var currentQueue: DispatchQueue? { DispatchQueue.context?.queue }

///
/// Bootstrap the `DispatchQueue` extensions using this method somewhere early in the lifecycle.
///
public func initialize() {
    
    DispatchQueue.Kind.allCases.forEach { $0.queue?.set(name: $0.name) }
    
}
