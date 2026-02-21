import numpy as np
import pandas as pd
import multiprocessing as mp
import sys

# ------------------------------------------------------------
# Load matrices from CSV
# ------------------------------------------------------------

def load_matrix(path):
    return pd.read_csv(path, header=None).values

if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A = load_matrix(f"{matrix_path}/A_matrix.csv")
    B = load_matrix(f"{matrix_path}/B_matrix.csv")
    C = load_matrix(f"{matrix_path}/C_matrix.csv")
    D = load_matrix(f"{matrix_path}/D_matrix.csv")

