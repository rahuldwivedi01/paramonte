####################################################################################################################################
####################################################################################################################################
##
##   ParaMonte: plain powerful parallel Monte Carlo library.
##
##   Copyright (C) 2012-present, The Computational Data Science Lab
##
##   This file is part of the ParaMonte library.
##
##   ParaMonte is free software: you can redistribute it and/or modify it
##   under the terms of the GNU Lesser General Public License as published
##   by the Free Software Foundation, version 3 of the License.
##
##   ParaMonte is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##   GNU Lesser General Public License for more details.
##
##   You should have received a copy of the GNU Lesser General Public License
##   along with the ParaMonte library. If not, see,
##
##       https://github.com/cdslaborg/paramonte/blob/master/LICENSE
##
##   ACKNOWLEDGMENT
##
##   As per the ParaMonte library license agreement terms,
##   if you use any parts of this library for any purposes,
##   we ask you to acknowledge the use of the ParaMonte library
##   in your work (education/research/industry/development/...)
##   by citing the ParaMonte library as described on this page:
##
##       https://github.com/cdslaborg/paramonte/blob/master/ACKNOWLEDGMENT.md
##
####################################################################################################################################
####################################################################################################################################

#[=======================================================================[.rst:
FindCoarray
----------

Finds compiler flags or library necessary to support Fortran 2008/2018 coarrays.

This packages primary purposes are:

* for compilers natively supporting Fortran coarrays without needing compiler options, simply indicating Coarray_FOUND  (example: Cray)
* for compilers with built-in Fortran coarray support, enable compiler option (example: Intel Fortran)
* for compilers needing a library such as OpenCoarrays, presenting library (example: GNU)


Result Variables
^^^^^^^^^^^^^^^^

``Coarray_FOUND``
  indicates coarray support found (whether built-in or library)

``Coarray_LIBRARIES``
  coarray library path
``Coarray_COMPILE_OPTIONS``
  coarray compiler options
``Coarray_EXECUTABLE``
  coarray executable e.g. ``cafrun``
``Coarray_MAX_NUMPROCS``
  maximum number of parallel processes
``Coarray_NUMPROC_FLAG``
  use for executing in parallel: ${Coarray_EXECUTABLE} ${Coarray_NUMPROC_FLAG} ${Coarray_MAX_NUMPROCS} ${CMAKE_CURRENT_BINARY_DIR}/myprogram

Cache Variables
^^^^^^^^^^^^^^^^

The following cache variables may also be set:

``Coarray_LIBRARY``
  The coarray libraries, if needed and found
#]=======================================================================]

cmake_policy(VERSION 3.3)

set(options_coarray Intel)  # flags needed
set(opencoarray_supported GNU)  # future: Flang, etc.

unset(Coarray_COMPILE_OPTIONS)
unset(Coarray_LIBRARY)
unset(Coarray_REQUIRED_VARS)

if(CMAKE_Fortran_COMPILER_ID IN_LIST options_coarray)

  if(CMAKE_Fortran_COMPILER_ID STREQUAL Intel)
    if(WIN32)
      set(Coarray_COMPILE_OPTIONS /Qcoarray:shared)
      list(APPEND Coarray_REQUIRED_VARS ${Coarray_COMPILE_OPTIONS})
    elseif(UNIX AND NOT APPLE)
      set(Coarray_COMPILE_OPTIONS -coarray=shared)
      set(Coarray_LIBRARY -coarray=shared)  # ifort requires it at build AND link
      list(APPEND Coarray_REQUIRED_VARS ${Coarray_LIBRARY})
    endif()
  endif()

elseif(CMAKE_Fortran_COMPILER_ID IN_LIST opencoarray_supported)

  find_package(OpenCoarrays)

  if(OpenCoarrays_FOUND)
    set(Coarray_LIBRARY OpenCoarrays::caf_mpi)

    set(Coarray_EXECUTABLE cafrun)

    include(ProcessorCount)
    ProcessorCount(Nproc)
    set(Coarray_MAX_NUMPROCS ${Nproc})
    set(Coarray_NUMPROC_FLAG -np)

    list(APPEND Coarray_REQUIRED_VARS ${Coarray_LIBRARY})
  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL GNU)
    set(Coarray_COMPILE_OPTIONS -fcoarray=single)
    list(APPEND Coarray_REQUIRED_VARS ${Coarray_COMPILE_OPTIONS})
  endif()

endif()


set(CMAKE_REQUIRED_FLAGS ${Coarray_COMPILE_OPTIONS})
set(CMAKE_REQUIRED_LIBRARIES ${Coarray_LIBRARY})
include(CheckFortranSourceCompiles)
check_fortran_source_compiles("real :: x[*]; end" f08coarray SRC_EXT f90)
unset(CMAKE_REQUIRED_FLAGS)
unset(CMAKE_REQUIRED_LIBRARIES)

list(APPEND Coarray_REQUIRED_VARS ${f08coarray})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Coarray
  REQUIRED_VARS Coarray_REQUIRED_VARS)

if(Coarray_FOUND)
  set(Coarray_LIBRARIES ${Coarray_LIBRARY})
endif()

mark_as_advanced(
  Coarray_LIBRARY
  Coarray_REQUIRED_VARS
)
