include("../src/madlnp/workload.jl")
using MethodAnalysis
meths = []
visit(MadNLP) do item
    isa(item, Method) && push!(meths, item)
    true   # walk through everything
end

mins
for meth in meths
    append!(mins, methodinstances(meth))
end
