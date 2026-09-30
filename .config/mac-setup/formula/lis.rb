class Lis < Formula
  desc "Library of Iterative Solvers for linear systems"
  homepage "https://www.ssisc.org/lis/"
  url "https://www.ssisc.org/lis/dl/lis-2.1.13.zip"
  sha256 "632600f6400c02876734ddf0d610ab8b09c0febed94467350ce195c064147c17"
  license "BSD-3-Clause"

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-shared", "--disable-test"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"solve.c").write <<~C
      #include <lis.h>
      int main(int argc, char **argv) {
        LIS_MATRIX a;
        LIS_VECTOR b, x;
        LIS_SOLVER solver;
        if (lis_initialize(&argc, &argv)) return 1;
        if (lis_matrix_create(LIS_COMM_WORLD, &a)) return 2;
        if (lis_matrix_set_size(a, 0, 1)) return 3;
        if (lis_matrix_set_value(LIS_INS_VALUE, 0, 0, 2.0, a)) return 4;
        if (lis_matrix_assemble(a)) return 5;
        if (lis_vector_duplicate(a, &b) || lis_vector_duplicate(a, &x)) return 6;
        if (lis_vector_set_value(LIS_INS_VALUE, 0, 4.0, b)) return 7;
        if (lis_solver_create(&solver)) return 8;
        if (lis_solve(a, b, x, solver)) return 9;
        LIS_SCALAR value;
        if (lis_vector_get_value(x, 0, &value)) return 10;
        lis_solver_destroy(solver);
        lis_vector_destroy(x);
        lis_vector_destroy(b);
        lis_matrix_destroy(a);
        lis_finalize();
        return value > 1.999 && value < 2.001 ? 0 : 11;
      }
    C
    system ENV.cc, "solve.c", "-I#{include}", "-L#{lib}", "-llis", "-o", "solve"
    system "./solve"
  end
end
