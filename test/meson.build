# Tests
t = executable('tlsfparse_test', 'tlsfparse_test.c',
               link_with : tlsfparse_lib,
               include_directories : tlsf_inc)

syntaxtests = [1, 2, 3, 4, 5, 6, 7, 8]
foreach i : syntaxtests
  test('test parsing tlsf' + i.to_string(), t, args: [i.to_string()])
endforeach
