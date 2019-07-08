//
//  estimateRDMFromStackOfPartials.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-02-28.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

import Foundation

func estimateRDM (distMats: [[[Double]]]) -> [[[Double]]] {
    // we will treat <stackOfPartialRDMs_ltv> as a list of list of lists with Double elements
    // the MATLAB implementation is a stack of row vectors along the third dimension
//    print("distMats")
//    print(distMats)
    var stackOfPartialRDMs_ltv_temp = vectorizeSimmats(simmats: distMats) //verify
    var stackOfPartialRDMs_ltv = [[[Double]]]()
    for i in 0..<stackOfPartialRDMs_ltv_temp.count {
        let new_stack = transpose(mat: [stackOfPartialRDMs_ltv_temp[i]])
        //stackOfPartialRDMs_ltv[i] = new_stack <-- original code
        stackOfPartialRDMs_ltv.append(new_stack)
    }
//    print("stackOfPartialRDMs_ltv 23")
//    print(stackOfPartialRDMs_ltv)
    let nPairs = stackOfPartialRDMs_ltv[0].count
    let nDissimPartialMats = stackOfPartialRDMs_ltv.count
    let nItems = (1 + Darwin.pow((1.0+8.0*Double(nPairs)), 0.5))/2.0
    
    let weights = evidenceWeights(mat: stackOfPartialRDMs_ltv)
    var evidenceWeight_ltv = distMats[0]
    do {
        evidenceWeight_ltv = try nansum3d(mat: weights)
//        print("evidenceWeight_ltv 33")
//        print(evidenceWeight_ltv)
    } catch {
        print("nansum3d error")
    }
    var initialEstimate = [[Double]]()
    do {
        initialEstimate = try nanmean3d(mat: stackOfPartialRDMs_ltv)
//        print("initialEstimate 41")
//        print(initialEstimate)
    } catch {
        print("nanmean3d error")
    }
    
    let squared = elementWise(op: "^", left: initialEstimate, right: 2.0)
//    print("line 46 squared")
//    print(squared)
    let denom = Darwin.pow(nansum1d(mat: squared), 0.5)
//    print("line 49 denom")
//    print(denom)
    
    initialEstimate = elementWise(op: "/", left: initialEstimate, right: denom)
//    print("initialEstimate 52")
//    print(initialEstimate)
    
    var cEstimate = initialEstimate
    var iterationChangeSSQ = 99999.0
    
    let snl_sub1 = [[Double]](repeating: [0.0], count: nPairs)
    var stackOfPartialRDMs_ltv_normalized = [[[Double]]](repeating: snl_sub1, count: 50)   // count <--> max # of trials?
    
    let start = DispatchTime.now()
    while iterationChangeSSQ > 1e-8 {
        for partialRDMI in 0..<nDissimPartialMats {
            let cPartialRDM_ltv = stackOfPartialRDMs_ltv[partialRDMI]   // TODO: verify this value
//            print("cPartialRDM_ltv 61")
//            print(cPartialRDM_ltv)
//            let nonNan = isnan(mat: cPartialRDM_ltv)
//            let nonNaN_LOG = elementWise(op: "~", left: nonNan, right: 0.0)
            var cEstimate_temp = cEstimate

//            print("cEstimate 63")
//            print(cEstimate)
            for i in 0..<cEstimate.count {
                for j in 0..<cEstimate[0].count {
                    if cPartialRDM_ltv[i][j].isNaN == false {
                        cEstimate_temp[i][j] = Darwin.pow(cEstimate[i][j], 2.0)
                    }
                }
            }
            let targetSSQ = nansum1d(mat: cEstimate_temp)
//            print("targetSSQ")
//            print(targetSSQ)
            var cPartial_temp = cEstimate
            for i in 0..<cPartialRDM_ltv.count {
                for j in 0..<cPartialRDM_ltv[0].count {
                    if cPartialRDM_ltv[i][j].isNaN == false {
                        cPartial_temp[i][j] = Darwin.pow(cPartialRDM_ltv[i][j], 2.0)
                    }
                }
            }
            let partial_sum = nansum1d(mat: cPartial_temp)
            let denom = Darwin.sqrt(partial_sum)
//            print("cPartialRDM_ltv")
//            print(cPartialRDM_ltv)
            let left_monoid = elementWise(op: "/", left: cPartialRDM_ltv, right: denom)
//            print("left_monoid")
//            print(left_monoid)
            stackOfPartialRDMs_ltv_normalized[partialRDMI] = elementWise(op: "*", left: left_monoid, right: sqrt(targetSSQ))
        }
        let pEstimate = cEstimate
        //weighted mean estimate
        do {
            //print("line 83")
            let right_monoid = try nansum3d(mat: weights)
        } catch {
            print("nansum3d error")
        }
//        print("normalized is")
//        print(stackOfPartialRDMs_ltv_normalized)
        var hid = stackOfPartialRDMs_ltv_normalized
        for k in 0..<weights.count {
            for j in 0..<weights[0].count {
                for i in 0..<weights[0][0].count {
                    hid[k][j][i] = hid[k][j][i] * weights[k][j][i]
                }
            }
        }
        var den = cEstimate
        var markov_buffer = cEstimate
        do {
//            print("line 99, hid is")
//            print(hid)
            den = try nansum3d(mat: hid)
        } catch {
            print("nansum3d error")
        }
        do {
            //print("line 105")
            markov_buffer = try nansum3d(mat: weights)
        } catch {
            print("nansum3d error")
        }
//        print("line 130 cEstimate")
//        print(cEstimate)
        var cEstimate_var = cEstimate
        for k in 0..<weights[0].count {
            for j in 0..<weights[0][0].count {
                cEstimate_var[k][j] = den[k][j] / markov_buffer[k][j]
            }
        }
//        print("line 138 cEstimate_var")
//        print(cEstimate_var)
        cEstimate_var = elementWise(op: "^", left: cEstimate_var, right: 2.0)
        let c_denom = sqrt(nansum1d(mat: cEstimate_var))
        cEstimate = elementWise(op: "/", left: cEstimate_var, right: c_denom)
//        print("line 143 cEstimate")
//        print(cEstimate)
        var diff = cEstimate
        for i in 0..<cEstimate.count {
            for j in 0..<cEstimate[0].count {
                diff[i][j] = cEstimate[i][j] - pEstimate[i][j]
            }
        }
        let diff_pow = elementWise(op: "^", left: diff, right: 2.0)
        iterationChangeSSQ = nansum1d(mat: diff_pow)
//        print("iterationChangeSSQ 159")
//        print(iterationChangeSSQ)
    }
    let end = DispatchTime.now()
    let estimate_RDM_ltv = cEstimate
    
    evidenceWeight_ltv = fix_evidenceWeights(weights: evidenceWeight_ltv)
    
    return [estimate_RDM_ltv, evidenceWeight_ltv]
}

// original code assumes elements of evidenceWeights are non-nan values
// as such, correct each nanvalue to 0.0
func fix_evidenceWeights(weights: [[Double]]) -> [[Double]] {
    var fixed = [[Double]]()
    for i in 0..<weights.count {
        var col = [Double]()
        for j in 0..<weights[i].count {
            if weights[i][j].isNaN {
                col.append(0.0)
            } else {
                col.append(weights[i][j])
            }
        }
        fixed.append(col)
    }
    return fixed
}
