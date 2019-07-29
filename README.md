# EZ-VCPKG

A CMake/Python tool to automatically download and build vcpkg based projects

Example usage:

```
cmake_minimum_required(VERSION 3.10)

include(${CMAKE_SOURCE_DIR}/cmake/VcpkgFetch.cmake)
vcpkg_fetch(
    PACKAGES glm vulkan basisu glfw3
)
include(${CMAKE_BINARY_DIR}/vcpkg.cmake)

project(MyProject)
```
