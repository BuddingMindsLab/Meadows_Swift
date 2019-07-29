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
    var maxNitemsPerTrial = 3
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

    @IBAction func earlyFinish(_ sender: Any) {
        experiment_complete()
        let final_data = get_data_string()
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
            maxI = maxIs[ceil(num: randNums[randI]*Double(maxIs.count) - 1)]
            randI += 1
        } else {
            initialPairI = ceil(num: randNums[randI]*Double(nPairs) - 1)
            randI += 1
        }
        let item1I = verIs_ltv[initialPairI]
        let item2I = horIs_ltv[initialPairI]
        cTrial_itemIs = [Int(item1I), Int(item2I)]
        cTrial_itemIs.sort()

        while Double(cTrial_itemIs.count) < 3 {
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
            maxI = maxIs[Int(ceil(randNums[randI]*Double(maxIs.count) - 1))]   // no -1 in original
            randI += 1
            if maxI == 1 {  // == 1 in original code
                //print("if")
                if cTrial_itemIs.count >= 3 {
                    break
                } else {
                    let efficiency_slice = Array(trialEfficiencies[1..<trialEfficiencies.count])
                    maxVal = efficiency_slice.max()!
                    maxIs = find_1d(arr: efficiency_slice, val: maxVal)
                    maxI = maxIs[Int(ceil(randNums[randI]*Double(maxIs.count) - 1))] // no -1 in original
                    randI += 1
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
        currPos = get_currPos(n: trialI)
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
        let squared = squareform(arr: distMat_ltv)
        let flat_distMat = squared.flatMap{$0}
        cTrial_itemIs_adjusted_index = cTrial_itemIs.compactMap{$0 - 1}
        cTrial_itemIs_adjusted_index.sort()
        distMatFullSize = replace_by_vector_indexing(mat: distMatFullSize, v1: cTrial_itemIs_adjusted_index, v2: cTrial_itemIs_adjusted_index, val: flat_distMat)
        
        var distMatFullSize_ltv = vectorizeSimmat(mat: distMatFullSize)
        distMatsForAllTrials_ltv.append(distMatFullSize_ltv)
        //estimate dissimilarity using current evidence
        let evidence_tuple = estimateRDM(distMats: distMatsForAllTrials_ltv)
        estimate_RDM_ltv = evidence_tuple[0].flatMap{ $0 }  // verify!
        print("estimate_RDM_ltv")
        print(estimate_RDM_ltv)
        evidenceWeight_ltv = evidence_tuple[1]
        print("evidenceWeight_ltv")
        print(evidenceWeight_ltv)
        // omitted unused variables lines 286-289 in MATLAB script

        minEvidenceWeight = min(mat: evidenceWeight_ltv).min()!

        trialI += 1
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
        testSet = [[[-0.47574590062771893, 0.6682920107229295], [0.9498516139040716, 0.8178013277468763], [-0.883351179590929, -0.8925415421279062]], [[-0.814752230207324, 0.9530336241147703], [-0.0007826957015832914, 0.5344949960378613], [-0.7008095457819825, 0.6342089972261908]], [[0.10615403991782246, 0.1390327139544143], [-0.19351914550085403, -0.9423466963978717], [0.3263879133073897, 0.653704275521183]], [[-0.05212276521993964, 0.7441676280942238], [0.945218751579064, 0.9129523264802608], [-0.019716321956061655, -0.9448603458978238]], [[0.10555196217275187, -0.47215553077418604], [0.5879751972929608, 0.5343111955516744], [-0.6987974346836288, -0.18696096655070638]], [[-0.626941329652063, -0.4250799244248509], [-0.6448920851317634, -0.2823380413102261], [-0.1513100247687369, 0.2893875207003693]], [[-0.6849085111991089, -0.15117372595036405], [0.9790213748339882, 0.5812688388163569], [-0.26849109981619645, 0.12688309071474024]], [[0.008802101142370677, -0.7507060560357219], [0.5569145808009086, 0.5244368146796312], [0.5583172055610803, -0.17682200332204023]], [[0.3972401175469147, -0.5133494897510888], [0.9396406575394634, 0.8276464298815558], [-0.9407943530321259, -0.26316511442396995]], [[-0.5203955467632695, -0.5775252006926783], [-0.5466391594450408, 0.10159448938899507], [-0.054632186250132, -0.6443440993553446]], [[-0.4919689704950174, 0.8734347376050495], [0.9950220048848961, -0.9882728207198426], [-0.8994717869943012, -0.2651508265057927]], [[-0.6746135134050573, 0.22679138005395227], [-0.8212347517320526, -0.052500659094695035], [0.2416103310976152, 0.747816491848682]], [[0.13586479279282204, 0.632772088825478], [-0.7290958598550799, 0.1736182677733613], [-0.9276280724309847, -0.7673244783930901]], [[0.5101511002536785, -0.23407053835499747], [-0.5224225680183798, -0.8097560756715798], [0.27054370903796654, -0.09043321584005226]], [[0.8465339197040429, 0.2625766950390376], [0.21958220391717442, -0.3342470337681145], [0.17258099458556808, -0.4628148019278091]], [[0.3042082079005728, -0.8823329877434949], [0.9548999127465914, 0.38390702598598625], [0.9285758477660948, -0.5369950853465861], [-0.8929167802674081, -0.33494080263082027], [-0.9757108122150899, 0.47690984039366646], [0.9216335510794815, -0.48022711205091695], [-0.36866658802496355, 0.13250751203654043], [0.21421765661446024, -0.6669061765565625], [-0.2347028227895871, -0.8911438174880433], [-0.5831381914647165, -0.6983479207929564], [0.7307319928520597, 0.07358405235271626], [0.0843456519467003, 0.319010057572648]], [[0.6230255076889895, -0.6568902656052074], [-0.485346540569789, 0.6862100943518503], [0.8697366348162525, 0.9210602629927469], [-0.9610387414475323, -0.8944413057414049], [-0.09265106022546177, -0.9653330351241678], [-0.36768879365034457, -0.13312498751142665], [0.1961505046108143, -0.07024359905970279], [0.3586407645489391, 0.544156518007413], [0.7641463791125656, 0.515775773688556], [0.13380754132699324, 0.39248186391003936], [-0.732944803777279, 0.5003870143597098], [-0.2630385784597633, 0.6488281653623247]], [[-0.9412463668953794, -0.4256473360770814], [0.7294441684168267, 0.5517006769849173], [-0.5046679420537221, -0.5860899173091918], [0.8038899030278179, 0.6715037059752431], [-0.47761347074376337, 0.6942476437086456], [0.34495601605203197, 0.1132380920728413], [-0.7738797687664016, -0.9469588440292886], [-0.3445872824775027, 0.5305751232731097], [-0.23305821182520825, 0.7558624557222167], [0.0161660253653797, -0.14214889662938313], [0.9212069869237927, -0.7167116381201886], [-0.37137135309014746, -0.3316748521785984]], [[0.4746977951032809, -0.06885768788375457], [0.32720869624178617, -0.4421564909284801], [-0.29214709850034737, -0.7919542114134892], [0.5841574302155086, -0.4564846800633995], [0.5348828872510711, -0.08982811785190781], [-0.36318986978078605, -0.07785282927756487], [0.08301258655389243, 0.645923072163904], [-0.37074405262149757, -0.2792956839476861], [0.8271311984922238, -0.854217467818396], [0.24387519870922025, 0.6958299155019847], [0.0733301896469416, 0.970925581941428], [0.8836374233316848, -0.03237944232830858]], [[-0.24032847785000633, -0.7067776537428199], [-0.7300595013618925, 0.19827357843382587], [-0.04775296732694656, -0.0691764919026836], [-0.5077122464218362, -0.7757056721007642], [-0.36151686253311843, -0.20763175158117497], [0.36737432120051383, 0.9163647481723547], [-0.6453029403506061, -0.9872088987408851], [0.6568409583804908, -0.1475622542245878], [-0.4051670063818511, -0.4567707494273734], [-0.5503167147973076, 0.8503970086690693], [-0.37682446274697523, -0.2926549506135929], [0.282406082136045, 0.7089782489674399]]]
    }

    func setRandNums() {
        randNums = [0.6006966286213917, 0.9200912867178763, 0.5875305444028074, 0.5011086861071219, 0.7957966987264736, 0.8417423281439527, 0.8453939604821639, 0.5908497652123952, 0.99812077762944, 0.7331843827189659, 0.4048923274704891, 0.2212536109295088, 0.13084136587190132, 0.9758465117316119, 0.1538669284808335, 0.8250638789385106, 0.12006757298108373, 0.45323718205598484, 0.3946925362034852, 0.41164113780737166, 0.27919349042272745, 0.8341785222053661, 0.9193968022115068, 0.36590248226453825, 0.4531691476107934, 0.5021622256093301, 0.17919773492642843, 0.022400793631311977, 0.5711896056906971, 0.6463529715234152, 0.21549252050354284, 0.29053934569441076, 0.6405258997930529, 0.755692318520558, 0.10694141704451132, 0.5827820460846121, 0.45687700745479887, 0.033801451881259714, 0.1477050724452742, 0.9733298484041135, 0.15392591148375956, 0.9009711637846058, 0.25334703610382014, 0.6424734244232466, 0.9998044242927873, 0.7449252550086429, 0.13284285072456037, 0.3998277687630495, 0.7579158570750965, 0.9604186026079494, 0.8506136213434239, 0.7138929910578802, 0.615758075073728, 0.5337571656327066, 0.22023368873239846, 0.7669823111795744, 0.6559799729059768, 0.24653201330577013, 0.7982297454940144, 0.13091306203477515, 0.03713067256730673, 0.6258816311910165, 0.9375227852492451, 0.6412227809818929, 0.08684756073757915, 0.367070151346659, 0.13869665694169642, 0.5493210352325151, 0.24830532834620112, 0.7004429886967872, 0.07597326450880526, 0.2738470789232117, 0.488933876479724, 0.08209361674708093, 0.8155887036131702, 0.7573079365911726, 0.8630414674333609, 0.7865479406877421, 0.5936901528104196, 0.8963105349978866, 0.8651550964183129, 0.3856655725536775, 0.2733876113844719, 0.15856657533694074, 0.6519476832617485, 0.3809014992527553, 0.42130591436689246, 0.3309350291712766, 0.7934491787565889, 0.8411688248524196, 0.7185504831951827, 0.10798635526110822, 0.16624846493218104, 0.8620697560101516, 0.5149002640322152, 0.8544878060270567, 0.8560121697275872, 0.04682154775150571, 0.654183362700069, 0.9964175770533703, 0.962070536868954, 0.16328287567009359, 0.8936969352419378, 0.3869595434702685, 0.3807586059855069, 0.09967700031383597, 0.26316146287076514, 0.20869629294928638, 0.6369812598884576, 0.8426889424246283, 0.6239609711500251, 0.9463458925504086, 0.46784516735072257, 0.013972463059703566, 0.9321035750327528, 0.42456379379653153, 0.9687111347015015, 0.2573768375128582, 0.7868293433302486, 0.3311341969669096, 0.08190433685047127, 0.26723002141673324, 0.057958793461975744, 0.8137673475869731, 0.01619349146917859, 0.0978984839448015, 0.9609049901776036, 0.6231598867963536, 0.43686139133281665, 0.8907808366482537, 0.7962912269866345, 0.4558094987184732, 0.17195967888304964, 0.09731296615876028, 0.3041893747217086, 0.1539010482682005, 0.04233642045230401, 0.4770907428500839, 0.45710876559159797, 0.3257138314512391, 0.7733027098142633, 0.5239728955252653, 0.7452642919039726, 0.5817410841857422, 0.8336018630405205, 0.380120994311409, 0.8634763454748792, 0.2863975391521697, 0.5351845474357788, 0.8908137484633946, 0.6174073179069981, 0.4154433038391563, 0.4909771877212292, 0.3843094591022326, 0.7189671864010913, 0.30456152493645594, 0.16392647153982776, 0.3549222444612459, 0.546200256253712, 0.46620130958973094, 0.9176336054067669, 0.6374144888818549, 0.8159520378759477, 0.4543541684043513, 0.534910917571243, 0.9888845900045248, 0.7665489349669037, 0.22357966639331184, 0.5332554521482489, 0.12577935415927066, 0.49483536766921166, 0.8673825710481445, 0.8659289137998362, 0.3772734030263386, 0.6612942368594706, 0.5155530749743913, 0.4003546754618059, 0.021412554013243823, 0.21955556269140697, 0.5192885613134656, 0.11994611759100848, 0.718522404354113, 0.07707030210908472, 0.37755234877283206, 0.13343526003606243, 0.7212870230318525, 0.9922244835479993, 0.730491711933474, 0.7245800516205751, 0.7753687790637716, 0.4377146247886917, 0.0719780955539766, 0.396143975997449, 0.6607956142632397, 0.5121786010030975, 0.07339938190853201, 0.573284952822564, 0.3267177202796855, 0.17320763311201093, 0.799073630256068, 0.024314482572966867, 0.3192126146610822, 0.7026974917726924, 0.7594588270968233, 0.8840218689074147, 0.30163057857073916, 0.9458216798528049, 0.8552416015110862, 0.339774541343394, 0.19936590258383113, 0.4173092900548383, 0.36324954586399794, 0.16902221438941822, 0.06202958210948051, 0.6081279466060048, 0.2897180696309668, 0.6959295253699856, 0.9190889479595403, 0.6178250881928384, 0.13890435982451999, 0.8901006040956086, 0.7806449129576257, 0.5995696704713754, 0.6079075164274192, 0.8616025040388356, 0.4442162214665224, 0.9548321996429404, 0.8641894344923143, 0.9123864746798325, 0.26267820420113186, 0.5676095999426216, 0.95333535311374, 0.4259729001710867, 0.9411140884047976, 0.7619754439895695, 0.08162173822914454, 0.906041108412239, 0.13692609207598094, 0.9015536906341253, 0.27178871642462477, 0.9265616005787652, 0.39612692303437314, 0.7056638535871517, 0.9399137138848184, 0.5215572966300656, 0.21347720234177336, 0.691348310778994, 0.5265739337672665, 0.9068841776276668, 0.9599512173385896, 0.8929320533068228, 0.6986210004999106, 0.40536039338518093, 0.9119191470587127, 0.39746660259876687, 0.27365521492512024, 0.7068232317313486, 0.6165762820153273, 0.6393371174980864, 0.46585869697543003, 0.21406533380795623, 0.8762843392630638, 0.7749667307517695, 0.7525098323838897, 0.3548389605389709, 0.8981819607108593, 0.24476147403189497, 0.6180859120150641, 0.38961821639585437, 0.1751977531011617, 0.7767774553059354, 0.8125302164909002, 0.35204590653735357, 0.9846332985071599, 0.9767780332167083, 0.11810646718072804, 0.13856961285899727, 0.9308473795766179, 0.18245681429424, 0.5348625648651321, 0.8729216621455346, 0.35576075934119744, 0.7607869288197728, 0.7461016598516679, 0.3624028052851137, 0.9051563291146273, 0.2689517298200833, 0.26490465806248553, 0.8175821513792338, 0.09536549443481301, 0.965835584889003, 0.9557909458873355, 0.6212072340411012, 0.31152935592471787, 0.33239610291928223, 0.269321055654709, 0.20220440500425496, 0.32472489873513555, 0.8209916153160943, 0.07684691242094388]
    }

    override func viewDidLoad() {
        // fill in dictionary with nil values
        stimuli = [stimuli[0],stimuli[1],stimuli[2],stimuli[3],stimuli[4]]
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
        
        for i in 1...14 {
//            print("Test iteration")
//            print(i)
            btnPressed_pseudo()
        }
        experiment_complete()
        print(get_data_string())
        print("experiment complete")
    }

}
