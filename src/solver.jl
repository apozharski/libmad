# TODO (@anton) In the future also handle abstract model types???

function generate_create_solver(solname, solver_expr, optsdict_expr)

    push!(function_sigs, "int $(solname)_create_solver($(String(nameof(eval(solver_expr))))** solver_ptr_ptr, CNLPModel* nlp_ptr, OptsDict* opts_ptr)")
    base_solver = eval(nameof(eval(solver_expr)))
    return quote
        Base.@ccallable function $(Symbol(solname, :_create_solver))(solver_ptr_ptr::Ptr{Ptr{Cvoid}},
                                                    nlp_ptr::Ptr{Cvoid},
                                                    opts_ptr::Ptr{Cvoid}
                                                    )::Cint
            nlp = wrap_obj(CNLPModel{Cdouble,Vector{Cdouble}},nlp_ptr)
            opts = wrap_obj(OptsDict, opts_ptr)
            nt_opts = $(Symbol(solname,:_to_parameters))(opts)
            solver = $(base_solver)(nlp;
                                    nt_opts...
                                   )

            solver_ptr = pointer_from_objref(solver)
            unsafe_store!(solver_ptr_ptr, solver_ptr)
            libmad_refs[solver_ptr] = solver

            return Cint(0)
        end

    end
end

function generate_delete_solver(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_delete_solver($(String(nameof(eval(solver_expr))))* solver_ptr)")
    base_solver = eval(nameof(eval(solver_expr)))
    return quote
        Base.@ccallable function $(Symbol(solname, :_delete_solver))(solver_ptr::Ptr{Cvoid})::Cint
            if haskey(libmad_refs, solver_ptr)
                delete!(libmad_refs, solver_ptr)
                return Cint(0)
            else
                return Cint(1)
            end
        end
    end
end


function generate_solve(solname, solver_expr, optsdict_expr, stats_expr)
    push!(function_sigs, "int $(solname)_solve($(String(nameof(eval(solver_expr))))* solver_ptr, OptsDict* opts_ptr, $(String(nameof(eval(stats_expr))))** stats_ptr_ptr)")
    base_solver = eval(nameof(eval(solver_expr)))
    return quote
        Base.@ccallable function $(Symbol(solname, :_solve))(solver_ptr::Ptr{Cvoid},
                                                             opts_ptr::Ptr{Cvoid},
                                                             stats_ptr_ptr::Ptr{Ptr{Cvoid}})::Cint
            solver = wrap_obj($(solver_expr), solver_ptr)
            opts = wrap_obj(OptsDict, opts_ptr)
            nt_opts = $(Symbol(solname,:_to_parameters))(opts)

            stats = solve!(solver; nt_opts...)
            stats_ptr = pointer_from_objref(stats)
            unsafe_store!(stats_ptr_ptr, stats_ptr)
            libmad_refs[stats_ptr] = stats

            return Cint(0)
        end
    end
end

macro solver(solname, solver_expr, optsdict_expr, stats_expr)
    push!(dummy_structs, String(nameof(eval(solver_expr))))
    return esc(
        quote
            $(generate_create_solver(solname, solver_expr, optsdict_expr))
            $(generate_delete_solver(solname, solver_expr, optsdict_expr))
            $(generate_solve(solname, solver_expr, optsdict_expr, stats_expr))
        end
    )
end
