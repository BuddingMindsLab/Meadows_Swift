//
//  CircularArenaController.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-01-10.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

import UIKit
import MessageUI
typealias Request = ((_ value:String) ->())

class CircularArenaController: UIViewController, MFMailComposeViewControllerDelegate {

    var evidenceUtility_sq_rounded_str = String()
    
    var stimuli = [String]()
    var subjectID = ""
    var options = ["evidenceUtilityExponent": 10, "minRequiredEvidenceWeight": 0.5,
                   "dragsExponent": 1.2]
    
    // for LiftTheWeakest
    var nItems = 0
    var nPairs = 0
    var controlVars = [String : Double]()
    var evidenceUtilityExponent = 10.0
    var minRequiredEvidenceWeight = 0.5
    var dragsExponent = 1.2
    var subjectWork_nItemsArranged = 0.0
    var subjectWork_nPairsArranged = 0.0
    var subjectWork_nDragsEstimate = 0.0
    var minEvidenceWeight = 0.0
    var maxSessionLength = Double.infinity
    var maxNitemsPerTrial = 12.0
    var estimate_RDM_ltv = [Double]()
    var estimate_RDM_sq = [[Double]]()
    var estimate_RDM_sq_cTrial = [[Double]]()
    var distanceMat_ltv = [Double]()
    var distMat_ltv = [Double]()
    var utilityBenefit = 0.0
    var timeLimit = 200.0    //change this for testing purposes
    var round_start_time = Double()
    var maxNumIterations = 60
    var currIter = 0
    
    var currentPos = [String : [Double]]()   // the current positions of the images <id(str) -> pos(list)>
    var currPos = [[Double]]()   // temp for currentPos above
    var finishClicked = false
    var trialStopTimes = [Double]()
    var trialDurations = [Double]()
    var nsItemsPerTrial = [Int : Double]()
    
    var distMatsForAllTrials_ltv = [[[Double]]]()   // an array of (arrays of arrays)
    var evidenceWeight_ltv = [[Double]]()
    
    var eye_nitems = [[Double]]()
    var verIs = [[Double]]()
    var horIs = [[Double]]()
    var verIs_ltv = [Double]()
    var horIs_ltv = [Double]()
    var weakestEvidenceWeights = [[Double]]()
    var meanEvidenceWeights = [[Double]]()
    var trialI = 0
    var cTrial_itemIs = [Int]()
    
    var first_press = true
    var start = Double()
    
    var final_result = story()
    
    let center_x = Double(UIScreen.main.bounds.width) / 2.0 - 46.0
    let center_y = Double(UIScreen.main.bounds.height) / 2.0 - 20.0
    let radius = 480.0
    let visual_radius = 728.0 / 2.0
    var draggedViews = [String:Bool]()
    
    var file_name = ""
    
    var initialPairI = Int()
    var maxVal = Double()
    var maxI = Int()
    var maxIs = [Int]()
    var cTrial_itemIs_adjusted_index = [Int]()
    
    var fixedItemsPerIteration = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nItems = stimuli.count
        nPairs = nItems * (nItems - 1) / 2   // pairs = n(n-1)/2
        
        file_name = subjectID + ".csv"
        
        startTrialSetup()   // was originally part of viewDidAppear
    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        //startTrial()
//        startTrialSetup()
//    }


    @IBOutlet weak var mScreen: UIView!


