//
//  FailableCoreDataStub.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/9/22.
//

import CoreData

extension NSManagedObjectContext {
    static func expectsEmptyRetrieval() -> Stub {
        Stub(
            #selector(NSManagedObjectContext.__execute(_:)),
            #selector(Stub.execute(_:))
        )
    }
    
    class Stub: NSObject {
        private let source: Selector
        private let destination: Selector
        
        init(_ source: Selector, _ destination: Selector) {
            self.source = source
            self.destination = destination
        }
        
        @objc func execute(_ request: NSPersistentStoreRequest) throws -> Any {
            if request.requestType == .fetchRequestType {
                return []
            }
            throw anyNSError()
        }
        
        func startIntercepting() {
            method_exchangeImplementations(
                class_getInstanceMethod(NSManagedObjectContext.self, source)!,
                class_getInstanceMethod(Stub.self, destination)!
            )
        }
        
        deinit {
            method_exchangeImplementations(
                class_getInstanceMethod(Stub.self, destination)!,
                class_getInstanceMethod(NSManagedObjectContext.self, source)!
            )
        }
    }
}
