import UIKit

func transpose(mat: [[Double]]) -> [[Double]] {
    var new_cols = [Double]()
    var new_mat = [[Double]](repeating: new_cols, count: mat.count)
    for j in 0..<mat.count {
        for i in 0..<mat[0].count {
            new_mat[i].append(mat[j][i])
        }
    }
    return new_mat
}

//let a = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
//print(transpose(mat: a))
