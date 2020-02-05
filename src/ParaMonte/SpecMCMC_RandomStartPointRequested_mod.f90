!**********************************************************************************************************************************
!**********************************************************************************************************************************
!
!  ParaMonte: plain powerful parallel Monte Carlo library.
!
!  Copyright (C) 2012-present, The Computational Data Science Lab
!
!  This file is part of ParaMonte library. 
!
!  ParaMonte is free software: you can redistribute it and/or modify
!  it under the terms of the GNU Lesser General Public License as published by
!  the Free Software Foundation, version 3 of the License.
!
!  ParaMonte is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU Lesser General Public License for more details.
!
!  You should have received a copy of the GNU Lesser General Public License
!  along with ParaMonte.  If not, see <https://www.gnu.org/licenses/>.
!
!**********************************************************************************************************************************
!**********************************************************************************************************************************

module SpecMCMC_RandomStartPointRequested_mod

    implicit none

    character(*), parameter         :: MODULE_NAME = "@SpecMCMC_RandomStartPointRequested_mod"

    logical                         :: randomStartPointRequested ! namelist input

    type                            :: RandomStartPointRequested_type
        logical                     :: val
        logical                     :: def
        character(:), allocatable   :: desc
    contains
        procedure, pass             :: set => setRandomStartPointRequested, nullifyNameListVar
    end type RandomStartPointRequested_type

    interface RandomStartPointRequested_type
        module procedure            :: constructRandomStartPointRequested
    end interface RandomStartPointRequested_type

    private :: constructRandomStartPointRequested, setRandomStartPointRequested, nullifyNameListVar

!***********************************************************************************************************************************
!***********************************************************************************************************************************

contains

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    function constructRandomStartPointRequested(methodName) result(RandomStartPointRequestedObj)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: constructRandomStartPointRequested
#endif
        use String_mod, only: log2str
        implicit none
        character(*), intent(in)                :: methodName
        type(RandomStartPointRequested_type)    :: RandomStartPointRequestedObj
        RandomStartPointRequestedObj%def = .false.
        RandomStartPointRequestedObj%desc = &
        "If randomStartPointRequested=TRUE (or true or t, all case-insensitive), then the variable startPointVec will be &
        &initialized randomly for each MCMC chain that is to be generated by " // methodName // ". The random values will be &
        &drawn from the specified or the default domain of startPointVec, given by RandomStartPointDomain variable. Note that the &
        &value of startPointVec, if provided, has precedence over random initialization. In other words, for every element of &
        &startPointVec that is not provided as input only that element will initialized randomly if randomStartPointRequested=TRUE. &
        &Also, note that even if startPointVec is randomly initialized, its random value will be deterministic between different &
        &independent runs of " // methodName // " if the input variable randomSeed is provided by the user. &
        &The default value is " // log2str(RandomStartPointRequestedObj%def) // "."
    end function constructRandomStartPointRequested

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    subroutine nullifyNameListVar(RandomStartPointRequestedObj)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: nullifyNameListVar
#endif
        implicit none
        class(RandomStartPointRequested_type), intent(in)    :: RandomStartPointRequestedObj
        randomStartPointRequested = RandomStartPointRequestedObj%def
    end subroutine nullifyNameListVar

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    subroutine setRandomStartPointRequested(RandomStartPointRequestedObj,randomStartPointRequested)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: setRandomStartPointRequested
#endif
        implicit none
        class(RandomStartPointRequested_type), intent(inout)    :: RandomStartPointRequestedObj
        logical, intent(in)                                     :: randomStartPointRequested
        RandomStartPointRequestedObj%val = randomStartPointRequested
    end subroutine setRandomStartPointRequested

!***********************************************************************************************************************************
!***********************************************************************************************************************************

end module SpecMCMC_RandomStartPointRequested_mod