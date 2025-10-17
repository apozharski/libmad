# Function barrier around unsafe_wrap?
function wrap_ptr(ptr::Ptr{T}, n::Int)::Vector{T} where T
    return unsafe_wrap(Vector{T}, ptr, n)
end

function wrap_obj(ptr::Ptr{T})::T where T
    return unsafe_pointer_to_objref(ptr)
end

function wrap_obj(::Type{T}, ptr::Ptr{Cvoid})::T where T
    return unsafe_pointer_to_objref(Ptr{T}(ptr))
end
