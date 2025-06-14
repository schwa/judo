import Collections

internal struct LanePool<Key: Hashable> {
    private var freeLanes: [Int] = []
    private var nextLane: Int = 0
    internal private(set) var lanesByKey: [Key: Int] = [:]
    private var keysByLane: [Int: Set<Key>] = [:]

    internal private(set) var allLanesByKey: [Key: Int] = [:]

    internal init() {
    }

    internal var isEmpty: Bool {
        lanesByKey.isEmpty
    }

    internal func isValid() -> Bool {
        // Ensure that all lanes are valid and keys are correctly assigned
        for (key, lane) in lanesByKey {
            guard keysByLane[lane]?.contains(key) == true else {
                print("Invalid lane assignment for key \(key): assigned to lane \(lane) but not found in keysByLane.")
                return false
            }
        }
        // Ensure that all lanes are accounted for in keysByLane
        for (lane, keys) in keysByLane {
            guard !keys.isEmpty else {
                print("Lane \(lane) is empty in keysByLane, but has keys assigned in lanesByKey.")
                return false
            }
            for key in keys {
                guard lanesByKey[key] == lane else {
                    print("Key \(key) is assigned to lane \(lane) in keysByLane, but found in lanesByKey with a different lane.")
                    return false
                }
            }
        }
        // Find the largest lane in use
        let maxLane = (keysByLane.keys + freeLanes).max() ?? -1
        // Ensure that the nextLane is correctly set
        guard nextLane == maxLane + 1 else {
            print("Next lane \(nextLane) does not match the maximum lane used \(maxLane + 1).")
            return false
        }
        return true
    }

    internal func lane(for key: Key) -> Int? {
        lanesByKey[key]
    }

    internal func count(for lane: Int) -> Int {
        keysByLane[lane]?.count ?? 0
    }

    internal var lanes: [Int] {
        keysByLane.keys.sorted()
    }

    @discardableResult
    internal mutating func allocateLane(for key: Key) -> Int {
        // Check if the key already has an assigned lane
        if let existingLane = lanesByKey[key] {
            return existingLane
        }
        if freeLanes.isEmpty == false {
            let lane = freeLanes.removeLast()
            lanesByKey[key] = lane
            allLanesByKey[key] = lane
            keysByLane[lane, default: []].insert(key)
            return lane
        }
        let lane = nextLane
        nextLane += 1
        lanesByKey[key] = lane
        allLanesByKey[key] = lane
        keysByLane[lane, default: []].insert(key)
        return lane
    }

    internal mutating func add(_ key: Key, to lane: Int) {
        // Ensure the lane exists in the pool
        guard keysByLane[lane] != nil else {
            fatalError("Attempted to share a lane that does not exist.")
        }
        // Check if the key already has a lane assigned
        if let existingLane = lanesByKey[key] {
            // If the key already has a lane, ensure it matches the provided lane
            guard existingLane == lane else {
                fatalError("Attempted to add a key to a different lane than it is already assigned to.")
            }
            return
        }

        // Associate the key with the lane
        lanesByKey[key] = lane
        allLanesByKey[key] = lane
        keysByLane[lane, default: []].insert(key)
    }

    internal mutating func freeLane(for key: Key) {
        guard let lane = lanesByKey.removeValue(forKey: key) else {
            fatalError("Attempted to release a key that does not have a lane assigned.")
        }
        lanesByKey.removeValue(forKey: key)
        keysByLane[lane]?.remove(key)
        if keysByLane[lane]?.isEmpty ?? true {
            keysByLane.removeValue(forKey: lane)
            freeLanes.append(lane)
        }
    }
}

extension LanePool: CustomDebugStringConvertible {
    var debugDescription: String {
        let keysByLane = keysByLane.map { "\($0.key): \($0.value)" }.joined(separator: ", ")

        return "LanePool(\(keysByLane))"
    }
}
