import JudoSupport

@main
struct JudoSupportPlayground {
    static func main() async throws {

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
        for row in graph.rows {
            print(row)
        }
        graph.prettyPrint(debug: true)
    }
}

// ○    N0  0
// │ ○  N1  1
// ├─╯
// ○    N2  0
// ├─╮
// │ ○  N3  1
// │ ○  N4  1
// ○ │  N5  0
// ○ │  N6  0
// ├─╯
// ○    N7  0

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
