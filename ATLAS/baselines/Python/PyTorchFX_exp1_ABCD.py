import torch
import torch.fx as fx
import numpy as np
import sys

def load_matrix(path):
    data = np.loadtxt(path, delimiter=",")
    return torch.tensor(data, dtype=torch.float32)

def model(A, B, C, D):
    return A @ B @ C @ D


if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A = load_matrix(f"{matrix_path}/A_matrix.csv")
    B = load_matrix(f"{matrix_path}/B_matrix.csv")
    C = load_matrix(f"{matrix_path}/C_matrix.csv")
    D = load_matrix(f"{matrix_path}/D_matrix.csv")


    # Trace graph
    # traced = fx.symbolic_trace(model)
    # print(traced.graph)

    # Run computation
    Y = model(A, B, C, D)
    # print("Result:\n", Y)

