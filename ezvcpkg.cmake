#
# A CMake function for installing VCPKG dependencies
#

# Arguments: 

# REPO The github repository organization and name, defaults to "microsoft/vcpkg"
# URL the URL of the git repository.  Defaults to "https://github.com/${REPO}.git"
# COMMIT The commit ID of the git repository to select when building.  Defaults to "f990dfaa5ba82155f95b75021453c075816fd4be"
# UPDATE_TOOLCHAIN if this flag is set, the function will populate the CMAKE_TOOLCHAIN_FILE variable.  Note that this will 
#   only have an effect if done prior to the `project()` directive of the top level CMake project.  
# BASEDIR The directory in which CMake will checkout and build vcpkg instances.  Each vcpkg commit will have it's own 
#   subdirectory.  If this is not specified, it will default to the location specified by the EZVCPKG_BASEDIR environment 
#   variable.  If that doesn't exist, it will default to ~/.ezvcpkg on OSX, and %TEMP%/ezvcpkg everywhere else
# CLEAN a single argument parameter that tells the script to clean up out of date EZVCPKG folders.  The value should be the 
#   number of days after which a folder should be removed if it hasn't been touched. (Not currently implemented)
# PACKAGES a multi-value argument specifying the packages to install
#
# Output:
# If successful the function will populate EZVCPKG_DIR with the location of the installed triplet, for instance 
# D:\ezvcpkg\f990dfaa5ba82155f95b75021453c075816fd4be\installed\x64-windows

