using MadNLP
using Base: unsafe_convert
# Built from MadNLP_c: https://github.com/jgillis/madnlp_c
nvar::Int64 = 2
ncon::Int64 = 1

a::Float64 = 1.0
b::Float64 = 100.0

function _jac_struct(I::Vector{T}, J::Vector{T}) where T
    I[1] = 1
    I[2] = 1
    J[1] = 1
    J[2] = 2
    println(I)
    println(J)
end

function _hess_struct(I::Vector{T}, J::Vector{T}) where T
    I[1] = 1
    I[2] = 1
    I[3] = 2
    J[1] = 1
    J[2] = 2
    J[3] = 2
    println(I)
    println(J)
end

function _eval_f!(w::Vector{T}, f::Vector{T}) where T
	  f[1] = (a-w[1])^2 + b*(w[2]-w[1]^2)^2
end

function _eval_g!(w::Vector{T}, g::Vector{T}) where T
	  g[1] = w[1]^2 + w[2]^2 - 1
end

function _eval_jac_g!(w::Vector{T}, jac_g::Vector{T}) where T
    jac_g[1] = 2*w[1]
    jac_g[2] = 2*w[2]
end

function _eval_grad_f!(w::Vector{T}, g::Vector{T}) where T
    g[1] = -4*b*w[1]*(w[2]-w[1]^2)-2*(a-w[1])
    g[2] = b*2*(w[2]-w[1]^2)
end

function _eval_h!(w::Vector{T},l::Vector{T}, h::Vector{T}) where T
    h[1] = (+2 -4*b*w[2] +12*b*w[1]^2)
    h[2] = (-4*b*w[1])
    h[3] = (2*b)
end

function jac_struct(I::Ptr{Clonglong}, J::Ptr{Clonglong}, d::Ptr{Cvoid})::Cint
    I_::Vector{Int64} = unsafe_wrap(Array, I, 2)
    J_::Vector{Int64} = unsafe_wrap(Array, J, 2)
    _jac_struct(I_, J_)
    return Cint(0)
end

function hess_struct(I::Ptr{Clonglong}, J::Ptr{Clonglong}, d::Ptr{Cvoid})::Cint
    I_::Vector{Int64} = unsafe_wrap(Array, I, 3)
    J_::Vector{Int64} = unsafe_wrap(Array, J, 3)
    _hess_struct(I_, J_)
    return Cint(0)
end

function eval_f(Cw::Ptr{Cdouble},Cf::Ptr{Cdouble}, d::Ptr{Cvoid})::Cint
    w::Vector{Float64} = unsafe_wrap(Array, Cw, nvar)
    f::Vector{Float64} = unsafe_wrap(Array, Cf, 1)
    _eval_f!(w,f)
    return Cint(0)
end

function eval_g(w::Ptr{Cdouble},Ccons::Ptr{Cdouble}, d::Ptr{Cvoid})::Cint
    w::Vector{Float64} = unsafe_wrap(Array, w, nvar)
    cons::Vector{Float64} = unsafe_wrap(Array, Ccons, ncon)
    _eval_g!(w,cons)
    return Cint(0)
end

function eval_grad_f(Cw::Ptr{Cdouble},Cgrad::Ptr{Cdouble}, d::Ptr{Cvoid})::Cint
    w::Vector{Float64} = unsafe_wrap(Array, Cw, nvar)
    grad::Vector{Float64} = unsafe_wrap(Array, Cgrad, 2)
    _eval_grad_f!(w,grad)
    return Cint(0)
end

function eval_jac_g(w::Ptr{Cdouble}, Cjac_q::Ptr{Cdouble}, d::Ptr{Cvoid})::Cint
    w::Vector{Float64} = unsafe_wrap(Array, w, nvar)
    jac_g::Vector{Float64} = unsafe_wrap(Array, Cjac_q, 2)
    _eval_jac_g!(w,jac_g)
    return Cint(0)
end

function eval_h(obj_scale::Cdouble, Cw::Ptr{Cdouble}, Cl::Ptr{Cdouble}, Chess::Ptr{Cdouble}, d::Ptr{Cvoid})::Cint
    w::Vector{Float64} = unsafe_wrap(Array, Cw, nvar)
    l::Vector{Float64} = unsafe_wrap(Array, Cl, ncon)
    hess::Vector{Float64} = unsafe_wrap(Array, Chess, 3)
    _eval_h!(w,l,hess)
    return Cint(0)
end

