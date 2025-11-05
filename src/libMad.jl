module libMad
using InteractiveUtils
using MadNLP
using MadNLPHSL
using NLPModels
using PrecompileTools: @setup_workload, @compile_workload, verbose
using Base: unsafe_convert
using SolverCore

# Store of references to libMad objects, to prevent garbage collection.
libmad_refs::Dict{Ptr, Any} = Dict{Ptr, Any}()

# Store of signatures for header generation
function_sigs::Vector{String} = []
dummy_structs::Vector{String} = []

include("utils.jl")
include("options.jl")
include("nlpmodels.jl")
include("solver.jl")
include("stats.jl")
# MadNLP Solver interface definition
# First define the possible types that any given `::Type` option can take.
# This is important as it allows `--trim` to be smart about what types to keep
# TODO(@anton): trim is currently broken so this is some complexity for little gain
#               however in future this gain will likely be _large_.
@concrete_dict LS_DICT MadNLP.AbstractLinearSolver
@concrete_dict KKT_DICT MadNLP.AbstractKKTSystem
@concrete_dict CB_DICT MadNLP.AbstractCallback
@concrete_dict FVT_DICT MadNLP.AbstractFixedVariableTreatment
@concrete_dict ET_DICT MadNLP.AbstractEqualityTreatment
@concrete_dict IC_DICT MadNLP.AbstractInertiaCorrector
@concrete_dict DIO_DICT MadNLP.DualInitializeOptions
@concrete_dict IT_DICT MadNLP.AbstractIterator
@concrete_dict HESS_DICT MadNLP.AbstractHessian
# Provide a dictionary from "paths" (tuples of symbols) to their corresponding concrete_dict
# For now we don't have a good way to "automagically" build this
const madnlp_type_dict = Dict(
    "callback" => CB_DICT,
    "kkt_system" => KKT_DICT,
    "linear_solver" => LS_DICT,
    "iterator" => IT_DICT,
    "fixed_variable_treatment" => FVT_DICT,
    "equality_treatment" => ET_DICT,
    "hessian_approximation" => HESS_DICT,
    "inertia_correction_method" => IC_DICT,
    "dual_initialization_method" => DIO_DICT,
)

include("madnlp/stats.jl")

@opts(madnlp, MadNLPOptions{Cdouble}, libMad.madnlp_type_dict)
#@opts_dict(MadNLPOptions{Cdouble}, MadNLPOptsDict, madnlp_type_dict)

# Create stats
@stats(madnlp, MadNLPExecutionStats{Cdouble, Vector{Cdouble}})

# Now create solver interface
@solver(madnlp, MadNLPSolver{Cdouble,Vector{Cdouble}}, MadNLPOptsDict, MadNLPExecutionStats{Cdouble, Vector{Cdouble}})

# Precompile workload for madnlp
include("madnlp/workload_precomp.jl")

end # module libMad
