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

function generate_solve(solname, solver_expr, optsdict_expr)
    push!(function_sigs, "int $(solname)_solve($(solver_expr)* solver_ptr, $(optsdict_expr)* opts_ptr)")
    return quote
        Base.@ccallable function $(Symbol(solname, :_solve))(solver_ptr::Ptr{$(solver_expr)},
                                                             opts_ptr::Ptr{$(optsdict_expr)})::Cint
            solver = unsafe_pointer_to_objref(solver_ptr)
            opts = unsafe_pointer_to_objref(opts_ptr)

            stats = solve!(solver; _to_parameters(opts)...)

            return Cint(0)
        end
    end
end

macro solver(solname, solver_expr, optsdict_expr)
    push!(dummy_structs, "$(solver_expr)")
    return esc(
        quote
            $(generate_create_solver(solname, solver_expr, optsdict_expr))
            $(generate_solve(solname, solver_expr, optsdict_expr))
        end
    )
end
