#include "libMad.h"

int jac_structure(long* I, long* J, void* user_data){

}

int hess_structure(long* I, long* J, void* user_data){

}

int obj(double* x, double* c, void* user_data){

}

int cons(double* x, double* c, void* user_data){

}

int grad(double* x, double* g, void* user_data){

}

int jac_coord(double* x, double* J, void* user_data){

}

int hess_coord(double obj_weight, double* x, double* y, double* H, void* user_data){

}

int main(int argc, char** argv)
{
	CNLPModel* model_ptr;
	MadNLPOptsDict* opts_ptr;
	MadNLPSolver* solver_ptr;

	double* x0 = malloc(2*sizeof(double))
	double* lvar = malloc(2*sizeof(double))
	double* uvar = malloc(2*sizeof(double))
	double* lcon = malloc(1*sizeof(double))
	double* ucon = malloc(1*sizeof(double))

	nlpmodel_cpu_create(&model_ptr, "test_model",
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
	madnlp_create_solver(&solver_ptr, nlp_ptr, opts_ptr);
	madnlp_solve(solver_ptr, opts_ptr);
	return 0;
}
