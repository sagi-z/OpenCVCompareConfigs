The OpenCVCompareConfigs project
================================

* A simple build system for multiple OpenCV build configurations.
* Was developped for Raspberry Pi but will work on debian like systems (Ubuntu).
* Supports building OpenCV debian packages for manually installing and testing your code against.
* Supports comparing OpenCV performance of different builds in detail and global average.

[For some background see my blog](https://www.theimpossiblecode.com/blog/build-faster-opencv-raspberry-pi3 "the impossible code")

##  Installing and usage
### Install
```
git clone https://github.com/sagi-z/OpenCVCompareConfigs.git
sudo apt-get install checkinstall
```

### Setup
Edit the *OpenCVCompareConfigs/opencv\_build\_funcs.sh*:
* Update the *OPENCV\_TEST\_DATA\_PATH* variable (the script error message will show you how to get the OpenCV test data).
* Update the *src\_dir* vaiable to the OpenCV source location (where the *CMakeLists.txt* is).

Edit the *OpenCVCompareConfigs/opencv\_builds.sh*:
* Edit/Delete/Add builds as the examples with the commented headers #1, #2, #3 and #4.
* If not changed, the currently 4 builds will be used, all building packages and testing performance against the simple release build.
* These are the supported bash functions:
.. *build(build\_name, cmake\_command)*
.. *build\_pkg(build\_name)*
.. *perf\_test(build\_name)*
.. *report\_failures()*
.. *perf\_compare\_against(build\_name\_to\_compare\_against)*

### Build/Test Performance/Compare
This can take days on Raspberry Pi3, mainly because of the performance tests.
```
OpenCVCompareConfigs/opencv_builds.sh
```

### Continue after fixing a build/confgiuation problem
* Simply remove the directory which failed to build and run the script again.
* The script will not re-build (cmake & make) a directory if it exists.
* The script will not rebuild a deb package if a deb is already built for that build.
* The script will not execute performance tests again for a build if it's xml files are already there.
* The script **will overwrite** the html summary files for each execution, as this is relatively fast and useful to redo (you can change the base you're comparing to and rerun).

