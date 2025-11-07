# This interface should be defined somewhere, and is certainly a work in progress
function obj(stats::AbstractExecutionStats) end

function solution(stats::AbstractExecutionStats) end

function constraints(stats::AbstractExecutionStats) end

function success(stats::AbstractExecutionStats) end

function multipliers(stats::AbstractExecutionStats) end

function multipliers_L(stats::AbstractExecutionStats) end

function multipliers_U(stats::AbstractExecutionStats) end

function iters(stats::AbstractExecutionStats) end

function primal_feas(stats::AbstractExecutionStats) end

function dual_feas(stats::AbstractExecutionStats) end

function status(stats::AbstractExecutionStats) end

function get_n(stats::AbstractExecutionStats) end

function get_m(stats::AbstractExecutionStats) end

# macros for defining the stats interfaces
function generate_stats_getters(solname, stats_expr)
    push!(function_sigs, "int $(solname)_get_obj($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _obj = quote
        Base.@ccallable function $(Symbol(solname, :_get_obj))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr), stats_ptr)
            unsafe_store!(out, obj(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_solution($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _solution = quote
        Base.@ccallable function $(Symbol(solname, :_get_solution))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            #out_arr = unsafe_wrap(Vector{Cdouble}, out, get_n(stats))
            out_arr = wrap_ptr(out, get_n(stats))
            out_arr .= solution(stats)
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_constraints($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _constraints = quote
        Base.@ccallable function $(Symbol(solname, :_get_constraints))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            out_arr = wrap_ptr(out, get_m(stats))
            out_arr .= constraints(stats)
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_multipliers($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _multipliers = quote
        Base.@ccallable function $(Symbol(solname, :_get_multipliers))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            out_arr = wrap_ptr(out, get_m(stats))
            out_arr .= multipliers(stats)
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_multipliers_L($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _multipliers_L = quote
        Base.@ccallable function $(Symbol(solname, :_get_multipliers_L))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            out_arr = wrap_ptr(out, get_n(stats))
            out_arr .= multipliers_L(stats)
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_multipliers_U($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _multipliers_U = quote
        Base.@ccallable function $(Symbol(solname, :_get_multipliers_U))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            out_arr = wrap_ptr(out, get_n(stats))
            out_arr .= multipliers_U(stats)
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_bound_multipliers($(String(nameof(eval(stats_expr))))* stats_ptr, libmmad_real* out)")
    _bound_multipliers = quote
        Base.@ccallable function $(Symbol(solname, :_get_bound_multipliers))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            out_arr = wrap_ptr(out, get_n(stats))
            out_arr .= multipliers_U(stats) .- multipliers_L(stats)
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_success($(String(nameof(eval(stats_expr))))* stats_ptr, bool* out)")
    _success = quote
        Base.@ccallable function $(Symbol(solname, :_get_success))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cuchar})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            unsafe_store!(out, success(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_iters($(String(nameof(eval(stats_expr))))* stats_ptr, libmad_int* out)")
    _iters = quote
        Base.@ccallable function $(Symbol(solname, :_get_iters))(stats_ptr::Ptr{Cvoid}, out::Ptr{Clong})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            unsafe_store!(out, iters(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_primal_feas($(String(nameof(eval(stats_expr))))* stats_ptr, libma_real* out)")
    _primal_feas = quote
        Base.@ccallable function $(Symbol(solname, :_get_primal_feas))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            unsafe_store!(out, primal_feas(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_dual_feas($(String(nameof(eval(stats_expr))))* stats_ptr, libmad_real* out)")
    _dual_feas = quote
        Base.@ccallable function $(Symbol(solname, :_get_dual_feas))(stats_ptr::Ptr{Cvoid}, out::Ptr{Cdouble})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            unsafe_store!(out, dual_feas(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_status($(String(nameof(eval(stats_expr))))* stats_ptr, libmad_int* out)")
    _status = quote
        Base.@ccallable function $(Symbol(solname, :_get_status))(stats_ptr::Ptr{Cvoid}, out::Ptr{Clong})::Cint
            stats = wrap_obj($(stats_expr),stats_ptr)
            unsafe_store!(out, status(stats))
            return Cint(0)
        end
    end

    return quote
        $(_obj)
        $(_solution)
        $(_constraints)
        $(_multipliers)
        $(_multipliers_L)
        $(_multipliers_U)
        $(_bound_multipliers)
        $(_success)
        $(_iters)
        $(_primal_feas)
        $(_dual_feas)
        $(_status)
    end
end

function generate_delete_stats(solname, stats_expr)
    push!(function_sigs, "int $(solname)_delete_stats($(String(nameof(eval(stats_expr))))* stats_ptr)")
    return quote
        Base.@ccallable function $(Symbol(solname, :_delete_stats))(stats_ptr::Ptr{Cvoid})::Cint
            if haskey(libmad_refs, stats_ptr)
                delete!(libmad_refs, stats_ptr)
                return Cint(0)
            else
                return Cint(1)
            end
        end
    end
end

macro stats(solname, stats_expr)
    push!(dummy_structs, "$(String(nameof(eval(stats_expr))))")

    return esc(
        quote
            $(generate_stats_getters(solname, stats_expr))
            $(generate_delete_stats(solname, stats_expr))
        end
    )
end
