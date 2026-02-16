import numpy as np
import pandas as pd
import multiprocessing as mp
import os
import sys
import torch

# ------------------------------------------------------------
# Automatic CPU detection
# ------------------------------------------------------------

CPU_COUNT = os.cpu_count()

os.environ["OMP_NUM_THREADS"] = str(CPU_COUNT)
os.environ["MKL_NUM_THREADS"] = str(CPU_COUNT)
os.environ["OPENBLAS_NUM_THREADS"] = str(CPU_COUNT)

torch.set_num_threads(CPU_COUNT)

print("Detected CPUs:", CPU_COUNT)

# ------------------------------------------------------------
# Load matrices
# ------------------------------------------------------------

def load_matrix(path):
    return pd.read_csv(path, header=None).values.astype(np.float32)

# ------------------------------------------------------------
# ATLAS optimizer
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
# Backends
# ------------------------------------------------------------

def numpy_mm(A, B):
    return A @ B

def torch_mm(A, B):
    A = torch.from_numpy(A)
    B = torch.from_numpy(B)
    return (A @ B).numpy()

# ------------------------------------------------------------
# EineDecom runtime
# ------------------------------------------------------------

def parallel_mm(A, B, backend="numpy"):
    chunks = np.array_split(A, CPU_COUNT, axis=0)

    if backend == "numpy":
        func = numpy_mm
    else:
        func = torch_mm

    with mp.Pool(CPU_COUNT) as pool:
        parts = pool.starmap(func, [(c, B) for c in chunks])

    return np.vstack(parts)

# ------------------------------------------------------------
# Execute plan
# ------------------------------------------------------------

def execute(A, B, C, D, order, backend="torch"):

    def mm(X, Y):
        return parallel_mm(X, Y, backend)

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

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

if __name__ == "__main__":
    matrix_path = sys.argv[1]
    mp.set_start_method("spawn", force=True)

    A = load_matrix(f"{matrix_path}/A_matrix.csv")
    B = load_matrix(f"{matrix_path}/B_matrix.csv")
    C = load_matrix(f"{matrix_path}/C_matrix.csv")
    D = load_matrix(f"{matrix_path}/D_matrix.csv")


    best, costs = atlas_optimize(A, B, C, D)

    print("\nATLAS selected:", best)

    Y = execute(A, B, C, D, best, backend="torch")

    print("Output shape:", Y.shape)
