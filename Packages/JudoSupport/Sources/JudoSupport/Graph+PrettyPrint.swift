//
//  Graph+PrettyPrint.swift
//  JudoSupport
//
//  Created by Jonathan Wight on 6/13/25.
//


public extension Graph {
    func prettyPrint(debug: Bool = false) {
        let laneCount = (rows.map({ $0.lanes.last ?? 0 }).max() ?? 0) + 1
        let rows = rows.flatMap { row -> [[String]] in
            var row0: [String] = []
            var characters = Array(repeating: Character(" "), count: laneCount * 2 - 1)
            for lane in row.lanes {
                characters[lane * 2] = "│"
            }
            characters[row.currentLane * 2] = "○"

            row0 = [String(characters), String(describing: row.node)]
            if debug {
                let lanes = row.lanes.map { "\($0)" }.joined(separator: ", ")
                let exits = row.exits.map { "\($0)" }.joined(separator: ", ")
                row0.append(contentsOf: ["\(row.currentLane)", "\(lanes)", "\(exits)", "\(row.debugLabel ?? "")"])
            }
            characters = Array(repeating: Character(" "), count: laneCount * 2 - 1)
            for exit in row.exits {
                let source = exit.childLane * 2
                let destination = exit.parentLane * 2
                if source == destination {
                    characters[destination] = characters[destination].boxMerge(with: "│")
                }
                else if destination > source {
                    characters[source] = characters[source].boxMerge(with: "╰")
                    for n in stride(from: source + 1, through: destination - 1, by: 1) {
                        characters[n] = "─"
                    }
                    characters[destination] = characters[destination].boxMerge(with: "╮")
                }
                else {
                    characters[source] = characters[source].boxMerge(with: "╯")
                    for n in stride(from: source - 1, through: destination + 1, by: -1) {
                        characters[n] = "─"
                    }
                    characters[destination] = characters[destination].boxMerge(with: "╭")
                }
            }
            let row1 = ([String(characters)])
            return [row0] + [row1]
        }

        printTable([["Graph", "Node", "Lane", "Lanes", "Exits", "Debug Label"]] + rows)
    }
}
