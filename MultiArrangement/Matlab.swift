import UIKit


//
//  Matlab.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-01-10.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

// *** ensure all matrices use column vectors ***

import Foundation

// returns an nxn matrix of zeros
func zeros(size: [Int]) -> [[Double]] {
    let col = [Double](repeating: 0.0, count: size[0])
    return [[Double]](repeating: col, count: size[1])
}

//print(zeros(n: 4))

// creates an nxn identity matrix
func eye(n: Int) -> [[Double]] {
    var frame = zeros(size: [n, n])
    for i in 0...n-1 {
        frame[i][i] = 1
    }
    return frame
}

//print(eye(n: 3))


// Gets the appropriate matrix size for squareform
func get_squareform_size(n: Int) -> Int {
    var curr = 1
    var gap = 2
    var size = 2
    while curr <= n {
        if curr == n {
            return size
        } else {
            curr += gap
            gap += 1
            size += 1
        }
    }
    return -1
}

func squareform(arr: [Double]) -> [[Double]] {
    let size = get_squareform_size(n: arr.count)
    assert (size != -1, "Invalid size for squareform")
    var matrix = zeros(size: [size, size])
    var index = 0
    for i in 0...size-1 {
        for j in 0...size-1 {
            if i != j && i < j {
                matrix[i][j] = arr[index]
                matrix[j][i] = arr[index]
                index += 1
            }
        }
    }
    return matrix
}
// returns [[0.0, 3.0, 6.0], [3.0, 0.0, 4.0], [6.0, 4.0, 0.0]]
//print(squareform(arr: [3, 6, 4]))


// this turns a dissimilatiry matrix into a *column* vector
// assumes the matrix is square and is a proper dissimilarity matrix
func inverse_squareform(arr: [[Double]]) -> [[Double]] {
    var result = [[Double]]()
    var diag_i = 0
    var diag_j = 0    // these i, j represent the diagonal indices
    while diag_i < arr.count - 1 {
        for j in diag_j+1..<arr[diag_i].count {
            result.append([arr[diag_i][j]])
        }
        diag_i += 1
        diag_j += 1
    }
    return result
}
//let a = [[0.0, 8.0, 5.0], [8.0, 0.0, 1.0], [5.0, 1.0, 0.0]]
//print(inverse_squareform(arr: a))



// restricted to 2D arrays
func numel_2d(mat: [[Double]]) -> Int {
    let size = mat.count
    var num = 0
    for i in 0...size-1 {
        num += mat[i].count
    }
    return num
}

//print(numel(mat: [[1.0, 2.0, 3.0], [1.0, 2.0, 3.0], [1.0, 2.0, 3.0]]))


// 1.0 for true, 0.0 for false
func isnan(mat: [[Double]]) -> [[Double]] {
    let row = [Double](repeating: 0.0, count: mat[0].count)
    var frame = [[Double]](repeating: row, count: mat.count)
    for i in 0..<mat.count {
        for j in 0..<mat[i].count {
            if mat[i][j].isNaN {
                frame[i][j] = 1.0
            }
        }
    }
    return frame
}

//let a = [[1, 2, 3], [Double.nan, 5, Double.nan], [7, 8, Double.nan]]
//print(isnan(mat: a))


// Restricted to concatenating along third dimension
func cat(mat1: [[Double]], mat2: [[Double]]) -> [[[Double]]] {
    var base = [[[Double]]]()
    base.append(mat1)
    base.append(mat2)
    return base
}



func split(arr: [Double], pivot_index: Int) -> [[Double]] {
    var result = [[Double]]()
    var left = [Double]()
    var right = [Double]()
    for i in 0..<arr.count {
        if arr[i] > arr[pivot_index] {
            right.append(arr[i])
        } else if i != pivot_index {
            left.append(arr[i])
        }
    }
    result.append(left)
    result.append(right)
    return result
}

func find_kth(arr: [Double], k: Int) -> Double {
    let rand_index = Int.random(in: 0..<arr.count)
    let result = split(arr: arr, pivot_index: rand_index)
    let left = result[0]
    let right = result[1]
    if k == left.count+1 {
        return arr[rand_index]
    } else if k <= left.count {
        return find_kth(arr: left, k: k)
    } else {    // k > left.count+1
        return find_kth(arr: right, k: k-(left.count+1))
    }
}

