# TODO (@anton) In the future also handle abstract model types???

function generate_create_solver(solname, solver_expr, optsdict_expr)

    push!(function_sigs, "int $(solname)_create_solver($(String(nameof(eval(solver_expr))))** solver_ptr_ptr, CNLPModel* nlp_ptr, OptsDict* opts_ptr)")
    return quote
        Base.@ccallable function $(Symbol(solname, :_create_solver))(solver_ptr_ptr::Ptr{Ptr{$(solver_expr)}},
                                                    nlp_ptr::Ptr{CNLPModel{Cdouble}},
                                                    opts_ptr::Ptr{OptsDict}
                                                    )::Cint
            nlp::CNLPModel{Cdouble} = unsafe_pointer_to_objref(nlp_ptr)::CNLPModel{Cdouble}
            opts::OptsDict = unsafe_pointer_to_objref(opts_ptr)::OptsDict
            nt_opts = $(Symbol(solname,:_to_parameters))(opts)
            println(nt_opts)
            solver = $(solver_expr)(nlp;
                                    nt_opts...
                                   )

            solver_ptr = pointer_from_objref(solver)::$(solver_expr)
            unsafe_store!(solver_ptr_ptr, solver_ptr)
            libmad_refs[solver_ptr] = solver

            return Cint(0)
        end

    end
end

function generate_delete_solver(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_delete_solver($(String(nameof(eval(solver_expr))))* solver_ptr)")
    return quote
        Base.@ccallable function $(Symbol(solname, :_delete_solver))(solver_ptr::Ptr{$(solver_expr)})::Cint
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
    return quote
        Base.@ccallable function $(Symbol(solname, :_solve))(solver_ptr::Ptr{$(solver_expr)},
                                                             opts_ptr::Ptr{OptsDict},
                                                             stats_ptr_ptr::Ptr{Ptr{$(stats_expr)}})::Cint
            solver::$(solver_expr) = unsafe_pointer_to_objref(solver_ptr)::$(solver_expr)
            opts::OptsDict = unsafe_pointer_to_objref(opts_ptr)::OptsDict
            nt_opts = $(Symbol(solname,:_to_parameters))(opts)

            stats = solve!(solver; nt_opts...)
            stats_ptr = pointer_from_objref(stats)::$(stats_expr)
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
