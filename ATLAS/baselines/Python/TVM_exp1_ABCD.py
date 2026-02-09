import tvm
from tvm import te
import numpy as np
import sys

def load_matrix(path):
    return np.loadtxt(path, delimiter=",").astype("float32")

def model(A, B, C, D):
    return A @ B @ C @ D


if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A_np = load_matrix(f"{matrix_path}/A_matrix.csv")
    B_np = load_matrix(f"{matrix_path}/B_matrix.csv")
    C_np = load_matrix(f"{matrix_path}/C_matrix.csv")
    D_np = load_matrix(f"{matrix_path}/D_matrix.csv")

    M, K1 = A_np.shape
    K1b, K2 = B_np.shape
    K2b, K3 = C_np.shape
    K3b, N = D_np.shape

    A = te.placeholder((M, K1), name="A")
    B = te.placeholder((K1, K2), name="B")
    C = te.placeholder((K2, K3), name="C")
    D = te.placeholder((K3, N), name="D")

    k1 = te.reduce_axis((0, K1), name="k1")
    k2 = te.reduce_axis((0, K2), name="k2")
    k3 = te.reduce_axis((0, K3), name="k3")

    AB = te.compute((M, K2), lambda i, j: te.sum(A[i, k1] * B[k1, j], axis=k1), name="AB")

    ABC = te.compute((M, K3), lambda i, j: te.sum(AB[i, k2] * C[k2, j], axis=k2), name="ABC")

    Y = te.compute((M, N), lambda i, j: te.sum(ABC[i, k3] * D[k3, j], axis=k3), name="Y")

    s = te.create_schedule(Y.op)
    func = tvm.build(s, [A, B, C, D, Y], target="llvm")

    dev = tvm.cpu()

    A_tvm = tvm.nd.array(A_np.astype("float32"), dev)
    B_tvm = tvm.nd.array(B_np.astype("float32"), dev)
    C_tvm = tvm.nd.array(C_np.astype("float32"), dev)
    D_tvm = tvm.nd.array(D_np.astype("float32"), dev)

    Y_tvm = tvm.nd.empty((M, N), dtype="float32", device=dev)

    func(A_tvm, B_tvm, C_tvm, D_tvm, Y_tvm)