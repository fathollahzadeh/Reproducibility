import torch
import torch.fx as fx
import numpy as np
import sys

def load_matrix(path):
    data = np.loadtxt(path, delimiter=",")
    return torch.tensor(data, dtype=torch.float32)


if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A = load_matrix(f"{matrix_path}/A_matrix.csv")
    B = load_matrix(f"{matrix_path}/B_matrix.csv")
    C = load_matrix(f"{matrix_path}/C_matrix.csv")
    D = load_matrix(f"{matrix_path}/D_matrix.csv")
