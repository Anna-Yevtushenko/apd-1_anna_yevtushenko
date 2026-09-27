import XCTest
@testable import StudyPlanner

final class StudyPlannerAdditionalTests: XCTestCase {
    
    func testNonPositiveMinutesAreRejected() {
        XCTAssertThrowsError(
            try StudyItem(
                id: "1",
                title: "Read",
                estimatedMinutes: 0,
                category: .reading
            )
        ) { error in
            XCTAssertEqual(error as? StudyPlanError, .nonPositiveEstimatedMinutes)
        }
    }
    
    func testPositiveMinutesAreAccepted() throws {
        let item = try StudyItem(
            id: "1",
            title: "Read",
            estimatedMinutes: 25,
            category: .reading
        )
        
        XCTAssertEqual(item.estimatedMinutes, 25)
    }
    
    func testDuplicateIDIsRejected() throws {
        let first = try StudyItem(
            id: "swift-basics",
            title: "Read Swift Basics",
            estimatedMinutes: 45,
            category: .reading
        )
        
        let second = try StudyItem(
            id: "swift-basics",
            title: "Practice Swift Syntax",
            estimatedMinutes: 60,
            category: .practice
        )
        
        XCTAssertThrowsError(
            try StudyPlan(items: [first, second])
        ) { error in
            XCTAssertEqual(error as? StudyPlanError, .duplicateID("swift-basics"))
        }
    }
    
    func testUniqueIDsAreAccepted() throws {
        let first = try StudyItem(
            id: "swift-basics",
            title: "Read Swift Basics",
            estimatedMinutes: 45,
            category: .reading
        )
        
        let second = try StudyItem(
            id: "swift-practice",
            title: "Practice Swift Syntax",
            estimatedMinutes: 60,
            category: .practice
        )
        
        let plan = try StudyPlan(items: [first, second])
        
        XCTAssertEqual(plan.items.count, 2)
    }
    
