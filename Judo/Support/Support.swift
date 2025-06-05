import Collections

extension Dictionary {
    init(_ orderedDictionary: OrderedDictionary<Key, Value>) {
        self.init(uniqueKeysWithValues: Array(orderedDictionary))
    }
}

