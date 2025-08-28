# This interface should be defined somewhere, and is certainly a work in progress
function obj(stats::AbstractExecutionStats) end

function solution(stats::AbstractExecutionStats) end

function constraints(stats::AbstractExecutionStats) end

function success(stats::AbstractExecutionStats) end

function multipliers(stats::AbstractExecutionStats) end

function multipliers_L(stats::AbstractExecutionStats) end

function multipliers_U(stats::AbstractExecutionStats) end

function get_n(stats::AbstractExecutionStats) end

function get_m(stats::AbstractExecutionStats) end

# macros for defining the stats interfaces
function generate_stats_getters(solname, stats_expr)
    push!(function_sigs, "int $(solname)_get_obj($(stats_expr)* stats_ptr, double* out)")
    _obj = quote
        Base.@ccallable function $(Symbol(solname, :_get_obj))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cdouble})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, obj(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_solution($(stats_expr)* stats_ptr, double* out)")
    _solution = quote
        Base.@ccallable function $(Symbol(solname, :_get_solution))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cdouble})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, solution(stats), get_n(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_constraints($(stats_expr)* stats_ptr, double* out)")
    _constraints = quote
        Base.@ccallable function $(Symbol(solname, :_get_constraints))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cdouble})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, constraints(stats), get_m(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_multipliers($(stats_expr)* stats_ptr, double* out)")
    _multipliers = quote
        Base.@ccallable function $(Symbol(solname, :_get_multipliers))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cdouble})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, multipliers(stats), get_m(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_multipliers_L($(stats_expr)* stats_ptr, double* out)")
    _multipliers_L = quote
        Base.@ccallable function $(Symbol(solname, :_get_multipliers_L))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cdouble})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, multipliers_L(stats), get_n(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_multipliers_U($(stats_expr)* stats_ptr, double* out)")
    _multipliers_U = quote
        Base.@ccallable function $(Symbol(solname, :_get_multipliers_U))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cdouble})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, multipliers_U(stats), get_n(stats))
            return Cint(0)
        end
    end

    push!(function_sigs, "int $(solname)_get_success($(stats_expr)* stats_ptr, bool* out)")
    _success = quote
        Base.@ccallable function $(Symbol(solname, :_get_success))(stats_ptr::Ptr{$(stats_expr)}, out::Ptr{Cbool})::Cint
            stats = unsafe_pointer_to_objref(stats_ptr)
            unsafe_store(out, success(stats))
            return Cint(0)
        end
    end

    return quote
        $(_obj)
        $(_solution)
        $(_constraints)
        $(_multipliers)
        $(_multipliers_L)
        $(_success)
    end
end

function generate_delete_stats(solname, stats_expr)
    push!(function_sigs, "int $(solname)_delete_solver($(stats_expr)* stats_ptr)")
    return quote
        Base.@ccallable function $(Symbol(solname, :_delete_stats))(stats_ptr::Ptr{$(stats_expr)})::Cint
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
    push!(dummy_structs, "$(stats_expr)")

    return esc(
        quote
            $(generate_stats_getters(solname, stats_expr))
            $(generate_delete_stats(solname, stats_expr))
        end
    )
end
