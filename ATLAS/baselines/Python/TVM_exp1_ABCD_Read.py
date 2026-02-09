import tvm
from tvm import te
import numpy as np
import sys

def load_matrix(path):
    return np.loadtxt(path, delimiter=",").astype("float32")

if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A_np = load_matrix(f"{matrix_path}/A_matrix.csv")
    B_np = load_matrix(f"{matrix_path}/B_matrix.csv")
    C_np = load_matrix(f"{matrix_path}/C_matrix.csv")
    D_np = load_matrix(f"{matrix_path}/D_matrix.csv")
