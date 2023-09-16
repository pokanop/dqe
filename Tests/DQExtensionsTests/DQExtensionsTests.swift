import XCTest
@testable import DQExtensions

final class DQExtensionsTests: XCTestCase {
    
    func testInitialize() {
        XCTAssertFalse(isMainQueue)
        DQExtensions.initialize()
        XCTAssertTrue(isMainQueue)
    }
    
    func testIsMainQueue() {
        DQExtensions.initialize()
        XCTAssertTrue(isMainQueue)
        
        DispatchQueue.global().sync {
            XCTAssertFalse(isMainQueue)
        }
    }
    
    func testQueueName() {
        DQExtensions.initialize()
        let queueNames: [String: DispatchQueue] = [
            "main": DispatchQueue.main,
            "background": DispatchQueue.background(),
            "utility": DispatchQueue.utility(),
            "default": DispatchQueue.default(),
            "userInitiated": DispatchQueue.userInitiated(),
            "userInteractive": DispatchQueue.userInteractive(),
            "custom": DispatchQueue(name: "custom")
        ]
        queueNames.forEach { name, queue in
            guard queue != DispatchQueue.main else {
                XCTAssertEqual(queueName, "main")
                return
            }
            
            queue.sync {
                XCTAssertEqual(queueName, name)
            }
        }
        DispatchQueue.global().sync {
            XCTAssertEqual(queueName, "default")
        }
    }
    
    func testName() {
        DQExtensions.initialize()
        let queueNames: [String: DispatchQueue] = [
            "main": DispatchQueue.main,
            "background": DispatchQueue.background(),
            "utility": DispatchQueue.utility(),
            "default": DispatchQueue.default(),
            "userInitiated": DispatchQueue.userInitiated(),
            "userInteractive": DispatchQueue.userInteractive(),
            "custom": DispatchQueue(name: "custom")
        ]
        queueNames.forEach { name, queue in
            XCTAssertEqual(queue.name, name)
        }
        XCTAssertEqual(DispatchQueue.global().name, "default")
    }
    
    func testIsCurrent() {
        DQExtensions.initialize()
        let queueNames: [String: DispatchQueue] = [
            "main": DispatchQueue.main,
            "background": DispatchQueue.background(),
            "utility": DispatchQueue.utility(),
            "default": DispatchQueue.default(),
            "userInitiated": DispatchQueue.userInitiated(),
            "userInteractive": DispatchQueue.userInteractive(),
            "custom": DispatchQueue(name: "custom")
        ]
        queueNames.forEach { name, queue in
            guard queue != DispatchQueue.main else {
                XCTAssertTrue(queue.isCurrent)
                return
            }
            
            queue.sync {
                XCTAssertTrue(queue.isCurrent)
            }
        }
        DispatchQueue.global().sync {
            XCTAssertTrue(DispatchQueue.global().isCurrent)
        }
    }
    
    func testSync() {
        DQExtensions.initialize()
        let queueNames: [String: DispatchQueue] = [
            "main": DispatchQueue.main,
            "background": DispatchQueue.background(),
            "utility": DispatchQueue.utility(),
            "default": DispatchQueue.default(),
            "userInitiated": DispatchQueue.userInitiated(),
            "userInteractive": DispatchQueue.userInteractive(),
            "custom": DispatchQueue(name: "custom")
        ]
        queueNames.forEach { name, queue in
            queue.safeSync {
                XCTAssertTrue(queue.isCurrent)
            }
        }
        DispatchQueue.global().safeSync {
            XCTAssertTrue(DispatchQueue.global().isCurrent)
        }
    }
    
    func testDebounce() {
        let queue = DispatchQueue(name: "custom")
        var words: [String] = []
        
        for i in 0..<10 {
            queue.debounce(for: 0.3, identifier: "foo") {
                words.append("bar \(i)")
            }
            queue.debounce(for: 0.3, identifier: "bar") {
                words.append("foo \(i)")
            }
        }
        
        XCTAssertTrue(words.isEmpty)
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(words.isEmpty)
        XCTAssertEqual(words.count, 2)
        
        words.removeAll()
        
        for i in 0..<10 {
            queue.debounce(for: 0.025, identifier: "foo") {
                words.append("bar \(i)")
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(words.isEmpty)
        XCTAssertEqual(words.count, 10)
    }
    
    func testThrottle() {
        let queue = DispatchQueue(name: "custom")
        var words: [String] = []
        
        for i in 0..<10 {
            queue.throttle(for: 0.3, identifier: "foo") {
                words.append("bar \(i)")
            }
            queue.throttle(for: 0.3, identifier: "bar") {
                words.append("foo \(i)")
            }
        }
        
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertFalse(words.isEmpty)
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(words.count, 2)
        
        words.removeAll()
        
        for i in 0..<10 {
            queue.throttle(for: 0.025, identifier: "foo") {
                words.append("bar \(i)")
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(words.isEmpty)
        XCTAssertEqual(words.count, 10)
        
        words.removeAll()
        
        for i in 0..<10 {
            queue.throttle(for: 0.025, identifier: "foo", async: false) {
                words.append("bar \(i)")
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        XCTAssertFalse(words.isEmpty)
        XCTAssertEqual(words.count, 10)
    }

    static var allTests = [
        ("testIsMainQueue", testIsMainQueue),
    ]
    
}