    func drawBackground(stimuli_indices: [Int]) {
        currIter += 1
        //print("drawing")
        //self.view.backgroundColor = UIColor.lightGray
        let pos = getPositions(n: stimuli_indices.count)
//        print("stimuli indices")
//        print(stimuli)
        for i in 0..<stimuli_indices.count {
            // programmatically add labels with corresponding words to arena

            let thisLabel:UILabel = UILabel(frame: CGRect(x: pos[i][0], y: pos[i][1], width: 120, height: 55))
            thisLabel.textAlignment = .center
            thisLabel.text = stimuli[stimuli_indices[i] - 1]    // -1
            thisLabel.textColor = UIColor.black
            //for MATLAB indexing correction
//            print("actual text")
//            print(stimuli[stimuli_indices[i] - 1])
            thisLabel.isUserInteractionEnabled = true
            thisLabel.accessibilityIdentifier = thisLabel.text!
            draggedViews = [String:Bool]()
            draggedViews[thisLabel.accessibilityIdentifier!] = false
            let gesture = UIPanGestureRecognizer(target: self,
                                                 action: #selector (draggingView(_:)))
            thisLabel.addGestureRecognizer(gesture)

            thisLabel.isHidden = false
            self.view.addSubview(thisLabel)
            
            // add labels to list for operation button activation
        }
        // start clock for this round
        start = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
    }

    // given n items, returns the positions of those n items such that they are
    // evenly spaced out in a circle
    func getPositions(n: Int) -> [[Double]] {
        var pos = [[Double]]()

        var angle = 0.0
        let delta_theta = 2*Double.pi / Double(n)
        //delta_theta.round(.down)
        for _ in 1...n {
            pos.append([center_x + radius*cos(angle), center_y + radius*sin(angle)])
            angle += delta_theta
        }
        return pos
    }

    @objc func draggingView(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: view)
        let draggedView = sender.view!
        draggedView.center = CGPoint(x: point.x, y: point.y)
        if (sender.state == .ended) {
            if (Darwin.pow(Darwin.pow(Double(draggedView.center.x)-center_x, 2.0) + Darwin.pow(Double(draggedView.center.y)-center_y, 2.0), 0.5) <= visual_radius + 30.0) {
                draggedViews[draggedView.accessibilityIdentifier!] = true
            }
            if (!draggedViews.values.contains(false)) {
                operation_button.isUserInteractionEnabled = true
            }
        }
    }

    @IBAction func earlyFinish(_ sender: Any) {
        experiment_complete()
        let final_data = get_data_string()
        sendEmail(data: final_data)
    }

 
    @IBOutlet weak var operation_button: UIButton!
    
    func set_random_indices() {
        let indices = Array(0..<stimuli.count).shuffled()
        cTrial_itemIs = indices.choose(fixedItemsPerIteration)
    }
    
    //get locations of each image after user clicks the Finish button
    @IBAction func btnPressed(_ sender: Any) {
        if first_press == true {
            if (fixedItemsPerIteration == 0) {
                prepare_matrices()
            } else {
                set_random_indices()
            }
            drawBackground(stimuli_indices: cTrial_itemIs)
            first_press = false
            operation_button.setTitle("Finished", for: .normal)
            operation_button.isUserInteractionEnabled = false
        } else {
            operation_button.isUserInteractionEnabled = false
            currentPos = [String:[Double]]()
            // gets the positions of all the labels on screen
            for label in view.subviews {
                if label.accessibilityIdentifier != nil {
                    // scale such that arena's diameter corresponds to 1.0
                    let x = (Double(label.center.x) - center_x) / visual_radius
                    let y = (Double(label.center.y) - center_y) / visual_radius
                    currentPos[label.accessibilityIdentifier!] = [x, y]
                }
            }

            // remaining code of while loop after the waiting for user input phase
            finishup()

            // same functionality as first while loop condition in previous version of startTrial()
            let argument = evidenceWeight_ltv.flatMap{ $0 }

            if  (currIter < maxNumIterations || self.minEvidenceWeight < self.minRequiredEvidenceWeight && (any(mat: argument, val: 0.0)) || etime(start: start) < maxSessionLength) {
                // remove all labels
                for label in view.subviews{
                    if label.accessibilityIdentifier != nil {
                        label.removeFromSuperview()
                    }
                }
                // calculate new stimuli set, process should update cTrial_itemIs
                // this process is done in finishup()
                // draw new labels
                if (fixedItemsPerIteration == 0) {
                    prepare_matrices()
                } else {
                    set_random_indices()
                }
                drawBackground(stimuli_indices: cTrial_itemIs)
            } else {
                // experiment is finished
                experiment_complete()
                let final_data = get_data_string()
                sendEmail(data: final_data)
            }
        }
    }


    func startTrialSetup() {
        //useful to have precomputed
        eye_nitems = eye(n: nItems)
        
        verIs = ndgrid(bounds: [[1,nItems], [1,nItems]])
        horIs = transpose(mat: verIs)
        verIs_ltv = vectorizeSimmat(mat: verIs)[0]
        horIs_ltv = vectorizeSimmat(mat: horIs)[0]
        evidenceWeight_ltv = zeros(size: [1, verIs_ltv.count])
        weakestEvidenceWeights = [[Double]]()       // this too
        meanEvidenceWeights = [[Double]]()
        
        trialI = 0
    }

