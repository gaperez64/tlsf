# Tests
t = executable('tlsfparse_test', 'tlsfparse_test.c',
               link_with : tlsfparse_lib,
               include_directories : tlsf_inc)

foreach i : range(1, 9)
  test('test syntax tlsf ' + i.to_string(), t, args: [i.to_string()])
endforeach

foreach i : range(9, 17)
  test('test info tlsf ' + i.to_string(), t, args: [i.to_string()])
endforeach
