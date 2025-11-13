#include "libMad.h"
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

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

int obj(const double* x, double* f, void* user_data)
{
  *f = 0.5*((x[0]-2)*(x[0]-2) + (x[1]-2)*(x[1]-2));
  return 0;
}

int cons(const double* x, double* c, void* user_data)
{
  *c = x[0] + x[1];

  return 0;
}

int grad(const double* x, double* g, void* user_data)
{
  g[0] = x[0] - 2;
  g[1] = x[1] - 2;

  return 0;
}

int jac_coord(const double* x, double* J, void* user_data)
{
  J[0] = 1;
  J[1] = 1;

  return 0;
}

int hess_coord(double obj_weight, const double* x, const double* y, double* H, void* user_data)
{
  H[0] = 1;
  H[1] = 1;

  return 0;
}

int main(int argc, char** argv)
{
  CNLPModel* nlp_ptr;
  OptsDict* opts1_ptr;
  OptsDict* opts2_ptr;
  OptsDict* opts3_ptr;
  MadNLPSolver* solver1_ptr;
  MadNLPSolver* solver2_ptr;
  MadNLPSolver* solver3_ptr;
	MadNLPExecutionStats* stats1_ptr;
	MadNLPExecutionStats* stats2_ptr;
	MadNLPExecutionStats* stats3_ptr;

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

  libmad_nlpmodel_create(&nlp_ptr, "test_model",
		      2, 1,
		      2, 2,
		      &jac_structure, &hess_structure,
		      &obj, &cons,
		      &grad, &jac_coord,
		      &hess_coord,
		      NULL);
	libmad_nlpmodel_set_numerics(nlp_ptr,
															 x0, NULL,
															 lvar, uvar,
															 lcon, ucon);

  libmad_create_options_dict(&opts1_ptr);
  libmad_create_options_dict(&opts2_ptr);
  libmad_create_options_dict(&opts3_ptr);
	libmad_set_double_option(opts1_ptr, "tol", 1e-8);
	libmad_set_string_option(opts1_ptr, "linear_solver", "MumpsSolver");
	libmad_set_string_option(opts2_ptr, "linear_solver", "Ma97Solver");
	libmad_set_string_option(opts3_ptr, "linear_solver", "Ma27Solver");
  madnlp_create_solver(&solver1_ptr, nlp_ptr, opts1_ptr);
  madnlp_create_solver(&solver2_ptr, nlp_ptr, opts2_ptr);
  madnlp_create_solver(&solver3_ptr, nlp_ptr, opts3_ptr);
  madnlp_solve(solver1_ptr, opts1_ptr, &stats1_ptr);
  madnlp_solve(solver2_ptr, opts2_ptr, &stats2_ptr);
  madnlp_solve(solver3_ptr, opts3_ptr, &stats3_ptr);

	bool success;
	double* solution = malloc(2*sizeof(double));
	double objective;

	madnlp_get_success(stats1_ptr, &success);
	madnlp_get_solution(stats1_ptr, solution);
	madnlp_get_obj(stats1_ptr, &objective);

	printf("Success: %s\n", success ? "true" : "false");
	printf("Objective: %f\n", objective);
	printf("Solution: [%f, ", solution[0]);
	printf("%f]\n", solution[1]);

	madnlp_delete_solver(solver1_ptr);
	madnlp_delete_solver(solver2_ptr);
	madnlp_delete_solver(solver3_ptr);

	madnlp_delete_stats(stats1_ptr);
	madnlp_delete_stats(stats2_ptr);
	madnlp_delete_stats(stats3_ptr);
  return 0;
}
