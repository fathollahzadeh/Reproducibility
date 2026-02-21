import torch
import pandas as pd
import time
from concurrent.futures import ThreadPoolExecutor
import os
import sys

# Enable full CPU parallelism
torch.set_num_threads(os.cpu_count())
torch.set_num_interop_threads(os.cpu_count())

device = "cpu"


# -------------------------
# CSV LOADER
# -------------------------
def load_matrix(path):
    return torch.tensor(pd.read_csv(path, header=None).values,
                        dtype=torch.float32,
                        device=device)


# -------------------------
# EineDecomp-style parallel matmul
# -------------------------
def eine_parallel_matmul(A, B, chunks=None):
    if chunks is None:
        chunks = os.cpu_count()

    splits = torch.chunk(A, chunks, dim=0)

    def worker(x):
        return x @ B

    with ThreadPoolExecutor(max_workers=chunks) as ex:
        results = list(ex.map(worker, splits))

    return torch.cat(results, dim=0)


# -------------------------
# ATLAS cost model
# -------------------------
def matmul_cost(m, k, n):
    return m * k * n


# -------------------------
# ATLAS planner for CDE
# -------------------------
def atlas_chain_3(C, D, E):
    m, k = C.shape
    _, n = D.shape
    _, p = E.shape

    cost_cd_e = matmul_cost(m, k, n) + matmul_cost(m, n, p)
    cost_c_de = matmul_cost(k, n, p) + matmul_cost(m, k, p)

    if cost_cd_e <= cost_c_de:
        CD = eine_parallel_matmul(C, D)
        return eine_parallel_matmul(CD, E)
    else:
        DE = eine_parallel_matmul(D, E)
        return eine_parallel_matmul(C, DE)


# -------------------------
# FULL ATLAS PIPELINE
# -------------------------
def atlas_pipeline(A, B, C, D, E):
    AB = eine_parallel_matmul(A, B)
    CDE = atlas_chain_3(C, D, E)
    return AB + CDE


# -------------------------
# MAIN
# -------------------------
if __name__ == "__main__":
    matrix_path = sys.argv[1]

    A = load_matrix(f"{matrix_path}/A_matrix.csv")
    B = load_matrix(f"{matrix_path}/B_matrix.csv")
    C = load_matrix(f"{matrix_path}/C_matrix.csv")
    D = load_matrix(f"{matrix_path}/D_matrix.csv")
    E = load_matrix(f"{matrix_path}/E_matrix.csv")

    start = time.time()
    result = atlas_pipeline(A, B, C, D, E)
    end = time.time()

    print("Result shape:", result.shape)
    print("Runtime:", end - start, "seconds")
