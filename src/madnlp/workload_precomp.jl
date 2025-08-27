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
    println("eval_f")
    println(w)
    println(f)
end

function _eval_g!(w::Vector{T}, g::Vector{T}) where T
	  g[1] = w[1]^2 + w[2]^2 - 1
    println("eval_g")
    println(w)
    println(g)
end

function _eval_jac_g!(w::Vector{T}, jac_g::Vector{T}) where T
    jac_g[1] = 2*w[1]
    jac_g[2] = 2*w[2]
    println("eval_jac_j")
    println(w)
    println(jac_g)
end

function _eval_grad_f!(w::Vector{T}, g::Vector{T}) where T
    g[1] = -4*b*w[1]*(w[2]-w[1]^2)-2*(a-w[1])
    g[2] = b*2*(w[2]-w[1]^2)
    println("eval_grad_f")
    println(w)
    println(g)
end

function _eval_h!(w::Vector{T},l::Vector{T}, h::Vector{T}) where T
    h[1] = (+2 -4*b*w[2] +12*b*w[1]^2)
    h[2] = (-4*b*w[1])
    h[3] = (2*b)
    println("eval_h")
    println(w)
    println(h)
end

function jac_struct(I::Ptr{Clong}, J::Ptr{Clong}, d::Ptr{Cvoid})::Cint
    I_::Vector{Int64} = unsafe_wrap(Array, I, 2)
    J_::Vector{Int64} = unsafe_wrap(Array, J, 2)
    _jac_struct(I_, J_)
    return Cint(0)
end

function hess_struct(I::Ptr{Clong}, J::Ptr{Clong}, d::Ptr{Cvoid})::Cint
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
    c_jac_struct = @cfunction(jac_struct, Cint, (Ptr{Clong}, Ptr{Clong}, Ptr{Cvoid}))
    c_hess_struct = @cfunction(hess_struct, Cint, (Ptr{Clong}, Ptr{Clong}, Ptr{Cvoid}))
    c_eval_f = @cfunction(eval_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_g = @cfunction(eval_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_grad_f = @cfunction(eval_grad_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_jac_g = @cfunction(eval_jac_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))
    c_eval_h = @cfunction(eval_h, Cint, (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}))

    opts_ptr_vec = Vector{Ptr{libMad.MadNLPOptsDict}}([C_NULL])
    opts_ptr = opts_ptr_vec[1]
    opts_ptr_ptr = pointer(opts_ptr_vec)
    nlp_ptr_vec = Vector{Ptr{libMad.CNLPModel{Cdouble}}}([C_NULL])
    nlp_ptr = nlp_ptr_vec[1]
    nlp_ptr_ptr = pointer(nlp_ptr_vec)
    solver_ptr_vec = Vector{Ptr{MadNLP.MadNLPSolver}}([C_NULL])
    solver_ptr = solver_ptr_vec[1]
    solver_ptr_ptr = pointer(solver_ptr_vec)

    x0 = Vector{Cdouble}([1.0, 1.0])
    println(x0)
    lvar = Vector{Cdouble}([-Inf, -Inf])
    uvar = Vector{Cdouble}([Inf, Inf])
    lcon = Vector{Cdouble}([0.0])
    ucon = Vector{Cdouble}([0.0])
    @compile_workload begin


        println("pointer at execute $(pointer(x0))")

        _name = "aname"
        libMad.nlpmodel_cpu_create(nlp_ptr_ptr,
                                   unsafe_convert(Cstring,_name),
                                   nvar, ncon,
                                   2, 3,
                                   pointer(x0),
                                   pointer(lvar), pointer(uvar),
                                   pointer(lcon), pointer(ucon),
                                   c_jac_struct, c_hess_struct,
                                   c_eval_f, c_eval_g,
                                   c_eval_grad_f, c_eval_jac_g,
                                   c_eval_h,
                                   C_NULL
                                   )
        nlp_ptr = nlp_ptr_vec[1]
        libMad.madnlpoptions_create_options_struct(opts_ptr_ptr)
        opts_ptr = opts_ptr_vec[1]

        _tol = "tol"
        _max_iter = "max_iter"
        _print_level = "print_level"
        _callback = "callback"
        _SparseCallback = "SparseCallback"
        _hessian_constant = "hessian_constant"
        libMad.madnlpoptions_set_float64_option(opts_ptr, unsafe_convert(Cstring,_tol), Cdouble(1e-6))
        libMad.madnlpoptions_set_int64_option(opts_ptr, unsafe_convert(Cstring,_max_iter), 2000)
        #madnlpoptions_set_int64_option(opts_ptr, unsafe_convert(Cstring,_print_level), 1)
        libMad.madnlpoptions_set_string_option(opts_ptr, unsafe_convert(Cstring,_callback), unsafe_convert(Cstring,_SparseCallback))
        libMad.madnlpoptions_set_bool_option(opts_ptr, unsafe_convert(Cstring,_hessian_constant), false)

        libMad.madnlp_create_solver(solver_ptr_ptr, nlp_ptr, opts_ptr)
        solver_ptr = solver_ptr_vec[1]
        libMad.madnlp_solve(solver_ptr, opts_ptr)
    end
end
