function generate_create_solver(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_create_solver($(solver_expr)** solver_ptr_ptr, CNLPModel* nlp_ptr, $(optsdict_expr)* opts_ptr)")
    return quote
        Base.@ccallable function $(Symbol(solname, :_create_solver))(solver_ptr_ptr::Ptr{Ptr{$(solver_expr)}},
                                                    nlp_ptr::Ptr{CNLPModel{Cdouble}},
                                                    opts_ptr::Ptr{$(optsdict_expr)}
                                                    )::Cint
            nlp = unsafe_pointer_to_objref(nlp_ptr)
            opts = unsafe_pointer_to_objref(opts_ptr)

            solver = $(solver_expr)(nlp;
                                    _to_parameters(opts)...
                                   )

            solver_ptr = pointer_from_objref(solver)
            unsafe_store!(solver_ptr_ptr, solver_ptr)
            libmad_refs[solver_ptr] = solver

            return Cint(0)
        end

    end
end

function generate_delete_solver(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_delete_solver($(solver_expr)* solver_ptr)")
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


function generate_solve(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_solve($(solver_expr)* solver_ptr, $(optsdict_expr)* opts_ptr, $(stats_expr)** stats_ptr_ptr")
    return quote
        Base.@ccallable function $(Symbol(solname, :_solve))(solver_ptr::Ptr{$(solver_expr)},
                                                             opts_ptr::Ptr{$(optsdict_expr)},
                                                             stats_ptr_ptr::Ptr{Ptr{$(stats_expr)}})::Cint
            solver = unsafe_pointer_to_objref(solver_ptr)
            opts = unsafe_pointer_to_objref(opts_ptr)

            stats = solve!(solver; _to_parameters(opts)...)
            stats_ptr = pointer_from_objref(stats)
            unsafe_store!(stats_ptr_ptr, stats_ptr)
            libmad_refs[stats_ptr] = stats

            return Cint(0)
        end
    end
end

macro solver(solname, solver_expr, optsdict_expr, stats_expr)
    push!(dummy_structs, "$(solver_expr)")
    return esc(
        quote
            $(generate_create_solver(solname, solver_expr, optsdict_expr))
            $(generate_delete_solver(solname, solver_expr, optsdict_expr))
            $(generate_solve(solname, solver_expr, optsdict_expr, stats_expr))
        end
    )
end
