abstract type AbstractOptionsDict end

abstract type AbstractOption end

const ABSTRACT_OPTS = Union{MadNLP.AbstractBarrierUpdate}

const ConcreteOption = Union{Float32, Float64, Int32, Int64, Type, String, Symbol, Enum{Int32}, Enum{Int64}, Bool}
const Path = String
const Guard = Tuple{Path, Type}
const Guards = Vector{Guard}
const Guardss = Vector{Guards}
const OptionWithGuards = Tuple{ConcreteOption, Guards}
const PathWithGuards = Tuple{Path, Guards}

# New interface, using strings and deferring errors to solver creation
# TODO(@anton) verify lhs is a valid dotstring
const OptsDict = IdDict{String, ConcreteOption}
push!(dummy_structs, "OptsDict")

function get_populated_subpaths!(dict::OptsDict, path::Path)
    paths::OptsDict = OptsDict()::OptsDict
    for (key,val) in dict
        if startswith(key, path)
            push!(paths, (String(chopprefix(key, path)), val))
            delete!(dict, key)
        end
    end
    return paths
end

macro concrete_dict(dictname, type)
    concrete_types = []
    abstract_types = Vector{Any}([eval(type)])
    while !isempty(abstract_types)
        type = pop!(abstract_types)
        stypes = subtypes(type)
        if isempty(stypes)
            push!(concrete_types,Core.typename(type).wrapper)
        else
            append!(abstract_types,stypes)
        end
    end

    dict = Dict([(String(nameof(ctype)), ctype) for ctype in concrete_types])
    
    return esc(:($(dictname) = $(dict)))
end

function get_concrete_types(absoptstype::Type)
    unqualified_types = []
    concrete_types = []
    abstract_types = [absoptstype]
    while !isempty(abstract_types)
        type = pop!(abstract_types)
        stypes = subtypes(type)
        if isconcretetype(type)
            push!(unqualified_types,Core.typename(type).wrapper)
            push!(concrete_types,type)
        else
            append!(abstract_types,stypes)
        end
    end
    return unqualified_types, concrete_types
end

function normalize_type(type::Type)
    if type <: Enum
        return Base.Enums.basetype(type)
    elseif type <: Type
        return String
    else
        return type
    end
end

function normalize_typename(type::Type)
    return String(nameof(type))
end

function get_path_info(optstype::Type)
    fnames = fieldnames(optstype)
    ftypes = fieldtypes(optstype)

    # Build set of valid tuples
    valid_paths = Dict{Path, Type}()
    path_guards = Dict{Path, Guardss}()
    path_type_options = Dict{Path, Dict{String,Type}}()

    worklist::Vector{Tuple{PathWithGuards, Type}} = [((String(fname), []),ftype) for (fname, ftype) in  zip(fnames,ftypes)]

    while !isempty(worklist)
        ((path, guards), type) = popfirst!(worklist)
        if type <: ConcreteOption
            push!(valid_paths, path => type)
            if !haskey(path_guards, path)
                push!(path_guards, path => [])
            end
            push!(path_guards[path], guards)
        elseif isconcretetype(type)
            fnames_ = fieldnames(type)
            ftypes_ = fieldtypes(type)
            append!(worklist, [((join((path, String(fname)), "."), guards),ftype) for (fname, ftype) in zip(fnames_,ftypes_)])
        else
            uts, cts = get_concrete_types(type)
            type_path = join((path, "TYPE"), ".")
            push!(valid_paths, type_path => Type)
            push!(path_type_options, path => Dict([(String(nameof(ut)),ct) for (ut,ct) in zip(uts,cts)]))
            if !haskey(path_guards, type_path)
                push!(path_guards, type_path => [])
            end
            push!(path_guards[type_path], guards)
            for (ut, ct) in zip(uts,cts)
                fnames_ = fieldnames(ct)
                ftypes_ = fieldtypes(ct)
                new_guards = vcat(guards, (path, ut))

                append!(worklist, [((join((path, String(fname)), "."), new_guards), ftype) for (fname, ftype) in zip(fnames_,ftypes_)])
            end
        end
    end

    return valid_paths, path_guards, path_type_options
end

function to_c_type(type::Type)
    if type == Int32
        return "int"
    elseif type == Int64
        return "libmad_int"
    elseif type == Float32
        return "float"
    elseif type == Float64
        return "libmad_real"
    elseif type == Bool
        return "bool"
    else
        return "?????"
    end
end

function to_c_name(type::Type)
    if type == Int32
        return "int"
    elseif type == Int64
        return "long long"
    elseif type == Float32
        return "float"
    elseif type == Float64
        return "double"
    elseif type == Bool
        return "bool"
    else
        return "?????"
    end
end

# WARNING(@anton): This code contains a hack to get around not being able to splat (when using --trim)
#                  a dictionary into the arguments via `subpaths...`. This is due to a fundamental
#                  limitation in Julia v1.12, see: https://github.com/JuliaLang/julia/issues/57830
function generate_string_to_type_suboptions_checks(path_type_options)
    checks = []
    for (path, typedict) in path_type_options
        for (tstring, type) in typedict
            check = quote
                if path == $(path) && type == $(tstring)
                    subpath_args = IdDict()
                    for (sk, sv) in subpaths
                        push!(subpath_args, (Symbol(sk),sv))
                    end
                    $(Symbol(tstring,:_suboptions)) = $(type)(;subpath_args)
                    push!(params, (path, $(Symbol(tstring,:_suboptions))))
                end
            end
            push!(checks, check)
        end
    end
    return quote
        $(checks...)
    end
end

