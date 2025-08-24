cmake_minimum_required(VERSION 3.17)
project(libMad)

message(CHECK_START "Check Juliaup Executable")
set(JULIAUP_EXECUTABLE "juliaup" CACHE STRING "Juliaup executable default")
if (JULIAUP_EXECUTABLE STREQUAL "julia")
  execute_process(
    COMMAND which juliaup
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE JULIAUP_EXECUTABLE_PARSED
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(JULIAUP_EXECUTABLE ${JULIAUP_EXECUTABLE_PARSED} CACHE STRING "Juliaup executable" FORCE)
endif()
message(CHECK_PASS "Check Juliaup Executable")

message(CHECK_START "Check Julia Executable")
set(JULIA_EXECUTABLE "julia" CACHE STRING "Julia exectuable default")
if (JULIA_EXECUTABLE STREQUAL "julia")
  execute_process(
    COMMAND which julia
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE JULIA_EXECUTABLE_PARSED
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  set(JULIA_EXECUTABLE ${JULIA_EXECUTABLE_PARSED} CACHE STRING "Julia executable" FORCE)
endif()
message(CHECK_PASS "Check Julia Executable")

message(CHECK_START "Check julia version")
if(NOT DEFINED JULIA_VERSION)
  execute_process(
    COMMAND ${JULIA_EXECUTABLE} --startup-file=no --version
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE JULIA_VERSION_FULL
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  string(
    REGEX REPLACE
    "^julia version (.*)"
    "\\1"
    JULIA_VERSION
    ${JULIA_VERSION_FULL}
  )
endif()
if(JULIA_VERSION VERSION_LESS "1.12.0-rc1")
  message(CHECK_FAIL "Incompatible Julia version: ${JULIA_VERSION}")
  # TODO if juliaup exists then we should install minimum version manually.
else()
  message(CHECK_PASS "Compatible julia version: ${JULIA_VERSION}")
endif()


# detect Julia binary dir
if(NOT DEFINED JULIA_BINDIR)
    # The executable could be a chocolatey shim, so run some Julia code to report
    # the path of the BINDIR
    execute_process(
      COMMAND "${JULIA_EXECUTABLE}" --startup-file=no -e "print(Sys.BINDIR)"
      OUTPUT_VARIABLE JULIA_BINDIR_LOCAL
    )
    file(TO_CMAKE_PATH "${JULIA_BINDIR_LOCAL}" JULIA_BINDIR_LOCAL)
    set(JULIA_BINDIR "${JULIA_BINDIR_LOCAL}" CACHE PATH "")
endif()
get_filename_component(JULIA_PATH_PREFIX "${JULIA_BINDIR}" DIRECTORY)

message(CHECK_START "Find juliac.jl")
# TODO is this consistent? for now it is
find_file(JULIAC_EXECUTABLE juliac.jl HINT ${JULIA_PATH_PREFIX}/share/julia/juliac)
if(NOT JULIAC_EXECUTABLE)
  message(CHECK_FAIL "juliac.jl not found")
else()
  message(CHECK_PASS "juliac.jl found")
endif()


add_custom_command(
  OUTPUT ${PROJECT_BINARY_DIR}/libMad.so
  COMMAND ${JULIA_EXECUTABLE} --project=${PROJECT_SOURCE_DIR} --startup-file=no ${JULIAC_EXECUTABLE} ${PROJECT_SOURCE_DIR}/src/libMad.jl --compile-ccallable --experimental --trim=no --output-lib ${PROJECT_BINARY_DIR}/libMad
)

add_custom_target(
  libMad ALL
  DEPENDS ${PROJECT_BINARY_DIR}/libMad.so
  SOURCES ${PROJECT_SOURCE_DIR}/src/libMad.jl
  ${PROJECT_SOURCE_DIR}/src/options.jl
  ${PROJECT_SOURCE_DIR}/src/madnlp.jl
  ${PROJECT_SOURCE_DIR}/src/nlpmodels.jl
)
