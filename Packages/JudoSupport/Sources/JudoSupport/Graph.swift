import Collections

public struct Graph <Node> where Node: Hashable {

    public struct Row {
        public var node: Node
        public var currentLane: Int
        public var lanes: [Int]
        public var entrances: [Intersection]
        public var exits: [Intersection] // Will be populated after initial row generation
        public var debugLabel: String?
    }

    public struct Edge {
        public var source: Node
        public var destination: Node
    }

    public struct Intersection {
        public var source: Int
        public var destination: Int
    }

    public private(set) var adjacency: [(node: Node, parents: [Node])]
    public private(set) var rows: [Row]
    public private(set) var laneCount: Int

    public init(adjacency: [(node: Node, parents: [Node])]) {
        self.adjacency = adjacency
        self.rows = Self.rows(for: adjacency)
        laneCount = rows.isEmpty ? 0 : (rows.map({ $0.lanes.last ?? 0 }).max() ?? 0) + 1
    }

    static func rows(for adjacency: [(node: Node, parents: [Node])]) -> [Row] {
        var lanes = LanePool<Node>()
        var currentEdges = OrderedSet<Edge>()

        var lastExits: [Intersection] = []

        let rows = adjacency.map { (node, parents) -> Row in
            for edge in currentEdges where edge.destination == node {
                if lanes.lane(for: edge.source) != nil {
                    lanes.freeLane(for: edge.source)
                }
            }

            let lane = lanes.allocateLane(for: node)

            if let (firstParent, remainingParents) = parents.uncons() {
                if lanes.lane(for: firstParent) == nil {
                    lanes.add(firstParent, to: lane)
                }
                else {
                    lanes.allocateLane(for: firstParent)
                }
                remainingParents.forEach { parent in
                    lanes.allocateLane(for: parent)
                }
            }

            // Form edges from current node to its parents
            let edges = parents.map {
                Edge(source: node, destination: $0)
            }
            currentEdges.formUnion(edges)
            currentEdges.removeAll(where: { $0.destination == node })

            // Form exits...
            let exits = currentEdges.map { edge in
                let childLane = node == edge.source ? lanes.allLanesByKey[edge.source] ?? -1 : lanes.allLanesByKey[edge.destination] ?? -1
                let parentLane = lanes.allLanesByKey[edge.destination] ?? -1
                return Intersection(source: childLane, destination: parentLane)
            }

            // Use lastExits & our exits to compute entrances.
            var entrances: [Intersection] = []

            for exit in Set(lastExits.map(\.destination)) {
                // Find an entrance that matches the exit's parent lane
                if let entrance = exits.first(where: { $0.source == exit }) {
                    entrances.append(.init(source: exit, destination: entrance.source))
                }
                else if exit == lane {
                    entrances.append(.init(source: exit, destination: lane))
                }
                else {
                    // Unreachable.
                    fatalError()
                }
            }
            let lanes_ = Set([lane] + exits.flatMap { [$0.source] }).sorted()
            lanes.freeLane(for: node)
            lastExits = exits

            return Row(node: node, currentLane: lane, lanes: lanes_, entrances: entrances.sorted(), exits: exits.sorted(), debugLabel: "[\(lane)]: \(currentEdges)")
        }
        return rows
    }
}

extension Graph.Edge: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(source)->\(destination)"
    }
}

extension Graph.Edge: Hashable {
}

extension Graph.Intersection: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(source)->\(destination)"
    }
}

extension Graph.Row: Identifiable {
    public var id: Node {
        node
    }
}

extension Graph.Intersection: Comparable {
    public static func < (lhs: Graph.Intersection, rhs: Graph.Intersection) -> Bool {
        if lhs.source == rhs.source {
            return lhs.destination < rhs.destination
        }
        return lhs.source < rhs.source
    }
}
