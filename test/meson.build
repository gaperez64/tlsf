# Tests
t = executable('tlsfparse_test', 'tlsfparse_test.c',
               link_with : tlsfparse_lib,
               include_directories : tlsf_inc)

test('test parsing tlsf 1', t, args: ['1'])
test('test parsing tlsf 2', t, args: ['2'])
test('test parsing tlsf 3', t, args: ['3'])
