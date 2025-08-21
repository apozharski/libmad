module libMad
using InteractiveUtils
using MadNLP
using NLPModels

# Store of references to libMad objects, to prevent garbage collection.
libmad_refs::Dict{Ptr{Any}, Any} = Dict()

include("options.jl")
@options MadNLPOptions{Cdouble}
@concrete_dict LS_DICT MadNLP.AbstractLinearSolver
@concrete_dict KKT_DICT MadNLP.AbstractKKTSystem
@concrete_dict CB_DICT MadNLP.AbstractCallback

include("nlpmodels.jl")
include("madnlp.jl")
end # module libMad
