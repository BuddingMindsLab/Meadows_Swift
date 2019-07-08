//
//  TestCircleArenaController.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-05-20.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

import UIKit

class TestCircleArenaController: UIViewController {

    var evidenceUtility_sq_rounded_str = String()
    
    var testSet = [[[Double]]]()
    var randNums = [Double]()
    var randI = 0

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
    let center_y = Double(UIScreen.main.bounds.height) / 2.0 - 38.0
    let radius = 433.0
    let visual_radius = 728.0 / 2.0

    var file_name = ""

    var initialPairI = Int()
    var maxVal = Double()
    var maxI = Int()
    var maxIs = [Int]()
    var cTrial_itemIs_adjusted_index = [Int]()

    @IBAction func btnPressed(_ sender: Any) {
        startTesting()
    }


    // generates test cases for currPos, given n, the index of the artificial test set constant array
    func get_currPos(n: Int) -> [[Double]] {
        return testSet[n]
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


    //get locations of each image after user clicks the Finish button
    func btnPressed_pseudo() {
        // gets the positions of all the labels on screen
        //    for label in view.subviews {
        //        if label.accessibilityIdentifier != nil {
        //            // scale such that arena's diameter corresponds to 1.0
        //            let x = (Double(label.center.x) - center_x) / visual_radius
        //            let y = (Double(label.center.y) - center_y) / visual_radius
        //            currentPos[label.accessibilityIdentifier!] = [x, y]
        //        }
        //    }

        // remaining code of while loop after the waiting for user input phase
        finishup()

        // same functionality as first while loop condition in previous version of startTrial()
        let argument = evidenceWeight_ltv.flatMap{ $0 }

        if (minEvidenceWeight < minRequiredEvidenceWeight && (any(mat: argument, val: 0.0)) || etime(start: start) < maxSessionLength) {
            // remove all labels
            //            for label in view.subviews{
            //                if label.accessibilityIdentifier != nil {
            //                    label.removeFromSuperview()
            //                }
            //            }
            // calculate new stimuli set, process should update cTrial_itemIs
            // this process is done in finishup()
            // draw new labels
            prepare_matrices()
            //drawBackground(stimuli_indices: cTrial_itemIs)
        } else {
            // experiment is finished
            experiment_complete()
            let final_data = get_data_string()
        }
    }


    func startTrialSetup() {
        //useful to have precomputed
        eye_nitems = eye(n: nItems)

        verIs = ndgrid(bounds: [[1,nItems], [1,nItems]])
        horIs = transpose(mat: verIs)
        verIs_ltv = vectorizeSimmat(mat: verIs)
        horIs_ltv = vectorizeSimmat(mat: horIs)
        evidenceWeight_ltv = zeros(size: [1, verIs_ltv.count])
        weakestEvidenceWeights = [[Double]]()       // this too
        meanEvidenceWeights = [[Double]]()

        trialI = 0
    }

    func prepare_matrices() {
//        print("evidenceWeight_ltv")
        //let evidenceWeight_ltv_rounded = matlab_round(mat: evidenceWeight_ltv)
//        print(evidenceWeight_ltv_rounded)
        
        
        let negate = elementWise(op: "*", left: evidenceWeight_ltv, right: -1)
        let etothe = elementWise(op: "*", left: negate, right: evidenceUtilityExponent)
        let exponent = elementWise(op: "exp", left: etothe, right: 1.0)
        let negagain = elementWise(op: "*", left: exponent, right: -1)
        var evidenceUtility_ltv = elementWise(op: "+", left: negagain, right: 1.0)
        var evidenceUtility_sq = squareform(arr: evidenceUtility_ltv.flatMap{ $0 })
        var evidenceLOG_ltv = elementWise(op: ">", left: evidenceUtility_ltv, right: 0.0)
        //        print("line 220")
        //        print(evidenceLOG_ltv)

        if any(mat: evidenceLOG_ltv.flatMap{ $0 } , val: 1.0) {
            var evidenceUtility_sq_nan = evidenceUtility_sq
            //print("line 224")
            //            print(evidenceUtility_sq_nan.count)
            //            print(evidenceUtility_sq_nan[0].count)
            //            print(eye_nitems.count)
            //            print(eye_nitems[0].count)
            evidenceUtility_sq_nan = logical(mat: evidenceUtility_sq_nan, bool_mat: eye_nitems, val: Double.nan)
            var nObjEachObjHasNotBeenPairedWith = nansum(mat: evidenceUtility_sq_nan)

            let repmat_column = nObjEachObjHasNotBeenPairedWith.flatMap{ $0 }
            let lhs = repmat_col(col: repmat_column, row_times: 1, col_times: nItems)
            let rhs = repmat(mat: nObjEachObjHasNotBeenPairedWith, num_row: nItems, num_col: 1)
            var nZeroEvidencePairsReachedByEachPair = matrix_addition(left: lhs, right: rhs)
            //print("line 236")
            //            print(nZeroEvidencePairsReachedByEachPair.count)
            //            print(nZeroEvidencePairsReachedByEachPair[0].count)
            //            print(eye_nitems.count)
            //            print(eye_nitems[0].count)
            nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair, bool_mat: eye_nitems, val: 0.0)
            let nZeroEvidencePairsReachedByEachPair_ltv = inverse_squareform(arr: nZeroEvidencePairsReachedByEachPair)
            let evidenceLOG_inverted = elementWise(op: "~", left: evidenceLOG_ltv, right: 1.0)
            //print("line 244")
            //            print(nZeroEvidencePairsReachedByEachPair.count)
            //            print(nZeroEvidencePairsReachedByEachPair[0].count)
            //            print(evidenceLOG_inverted.count)
            //            print(evidenceLOG_inverted[0].count)

            nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair_ltv, bool_mat: evidenceLOG_inverted, val: 0.0)
//            print("nZeroEvidencePairsReachedByEachPair")
//            print(nZeroEvidencePairsReachedByEachPair)

            let nZero_flat = nZeroEvidencePairsReachedByEachPair.flatMap{ $0 }
            maxVal = nZero_flat.max()!
            maxI = nZero_flat.firstIndex(of: maxVal)!
//            print("maxI First")
//            print(maxI)
            maxIs = find_2d(in_: nZeroEvidencePairsReachedByEachPair, item: maxVal)
//            print("maxIs 212")
//            print(maxIs)
//            print("index 212")
//            print(ceil(num: randNums[randI]*Double(maxIs.count) - 1))
            maxI = maxIs[ceil(num: randNums[randI]*Double(maxIs.count) - 1)]
//            print("maxI Second")
//            print(maxI)
            randI += 1
        } else {
//            print("randNums[randI]")
//            print(randNums[randI])
            initialPairI = ceil(num: randNums[randI]*Double(nPairs) - 1)
            randI += 1
        }
//        print("nPairs")
//        print(Double(nPairs))
//        print("trying to access")
//        print(initialPairI)
        let item1I = verIs_ltv[initialPairI]
        let item2I = horIs_ltv[initialPairI]
//        print("initialPairI")
//        print(initialPairI)
//        print("verIs_ltv")
//        print(verIs_ltv)
//        print("horIs_ltv")
//        print(horIs_ltv)

