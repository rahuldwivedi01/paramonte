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

module SpecDRAM_AdaptiveUpdatePeriod_mod

    use Constants_mod, only: IK
    implicit none

    character(*), parameter         :: MODULE_NAME = "@SpecDRAM_AdaptiveUpdatePeriod_mod"

    integer(IK)                     :: adaptiveUpdatePeriod ! namelist input

    type                            :: AdaptiveUpdatePeriod_type
        integer(IK)                 :: val
        integer(IK)                 :: def
        integer(IK)                 :: null
        character(:), allocatable   :: desc
    contains
        procedure, pass             :: set => setAdaptiveUpdatePeriod, checkForSanity, nullifyNameListVar
    end type AdaptiveUpdatePeriod_type

    interface AdaptiveUpdatePeriod_type
        module procedure            :: constructAdaptiveUpdatePeriod
    end interface AdaptiveUpdatePeriod_type

    private :: constructAdaptiveUpdatePeriod, setAdaptiveUpdatePeriod, checkForSanity, nullifyNameListVar

!***********************************************************************************************************************************
!***********************************************************************************************************************************

contains

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    function constructAdaptiveUpdatePeriod(ndim,methodName) result(AdaptiveUpdatePeriodObj)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: constructAdaptiveUpdatePeriod
#endif
        use Constants_mod, only: IK, NULL_IK
        use String_mod, only: num2str
        implicit none
        integer(IK), intent(in)         :: ndim
        character(*), intent(in)        :: methodName
        type(AdaptiveUpdatePeriod_type) :: AdaptiveUpdatePeriodObj
        AdaptiveUpdatePeriodObj%def     = ndim * 4_IK !+ 1_IK ! max(ndim+1_IK,100_IK)
        AdaptiveUpdatePeriodObj%null    = NULL_IK
        AdaptiveUpdatePeriodObj%desc    = &
        "Every adaptiveUpdatePeriod calls to the objective function, the parameters of the proposal distribution will be updated. &
        &The variable adaptiveUpdatePeriod must be a positive integer (>0). The smaller the value of adaptiveUpdatePeriod, &
        &the easier it will be for the " // methodName // " kernel to adapt the proposal distribution to the covariance structure &
        &of the objective function. However, this will happen at the expense of slower simulation runtime as the adaptation &
        &process can become computationally expensive, in particular, for very high dimensional objective functions (ndim>>1). &
        &The larger the value of adaptiveUpdatePeriod, the easier it will be &
        &for the " // methodName // " kernel to keep the sampling efficiency close to the requested target acceptance rate range &
        &(if specified via the input variable targetAcceptanceRate). &
        &However, too large values for adaptiveUpdatePeriod will only delay the adaptation of the proposal distribution to &
        &the global structure of the objective function that is being sampled. &
        &If adaptiveUpdatePeriod>=chainSize, then no adaptive updates to the proposal distribution will be made. &
        &The default value is 4 * ndim, where ndim is the dimension of the domain of the objective function to be sampled. &
        &In this particular " // methodName // " simulation, this corresponds to the value " // &
        num2str(AdaptiveUpdatePeriodObj%def) // "."
    end function constructAdaptiveUpdatePeriod

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    subroutine nullifyNameListVar(AdaptiveUpdatePeriodObj)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: nullifyNameListVar
#endif
        implicit none
        class(AdaptiveUpdatePeriod_type), intent(in)  :: AdaptiveUpdatePeriodObj
        adaptiveUpdatePeriod = AdaptiveUpdatePeriodObj%null
    end subroutine nullifyNameListVar

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    subroutine setAdaptiveUpdatePeriod(AdaptiveUpdatePeriodObj,adaptiveUpdatePeriod)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: setAdaptiveUpdatePeriod
#endif
        use Constants_mod, only: IK
        implicit none
        class(AdaptiveUpdatePeriod_type), intent(inout) :: AdaptiveUpdatePeriodObj
        integer(IK), intent(in)                         :: adaptiveUpdatePeriod
        AdaptiveUpdatePeriodObj%val = adaptiveUpdatePeriod
        if ( AdaptiveUpdatePeriodObj%val==AdaptiveUpdatePeriodObj%null ) AdaptiveUpdatePeriodObj%val = AdaptiveUpdatePeriodObj%def
    end subroutine setAdaptiveUpdatePeriod

!***********************************************************************************************************************************
!***********************************************************************************************************************************

    subroutine checkForSanity(AdaptiveUpdatePeriodObj,Err,methodName)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: checkForSanity
#endif
        use Constants_mod, only: IK
        use Err_mod, only: Err_type
        use String_mod, only: num2str
        implicit none
        class(AdaptiveUpdatePeriod_type), intent(in)    :: AdaptiveUpdatePeriodObj
        character(*), intent(in)                        :: methodName
        type(Err_type), intent(inout)                   :: Err
        character(*), parameter                         :: PROCEDURE_NAME = "@checkForSanity()"
        if ( AdaptiveUpdatePeriodObj%val<1_IK) then
            Err%occurred = .true.
            Err%msg =   Err%msg // &
                        MODULE_NAME // PROCEDURE_NAME // ": Error occurred. &
                        &Invalid requested value for adaptiveUpdatePeriod. &
                        &The input requested value for adaptiveUpdatePeriod (" // num2str(AdaptiveUpdatePeriodObj%val) // &
                        ") cannot be less than 1. If you are not sure of the appropriate value for adaptiveUpdatePeriod, drop it &
                        &from the input list. " // methodName // " will automatically assign an appropriate value to it.\n\n"
        end if
    end subroutine checkForSanity

!***********************************************************************************************************************************
!***********************************************************************************************************************************

end module SpecDRAM_AdaptiveUpdatePeriod_mod