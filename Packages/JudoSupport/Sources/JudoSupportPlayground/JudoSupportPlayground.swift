import JudoSupport

@main
struct JudoSupportPlayground {

    static func complex() {
        /*
        | Graph | ID | Lane | Lanes | Exits      | Debug Label      |
        | ○     | N0 | 0    | 0     | 0->0       | [N0->N2]         |
        | │     |    |      |       |            |                  |
        | │ ○   | N1 | 1    | 0, 1  | 0->0, 1->0 | [N1->N2]         |
        | ├─╯   |    |      |       |            |                  |
        | ○     | N2 | 0    | 0     | 0->0       | [N2->N3, N2->N5] |
        | ├─╮   |    |      |       |            |                  |
        | ○ │   | N3 | 0    | 0, 1  | 0->0, 1->1 | [N3->N4]         |
        | │ |   |    |      |       |            |                  |
        | ○ │   | N4 | 0    | 0, 1  | 0->0, 1->1 | [N4->N7]         |
        | │ │   |    |      |       |            |                  |
        | │ ○   | N5 | 1    | 0, 1  | 0->0, 1->1 | [N5->N6]         |
        | │ │   |    |      |       |            |                  |
        | │ ○   | N6 | 1    | 0, 1  | 0->0, 1->0 | [N6->N7]         |
        | ├─╯   |    |      |       |            |                  |
        | ○     | N7 | 0    | 0     |            | []               |
        |       |    |      |       |            |                  |
        */
        let changes = [
            ("N0", ["N2"]),
            ("N1", ["N2"]),
            ("N2", ["N3", "N5"]),
            ("N3", ["N4"]),
            ("N4", ["N7"]),
            ("N5", ["N6"]),
            ("N6", ["N7"]),
            ("N7", []),
        ]
        let graph = Graph(adjacency: changes)
        graph.prettyPrint(debug: true)
    }

    static func simple1() {
        /*
        | Graph | ID | Lane | Lanes | Exits      | Debug Label      |
        | ○     | N0 | 0    | 0     | 0->0, 0->1 | [N0->N1, N0->N2] |
        | ├─╮   |    |      |       |            |                  |
        | ○ │   | N1 | 0    | 0, 1  | 1->1       | []               |
        |   │   |    |      |       |            |                  |
        |   ○   | N2 | 1    | 1     |            | []               |
        |       |    |      |       |            |                  |

        | Graph | ID | Lane | Lanes | Exits      | Debug Label      |
        | ○     | N0 | 0    | 0     | 0->0, 0->1 | [N0->N1, N0->N2] |
        | ├─╮   |    |      |       |            |                  |
        | ○     | N1 | 0    | 0     | 0->1       | []               |
        | ╰─╮   |    |      |       |            |                  |
        |   ○   | N2 | 1    | 1     |            | []               |
        |       |    |      |       |            |                  |
        */
        let changes = [
            ("N0", ["N1", "N2"]),
            ("N1", []),
            ("N2", []),
        ]
        let graph = Graph(adjacency: changes)
        graph.prettyPrint(debug: true)
    }


    static func simple2() {
        let changes = [
            ("N0", ["N1"]),        // Linear start
            ("N1", ["N2", "N3"]),  // Fork: N1 branches to N2 and N3
            ("N2", ["N4"]),        // N2 continues to N4
            ("N3", ["N4"]),        // N3 also goes to N4 (rejoin)
            ("N4", ["N5"]),        // Continue after rejoin
            ("N5", []),            // End
        ]
        let graph = Graph(adjacency: changes)
        graph.prettyPrint()
    }


    static func main() {
        simple2()
    }
}
