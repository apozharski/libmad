
mutable struct CNLPModel{T, VT<:AbstractVector{T}} <: AbstractNLPModel{T,VT}
    meta::NLPModelMeta{T, VT}
    counters::NLPModels.Counters
    jac_struct::Ptr{Cvoid}
    hess_struct::Ptr{Cvoid}
    eval_f::Ptr{Cvoid}
    eval_g::Ptr{Cvoid}
    eval_grad_f::Ptr{Cvoid}
    eval_jac_g::Ptr{Cvoid}
    eval_h::Ptr{Cvoid}
    user_data::Ptr{Cvoid}
end

push!(dummy_structs, "CNLPModel")
push!(function_sigs, """int libmad_nlpmodel_create(CNLPModel** nlp_ptr_ptr,
                                                   char* name,
                                                   long nvar, long ncon,
                                                   long nnzj, long nnzh,
                                                   void* jac_struct, void* hess_struct,
                                                   void* eval_f, void* eval_g,
                                                   void* eval_grad_f, void* eval_jac_g,
                                                   void* eval_h,
                                                   void* user_data)"""
      )

Base.@ccallable function libmad_nlpmodel_create(nlp_ptr_ptr::Ptr{Ptr{Cvoid}},
                                                name::Cstring,
                                                nvar::Clong, ncon::Clong,
                                                nnzj::Clong, nnzh::Clong,
                                                jac_struct::Ptr{Cvoid}, hess_struct::Ptr{Cvoid},
                                                eval_f::Ptr{Cvoid}, eval_g::Ptr{Cvoid},
                                                eval_grad_f::Ptr{Cvoid}, eval_jac_g::Ptr{Cvoid},
                                                eval_h::Ptr{Cvoid},
                                                user_data::Ptr{Cvoid})::Cint
    meta = NLPModelMeta(
        nvar,
        ncon = ncon,
        nnzj = nnzj,
        nnzh = nnzh,
        name = unsafe_string(name),
        minimize = true
    )

    nlp = CNLPModel(
        meta,
        NLPModels.Counters(),
        jac_struct,
        hess_struct,
        eval_f,
        eval_g,
        eval_grad_f,
        eval_jac_g,
        eval_h,
        user_data
    )
    nlp_ptr = Ptr{CNLPModel{Cdouble, Vector{Cdouble}}}(pointer_from_objref(nlp))
    unsafe_store!(nlp_ptr_ptr, nlp_ptr)
    libmad_refs[nlp_ptr] = nlp

    return Cint(0)
end

push!(function_sigs, """int libmad_nlpmodel_set_numerics(CNLPModel* nlp_ptr,
                                                         double* x0, double* y0,
                                                         double* lvar, double* uvar,
                                                         double* lcon, double* ucon
                                                        )"""
      )
Base.@ccallable function libmad_nlpmodel_set_numerics(nlp_ptr::Ptr{Cvoid},
                                                      x0::Ptr{Cdouble}, y0::Ptr{Cdouble},
                                                      lvar::Ptr{Cdouble}, uvar::Ptr{Cdouble},
                                                      lcon::Ptr{Cdouble}, ucon::Ptr{Cdouble},
                                                      )::Cint
    nlp = wrap_obj(CNLPModel, nlp_ptr)
    if x0 != C_NULL
        nlp.meta.x0 .= wrap_ptr(x0, nlp.meta.nvar)
    end
    if y0 != C_NULL
        nlp.meta.y0 .= wrap_ptr(y0, nlp.meta.ncon)
    end
    if lvar != C_NULL
        nlp.meta.lvar .= wrap_ptr(lvar, nlp.meta.nvar)
    end
    if uvar != C_NULL
        nlp.meta.uvar .= wrap_ptr(uvar, nlp.meta.nvar)
    end
    if lcon != C_NULL
        nlp.meta.lcon .= wrap_ptr(lcon, nlp.meta.ncon)
    end
    if ucon != C_NULL
        nlp.meta.ucon .= wrap_ptr(ucon, nlp.meta.ncon)
    end

    return Cint(0)
end

function NLPModels.jac_structure!(nlp::CNLPModel, I::AbstractVector{T}, J::AbstractVector{T}) where T
    I_ = Base.unsafe_convert(Ptr{Clong}, I)
    J_ = Base.unsafe_convert(Ptr{Clong}, J)
    ret = ccall(nlp.jac_struct, Cint, (Ptr{Clong}, Ptr{Clong}, Ptr{Cvoid}), I_, J_, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError jac_struct"))
    end
    return I, J
end

function NLPModels.hess_structure!(nlp::CNLPModel, I::AbstractVector{T}, J::AbstractVector{T}) where T
    I_ = Base.unsafe_convert(Ptr{Clong}, I)
    J_ = Base.unsafe_convert(Ptr{Clong}, J)
    ret = ccall(nlp.hess_struct, Cint, (Ptr{Clong}, Ptr{Clong}, Ptr{Cvoid}), I_, J_, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError jac_struct"))
    end
    return I, J
end

function NLPModels.obj(nlp::CNLPModel, x::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    f = Vector{Cdouble}([0.0])
    ret::Cint = ccall(nlp.eval_f, Cint, (Ptr{Cdouble},Ptr{Cdouble}, Ptr{Cvoid}), x_, f, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError eval_f"))
    end
    return f[1]
end

function NLPModels.cons!(nlp::CNLPModel, x::AbstractVector, c::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    c_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, c)
    ret::Cint = ccall(nlp.eval_g, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}), x_, c_, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError eval_cons"))
    end
    return c
end


function NLPModels.grad!(nlp::CNLPModel, x::AbstractVector, g::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    g_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, g)
    ret::Cint = ccall(nlp.eval_grad_f, Cint, (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}), x_, g_, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError eval_grad_f"))
    end
    return g
end


function NLPModels.jac_coord!(nlp::CNLPModel, x::AbstractVector, J::AbstractVector)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    J_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, J)
    ret::Cint = ccall(nlp.eval_jac_g, Cint, (Ptr{Cdouble},Ptr{Cdouble},Ptr{Cvoid}), x_, J_, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError eval_jac_g"))
    end
    return J
end


function NLPModels.hess_coord!(nlp::CNLPModel, x::AbstractVector, y::AbstractVector, H::AbstractVector;
                               obj_weight::Float64=1.0)
    x_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, x)
    y_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, y)
    H_::Ptr{Cdouble} = Base.unsafe_convert(Ptr{Cdouble}, H)
    ret::Cint = ccall(nlp.eval_h, Cint,
                      (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cvoid}),
                      obj_weight, x_, y_, H_, nlp.user_data)
    if ret != Cint(0)
        throw(Exception("CallbackError eval_hess_l"))
    end
    return H
end
