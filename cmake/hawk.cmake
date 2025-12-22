# Copyright (c) 2023-present The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

enable_language(C)

function(add_hawk subdir)
    message("")
    message("Configuring hawk subtree...")

    include(ExternalProject)

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
    set(HAWK_BUILD_DIR ${HAWK_SOURCE_DIR}/${HAWK_IMPL_DIR}/build)
    set(HAWK_LIB_FILE ${HAWK_BUILD_DIR}/libhawk.a)

    # Prepare compiler flags similar to secp256k1
    include(GetTargetInterface)
    get_target_interface(HAWK_CFLAGS "" sanitize_interface COMPILE_OPTIONS)
    string(STRIP "${HAWK_CFLAGS} ${APPEND_CPPFLAGS}" HAWK_CFLAGS)
    string(STRIP "${HAWK_CFLAGS} ${APPEND_CFLAGS}" HAWK_CFLAGS)

    get_target_interface(HAWK_LDFLAGS "" sanitize_interface LINK_OPTIONS)
    string(STRIP "${HAWK_LDFLAGS} ${APPEND_LDFLAGS}" HAWK_LDFLAGS)

    # Build hawk using its build script and Makefile
    ExternalProject_Add(hawk_external
            SOURCE_DIR ${HAWK_SOURCE_DIR}
            BUILD_IN_SOURCE 1
            CONFIGURE_COMMAND ""
            BUILD_COMMAND python3 ${HAWK_SOURCE_DIR}/build.py ${HAWK_BUILD_TARGET}
            COMMAND $(MAKE) -C ${HAWK_SOURCE_DIR}/${HAWK_IMPL_DIR} CC=${CMAKE_C_COMPILER} CFLAGS=${HAWK_CFLAGS}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${HAWK_BUILD_DIR}
            COMMAND ${CMAKE_AR} rcs ${HAWK_LIB_FILE} ${HAWK_SOURCE_DIR}/${HAWK_IMPL_DIR}/build/*.o
            INSTALL_COMMAND ""
            BUILD_BYPRODUCTS ${HAWK_LIB_FILE}
    )

    # Create imported target
    add_library(hawk STATIC IMPORTED GLOBAL)
    add_dependencies(hawk hawk_external)

    # Set include directories and library location
    # Headers are in the original src directory
    set_target_properties(hawk PROPERTIES
            IMPORTED_LOCATION ${HAWK_LIB_FILE}
            INTERFACE_INCLUDE_DIRECTORIES ${HAWK_SOURCE_DIR}/src
            EXCLUDE_FROM_ALL TRUE
    )

endfunction()