func median_2d(arr: [[Double]]) -> Double {
    let flat = arr.flatMap{ $0 }
    if flat.count % 2 == 0 {
        let first_mid = find_kth(arr: flat, k: flat.count/2)
        let second_mid = find_kth(arr: flat, k: flat.count/2 + 1)
        return (first_mid + second_mid)/2
    } else {
        let k = flat.count / 2 + 1
        return find_kth(arr: flat, k: k)
    }
}

// returns MATLAB indices of elements in <in_> that are equal "==" to <item>
func find_2d(in_: [[Double]], item: Double) -> [Int] {
    var locations = [Int]()
    let flat = in_.flatMap{ $0 }
    for i in 0..<flat.count {
        if item.isNaN && flat[i].isNaN {
            locations.append(i+1)
        } else if flat[i] == item {
            locations.append(i+1)
        }
    }
    return locations
}


// input array format: [[start, stop], [start, stop]]
// start and stop inclusive
func ndgrid(bounds: [[Int]]) -> [[Double]] {
    var col = [Double]()
    for i in bounds[0][0]...bounds[0][1] {
        col.append(Double(i))
    }
    let layer = [[Double]](repeating: col, count: bounds[1][1]-bounds[1][0] + 1)
    return layer
}


func nan_grid(num_rows: Int, num_cols: Int) -> [[Double]] {
    let row = [Double](repeating: Double.nan, count: num_rows)
    return [[Double]](repeating: row, count: num_cols)
}


// returns a matrix with the values in mat that have corresponding "1" in <bool_mat> changed to <val>
func logical(mat: [[Double]], bool_mat: [[Double]], val: Double) -> [[Double]] {
    var copy = mat
    for i in 0..<mat.count {
        for j in 0..<mat[0].count {
            if bool_mat[i][j] == 1.0 {
                copy[i][j] = val
            } else {
                copy[i][j] = mat[i][j]
            }
        }
    }
    return copy
}

// this may be unnecessary
func createBoolMatrix(mat:[[Double]]) -> [[Bool]] {
    let boolCol = [Bool](repeating: false, count: mat[0].count)
    var boolMat = [[Bool]](repeating: boolCol, count: mat.count)
    for i in 0..<mat.count {
        for j in 0..<mat[0].count {
            if mat[i][j] == 1.0 {
                boolMat[i][j] = true
            }
        }
    }
    return boolMat
}

// works for square matrices
func vectorizeSimmat(mat: [[Double]]) -> [Double] {
    var lowerT = [Double]()
    for i in 0..<mat.count {
        for j in (i+1)..<mat[i].count {
            lowerT.append(mat[i][j])
        }
    }
    return lowerT
}

// from matlab results, this should return an array of arrays
func vectorizeSimmats(simmats: [[[Double]]]) -> [[Double]] {
    var result = [[Double]]()
    for sim in simmats {
        result.append(vectorizeSimmat(mat: sim))
    }
    return result
}

//let a = [[1.0, 2.0, 4.0], [2.0, 3.0, 4.0], [4.0, 5.0, 6.0]]
//let b = [[true, false, false], [false, true, false], [false, false, true]]
//print(logical(mat: a, bool_arr: b, val: 23.0))


func nansum(mat: [[Double]]) -> [[Double]] {
    var result = [[Double]]()
    for col in mat {
        result.append([Double(col.filter{ $0.isNaN == false }.reduce(0, +))])
    }
    return result
}

// same input as nansum, but assumes <mat> is a row vector
func nansum1d(mat: [[Double]]) -> Double {
    var sum = Double()
    for col in mat {
        for num in col {
            if num.isNaN == false {
                sum += num
            }
        }
    }
    return sum
}

//let a = [[1.0, 2.0, 4.0], [2.0, 1.0, 4.0], [1.0, 5.0, 1.0]]
//print(nansum(mat: a, val: 1))

enum AssumptionError: Error {
    case nansum3dError
}


// equivalent to MATLAB code nansum([[Double]], 3) i.e. the adding
// takes place in the third dimension
// this assumes that mat is always a stack of 1xn vectors, otherwise it
// will raise an exception
func nansum3d(mat: [[[Double]]]) throws -> [[Double]] {
    var temp_result = [Double]()
    let num_cols = mat[0].count
    let num_rows = mat[0][0].count
    for j in 0 ..< num_cols {
        for i in 0 ..< num_rows {
            var c_sum = 0.0
            for k in 0..<mat.count {
                if mat[k][j][i].isNaN == false {
                    c_sum += mat[k][j][i]
                }
            }
            temp_result.append(c_sum)
        }
    }
    if num_rows == 1 {
        return transpose(mat: [temp_result])
    } else {
        throw AssumptionError.nansum3dError
    }
}


