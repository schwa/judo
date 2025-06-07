public extension RepositoryLog {
    func makeGraphRows() -> [GraphRow] {
        JudoSupport.makeGraphRows(changes: changes.values.map { ($0.changeID, $0.parents) })
    }
}

func makeGraphRows(changes: [(change_id: ChangeID, parents: [ChangeID])]) -> [GraphRow] {
    var nextLaneID = 0
    func makeLaneID() -> LaneID {
        defer {
            nextLaneID += 1
        }
        return LaneID(id: nextLaneID)
    }
    var rows: [GraphRow] = []
    for (index, change) in changes.enumerated() {
        let isAtEnd = index == changes.count - 1
        let lastRow = rows.last
        if let lastRow {
            var nextLanes = lastRow.nextLanes
            let activeLane = nextLanes
                .sorted { $0.key.id < $1.key.id }
                .first(where: { $0.value == change.change_id })?.key ?? makeLaneID()
            if let first = change.parents.first {
                nextLanes[activeLane] = first
                for parent in change.parents.dropFirst() {
                    nextLanes[makeLaneID()] = parent
                }
            }
            if isAtEnd {
                nextLanes.removeAll()
            }
            let row = GraphRow(changeID: change.change_id, activeLane: activeLane, nextLanes: nextLanes)
            rows.append(row)
        }
        else {
            let activeLane = makeLaneID()
            var nextLanes: [LaneID: ChangeID] = [:]
            if let first = change.parents.first {
                nextLanes[activeLane] = first
                for parent in change.parents.dropFirst() {
                    nextLanes[makeLaneID()] = parent
                }
            }
            let row = GraphRow(changeID: change.change_id, activeLane: activeLane, nextLanes: nextLanes)
            rows.append(row)
        }
//        print(">>", rows.last as Any)
    }
    return rows
}


public struct LaneID: Hashable {
    public var id: Int
}

extension LaneID: CustomStringConvertible {
    public var description: String {
        return "L\(id)"
    }
}

public struct GraphRow {
    public var changeID: ChangeID
    public var activeLane: LaneID
    public var nextLanes: [LaneID: ChangeID]
}

extension GraphRow: Identifiable {
    public var id: ChangeID { changeID }
}

extension GraphRow: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "GraphRow(changeID: \(changeID.short(4)), activeLane: \(activeLane), nextLanes: \(nextLanes))"
    }
}
