import jax
import jax.numpy as jnp
import numpy as np
import sys

def load_matrix(path):
    data = np.loadtxt(path, delimiter=",")
    return data

@jax.jit
def compute(A, B, C, D, E):
    return (A @ B) +  (C @ D @ E)


if __name__ == "__main__":
    matrix_path = sys.argv[1]

    # Load matrices from CSV
    A_np = load_matrix(f"{matrix_path}/A_matrix.csv")
    B_np = load_matrix(f"{matrix_path}/B_matrix.csv")
    C_np = load_matrix(f"{matrix_path}/C_matrix.csv")
    D_np = load_matrix(f"{matrix_path}/D_matrix.csv")
    E_np = load_matrix(f"{matrix_path}/E_matrix.csv")


    A = jnp.array(A_np)
    B = jnp.array(B_np)
    C = jnp.array(C_np)
    D = jnp.array(D_np)
    E = jnp.array(E_np)

    Y = compute(A, B, C, D, E)