// eturns [[mean of e1], [mean of e2], ..., [mean of en]], where ej = jth element of an element in <mat>
//func nanmean(mat: [[Double]]) -> [[Double]] {
//    let layers = mat.count
//    var result = [[Double]]()
//    var tally = [Double](repeating: 0.0, count: mat[0].count)
//    for i in 0..<layers {
//        for j in 0..<mat[i].count {
//            if mat[i][j].isNaN == false {
//                tally[j] += mat[i][j]
//            }
//        }
//    }
//    for elem in tally {
//        result.append([elem/Double(layers)])
//    }
//    return result
//}

// equivalent to MATLAB code nanmean([[Double]], 3) i.e. the averaging
// takes place in the third dimension
// if every entry is nan, the output is nan
// if at least one entry is not nan, the output is not nan
func nanmean3d(mat: [[[Double]]]) throws -> [[Double]] {
    var temp_result = [Double]()
    let num_cols = mat[0].count
    let num_rows = mat[0][0].count
    for j in 0 ..< num_cols {
        for i in 0 ..< num_rows {
            var c_sum = 0.0
            var c_nonnan_count = 0
            for k in 0..<mat.count {
                if mat[k][j][i].isNaN == false {
                    c_sum += mat[k][j][i]
                    c_nonnan_count += 1
                }
            }
            if c_sum != 0.0 {
                temp_result.append(c_sum / Double(c_nonnan_count))
            } else {    // this is the case for when every entry is nan
                temp_result.append(Double.nan)
            }
        }
    }
    if num_rows == 1 {
        return transpose(mat: [temp_result])
    } else {
        throw AssumptionError.nansum3dError
    }
}


// special case for column vector
func repmat_col(col: [Double], row_times: Int, col_times: Int) -> [[Double]] {
    let new_col = [[Double]](repeating: col, count: row_times)
    let flat_col = new_col.flatMap{ $0 }
    return [[Double]](repeating: flat_col, count: col_times)
}
// general case for a single row or a non-(nx1) matrix
func repmat(mat: [[Double]], num_row: Int, num_col: Int) -> [[Double]] {
    var new_mat = [[Double]]()
    for col in mat {
        let new_col = [[Double]](repeating: col, count: num_row)
        let flat_col = new_col.flatMap{ $0 }
        new_mat.append(flat_col)
    }
    let col_mult = [[[Double]]](repeating: new_mat, count: num_col)
    return col_mult.flatMap{ $0 }
}


// does not generalize to nxn <size>
func rand() -> Double {
    return Double.random(in: 0.0...1.0)
}
func randn_helper() -> [Double] {
    let u1 = Double.random(in: 0...1) // uniform distribution
    let u2 = Double.random(in: 0...1) // uniform distribution
    let f1 = sqrt(-2 * log(u1))
    let f2 = 2 * Double.pi * u2
    let g1 = f1 * cos(f2) // gaussian distribution
    let g2 = f1 * sin(f2) // gaussian distribution
    return [g1, g2]
}

func randn(size: [Int]) -> [[Double]] {
    let num_vals = size[0] * size[1]
    var randn_mat = [[Double]]()
    var randn_vals = [Double]()
    for _ in 0...(num_vals+1) {
        let std_norms = randn_helper()
        randn_vals.append(std_norms[0])
        randn_vals.append(std_norms[1])
    }
    var col = [Double]()
    var count = 0
    for _ in 0..<size[0] {
        for _ in 0..<size[1] {
            col.append(randn_vals[count])
            count += 1
        }
        randn_mat.append(col)
        col.removeAll(keepingCapacity: true)
    }
    return randn_mat
}

//let a = randn(size: [3, 3])
//print(a)


// returns a column vector of elements in A that are not in B
func setdiff(A: [Int], B: [Int]) -> [Int] {
    var temp_A = A
    var diff = [Int]()
    for num in B {
        diff = temp_A.filter{ $0 != num }
        temp_A = diff
    }
    return temp_A
}

//var A = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
//let B = [[2.0, 4.0], [6.0, 8.0]]
//print(setdiff(A: A, B: B))


// returns a row vector of the sums of the columns of <mat>
func sum(mat: [[Double]]) -> [[Double]] {
    var sums = [[Double]]()
    for col in mat {
        sums.append([col.reduce(0, +)])
    }
    return sums
}

//print(sum(mat: [[1.0, 2.0], [3.0, 4.0]]))