        cTrial_itemIs = [Int(item1I), Int(item2I)]
//        print("First")
//        print(cTrial_itemIs)
        cTrial_itemIs.sort()

        while Double(cTrial_itemIs.count) < maxNitemsPerTrial {
            //print("are we stuck at 192?")
            var trialEfficiencies = nan_grid(num_rows: nItems - cTrial_itemIs.count + 1, num_cols: 1)[0]     //
//            print("line 230")
//            print(trialEfficiencies)
//            print("dimension")
//            print(nItems - cTrial_itemIs.count + 1)
            //note: verify that the above results in a column vector (1D)
            let otherItemIs = setdiff(A: [Int](1...nItems), B: cTrial_itemIs)
//            print("otherItemIs")
//            print(otherItemIs)
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
                //                    print("cTrial_itemIs is")
                //                    print(cTrial_itemIs)
                //                    print("estimate_RDM_sq")
                //                    print(estimate_RDM_sq)
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
                    
//                    evidenceUtility_sq = matlab_round(mat: evidenceUtility_sq)
//
//                    if trialI >= 1 {
//
//                        var evidenceUtility_sq_rounded = [Double]()
//                        for elem in evidenceUtility_sq.flatMap({ $0 }){
//                            evidenceUtility_sq_rounded.append(round(100000 * elem) / 100000)
//                        }
//
////                        evidenceUtility_sq_rounded_str += "\nevidenceUtility_sq\n"
////                        evidenceUtility_sq_rounded_str += evidenceUtility_sq_rounded.description
////                        print("after part")
////                        print(after_part)
//                    }
                    let utilityBeforeTrial = inverse_squareform(arr: after_part).flatMap{ $0 }.reduce(0, +)
//                    print("before calc")
//                    print(inverse_squareform(arr: after_part))

                    let evidenceWeight_sq = squareform(arr: evidenceWeight_ltv.flatMap{ $0 })

                    //                        print("cTrial_itemIs is")
                    //                        print(cTrial_itemIs)
                    //                        print("evidenceWeight_sq")
                    //                        print(evidenceWeight_sq)
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
//                    print("In if")
//                    print("AfterTrial")
//                    print(utilityAfterTrial)
//                    print("BeforeTrial")
//                    print(utilityBeforeTrial)
                    utilityBenefit = utilityAfterTrial - utilityBeforeTrial
//                    print("utilityAferTrial 316")
//                    print(utilityAfterTrial)
                    //                    print("before")
                    //                    print(utilityBeforeTrial)
                } else {
//                    print("In else")
                    utilityBenefit = 0.0
                }
                let trialCost = Darwin.pow(Double(cTrial_itemIs.count), dragsExponent)
                //                    print(trialEfficiencies)
                //                    print("itemSetI is")
                //                    print(itemSetI)
                //                print("line 333")
                //                print(trialEfficiencies)
//                print("two numbers")
//                print(utilityBenefit)
//                print(trialCost)
                trialEfficiencies[itemSetI] = utilityBenefit / trialCost
                cTrial_itemIs = setdiff(A: cTrial_itemIs, B: itemAddedI)
//                print("Second")
//                print(cTrial_itemIs)
//                cTrial_itemIs.sort()