    func prepare_matrices() {
        let negate = elementWise(op: "*", left: evidenceWeight_ltv, right: -1)
        let etothe = elementWise(op: "*", left: negate, right: evidenceUtilityExponent)
        let exponent = elementWise(op: "exp", left: etothe, right: 1.0)
        let negagain = elementWise(op: "*", left: exponent, right: -1)
        var evidenceUtility_ltv = elementWise(op: "+", left: negagain, right: 1.0)
        var evidenceUtility_sq = squareform(arr: evidenceUtility_ltv.flatMap{ $0 })
        var evidenceLOG_ltv = elementWise(op: ">", left: evidenceUtility_ltv, right: 0.0)
        
        if any(mat: evidenceLOG_ltv.flatMap{ $0 } , val: 1.0) {
            var evidenceUtility_sq_nan = evidenceUtility_sq
            evidenceUtility_sq_nan = logical(mat: evidenceUtility_sq_nan, bool_mat: eye_nitems, val: Double.nan)
            var nObjEachObjHasNotBeenPairedWith = nansum(mat: evidenceUtility_sq_nan)
            
            let repmat_column = nObjEachObjHasNotBeenPairedWith.flatMap{ $0 }
            let lhs = repmat_col(col: repmat_column, row_times: 1, col_times: nItems)
            let rhs = repmat(mat: nObjEachObjHasNotBeenPairedWith, num_row: nItems, num_col: 1)
            var nZeroEvidencePairsReachedByEachPair = matrix_addition(left: lhs, right: rhs)
            nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair, bool_mat: eye_nitems, val: 0.0)
            let nZeroEvidencePairsReachedByEachPair_ltv = inverse_squareform(arr: nZeroEvidencePairsReachedByEachPair)
            let evidenceLOG_inverted = elementWise(op: "~", left: evidenceLOG_ltv, right: 1.0)
            
            nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair_ltv, bool_mat: evidenceLOG_inverted, val: 0.0)
            
