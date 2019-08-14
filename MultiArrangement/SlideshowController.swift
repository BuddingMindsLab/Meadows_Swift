//
//  SlideshowController.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-04-18.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

import UIKit

class SlideshowController: UIViewController {

    var subjectID = ""
    var data = [String]()
    var subsetData = [String]()
    var evidenceUtilityExponent = Double()
    var minRequiredEvidenceWeight = Double()
    var maxSessionLength = Double()
    var maxNitemsPerTrial = Double()
    var maxNumIterations = 60
    var fixedItemsPerIteration = 0
    
    let center_x = Double(UIScreen.main.bounds.width) / 2.0
    let center_y = Double(UIScreen.main.bounds.height) / 3.0
    
    var i = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showWord()
    }
    
    func showWord() {
        for v in self.view.subviews {
            if v.accessibilityIdentifier == nil {
                v.removeFromSuperview()
            }
        }
        if i < data.count {
            let thisLabel:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
            thisLabel.center = CGPoint(x: center_x, y: center_y)
            thisLabel.textAlignment = .center
            thisLabel.text = data[i]
            thisLabel.textColor = UIColor.black
            thisLabel.font = thisLabel.font.withSize(48)
            self.view.addSubview(thisLabel)
        } else {
            performSegue(withIdentifier: "SlideshowToCircle", sender: self)
        }
    }

    @IBAction func yesButton(_ sender: Any) {
        subsetData.append(data[i])
        i += 1
        showWord()
    }
    
    @IBAction func noButton(_ sender: Any) {
        i += 1
        showWord()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! CircularArenaController
        controller.subjectID = self.subjectID
        controller.stimuli = self.data
        controller.evidenceUtilityExponent = self.evidenceUtilityExponent
        controller.minRequiredEvidenceWeight = self.minRequiredEvidenceWeight
        controller.maxSessionLength = self.maxSessionLength
        controller.maxNitemsPerTrial = self.maxNitemsPerTrial
        controller.maxNumIterations = maxNumIterations
        controller.fixedItemsPerIteration = fixedItemsPerIteration
    }
}
