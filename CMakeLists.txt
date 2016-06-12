# Modified by Luc Michalski - 2016

cmake_minimum_required(VERSION 3.5)

include("cmake/HunterGate.cmake")
HunterGate(
    URL "https://github.com/ruslo/hunter/archive/v0.14.25.tar.gz"
    SHA1 "a7ba9775c1206ced7cac204db802b116736ca481"
)

project(libmill C)

#### settings 

option(MILL_STATIC_LIB "Build static librairies" ON)
option(MILL_SHARED_LIB "Build shared librairies" ON)
option(MILL_PERFS "Build performances tests" OFF)
option(MILL_TESTS "Build unit tests" OFF)

#### install 

set(config_install_dir "lib/cmake/${PROJECT_NAME}")
set(include_install_dir "include")

set(generated_dir "${CMAKE_CURRENT_BINARY_DIR}/generated")

# Configuration
set(version_config "${generated_dir}/${PROJECT_NAME}ConfigVersion.cmake")
set(project_config "${generated_dir}/${PROJECT_NAME}Config.cmake")
set(targets_export_name "${PROJECT_NAME}Targets")
set(namespace "${PROJECT_NAME}::")

include(CMakePackageConfigHelpers)

configure_package_config_file(
  "cmake/Config.cmake.in"
  "${project_config}"
  INSTALL_DESTINATION "${config_install_dir}"
  )


include(CheckSymbolExists)
include(CheckFunctionExists)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")

# static and shared libs
file(GLOB sources *.c dns/*.c)
set_source_files_properties(dns/dns.c PROPERTIES COMPILE_FLAGS -std=c99)

set(headers "")
foreach(x ${sources})
  string(REGEX MATCH ".*\\.h$" is_header "${x}")
  if(is_header)
    list(APPEND headers "${x}")
  endif()
endforeach()

foreach(HEADER ${headers})
  install(
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/${HEADER}"
    DESTINATION "${include_install_dir}/${PROJECT_NAME}"
    )
endforeach()

if(MILL_STATIC_LIB)
add_library(mill STATIC ${sources})
set_target_properties(mill PROPERTIES OUTPUT_NAME mill)

install(
  TARGETS mill
  EXPORT "${targets_export_name}"
  LIBRARY DESTINATION "lib"
  ARCHIVE DESTINATION "lib"
  RUNTIME DESTINATION "bin"
  INCLUDES DESTINATION "${include_install_dir}"
  )

install(
  FILES "${project_config}" "${version_config}"
  DESTINATION "${config_install_dir}"
  )

install(
  EXPORT "${targets_export_name}"
  NAMESPACE "${namespace}"
  DESTINATION "${config_install_dir}"
  )

endif()

if(MILL_SHARED_LIB)
add_library(mill_s SHARED ${sources})
set_target_properties(mill_s PROPERTIES OUTPUT_NAME mill)

install(
  TARGETS mill_s
  EXPORT "${targets_export_name}"
  LIBRARY DESTINATION "lib"
  ARCHIVE DESTINATION "lib"
  RUNTIME DESTINATION "bin"
  INCLUDES DESTINATION "${include_install_dir}"
  )

install(
  FILES "${project_config}" "${version_config}"
  DESTINATION "${config_install_dir}"
  )

install(
  EXPORT "${targets_export_name}"
  NAMESPACE "${namespace}"
  DESTINATION "${config_install_dir}"
  )

endif()


# check and enable rt if available
list(APPEND CMAKE_REQUIRED_LIBRARIES rt)
check_symbol_exists(clock_gettime time.h HAVE_CLOCK_GETTIME)
if(HAVE_CLOCK_GETTIME)
  target_link_libraries(mill rt)
  if(MILL_SHARED_LIB)
    target_link_libraries(mill_s rt)
  endif()
endif()

set(CMAKE_REQUIRED_LIBRARIES )

# check and enable stack guard and dns if available
list(APPEND CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)

set(CMAKE_REQUIRED_LIBRARIES )
set(CMAKE_REQUIRED_DEFINITIONS )

check_function_exists(mprotect HAVE_MPROTECT)
if(HAVE_MPROTECT)
  add_definitions(-DHAVE_MPROTECT)
endif()

check_function_exists(posix_memalign HAVE_POSIX_MEMALIGN)
if(HAVE_POSIX_MEMALIGN)
  add_definitions(-DHAVE_POSIX_MEMALIGN)
endif()

if(MILL_TESTS)
# tests
enable_testing()
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/tests)
file(GLOB test_files tests/*.c)
foreach(test_file IN LISTS test_files)
  get_filename_component(test_name ${test_file} NAME_WE)
  add_executable(test_${test_name} ${test_file})
  set_target_properties(test_${test_name} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/tests
    OUTPUT_NAME ${test_name})
  target_link_libraries(test_${test_name} mill)
  add_test(test_${test_name} tests/${test_name})
endforeach()
endif()

if(MILL_PERFS)
# perf
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/perf)
file(GLOB perf_files perf/*.c)
foreach(perf_file IN LISTS perf_files)
  get_filename_component(perf_name ${perf_file} NAME_WE)
  add_executable(perf_${perf_name} ${perf_file})
  set_target_properties(perf_${perf_name} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/perf
    OUTPUT_NAME ${perf_name})
  target_link_libraries(perf_${perf_name} mill)
endforeach()
endif()

install(TARGETS mill DESTINATION "lib" EXPORT LibMill)
install(
    EXPORT LibMill NAMESPACE LibMill:: DESTINATION "lib/cmake/LibMill"
)