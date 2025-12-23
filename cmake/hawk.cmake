# Copyright (c) 2023-present The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

enable_language(C)

function(add_hawk subdir)
    message("")
    message("Configuring hawk subtree...")

    # Determine which implementation to build (AVX2 or reference)
    option(HAWK_USE_AVX2 "Use AVX2 optimized implementation of hawk." ON)

    if(HAWK_USE_AVX2)
        set(HAWK_IMPL_DIR "Optimized_Implementation/avx2")
        set(HAWK_BUILD_TARGET "avx2")
        message("  Using AVX2 optimized implementation")
    else()
        set(HAWK_IMPL_DIR "Reference_Implementation")
        set(HAWK_BUILD_TARGET "ref")
        message("  Using reference implementation")
    endif()

    set(HAWK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${subdir})
    set(HAWK_IMPL_PATH ${HAWK_SOURCE_DIR}/${HAWK_IMPL_DIR})

    # Run build.py to generate implementation-specific sources
    execute_process(
            COMMAND python3 ${HAWK_SOURCE_DIR}/build.py ${HAWK_BUILD_TARGET}
            WORKING_DIRECTORY ${HAWK_SOURCE_DIR}
            RESULT_VARIABLE BUILD_PY_RESULT
    )

    if(NOT BUILD_PY_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to run hawk build.py script")
    endif()

    # Collect all C source files from the generated implementation directory
    file(GLOB HAWK_SOURCES "${HAWK_IMPL_PATH}/*.c")

    if(NOT HAWK_SOURCES)
        message(FATAL_ERROR "No hawk source files found in ${HAWK_IMPL_PATH}")
    endif()

    # Create the hawk library target
    add_library(hawk STATIC ${HAWK_SOURCES})

    # Set include directories
    target_include_directories(hawk
            PUBLIC
            ${HAWK_SOURCE_DIR}/src
            PRIVATE
            ${HAWK_IMPL_PATH}
    )

    # Apply compiler flags similar to secp256k1
    include(GetTargetInterface)
    get_target_interface(HAWK_COMPILE_OPTIONS "" sanitize_interface COMPILE_OPTIONS)
    if(HAWK_COMPILE_OPTIONS)
        target_compile_options(hawk PRIVATE ${HAWK_COMPILE_OPTIONS})
    endif()

    get_target_interface(HAWK_LINK_OPTIONS "" sanitize_interface LINK_OPTIONS)
    if(HAWK_LINK_OPTIONS)
        target_link_options(hawk PRIVATE ${HAWK_LINK_OPTIONS})
    endif()

    # Set properties
    set_target_properties(hawk PROPERTIES
            EXCLUDE_FROM_ALL TRUE
            C_STANDARD 99
            C_EXTENSIONS OFF
    )

    message("  Hawk library configured with ${CMAKE_CURRENT_LIST_LENGTH} source files")

endfunction()