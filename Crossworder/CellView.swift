//
//  CellView.swift
//  Crossworder
//
//  Created by Jacob Vandermeer on 2/24/17.
//  Copyright © 2017 Jacob Vandermeer. All rights reserved.
//

import UIKit

protocol CellViewDelegate: class {
    func enterLetterFromCellView(sender: CellView)
    func deleteLetterFromCellView(sender: CellView)
    func touchFromCellView(sender: CellView)
}


class CellView: UIControl, UITextInput {
    
    static let blueColor = UIColor(red: 0.87, green: 0.93, blue: 0.96, alpha: 1.0)
    static let yellowColor = UIColor(red: 0.98, green: 0.97, blue: 0.67, alpha: 1.0)
    static let blackColor = UIColor.black
    static let whiteColor = UIColor.white
    
    enum CellType {
        case White(Int?)
        case Black
    }
    
    typealias Location = CrosswordModel.Location

    private (set) var letter: String {
        get {
            return letterLabel.text!
        } set {
            letterLabel.text = newValue
        }
    }
    
    func highlightYellow() {
        backgroundColor = CellView.yellowColor
    }
    func highlightBlue() {
        backgroundColor = CellView.blueColor
    }
    func highlightWhite() {
        backgroundColor = UIColor.white
    }
    
    let location: Location
    private weak var delegate: CellViewDelegate!
    private (set) var cellType: CellType
    private var clueNumberLabel: UILabel!
    private var letterLabel: UILabel!
    
    var autocorrectionType: UITextAutocorrectionType
    var autocapitalizationType: UITextAutocapitalizationType
    
    private struct Scaling {
        static let numLabelOffsetToBoundsWidthRatio: CGFloat = 0.15
        static let numLabelWidthToBoundsWidthRatio: CGFloat = 0.4
        static let numLabelOffsetToBoundsHeightRatio: CGFloat = 0.05
        static let numLabelHeightToBoundsHeightRatio: CGFloat = 0.35
        static let numLabelFontPointToBoundsHeightRatio: CGFloat = 0.3
        
        static let letterLabelOffsetFromCenterToMaxOffsetFromCenterRatio: CGFloat = 0.1
        static let letterLabelOffsetFromNumLabelToBoundsHeightRatio: CGFloat = 0
        static let letterLabelWidthToBoundsWidthRatio: CGFloat = 0.65
        static let letterLabelHeightToBoundsHeightRatio: CGFloat = 0.65
        static let letterLabelFontPointToBoundsHeightRatio: CGFloat = 0.65
        
        static let borderWidthToBoundsWidthRatio: CGFloat = 0.015
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            switch cellType {
            case .White:
                return true
            case .Black:
                return false
            }
        }
    }
    
    
    init(frame: CGRect, cellType: CellType, location: Location, sender: CrosswordViewController) {
        self.cellType = cellType
        self.location = location
        delegate = sender
        autocorrectionType = UITextAutocorrectionType.no
        autocapitalizationType = UITextAutocapitalizationType.allCharacters
        super.init(frame: frame)
        self.frame = frame
        switch cellType {
        case .White(let (possibleClueNumber)):
            backgroundColor = CellView.whiteColor
            if let clueNumber = possibleClueNumber { buildNumLabel(clueNumber: clueNumber) }
            buildLetterLabel()
        case .Black:
            backgroundColor = CellView.blackColor
        }
        layer.borderColor = CellView.blackColor.cgColor
        layer.borderWidth = bounds.width * Scaling.borderWidthToBoundsWidthRatio
        if clueNumberLabel != nil { self.addSubview(clueNumberLabel!) }
        if letterLabel != nil { self.addSubview(letterLabel!) }
        addTarget(self, action: #selector(CellView.onTouchUpInside(_:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildNumLabel(clueNumber: Int) {
        clueNumberLabel = UILabel(frame: CGRect(x: bounds.width * Scaling.numLabelOffsetToBoundsWidthRatio, y: bounds.height * Scaling.numLabelOffsetToBoundsHeightRatio, width: bounds.width * Scaling.numLabelWidthToBoundsWidthRatio, height: bounds.height * Scaling.numLabelHeightToBoundsHeightRatio))
        clueNumberLabel.textAlignment = NSTextAlignment.left
        clueNumberLabel.font = UIFont(name: "Arial", size: bounds.height * Scaling.numLabelFontPointToBoundsHeightRatio)
        clueNumberLabel.text = "\(clueNumber)"
    }
    
    private func buildLetterLabel() {
        let letterX = bounds.width * (1 - Scaling.letterLabelWidthToBoundsWidthRatio) * (1 + Scaling.letterLabelOffsetFromCenterToMaxOffsetFromCenterRatio) / 2
        let letterY = bounds.height * (Scaling.numLabelHeightToBoundsHeightRatio + Scaling.letterLabelOffsetFromNumLabelToBoundsHeightRatio)
        let letterFrame = CGRect(x: letterX, y: letterY, width: bounds.width * Scaling.letterLabelWidthToBoundsWidthRatio, height: bounds.height * Scaling.letterLabelHeightToBoundsHeightRatio)
        letterLabel = UILabel(frame: letterFrame)
        letterLabel.textAlignment = NSTextAlignment.center
        letterLabel.font = UIFont(name: "Arial", size: bounds.height * Scaling.letterLabelHeightToBoundsHeightRatio)
        letterLabel.text = ""
    }
    
    @objc private func onTouchUpInside(_: AnyObject) {
        switch cellType {
        case .White:
            delegate.touchFromCellView(sender: self)
        case .Black: break
        }
    }
    
    func delete() {
        letter = ""
    }
    
    func insertText(_ text: String) {
        letter = text
        delegate.enterLetterFromCellView(sender: self)
    }
    
    func deleteBackward() {
        delete()
        delegate.deleteLetterFromCellView(sender: self)
    }
    
    var hasText: Bool {
        get {
            return letter == ""
        }
    }
    
    //UITextInput implementation
    
    func text(in range: UITextRange) -> String? { return nil }
    func replace(_ range: UITextRange, withText text: String) { }
    var selectedTextRange: UITextRange?
    var markedTextRange: UITextRange?
    var markedTextStyle: [AnyHashable : Any]?
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) { }
    func unmarkText() { }
    var beginningOfDocument: UITextPosition = UITextPosition()
    var endOfDocument: UITextPosition = UITextPosition()
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? { return nil }
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? { return nil }
    func position(within range: UITextRange, atCharacterOffset offset: Int) -> UITextPosition? { return nil }
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? { return nil }
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult { return ComparisonResult(rawValue: 0)! }
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int { return 0 }
    var inputDelegate: UITextInputDelegate?
    var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer()
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? { return nil }
    func characterRange(at point: CGPoint) -> UITextRange? { return nil }
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> UITextWritingDirection { return UITextWritingDirection.leftToRight }
    func setBaseWritingDirection(_ writingDirection: UITextWritingDirection, for range: UITextRange) { }
    func firstRect(for range: UITextRange) -> CGRect { return CGRect.zero }
    func caretRect(for position: UITextPosition) -> CGRect { return CGRect.zero }
    func selectionRects(for range: UITextRange) -> [Any] { return [Any]() }
    func closestPosition(to point: CGPoint) -> UITextPosition? { return nil }
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? { return nil }
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? { return nil }
}
