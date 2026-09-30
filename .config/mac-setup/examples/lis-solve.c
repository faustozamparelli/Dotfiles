#include <lis.h>
#include <stdio.h>

int main(int argc, char **argv) {
    LIS_MATRIX a;
    LIS_VECTOR b, x;
    LIS_SOLVER solver;
    LIS_SCALAR x0, x1;

    if (lis_initialize(&argc, &argv) != LIS_SUCCESS) return 1;
    if (lis_matrix_create(LIS_COMM_WORLD, &a) != LIS_SUCCESS) return 1;
    if (lis_matrix_set_size(a, 0, 2) != LIS_SUCCESS) return 1;

    /* [4 1; 1 3] x = [1; 2] */
    if (lis_matrix_set_value(LIS_INS_VALUE, 0, 0, 4.0, a) != LIS_SUCCESS) return 1;
    if (lis_matrix_set_value(LIS_INS_VALUE, 0, 1, 1.0, a) != LIS_SUCCESS) return 1;
    if (lis_matrix_set_value(LIS_INS_VALUE, 1, 0, 1.0, a) != LIS_SUCCESS) return 1;
    if (lis_matrix_set_value(LIS_INS_VALUE, 1, 1, 3.0, a) != LIS_SUCCESS) return 1;
    if (lis_matrix_assemble(a) != LIS_SUCCESS) return 1;

    if (lis_vector_duplicate(a, &b) != LIS_SUCCESS) return 1;
    if (lis_vector_duplicate(a, &x) != LIS_SUCCESS) return 1;
    if (lis_vector_set_value(LIS_INS_VALUE, 0, 1.0, b) != LIS_SUCCESS) return 1;
    if (lis_vector_set_value(LIS_INS_VALUE, 1, 2.0, b) != LIS_SUCCESS) return 1;

    if (lis_solver_create(&solver) != LIS_SUCCESS) return 1;
    if (lis_solver_set_option("-i cg -tol 1.0e-12", solver) != LIS_SUCCESS) return 1;
    if (lis_solve(a, b, x, solver) != LIS_SUCCESS) return 1;
    if (lis_vector_get_value(x, 0, &x0) != LIS_SUCCESS) return 1;
    if (lis_vector_get_value(x, 1, &x1) != LIS_SUCCESS) return 1;

    printf("x = (%.9f, %.9f)\n", (double)x0, (double)x1);
    lis_solver_destroy(solver);
    lis_vector_destroy(x);
    lis_vector_destroy(b);
    lis_matrix_destroy(a);
    lis_finalize();
    return 0;
}