    func testItemsInCategoryReturnsOnlyMatchingItems() throws {
        let readingItem = try StudyItem(
            id: "swift-book-chapter-3",
            title: "Read Swift Programming Chapter 3",
            estimatedMinutes: 40,
            category: .reading
        )
        
        let practiceItem = try StudyItem(
            id: "swift-optionals-practice",
            title: "Practice Swift Optionals",
            estimatedMinutes: 50,
            category: .practice
        )
        
        let plan = try StudyPlan(items: [readingItem, practiceItem])
        
        let result = plan.items(in: .reading)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "swift-book-chapter-3")
    }
    
    func testUnknownIDThrowsError() throws {
        let item = try StudyItem(
            id: "swift-closures",
            title: "Practice Swift Closures",
            estimatedMinutes: 35,
            category: .practice
        )
        
        var plan = try StudyPlan(items: [item])
        
        XCTAssertThrowsError(
            try plan.markCompleted(id: "swift-generics")
        ) { error in
            XCTAssertEqual(error as? StudyPlanError, .unknownID("swift-generics"))
        }
    }
    
    func testMarkCompletedCanBeCalledTwice() throws {
        let item = try StudyItem(
            id: "swift-memory-management",
            title: "Read About ARC in Swift",
            estimatedMinutes: 45,
            category: .reading
        )
        
        var plan = try StudyPlan(items: [item])
        
        try plan.markCompleted(id: "swift-memory-management")
        try plan.markCompleted(id: "swift-memory-management")
        
        XCTAssertTrue(plan.items[0].isCompleted)
        XCTAssertEqual(plan.incompleteMinutes(), 0)
    }
    
    func testDecodingRejectsBlankTitle() {
        let json = """
        [
          {
            "id": "swift-concurrency-reading",
            "title": "   ",
            "estimatedMinutes": 35,
            "category": "reading",
            "isCompleted": false
          }
        ]
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(
            try StudyPlan.decode(from: json)
        ) { error in
            XCTAssertEqual(error as? StudyPlanError, .blankTitle)
        }
    }
    
    func testDecodeTopLevelArray() throws {
        let json = """
        [
          {
            "id": "swift-error-handling",
            "title": "Read About Error Handling in Swift",
            "estimatedMinutes": 30,
            "category": "reading",
            "isCompleted": false
          }
        ]
        """.data(using: .utf8)!
        
        let plan = try StudyPlan.decode(from: json)
        
        XCTAssertEqual(plan.items.count, 1)
        XCTAssertEqual(plan.items[0].title, "Read About Error Handling in Swift")
    }
    
    func testItemsAreSortedByTitleThenID() throws {
        let first = try StudyItem(
            id: "swift-basics-2",
            title: "Read Swift Basics",
            estimatedMinutes: 35,
            category: .reading
        )
        
        let second = try StudyItem(
            id: "algorithms-intro",
            title: "Learn Algorithms",
            estimatedMinutes: 50,
            category: .reading
        )
        
        let third = try StudyItem(
            id: "swift-basics-1",
            title: "Read Swift Basics",
            estimatedMinutes: 40,
            category: .reading
        )
        
        let plan = try StudyPlan(items: [first, second, third])
        
        XCTAssertEqual(
            plan.items.map(\.id),
            ["algorithms-intro", "swift-basics-1", "swift-basics-2"]
        )
    }
    
    func testKeyedStudyPlanDecodingRejectsDuplicateIDs() {
        let json = """
        {
          "items": [
            {
              "id": "swift-basics",
              "title": "Read Swift Basics",
              "estimatedMinutes": 45,
              "category": "reading",
              "isCompleted": false
            },
            {
              "id": "swift-basics",
              "title": "Practice Swift Syntax",
              "estimatedMinutes": 60,
              "category": "practice",
              "isCompleted": false
            }
          ]
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(
            try JSONDecoder().decode(StudyPlan.self, from: json)
        ) { error in
            XCTAssertEqual(
                error as? StudyPlanError,
                .duplicateID("swift-basics")
            )
        }
    }
    
    
    func testImportMergingReplacesExistingItem() throws {
        let existingItem = try StudyItem(
            id: "swift-basics",
            title: "Read Swift Basics",
            estimatedMinutes: 45,
            category: .reading
        )
        
        var plan = try StudyPlan(items: [existingItem])
        
        let updatedItem = try StudyItem(
            id: "swift-basics",
            title: "Practice Swift Basics",
            estimatedMinutes: 60,
            category: .practice
        )
        
        try plan.importMerging([updatedItem])
        
        XCTAssertEqual(plan.items.count, 1)
        XCTAssertEqual(plan.items[0].id, "swift-basics")
        XCTAssertEqual(plan.items[0].title, "Practice Swift Basics")
        XCTAssertEqual(plan.items[0].estimatedMinutes, 60)
        XCTAssertEqual(plan.items[0].category, .practice)
    }
    
    
    func testImportMergingAddsNewItemsSortedByID() throws {
        let existingItem = try StudyItem(
            id: "swift-basics",
            title: "Read Swift Basics",
            estimatedMinutes: 45,
            category: .reading
        )
        
        var plan = try StudyPlan(items: [existingItem])
        
        let projectItem = try StudyItem(
            id: "swift-project",
            title: "Build a Swift Mini Project",
            estimatedMinutes: 90,
            category: .project
        )
        
        let practiceItem = try StudyItem(
            id: "swift-optionals",
            title: "Practice Swift Optionals",
            estimatedMinutes: 50,
            category: .practice
        )
        
        try plan.importMerging([projectItem, practiceItem])
        
        XCTAssertEqual(
            plan.items.map(\.id),
            ["swift-basics", "swift-optionals", "swift-project"]
        )
    }
    
    
    func testImportMergingRejectsDuplicateImportedIDs() throws {
        let existingItem = try StudyItem(
            id: "swift-basics",
            title: "Read Swift Basics",
            estimatedMinutes: 45,
            category: .reading
        )
        
        var plan = try StudyPlan(items: [existingItem])
        
        let firstImportedItem = try StudyItem(
            id: "swift-generics",
            title: "Read About Swift Generics",
            estimatedMinutes: 40,
            category: .reading
        )
        
        let secondImportedItem = try StudyItem(
            id: "swift-generics",
            title: "Practice Swift Generics",
            estimatedMinutes: 55,
            category: .practice
        )
        
        XCTAssertThrowsError(
            try plan.importMerging([firstImportedItem, secondImportedItem])
        ) { error in
            XCTAssertEqual(
                error as? StudyPlanError,
                .duplicateID("swift-generics")
            )
        }
    }
}
