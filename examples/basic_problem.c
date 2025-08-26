#include "libMad.h"
#include <math.h>

int jac_structure(long* I, long* J, void* user_data)
{
  I[0] = 1;
  I[1] = 1;
  J[0] = 1;
  J[1] = 2;

  return 0;
}

int hess_structure(long* I, long* J, void* user_data)
{
  I[0] = 1;
  I[1] = 2;
  J[0] = 1;
  J[1] = 2;

  return 0;
}

int obj(double* x, double* f, void* user_data)
{
  *f = 0.5*((x[0]-2)*(x[0]-2) + (x[1]-2)*(x[1]-2));
	printf("%p : %f\n", (void*) f, 0.5*((x[0]-2)*(x[0]-2) + (x[1]-2)*(x[1]-2)));
  return 0;
}

int cons(double* x, double* c, void* user_data)
{
  *c = x[0] + x[1];

  return 0;
}

int grad(double* x, double* g, void* user_data)
{
  g[0] = x[0] - 2;
  g[1] = x[1] - 2;

  return 0;
}

int jac_coord(double* x, double* J, void* user_data)
{
  J[0] = 1;
  J[1] = 1;

  return 0;
}

int hess_coord(double obj_weight, double* x, double* y, double* H, void* user_data)
{
  H[0] = 1;
  H[1] = 1;

  return 0;
}

int main(int argc, char** argv)
{
  CNLPModel* nlp_ptr;
  MadNLPOptsDict* opts_ptr;
  MadNLPSolver* solver_ptr;
  MadNLPSolver* solver2_ptr;

  double* x0 = malloc(2*sizeof(double));
  x0[0] = 0; x0[1] = 0;
  double* lvar = malloc(2*sizeof(double));
  lvar[0] = 0; lvar[1] = 0;
  double* uvar = malloc(2*sizeof(double));
  uvar[0] = INFINITY; uvar[1] = INFINITY;
  double* lcon = malloc(1*sizeof(double));
  lcon[0] = -INFINITY;
  double* ucon = malloc(1*sizeof(double));
  ucon[0] = 1;

  nlpmodel_cpu_create(&nlp_ptr, "test_model",
		      2, 1,
		      2, 2,
		      x0,
		      lvar, uvar,
		      lcon, ucon,
		      &jac_structure, &hess_structure,
		      &obj, &cons,
		      &grad, &jac_coord,
		      &hess_coord,
		      NULL);

  madnlpoptions_create_options_struct(&opts_ptr);
	madnlpoptions_set_float64_option(opts_ptr, "tol", 1e-3);
  madnlp_create_solver(&solver_ptr, nlp_ptr, opts_ptr);
  madnlp_create_solver(&solver2_ptr, nlp_ptr, opts_ptr);
  madnlp_solve(solver_ptr, opts_ptr);
  madnlp_solve(solver2_ptr, opts_ptr);
  return 0;
}