// treats A and B as sets
func union(A: [Int], B: [Int]) -> [Int] {
    var c = [Int]()
    for elem in A {
        c.append(elem)
    }
    for elem in B {
        c.append(elem)
    }
    var seen = Set<Int>()
    return c.filter{ seen.insert($0).inserted }

}

//let a = [1.0, 2.0, 2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 6.0]
//let b = [5.0, 7.0, 10.0]
//print(union(A: a, B: b))


// timing the experiment
//let start = DispatchTime.now()
//// run the code here
//let end = DispatchTime.now()
//let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
//let timeInterval = Double(nanoTime) / 1_000_000_000  //this is the seconds elapsed


func exp(x: Double) -> Double {
    let e = Darwin.M_E
    return pow(e, x)
}
//print(exp(x: 1.0))


// treats the column vectors as points x_1...x_n
// returns an array of pair-wise distances that is an appropriate input for squareform()
func pdist(mat: [[Double]]) -> [Double] {
    var dist = [Double]()
    var pivot = 0
    var running_compare = 1
    while pivot < mat.count {
        while running_compare < mat.count {
            let col1 = mat[pivot]
            let col2 = mat[running_compare]
            var sum = 0.0
            for i in 0..<col1.count {
                sum += Darwin.pow((col2[i] - col1[i]), 2.0)
            }
            dist.append(Darwin.sqrt(sum))
            running_compare += 1
        }
        pivot += 1
        running_compare = pivot + 1
    }
    return dist
}

//let a = [[1.0,1.0,1.0], [2.0,2.0,2.0], [4.0,4.0,4.0], [8.0,8.0,8.0]]
//print(pdist(mat: a))


// returns an array of the maximum element in each column of <mat>
func max(mat: [[Double]]) -> [Double] {
    var result = [Double]()
    for col in mat {
        result.append(col.max()!)
    }
    return result
}
// returns an array of the minimum element in each column of <mat>
func min(mat: [[Double]]) -> [Double] {
    var result = [Double]()
    for col in mat {
        result.append(col.min()!)
    }
    return result
}
// returns an array of the mean of each column of <mat>
func mean(mat: [[Double]]) -> [Double] {
    var result = [Double]()
    for col in mat {
        let s = col.reduce(0, +)
        result.append(s / Double(col.count))
    }
    return result
}
//let a = [[2.0, 3.0, 4.0], [1.0, 4.0, 5.0]]
//print(max(mat: a))
//print(min(mat: a))
//print(mean(mat: a))

func any(mat: [Double], val: Double) -> Bool {
    for item in mat {
        if item == val {
            return true
        }
    }
    return false
}


enum DivisionError: Error {
    case divisionByZero(String)
}


// provides support for element-wise operations in MATLAB
// a better implementation: parse the expression directly (future)
// also, remove the operators that do not depend on <right>
func elementWise(op: String, left: [[Double]], right: Double) -> [[Double]] {
    var result = [[Double]]()
    for vec in left {
        var new_vec = [Double]()
        for item in vec {
            if op == "+" {
                new_vec.append(item + right)
            } else if op == "*" {
                new_vec.append(item * right)
            } else if op == "exp" {
                new_vec.append(Darwin.exp(item))
            } else if op == ">" {
                if item > right {
                    new_vec.append(1.0)
                } else {
                    new_vec.append(0.0)
                }
            } else if op == "<" {
                if item < right {
                    new_vec.append(1.0)
                } else {
                    new_vec.append(0.0)
                }
            } else if op == "~" {      // assumes that <left> is a logical array (only 0.0 and 1.0)
                if item == 0.0 {
                    new_vec.append(1.0)
                } else {
                    new_vec.append(0.0)
                }
            } else if op == "/" {
                new_vec.append(item / right)
            } else if op == "^" {
                new_vec.append(Darwin.pow(item, right))
            }
        }
        result.append(new_vec)
    }
    return result
}

// matrix addition: <left> and <right> must have the same size!
func matrix_addition(left: [[Double]], right: [[Double]]) -> [[Double]] {
    let col = [Double](repeating: 0.0, count: left[0].count)
    var result = [[Double]](repeating: col, count: left.count)
    for i in 0..<left.count {
        for j in 0..<left[0].count {
            result[i][j] = left[i][j] + right[i][j]
        }
    }
    return result
}

func etime(start: Double) -> Double {
    let end = Double(DispatchTime.now().uptimeNanoseconds)
    return (end - start) / 1_000_000_000    //this is the seconds elapsed
}

// returns the nearest integer >= <num>
func ceil(num: Double) -> Int {
    return Int(num.rounded(.up))
}