macro(EZVCPKG_CALCULATE_PATHS)
    if (NOT VCPKG_BASEDIR)
        if (DEFINED ENV{EZVCPKG_BASEDIR})
            set(VCPKG_BASEDIR $ENV{EZVCPKG_BASEDIR})
        else() 
            if(APPLE)
                # OSX wipes binaries from the temp directory over time, leaving the remaining files
                # This causes the vcpkg folder to end up in an unusable state, so we default to the 
                # home directory instead
                set(VCPKG_BASEDIR "$ENV{HOME}/.ezvcpkg")
            else()
                set(VCPKG_BASEDIR "$ENV{TEMP}/ezvcpkg")
            endif()
            # We want people to specify a base directory, either through the calling EZVCPKG_FETCH 
            # function or through an environment variable.  
            message(WARNING "EZVCPKG_BASEDIR envrionment variable not found and basedir not set, using default ${VCPKG_BASEDIR}")
        endif()
    endif()
    file(TO_CMAKE_PATH "${VCPKG_BASEDIR}/${VCPKG_COMMIT}" VCPKG_DIR)
    file(TO_CMAKE_PATH "${VCPKG_BASEDIR}/${VCPKG_COMMIT}.lock" VCPKG_LOCK)
    if (WIN32)
        file(TO_CMAKE_PATH "${VCPKG_DIR}/vcpkg.exe" VCPKG_EXE)
        file(TO_CMAKE_PATH "${VCPKG_DIR}/bootstrap-vcpkg.bat" VCPKG_BOOTSTRAP)
    else()
        file(TO_CMAKE_PATH "${VCPKG_DIR}/vcpkg" VCPKG_EXE)
        file(TO_CMAKE_PATH "${VCPKG_DIR}/bootstrap-vcpkg.sh" VCPKG_BOOTSTRAP)
    endif()

    # The tag file exists purely to be a touch target every time the ezvcpkg macro is called
    # making it easy to find out of date ezvcpkg folder.  
    file(TO_CMAKE_PATH "${VCPKG_DIR}/.tag" VCPKG_TAG)

    # The whole host-triplet / triplet setup is to support cross compiling, specifically for things 
    # like android.  The idea is that some things you might need from vcpkg to act as tools to execute 
    # on the host system, like glslang and spirv-cross, while other things you need as binaries
    # compatible with the target system.  However, this isn't fully fleshed out, so don't try to use 
    # it yet
    if (WIN32)
        set(VCPKG_HOST_TRIPLET "x64-windows")
    elseif(APPLE)
        set(VCPKG_HOST_TRIPLET "x64-osx")
    else() 
        set(VCPKG_HOST_TRIPLET "x64-linux")
    endif()

    if (ANDROID)
        set(VCPKG_TRIPLET "arm64-android")
    else()
        set(VCPKG_TRIPLET ${VCPKG_HOST_TRIPLET})
    endif()

    file(TO_CMAKE_PATH ${VCPKG_DIR}/installed/${VCPKG_TRIPLET} VCPKG_INSTALLED_DIR)
    file(TO_CMAKE_PATH ${VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake VCPKG_CMAKE_TOOLCHAIN)
endmacro()

macro(EZVCPKG_BOOTSTRAP)
    if (NOT EXISTS ${VCPKG_EXE})
        find_package(Git)
        if (NOT Git_FOUND)
            message(FATAL_ERROR "Git not found, can't bootstrap vcpkg")
        endif()
        execute_process(
            COMMAND ${GIT_EXECUTABLE} "clone" ${VCPKG_URL} ${VCPKG_DIR})
        execute_process(
            COMMAND ${GIT_EXECUTABLE} "checkout" ${VCPKG_COMMIT}
            WORKING_DIRECTORY ${VCPKG_DIR})
        execute_process(
            COMMAND ${VCPKG_BOOTSTRAP}
            WORKING_DIRECTORY ${VCPKG_DIR})
    endif()
endmacro()

macro(EZVCPKG_BUILD)
    execute_process(
        COMMAND ${VCPKG_EXE} --vcpkg-root ${VCPKG_DIR} install --triplet ${VCPKG_TRIPLET} ${VCPKG_PACKAGES}
        WORKING_DIRECTORY ${VCPKG_DIR}
    )

    file(TO_CMAKE_PATH ${VCPKG_DIR}/buildtrees VCPKG_BUILDTREES)
    if (EXISTS ${VCPKG_BUILDTREES})
        file(REMOVE_RECURSE "${VCPKG_DIR}/buildtrees")
    endif()
endmacro()

macro(EZVCPKG_CLEAN)
    message(STATUS "Cleaning unused ezvcpkg dirs after ${VCPKG_CLEAN} days")
    message(WARNING "Cleaning not implemented")
endmacro()

macro(EZVCPKG_CHECK_ARGS)
    # Default to a recent vcpkg commit
    if (NOT VCPKG_COMMIT)
        set(VCPKG_COMMIT "f990dfaa5ba82155f95b75021453c075816fd4be")
    endif()

    if (VCPKG_REPO AND VCPKG_URL)
        message(FATAL_ERROR "Set either a Git repository URL or a REPO org/name combination, but not both")
    endif()

    # Default to the microsoft root vcpkg repository
    if((NOT VCPKG_URL) AND (NOT VCPKG_REPO))
        set(VCPKG_REPO "microsoft/vcpkg")
    endif()

    # Default to github
    if(NOT VCPKG_URL) 
        set(VCPKG_URL "https://github.com/${VCPKG_REPO}.git")
    endif()

    if (NOT VCPKG_PACKAGES)
        message(FATAL_ERROR "No vcpkg packages specified")
    endif()
endmacro()

function(EZVCPKG_FETCH)
    set(options UPDATE_TOOLCHAIN)
    set(oneValueArgs COMMIT URL REPO BASEDIR OUTPUT CLEAN)
    set(multiValueArgs PACKAGES)
    cmake_parse_arguments(VCPKG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Validate arguments
    EZVCPKG_CHECK_ARGS()

    # Figure out the paths for everything
    EZVCPKG_CALCULATE_PATHS()

    # We can't assume build systems will be well behaved if we attempt two different concurrent builds of the same 
    # target, so we need to have some locking here to ensure that for a given vcpkg location, only one instance
    # of vcpkg runs at a given time. 
        
    # This is critical because, for instance, when Android Studio does a native code build it will concurrently execute
    # cmake for debug and release versions of the build, in different directories, and therefore concurrently try to 
    # bootstrap and run vcpkg, which will almost certainly corrupt your build directories
    file(LOCK ${VCPKG_LOCK})

    EZVCPKG_BOOTSTRAP()

    # Touch the tag file so that this directory is marked as recent, and therefore not cleanable
    file(TOUCH ${VCPKG_TAG})

    # While still holding the global lock, clean up old build directories
    if (VCPKG_CLEAN)
        EZVCPKG_CLEAN()
    endif()

    # Build packages
    EZVCPKG_BUILD()

    file(LOCK ${VCPKG_LOCK} RELEASE)
    file(REMOVE ${VCPKG_LOCK})

    set(EZVCPKG_DIR "${VCPKG_INSTALLED_DIR}" PARENT_SCOPE)
    if (VCPKG_UPDATE_TOOLCHAIN)
        set(CMAKE_TOOLCHAIN_FILE ${VCPKG_CMAKE_TOOLCHAIN} PARENT_SCOPE)
    endif()
endfunction()