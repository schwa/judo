import Testing
import Collections
@testable import JudoSupport

@Suite
struct GraphTests {

    @Test
    func testEmptyGraph() {
        let changes: [(String, [String])] = []
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.isEmpty)
        #expect(graph.laneCount == 0)
    }

    @Test
    func testSingleNode() {
        let changes: [(String, [String])] = [
            ("N0", []),
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 1)
        #expect(graph.laneCount == 1)

        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: []))
    }

    @Test
    func testTwoDisconnectedNodes() {
        let changes: [(String, [String])] = [
            ("N0", []),
            ("N1", []),
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 2)
        #expect(graph.laneCount == 1)

        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: []))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0], exits: []))
    }

    @Test
    func testLinearChain() {
        let changes = [
            ("N0", ["N1"]),
            ("N1", ["N2"]),
            ("N2", []),
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 3)
        #expect(graph.laneCount == 1)

        // Compare whole rows
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 0, lanes: [0], exits: []))
    }

    @Test
    func testSimpleMerge() {
        let changes = [
            ("N0", ["N2"]),
            ("N1", ["N2"]),
            ("N2", []),
        ]
        let graph = Graph(adjacency: changes)

        // Verify we have 3 rows
        #expect(graph.rows.count == 3)
        #expect(graph.laneCount == 2)

        // Compare whole rows
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 1, lanes: [0, 1], exits: [[0, 0], [1, 0]]))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 0, lanes: [0], exits: []))
    }

    @Test
    func testSimpleBranch() {
        let changes = [
            ("N0", ["N1", "N2"]),
            ("N1", []),
            ("N2", []),
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 3)
        #expect(graph.laneCount == 2) // Should need 2 lanes for the branch

        // Expected behavior: N0 branches, N1 stays on lane 0, N2 moves to lane 1
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0], [0, 1]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0, 1], exits: [[1, 1]]))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 1, lanes: [1], exits: []))
    }

    @Test
    func testDiamondStructure() {
        let changes = [
            ("N0", ["N1", "N2"]),  // N0 branches to N1 and N2
            ("N1", ["N3"]),        // N1 flows to N3
            ("N2", ["N3"]),        // N2 flows to N3 (merge)
            ("N3", []),            // N3 is terminal
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 4)
        #expect(graph.laneCount == 2) // Should need 2 lanes for the branch/merge

        // Expected behavior: N0 branches (N1 lane 0, N2 lane 1), then both merge into N3 on lane 0
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0], [0, 1]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0, 1], exits: [[1, 1], [0, 0]]))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 1, lanes: [0, 1], exits: [[0, 0], [1, 0]]))
        #expect(graph.rows[3] == Graph.Row(node: "N3", currentLane: 0, lanes: [0], exits: []))
    }

    @Test(.disabled("Current implementation doesn't handle branching - all children end up on same lane"))
    func testComplexBranching() {
        let changes = [
            ("N0", ["N1", "N2", "N3"]),
            ("N1", []),
            ("N2", []),
            ("N3", []),
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 4)
        #expect(graph.laneCount == 3) // Should need 3 lanes for the triple branch

        // Expected behavior: N0 branches to three children on separate lanes
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0], [0, 1], [0, 2]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0, 1, 2], exits: [[1, 1], [2, 2]]))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 1, lanes: [1, 2], exits: [[2, 2]]))
        #expect(graph.rows[3] == Graph.Row(node: "N3", currentLane: 2, lanes: [2], exits: []))
    }

    @Test
    func testMultipleDisconnectedComponents() {
        let changes = [
            ("N0", ["N1"]),  // First component: N0 -> N1
            ("N1", []),
            ("N2", ["N3"]),  // Second component: N2 -> N3
            ("N3", []),
        ]
        let graph = Graph(adjacency: changes)

        #expect(graph.rows.count == 4)
        #expect(graph.laneCount == 1) // Should reuse lane 0 for both components

        // Expected behavior: both components use lane 0 independently
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0], exits: []))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[3] == Graph.Row(node: "N3", currentLane: 0, lanes: [0], exits: []))
    }

    @Test
    func testForkAndRejoin() {
        let changes = [
            ("N0", ["N1"]),        // Linear start
            ("N1", ["N2", "N3"]),  // Fork: N1 branches to N2 and N3
            ("N2", ["N4"]),        // N2 continues to N4
            ("N3", ["N4"]),        // N3 also goes to N4 (rejoin)
            ("N4", ["N5"]),        // Continue after rejoin
            ("N5", []),            // End
        ]
        let graph = Graph(adjacency: changes)
        #expect(graph.rows.count == 6)
        #expect(graph.laneCount == 2) // Should need 2 lanes for the fork

        // Expected behavior: fork at N1, rejoin at N4, continue on lane 0
        #expect(graph.rows[0] == Graph.Row(node: "N0", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[1] == Graph.Row(node: "N1", currentLane: 0, lanes: [0], exits: [[0, 0], [0, 1]]))
        #expect(graph.rows[2] == Graph.Row(node: "N2", currentLane: 0, lanes: [0, 1], exits: [[1, 1], [0, 0]]))
        #expect(graph.rows[3] == Graph.Row(node: "N3", currentLane: 1, lanes: [0, 1], exits: [[0, 0], [1, 0]]))
        #expect(graph.rows[4] == Graph.Row(node: "N4", currentLane: 0, lanes: [0], exits: [[0, 0]]))
        #expect(graph.rows[5] == Graph.Row(node: "N5", currentLane: 0, lanes: [0], exits: []))
    }
}

// MARK: -

extension Graph.Edge: ExpressibleByArrayLiteral where Node == String {
    public init(arrayLiteral elements: String...) {
        guard elements.count == 2 else {
            fatalError("Edge array literal must have exactly 2 elements: [child, parent]")
        }
        self.init(child: elements[0], parent: elements[1])
    }
}

extension Graph.Intersection: Equatable {
    public static func == (lhs: Graph.Intersection, rhs: Graph.Intersection) -> Bool {
        return lhs.childLane == rhs.childLane && lhs.parentLane == rhs.parentLane
    }
}

extension Graph.Intersection: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        guard elements.count == 2 else {
            fatalError("Exit array literal must have exactly 2 elements: [childLane, parentLane]")
        }
        self.init(childLane: elements[0], parentLane: elements[1])
    }
}

extension Graph.Row: Equatable where Node: Equatable {
    public static func == (lhs: Graph.Row, rhs: Graph.Row) -> Bool {
        return lhs.node == rhs.node
            && lhs.currentLane == rhs.currentLane
            && lhs.lanes == rhs.lanes
            && lhs.entrances == rhs.entrance
            && lhs.exits == rhs.exits
    }
}
