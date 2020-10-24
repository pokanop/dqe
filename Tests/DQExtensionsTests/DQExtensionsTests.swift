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
            queue.syncSafe {
                XCTAssertTrue(queue.isCurrent)
            }
        }
        DispatchQueue.global().syncSafe {
            XCTAssertTrue(DispatchQueue.global().isCurrent)
        }
    }

    static var allTests = [
        ("testIsMainQueue", testIsMainQueue),
    ]
    
}
