//
//  GraphTests.swift
//  JudoSupport
//
//  Created by Jonathan Wight on 6/6/25.
//


//

@testable import JudoSupport
import Testing

struct GraphTests {

    @Test func testGraph() async throws {
        let changes: [(change_id: ChangeID, parents: [ChangeID])] = [
            (change_id: "vvnt", parents: ["vlny"]),
            (change_id: "vlny", parents: ["zzzz"]),
            (change_id: "qxqz", parents: ["pxpm"]),
            (change_id: "pxpm", parents: ["zzzz"]),
            (change_id: "zzzz", parents: [])
        ]

        let rows = makeGraphRows(changes: changes)
        #expect(rows.count == 5)

        #expect(rows[0].changeID == "vvnt")
        #expect(rows[0].activeLane == LaneID(id: 0))
        #expect(rows[0].nextLanes == [LaneID(id: 0): "vlny"])

        #expect(rows[1].changeID == "vlny")
        #expect(rows[1].activeLane == LaneID(id: 0))
        #expect(rows[1].nextLanes == [LaneID(id: 0): "zzzz"])

        #expect(rows[2].changeID == "qxqz")
        #expect(rows[2].activeLane == LaneID(id: 1))
        #expect(rows[2].nextLanes == [LaneID(id: 0): "zzzz", LaneID(id: 1): "pxpm"])

        #expect(rows[3].changeID == "pxpm")
        #expect(rows[3].activeLane == LaneID(id: 1))
        #expect(rows[3].nextLanes == [LaneID(id: 0): "zzzz", LaneID(id: 1): "zzzz"])

        #expect(rows[4].changeID == "zzzz")
        #expect(rows[4].activeLane == LaneID(id: 0))
        #expect(rows[4].nextLanes == [:])

    }
}

