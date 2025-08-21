Base.@ccallable function madnlp_create_solver(solver_ptr_ptr::Ptr{Ptr{MadNLPSolver}},
                                              opts_ptr_ptr::Ptr{Ptr{MadNLPSolver}},
                                              nlp_ptr::Ptr{CNLPModel{Cdouble}},
                                              tol::Cdouble,
                                              linear_solver::Cstring,
                                              kkt_system::Cstring,
                                              callback::Cstring
                                              )::Cint

    nlp = nlp_ptr[]

    ls_str = String(linear_solver[1:findfirst(==(0x00), name)-1])
    kkt_str = String(kkt_system[1:findfirst(==(0x00), name)-1])
    cb_str = String(callback[1:findfirst(==(0x00), name)-1])

    if haskey(LS_DICT, ls_str)
        ls = LS_DICT[ls_str]
    else
        return Cint(1)
    end
    
    if haskey(KKT_DICT, kkt_str)
        kkt = KKT_DICT[kkt_str]
    else
        return Cint(2)
    end

    if haskey(CB_DICT, cb_str)
        cb = CB_DICT[kkt_str]
    else
        return Cint(3)
    end

    solver = MadNLPSolver(nlp;
                          tol=tol,
                          linear_solver=ls,
                          kkt_system=kkt,
                          callback=cb
                          )

    solver_ptr = pointer_from_objref(solver)
    opts_ptr = pointer_from_objref(solver.opt)
    solver_ptr_ptr[] = solver_ptr
    opts_ptr_ptr[] = opts_ptr
    libmad_refs[solver_ptr] = solver
    libmad_refs[opts_ptr] = solver.opt

    return Cint(0)
end
