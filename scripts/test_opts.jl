using libMad
opts_ptr_ptr = Ref{Ptr{libMad.MadNLPOptsDict}}(opts_ptr)
libMad.madnlpoptions_create_options_struct(opts_ptr_ptr)

name = Vector{Int8}([109,97,120,95,105,116,101,114,0]) # max_iter
name_ptr = Cstring(pointer(name))
val = Clonglong(10)
libMad.madnlpoptions_set_int64_option(opts_ptr, name_ptr, val)
