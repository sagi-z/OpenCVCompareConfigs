#!/bin/bash

# incude all the functions first
dir=`dirname $0`
. ${dir}/opencv_build_funcs.sh

# use build() and then optionally build_pkg() and/or perf_test() 

# 1
build="build_rpi3_release"
build $build 'cmake -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..'
build_pkg $build
perf_test $build

# 2
build="build_rpi3_release_fp"
build $build 'cmake -DBUILD_TESTS=OFF -DENABLE_VFPV3=ON -DENABLE_NEON=ON -DCMAKE_BUILD_TYPE=Release ..'
build_pkg $build
perf_test $build

# 3
build="build_rpi3_release_tbb"
build $build 'cmake  -DCMAKE_CXX_FLAGS="-DTBB_USE_GCC_BUILTINS=1 -D__TBB_64BIT_ATOMICS=0" -DBUILD_TESTS=OFF -DWITH_TBB=ON -DCMAKE_BUILD_TYPE=Release ..'
build_pkg $build
perf_test $build

# 4
build="build_rpi3_release_fp_tbb"
build $build 'cmake  -DCMAKE_CXX_FLAGS="-DTBB_USE_GCC_BUILTINS=1 -D__TBB_64BIT_ATOMICS=0" -DENABLE_VFPV3=ON -DENABLE_NEON=ON -DBUILD_TESTS=OFF -DWITH_TBB=ON -DCMAKE_BUILD_TYPE=Release ..'
build_pkg $build
perf_test $build

# Do this last
report_failures
perf_compare_against build_rpi3_release
