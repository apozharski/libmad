function generate_create_solver(solname, solver_expr, optsdict_expr)
    return quote
        Base.@ccallable function $(Symbol(solname, :_create_solver))(solver_ptr_ptr::Ptr{Ptr{$(solver_expr)}},
                                                    nlp_ptr::Ptr{CNLPModel{Cdouble}},
                                                    opts_ptr::Ptr{$(optsdict_expr)}
                                                    )::Cint

            nlp = unsafe_load(nlp_ptr)
            opts = unsafe_load(opts_ptr)

            solver = $(solver_expr)(nlp;
                                    _to_parameter(opts)...
                                   )

            solver_ptr = pointer_from_objref(solver)
            unsafe_store!(solver_ptr_ptr, solver_ptr)
            libmad_refs[solver_ptr] = solver

            return Cint(0)
        end

    end
end

function generate_solve(solname, solver_expr, optsdict_expr)
    return quote
        Base.@ccallable function $(Symbol(solname, :_solve))(solver_ptr::Ptr{$(solver_expr)},
                                                             opts_ptr::Ptr{$(optsdict_expr)})::Cint
            solver = unsafe_load(solver_ptr)
            opts = unsafe_load(opts_ptr)

            stats = solve!(solver; _to_parameter(opts)...)
        end
    end
end

macro solver(solname, solver_expr, optsdict_expr)
    return esc(
        quote
            $(generate_create_solver(solname, solver_expr, optsdict_expr))
            $(generate_solve(solname, solver_expr, optsdict_expr))
        end
    )
end
