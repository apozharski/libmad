using libMad
# TODO(@anton) make this safer

outpath = ARGS[1]

open(joinpath(outpath,"libMad.h"), "w") do header
    println(header,"#include \"julia.h\"")
    println(header)
    for ds in libMad.dummy_structs
        println(header, "typedef struct $(ds) $(ds);")
    end
    println(header)
    for fs in libMad.function_sigs
        println(header, "$(fs);")
        println(header)
    end
end
