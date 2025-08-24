Base.@ccallable function test_func(val::Cstring)::Cint
    path = Tuple(Symbol.(split(unsafe_string(val), ".")))
    if path == (:foo,)
        val = Cint(1)
    elseif path == (:bar, :baz)
        val = Cint(2)
    else
        val = Cint(3)
    end
        
    return Cint(val+1)
end
