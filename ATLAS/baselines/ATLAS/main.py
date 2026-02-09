import numpy as np
import pandas as pd
import multiprocessing as mp
import sys

# ------------------------------------------------------------
# Load matrices from CSV
# ------------------------------------------------------------

def load_matrix(path):
    return pd.read_csv(path, header=None).values


# ------------------------------------------------------------
# ATLAS optimizer (cost-based contraction ordering)
# ------------------------------------------------------------

def matmul_flops(a_shape, b_shape):
    m, k = a_shape
    _, n = b_shape
    return 2 * m * k * n


def shape_after(a_shape, b_shape):
    return (a_shape[0], b_shape[1])


def atlas_optimize(A, B, C, D):
    shapes = [A.shape, B.shape, C.shape, D.shape]
    results = {}

    results["((AB)C)D"] = (
        matmul_flops(shapes[0], shapes[1]) +
        matmul_flops(shape_after(shapes[0], shapes[1]), shapes[2]) +
        matmul_flops(shape_after(shape_after(shapes[0], shapes[1]), shapes[2]), shapes[3])
    )

    results["(A(BC))D"] = (
        matmul_flops(shapes[1], shapes[2]) +
        matmul_flops(shapes[0], shape_after(shapes[1], shapes[2])) +
        matmul_flops(shape_after(shapes[0], shape_after(shapes[1], shapes[2])), shapes[3])
    )

    results["A((BC)D)"] = (
        matmul_flops(shapes[1], shapes[2]) +
        matmul_flops(shape_after(shapes[1], shapes[2]), shapes[3]) +
        matmul_flops(shapes[0], shape_after(shape_after(shapes[1], shapes[2]), shapes[3]))
    )

    results["(AB)(CD)"] = (
        matmul_flops(shapes[0], shapes[1]) +
        matmul_flops(shapes[2], shapes[3]) +
        matmul_flops(shape_after(shapes[0], shapes[1]), shape_after(shapes[2], shapes[3]))
    )

    results["A(B(CD))"] = (
        matmul_flops(shapes[2], shapes[3]) +
        matmul_flops(shapes[1], shape_after(shapes[2], shapes[3])) +
        matmul_flops(shapes[0], shape_after(shapes[1], shape_after(shapes[2], shapes[3])))
    )

    best = min(results, key=results.get)
    return best, results


# ------------------------------------------------------------
# EineDecom-style parallel GEMM runtime
# ------------------------------------------------------------

_B = None

def _init_pool(B):
    global _B
    _B = B


def _worker(A_chunk):
    return A_chunk @ _B


def parallel_matmul(A, B, nproc=8):
    chunks = np.array_split(A, nproc, axis=0)

    with mp.Pool(nproc, initializer=_init_pool, initargs=(B,)) as pool:
        parts = pool.map(_worker, chunks)

    return np.vstack(parts)


# ------------------------------------------------------------
# Execute contraction plan
# ------------------------------------------------------------

def execute(A, B, C, D, order, nproc=8):

    def mm(X, Y):
        return parallel_matmul(X, Y, nproc)

    if order == "((AB)C)D":
        return mm(mm(mm(A, B), C), D)

    elif order == "(A(BC))D":
        return mm(mm(A, mm(B, C)), D)

    elif order == "A((BC)D)":
        return mm(A, mm(mm(B, C), D))

    elif order == "(AB)(CD)":
        return mm(mm(A, B), mm(C, D))

    elif order == "A(B(CD))":
        return mm(A, mm(B, mm(C, D)))

    else:
        raise ValueError("Unknown order")


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

if __name__ == "__main__":
    matrix_path = sys.argv[1]
    number_threads = mp.cpu_count()

    # Load matrices from CSV
    A = load_matrix(f"{matrix_path}/A_matrix.csv")
    B = load_matrix(f"{matrix_path}/B_matrix.csv")
    C = load_matrix(f"{matrix_path}/C_matrix.csv")
    D = load_matrix(f"{matrix_path}/D_matrix.csv")

    best_order, costs = atlas_optimize(A, B, C, D)

    # print("\nContraction FLOPs:")
    # for k, v in costs.items():
    #     print(f"{k}: {v:.2e}")

    # print("\nATLAS selected:", best_order)

    Y = execute(A, B, C, D, best_order, nproc=number_threads)

    # print("\nOutput shape:", Y.shape)
