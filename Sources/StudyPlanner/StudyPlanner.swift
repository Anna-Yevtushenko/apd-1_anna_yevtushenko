import Foundation

public enum StudyCategory: String, Codable, CaseIterable {
    case reading, practice, project
}

public enum StudyPlanError: Error, Equatable {
    case blankTitle
    case nonPositiveEstimatedMinutes
    case duplicateID(String)
    case unknownID(String)
}

public struct StudyItem: Codable, Equatable {
    public let id: String
    public let title: String
    public let estimatedMinutes: Int
    public let category: StudyCategory
    public private(set) var isCompleted: Bool
    
    public init(
        id: String,
        title: String,
        estimatedMinutes: Int,
        category: StudyCategory,
        isCompleted: Bool = false
    ) throws {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedTitle.isEmpty else {
            throw StudyPlanError.blankTitle
        }
        
        guard estimatedMinutes > 0 else {
            throw StudyPlanError.nonPositiveEstimatedMinutes
        }
        
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.isCompleted = isCompleted
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case estimatedMinutes
        case category
        case isCompleted
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        let category = try container.decode(StudyCategory.self, forKey: .category)
        let isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        
        try self.init(
            id: id,
            title: title,
            estimatedMinutes: estimatedMinutes,
            category: category,
            isCompleted: isCompleted
        )
    }
}

public struct StudyPlan: Codable, Equatable {
    public private(set) var items: [StudyItem]
    
    private enum CodingKeys: String, CodingKey {
        case items
    }
    
    private static func isOrderedBefore(_ first: StudyItem, _ second: StudyItem) -> Bool {
        if first.title == second.title {
            return first.id < second.id
        }
        
        return first.title < second.title
    }
    
    
    private static func validateUniqueIDs(in items: [StudyItem]) throws {
        var existingIDs = Set<String>()
        
        for item in items {
            if existingIDs.contains(item.id) {
                throw StudyPlanError.duplicateID(item.id)
            }
            
            existingIDs.insert(item.id)
        }
    }
    
    
    public init(items: [StudyItem]) throws {
        try Self.validateUniqueIDs(in: items)
        
        self.items = items.sorted(by: Self.isOrderedBefore)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedItems = try container.decode([StudyItem].self, forKey: .items)
        
        try self.init(items: decodedItems)
    }
    
    
    public static func decode(from data: Data) throws -> StudyPlan {
        let decoder = JSONDecoder()
        let decodedItems = try decoder.decode([StudyItem].self, from: data)
        return try StudyPlan(items: decodedItems)
    }
    
    public func items(in category: StudyCategory) -> [StudyItem] {
        items.filter { $0.category == category }
    }
    
    public func incompleteMinutes() -> Int {
        items
            .filter { !$0.isCompleted }
            .reduce(0) { $0 + $1.estimatedMinutes }
    }
    
    public mutating func markCompleted(id: String) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw StudyPlanError.unknownID(id)
        }
        
        let item = items[index]
        
        items[index] = try StudyItem(
            id: item.id,
            title: item.title,
            estimatedMinutes: item.estimatedMinutes,
            category: item.category,
            isCompleted: true
        )
    }
    
    public mutating func importMerging(_ importedItems: [StudyItem]) throws {
        try Self.validateUniqueIDs(in: importedItems)
        
        var updatedItems = items
        var newItems: [StudyItem] = []
        
        for importedItem in importedItems {
            if let index = updatedItems.firstIndex(where: { $0.id == importedItem.id }) {
                updatedItems[index] = importedItem
            } else {
                newItems.append(importedItem)
            }
        }
        
        newItems.sort { $0.id < $1.id }
        updatedItems.append(contentsOf: newItems)
        
        self.items = updatedItems
    }
    
}