            let nZero_flat = nZeroEvidencePairsReachedByEachPair.flatMap{ $0 }
            maxVal = nZero_flat.max()!
            maxI = nZero_flat.firstIndex(of: maxVal)!
            maxIs = find_2d(in_: nZeroEvidencePairsReachedByEachPair, item: maxVal)
            maxI = maxIs[ceil(num: rand()*Double(maxIs.count) - 1)]
        } else {
            initialPairI = ceil(num: rand()*Double(nPairs) - 1)
        }
        let item1I = verIs_ltv[initialPairI]
        let item2I = horIs_ltv[initialPairI]
        cTrial_itemIs = [Int(item1I), Int(item2I)]
        cTrial_itemIs.sort()
        
        while Double(cTrial_itemIs.count) < maxNitemsPerTrial {
            var trialEfficiencies = nan_grid(num_rows: nItems - cTrial_itemIs.count + 1, num_cols: 1)[0]     //
            //note: verify that the above results in a column vector (1D)
            let otherItemIs = setdiff(A: [Int](1...nItems), B: cTrial_itemIs)
            var itemAddedI = [Int]()
            //var itemSetI = 1 <-- original initialization
            var itemSetI = 0    // adjusted index
            
            while true {
                if estimate_RDM_ltv.count > 0 {
                    estimate_RDM_sq = squareSimmat(vec: estimate_RDM_ltv)
                } else {
                    estimate_RDM_sq = ones(rows: nItems, cols: nItems)
                    //print("line 279")
                    estimate_RDM_sq = logical(mat: estimate_RDM_sq, bool_mat: eye_nitems, val: 0.0)
                    estimate_RDM_ltv = inverse_squareform(arr: estimate_RDM_sq).flatMap{ $0 }
                }
                // this corrects for MATLAB's index for matrix_partition
                cTrial_itemIs_adjusted_index = cTrial_itemIs.compactMap{$0 - 1}
                cTrial_itemIs_adjusted_index.sort()
                estimate_RDM_sq_cTrial = matrix_partition(mat: estimate_RDM_sq, rows: cTrial_itemIs_adjusted_index, cols: cTrial_itemIs_adjusted_index)
                if colon_operation(mat: estimate_RDM_sq_cTrial).max()! > 0.0 {
                    let med = median(arr: estimate_RDM_ltv)
                    let isnan_bool = isnan(mat: estimate_RDM_sq_cTrial)
                    //print("line 293")
                    estimate_RDM_sq_cTrial = logical(mat: estimate_RDM_sq_cTrial, bool_mat: isnan_bool, val: med)
                    let denom = colon_operation(mat: estimate_RDM_sq_cTrial).max()!
                    estimate_RDM_sq_cTrial = elementWise(op: "/", left: estimate_RDM_sq_cTrial, right: denom)
                    let after_part = matrix_partition(mat: evidenceUtility_sq, rows: cTrial_itemIs_adjusted_index, cols: cTrial_itemIs_adjusted_index)
                    let utilityBeforeTrial = inverse_squareform(arr: after_part).flatMap{ $0 }.reduce(0, +)
                    //                    print("before calc")
                    //                    print(inverse_squareform(arr: after_part))
                    
                    let evidenceWeight_sq = squareform(arr: evidenceWeight_ltv.flatMap{ $0 })
                    
                    let left_partition = matrix_partition(mat: evidenceWeight_sq, rows: cTrial_itemIs_adjusted_index, cols: cTrial_itemIs_adjusted_index)
                    let right_part = evidenceWeights(mat: [estimate_RDM_sq_cTrial])
                    var evidenceWeightAfterTrial_sq = matrix_addition(left: left_partition, right: right_part[0])    // verify
                    let cTrial_logic_eye = eye(n: cTrial_itemIs.count)
                    //print("line 314")
                    evidenceWeightAfterTrial_sq = logical(mat: evidenceWeightAfterTrial_sq, bool_mat: cTrial_logic_eye, val: 0.0)
                    let weight_after_trial_vector = inverse_squareform(arr: evidenceWeightAfterTrial_sq)    // 2D row vector here
                    let negated_weights = elementWise(op: "*", left: weight_after_trial_vector, right: -1.0*evidenceUtilityExponent)
                    let exponential = elementWise(op: "exp", left: negated_weights, right: 1.0)
                    let negated_exponential = elementWise(op: "*", left: exponential, right: -1.0)
                    let final_sum_arg = elementWise(op: "+", left: negated_exponential, right: 1.0).flatMap{ $0 }
                    let utilityAfterTrial = final_sum_arg.reduce(0, +)
                    utilityBenefit = utilityAfterTrial - utilityBeforeTrial
                } else {
                    //                    print("In else")
                    utilityBenefit = 0.0
                }
                let trialCost = Darwin.pow(Double(cTrial_itemIs.count), dragsExponent)
                trialEfficiencies[itemSetI] = utilityBenefit / trialCost
                cTrial_itemIs = setdiff(A: cTrial_itemIs, B: itemAddedI)
                if itemSetI == otherItemIs.count {  // original code contains +1, which is deleted here
                    break
                }
                itemAddedI = [otherItemIs[itemSetI]]
                cTrial_itemIs = union(A: cTrial_itemIs, B: itemAddedI)
                itemSetI += 1
            }
            
            var maxVal = trialEfficiencies.max()!
            maxIs = find_1d(arr: trialEfficiencies, val: maxVal)
            maxI = maxIs[Int(ceil(rand()*Double(maxIs.count) - 1))]   // no -1 in original
            if maxI == 1 {  // == 1 in original code
                //print("if")
                if cTrial_itemIs.count >= 3 {
                    break
                } else {
                    let efficiency_slice = Array(trialEfficiencies[1..<trialEfficiencies.count])
                    maxVal = efficiency_slice.max()!
                    maxIs = find_1d(arr: efficiency_slice, val: maxVal)
                    maxI = maxIs[Int(ceil(rand()*Double(maxIs.count) - 1))] // no -1 in original
                    cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI - 1]])
                    cTrial_itemIs.sort()
                }
            } else {
                cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI - 2]])
                cTrial_itemIs.sort()
            }
        }
        cTrial_itemIs.sort()    // it seems that this variable in MATLAB is sorted
        trialI += 1
    }

    func experiment_complete() {
        // start/stop times not included in story
        let final_result = estimateRDM(distMats: distMatsForAllTrials_ltv)
        evidenceWeight_ltv = final_result[1]
        estimate_RDM_ltv = final_result[0].flatMap{ $0 }
    }


    func finishup() {
        trialI -= 1
        currPos.removeAll(keepingCapacity: true)
//        print("currentPos")
//        print(currentPos)
        for pos in self.currentPos.values {
            currPos.append(pos)
        }
        // TODO: make sure in original code that currPos is refreshed every round
        //       and does not maintain the data from previous rounds
        distMat_ltv = pdist(mat: currPos)
        let stopTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
        trialStopTimes.append(stopTime)
        trialDurations.append(stopTime - start)
        
        nsItemsPerTrial[trialI] = Double(cTrial_itemIs.count)
        subjectWork_nItemsArranged = subjectWork_nItemsArranged + nsItemsPerTrial[trialI]!
        let quant = Darwin.pow(nsItemsPerTrial[trialI]!, 2.0) - (nsItemsPerTrial[trialI]!/2.0)
        subjectWork_nPairsArranged = subjectWork_nPairsArranged + quant
        subjectWork_nDragsEstimate = subjectWork_nDragsEstimate + Darwin.pow(Darwin.pow(quant, 0.5), dragsExponent)
        
        var distMatFullSize = nan_grid(num_rows: nItems, num_cols: nItems)
        print("currentPos")
        print(currentPos)
        print("distmatltv")
        print(distMat_ltv.count)
        let squared = squareform(arr: distMat_ltv)
        let flat_distMat = squared.flatMap{$0}
        cTrial_itemIs_adjusted_index = cTrial_itemIs.compactMap{$0 - 1}
        cTrial_itemIs_adjusted_index.sort()
        print("four numbers")
        print(distMatFullSize.count)
        print(distMatFullSize[0].count)
        print(cTrial_itemIs_adjusted_index)
        print(flat_distMat.count)
        distMatFullSize = replace_by_vector_indexing(mat: distMatFullSize, v1: cTrial_itemIs_adjusted_index, v2: cTrial_itemIs_adjusted_index, val: flat_distMat)
        
        var distMatFullSize_ltv = vectorizeSimmat(mat: distMatFullSize)
        distMatsForAllTrials_ltv.append(distMatFullSize_ltv)
        
        //estimate dissimilarity using current evidence
        let evidence_tuple = estimateRDM(distMats: distMatsForAllTrials_ltv)
        estimate_RDM_ltv = evidence_tuple[0].flatMap{ $0 }  // verify!
        evidenceWeight_ltv = evidence_tuple[1]

        // omitted unused variables lines 286-289 in MATLAB script
        
        minEvidenceWeight = min(mat: evidenceWeight_ltv).min()!
        
        trialI += 1

        let currData = get_data_string()
        update_output(data: currData, file: subjectID + ".csv")
    }


    func update_output(data: String, file: String) {
        let this_file = getDocumentsDirectory().appendingPathComponent(file)
        do{
            try data.write(to: this_file, atomically: true, encoding: String.Encoding.utf8)
            print("file written")
        } catch {
            print("Failed to write")
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // make sure you know the order of the stimuli in the results
    //converts the current data into a string for emailing and csv file writing
    func get_data_string() -> String {
        var result = ""
        var estimate = "estimate_RDM_ltv\n"
        estimate += (estimate_RDM_ltv.map{String($0)}).joined(separator: ",") + "\n\n\n"
        var evidence = "evidenceWeight_ltv\n"
        for sub_evidence in evidenceWeight_ltv {
            let cEvidence = sub_evidence.map{String($0)}.joined(separator: ",")
            evidence = evidence + cEvidence + "\n"
        }
        evidence += "\n\n\n"
        var durations = "trialDurations\n"
        durations += trialDurations.map{String($0)}.joined(separator: ",") + "\n\n\n"
        var distMats = "distMatsForAllTrials_ltv\n"
        for i in 0..<distMatsForAllTrials_ltv.count {
            distMats += "Layer " + String(i+1) + "\n"
            for vec in distMatsForAllTrials_ltv[i] {
                distMats += vec.map{String($0)}.joined(separator: ",") + "\n"
            }
            distMats += "\n"
        }
        result = estimate + evidence + durations + distMats
        //print(result)
        return result
    }

    func sendEmail(data: String) {
        let fileName = subjectID + ".csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        do {
            try data.write(to: path!, atomically: true, encoding: String.Encoding.utf8)

            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self as MFMailComposeViewControllerDelegate
                mail.setToRecipients(["blumenthal.anna@gmail.com"])
                mail.setSubject("Multi-Arrangement Subject " + subjectID)
                mail.setMessageBody("Hi,\n\nPlease find attached the .csv file\n\nBudding Minds Lab", isHTML: false)
                try mail.addAttachmentData(NSData(contentsOf: path!) as Data, mimeType: "text/csv", fileName: subjectID + ".csv")
                present(mail, animated: true)
            } else {
                print("Email failed")
            }
        } catch {
            print("Attachment failed")
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