function generate_string_to_type_checks(typedict_expr)
    typedictdict = eval(typedict_expr) # get actual dict?
    checks = []
    for (path, typedict) in typedictdict
        for (tstring, type) in typedict
            check = quote
                if path == $(path) && val == $(tstring)
                    params[path] = $(type)
                end
            end
            push!(checks, check)
        end
    end
    return quote
        $(checks...)
    end
end

push!(function_sigs, "int libmad_create_options_dict(OptsDict** opts_ptr)")
Base.@ccallable function libmad_create_options_dict(opts_ptr_ptr::Ptr{Ptr{Cvoid}})::Cint
    opts = OptsDict()
    opts_ptr = Ptr{OptsDict}(pointer_from_objref(opts))
    libmad_refs[opts_ptr] = opts
    unsafe_store!(opts_ptr_ptr, opts_ptr)

    return Cint(0)
end

# TODO(@anton) in principle we could support the rest of these types but this may needlessly complicate the interface
# for type in [Int32, Int64, Float32, Float64, Bool]
for type in [Int64, Float64, Bool]
    push!(function_sigs, "int libmad_set_$(to_c_name(type))_option(OptsDict* opts_ptr, const char* name, $(to_c_type(type)) val)")
    fname = "libmad_set_$(to_c_name(type))_option"
    @eval begin
        Base.@ccallable function $(Symbol(fname))(opts_ptr::Ptr{Cvoid}, name::Cstring, val::$(Symbol(type)))::Cint
            opts = wrap_obj(OptsDict, opts_ptr)
            setindex!(opts, val, String(unsafe_string(name)))
            return Cint(0)
        end
    end
end

push!(function_sigs, "int libmad_set_string_option(OptsDict* opts_ptr, const char* name, const char* val)")
Base.@ccallable function libmad_set_string_option(opts_ptr::Ptr{Cvoid}, name::Cstring, val::Cstring)::Cint
    opts = wrap_obj(OptsDict, opts_ptr)
    setindex!(opts, String(unsafe_string(val)), String(unsafe_string(name)))
    return Cint(0)
end

push!(function_sigs, "int libmad_delete_options_dict(OptsDict* stats_ptr)")
Base.@ccallable function libmad_delete_options_dict(opts_ptr::Ptr{Cvoid})::Cint
    if haskey(libmad_refs, opts_ptr)
        delete!(libmad_refs, opts_ptr)
        return Cint(0)
    else
        return Cint(1)
    end
end

function generate_guard(guard)
    if isempty(guard)
        return :(true)
    elseif length(guard) == 1
        (path, type) = guard[1]
        return :((haskey(params, path) && params[$(join((path,"TYPE"), "."))] == $(normalize_typename(type))))
    else
        (path, type) = guard[1]
        return :((haskey(params, path) && params[$(join((path,"TYPE"), "."))] == $(normalize_typename(type))) && $(generate_guard(guard[2:end])))
    end
end

function generate_guards_check(guards)
    if isempty(guards)
        return :()
    elseif length(guards) == 1
        return :(($(generate_guard(guards[1]))) || delete!(params, path))
    else
        return :(($(generate_guard(guards[1]))) || ($(generate_guards_check(guards[2:end]))))
    end
end

function generate_type_check(type)
    return :(isa(params[path],$(normalize_type(type))) || delete!(params, path))
end

function generate_drop_check(path, type, guards)
    return quote
        if path == $(path)
            $(generate_guards_check(guards))
            $(generate_type_check(type))
        end
    end
end

function generate_drop_checks(valid_paths, path_guards)
    checks = []
    for (path, type) in valid_paths
        push!(checks, generate_drop_check(path, type, path_guards[path]))
    end
    return checks
end

function generate_drop_invalid_options(valid_paths, path_guards)
    type_checks = quote
        for path in keys(params)
            $(generate_drop_checks(valid_paths, path_guards)...)
        end
    end
end

function generate_to_parameters(prefix, typedict_expr, valid_paths, path_guards,  path_type_options)
    # TODO(@anton) I think the path compression could be done at compile time instead of searching at runtime,
    #              however I think this is unimportant for now.
    # TODO(@anton) This breaks if you have nested abstract options types. But fixing this is a huge pain.
    #              We need to think about restricting the interface.
    # TODO(@anton) This currently defers errors to the solver call if the types passed are wrong.
    to_params = quote
        function $(Symbol(prefix, :_to_parameters))(opts::OptsDict)#::NamedTuple
            # Takes a dict and walks it to create a flat dict with the proper types
            params::OptsDict = OptsDict(opts)::OptsDict
            path_type_options = $(path_type_options)

            $(generate_drop_invalid_options(valid_paths, path_guards))
            # Process sub-options structs
            for (path, typedict) in path_type_options
                subpaths::OptsDict = get_populated_subpaths!(params, path)
                if !haskey(subpaths, "TYPE")
                    # TODO(@anton) warn?
                    #@warn "Missing TYPE for $(path)"
                    continue
                end
                type = subpaths["TYPE"]
                delete!(subpaths, "TYPE")
                $(generate_string_to_type_suboptions_checks(path_type_options))
            end
            # Process `::Type` options
            for (path, val) in params
                $(generate_string_to_type_checks(typedict_expr))
            end
            dict_out = IdDict()
            for (path, val) in params
                # TODO(@anton) check that path is length one
                setindex!(dict_out, val, Symbol(path))
            end
            return dict_out
        end
    end

    return to_params
end

macro opts(prefix, optstype_expr, typedict_expr)
    opts_type = eval(optstype_expr)

    valid_paths, path_guards, path_type_options = get_path_info(opts_type)

    norm_leaf_types = Set(normalize_type.(values(valid_paths)))

    return esc(
        quote
            $(generate_to_parameters(prefix, typedict_expr, valid_paths, path_guards, path_type_options))
        end
    )
end
