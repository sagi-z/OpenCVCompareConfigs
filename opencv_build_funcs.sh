#!/bin/bash

pushd `dirname $0` > /dev/null
abs_path=$PWD
popd > /dev/null

export OPENCV_TEST_DATA_PATH="/home/pi/opencv_extra/testdata"
if [ ! -d "$OPENCV_TEST_DATA_PATH" ]; then
	echo "No $OPENCV_TEST_DATA_PATH directory, do this first:"
	echo "cd && git clone git://github.com/Itseez/opencv_extra.git"
	exit -1;
fi

src_dir="/home/pi/tmp/mnt"
if [ ! -f "${src_dir}/CMakeLists.txt" ]; then
	echo "Using source dir '$src_dir', but didn't find file '${src_dir}/CMakeLists.txt'"
	echo "Fix src_dir in the script or mount the directory to sources before executing the script"
	exit -1;
fi
cd $src_dir

failures=()
fail_cont () {
	if [ ! "$1" ]; then
		echo "fail_cont must get a failure message"
		exit -1
	fi
	echo $1
	failures=("${failures[@]}" "$1")
}

report_failures () {
	echo ""
	if [ ${#failures[@]} -eq 0 ]; then
		echo "========================="
		echo "No failures were detected"
		echo "========================="
	else
		echo "============================"
		echo "These failures were detected:"
		echo "============================"
		for i in "${failures[@]}"
			do
			echo $i 
		done
	fi
}

build () {
	my_build_name=$1
	my_config=$2
	if [ ! "$my_build_name" ]; then
		echo "build must get a build name"
		exit -1
	fi
	if [ ! "$my_config" ]; then
		echo "build must get a config command"
		exit -1
	fi
	if [ -d "$my_build_name" ]; then
		echo $my_build_name exists - skip it
	else
		echo $my_build_name does not exist - build it
		mkdir $my_build_name
		cd $my_build_name
		echo "Config with: $my_config" > build_cmake.log
		eval $my_config 2>&1 | tee -a build_cmake.log
		if [ -f "Makefile" ]; then
			echo "Make with: make -j 4" > build_make.log
			make -j 4 2>&1 | tee -a build_make.log
			if [ ! -f "lib/libopencv_stitching.so.3.1.0" ]; then
				fail_cont "Please fix build issues (make failed) for '$my_build_name'"
			fi
		else
			fail_cont "Please fix build issues (cmake failed) for '$my_build_name'"
		fi
		cd - > /dev/null
	fi
}  

build_pkg () {
	my_build_name=$1
	if [ ! "$my_build_name" ]; then
		echo "build_pkg must get a build name"
		exit -1
	fi
	if [ -d $my_build_name ]; then
		cd $my_build_name
		if [ -f opencv_*.deb ]; then
			echo "A deb was found for $my_build_name - skip deb build"
		else
			if [ -f "lib/libopencv_stitching.so.3.1.0" ]; then
				echo "opencv 3.1.0 $my_build_name" > description-pak
				echo | sudo checkinstall -D --install=no --pkgname=opencv --pkgversion=3.1.0 --provides=opencv --nodoc --backup=no --exclude=$HOME
			else
				fail_cont "Please fix build issues for '$my_build_name' before building a deb package"
			fi
		fi
		cd - > /dev/null
	fi
}

perf_builds=()
perf_test () {
	my_build_name=$1
	if [ ! "$my_build_name" ]; then
		echo "perf_test must get a build name"
		exit -1
	fi
	perf_builds=("${perf_builds[@]}" "$my_build_name")
	if [ -d $my_build_name ]; then
		cd $my_build_name
		if [ -f core_*xml ]; then
			echo "Performance tests already executed for $my_build_name"
		else
			if [ -f "lib/libopencv_stitching.so.3.1.0" ]; then
				python ../modules/ts/misc/run.py .
			else
				fail_cont "Please fix build issues for '$my_build_name' before running performance tests"
			fi
		fi
                # Change filenames to something more meaningful for compare
		for file in *.xml; do
			file_name=$(echo $file | perl -pe 's/([^_]+).*/$1_'$my_build_name'.xml/')
			if [ "$file" != "$file_name" ]; then
				echo mv $file $file_name
				mv $file $file_name
			fi
		done
		cd - > /dev/null
	fi
}  

perf_compare_against () {
	my_base_build=$1
	if [ ! "$my_base_build" ]; then
		echo "perf_compare_against must get a build name to compare against"
		exit -1
	fi
	if [ ${#failures[@]} -eq 0 ]; then
		tmp_perf_builds="${perf_builds[@]}"
		perf_builds=( $my_base_build )
		for bld in $tmp_perf_builds; do
			if [ "$bld" != "$my_base_build" ]; then
				perf_builds=( "${perf_builds[@]}" $bld)
			fi
		done
		echo "Comparing performance of ${perf_builds[@]} (all compared against the first one)"
		for module in core calib3d features2d videoio video stitching objdetect superres photo imgproc
			do
			echo "Comparing module '$module' will go into ${src_dir}/compare_${module}.html"
			xml_files=( ${perf_builds[@]/%//${module}_*xml} )
			python modules/ts/misc/summary.py ${xml_files[@]} --with-score -o html > compare_${module}.html
			${abs_path}/averageXFactor.pl compare_${module}.html
		done
	else
		echo "Will not compare peformance because of previous failures"
	fi
}

