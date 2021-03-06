!***********************************************************************************************************************************
!***********************************************************************************************************************************
!
!   ParaMonte: plain powerful parallel Monte Carlo library.
!
!   Copyright (C) 2012-present, The Computational Data Science Lab
!
!   This file is part of the ParaMonte library.
!
!   ParaMonte is free software: you can redistribute it and/or modify it
!   under the terms of the GNU Lesser General Public License as published
!   by the Free Software Foundation, version 3 of the License.
!
!   ParaMonte is distributed in the hope that it will be useful,
!   but WITHOUT ANY WARRANTY; without even the implied warranty of
!   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!   GNU Lesser General Public License for more details.
!
!   You should have received a copy of the GNU Lesser General Public License
!   along with the ParaMonte library. If not, see,
!
!       https://github.com/cdslaborg/paramonte/blob/master/LICENSE
!
!   ACKNOWLEDGMENT
!
!   As per the ParaMonte library license agreement terms,
!   if you use any parts of this library for any purposes,
!   we ask you to acknowledge the use of the ParaMonte library
!   in your work (education/research/industry/development/...)
!   by citing the ParaMonte library as described on this page:
!
!       https://github.com/cdslaborg/paramonte/blob/master/ACKNOWLEDGMENT.md
!
!***********************************************************************************************************************************
!***********************************************************************************************************************************

module Decoration_mod

    use Constants_mod, only: IK
    use JaggedArray_mod, only: CharVec_type

    implicit none

    character(*), parameter :: MODULE_NAME = "@Decoration_mod"

    integer(IK) , parameter :: DECORATION_WIDTH = 132
    integer(IK) , parameter :: DECORATION_THICKNESS_HORZ = 4
    integer(IK) , parameter :: DECORATION_THICKNESS_VERT = 1
    character(*), parameter :: STAR = "*"
    character(*), parameter :: TAB = "    "
    character(*), parameter :: INDENT = TAB // TAB

    character(*), parameter :: GENERIC_OUTPUT_FORMAT = "(*(g0,:,' '))"
    character(*), parameter :: GENERIC_TABBED_FORMAT = "('" // TAB // TAB // "',*(g0,:,' '))"

    type :: decoration_type
        character(:), allocatable       :: tab
        character(:), allocatable       :: text
        character(:), allocatable       :: symbol
        type(CharVec_type), allocatable :: List(:)
    contains
        procedure, nopass :: write, writeDecoratedText, writeDecoratedList, wrapText
        !generic           :: write => writeDecoratedText, writeDecoratedList
    end type decoration_type

    interface decoration_type
        module procedure :: constructDecoration
    end interface decoration_type

    type :: wrapper_type
        type(CharVec_type), allocatable :: Line(:)
    contains
        procedure, nopass :: wrap => wrapText
    end type wrapper_type

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    module function constructDecoration(tabStr,symbol,text,List) result(Decoration)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: constructDecoration
#endif
        use JaggedArray_mod, only: CharVec_type
        implicit none
        character(*), intent(in), optional          :: tabStr, symbol, text
        type(CharVec_type), intent(in), optional    :: List
        type(Decoration_type)                       :: Decoration
    end function constructDecoration
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    module subroutine writeDecoratedText(text,symbol,width,thicknessHorz,thicknessVert,marginTop,marginBot,outputUnit,newLine)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: writeDecoratedText
#endif
        use, intrinsic :: iso_fortran_env, only: output_unit
        use Constants_mod, only: IK
        implicit none
        character(*), intent(in)            :: text
        character(*), intent(in), optional  :: symbol,newLine
        integer(IK) , intent(in), optional  :: width,thicknessHorz,thicknessVert,marginTop,marginBot
        integer(IK) , intent(in), optional  :: outputUnit
    end subroutine writeDecoratedText
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    module subroutine writeDecoratedList(List,symbol,width,thicknessHorz,thicknessVert,marginTop,marginBot,outputUnit)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: writeDecoratedList
#endif
        use, intrinsic :: iso_fortran_env, only: output_unit
        use Constants_mod, only: IK
        implicit none
        type(CharVec_type), allocatable , intent(in)    :: List(:)
        character(*)        , intent(in), optional      :: symbol
        integer(IK)         , intent(in), optional      :: width,thicknessHorz,thicknessVert,marginTop,marginBot
        integer(IK)         , intent(in), optional      :: outputUnit
    end subroutine writeDecoratedList
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    pure module function drawLine(symbol,width) result(line)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: drawLine
#endif
        use Constants_mod, only: IK
        implicit none
        character(*), intent(in), optional  :: symbol
        integer(IK), intent(in) , optional  :: width
        character(:), allocatable           :: line
    end function drawLine
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    pure module function sandwich(text,symbol,width,thicknessHorz) result(sandwichedText)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: sandwich
#endif
        use Constants_mod, only: IK
        implicit none
        character(*), intent(in), optional  :: text, symbol
        integer(IK), intent(in) , optional  :: width,thicknessHorz
        character(:), allocatable           :: sandwichedText
    end function sandwich
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    module subroutine write ( outputUnit    &
                            , marginTop     &
                            , marginBot     &
                            , count         &
                            , string        &
#if defined MEXPRINT_ENABLED
                            , advance       &
#endif
                            )
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: write
#endif
        use, intrinsic :: iso_fortran_env, only: output_unit
        use Constants_mod, only: IK
        implicit none
        integer(IK) , intent(in), optional  :: outputUnit
        integer(IK) , intent(in), optional  :: marginTop, marginBot, count
        character(*), intent(in), optional  :: string
