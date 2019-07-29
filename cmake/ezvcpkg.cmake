#
# A CMake function for installing VCPKG dependencies
#

# Arguments: 

# URL the URL of the git repository.  Defaults to nothing
# REPO The github repository organization and name, defaults to "microsoft/vcpkg"
# COMMIT The commit of the git repository to select when building.  Defaults to "f990dfaa5ba82155f95b75021453c075816fd4be"

set(EZVCPKG_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})

function(EZVCPKG_FETCH)
    set(options OPTIONAL FAST)
    set(oneValueArgs COMMIT URL REPO BASEDIR)
    set(multiValueArgs PACKAGES)
    cmake_parse_arguments(VCPKG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    if (NOT VCPKG_COMMIT)
        set(VCPKG_COMMIT "f990dfaa5ba82155f95b75021453c075816fd4be")
    endif()

    if (VCPKG_REPO AND VCPKG_URL)
        message(FATAL_ERROR "Set either a Git repository URL or a REPO org/name combination, but not both")
    endif()
    
    if((NOT VCPKG_URL) AND (NOT VCPKG_REPO))
        set(VCPKG_REPO "microsoft/vcpkg")
    endif()
    
    if(NOT VCPKG_URL) 
        set(VCPKG_URL "https://github.com/${VCPKG_REPO}.git")
    endif()

    if (NOT VCPKG_PACKAGES)
        message(FATAL_ERROR "No vcpkg packages specified")
    endif()

    if ((NOT Python3_EXECUTABLE) OR (NOT Python3_VERSION))
        find_package(Python3)
    endif()

    if ((NOT Python3_EXECUTABLE) OR (Python3_VERSION VERSION_LESS 3.5))
        message(FATAL_ERROR "Unable to locate Python interpreter 3.5 or higher")
    endif()

    # FIXME, use the command line to generate a file to parse and then 
    # explicitly assign values to the parent context after reading the
    # file
    execute_process(
        COMMAND ${Python3_EXECUTABLE} 
            ${EZVCPKG_ROOT_DIR}/scripts/ezvcpkg_main.py 
            --build-root ${CMAKE_BINARY_DIR} 
            --vcpkg-url ${VCPKG_URL}
            --vcpkg-commit ${VCPKG_COMMIT}
            --vcpkg-packages ${VCPKG_PACKAGES}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    if(NOT EXISTS "${CMAKE_BINARY_DIR}/vcpkg.cmake")
        message(FATAL_ERROR "vcpkg configuration missing.")
    endif()
endfunction()