                if itemSetI == otherItemIs.count {  // original code contains +1, which is deleted here
                    break
                }
                //                    print("otherItems")
                //                    print(otherItemIs)
                //                    print("index_itemset")
                //                    print(itemSetI)
                itemAddedI = [otherItemIs[itemSetI]]
                //                    print("input A")
                //                    print(cTrial_itemIs)
                //                    print("input B")
                //                    print(itemAddedI)
                cTrial_itemIs = union(A: cTrial_itemIs, B: itemAddedI)
//                print("Third")
//                print(cTrial_itemIs)
//                cTrial_itemIs.sort()
                itemSetI += 1
            }

            var maxVal = trialEfficiencies.max()!
//            print("line top")
//            print(trialEfficiencies)
            maxIs = find_1d(arr: trialEfficiencies, val: maxVal)
//            print("trialEfficiencies") // why does this start at 34 in MATLAB
            // on second round of choosing cTrial_itemIs, second <Fifth>
            // Fix: changed matlab code from find(a==b) to find(abs(a-b)<0.001)
//            print(trialEfficiencies)
//            print("maxVal")
//            print(maxVal)
//            print("rand3")
//            print(Double(maxIs.count-1))
//            print("maxIs 365")
//            print(maxIs)
//            print("index 365")
//            print(Int(ceil(randNums[randI]*Double(maxIs.count) - 1)))
//            print("Double(maxIs.count-1)")
//            print(Double(maxIs.count - 1))
//            print("randNums[randI]")
//            print(randNums[randI])
            maxI = maxIs[Int(ceil(randNums[randI]*Double(maxIs.count) - 1))]   // no -1 in original
//            print("maxI Third")
//            print(maxI)
            randI += 1
            //                print("maxIs 277")
            //                print(maxIs)
            //                print("maxIs 279")
            //                print(maxIs)
            //                print("cTrial_itemIs 282")
            //                print(cTrial_itemIs)
            if maxI == 1 {  // == 1 in original code
                //print("if")
                if cTrial_itemIs.count >= 3 {
                    break
                } else {
                    let efficiency_slice = Array(trialEfficiencies[1..<trialEfficiencies.count])
                    maxVal = efficiency_slice.max()!
                    maxIs = find_1d(arr: efficiency_slice, val: maxVal)
//                    print("rand4")
//                    print(Double(maxIs.count-1))
                    maxI = maxIs[Int(ceil(randNums[randI]*Double(maxIs.count) - 1))] // no -1 in original
//                    print("maxI Fourth")
//                    print(maxI)
                    randI += 1
                    cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI - 1]])
//                    print("Fourth")
//                    print(cTrial_itemIs)
                    cTrial_itemIs.sort()
                }
            } else {
                //print("else")
//                print("maxI Fifth")
//                print(maxI)
//                print("otherItemIs")
//                print(otherItemIs)
                cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI - 2]])
//                print("Fifth")
//                print(cTrial_itemIs)
                cTrial_itemIs.sort()
            }
        }
        cTrial_itemIs.sort()    // it seems that this variable in MATLAB is sorted
        trialI += 1

