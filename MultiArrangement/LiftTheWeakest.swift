//
//  LiftTheWeakest.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-01-15.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//
//***Corresponds to "simJudgeByMultiArrangement_circArena_ltw_maxNitems.m" script

import Foundation

class LiftTheWeakest {
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
    let maxSessionLength = Double.infinity
    let maxNitemsPerTrial = Double.infinity
    var estimate_RDM_ltv = [Double]()
    var estimate_RDM_sq = [[Double]]()
    var estimate_RDM_sq_cTrial = [[Double]]()
    var utilityBenefit = 0.0
    
    init(images: [String]) {
        self.nItems = images.count
        self.nPairs = (self.nItems^2 - self.nItems)/2   // pairs = n(n-1)/2
        
    }
    
    func startTrial() {
        
        //useful to have precomputed
        let eye_nitems = eye(n: nItems)
        
        let verIs = ndgrid(bounds: [[1,self.nItems], [1,self.nItems]])
        let horIs = transpose(mat: verIs)
        let verIs_ltv = vectorizeSimmat(mat: verIs)
        let horIs_ltv = vectorizeSimmat(mat: horIs)
        let evidenceWeight_ltv = zeros(size: [1, verIs_ltv.count])
        var distMatsForAllTrials_ltv = [[Double]]()   //not sure about this
        var weakestEvidenceWeights = [[Double]]()       // this too
        var meanEvidenceWeights = [[Double]]()
        
        var trialI = 0
        
        //record session start time
        let start = Double(DispatchTime.now().uptimeNanoseconds)
        
        // put this at the end of each trial
//        let end = Double(DispatchTime.now().uptimeNanoseconds)
//        let nanoTime = end - start
//        let timeInterval = nanoTime / 1_000_000_000  //this is the seconds elapsed
        let argument = evidenceWeight_ltv.flatMap{ $0 }
        while (self.minEvidenceWeight < self.minRequiredEvidenceWeight && (any(mat: argument, val: 0.0)) || etime(start: start) < maxSessionLength) {
            let negate = elementWise(op: "*", left: evidenceWeight_ltv, right: -1)
            let etothe = elementWise(op: "*", left: negate, right: evidenceUtilityExponent)
            let exponent = elementWise(op: "exp", left: etothe, right: 1.0)
            let negagain = elementWise(op: "*", left: exponent, right: -1)
            var evidenceUtility_ltv = elementWise(op: "+", left: negagain, right: 1.0)
            var evidenceUtility_sq = squareform(arr: evidenceUtility_ltv.flatMap{ $0 })
            var evidenceLOG_ltv = elementWise(op: ">", left: evidenceUtility_ltv, right: 0.0)
            var initialPairI = Int()
            
            if any(mat: evidenceLOG_ltv.flatMap{ $0 } , val: 1.0) {
                var evidenceUtility_sq_nan = evidenceUtility_sq
                evidenceUtility_sq_nan = logical(mat: evidenceUtility_sq_nan, bool_mat: eye_nitems, val: Double.nan)
                var nObjEachObjHasNotBeenPairedWith = nansum(mat: evidenceUtility_sq_nan)
                
                let repmat_column = nObjEachObjHasNotBeenPairedWith.flatMap{ $0 }
                let lhs = repmat_col(col: repmat_column, row_times: 1, col_times: nItems)
                let rhs = repmat(mat: nObjEachObjHasNotBeenPairedWith, num_row: nItems, num_col: 1)
                var nZeroEvidencePairsReachedByEachPair = matrix_addition(left: lhs, right: rhs)
                nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair, bool_mat: eye_nitems, val: 0.0)
                let distances = inverse_squareform(arr: nZeroEvidencePairsReachedByEachPair).flatMap{ $0 }
                let evidenceLOG_inverted = elementWise(op: "~", left: evidenceLOG_ltv, right: 1.0)
                nZeroEvidencePairsReachedByEachPair = logical(mat: nZeroEvidencePairsReachedByEachPair, bool_mat: evidenceLOG_inverted, val: 0.0)
                let nZero_flat = nZeroEvidencePairsReachedByEachPair.flatMap{ $0 }
                let maxVal = nZero_flat.max()
                var maxI = nZero_flat.firstIndex(of: maxVal!)
                let maxIs = find_2d(in_: nZeroEvidencePairsReachedByEachPair, item: maxVal!)
                maxI = maxIs[ceil(num: rand()*Double(nPairs))]
            } else {
                initialPairI = ceil(num: rand()*Double(nPairs))
            }
            
            let item1I = verIs_ltv[initialPairI]
            let item2I = horIs_ltv[initialPairI]
            
            var cTrial_itemIs = [Int(item1I), Int(item2I)]
            
            while Double(cTrial_itemIs.count) < maxNitemsPerTrial {
                var trialEfficiencies = nan_grid(num_rows: nItems - cTrial_itemIs.count + 1, num_cols: 1)[0]     //note: verify that the above results in a column vector (1D)
                let otherItemIs = setdiff(A: [Int](0...nItems), B: cTrial_itemIs)
                var itemAddedI = [Int]()
                var itemSetI = 1
                
                while true {
                    if estimate_RDM_ltv.count > 1 {
                        //...
                    } else {
                        estimate_RDM_sq = ones(rows: nItems, cols: nItems)
                        estimate_RDM_sq = logical(mat: estimate_RDM_sq, bool_mat: eye_nitems, val: 0.0)
                        estimate_RDM_ltv = inverse_squareform(arr: estimate_RDM_sq).flatMap{ $0 }
                    }
                    estimate_RDM_sq_cTrial = matrix_partition(mat: estimate_RDM_sq, rows: cTrial_itemIs, cols: cTrial_itemIs)
                    if colon_operation(mat: estimate_RDM_sq_cTrial).max()! > 0.0 {
                        let med = median(arr: estimate_RDM_ltv)
                        let isnan_bool = isnan(mat: estimate_RDM_sq_cTrial)
                        estimate_RDM_sq_cTrial = logical(mat: estimate_RDM_sq_cTrial, bool_mat: isnan_bool, val: med)
                        let denom = colon_operation(mat: estimate_RDM_sq_cTrial).max()!
                        estimate_RDM_sq_cTrial = elementWise(op: "/", left: estimate_RDM_sq_cTrial, right: denom)
                        
                        let after_part = matrix_partition(mat: evidenceUtility_sq, rows: cTrial_itemIs, cols: cTrial_itemIs)
                        let utilityBeforeTrial = inverse_squareform(arr: after_part).flatMap{ $0 }.reduce(0, +)
                        let evidenceWeight_sq = squareform(arr: evidenceWeight_ltv.flatMap{ $0 })
                        let left_partition = matrix_partition(mat: evidenceWeight_sq, rows: cTrial_itemIs, cols: cTrial_itemIs)
                        let right_part = evidenceWeights(mat: [estimate_RDM_sq_cTrial])
                        var evidenceWeightAfterTrial_sq = matrix_addition(left: left_partition, right: right_part[0])
                        let cTrial_logic_eye = eye(n: cTrial_itemIs.count)
                        evidenceWeightAfterTrial_sq = logical(mat: evidenceWeightAfterTrial_sq, bool_mat: cTrial_logic_eye, val: 0.0)
                        let weight_after_trial_vector = inverse_squareform(arr: evidenceWeightAfterTrial_sq)    // 2D row vector here
                        let negated_weights = elementWise(op: "*", left: weight_after_trial_vector, right: -1.0*evidenceUtilityExponent)
                        let exponential = elementWise(op: "exp", left: negated_weights, right: 1.0)
                        let negated_exponential = elementWise(op: "*", left: exponential, right: -1.0)
                        let final_sum_arg = elementWise(op: "+", left: negated_exponential, right: 1.0).flatMap{ $0 }
                        let utilityAfterTrial = final_sum_arg.reduce(0, +)
                        utilityBenefit = utilityAfterTrial - utilityBeforeTrial
                    } else {
                        utilityBenefit = 0.0
                    }
                    let trialCost = Darwin.pow(Double(cTrial_itemIs.count), dragsExponent)
                    trialEfficiencies[itemSetI] = utilityBenefit / trialCost
                    cTrial_itemIs = setdiff(A: cTrial_itemIs, B: itemAddedI)
                    
                    if itemSetI == otherItemIs.count + 1 {
                        break
                    }
                    
                    // this line is strange
                    itemAddedI = [otherItemIs[itemSetI]]
                    cTrial_itemIs = union(A: cTrial_itemIs, B: itemAddedI)
                    itemSetI += 1
                }
                
                var maxVal = trialEfficiencies.max()!
                var maxIs = find_1d(arr: trialEfficiencies, val: maxVal)
                var maxI = maxIs[Int(ceil(rand()*Double(maxIs.count)))]
                
                if maxI == 1 {
                    if cTrial_itemIs.count >= 3 {
                        break
                    } else {
                        let efficiency_slice = Array(trialEfficiencies[1..<trialEfficiencies.count])
                        maxVal = efficiency_slice.max()!
                        maxIs = find_1d(arr: efficiency_slice, val: maxVal)
                        maxI = maxIs[Int(ceil(rand()*Double(maxIs.count)))]
                        cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI]])
                    }
                } else {
                    cTrial_itemIs = union(A: cTrial_itemIs, B: [otherItemIs[maxI - 1]])
                }
            }
            
            trialI += 1
            
            // Idea: the following line will load the list of images on the Circular Arena
            // image_positions = CircularArenaController.load_images([List of images])
            
        }
    }
    
}
