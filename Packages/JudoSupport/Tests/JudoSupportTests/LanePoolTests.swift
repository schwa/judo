@testable import JudoSupport
import Testing

@Suite
struct LanePoolTests {
    @Test func test1() {
        var lanes = LanePool<String>()
        #expect(lanes.isEmpty)
        #expect(lanes.isValid())

        let lane = lanes.allocateLane(for: "A")
        #expect(lane == 0)
        #expect(lanes.isValid())
        lanes.freeLane(for: "A")
        #expect(lanes.isValid())

        let lane2 = lanes.allocateLane(for: "B")
        #expect(lane2 == 0)
        #expect(lanes.isValid())

        lanes.add("C", to: lane2)

        let lane3 = lanes.lane(for: "C")
        #expect(lane3 == lane2)
        #expect(lanes.isValid())

        lanes.add("C", to: lane2)
        #expect(lanes.isValid())

        let lane4 = lanes.allocateLane(for: "D")
        #expect(lane4 == 1)

        #expect(lanes.lanesByKey == ["B": 0, "C": 0, "D": 1])
    }
}
