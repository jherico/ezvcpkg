# EZ-VCPKG

A CMake script to automatically download and build vcpkg based projects and make them available 
to your projects

This script emphasizes reducing the overall build footprint and reduce the aggregate build time of
upstream dependencies.  It does this by building the dependencies outside of the cmake build 
directory, instead placing them in a vcpkg commit specific directory, which in turn can be placed 
inside any directory by populating the `EZVCPKG_BASEDIR` environment variable, or which defaults to 
`$ENV{TEMP}/ezvcpkg` or `$ENV{HOME}/.ezvcpkg` depending on the host platform.  

Once the dependencies are built, the disk space cost for them is fixed and the time cost is negligible
for future builds, even if you wipe out the CMake build directory and start from scratch.  

## Usage

Call `ezvcpkg_fetch()` with your desired arguments

## Arguments

* _PACKAGES pkga pkgb pkgc_

The list of packages to be installed.  Note that additional packages may be installed automatically based on the vcpkg dependency graph.

* _COMMIT commidId_ 

The commit ID of the git repository to select when building.  Defaults to `f990dfaa5ba82155f95b75021453c075816fd4be`

* _REPO org/repo_ or _URL url_

You can specify a full URL suitable for passing to `git clone` in the `URL` argument.  Alternatively, if you specify only a repository via the `REPO` argument in the form `microsoft/vcpkg` then it will automatically be expanded to GitHub repositoy URL in the form `https://github.com/microsoft/vcpkg.git`.  If neither a `REPO` or `URL` are specified, then it defaults to `https://github.com/microsoft/vcpkg.git`

* _BASEDIR filepath_ 

The local filesystem location in which to place EZVCPKG build direcotries.  If not specified, it will default to the location specified in an `EZVCPKG_BASEDIR` environment variable.  If this is also not specified, it will default to `~/.ezvcpkg`.

Within the base directory will be subdirectories that mirror the individual VCPKG repository commit IDs.

* _CLEAN days_

A number of days after which unused EZVCPKG commit folders within the `BASEDIR` location should be deleted to free up disk space.  This functionality is not currently implemented.

* _SERIALIZE_

By default EZVCPKG will execute a single command to build all the requested packages.  The `SERIALIZE` option will cause EZVCPKG to execute the `vcpkg install` command for each package individually, in the order they're listed.  May be useful for debugging failures.

* _USE_HOST_VCPKG_

By default, EZVCPKG will use the built-in bootstrap functionality to build the `vcpkg` executable.  If `USE_HOST_VCPKG` is enabled, then it will look for a `vcpkg` executable in the system path using cmake's `find_program` function.  If found it will skip the boostrapping and use the local `vcpkg` binary.  This can be useful in continuous integration where you can't cache the ezvcpkg folder, but you want to avoid the extra time building vcpkg itself (i.e. GitHub Actions)

## Output

After calling `ezvcpkg_fetch`, the `EZVCPKG_DIR` CMake variable will be populated with the local filesystem directory where the vcpkg installed files are.  For example, on a Windows system where the environment varaible EZVCPKG_BASEDIR is set to `D:\ezvcpkg` then it might be `D:\ezvcpkg\f990dfaa5ba82155f95b75021453c075816fd4be\installed\x64-windows`

## Examples

### Toolchain (recommended)

If you want to use the built-in find_package functionality with vcpkg packages that support it
you MUST call `EZVCPKG_FETCH` before the `PROJECT` directive, and you must include the `UPDATE_TOOLCHAIN` 
parameter, which will then populate `CMAKE_TOOLCHAIN_FILE` value before `EZVCPKG_FETCH` returns


```CMake
cmake_minimum_required(VERSION 3.10)

include(${CMAKE_SOURCE_DIR}/ezvcpkg.cmake)

ezvcpkg_fetch(
    PACKAGES glm vulkan basisu glfw3 imgui
    UPDATE_TOOLCHAIN
)

project(MyProject)

...

find_package(imgui CONFIG REQUIRED)
target_link_libraries(MyTarget PRIVATE imgui::imgui)
```

### Simple 

In this mode it's up to the CMake developer to use the find the libraries and binaries they need 
relative to `EZVCPKG_DIR`

```CMake
cmake_minimum_required(VERSION 3.10)

include(${CMAKE_SOURCE_DIR}/ezvcpkg.cmake)

project(MyProject)

ezvcpkg_fetch(
    PACKAGES glm vulkan basisu glfw3 imgui
)

...

find_library(IMGUI_LIB 
    NAMES imgui
    PATHS ${EZVCPKG_DIR}/lib)

target_include_directories(MyTarget PRIVATE ${EZVCPKG_DIR}/include)
target_link_libraries(MyTarget PRIVATE ${IMGUI_LIB})    
```

