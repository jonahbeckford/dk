##########################################################################
# File: dkcoder/cmake/scripts/dksdk/ninja/copy.cmake                      #
#                                                                        #
# Copyright 2023 Diskuv, Inc.                                            #
#                                                                        #
# Licensed under the Open Software License version 3.0                   #
# (the "License"); you may not use this file except in compliance        #
# with the License. You may obtain a copy of the License at              #
#                                                                        #
#     https://opensource.org/license/osl-3-0-php/                        #
#                                                                        #
##########################################################################

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} [[usage: ./dk dksdk.ninja.copy

Creates a copy of the CMake installation into .ci/ninja/.

Typically used when mounting Docker containers, so that on a restart of
the Docker container the CMake installation is still present (assuming
the local project directory was mounted).

Directory Structure
===================

.ci/ninja/bin
└── ninja

On Windows the file will be named ninja.exe in the .ci/ninja/bin/ directory.

Arguments
=========

HELP
  Print this help message.
]])
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # Recognize one of the forms:
    # A: ninja-1.11.1-windows-x86_64/bin/ninja -> ninja-1.11.1-windows-x86_64
    # B: /Users/jonah/.local/share/dkcoder/code.1/dkexe/ninja/aa4a5b61-8c9c-42cd-9031-399a4abb09da/ninja
    # C: /usr/bin/ninja

    cmake_path(GET CMAKE_MAKE_PROGRAM PARENT_PATH d1)
    cmake_path(GET CMAKE_MAKE_PROGRAM FILENAME CMAKE_MAKE_PROGRAMNAME)
    cmake_path(GET d1 PARENT_PATH d2)
    cmake_path(GET d1 FILENAME f1)
    cmake_path(GET d2 FILENAME f2)

    if(f1 STREQUAL bin AND (f2 MATCHES "^ninja-" OR f2 STREQUAL ninja))
      set(ninja_bindir "${d1}")
      file(GLOB ninja_binentries
        LIST_DIRECTORIES true
        RELATIVE ${ninja_bindir}
        ${ninja_bindir}/*)
    elseif(CMAKE_MAKE_PROGRAMNAME STREQUAL ninja OR CMAKE_MAKE_PROGRAMNAME STREQUAL ninja.exe)
      set(ninja_binentries "${CMAKE_MAKE_PROGRAM}")
    else()
      message(FATAL_ERROR "This script does not support Ninja installations that are not embedded in a standalone directory named `ninja-{VERSION}` or `ninja`. Details: CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}")
    endif()

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/ninja")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/ninja/.gitignore"
        ONLY_IF_DIFFERENT)

    # copy
    foreach(entry IN LISTS ninja_binentries)
        file(INSTALL ${ninja_bindir}/${entry}
            DESTINATION ${CMAKE_SOURCE_DIR}/.ci/ninja/bin
            USE_SOURCE_PERMISSIONS)
    endforeach()
endfunction()
