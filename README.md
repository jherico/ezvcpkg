# EZ-VCPKG

A CMake script to automatically download and build vcpkg based projects and make them available 
to your projects

This script emphasizes reducing the overall build footprint and reduce the aggregate build time of
upstream dependencies.  It does this by building the dependencies outside of the cmake build 
directory, instead placing them in a vcpkg commit specific directory, which in turn can be placed 
inside any directory by populating the `EZVCPKG_BASEDIR` environment variable, or which defaults to 
`$ENV{TEMP}/ezvcpkg` or `$ENV{HOME}/.ezvcpkg` depending on the host platform.  

Once the dependencies are built, the disk space cost for them is fixed and the time cost is negligible
for future builds, even if you wipe out the build directory and start from scratch.  

## Examples

### Simple 

In this mode it's up to the CMake developer to use the find the libraries and binaries they need 
relative to the ${EZVCPKG_DIR}

```
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

### Toolchain

If you want to use the built-in find_package functionality with vcpkg packages that support it
you MUST call `EZVCPKG_FETCH` before the `PROJECT` directive, and you must include the `UPDATE_TOOLCHAIN` 
parameter, which will then populate the CMAKE_TOOLCHAIN_FILE value before `EZVCPKG_FETCH` returns


```
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
