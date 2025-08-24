using libMad
opts = libMad.MadNLPOptsDict(Dict())
opts_ptr = Ptr{libMad.MadNLPOptsDict}(pointer_from_objref(opts))
name = Vector{Int8}([109,97,120,95,105,116,101,114,0]) # max_iter
name_ptr = Cstring(pointer(name))
val = Clong(10)
libMad.madnlpoptions_set_int64_option(opts_ptr, name_ptr, val)
