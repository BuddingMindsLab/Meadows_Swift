//
//  ViewController.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-01-10.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var stimuliControls: UISegmentedControl!
    @IBOutlet weak var subjectField: UITextField!
    @IBOutlet weak var utilityExp: UITextField!
    @IBOutlet weak var evidenceWeightField: UITextField!
    @IBOutlet weak var maxLengthField: UITextField!
    @IBOutlet weak var maxItemsField: UITextField!
    @IBOutlet weak var maxNumIterations: UITextField!
    @IBOutlet weak var deterministic: UISwitch!
    @IBOutlet weak var numToPlace: UITextField!
    
    @IBOutlet weak var mPicker: UIPickerView!
    
    var stimuliType = 0
    var stimuli = [String]()
    let picker_data = ["Group 1", "Group 2", "Group 3", "Group 4", "Group 5", "Group 6", "Group 7", "Group 8", "Group 9", "Group 10", "Group 11", "Group 12", "Group 13", "Group 14", "Group 15", "Group 16", "Group 17", "Group 18", "Group 19", "Group 20", "Group 21", "Group 22", "Group 23", "Group 24", "Group 25", "Group 26", "Group 27", "Group 28"]
    var groupId = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startBtn.layer.cornerRadius = 5
        startBtn.layer.borderWidth = 1
        startBtn.layer.borderColor = UIColor.blue.cgColor
        
        mPicker.delegate = self
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return picker_data.count
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return picker_data[row]
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        groupId = row + 1
    }
    
    @IBAction func stimuliChanged(_ sender: Any) {
        stimuliType = stimuliControls.selectedSegmentIndex
    }
    
    @IBAction func startExperiment(_ sender: Any) {
        let choice = stimuliControls.selectedSegmentIndex
        switch choice {
        case 0:
            performSegue(withIdentifier: "DefaultSegue", sender: self)
        case 1:
            performSegue(withIdentifier: "CustomSegue", sender: self)
        case 2:
            performSegue(withIdentifier: "SlideshowSegue", sender: self)
        default:
            print("error at start button")
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DefaultSegue" {
            let controller = segue.destination as! CircularArenaController
            //need to load controller.stimuli right away
            controller.subjectID = subjectField.text!
            controller.stimuli = process_data(input: load_data(fileName: "words", fileType: "csv"))
            controller.evidenceUtilityExponent = Double(utilityExp.text!)!
            controller.minRequiredEvidenceWeight = Double(evidenceWeightField.text!)!
            controller.maxSessionLength = Double(maxLengthField.text!)!
            controller.maxNitemsPerTrial = Double(maxItemsField.text!)!
            controller.maxNumIterations = Int(maxNumIterations.text!)!
            if (deterministic.isOn) {
                controller.fixedItemsPerIteration = Int(numToPlace.text!)!
            }
        } else if segue.identifier == "CustomSegue" {
            let controller = segue.destination as! CustomStimuliController
            controller.subjectID = subjectField.text!
            controller.data = process_data(input: load_data(fileName: "words", fileType: "csv"))
            controller.evidenceUtilityExponent = Double(utilityExp.text!)!
            controller.minRequiredEvidenceWeight = Double(evidenceWeightField.text!)!
            controller.maxSessionLength = Double(maxLengthField.text!)!
            controller.maxNitemsPerTrial = Double(maxItemsField.text!)!
            controller.maxNumIterations = Int(maxNumIterations.text!)!
            if (deterministic.isOn) {
                controller.fixedItemsPerIteration = Int(numToPlace.text!)!
            }
        } else if segue.identifier == "SlideshowSegue" {
            let controller = segue.destination as! SlideshowController
            controller.subjectID = subjectField.text!
            controller.data = process_data(input: load_data(fileName: "words", fileType: "csv"))
            controller.evidenceUtilityExponent = Double(utilityExp.text!)!
            controller.minRequiredEvidenceWeight = Double(evidenceWeightField.text!)!
            controller.maxSessionLength = Double(maxLengthField.text!)!
            controller.maxNitemsPerTrial = Double(maxItemsField.text!)!
            controller.maxNumIterations = Int(maxNumIterations.text!)!
            if (deterministic.isOn) {
                controller.fixedItemsPerIteration = Int(numToPlace.text!)!
            }
        }
        
    }
    
    func process_data(input: [String]) -> [String] {
        var result = [String]()
        for rowI in 1 ..< input.count {
            let rowList = input[rowI].components(separatedBy: ",")
            result.append(rowList[groupId - 1])
        }
        return result
    }
    
    func load_data(fileName: String, fileType: String) -> [String]! {
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else {
                return nil
        }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            let data = contents.components(separatedBy: "\r")
            return data
        } catch {
            return nil
        }
    }

}