#if defined MEXPRINT_ENABLED
        logical     , intent(in), optional  :: advance
#endif
    end subroutine write
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    module function getListOfLines(string,delimiter) result(ListOfLines)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: getListOfLines
#endif
        implicit none
        character(len=*)  , intent(in)              :: string
        character(len=*)  , intent(in), optional    :: delimiter
        type(CharVec_type), allocatable             :: ListOfLines(:)
    end function getListOfLines
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    interface
    module function wrapText(string,width,split, pad) result(ListOfLines)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: wrapText
#endif
        use Constants_mod, only: IK
        implicit none
        character(*), intent(in)            :: string
        integer(IK) , intent(in)            :: width
        character(*), intent(in), optional  :: split, pad
        type(CharVec_type), allocatable     :: ListOfLines(:)
    end function wrapText
    end interface

!***********************************************************************************************************************************
!***********************************************************************************************************************************

contains

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    pure function getGenericFormat(width,precision,delim,prefix) result(formatStr)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: getGenericFormat
#endif
        ! generates IO format strings, primarily for use in the output report files of ParaMonte
        use Constants_mod, only: IK
        use String_mod, only: num2str
        implicit none
        integer(IK) , intent(in), optional  :: width
        integer(IK) , intent(in), optional  :: precision
        character(*), intent(in), optional  :: delim
        character(*), intent(in), optional  :: prefix
        character(:), allocatable           :: widthStr
        character(:), allocatable           :: formatStr
        character(:), allocatable           :: precisionStr
        character(:), allocatable           :: delimDefault

        widthStr = "0"; if (present(width)) widthStr = num2str(width)
        precisionStr = ".0"; if (present(precision)) precisionStr = "."//num2str(precision)
        delimDefault = ""; if (present(delim)) delimDefault = ",:,'"//delim//"'"
        formatStr = "*(g"//widthStr//precisionStr//delimDefault//"))"
        if (present(prefix)) then
            formatStr = "('" // prefix // "'," // formatStr
        else
            formatStr = "(" // formatStr
        end if

    end function getGenericFormat

!***********************************************************************************************************************************
!***********************************************************************************************************************************

end module Decoration_mod
