cmake_minimum_required(VERSION 3.17)
project(libMad C)
include(CMakePackageConfigHelpers)
include(CMakePrintHelpers)
include(GNUInstallDirs)

if(NOT JULIAC_FLAGS)
  set(JULIAC_FLAGS "")
endif()
option(WITH_EXAMPLE "Build basic example" ON)

# Set JULIA_HSL_LIBRARY_PATH.
# TODO(@anton) Make this make sense for mac/windows?
# TODO(@anton) There might be a better way of doing this.
#              Currently HSL.jl loads this at compile time
#SET(ENV{JULIA_HSL_LIBRARY_PATH} ".")

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
  if(LINUX OR APPLE)
    execute_process(
      COMMAND which julia
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE JULIA_EXECUTABLE_PARSED
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
  elseif(WIN32)
    execute_process(
      COMMAND where.exe julia
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE JULIA_EXECUTABLE_PARSED
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    string(REGEX MATCH "(.*)\n|$" JULIA_EXECUTABLE_PARSED ${JULIA_EXECUTABLE_PARSED})
    string(STRIP ${JULIA_EXECUTABLE_PARSED} JULIA_EXECUTABLE_PARSED)
  endif()
  message("Julia executable: ${JULIA_EXECUTABLE_PARSED}")
  set(JULIA_EXECUTABLE ${JULIA_EXECUTABLE_PARSED} CACHE STRING "Julia executable" FORCE)
endif()
message(CHECK_PASS "Check Julia Executable")

message(CHECK_START "Check julia version")
if(NOT DEFINED JULIA_VERSION)
  execute_process(
    COMMAND ${JULIA_EXECUTABLE} --startup-file=no --version
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE JULIA_VERSION_FULL
    ERROR_VARIABLE JULIA_VERSION_ERROR
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
  message("Raw Julia version: ${JULIA_VERSION_FULL}")
  message("Julia version error: ${JULIA_VERSION_ERROR}")
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
set(JULIA_INCLUDE_DIR ${JULIA_PATH_PREFIX}/include/julia)

message(CHECK_START "Find juliac.jl")
if(LINUX OR APPLE)
  execute_process(
    COMMAND which juliac
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE JULIAC_EXECUTABLE
  )
  message(${JULIAC_EXECUTABLE})
elseif(WIN32)
  execute_process(
    COMMAND where.exe juliac
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE JULIAC_EXECUTABLE
  )
endif()
if(NOT JULIAC_EXECUTABLE)
  message(CHECK_FAIL "juliac.jl not found")
else()
  message(CHECK_PASS "juliac.jl found")
  message(${JULIAC_EXECUTABLE})
endif()

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/include")

# SETUP VARIABLES BECAUSE WINDOWS IS HORRIBLE:
if(LINUX OR APPLE)
  set(LIBMAD_SHARED_LIBRARY ${PROJECT_BINARY_DIR}/lib/libMad${CMAKE_SHARED_LIBRARY_SUFFIX})
  set(LIBMAD_SHARED_LIBRARY_PATH ${PROJECT_BINARY_DIR}/lib)
elseif(WIN32)
  set(LIBMAD_SHARED_LIBRARY ${PROJECT_BINARY_DIR}/bin/libMad${CMAKE_SHARED_LIBRARY_SUFFIX})
  set(LIBMAD_SHARED_LIBRARY_PATH ${PROJECT_BINARY_DIR}/bin)
endif()
set(LIBMAD_IMPLIB ${PROJECT_BINARY_DIR}/bin/libMad.imp.lib)
set(LIBMAD_HEADER ${PROJECT_BINARY_DIR}/include/libMad.h)
set(LIBMAD_HEADER_PATH ${PROJECT_BINARY_DIR}/include)
set(LIBMAD_BUNDLE_PATH ${PROJECT_BINARY_DIR}/share)
set(LIBMAD_SHARED_LIBRARY_DEPENDENCIES
  ${PROJECT_SOURCE_DIR}/src/libMad.jl
  ${PROJECT_SOURCE_DIR}/src/utils.jl
  ${PROJECT_SOURCE_DIR}/src/options.jl
  ${PROJECT_SOURCE_DIR}/src/solver.jl
  ${PROJECT_SOURCE_DIR}/src/stats.jl
  ${PROJECT_SOURCE_DIR}/src/madnlp.jl
  ${PROJECT_SOURCE_DIR}/src/nlpmodels.jl
)
set(LIBMAD_GENERATE_HEADERS_SCRIPT ${PROJECT_SOURCE_DIR}/scripts/generate_headers.jl)
set(LIBMAD_HEADER_DEPENDENCIES
  ${PROJECT_SOURCE_DIR}/src/libMad.jl
  ${PROJECT_SOURCE_DIR}/src/utils.jl
  ${PROJECT_SOURCE_DIR}/src/options.jl
  ${PROJECT_SOURCE_DIR}/src/solver.jl
  ${PROJECT_SOURCE_DIR}/src/stats.jl
  ${PROJECT_SOURCE_DIR}/src/madnlp.jl
  ${PROJECT_SOURCE_DIR}/src/nlpmodels.jl
  ${PROJECT_SOURCE_DIR}/scripts/generate_headers.jl
)
if(LINUX OR APPLE)
  set(LIBMAD_JULIAC_OUTPUTS
    ${LIBMAD_SHARED_LIBRARY}
    ${LIBMAD_SHARED_LIBRARY_PATH}
    ${LIBMAD_BUNDLE_PATH}
  )
elseif(WIN32)
  set(LIBMAD_JULIAC_OUTPUTS
    ${LIBMAD_SHARED_LIBRARY}
    ${LIBMAD_IMPLIB}
    ${LIBMAD_SHARED_LIBRARY_PATH}
    ${LIBMAD_BUNDLE_PATH}
  )
endif()

cmake_path(NATIVE_PATH LIBMAD_SHARED_LIBRARY LIBMAD_SHARED_LIBRARY)
cmake_path(NATIVE_PATH LIBMAD_HEADER LIBMAD_HEADER)
cmake_path(NATIVE_PATH LIBMAD_GENERATE_HEADERS_SCRIPT LIBMAD_GENERATE_HEADERS_SCRIPT)
cmake_path(NATIVE_PATH LIBMAD_SHARED_LIBRARY_PATH LIBMAD_SHARED_LIBRARY_PATH)
cmake_path(NATIVE_PATH LIBMAD_HEADER_PATH LIBMAD_HEADER_PATH)
cmake_path(NATIVE_PATH LIBMAD_BUNDLE_PATH LIBMAD_BUNDLE_PATH)
cmake_path(NATIVE_PATH LIBMAD_SHARED_LIBRARY_DEPENDENCIES LIBMAD_SHARED_LIBRARY_DEPENDENCIES)
cmake_path(NATIVE_PATH LIBMAD_HEADER_DEPENDENCIES LIBMAD_HEADER_DEPENDENCIES)
cmake_path(NATIVE_PATH LIBMAD_JULIAC_OUTPUTS LIBMAD_JULIAC_OUTPUTS)
message("${LIBMAD_HEADER_DEPENDENCIES}")
message("${LIBMAD_SHARED_LIBRARY_DEPENDENCIES}")

# SETUP THE BUILD
add_custom_command(
  OUTPUT ${LIBMAD_JULIAC_OUTPUTS}
  COMMAND ${JULIAC_EXECUTABLE} --verbose --compile-ccallable --bundle ${PROJECT_BINARY_DIR} --experimental ${JULIAC_FLAGS} --output-lib libMad ${PROJECT_SOURCE_DIR}
  DEPENDS ${LIBMAD_SHARED_LIBRARY_DEPENDENCIES}
)

add_custom_command(
  OUTPUT ${LIBMAD_HEADER}
  COMMAND ${JULIA_EXECUTABLE} --project --startup-file=no ${LIBMAD_GENERATE_HEADERS_SCRIPT} ${LIBMAD_HEADER_PATH}
  DEPENDS ${LIBMAD_HEADER_DEPENDENCIES}
)

add_custom_target(
  libMad_target ALL
  DEPENDS ${LIBMAD_SHARED_LIBRARY}
  ${LIBMAD_HEADER}
)

add_library(libMad SHARED IMPORTED global)
add_dependencies(libMad libMad_target)

set_target_properties(libMad
  PROPERTIES
  IMPORTED_LOCATION ${LIBMAD_SHARED_LIBRARY}
  IMPORTED_IMPLIB ${LIBMAD_IMPLIB}
  IMPORTED_SONAME libMad
)
set_target_properties(libMad PROPERTIES LINKER_LANGUAGE C)


target_include_directories(libMad INTERFACE
  ${LIBMAD_HEADER_PATH}
  ${JULIA_INCLUDE_DIR}
  $<INSTALL_INTERFACE:include>
)

if(WITH_EXAMPLE)
  add_executable(basic_problem $<SHELL_PATH:${PROJECT_SOURCE_DIR}/examples/basic_problem.c>)
  if(APPLE)
    set_target_properties(
    basic_problem
    PROPERTIES 
    INSTALL_RPATH 
    "${CMAKE_INSTALL_RPATH};${CMAKE_INSTALL_PREFIX}/lib")  
  endif()
  target_link_libraries(basic_problem PRIVATE libMad)

  add_executable(no_hsl_example $<SHELL_PATH:${PROJECT_SOURCE_DIR}/examples/no_hsl_example.c>)
  if(APPLE)
    set_target_properties(
    no_hsl_example
    PROPERTIES 
    INSTALL_RPATH 
    "${CMAKE_INSTALL_RPATH};${CMAKE_INSTALL_PREFIX}/lib")  
  endif()
  target_link_libraries(no_hsl_example PRIVATE libMad)
endif()

cmake_print_properties(TARGETS libMad
  PROPERTIES LINKER_LANGUAGE
  IMPORTED_IMPLIB
)
## NOW DO INSTALL
install(
  DIRECTORY ${LIBMAD_SHARED_LIBRARY_PATH}
  DESTINATION "."
)
install(
  FILES
    ${LIBMAD_HEADER}
  DESTINATION
    include
)
install(
  DIRECTORY ${LIBMAD_BUNDLE_PATH}
  DESTINATION "."
)

if(WITH_EXAMPLE)
  install(TARGETS basic_problem
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
  install(TARGETS no_hsl_example
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()
## Export configs
# export(TARGETS libMad
#   FILE "${PROJECT_BINARY_DIR}/libmad-targets.cmake")
