////
////  CircularArena_Backup.swift
////  MultiArrangement
////
////  Created by Budding Minds Admin on 2019-05-03.
////  Copyright © 2019 Budding Minds Admin. All rights reserved.
////
//
//import UIKit
//typealias Request = ((_ value:String) ->())
//
//class CircularArenaController: UIViewController {
//
//    // var images = ["img1.jpeg", "img2.png", "img3.jpeg", "img4.jpg", "img5.jpeg"]
//    var stimuli = [String]()
//    var subjectID = ""
//    let options = ["evidenceUtilityExponent": 10, "minRequiredEvidenceWeight": 0.5,
//                   "dragsExponent": 1.2]
//
//    // for LiftTheWeakest
//    var nItems = 0
//    var nPairs = 0
//    var controlVars = [String : Double]()
//    var evidenceUtilityExponent = 10.0
//    var minRequiredEvidenceWeight = 0.5
//    var dragsExponent = 1.2
//    var subjectWork_nItemsArranged = 0.0
//    var subjectWork_nPairsArranged = 0.0
//    var subjectWork_nDragsEstimate = 0.0
//    var minEvidenceWeight = 0.0
//    let maxSessionLength = Double.infinity
//    let maxNitemsPerTrial = 12.0
//    var estimate_RDM_ltv = [Double]()
//    var estimate_RDM_sq = [[Double]]()
//    var estimate_RDM_sq_cTrial = [[Double]]()
//    var distanceMat_ltv = [Double]()
//    var distMat_ltv = [Double]()
//    var utilityBenefit = 0.0
//    var timeLimit = 20.0    //change this for testing purposes
//    var round_start_time = Double()
//
//    var currentPos = [String : [Double]]()   // the current positions of the images <id(str) -> pos(list)>
//    var currPos = [[Double]]()   // temp for currentPos above
//    var finishClicked = false
//    var trialStopTimes = [Double]()
//    var trialDurations = [Double]()
//    var nsItemsPerTrial = [Int : Double]()
//
//    var distMatsForAllTrials_ltv = [[[Double]]]()   // an array of (arrays of arrays)
//    var evidenceWeight_ltv = [[Double]]()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // fill in dictionary with nil values
//        for word in stimuli {
//            currentPos[word] = nil
//        }
//
//        self.nItems = stimuli.count
//        self.nPairs = (self.nItems^2 - self.nItems)/2   // pairs = n(n-1)/2
//
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        startTrial()
//    }
//
//
//    @IBOutlet weak var mScreen: UIView!
//
//
//    func drawBackground(stimuli_indices: [Int]) {
//        print("drawing")
//        //self.view.backgroundColor = UIColor.lightGray
//        let pos = getPositions(n: stimuli_indices.count)
//        print("stimuli indices")
//        print(stimuli)
//        for i in 0..<stimuli_indices.count {
//            // programmatically add labels with corresponding words to arena
//
//            let thisLabel:UILabel = UILabel(frame: CGRect(x: pos[i][0], y: pos[i][1], width: 300, height: 300))
//            thisLabel.textAlignment = .center
//            thisLabel.text = stimuli[stimuli_indices[i] - 1]    // -1
//            thisLabel.textColor = UIColor.black
//            //for MATLAB indexing correction
//            //            print("actual text")
//            //            print(stimuli[stimuli_indices[i] - 1])
//            thisLabel.isUserInteractionEnabled = true
//            thisLabel.accessibilityIdentifier = "nonnil"
//            let gesture = UIPanGestureRecognizer(target: self,
//                                                 action: #selector (draggingView(_:)))
//            thisLabel.addGestureRecognizer(gesture)
//
//            thisLabel.isHidden = false
//            self.view.addSubview(thisLabel)
//        }
//        sleep(3)
//        print("line 89")
//    }
//
//    // given n items, returns the positions of those n items such that they are
//    // evenly spaced out in a circle
//    func getPositions(n: Int) -> [[Double]] {
//        let center_x = Double(UIScreen.main.bounds.width) / 2.0 - 40.0
//        let center_y = Double(UIScreen.main.bounds.height) / 2.0 - 40.0
//        //        print(center_x)
//        //        print(center_y)
//        var pos = [[Double]]()
//        let radius = 320.0      // improvement: this could be not hard-coded
//        var angle = 0.0
//        let delta_theta = 2*Double.pi / Double(n)
//        //delta_theta.round(.down)
//        for _ in 1...n {
//            pos.append([center_x + radius*cos(angle), center_y + radius*sin(angle)])
//            angle += delta_theta
//        }
//        return pos
//    }
//
//    @objc func draggingView(_ sender: UIPanGestureRecognizer) {
//        let point = sender.location(in: view)
//        let draggedView = sender.view!
//        draggedView.center = CGPoint(x: point.x, y: point.y)
//    }
//
//    //get locations of each image after user clicks the Finish button
//    @IBAction func finishButton(_ sender: Any) {
//        // change this to labels
//        for label in view.subviews {
//            if label.accessibilityIdentifier != nil {
//                currentPos[label.accessibilityIdentifier!] = [Double(label.center.x), Double(label.center.y)]
//            }
//        }
//        finishClicked = true
//    }
//
//    // loades in images in <images> and returns the positions of each image with their corresponding tag
//    //    func load_images(images: [String]) -> (loc: CGPoint, tag: Int) {
//    //
//    //    }
//
//    func load_trial() {
//
//    }
//
//    func startTrial() -> story {
//        //useful to have precomputed
//        let eye_nitems = eye(n: nItems)
//
//        let verIs = ndgrid(bounds: [[1,self.nItems], [1,self.nItems]])
//        let horIs = transpose(mat: verIs)
//        let verIs_ltv = vectorizeSimmat(mat: verIs)
//        let horIs_ltv = vectorizeSimmat(mat: horIs)
//        evidenceWeight_ltv = zeros(size: [1, verIs_ltv.count])
//        var weakestEvidenceWeights = [[Double]]()       // this too
//        var meanEvidenceWeights = [[Double]]()
//
//        var trialI = 0
//
//        //record session start time
//        let start = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
//
//        // put this at the end of each trial
//        //        let end = Double(DispatchTime.now().uptimeNanoseconds)
//        //        let nanoTime = end - start
//        //        let timeInterval = nanoTime / 1_000_000_000  //this is the seconds elapsed
//        let argument = evidenceWeight_ltv.flatMap{ $0 }
//        while (self.minEvidenceWeight < self.minRequiredEvidenceWeight && (any(mat: argument, val: 0.0)) || etime(start: start) < maxSessionLength) {
//            print("line 171")
//            let negate = elementWise(op: "*", left: evidenceWeight_ltv, right: -1)
//            let etothe = elementWise(op: "*", left: negate, right: evidenceUtilityExponent)
//            let exponent = elementWise(op: "exp", left: etothe, right: 1.0)
//            let negagain = elementWise(op: "*", left: exponent, right: -1)
//            var evidenceUtility_ltv = elementWise(op: "+", left: negagain, right: 1.0)
//            var evidenceUtility_sq = squareform(arr: evidenceUtility_ltv.flatMap{ $0 })
//            var evidenceLOG_ltv = elementWise(op: ">", left: evidenceUtility_ltv, right: 0.0)
//            var initialPairI = Int()
//
//            if any(mat: evidenceLOG_ltv.flatMap{ $0 } , val: 1.0) {
//                var evidenceUtility_sq_nan = evidenceUtility_sq
//                evidenceUtility_sq_nan = logical(mat: evidenceUtility_sq_nan, bool_mat: eye_nitems, val: Double.nan)
//                var nObjEachObjHasNotBeenPairedWith = nansum(mat: evidenceUtility_sq_nan)
//
//                let repmat_column = nObjEachObjHasNotBeenPairedWith.flatMap{ $0 }
//                let lhs = repmat_col(col: repmat_column, row_times: 1, col_times: nItems)
//                let rhs = repmat(mat: nObjEachObjHasNotBeenPairedWith, num_row: nItems, num_col: 1)
//                var nZeroEvidencePairsReachedByEachPair = matrix_addition(left: lhs, right: rhs)
//                nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair, bool_mat: eye_nitems, val: 0.0)
//                let distances = inverse_squareform(arr: nZeroEvidencePairsReachedByEachPair).flatMap{ $0 }
//                let evidenceLOG_inverted = elementWise(op: "~", left: evidenceLOG_ltv, right: 1.0)
//                nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair, bool_mat: evidenceLOG_inverted, val: 0.0)
//                let nZero_flat = nZeroEvidencePairsReachedByEachPair.flatMap{ $0 }
//                let maxVal = nZero_flat.max()
//                var maxI = nZero_flat.firstIndex(of: maxVal!)
//                let maxIs = find_2d(in_: nZeroEvidencePairsReachedByEachPair, item: maxVal!)
//                maxI = maxIs[ceil(num: rand()*Double(nPairs))]
//            } else {
//                initialPairI = ceil(num: rand()*Double(nPairs))
//            }
//
//            let item1I = verIs_ltv[initialPairI]
//            let item2I = horIs_ltv[initialPairI]
//
//            var cTrial_itemIs = [Int(item1I), Int(item2I)]
//            //            print("line 190")
//            //            print(cTrial_itemIs)
//
//            while Double(cTrial_itemIs.count) < maxNitemsPerTrial {
//                //print("are we stuck at 192?")
//                var trialEfficiencies = nan_grid(num_rows: nItems - cTrial_itemIs.count + 1, num_cols: 1)[0]     //note: verify that the above results in a column vector (1D)
//                let otherItemIs = setdiff(A: [Int](1...nItems), B: cTrial_itemIs)
//                var itemAddedI = [Int]()
//                //var itemSetI = 1 <-- original initialization
//                var itemSetI = 0    // adjusted index
//
//                while true {
//                    if estimate_RDM_ltv.count > 1 {
//                        //...
//                    } else {
//                        estimate_RDM_sq = ones(rows: nItems, cols: nItems)
//                        estimate_RDM_sq = logical(mat: estimate_RDM_sq, bool_mat: eye_nitems, val: 0.0)
//                        estimate_RDM_ltv = inverse_squareform(arr: estimate_RDM_sq).flatMap{ $0 }
//                    }
//                    //                    print("cTrial_itemIs is")
//                    //                    print(cTrial_itemIs)
//                    //                    print("estimate_RDM_sq")
//                    //                    print(estimate_RDM_sq)
//                    // this corrects for MATLAB's index for matrix_partition
//                    let cTrial_itemIs_adjusted_index = cTrial_itemIs.compactMap{$0 - 1}
//                    estimate_RDM_sq_cTrial = matrix_partition(mat: estimate_RDM_sq, rows: cTrial_itemIs_adjusted_index, cols: cTrial_itemIs_adjusted_index)
//                    if colon_operation(mat: estimate_RDM_sq_cTrial).max()! > 0.0 {
//                        let med = median(arr: estimate_RDM_ltv)
//                        let isnan_bool = isnan(mat: estimate_RDM_sq_cTrial)
//                        estimate_RDM_sq_cTrial = logical(mat: estimate_RDM_sq_cTrial, bool_mat: isnan_bool, val: med)
//                        let denom = colon_operation(mat: estimate_RDM_sq_cTrial).max()!
//                        estimate_RDM_sq_cTrial = elementWise(op: "/", left: estimate_RDM_sq_cTrial, right: denom)
//
//                        //                        print("cTrial_itemIs is")
//                        //                        print(cTrial_itemIs)
//                        //                        print("evidenceUtility_sq")
//                        //                        print(evidenceUtility_sq)
//                        let after_part = matrix_partition(mat: evidenceUtility_sq, rows: cTrial_itemIs_adjusted_index, cols: cTrial_itemIs_adjusted_index)
//                        let utilityBeforeTrial = inverse_squareform(arr: after_part).flatMap{ $0 }.reduce(0, +)
//                        let evidenceWeight_sq = squareform(arr: evidenceWeight_ltv.flatMap{ $0 })
//
//                        //                        print("cTrial_itemIs is")
//                        //                        print(cTrial_itemIs)
//                        //                        print("evidenceWeight_sq")
//                        //                        print(evidenceWeight_sq)
//                        let left_partition = matrix_partition(mat: evidenceWeight_sq, rows: cTrial_itemIs_adjusted_index, cols: cTrial_itemIs_adjusted_index)
//                        let right_part = evidenceWeights(mat: [estimate_RDM_sq_cTrial])
//                        var evidenceWeightAfterTrial_sq = matrix_addition(left: left_partition, right: right_part[0])    // verify
//                        let cTrial_logic_eye = eye(n: cTrial_itemIs.count)
//                        evidenceWeightAfterTrial_sq = logical(mat: evidenceWeightAfterTrial_sq, bool_mat: cTrial_logic_eye, val: 0.0)
//                        let weight_after_trial_vector = inverse_squareform(arr: evidenceWeightAfterTrial_sq)    // 2D row vector here
//                        let negated_weights = elementWise(op: "*", left: weight_after_trial_vector, right: -1.0*evidenceUtilityExponent)
//                        let exponential = elementWise(op: "exp", left: negated_weights, right: 1.0)
//                        let negated_exponential = elementWise(op: "*", left: exponential, right: -1.0)
//                        let final_sum_arg = elementWise(op: "+", left: negated_exponential, right: 1.0).flatMap{ $0 }
//                        let utilityAfterTrial = final_sum_arg.reduce(0, +)
//                        utilityBenefit = utilityAfterTrial - utilityBeforeTrial
//                    } else {
//                        utilityBenefit = 0.0
//                    }
//                    let trialCost = Darwin.pow(Double(cTrial_itemIs.count), dragsExponent)
//                    //                    print(trialEfficiencies)
//                    //                    print("itemSetI is")
//                    //                    print(itemSetI)
//                    trialEfficiencies[itemSetI] = utilityBenefit / trialCost
//                    cTrial_itemIs = setdiff(A: cTrial_itemIs, B: itemAddedI)
//                    //                    print("line 253")
//                    //                    print(cTrial_itemIs)
//
//                    if itemSetI == otherItemIs.count {  // original code contains +1, which is deleted here
//                        break
//                    }
//                    //                    print("otherItems")
//                    //                    print(otherItemIs)
//                    //                    print("index_itemset")
//                    //                    print(itemSetI)
//                    itemAddedI = [otherItemIs[itemSetI]]
//                    //                    print("input A")
//                    //                    print(cTrial_itemIs)
//                    //                    print("input B")
//                    //                    print(itemAddedI)
//                    cTrial_itemIs = union(A: cTrial_itemIs, B: itemAddedI)
//                    //                    print("line 263")
//                    //                    print(cTrial_itemIs)
//                    itemSetI += 1
//                }
//
//                var maxVal = trialEfficiencies.max()!
//                var maxIs = find_1d(arr: trialEfficiencies, val: maxVal)
//                var maxI = maxIs[Int(ceil(rand()*Double(maxIs.count-1)))]   // no -1 in original
//                //                print("maxIs 277")
//                //                print(maxIs)
//                //                print("maxIs 279")
//                //                print(maxIs)
//                //                print("cTrial_itemIs 282")
//                //                print(cTrial_itemIs)
//                if maxI == 0 {  // == 1 in original code
//                    //print("if")
//                    if cTrial_itemIs.count >= 3 {
//                        break
//                    } else {
//                        let efficiency_slice = Array(trialEfficiencies[1..<trialEfficiencies.count])
//                        maxVal = efficiency_slice.max()!
//                        maxIs = find_1d(arr: efficiency_slice, val: maxVal)
//                        maxI = maxIs[Int(ceil(rand()*Double(maxIs.count-1)))] // no -1 in original
//                        cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI]])
//                        //                        print("line 281")
//                        //                        print(cTrial_itemIs)
//                    }
//                } else {
//                    //print("else")
//                    //                    print("maxI 291")
//                    //                    print(maxI)
//                    //                    print("otherItemIs")
//                    //                    print(otherItemIs)
//                    cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI - 1]])
//                    //                    print("line 286")
//                    //                    print(cTrial_itemIs)
//
//                }
//            }
//
//            trialI += 1
//
//            // Idea: wait for <time_limit> seconds OR until user clicks button to get the
//            //       locations of each image
//            // while loop with two OR predicates?
//            round_start_time = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
//
//            let group = DispatchGroup()
//            group.enter()
//            DispatchQueue.global().async {
//                self.drawBackground(stimuli_indices: cTrial_itemIs)
//                group.leave()
//            }
//            // this only executes when # of leaves == # of enters
//            group.notify(queue: .main) {
//                self.wait_for_response()
//                self.finishup(cTrial_itemIs: cTrial_itemIs, trialI: trialI, start: start)
//            }
//
//
//        }
//
//        // start/stop times and durations omitted
//        var data = story()
//        data.distMatsForAllTrials_ltv = distMatsForAllTrials_ltv
//        data.evidenceWeight_ltv = evidenceWeight_ltv
//        data.nsItemsPerTrial = nsItemsPerTrial
//        data.estimate_RDM_ltv = estimate_RDM_ltv
//        return data
//    }
//
//    func finishup(cTrial_itemIs: [Int], trialI: Int, start: Double) {
//        currPos.removeAll(keepingCapacity: true)
//        for pos in self.currentPos.values {
//            currPos.append(pos)
//        }
//        finishClicked = false   // reset finish button state
//        distMat_ltv = pdist(mat: currPos)
//        print("trolled again")
//
//        let stopTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
//        trialStopTimes.append(stopTime)
//        trialDurations.append(stopTime - start)
//
//        nsItemsPerTrial[trialI] = Double(cTrial_itemIs.count)
//        subjectWork_nItemsArranged = subjectWork_nItemsArranged + nsItemsPerTrial[trialI]!
//        let quant = Darwin.pow(nsItemsPerTrial[trialI]!, 2.0) - (nsItemsPerTrial[trialI]!/2.0)
//        subjectWork_nPairsArranged = subjectWork_nPairsArranged + quant
//        subjectWork_nDragsEstimate = subjectWork_nDragsEstimate + Darwin.pow(Darwin.pow(quant, 0.5), dragsExponent)
//
//        var distMatFullSize = nan_grid(num_rows: nItems, num_cols: nItems)
//        distMatFullSize = replace_by_vector_indexing(mat: distMatFullSize, v1: cTrial_itemIs, v2: cTrial_itemIs, val: distMat_ltv)
//        let distMatFullSize_ltv = vectorizeSimmat(mat: distMatFullSize)
//        distMatsForAllTrials_ltv.append(distMatFullSize)                // convert to global var
//
//        //estimate dissimilarity using current evidence
//        let evidence_tuple = estimateRDM(distMats: distMatsForAllTrials_ltv)
//        estimate_RDM_ltv = evidence_tuple[0].flatMap{ $0 }  // verify!
//        evidenceWeight_ltv = evidence_tuple[1]                          // convert to global var
//        // omitted unused variables lines 286-289 in MATLAB script
//
//        minEvidenceWeight = min(mat: evidenceWeight_ltv).min()!
//    }
//
//    func wait_for_response() {
//        //        while finishClicked == false || (Double(DispatchTime.now().uptimeNanoseconds)-start)/1_000_000 < timeLimit {
//        //
//        //        }
//        let now = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
//        if finishClicked == false && (now - round_start_time) < timeLimit {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                self.wait_for_response()
//            }
//        } else {
//            print("finished waiting")
//        }
//    }
//}