//        print("cTrial_itemIs")
//        print(cTrial_itemIs)
    }

    func experiment_complete() {
        // start/stop times not included in story
        let final_result = estimateRDM(distMats: distMatsForAllTrials_ltv)
        evidenceWeight_ltv = final_result[1]
        estimate_RDM_ltv = final_result[0].flatMap{ $0 }
    }


    func finishup() {
        currPos.removeAll(keepingCapacity: true)
        //        print("currentPos")
        //        print(currentPos)
        //    for pos in currentPos.values {
        //        currPos.append(pos)
        //    }
        currPos = get_currPos(n: trialI)
//        print("currPos 405")
//        print(currPos)
        distMat_ltv = pdist(mat: currPos)
//        print("distMat_ltv 408")
//        print(distMat_ltv)
        //print("trolled again")
        //        print("distMat_ltv")
        //        print(distMat_ltv)
        //        print("currPos")
        //        print(currPos)
        //        print("cTrial_itemIs")
        //        print(cTrial_itemIs)

        let stopTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000.0
        trialStopTimes.append(stopTime)
        trialDurations.append(stopTime - start)

        nsItemsPerTrial[trialI] = Double(cTrial_itemIs.count)
        subjectWork_nItemsArranged = subjectWork_nItemsArranged + nsItemsPerTrial[trialI]!
        let quant = Darwin.pow(nsItemsPerTrial[trialI]!, 2.0) - (nsItemsPerTrial[trialI]!/2.0)
        subjectWork_nPairsArranged = subjectWork_nPairsArranged + quant
        subjectWork_nDragsEstimate = subjectWork_nDragsEstimate + Darwin.pow(Darwin.pow(quant, 0.5), dragsExponent)

        var distMatFullSize = nan_grid(num_rows: nItems, num_cols: nItems)
        let squared = squareform(arr: distMat_ltv)
        let flat_distMat = squared.flatMap{$0}
        //        print("replace by vector indexing")
        //        print("distMatFullSize")
        //        print(distMatFullSize)
        //        print("cTrial_itemIs")
        //        print(cTrial_itemIs)
        //        print("flattened matrix")
        //        print(flat_distMat)
        cTrial_itemIs_adjusted_index = cTrial_itemIs.compactMap{$0 - 1}
        cTrial_itemIs_adjusted_index.sort()
        distMatFullSize = replace_by_vector_indexing(mat: distMatFullSize, v1: cTrial_itemIs_adjusted_index, v2: cTrial_itemIs_adjusted_index, val: flat_distMat)
        let distMatFullSize_ltv = vectorizeSimmat(mat: distMatFullSize)
        distMatsForAllTrials_ltv.append(distMatFullSize)
//        print("distMatsForAllTrials_ltv 450")
//        print(distMatsForAllTrials_ltv)
        //estimate dissimilarity using current evidence
        let evidence_tuple = estimateRDM(distMats: distMatsForAllTrials_ltv)
        estimate_RDM_ltv = evidence_tuple[0].flatMap{ $0 }  // verify!
//        print("estimate_RDM_ltv 447")
//        print(estimate_RDM_ltv)
        evidenceWeight_ltv = evidence_tuple[1]
        print("evidenceWeight_ltv 450")
        print(evidenceWeight_ltv)
        // omitted unused variables lines 286-289 in MATLAB script

        minEvidenceWeight = min(mat: evidenceWeight_ltv).min()!

//        print("data_string 453")
//        print(get_data_string())
    }

    // make sure you know the order of the stimuli in the results
    //converts the current data into a string for emailing and csv file writing
    func get_data_string() -> String {
        var result = ""
        var estimate = "Final_estimate_RDM_ltv\n"
        //estimate_RDM_ltv = matlab_round(mat: [estimate_RDM_ltv])[0]
        for i in 0..<estimate_RDM_ltv.count{
            estimate_RDM_ltv[i] = round(1000 * estimate_RDM_ltv[i]) / 1000
        }
        estimate += (estimate_RDM_ltv.map{String($0)}).joined(separator: " ") + "\n"
        var evidence = "Final_evidenceWeight_ltv\n"
        //evidenceWeight_ltv = matlab_round(mat: evidenceWeight_ltv)
        for i in 0..<evidenceWeight_ltv.count{
            for j in 0..<evidenceWeight_ltv[0].count{
                evidenceWeight_ltv[i][j] = round(1000 * evidenceWeight_ltv[i][j]) / 1000
            }
        }
        for sub_evidence in evidenceWeight_ltv {
            let cEvidence = sub_evidence.map{String($0)}.joined(separator: " ")
            evidence = evidence + cEvidence
        }
        evidence += "\n"
//        var durations = "trialDurations\n"
//        durations += trialDurations.map{String($0)}.joined(separator: ",") + "\n\n\n"
        var distMats = "Final_distMatsForAllTrials_ltv\n"
        for i in 0..<distMatsForAllTrials_ltv.count{
            //distMatsForAllTrials_ltv[i] = matlab_round(mat: distMatsForAllTrials_ltv[i])
            for j in 0..<distMatsForAllTrials_ltv[0].count{
                for k in 0..<distMatsForAllTrials_ltv[0][0].count{
                    distMatsForAllTrials_ltv[i][j][k] = round(1000 * distMatsForAllTrials_ltv[i][j][k]) / 1000
                }
            }
        }
        for i in 0..<distMatsForAllTrials_ltv.count {
            //distMats += "Layer " + String(i+1) + "\n"
            for vec in distMatsForAllTrials_ltv[i] {
                distMats += vec.map{String($0)}.joined(separator: " ")
            }
            //distMats += "\n"
        }
        //result = estimate + evidence + durations + distMats
        result = estimate + evidence + distMats
        //print(result)
        return result
    }


    // Test cases (instead of waiting for user input, feed currPos as artificial input)
    // currPos --> need random numbers between -1 and 1 in form [[x1, y1], ..., [xn, yn]]
    func setTestSet() {
        testSet = [[[-0.47574590062771893, 0.6682920107229295], [0.9498516139040716, 0.8178013277468763], [-0.883351179590929, -0.8925415421279062], [0.6569846503554722, -0.1723846601460466], [0.45527871462463865, 0.5180771211272932], [-0.4212044356063249, -0.25462264304388116], [0.44563099762616587, 0.903468954920871], [-0.7882176465672521, -0.10830097544045159], [0.88565629013524, 0.12909032195835968], [0.4980733987023058, -0.6034542090938828], [-0.00804164333516133, 0.6873706776469679], [0.19999819290054788, 0.7672876807045841]], [[-0.814752230207324, 0.9530336241147703], [-0.0007826957015832914, 0.5344949960378613], [-0.7008095457819825, 0.6342089972261908], [-0.4982895917215473, -0.9545986593280509], [0.6110782307330134, -0.35301398240471005], [-0.09444074852252338, 0.37112970125632216], [0.31019630800021813, 0.32312571376816135], [0.32612445821008573, 0.41682842692273625], [0.47768356294228176, 0.4950296132681413], [0.9734589701578087, 0.6386905919029504], [-0.8625777788080693, 0.35043794871421063], [0.019077025917328072, 0.44213533673324634]], [[0.10615403991782246, 0.1390327139544143], [-0.19351914550085403, -0.9423466963978717], [0.3263879133073897, 0.653704275521183], [-0.8173532190734616, -0.4608109095014403], [0.4735967934610972, -0.3623289154621758], [-0.8965704353610007, -0.18560266519096214], [-0.8606322808580495, 0.3142974861395813], [0.6548035086046975, -0.9628041823109132], [-0.8460878711853785, -0.31747466684662684], [-0.621713352689401, 0.155123444261132], [0.007480935495890684, -0.9088870773011939], [0.7013252410711082, 0.9937528242679206]], [[-0.05212276521993964, 0.7441676280942238], [0.945218751579064, 0.9129523264802608], [-0.019716321956061655, -0.9448603458978238], [-0.5636228468035531, 0.3994944167421093], [-0.5127195681287833, -0.06631648743320873], [-0.9126250488062337, -0.9649473639882313], [-0.818683997322909, -0.5784988481932363], [0.44118230340045317, -0.6726453175312128], [-0.640441082812008, -0.8325178295418829], [0.052691151470848574, 0.29011191793004754], [0.4570905768476159, -0.22343982849978405], [-0.5844056279812357, 0.8159949338078447]], [[0.10555196217275187, -0.47215553077418604], [0.5879751972929608, 0.5343111955516744], [-0.6987974346836288, -0.18696096655070638], [0.2951071312667297, 0.6752356665344961], [-0.2993443976151302, -0.23704352998687894], [-0.5863928729270997, 0.3153215755965255], [0.6976425251777101, -0.31147916090780736], [-0.12770571196847436, 0.25022818615669573], [0.08962324649228348, 0.9155389648116172], [0.8045749315042032, -0.677602920571226], [0.8534792326503051, -0.23623778695307496], [0.39598573137217397, 0.7370044896988874]], [[-0.626941329652063, -0.4250799244248509], [-0.6448920851317634, -0.2823380413102261], [-0.1513100247687369, 0.2893875207003693], [-0.7010638641322362, -0.42094612496218664], [-0.6356614482992964, -0.5469411831224027], [0.9909661114702764, 0.11453339368491533], [0.8697962837803987, 0.6717413387379758], [0.3180904322060272, 0.8213428511548033], [0.46778281462349147, 0.0860161172616849], [0.03765200119118006, 0.18629932036592223], [-0.3747537269472532, -0.6312463401660795], [-0.026957812759059507, 0.1413430748855633]], [[-0.6849085111991089, -0.15117372595036405], [0.9790213748339882, 0.5812688388163569], [-0.26849109981619645, 0.12688309071474024], [0.4956037890595324, -0.21327153881441796], [-0.306632946895254, 0.9839821025521625], [0.7092960711061413, 0.05837137475545995], [0.3155557134081106, -0.7400884312757272], [-0.4156379009550528, 0.3681143858135685], [0.4733455357586682, -0.43393986897976844], [-0.5480744897653196, -0.4019214131108504], [-0.7334494791345423, -0.9244388165962649], [-0.875276324361262, -0.6463514455853294]], [[0.008802101142370677, -0.7507060560357219], [0.5569145808009086, 0.5244368146796312], [0.5583172055610803, -0.17682200332204023], [-0.8939000018428067, -0.44264170946450077], [0.42218388537912177, 0.01830998936552186], [0.3075826751364006, 0.0389030724146231], [0.1210422095569661, 0.7780787105990459], [-0.793882858011834, 0.17558629918014246], [0.24339950150875533, -0.20055342330197257], [0.509024872407527, 0.10641191713167109], [-0.057582547946155804, -0.747405529449443], [0.9175021191886465, 0.34833094653602825]], [[0.3972401175469147, -0.5133494897510888], [0.9396406575394634, 0.8276464298815558], [-0.9407943530321259, -0.26316511442396995], [-0.0013226412929845388, 0.6839211051712908], [0.004586631444985834, 0.28506650164659897], [-0.010953527017794507, 0.8693846014965452], [-0.4700735836696084, 0.7285472185324895], [-0.5207916321116743, 0.5972253571647703], [0.616324616591396, -0.903056686047516], [0.00029386145674648034, -0.16608029692465598], [-0.8884593699972085, -0.22488488763538395], [-0.13562317840779436, -0.8609161899990376]], [[-0.5203955467632695, -0.5775252006926783], [-0.5466391594450408, 0.10159448938899507], [-0.054632186250132, -0.6443440993553446], [0.4191284666003827, 0.5561178047133681], [0.18131985313339438, -0.6503933738256598], [-0.8273135035446679, 0.7870291301042291], [-0.3125907808504311, -0.48454184450685145], [-0.3587085356871984, 0.13765008875395934], [-0.11244650474828455, -0.8808568404976267], [-0.07419909666930646, -0.0904679419110237], [-0.9980697378142032, -0.004530318672007372], [-0.17884687307261005, -0.18069592934262513]], [[-0.4919689704950174, 0.8734347376050495], [0.9950220048848961, -0.9882728207198426], [-0.8994717869943012, -0.2651508265057927], [0.7610523840688148, -0.6840524603374709], [0.6656900008816511, 0.6499821950402571], [-0.34918264312699065, -0.743661764599741], [-0.8749396911767036, -0.3423366678667945], [0.18517913208604386, -0.4001639305479052], [0.2755127153744954, 0.875612600166209], [0.07523835754877473, 0.7380933286775337], [0.13323684060020358, -0.6623291420406325], [-0.9002164934783261, -0.5572211759882397]], [[-0.6746135134050573, 0.22679138005395227], [-0.8212347517320526, -0.052500659094695035], [0.2416103310976152, 0.747816491848682], [0.39320635480806976, 0.5822590980959186], [-0.8199662002732047, -0.389410534518841], [-0.4335651829682603, -0.726112597075534], [-0.8045989292551643, -0.36345995816909027], [0.14233500157302292, 0.8827723020965053], [-0.5966090538732434, -0.3266246715282306], [-0.954339760366254, 0.856417016696333], [-0.47440080696586984, -0.31922343375178786], [-0.3804363829368014, 0.8541463864947729]], [[0.13586479279282204, 0.632772088825478], [-0.7290958598550799, 0.1736182677733613], [-0.9276280724309847, -0.7673244783930901], [0.042087722712073505, -0.908227662317119], [0.29126724866201537, -0.9954243564044116], [0.7885028675745125, 0.7529536775087309], [-0.051337503389269123, 0.3682923791006849], [0.11820249424498175, -0.2589739836606366], [-0.6119464361922025, -0.796683817803667], [-0.32865744088891025, -0.02289459679178618], [0.26370367081027735, 0.25832221231423835], [0.3291521935540087, 0.24115085432976868]], [[0.5101511002536785, -0.23407053835499747], [-0.5224225680183798, -0.8097560756715798], [0.27054370903796654, -0.09043321584005226], [-0.7672285749085768, 0.8189685334453793], [-0.09594479817678492, 0.11891938383145306], [0.45419116543360594, 0.09616966219398049], [0.3719924205414993, -0.47927777221684176], [-0.1925799550819347, -0.41082753693777874], [-0.9943796026653584, 0.3492297854889501], [-0.11533070212344132, 0.005549391271281401], [-0.07906628415767525, -0.8493914744125084], [-0.5569534530170057, 0.44332831201411826]], [[0.8465339197040429, 0.2625766950390376], [0.21958220391717442, -0.3342470337681145], [0.17258099458556808, -0.4628148019278091], [0.25970342390910783, -0.7995103401662875], [-0.12669048287123763, 0.3286479090005574], [-0.8532414071904966, -0.10826188429254668], [0.9189106168924555, -0.9363527127902258], [0.6801942293960159, 0.011047821271049862], [-0.2678544850811302, 0.07324272787837427], [0.4510782765111654, 0.35810063944675896], [0.07461344840602835, -0.8845735896892257], [-0.27399630096725724, 0.9479669542245073]], [[0.3042082079005728, -0.8823329877434949], [0.9548999127465914, 0.38390702598598625], [0.9285758477660948, -0.5369950853465861], [-0.8929167802674081, -0.33494080263082027], [-0.9757108122150899, 0.47690984039366646], [0.9216335510794815, -0.48022711205091695], [-0.36866658802496355, 0.13250751203654043], [0.21421765661446024, -0.6669061765565625], [-0.2347028227895871, -0.8911438174880433], [-0.5831381914647165, -0.6983479207929564], [0.7307319928520597, 0.07358405235271626], [0.0843456519467003, 0.319010057572648]], [[0.6230255076889895, -0.6568902656052074], [-0.485346540569789, 0.6862100943518503], [0.8697366348162525, 0.9210602629927469], [-0.9610387414475323, -0.8944413057414049], [-0.09265106022546177, -0.9653330351241678], [-0.36768879365034457, -0.13312498751142665], [0.1961505046108143, -0.07024359905970279], [0.3586407645489391, 0.544156518007413], [0.7641463791125656, 0.515775773688556], [0.13380754132699324, 0.39248186391003936], [-0.732944803777279, 0.5003870143597098], [-0.2630385784597633, 0.6488281653623247]], [[-0.9412463668953794, -0.4256473360770814], [0.7294441684168267, 0.5517006769849173], [-0.5046679420537221, -0.5860899173091918], [0.8038899030278179, 0.6715037059752431], [-0.47761347074376337, 0.6942476437086456], [0.34495601605203197, 0.1132380920728413], [-0.7738797687664016, -0.9469588440292886], [-0.3445872824775027, 0.5305751232731097], [-0.23305821182520825, 0.7558624557222167], [0.0161660253653797, -0.14214889662938313], [0.9212069869237927, -0.7167116381201886], [-0.37137135309014746, -0.3316748521785984]], [[0.4746977951032809, -0.06885768788375457], [0.32720869624178617, -0.4421564909284801], [-0.29214709850034737, -0.7919542114134892], [0.5841574302155086, -0.4564846800633995], [0.5348828872510711, -0.08982811785190781], [-0.36318986978078605, -0.07785282927756487], [0.08301258655389243, 0.645923072163904], [-0.37074405262149757, -0.2792956839476861], [0.8271311984922238, -0.854217467818396], [0.24387519870922025, 0.6958299155019847], [0.0733301896469416, 0.970925581941428], [0.8836374233316848, -0.03237944232830858]], [[-0.24032847785000633, -0.7067776537428199], [-0.7300595013618925, 0.19827357843382587], [-0.04775296732694656, -0.0691764919026836], [-0.5077122464218362, -0.7757056721007642], [-0.36151686253311843, -0.20763175158117497], [0.36737432120051383, 0.9163647481723547], [-0.6453029403506061, -0.9872088987408851], [0.6568409583804908, -0.1475622542245878], [-0.4051670063818511, -0.4567707494273734], [-0.5503167147973076, 0.8503970086690693], [-0.37682446274697523, -0.2926549506135929], [0.282406082136045, 0.7089782489674399]]]
    }

    func setRandNums() {
        randNums = [0.6006966286213917, 0.9200912867178763, 0.5875305444028074, 0.5011086861071219, 0.7957966987264736, 0.8417423281439527, 0.8453939604821639, 0.5908497652123952, 0.99812077762944, 0.7331843827189659, 0.4048923274704891, 0.2212536109295088, 0.13084136587190132, 0.9758465117316119, 0.1538669284808335, 0.8250638789385106, 0.12006757298108373, 0.45323718205598484, 0.3946925362034852, 0.41164113780737166, 0.27919349042272745, 0.8341785222053661, 0.9193968022115068, 0.36590248226453825, 0.4531691476107934, 0.5021622256093301, 0.17919773492642843, 0.022400793631311977, 0.5711896056906971, 0.6463529715234152, 0.21549252050354284, 0.29053934569441076, 0.6405258997930529, 0.755692318520558, 0.10694141704451132, 0.5827820460846121, 0.45687700745479887, 0.033801451881259714, 0.1477050724452742, 0.9733298484041135, 0.15392591148375956, 0.9009711637846058, 0.25334703610382014, 0.6424734244232466, 0.9998044242927873, 0.7449252550086429, 0.13284285072456037, 0.3998277687630495, 0.7579158570750965, 0.9604186026079494, 0.8506136213434239, 0.7138929910578802, 0.615758075073728, 0.5337571656327066, 0.22023368873239846, 0.7669823111795744, 0.6559799729059768, 0.24653201330577013, 0.7982297454940144, 0.13091306203477515, 0.03713067256730673, 0.6258816311910165, 0.9375227852492451, 0.6412227809818929, 0.08684756073757915, 0.367070151346659, 0.13869665694169642, 0.5493210352325151, 0.24830532834620112, 0.7004429886967872, 0.07597326450880526, 0.2738470789232117, 0.488933876479724, 0.08209361674708093, 0.8155887036131702, 0.7573079365911726, 0.8630414674333609, 0.7865479406877421, 0.5936901528104196, 0.8963105349978866, 0.8651550964183129, 0.3856655725536775, 0.2733876113844719, 0.15856657533694074, 0.6519476832617485, 0.3809014992527553, 0.42130591436689246, 0.3309350291712766, 0.7934491787565889, 0.8411688248524196, 0.7185504831951827, 0.10798635526110822, 0.16624846493218104, 0.8620697560101516, 0.5149002640322152, 0.8544878060270567, 0.8560121697275872, 0.04682154775150571, 0.654183362700069, 0.9964175770533703, 0.962070536868954, 0.16328287567009359, 0.8936969352419378, 0.3869595434702685, 0.3807586059855069, 0.09967700031383597, 0.26316146287076514, 0.20869629294928638, 0.6369812598884576, 0.8426889424246283, 0.6239609711500251, 0.9463458925504086, 0.46784516735072257, 0.013972463059703566, 0.9321035750327528, 0.42456379379653153, 0.9687111347015015, 0.2573768375128582, 0.7868293433302486, 0.3311341969669096, 0.08190433685047127, 0.26723002141673324, 0.057958793461975744, 0.8137673475869731, 0.01619349146917859, 0.0978984839448015, 0.9609049901776036, 0.6231598867963536, 0.43686139133281665, 0.8907808366482537, 0.7962912269866345, 0.4558094987184732, 0.17195967888304964, 0.09731296615876028, 0.3041893747217086, 0.1539010482682005, 0.04233642045230401, 0.4770907428500839, 0.45710876559159797, 0.3257138314512391, 0.7733027098142633, 0.5239728955252653, 0.7452642919039726, 0.5817410841857422, 0.8336018630405205, 0.380120994311409, 0.8634763454748792, 0.2863975391521697, 0.5351845474357788, 0.8908137484633946, 0.6174073179069981, 0.4154433038391563, 0.4909771877212292, 0.3843094591022326, 0.7189671864010913, 0.30456152493645594, 0.16392647153982776, 0.3549222444612459, 0.546200256253712, 0.46620130958973094, 0.9176336054067669, 0.6374144888818549, 0.8159520378759477, 0.4543541684043513, 0.534910917571243, 0.9888845900045248, 0.7665489349669037, 0.22357966639331184, 0.5332554521482489, 0.12577935415927066, 0.49483536766921166, 0.8673825710481445, 0.8659289137998362, 0.3772734030263386, 0.6612942368594706, 0.5155530749743913, 0.4003546754618059, 0.021412554013243823, 0.21955556269140697, 0.5192885613134656, 0.11994611759100848, 0.718522404354113, 0.07707030210908472, 0.37755234877283206, 0.13343526003606243, 0.7212870230318525, 0.9922244835479993, 0.730491711933474, 0.7245800516205751, 0.7753687790637716, 0.4377146247886917, 0.0719780955539766, 0.396143975997449, 0.6607956142632397, 0.5121786010030975, 0.07339938190853201, 0.573284952822564, 0.3267177202796855, 0.17320763311201093, 0.799073630256068, 0.024314482572966867, 0.3192126146610822, 0.7026974917726924, 0.7594588270968233, 0.8840218689074147, 0.30163057857073916, 0.9458216798528049, 0.8552416015110862, 0.339774541343394, 0.19936590258383113, 0.4173092900548383, 0.36324954586399794, 0.16902221438941822, 0.06202958210948051, 0.6081279466060048, 0.2897180696309668, 0.6959295253699856, 0.9190889479595403, 0.6178250881928384, 0.13890435982451999, 0.8901006040956086, 0.7806449129576257, 0.5995696704713754, 0.6079075164274192, 0.8616025040388356, 0.4442162214665224, 0.9548321996429404, 0.8641894344923143, 0.9123864746798325, 0.26267820420113186, 0.5676095999426216, 0.95333535311374, 0.4259729001710867, 0.9411140884047976, 0.7619754439895695, 0.08162173822914454, 0.906041108412239, 0.13692609207598094, 0.9015536906341253, 0.27178871642462477, 0.9265616005787652, 0.39612692303437314, 0.7056638535871517, 0.9399137138848184, 0.5215572966300656, 0.21347720234177336, 0.691348310778994, 0.5265739337672665, 0.9068841776276668, 0.9599512173385896, 0.8929320533068228, 0.6986210004999106, 0.40536039338518093, 0.9119191470587127, 0.39746660259876687, 0.27365521492512024, 0.7068232317313486, 0.6165762820153273, 0.6393371174980864, 0.46585869697543003, 0.21406533380795623, 0.8762843392630638, 0.7749667307517695, 0.7525098323838897, 0.3548389605389709, 0.8981819607108593, 0.24476147403189497, 0.6180859120150641, 0.38961821639585437, 0.1751977531011617, 0.7767774553059354, 0.8125302164909002, 0.35204590653735357, 0.9846332985071599, 0.9767780332167083, 0.11810646718072804, 0.13856961285899727, 0.9308473795766179, 0.18245681429424, 0.5348625648651321, 0.8729216621455346, 0.35576075934119744, 0.7607869288197728, 0.7461016598516679, 0.3624028052851137, 0.9051563291146273, 0.2689517298200833, 0.26490465806248553, 0.8175821513792338, 0.09536549443481301, 0.965835584889003, 0.9557909458873355, 0.6212072340411012, 0.31152935592471787, 0.33239610291928223, 0.269321055654709, 0.20220440500425496, 0.32472489873513555, 0.8209916153160943, 0.07684691242094388]
    }

    override func viewDidLoad() {
        // fill in dictionary with nil values
        for word in stimuli {
            currentPos[word] = nil
        }

        nItems = stimuli.count
        nPairs = nItems * (nItems - 1) / 2   // pairs = n(n-1)/2

        file_name = subjectID + ".csv"

        startTrialSetup()   // was originally part of viewDidAppear
    }


    func startTesting() {
        setTestSet()
        setRandNums()
        prepare_matrices()
        
        for i in 1...2 {
//            print("Test iteration")
//            print(i)
            btnPressed_pseudo()
        }
        experiment_complete()
        print(get_data_string())
        print("experiment complete")
    }

}
