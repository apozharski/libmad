abstract type AbstractOptionsDict end

abstract type AbstractOption end

const ABSTRACT_OPTS = Union{MadNLP.AbstractBarrierUpdate}

const ConcreteOption = Union{AbstractFloat, Integer, Type, String, Symbol, Enum}
const Path = Tuple{Vararg{Symbol}}
const Guard = Tuple{Path, Type}
const Guards = Vector{Guard}
const Guardss = Vector{Guards}
const OptionWithGuards = Tuple{ConcreteOption, Guards}
const PathWithGuards = Tuple{Path, Guards}


function dotchain(names)
    if isempty(names)
        return :()
    end
    if length(names) == 1
        return names[1]
    end
    if length(names) == 2
        return Expr(:., names[1], QuoteNode((names[2])))
    end
    return Expr(:., dotchain(names[1:end-1]), QuoteNode(names[end]) )
end

function strdotchain(names)
    return join([String(name) for name in names], ".")
end

function add_assign!(vec, parents, fname)
    push!(vec,
          quote
              if unsafe_string(str) == $(strdotchain(vcat(parents, fname)))
                  $(dotchain(vcat([:opt], parents, fname))) = val
                  return 0
              end
          end
          )
end

function add_assign_sub!(vec, parents, fname, type)
    push!(vec,
          quote
              if unsafe_string(str) == $(strdotchain(vcat(parents, fname)))
                  if typeof($(dotchain(vcat([:opt], parents, fname)))) == $(type)
                      $(dotchain(vcat([:opt], parents, fname))) = val
                      return 0
                  else
                      return 2
                  end
              end
          end
          )
end

function genoptsetters(opttype)
    fnames = fieldnames(opttype)
    ftypes = fieldtypes(opttype)
    n = length(fnames)
    f64sets = []
    i64sets = []
    i32sets = []
    bsets = []
    for ii=1:n
        if ftypes[ii] == Cdouble
            add_assign!(f64sets, [], fnames[ii])
        end
        if ftypes[ii] == Clong
            add_assign!(i64sets, [], fnames[ii])
        end
        if ftypes[ii] <: Enum{Clong}
            add_assign!(i64sets, [], fnames[ii])
        end
        if ftypes[ii] == Cint
            add_assign!(i32sets, [], fnames[ii])
        end
        if ftypes[ii] <: Enum{Cint}
            add_assign!(i32sets, [], fnames[ii])
        end
        if ftypes[ii] == Bool
            add_assign!(bsets, [], fnames[ii])
        end
        if isstructtype(ftypes[ii])
            f64_, i64_, i32_, b_ = genoptsetters(ftypes[ii], [fnames[ii]])
            append!(f64sets, f64_)
            append!(i64sets, i64_)
            append!(i32sets, i32_)
            append!(bsets, b_)
        end
        if isabstracttype(ftypes[ii]) && ftypes[ii] <: ABSTRACT_OPTS
            concrete = InteractiveUtils.subtypes(ftypes[ii])
            for stype in concrete
                f64_, i64_, i32_, b_ = genoptsetters_sub(stype, [fnames[ii]])
                append!(f64sets, f64_)
                append!(i64sets, i64_)
                append!(i32sets, i32_)
                append!(bsets, b_)
            end
        end
    end
    
    return quote
        Base.@ccallable function madnlp_set_double_option(opts::Ptr{$(opttype)}, str::Cstring, val::Cdouble)::Cint
            opt = opts[]
            $(f64sets...)
            return 1
        end

        Base.@ccallable function madnlp_set_long_option(opts::Ptr{$(opttype)}, str::Cstring, val::Clong)::Cint
            opt = opts[]
            $(i64sets...)
            return 1
        end

        Base.@ccallable function madnlp_set_int_option(opts::Ptr{$(opttype)}, str::Cstring, val::Cint)::Cint
            opt = opts[]
            $(i32sets...)
            return 1
        end

        Base.@ccallable function madnlp_set_bool_option(opts::Ptr{$(opttype)}, str::Cstring, val::Cuchar)::Cint
            opt = opts[]
            $(bsets...)
            return 1
        end
    end
end

function genoptsetters(opttype, parents)
    fnames = fieldnames(opttype)
    ftypes = fieldtypes(opttype)
    n = length(fnames)
    f64sets = []
    i64sets = []
    i32sets = []
    bsets = []
    for ii=1:n
        if ftypes[ii] == Cdouble
            add_assign!(f64sets, parents, fnames[ii])
        end
        if ftypes[ii] == Clong
            add_assign!(i64sets, parents, fnames[ii])
        end
        if ftypes[ii] <: Enum{Clong}
            add_assign!(i64sets, parents, fnames[ii])
        end
        if ftypes[ii] == Cint
            add_assign!(i32sets, parents, fnames[ii])
        end
        if ftypes[ii] <: Enum{Cint}
            add_assign!(i32sets, parents, fnames[ii])
        end
        if ftypes[ii] == Bool
            add_assign!(bsets, parents, fnames[ii])
        end
        if isstructtype(ftypes[ii])
            f64_, i64_, i32_, b_ = genoptsetters(ftypes[ii], vcat(parents,fnames[ii]))
            append!(f64sets, f64_)
            append!(i64sets, i64_)
            append!(i32sets, i32_)
            append!(bsets, b_)
        end
        if isabstracttype(ftypes[ii]) && ftypes[ii] <: ABSTRACT_OPTS
            concrete = InteractiveUtils.subtypes(ftypes[ii])
            for stype in concrete
                f64_, i64_, i32_, b_ = genoptsetters_sub(stype, vcat(parents,fnames[ii]))
                append!(f64sets, f64_)
                append!(i64sets, i64_)
                append!(i32sets, i32_)
                append!(bsets, b_)
            end
        end
    end
    return f64sets, i64sets, i32sets, bsets
