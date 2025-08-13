//
//  XCTestCaseExtensions.swift
//  EssentialFeedTests
//
//  Created by Neutron Stein on 12/08/2025.
//

import XCTest

extension XCTestCase {
    func expectation(_ description: String = "wait for completion") -> XCTestExpectation {
        XCTestExpectation(description: description)
    }
    
    func trackMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance \(type(of: instance)) should have been deallocated. Potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