@setup_workload begin
    c_jac_struct = @cfunction(jac_struct, Cint, (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cvoid}))
    c_hess_struct = @cfunction(hess_struct, Cint, (Ptr{Clonglong}, Ptr{Clonglong}, Ptr{Cvoid}))
    c_eval_f = @cfunction(eval_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_g = @cfunction(eval_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_grad_f = @cfunction(eval_grad_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_jac_g = @cfunction(eval_jac_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_h = @cfunction(eval_h, Cint, (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))

    # Structures
    opts_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    opts_ptr = opts_ptr_vec[1]
    opts_ptr_ptr = pointer(opts_ptr_vec)
    nlp_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    nlp_ptr = nlp_ptr_vec[1]
    nlp_ptr_ptr = pointer(nlp_ptr_vec)
    solver_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    solver_ptr = solver_ptr_vec[1]
    solver_ptr_ptr = pointer(solver_ptr_vec)
    stats_ptr_vec = Vector{Ptr{Cvoid}}([C_NULL])
    stats_ptr = stats_ptr_vec[1]
    stats_ptr_ptr = pointer(stats_ptr_vec)

    o_success = Vector{Cuchar}([false])
    o_obj = Vector{Cdouble}(undef, 1)
    o_solution = Vector{Cdouble}(undef, 2)
    o_multipliers_L = Vector{Cdouble}(undef, 2)
    o_multipliers_U = Vector{Cdouble}(undef, 2)
    o_constraints = Vector{Cdouble}(undef, 1)
    o_multipliers = Vector{Cdouble}(undef, 1)

    x0 = Vector{Cdouble}([1.0, 1.0])

    println(x0)
    lvar = Vector{Cdouble}([-Inf, -Inf])
    uvar = Vector{Cdouble}([Inf, Inf])
    lcon = Vector{Cdouble}([0.0])
    ucon = Vector{Cdouble}([0.0])
    # until we figure out a workaround for CUDA/HSL
    # We only precompile the basic solvers.
    for ls in ["CHOLMODSolver", "LapackCPUSolver", "LDLSolver", "MumpsSolver", "UmfpackSolver"]
        for kkt in keys(KKT_DICT)
            GC.@preserve x0 lvar uvar lcon ucon begin
                @compile_workload begin
                    try
                        _name = "aname"
                        libMad.libmad_nlpmodel_create(nlp_ptr_ptr,
                                                      unsafe_convert(Cstring,_name),
                                                      nvar, ncon,
                                                      2, 3,
                                                      c_jac_struct, c_hess_struct,
                                                      c_eval_f, c_eval_g,
                                                      c_eval_grad_f, c_eval_jac_g,
                                                      c_eval_h,
                                                      Ptr{Cvoid}(C_NULL)
                                                      )
                        nlp_ptr = nlp_ptr_vec[1]
                        libMad.libmad_nlpmodel_set_numerics(nlp_ptr,
                                                           pointer(x0), Ptr{Cdouble}(C_NULL),
                                                           pointer(lvar), pointer(uvar),
                                                           pointer(lcon), pointer(ucon)
                                                           )

                        nlp_ptr = nlp_ptr_vec[1]
                        libMad.libmad_create_options_dict(opts_ptr_ptr)
                        opts_ptr = opts_ptr_vec[1]

                        _tol = "tol"
                        _max_iter = "max_iter"
                        _print_level = "print_level"
                        _callback = "callback"
                        _linear_solver = "linear_solver"
                        _SparseCallback = "SparseCallback"
                        _hessian_constant = "hessian_constant"
                        libMad.libmad_set_double_option(opts_ptr, unsafe_convert(Cstring,_tol), Cdouble(1e-6))
                        libMad.libmad_set_int64_option(opts_ptr, unsafe_convert(Cstring,_max_iter), 2000)
                        libMad.libmad_set_string_option(opts_ptr, unsafe_convert(Cstring,_callback), unsafe_convert(Cstring,_SparseCallback))
                        libMad.libmad_set_string_option(opts_ptr, unsafe_convert(Cstring,_linear_solver), unsafe_convert(Cstring,ls))
                        libMad.libmad_set_bool_option(opts_ptr, unsafe_convert(Cstring,_hessian_constant), false)

                        libMad.madnlp_create_solver(solver_ptr_ptr, nlp_ptr, opts_ptr)
                        solver_ptr = solver_ptr_vec[1]
                        libMad.madnlp_solve(solver_ptr, opts_ptr, stats_ptr_ptr)
                        stats_ptr = stats_ptr_vec[1]

                        libMad.madnlp_get_success(stats_ptr, pointer(o_success))
                        libMad.madnlp_get_obj(stats_ptr, pointer(o_obj))
                        libMad.madnlp_get_solution(stats_ptr, pointer(o_solution))
                        libMad.madnlp_get_multipliers(stats_ptr, pointer(o_multipliers))
                        libMad.madnlp_get_constraints(stats_ptr, pointer(o_constraints))
                        libMad.madnlp_get_multipliers_L(stats_ptr, pointer(o_multipliers_L))
                        libMad.madnlp_get_multipliers_U(stats_ptr, pointer(o_multipliers_U))

                        println("success: $(o_success)")
                        println("obj: $(o_obj)")
                        println("solution: $(o_solution)")
                        println("multipliers: $(o_multipliers)")
                        println("constraints: $(o_constraints)")
                        println("multipliers_U: $(o_multipliers_U)")
                        println("multipliers_L: $(o_multipliers_L)")

                        libMad.madnlp_delete_solver(solver_ptr)
                    catch e
                        Base.printstyled("ERROR: "; color=:red, bold=true)
                        Base.showerror(stdout, e)
                        Base.show_backtrace(stdout, Base.catch_backtrace())
                        println("$((ls, kkt)) failed")
                    finally
                    end
                end
            end
        end
    end
end
