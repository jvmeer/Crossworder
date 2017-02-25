//
//  CrosswordModel.swift
//  Crossworder
//
//  Created by Jacob Vandermeer on 2/24/17.
//  Copyright © 2017 Jacob Vandermeer. All rights reserved.
//

import Foundation

let maxDimension = 50

class CrosswordModel {
    struct Location: Hashable, CustomStringConvertible {
        let row: Int, column: Int
        
        var upNeighbor: Location { get { return Location(row: row - 1, column: column) } }
        var downNeighbor: Location { get { return Location(row: row + 1, column: column) } }
        var rightNeighbor: Location { get { return Location(row: row, column: column + 1) } }
        var leftNeighbor: Location { get { return Location(row: row, column: column - 1) } }
        
        static func == (lhs: Location, rhs: Location) -> Bool {
            return (lhs.row == rhs.row && lhs.column == rhs.column)
        }
        
        var hashValue: Int {
            return row.hashValue * maxDimension + column.hashValue
        }
        
        var description: String {
            get {
                return "(\(row), \(column))"
            }
        }
    }
    
    enum Orientation {
        case Across
        case Down
    }
    
    struct CellId: Hashable {
        let location: Location
        let orientation: Orientation
        
        static func == (lhs: CellId, rhs: CellId) -> Bool {
            return (lhs.location == rhs.location && lhs.orientation == rhs.orientation)
        }
        
        var hashValue: Int {
            return location.hashValue * (orientation == .Across ? 1 : -1)
        }
    }
    
    enum Direction {
        case Forward
        case Backward
    }
    
    private class Cell: Equatable {
        let cellId: CellId
        let correctLetter: String
        let word: [Location]
        let clue: String
        let clueNumber: Int?
        
        var nextCell: Cell!
        weak var previousCell: Cell!
        weak var startOfNextWord: Cell!
        weak var startOfPreviousWord: Cell!
        
        var currentLetter = ""
        
        init(cellId: CellId, correctLetter: String, word: [Location], clue: String, clueNumber: Int?) {
            self.cellId = cellId
            self.correctLetter = correctLetter
            self.word = word
            self.clue = clue
            self.clueNumber = clueNumber
        }
        
        var isStartOfWord: Bool { get { return cellId.location == word.first } }
        var isEndOfWord: Bool { get { return cellId.location == word.last } }
        
        static func == (lhs: Cell, rhs: Cell) -> Bool {
            return lhs.cellId == rhs.cellId
        }
    }
    
    private class CellDict {
        private var dict = [CellId: Cell]()
        func addCell(cell: Cell) {
            dict[cell.cellId] = cell
        }
        func cellAt(location: Location, currentCell: Cell) -> Cell? {
            if dict[CellId(location: location, orientation: .Across)] == nil && dict[CellId(location: location, orientation: .Down)] == nil {
                return nil
            } else {
                if currentCell.cellId.location == location {
                    let test = dict[CellId(location: location, orientation: .Down)]
                    let x = test
                    return currentCell.cellId.orientation == .Across ? test ?? currentCell : dict[CellId(location: location, orientation: .Across)] ?? currentCell
                } else {
                    return currentCell.cellId.orientation == .Across ? dict[CellId(location: location, orientation: .Across)] ?? dict[CellId(location: location, orientation: .Down)]! : dict[CellId(location: location, orientation: .Down)] ?? dict[CellId(location: location, orientation: .Across)]!
                }
            }
        }
        func clueNumberAt(location: Location) -> Int? {
            var result: Int? = nil
            if let acrossCell = dict[CellId(location: location, orientation: .Across)] {
                if let acrossClueNumber = acrossCell.clueNumber { result = acrossClueNumber }
            }
            if let downCell = dict[CellId(location: location, orientation: .Down)] {
                if let downClueNumber = downCell.clueNumber { result = downClueNumber }
            }
            return result
        }
        func isFull() -> Bool {
            var result = true
            for cell in dict {
                if cell.value.currentLetter == "" { result = false }
            }
            return result
        }
        func isSolved() -> Bool {
            var result = true
            for cell in dict {
                if cell.value.currentLetter != cell.value.correctLetter { result = false }
            }
            return result
        }
    }
    
    let rows: Int, columns: Int
    private var currentCell: Cell!
    private var cellDict: CellDict!
    private var isFull: Bool {
        get {
            return cellDict.isFull()
        }
    }
    var currentLocation: Location {
        get {
            return currentCell.cellId.location
        }
    }
    var currentWord: [Location] {
        get {
            return currentCell.word
        }
    }
    var currentClue: String {
        get {
            return currentCell.clue
        }
    }
    var isSolved: Bool {
        get {
            return cellDict.isSolved()
        }
    }
    
