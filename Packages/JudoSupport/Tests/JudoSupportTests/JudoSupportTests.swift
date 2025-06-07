import Testing
@testable import JudoSupport

struct JujutsuIDTests {
    @Test func testIDInitialization() throws {
        let rawValue = "12345678"
        let jujutsuID = JujutsuID(rawValue: rawValue)
        #expect(jujutsuID?.rawValue == rawValue)
//        #expect(jujutsuID?.shortestPrefixCount == nil)
    }

    @Test func testIDEquality() throws {
        let id1 = JujutsuID(rawValue: "12345678")
        let id2 = JujutsuID(rawValue: "12345678", shortest: "12")
        let id3 = JujutsuID(rawValue: "12345678", shortest: "12345")
        #expect(id1 == id2)
        #expect(id1 == id3)
        #expect(id2 == id3)
    }

    @Test func testIDShortMethod() throws {
        let rawValue = "1234567890"
        let jujutsuID = JujutsuID(rawValue: rawValue)
        #expect(jujutsuID?.short(4) == "1234")
        #expect(jujutsuID?.short(8) == "12345678")
    }

    @Test func testIDShortestMethod() throws {
        let rawValue = "1234567890"
        let jujutsuID = JujutsuID(rawValue: rawValue, shortest: "1234")
        #expect(jujutsuID.shortest() == "1234")
    }
}