func squareSimmat(vec: [Double]) -> [[Double]] {
    let square = squareform(arr: vec)
    let lowerT = vectorizeSimmat(mat: square)
    return squareform(arr: lowerT)
}

func ones(rows: Int, cols: Int) -> [[Double]] {
    let col = [Double](repeating: 1.0, count: rows)
    return [[Double]](repeating: col, count: cols)
}

func matrix_partition(mat: [[Double]], rows: [Int], cols: [Int]) -> [[Double]] {
    var new_mat = [[Double]]()
    for j in cols {
        var new_col = [Double]()
        for i in rows {
            new_col.append(mat[i][j])
        }
        new_mat.append(new_col)
    }
    return new_mat
}

func colon_operation(mat: [[Double]]) -> [Double] {
    return mat.flatMap{ $0 }
}

func sigfig_round(_ num: Double, to places: Int) -> Double {
    let p = log10(abs(num))
    let f = pow(10, p.rounded() - Double(places) + 1)
    let rnum = (num / f).rounded() * f
    
    return rnum
}

// returns <mat> such that sneaky MATLAB numerical errors are avoided
func matlab_round(mat: [[Double]]) -> [[Double]]{
    var result = [[Double]]()
    for i in 0..<mat.count {
        var vec = [Double]()
        for j in 0..<mat[0].count {
            if abs( mat[i][j] - 0 ) <= 0.0001 {
                vec.append(0.0)
            } else if abs( mat[i][j] - 1 ) <= 0.0001 {
                vec.append(1.0)
            } else {
                //vec.append(sigfig_round(mat[i][j], to: 5))
                vec.append(mat[i][j])
            }
        }
        result.append(vec)
    }
    return result
}


// find the median of a 1D array, ignoring NaN values
func median(arr: [Double]) -> Double {
    var new_arr = [Double]()
    for e in arr {
        if e.isNaN == false {
            new_arr.append(e)
        }
    }
    if arr.count % 2 == 0 {
        let first_mid = find_kth(arr: new_arr, k: new_arr.count/2)
        let second_mid = find_kth(arr: new_arr, k: new_arr.count/2 + 1)
        return (first_mid + second_mid)/2
    } else {
        let k = new_arr.count / 2 + 1
        return find_kth(arr: new_arr, k: k)
    }
}

func evidenceWeights(mat: [[[Double]]]) -> [[[Double]]] {
    var result = [[[Double]]]()
    let lowerLimit = Darwin.pow(0.2, 2.0)
    for layer in mat {
        var temp = elementWise(op: "^", left: layer, right: 2.0)
        for i in 0..<temp.count {
            for j in 0..<temp[0].count {
                if temp[i][j] < lowerLimit {
                    temp[i][j] = lowerLimit
                }
            }
        }
        result.append(temp)
    }
    return result
}

func transpose(mat: [[Double]]) -> [[Double]] {
    var new_mat = [[Double]]()
    for j in 0..<mat[0].count {
        var new_col = [Double]()
        for i in 0..<mat.count {
            new_col.append(mat[i][j])
        }
        new_mat.append(new_col)
    }
    return new_mat
}

//let a = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
//print(transpose(mat: a))


// returns MATLAB indices of elements in <arr> that are equal "==" to <val>
func find_1d(arr: [Double], val: Double) -> [Int] {
    var result = [Int]()
    for i in 0..<arr.count {
        if arr[i] == val {
            result.append(i+1)
        }
    }
    return result
}

// returns the int rep of <arr> by casting
func double_to_int(arr: [Double]) -> [Int] {
    var int_arr = [Int]()
    for i in 0..<arr.count {
        int_arr.append(Int(arr[i]))
    }
    return int_arr
}

// custom indexing by vectors
// replaces elements at all possible permutations of elements in the two input vectors by
// corresponding element in <val>
// assumes that <mat> is written as an array of column vectors
func replace_by_vector_indexing(mat: [[Double]], v1: [Int], v2: [Int], val: [Double]) -> [[Double]] {
    var filtered = mat
    var count = 0
    for j in v2 {
        for i in v1 {
            filtered[j][i] = val[count]
            count += 1
        }
    }
    return filtered
}


// analogous to <story> struct in MATLAB
struct story {
    var distMatsForAllTrials_ltv = [[[Double]]]()
    var trialStartTimes = [Double]()
    var trialStopTimes = [Double]()
    var trialDurations = [Double]()
    var evidenceWeight_ltv = [[Double]]()
    var nsItemsPerTrial = [Int:Double]()
    var estimate_RDM_ltv = [Double]()   // this is extra
}