    init(fileName: String) {
        let simpleGrid = CrosswordModel.simpleGrid(fileName: fileName)
        let clueDict = CrosswordModel.clueDict(fileName: fileName)
        (rows, columns) = CrosswordModel.gridDimensions(simpleGrid: simpleGrid)
        cellDict = CellDict()
        buildCells(simpleGrid: simpleGrid, clueDict: clueDict)
    }
    
    private class func simpleGrid(fileName: String) -> [Location: String] {
        var simpleGrid = [Location: String]()
        if let filePath = Bundle.main.path(forResource: fileName, ofType: "csv") {
            do {
                let contents = try String(contentsOfFile: filePath)
                let linesArr = contents.characters.split(separator: "\r\n")
                for row in 0..<linesArr.count {
                    if Int(String(linesArr[row][linesArr[row].startIndex])) == nil {
                        let cellsArr = linesArr[row].split(separator: ",", omittingEmptySubsequences: false).map(String.init)
                        for column in 0..<cellsArr.count {
                            simpleGrid[Location(row: row, column: column)] = cellsArr[column]
                        }
                    }
                }
            } catch {
                fatalError("File not readable")
            }
        } else {
            fatalError("File not found")
        }
        return simpleGrid
    }
    
    private class func clueDict(fileName: String) -> [CellId: String] {
        var clueDict = [CellId: String]()
        if let filePath = Bundle.main.path(forResource: fileName, ofType: "csv") {
            do {
                let contents = try String(contentsOfFile: filePath)
                let linesArr = contents.characters.split(separator: "\r\n")
                for row in linesArr {
                    if Int(String(row[row.startIndex])) != nil {
                        let cellsArr = row.split(separator: ",", maxSplits: 3).map(String.init)
                        let location = Location(row: Int(cellsArr[0])!, column: Int(cellsArr[1])!)
                        let clue = cellsArr[3].substring(to: cellsArr[3].range(of: ",,")!.lowerBound)
                        switch cellsArr[2] {
                        case "A":
                            clueDict[CellId(location: location, orientation: Orientation.Across)] = clue
                        case "D":
                            clueDict[CellId(location: location, orientation: Orientation.Down)] = clue
                        default:
                            fatalError("Invalid clue orientation found")
                        }
                    }
                }
            } catch {
                fatalError("File not readable")
            }
        } else {
            fatalError("File not found")
        }
        return clueDict
    }
    
    private class func gridDimensions(simpleGrid: [Location: String]) -> (Int, Int) {
        var numRows = 0
        var numColumns = 0
        for cell in simpleGrid {
            if cell.key.row + 1 > numRows { numRows += 1 }
            if cell.key.column + 1 > numColumns { numColumns += 1 }
        }
        return (numRows, numColumns)
    }
    
    private func buildCells(simpleGrid: [Location: String], clueDict: [CellId: String]) {
        var head: (across: Cell?, down: Cell?)
        var tail: (across: Cell?, down: Cell?)
        var clueCounter = 0
        for row in 0..<rows {
            for column in 0..<columns {
                let letter = simpleGrid[Location(row: row, column: column)]!
                if letter != "" {
                    let location = Location(row: row, column: column)
                    let atBeginningOfAcrossWord = letterAt(location: location.leftNeighbor, simpleGrid: simpleGrid, rows: rows, columns: columns) == "" && letterAt(location: location.rightNeighbor, simpleGrid: simpleGrid, rows: rows, columns: columns) != ""
                    let atBeginningOfDownWord = letterAt(location: location.upNeighbor, simpleGrid: simpleGrid, rows: rows, columns: columns) == "" && letterAt(location: location.downNeighbor, simpleGrid: simpleGrid, rows: rows, columns: columns) != ""
                    
                    if atBeginningOfAcrossWord || atBeginningOfDownWord {
                        clueCounter += 1
                    }

                    if atBeginningOfAcrossWord {
                        addLettersInWord(startCellId: CellId(location: location, orientation: .Across), simpleGrid: simpleGrid, clueDict: clueDict, clueNumber: clueCounter, head: &head, tail: &tail)
                    }
                    if atBeginningOfDownWord {
                        addLettersInWord(startCellId: CellId(location: location, orientation: .Down), simpleGrid: simpleGrid, clueDict: clueDict, clueNumber: clueCounter, head: &head, tail: &tail)
                    }
                }
            }
        }
        head.across!.previousCell = tail.down
        head.down!.previousCell = tail.across
        tail.across!.nextCell = head.down
        tail.down!.nextCell = head.across
        currentCell = head.across
        
        linkWordStarts()
    }
    
