import Collections

public struct Graph <Node> where Node: Hashable {

    public struct Row {
        public var node: Node
        public var currentLane: Int
        public var lanes: [Int]
        public var exits: [Exit] // Will be populated after initial row generation
        public var debugLabel: String?
    }

    public struct Edge {
        public var child: Node
        public var parent: Node
    }

    public struct Exit {
        public var childLane: Int
        public var parentLane: Int
    }

    public private(set) var adjacency: [(node: Node, parents: [Node])]
    public private(set) var rows: [Row]
    public private(set) var laneCount: Int

    public init(adjacency: [(node: Node, parents: [Node])]) {
        self.adjacency = adjacency
        self.rows = Self.rows(for: adjacency)
        laneCount = rows.isEmpty ? 0 : (rows.map({ $0.lanes.last ?? 0 }).max() ?? 0) + 1
    }

    public init() {
        self.adjacency = []
        self.rows = []
        self.laneCount = 0
    }

    static func rows(for adjacency: [(node: Node, parents: [Node])]) -> [Row] {

        var lanes = LanePool<Node>()
        var currentEdges = OrderedSet<Edge>()

        let rows = adjacency.map { (node, parents) -> Row in
            for edge in currentEdges where edge.parent == node {
                if lanes.lane(for: edge.child) != nil {
                    lanes.freeLane(for: edge.child)
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
                Edge(child: node, parent: $0)
            }
            currentEdges.formUnion(edges)
            currentEdges.removeAll(where: { $0.parent == node })

            let exits = currentEdges.map { edge in
                let childLane = lanes.allLanesByKey[edge.child] ?? -1
                let parentLane = lanes.allLanesByKey[edge.parent] ?? -1
                return Exit(childLane: childLane, parentLane: parentLane)
            }
            return Row(node: node, currentLane: lane, lanes: lanes.lanes, exits: exits, debugLabel: "\(edges)")
        }
        return rows
    }
}

extension Graph.Edge: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(child)->\(parent)"
    }
}

extension Graph.Edge: Hashable {
}

extension Graph.Exit: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(childLane)->\(parentLane)"
    }
}

extension Graph.Row: Identifiable {
    public var id: Node {
        node
    }
}
