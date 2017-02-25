//
//  CrosswordViewController.swift
//  Crossworder
//
//  Created by Jacob Vandermeer on 2/24/17.
//  Copyright © 2017 Jacob Vandermeer. All rights reserved.
//

import UIKit

class CrosswordViewController: UIViewController, UITextInputTraits, CellViewDelegate {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    @IBOutlet weak var clueLabel: UILabel!
    @IBOutlet weak var nextClueButton: UIButton!
    @IBOutlet weak var previousClueButton: UIButton!
    
    @IBAction func moveToNeighborClue(_ sender: UIButton) {
        switch sender.titleLabel!.text! {
        case ">":
            model.goToNextClue()
        case "<":
            model.goToPreviousClue()
        default: break
        }
        update()
    }
    
    
    
    private typealias Orientation = CrosswordModel.Orientation
    private typealias Location = CrosswordModel.Location
    private typealias CellType = CellView.CellType
    
    private let outerBorderWidth: CGFloat = 2.0, topOffset: CGFloat = 22.0
    private var needToAdjustForKeyboard = true
    private var model: CrosswordModel!
    private var grid: [Location: CellView]!
    
    private var highlightLocation: Location! {
        didSet {
            if oldValue != nil {
                if highlightWord.contains(oldValue) {
                    if oldValue != highlightLocation {
                        grid[oldValue]!.highlightBlue()
                    }
                } else {
                    grid[oldValue]!.highlightWhite()
                }
            }
            grid[highlightLocation]!.highlightYellow()
        }
    }
    
    private var highlightWord: [Location]! {
        didSet {
            if oldValue != nil && oldValue != highlightWord {
                for location in oldValue {
                    grid[location]!.highlightWhite()
                }
            }
            for location in highlightWord {
                grid[location]!.highlightBlue()
            }
        }
    }
    
    private func update() {
        highlightWord = model.currentWord
        highlightLocation = model.currentLocation
        clueLabel.text = model.currentClue
        if grid[highlightLocation]!.letter != model.currentLetter() {
            grid[highlightLocation]!.delete()
        }
        grid[highlightLocation]!.becomeFirstResponder()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if needToAdjustForKeyboard {
            let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
            clueLabel.center.y -= keyboardHeight
            nextClueButton.center.y -= keyboardHeight
            previousClueButton.center.y -= keyboardHeight
            needToAdjustForKeyboard = false
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(CrosswordViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        model = CrosswordModel(fileName: "Puzzle")
        let cellDimension = view.bounds.width / CGFloat(model.columns)
        let roundedCellDiomension = round(cellDimension)
        
        
        grid = [Location: CellView]()
        let gridView = UIView(frame: CGRect(x: 0, y: topOffset, width: view.bounds.width, height: CGFloat(model.rows) * roundedCellDiomension))
        gridView.layer.borderColor = CellView.blackColor.cgColor
        gridView.layer.borderWidth = outerBorderWidth
        view.addSubview(gridView)
        for row in 0..<model.rows {
            for column in 0..<model.columns {
                let location = Location(row: row, column: column)
                let cell = CellView(frame: CGRect(x: CGFloat(column) * roundedCellDiomension, y: CGFloat(row) * roundedCellDiomension, width: cellDimension, height: cellDimension), cellType: model.correctLetterAt(location: location) == nil ? CellType.Black : CellType.White(model.clueNumberAt(location: location)), location: location, sender: self)
                grid[location] = cell
                gridView.addSubview(cell)
            }
        }
        update()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func enterLetterFromCellView(sender: CellView) {
        model.enterLetter(letter: sender.letter)
        update()
    }
    
    func deleteLetterFromCellView(sender: CellView) {
        model.deleteLetter(letter: sender.letter)
        update()
    }
    
    func touchFromCellView(sender: CellView) {
        model.goToLocation(location: sender.location)
        update()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
