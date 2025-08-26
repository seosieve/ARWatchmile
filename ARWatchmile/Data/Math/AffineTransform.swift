//
//  AffineTransform.swift
//  ARWatchmile
//
//  Created by 베스텔라랩 on 8/1/25.
//

import Accelerate
import CoreGraphics
import simd

enum AffineTransform {
    /// 최소제곱으로 from → to 변환을 근사하는 CGAffineTransform
    static func calculate(from src: [SIMD2<Float>], to dst: [SIMD2<Float>]) -> CGAffineTransform {
        let n = min(src.count, dst.count)
        guard n >= 3 else { return .identity }

        // A (2n x 6), b (2n)
        var A = [Double](repeating: 0, count: 2*n*6)
        var b = [Double](repeating: 0, count: 2*n)

        for i in 0..<n {
            let sx = Double(src[i].x), sy = Double(src[i].y)
            let dx = Double(dst[i].x), dy = Double(dst[i].y)

            // x' = a*sx + c*sy + tx
            A[(2*i)*6 + 0] = sx
            A[(2*i)*6 + 1] = sy
            A[(2*i)*6 + 2] = 1
            // y' = b*sx + d*sy + ty
            A[(2*i+1)*6 + 3] = sx
            A[(2*i+1)*6 + 4] = sy
            A[(2*i+1)*6 + 5] = 1

            b[2*i] = dx
            b[2*i+1] = dy
        }

        // AtA (6x6), Atb (6)
        var AtA = [Double](repeating: 0, count: 36)
        var Atb = [Double](repeating: 0, count: 6)

        cblas_dgemm(CblasRowMajor, CblasTrans, CblasNoTrans, 6, 6, Int32(2*n), 1.0, A, 6, A, 6, 0.0, &AtA, 6)
        cblas_dgemv(CblasRowMajor, CblasTrans, Int32(2*n), 6, 1.0, A, 6, b, 1, 0.0, &Atb, 1)

        // 풀기
        var N: __CLPK_integer = 6
        var NRHS: __CLPK_integer = 1
        var LDA: __CLPK_integer = 6
        var LDB: __CLPK_integer = 6
        var ipiv = [__CLPK_integer](repeating: 0, count: 6)
        var info: __CLPK_integer = 0
        var ata = AtA
        var x = Atb

        dgesv_(&N, &NRHS, &ata, &LDA, &ipiv, &x, &LDB, &info)
        guard info == 0 else { return .identity }

        // x = [a, c, tx, b, d, ty]
        return CGAffineTransform(
            a: CGFloat(x[0]), b: CGFloat(x[3]),
            c: CGFloat(x[1]), d: CGFloat(x[4]),
            tx: CGFloat(x[2]), ty: CGFloat(x[5])
        )
    }
}