    private func letterAt(location: Location, simpleGrid: [Location: String], rows: Int, columns: Int) -> String {
        if location.row < 0 || location.column < 0 || location.row >= rows || location.column >= columns {
            return ""
        } else {
            return simpleGrid[location]!
        }
    }
    
    private func addLettersInWord(startCellId: CellId, simpleGrid: [Location: String], clueDict: [CellId: String], clueNumber: Int, head: inout (across: Cell?, down: Cell?), tail: inout (across: Cell?, down: Cell?)) {
        let word = self.word(startCellId: startCellId, simpleGrid: simpleGrid)
        for location in word {
            let cell = Cell(cellId: CellId(location: location, orientation: startCellId.orientation), correctLetter: simpleGrid[location]!, word: word, clue: clueDict[startCellId]!, clueNumber: location == startCellId.location ? clueNumber : nil)
            addCell(cell: cell, head: &head, tail: &tail)
        }
    }
    
    private func word(startCellId: CellId, simpleGrid: [Location: String]) -> [Location] {
        var word = [Location]()
        var locationCursor = startCellId.location
        while true {
            word.append(locationCursor)
            if startCellId.orientation == .Across ? letterAt(location: locationCursor.rightNeighbor, simpleGrid: simpleGrid, rows: rows, columns: columns) == "" : letterAt(location: locationCursor.downNeighbor, simpleGrid: simpleGrid, rows: rows, columns: columns) == "" {
                break
            } else {
                locationCursor = startCellId.orientation == .Across ? locationCursor.rightNeighbor : locationCursor.downNeighbor
            }
        }
        return word
    }
    
    private func addCell(cell: Cell, head: inout (across: Cell?, down: Cell?), tail: inout (across: Cell?, down: Cell?)) {
        if let tail = cell.cellId.orientation == .Across ? tail.across : tail.down {
            cell.previousCell = tail
            tail.nextCell = cell
        } else {
            cell.cellId.orientation == .Across ? (head.across = cell) : (head.down = cell)
        }
        cell.cellId.orientation == .Across ? (tail.across = cell) : (tail.down = cell)
        cellDict.addCell(cell: cell)
    }
    
    private func linkWordStarts() {
        var outerCellCursor = currentCell!
        while true {
            if outerCellCursor.nextCell! == currentCell { break }
            var nextWordCellCursor = outerCellCursor.nextCell!
            var previousWordCellCursor = outerCellCursor.previousCell!
            while !nextWordCellCursor.isStartOfWord {
                nextWordCellCursor = nextWordCellCursor.nextCell
            }
            while !previousWordCellCursor.isStartOfWord || outerCellCursor.word.contains(previousWordCellCursor.cellId.location) {
                previousWordCellCursor = previousWordCellCursor.previousCell
            }
            outerCellCursor.startOfNextWord = nextWordCellCursor
            outerCellCursor.startOfPreviousWord = previousWordCellCursor
            outerCellCursor = outerCellCursor.nextCell
        }
    }
    
    private func goToNextCell() {
        currentCell = currentCell.nextCell
    }
    
    private func goToNextBlankCell() {
        while true {
            goToNextCell()
            if currentCell.currentLetter == "" { break }
        }
    }
    
    func enterLetter(letter: String) {
        let oldLetter = currentCell.currentLetter
        currentCell.currentLetter = letter
        cellDict.cellAt(location: currentCell.cellId.location, currentCell: currentCell)?.currentLetter = letter
        if oldLetter == "" || currentCell.isEndOfWord {
            if isFull {
                goToNextCell()
            } else {
                goToNextBlankCell()
            }
        } else {
            goToNextCell()
        }
    }
    
    func deleteLetter(letter: String) {
        let oldLetter = currentCell.currentLetter
        if oldLetter == "" {
            currentCell = currentCell.previousCell
        }
        currentCell.currentLetter = ""
    }
    
    func goToNextClue() {
        currentCell = currentCell.startOfNextWord
        if !isFull {
            while currentCell.currentLetter != "" {
                goToNextCell()
            }
        }
    }
    
    func goToPreviousClue() {
        currentCell = currentCell.startOfPreviousWord
        if !isFull {
            while currentCell.currentLetter != "" {
                if currentCell.isEndOfWord {
                    currentCell = currentCell.startOfPreviousWord
                } else {
                    goToNextCell()
                }
            }
        }
    }
    
    func goToLocation(location: Location) {
        currentCell = cellDict.cellAt(location: location, currentCell: currentCell)
    }
    
    func correctLetterAt(location: Location) -> String? {
        return cellDict.cellAt(location: location, currentCell: currentCell)?.correctLetter
    }
    
    func currentLetter() -> String {
        return currentCell.currentLetter
    }
    
    func clueNumberAt(location: Location) -> Int? {
        return cellDict.clueNumberAt(location: location)
    }
    
}
