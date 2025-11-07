project('libmad', ['c'],
        version : '0.0.1'
       )

julia = find_program('julia')
juliac = find_program('juliac')

libmad_name = 'libMad'
libmad_project_source_root = meson.project_source_root()
libmad_jl_depends = [ 'src/libMad.jl',
                      'src/utils.jl',
                      'src/options.jl',
                      'src/solver.jl',
                      'src/stats.jl',
                      'src/madnlp.jl',
                      'src/nlpmodels.jl'
                    ]

# commands for building libMad.so
libmad_so_fname = f'@libmad_name@.so'

juliac_experimental_flags = []

juliac_flags = ['--compile-ccallable',
                #'--bundle',
                #meson.project_build_root(),
                '--experimental',
                juliac_experimental_flags,
                '--output-lib',
                libmad_name,
               ]


juliac_command = [ juliac,
                   juliac_flags,
                   libmad_project_source_root
                 ]

libmad_so = custom_target('libMad.so',
                          output      : libmad_so_fname,
                          input       : libmad_jl_depends,
                          command     : juliac_command,
                          install     : true,
                          install_dir : 'lib'
                      )

# commands for generating libmad header
libmad_h_fname = f'@libmad_name@.h'
libmad_h_generator = libmad_project_source_root / 'scripts/generate_headers.jl'

julia_header_command = [julia,
                        '--project=@libmad_project_source_root@',
                        '--startup-file=no',
                        libmad_h_generator,
                        meson.project_build_root() / 'include'
                       ]

libmad_h = custom_target('libMad.h',
                         output      : libmad_h_fname,
                         input       : libmad_jl_depends,
                         command     : julia_header_command,
                         install     : true,
                         install_dir : 'include'
                        )
# alias target for building the library
libmad = alias_target(libmad_name,
                      'libMad.h',
                      'libmad.so')
# commands for generating example
basic_problem_source = 'examples'/'basic_problem.c'
basic_problem = executable('basic_problem',
                           basic_problem_source,
                           link_with : [libmad_so]
                          )
