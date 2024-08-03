# Flex as a generator
flex = find_program('flex')
lgen = generator(flex,
                 output: ['@BASENAME@.lex.c', '@BASENAME@.lex.h'],
                 arguments: ['--outfile=@OUTPUT0@',
                             '--header-file=@OUTPUT1@',
                             '@INPUT@'])

# Bison as a generator
bison = find_program('bison')
pgen = generator(bison,
                 output: ['@BASENAME@.tab.c', '@BASENAME@.tab.h'],
                 arguments: ['--output=@OUTPUT0@',
                             '--defines=@OUTPUT1@',
                             '@INPUT@'])

# Library: Functions and expressions
#tlsfspec_lib = library('tlsfspec', 'tlsfspec.c')

# Library: TLSF parser
tlsfparse_lib = library('tlsfparse',
                        [lgen.process('tlsf.l'),
                         pgen.process('tlsf.y')],
                        #link_with : [tlsfspec_lib],
                        include_directories : [tlsf_inc])

