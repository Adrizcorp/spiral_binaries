# CMake generated Testfile for 
# Source directory: C:/spiral/spiral-software/tests/OpenMP
# Build directory: C:/spiral/spiral-software/tests/OpenMP
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
if("${CTEST_CONFIGURATION_TYPE}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
  add_test(OpenMP "C:/spiral/spiral-software/spiral.bat" "<" "C:\\spiral\\spiral-software\\tests\\OpenMP\\OpenMP.g")
  set_tests_properties(OpenMP PROPERTIES  FAIL_REGULAR_EXPRESSION "TEST FAILED" LABELS "OpenMP" _BACKTRACE_TRIPLES "C:/spiral/spiral-software/config/CMakeIncludes/TestDefines.cmake;37;add_test;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;21;my_add_test_target;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;0;")
elseif("${CTEST_CONFIGURATION_TYPE}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
  add_test(OpenMP "C:/spiral/spiral-software/spiral.bat" "<" "C:\\spiral\\spiral-software\\tests\\OpenMP\\OpenMP.g")
  set_tests_properties(OpenMP PROPERTIES  FAIL_REGULAR_EXPRESSION "TEST FAILED" LABELS "OpenMP" _BACKTRACE_TRIPLES "C:/spiral/spiral-software/config/CMakeIncludes/TestDefines.cmake;37;add_test;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;21;my_add_test_target;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;0;")
elseif("${CTEST_CONFIGURATION_TYPE}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
  add_test(OpenMP "C:/spiral/spiral-software/spiral.bat" "<" "C:\\spiral\\spiral-software\\tests\\OpenMP\\OpenMP.g")
  set_tests_properties(OpenMP PROPERTIES  FAIL_REGULAR_EXPRESSION "TEST FAILED" LABELS "OpenMP" _BACKTRACE_TRIPLES "C:/spiral/spiral-software/config/CMakeIncludes/TestDefines.cmake;37;add_test;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;21;my_add_test_target;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;0;")
elseif("${CTEST_CONFIGURATION_TYPE}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
  add_test(OpenMP "C:/spiral/spiral-software/spiral.bat" "<" "C:\\spiral\\spiral-software\\tests\\OpenMP\\OpenMP.g")
  set_tests_properties(OpenMP PROPERTIES  FAIL_REGULAR_EXPRESSION "TEST FAILED" LABELS "OpenMP" _BACKTRACE_TRIPLES "C:/spiral/spiral-software/config/CMakeIncludes/TestDefines.cmake;37;add_test;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;21;my_add_test_target;C:/spiral/spiral-software/tests/OpenMP/CMakeLists.txt;0;")
else()
  add_test(OpenMP NOT_AVAILABLE)
endif()
