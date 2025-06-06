import Collections

extension Dictionary {
    init(_ orderedDictionary: OrderedDictionary<Key, Value>) {
        self.init(uniqueKeysWithValues: Array(orderedDictionary))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
