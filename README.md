# libMad
`libMad` is a metapackage used to compile a shared library which contains a c interface for MadNLP.
It is currently _very much_ a work in progress.

## Current development
Requires `Julia 1.12+` and the [`JuliaC.jl` package](https://github.com/JuliaLang/JuliaC.jl).
The `JuliaC.jl` app should be installed and a work around for [JuliacLang/JuliaC.jl#13](https://github.com/JuliaLang/JuliaC.jl/issues/13) implemented, i.e., add `:$JULIA_LOAD_PATH` to the shim where the `JULIA_LOAD_PATH` is loaded.
Checks for these requirements are not currently failing the cmake.
To build:
```bash
mkdir build
cd build
cmake ..
make
```
Which makes the library as well as a basic executable.