end

function genoptsetters_sub(opttype, parents)
    fnames = fieldnames(opttype)
    ftypes = fieldtypes(opttype)
    n = length(fnames)
    f64sets = []
    i64sets = []
    i32sets = []
    bsets = []
    for ii=1:n
        if ftypes[ii] == Cdouble
            add_assign_sub!(f64sets, parents, fnames[ii], opttype)
        end
        if ftypes[ii] == Clong
            add_assign_sub!(i64sets, parents, fnames[ii], opttype)
        end
        if ftypes[ii] <: Enum{Clong}
            add_assign_sub!(i64sets, parents, fnames[ii], opttype)
        end
        if ftypes[ii] == Cint
            add_assign_sub!(i32sets, parents, fnames[ii], opttype)
        end
        if ftypes[ii] <: Enum{Cint}
            add_assign_sub!(i32sets, parents, fnames[ii], opttype)
        end
        if ftypes[ii] == Bool
            add_assign_sub!(bsets, parents, fnames[ii], opttype)
        end
        if isstructtype(ftypes[ii])
            f64_, i64_, i32_, b_ = genoptsetters(ftypes[ii], vcat(parents,fnames[ii]))
            append!(f64sets, f64_)
            append!(i64sets, i64_)
            append!(i32sets, i32_)
            append!(bsets, b_)
        end
        if isabstracttype(ftypes[ii]) && ftypes[ii] <: ABSTRACT_OPTS
            concrete = InteractiveUtils.subtypes(ftypes[ii])
            for stype in concrete
                f64_, i64_, i32_, b_ = genoptsetters_sub(stype, vcat(parents,fnames[ii]))
                append!(f64sets, f64_)
                append!(i64sets, i64_)
                append!(i32sets, i32_)
                append!(bsets, b_)
            end
        end
    end
    return f64sets, i64sets, i32sets, bsets
end

macro options(expr)
    esc(genoptsetters(eval(expr)))
end

macro concrete_dict(dictname, type)
    concrete_types = []
    abstract_types = [eval(type)]
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
    path_type_options = Dict{Path, Vector{Type}}()

    worklist::Vector{Tuple{PathWithGuards, Type}} = [(((fname,), []),ftype) for (fname, ftype) in  zip(fnames,ftypes)]

    while !isempty(worklist)
        ((path, guards), type) = popfirst!(worklist)
        println("$(path), $(guards), $(type)")
        if type <: ConcreteOption
            push!(valid_paths, path => type)
            if !haskey(path_guards, path)
                push!(path_guards, path => [])
            end
            push!(path_guards[path], guards)
        elseif isconcretetype(type)
            fnames_ = fieldnames(type)
            ftypes_ = fieldtypes(type)
            append!(worklist, [(((path...,fname,), guards),ftype) for (fname, ftype) in zip(fnames_,ftypes_)])
        else
            uts, cts = get_concrete_types(type)
            push!(valid_paths, (path..., :TYPE) => Type)
            push!(path_type_options, path => uts)
            if !haskey(path_guards, (path..., :TYPE))
                push!(path_guards, (path..., :TYPE) => [])
            end
            push!(path_guards[(path..., :TYPE)], guards)
            for (ut, ct) in zip(uts,cts)
                fnames_ = fieldnames(ct)
                ftypes_ = fieldtypes(ct)
                new_guards = vcat(guards, (path, ut))

                append!(worklist, [(((path...,fname,), new_guards), ftype) for (fname, ftype) in zip(fnames_,ftypes_)])
            end
        end
    end

    return valid_paths, path_guards, path_type_options
end

function generate_guard(guard)
    if isempty(guard)
        return :()
    elseif length(guard) == 1
        (path, type) = guard[1]
        return :(opts.dict[($(path)...,:TYPE)] == $(normalize_typename(type)))
    else
        (path, type) = guard[1]
        return :(opts.dict[($(path)...,:TYPE)] == $(normalize_typename(type)) && $(generate_guard(guard[2:end])))
    end
end

function generate_guards(guards, errcode)
    if isempty(guards)
        return :()
    elseif length(guards) == 1
        return :(($(generate_guard(guards[1]))) || return Cint($(errcode)))
    else
        return :(($(generate_guard(guards[1]))) || ($(generate_guards(guards[2:end], errcode))))
    end
end

function generate_setter_check(path, guards, errorcode)
    return quote
        if path == $(path)
            $(generate_guards(guards, errorcode))
            opts.dict[path] = val
            return Cint(0)
        end
    end
end

function generate_setter(opts_type, dict_type, leaf_type, valid_paths, path_guards, path_type_options)
    leaf_name = Symbol(lowercase(String(leaf_type.name.name)))
    opts_name = Symbol(lowercase(String(opts_type.name.name)))

    for (path, type) in valid_paths
        ntype = normalize_type(type)
        if normalize_type != leaf_type
            continue
        end


    end

    setter = quote
        Base.@ccallable function $(Symbol(opts_name,:_set_ ,leaf_name, :_option))(opts_ptr::Ptr{$(dict_type)}, name::Cstring, val::$(leaf_type))::Cint

        end
    end

    return setter
end

# Generate opts dict and opts dict interface for
macro opts_dict(optstype_expr, optsdict_expr)
    # get type
    # TODO(@anton check if is subtype of AbstractOptions
    optstype = eval(optstype_expr)

    valid_paths, path_guards, path_type_options = get_path_info(optstype)

    normal_leaf_types = Set(normalize_type.(values(valid_paths)))

    return esc(generate_setter(optstype, optsdict_expr, Int64, valid_paths, path_guards, path_type_options))
end
