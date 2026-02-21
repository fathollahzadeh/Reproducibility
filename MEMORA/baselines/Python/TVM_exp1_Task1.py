import tvm
from tvm import te
import numpy as np
import sys

def load_matrix(path):
    return np.loadtxt(path, delimiter=",").astype("float32")

def model(A, B, C, D):
    return (A @ B) + (C @ D @ E)


if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A_np = load_matrix(f"{matrix_path}/A_matrix.csv")
    B_np = load_matrix(f"{matrix_path}/B_matrix.csv")
    C_np = load_matrix(f"{matrix_path}/C_matrix.csv")
    D_np = load_matrix(f"{matrix_path}/D_matrix.csv")
    E_np = load_matrix(f"{matrix_path}/E_matrix.csv")

    # Shapes
    M, K1 = A_np.shape
    K1b, N = B_np.shape

    M2, K2 = C_np.shape
    K2b, K3 = D_np.shape
    K3b, N2 = E_np.shape

    # Placeholders
    A = te.placeholder((M, K1), name="A")
    B = te.placeholder((K1, N), name="B")

    C = te.placeholder((M, K2), name="C")
    D = te.placeholder((K2, K3), name="D")
    E = te.placeholder((K3, N), name="E")

    # Reduce axes
    k1 = te.reduce_axis((0, K1), name="k1")
    k2 = te.reduce_axis((0, K2), name="k2")
    k3 = te.reduce_axis((0, K3), name="k3")

    # A @ B
    AB = te.compute((M, N), lambda i, j: te.sum(A[i, k1] * B[k1, j], axis=k1), name="AB",)

    # C @ D
    CD = te.compute((M, K3), lambda i, j: te.sum(C[i, k2] * D[k2, j], axis=k2), name="CD",)

    # (C @ D) @ E
    CDE = te.compute((M, N), lambda i, j: te.sum(CD[i, k3] * E[k3, j], axis=k3), name="CDE",)

    # Final result: (A @ B) + (C @ D @ E)
    Y = te.compute((M, N), lambda i, j: AB[i, j] + CDE[i, j], name="Y",)

    # Schedule
    s = te.create_schedule(Y.op)
    s[Y].parallel(s[Y].op.axis[0])
    s[AB].parallel(s[AB].op.axis[0])
    s[CD].parallel(s[CD].op.axis[0])
    s[CDE].parallel(s[CDE].op.axis[0])

    func = tvm.build( s, [A, B, C, D, E, Y], target="llvm -libs=openmp")

    dev = tvm.cpu()

    A_tvm = tvm.nd.array(A_np.astype("float32"), dev)
    B_tvm = tvm.nd.array(B_np.astype("float32"), dev)
    C_tvm = tvm.nd.array(C_np.astype("float32"), dev)
    D_tvm = tvm.nd.array(D_np.astype("float32"), dev)
    E_tvm = tvm.nd.array(E_np.astype("float32"), dev)

    Y_tvm = tvm.nd.empty((M, N), dtype="float32", device=dev)

    func(A_tvm, B_tvm, C_tvm, D_tvm, E_tvm, Y_tvm)
