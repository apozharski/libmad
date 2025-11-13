cmake_minimum_required(VERSION 3.17)
project(libMad C)
include(CMakePackageConfigHelpers)
include(CMakePrintHelpers)
include(GNUInstallDirs)

if(NOT JULIAC_FLAGS)
    set(JULIAC_FLAGS "")
endif()

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

message("${JULIA_EXECUTABLE}")
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
set(JULIA_INCLUDE_DIR ${JULIA_PATH_PREFIX}/include/julia)

message(CHECK_START "Find juliac.jl")
# TODO is this consistent? for now it is
find_file(JULIAC_EXECUTABLE juliac.jl HINT ${JULIA_PATH_PREFIX}/share/julia/juliac)
if(NOT JULIAC_EXECUTABLE)
  message(CHECK_FAIL "juliac.jl not found")
else()
  message(CHECK_PASS "juliac.jl found")
endif()

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/include")

add_custom_command(
  OUTPUT ${PROJECT_BINARY_DIR}/lib/libMad.so
  ${PROJECT_BINARY_DIR}/lib
  ${PROJECT_BINARY_DIR}/share
  COMMAND juliac  --compile-ccallable --bundle ${PROJECT_BINARY_DIR} --experimental ${JULIAC_FLAGS} --output-lib ${PROJECT_BINARY_DIR}/libMad ${PROJECT_SOURCE_DIR}
  DEPENDS ${PROJECT_SOURCE_DIR}/src/libMad.jl
  ${PROJECT_SOURCE_DIR}/src/utils.jl
  ${PROJECT_SOURCE_DIR}/src/options.jl
  ${PROJECT_SOURCE_DIR}/src/solver.jl
  ${PROJECT_SOURCE_DIR}/src/stats.jl
  ${PROJECT_SOURCE_DIR}/src/madnlp.jl
  ${PROJECT_SOURCE_DIR}/src/nlpmodels.jl
)

add_custom_command(
  OUTPUT ${PROJECT_BINARY_DIR}/include/libMad.h
  COMMAND ${JULIA_EXECUTABLE} --project=${PROJECT_SOURCE_DIR} --startup-file=no ${PROJECT_SOURCE_DIR}/scripts/generate_headers.jl ${PROJECT_BINARY_DIR}/include
  DEPENDS ${PROJECT_SOURCE_DIR}/src/libMad.jl
  ${PROJECT_SOURCE_DIR}/src/utils.jl
  ${PROJECT_SOURCE_DIR}/src/options.jl
  ${PROJECT_SOURCE_DIR}/src/solver.jl
  ${PROJECT_SOURCE_DIR}/src/stats.jl
  ${PROJECT_SOURCE_DIR}/src/madnlp.jl
  ${PROJECT_SOURCE_DIR}/src/nlpmodels.jl
  ${PROJECT_SOURCE_DIR}/scripts/generate_headers.jl
)

add_custom_target(
  libMad_target ALL
  DEPENDS ${PROJECT_BINARY_DIR}/lib/libMad.so
  ${PROJECT_BINARY_DIR}/include/libMad.h
)

add_library(libMad SHARED IMPORTED global)
add_dependencies(libMad libMad_target)

set_target_properties(libMad
  PROPERTIES
  IMPORTED_LOCATION ${PROJECT_BINARY_DIR}/lib/libMad.so
  IMPORTED_IMPLIB ${PROJECT_BINARY_DIR}/lib/libMad.so
)
set_target_properties(libMad PROPERTIES LINKER_LANGUAGE C)


target_include_directories(libMad INTERFACE
  ${PROJECT_BINARY_DIR}/include
  ${JULIA_INCLUDE_DIR}
  $<INSTALL_INTERFACE:include/>
)

add_executable(basic_problem ${PROJECT_SOURCE_DIR}/examples/basic_problem.c)

target_link_libraries(basic_problem PRIVATE libMad)

cmake_print_properties(TARGETS libMad
  PROPERTIES LINKER_LANGUAGE
  IMPORTED_IMPLIB
)
## NOW DO INSTALL
install(
  DIRECTORY ${PROJECT_BINARY_DIR}/lib
  DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(
  FILES
    ${PROJECT_BINARY_DIR}/libMad.h
  DESTINATION
    include
)

install(TARGETS ${EXECUTABLE_NAME}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
## Export configs
# export(TARGETS libMad
#   FILE "${PROJECT_BINARY_DIR}/libmad-targets.cmake")
