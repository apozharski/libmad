push!(function_sigs, """int qpmodel_cpu_create(QuadraticModel** qp_ptr_ptr,
                                               char* name,
                                               long nvar, long ncon,
                                               long nnzh, long nnza,
                                               double* c,
                                               double* lvar, double* uvar,
                                               double* lcon, double* ucon,
                                               long* I_H, long* J_H, double* H,
                                               long* I_A, long* J_A, double* A,
                                               )"""
      )
push!(dummy_structs, "QuadraticModel")

Base.@ccallable function qpmodel_cpu_create(qp_ptr_ptr::Ptr{Ptr{QuadraticModel{Cdouble}}},
                                            name::Cstring,
                                            nvar::Clong, ncon::Clong,
                                            nnzh::Clong, nnza::Clong,
                                            c::Ptr{Cdouble},
                                            lvar::Ptr{Cdouble}, uvar::Ptr{Cdouble},
                                            lcon::Ptr{Cdouble}, ucon::Ptr{Cdouble},
                                            Hrows::Ptr{Clong}, Hcols::Ptr{Clong}, Hvals::Ptr{Cdouble},
                                            Arows::Ptr{Clong}, Acols::Ptr{Clong}, Avals::Ptr{Cdouble},
                                            )::Cint

    qp = QuadraticModel(
        unsafe_wrap(Vector{Cdouble}, c, nvar),
        unsafe_wrap(Vector{Clong}, Hrows, nnzh),
        unsafe_wrap(Vector{Clong}, Hcols, nnzh),
        unsafe_wrap(Vector{Cdouble}, Hvals, nnzh);
        Arows=unsafe_wrap(Vector{Clong}, Arows, nnza),
        Acols=unsafe_wrap(Vector{Clong}, Acols, nnza),
        Avals=unsafe_wrap(Vector{Cdouble}, Avals, nnza),
        lvar=unsafe_wrap(Vector{Cdouble), lvar, nvar),
        uvar=unsafe_wrap(Vector{Cdouble), uvar, nvar),
        lcon=unsafe_wrap(Vector{Cdouble), lcon, ncon),
        ucon=unsafe_wrap(Vector{Cdouble), ucon, ncon),
        name = unsafe_string(name)
    )
    qp_ptr = pointer_from_objref(nlp)
    unsafe_store!(qp_ptr_ptr, qp_ptr)
    libmad_refs[qp_ptr] = qp

    return Cint(0)
end

push!(function_sigs, "int qpmodel_delete_model(QuadraticModel* model_ptr)")
Base.@ccallable function qpmodel_delete_model(model_ptr::Ptr{QuadraticModel{Cdouble}})::Cint
    if haskey(libmad_refs, model_ptr)
        delete!(libmad_refs, model_ptr)
        return Cint(0)
    else
        return Cint(1)
    end
end
