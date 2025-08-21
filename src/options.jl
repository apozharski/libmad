const ABSTRACT_OPTS = Union{MadNLP.AbstractBarrierUpdate}

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
            add_assign(f64sets, parents, fnames[ii])
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
