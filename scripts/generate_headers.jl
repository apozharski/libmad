#println(Base.active_project())
using Pkg
#println(Pkg.status())
Pkg.instantiate()
using libMad
# TODO(@anton) make this safer

outpath = ARGS[1]
open(joinpath(outpath,"libMad.h"), "w") do header
    #println(header,"#include \"julia.h\"")
    # add Guard
    println(header, """
    #ifndef _LIBMAD_H
    #define _LIBMAD_H
    """)
    # add c++ extern "c" guard
    println(header, """
    #ifdef __cplusplus
    extern "C" {
    #endif
    """)
    println(header)
    println(header,"#include <stdbool.h>")
    println(header,"#include <stdint.h>")
    println(header)
    println(header, """
    #define libmad_int int64_t
    #define libmad_real double

    // function pointer types
    typedef int (*NlpConstrJacStructure)(libmad_int*, libmad_int*, void*);
    typedef int (*NlpLagHessStructure)(libmad_int*, libmad_int*, void*);
    typedef int (*NlpEvalObj)(const libmad_real*, libmad_real*, void*);
    typedef int (*NlpEvalConstr)(const libmad_real*, libmad_real*, void*);
    typedef int (*NlpEvalObjGrad)(const libmad_real*, libmad_real*, void*);
    typedef int (*NlpEvalConstrJac)(const libmad_real*, libmad_real*, void*);
    typedef int (*NlpEvalLagHess)(libmad_real, const libmad_real*, const libmad_real*, libmad_real*, void*);
    """)
    for ds in libMad.dummy_structs
        println(header, "typedef struct $(ds) $(ds);")
    end
    println(header)
    for fs in libMad.function_sigs
        println(header, "$(fs);")
        println(header)
    end
    # Generate end of c++ externa and guard
    println(header,"""
    #ifdef __cplusplus
    }
    #endif

    #endif // _LIBMAD_H
    """)
end
