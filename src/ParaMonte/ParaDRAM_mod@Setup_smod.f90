!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

submodule (ParaDRAM_mod) Setup_smod

    !use Constants_mod, only: IK, RK ! gfortran 9.3 compile crashes with this line
    implicit none

    character(*), parameter :: SUBMODULE_NAME = MODULE_NAME // "@Setup_smod"

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

contains

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    module subroutine runSampler( self                                  &
                                , ndim                                  &
                                , getLogFunc                            &
                                , inputFile                             &
                                ! ParaMonte variables
                                , sampleSize                            &
                                , randomSeed                            &
                                , description                           &
                                , outputFileName                        &
                                , outputDelimiter                       &
                                , chainFileFormat                       &
                                , variableNameList                      &
                                , restartFileFormat                     &
                                , outputColumnWidth                     &
                                , outputRealPrecision                   &
                                , silentModeRequested                   &
                                , domainLowerLimitVec                   &
                                , domainUpperLimitVec                   &
                                , parallelizationModel                  &
                                , progressReportPeriod                  &
                                , targetAcceptanceRate                  &
                                , mpiFinalizeRequested                  &
                                , maxNumDomainCheckToWarn               &
                                , maxNumDomainCheckToStop               &
                                ! ParaMCMC variables
                                , chainSize                             &
                                , startPointVec                         &
                                , sampleRefinementCount                 &
                                , sampleRefinementMethod                &
                                , randomStartPointRequested             &
                                , randomStartPointDomainLowerLimitVec   &
                                , randomStartPointDomainUpperLimitVec   &
                                ! ParaDRAM variables
                                , scaleFactor                           &
                                , proposalModel                         &
                                , proposalStartStdVec                   &
                                , proposalStartCorMat                   &
                                , proposalStartCovMat                   &
                                , adaptiveUpdateCount                   &
                                , adaptiveUpdatePeriod                  &
                                , greedyAdaptationCount                 &
                                , delayedRejectionCount                 &
                                , burninAdaptationMeasure               &
                                , delayedRejectionScaleFactorVec        &
                                ) !  result(self)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !!DEC$ ATTRIBUTES DLLEXPORT :: ParaDRAM_type
        !DEC$ ATTRIBUTES DLLEXPORT :: runSampler
#endif
        use, intrinsic :: iso_fortran_env, only: output_unit, stat_stopped_image
        use ParaDRAMProposalSymmetric_mod, only: ProposalSymmetric_type
        use ParaMonteLogFunc_mod, only: getLogFunc_proc
        use Decoration_mod, only: GENERIC_OUTPUT_FORMAT
        use Decoration_mod, only: GENERIC_TABBED_FORMAT
        use Decoration_mod, only: getGenericFormat
        use Decoration_mod, only: INDENT
        use Statistics_mod, only: getUpperCorMatFromUpperCovMat
        use Statistics_mod, only: getWeiSamCovUppMeanTrans
        use Statistics_mod, only: getQuantile
        use ParaMonte_mod, only: QPROB
        use Constants_mod, only: IK, RK, NLC, PMSM, UNDEFINED
        use DateTime_mod, only: getNiceDateTime
        use String_mod, only: num2str

        implicit none

        ! self
        class(ParaDRAM_type), intent(inout) :: self

        ! mandatory variables
        integer(IK) , intent(in)            :: ndim
        procedure(getLogFunc_proc)          :: getLogFunc

        character(*), intent(in), optional  :: inputFile
        
        ! ParaMonte variables
        integer(IK) , intent(in), optional  :: sampleSize
        integer(IK) , intent(in), optional  :: randomSeed
        character(*), intent(in), optional  :: description
        character(*), intent(in), optional  :: outputFileName
        character(*), intent(in), optional  :: outputDelimiter
        character(*), intent(in), optional  :: chainFileFormat
        character(*), intent(in), optional  :: variableNameList(ndim)
        character(*), intent(in), optional  :: restartFileFormat
        integer(IK) , intent(in), optional  :: outputColumnWidth
        integer(IK) , intent(in), optional  :: outputRealPrecision
        real(RK)    , intent(in), optional  :: domainLowerLimitVec(ndim)
        real(RK)    , intent(in), optional  :: domainUpperLimitVec(ndim)
        logical     , intent(in), optional  :: silentModeRequested
        character(*), intent(in), optional  :: parallelizationModel
        integer(IK) , intent(in), optional  :: progressReportPeriod
        real(RK)    , intent(in), optional  :: targetAcceptanceRate(2)
        logical     , intent(in), optional  :: mpiFinalizeRequested
        integer(IK) , intent(in), optional  :: maxNumDomainCheckToWarn
        integer(IK) , intent(in), optional  :: maxNumDomainCheckToStop

        ! ParaMCMC variables
        integer(IK) , intent(in), optional  :: chainSize
        real(RK)    , intent(in), optional  :: startPointVec(ndim)
        integer(IK) , intent(in), optional  :: sampleRefinementCount
        character(*), intent(in), optional  :: sampleRefinementMethod
        logical     , intent(in), optional  :: randomStartPointRequested
        real(RK)    , intent(in), optional  :: randomStartPointDomainLowerLimitVec(ndim)
        real(RK)    , intent(in), optional  :: randomStartPointDomainUpperLimitVec(ndim)

        ! ParaDRAM variables
        character(*), intent(in), optional  :: scaleFactor
        character(*), intent(in), optional  :: proposalModel
        real(RK)    , intent(in), optional  :: proposalStartStdVec(ndim)
        real(RK)    , intent(in), optional  :: proposalStartCorMat(ndim,ndim)
        real(RK)    , intent(in), optional  :: proposalStartCovMat(ndim,ndim)
        integer(IK) , intent(in), optional  :: adaptiveUpdateCount
        integer(IK) , intent(in), optional  :: adaptiveUpdatePeriod
        integer(IK) , intent(in), optional  :: greedyAdaptationCount
        integer(IK) , intent(in), optional  :: delayedRejectionCount
        real(RK)    , intent(in), optional  :: burninAdaptationMeasure
        real(RK)    , intent(in), optional  :: delayedRejectionScaleFactorVec(:)

        character(*), parameter             :: PROCEDURE_NAME = SUBMODULE_NAME // "@runSampler()"

       !type(ProposalSymmetric_type), target   :: ProposalSymmetric
        integer(IK)                         :: i, iq
        character(:), allocatable           :: msg, formatStr, formatStrInt, formatStrReal, formatAllReal
        real(RK)                            :: mcmcSamplingEfficiency

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! Initialize SpecBase variables, then check existence of inputFile and open it and return the unit file, if it exists
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        call self%setupParaMonte  ( nd = ndim             &
                                , name = PMSM%ParaDRAM    &
                               !, date = "May 23 2018"    &
                               !, version = "1.0.0"       &
                                , inputFile = inputFile   &
                                )
        if (self%Err%occurred) return

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! Initialize ParaMCMC variables
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        call self%setupParaMCMC()

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! Initialize ParaDRAM variables
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        self%SpecDRAM = SpecDRAM_type( self%nd%val, self%name ) ! , self%SpecMCMC%ChainSize%def )

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! read variables from input file if it exists
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        call self%getSpecFromInputFile(ndim)
        if (self%Err%occurred) then
            self%Err%msg = PROCEDURE_NAME // self%Err%msg
            call self%abort( Err = self%Err, prefix = self%brand, newline = "\n", outputUnit = self%LogFile%unit )
            return
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! read variables from argument list if needed
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (self%Image%isFirst) call self%setWarnAboutProcArgHasPriority()
        if (self%procArgNeeded) then
            call self%SpecBase%setFromInputArgs ( Err                                 = self%Err                                &
                                                , sampleSize                            = sampleSize                            &
                                                , randomSeed                            = randomSeed                            &
                                                , description                           = description                           &
                                                , outputFileName                        = outputFileName                        &
                                                , outputDelimiter                       = outputDelimiter                       &
                                                , chainFileFormat                       = chainFileFormat                       &
                                                , variableNameList                      = variableNameList                      &
                                                , restartFileFormat                     = restartFileFormat                     &
                                                , outputColumnWidth                     = outputColumnWidth                     &
                                                , outputRealPrecision                   = outputRealPrecision                   &
                                                , silentModeRequested                   = silentModeRequested                   &
                                                , domainLowerLimitVec                   = domainLowerLimitVec                   &
                                                , domainUpperLimitVec                   = domainUpperLimitVec                   &
                                                , parallelizationModel                  = parallelizationModel                  &
                                                , progressReportPeriod                  = progressReportPeriod                  &
                                                , targetAcceptanceRate                  = targetAcceptanceRate                  &
                                                , mpiFinalizeRequested                  = mpiFinalizeRequested                  &
                                                , maxNumDomainCheckToWarn               = maxNumDomainCheckToWarn               &
                                                , maxNumDomainCheckToStop               = maxNumDomainCheckToStop               &
                                                )
            call self%SpecMCMC%setFromInputArgs ( domainLowerLimitVec                   = self%SpecBase%DomainLowerLimitVec%Val &
                                                , domainUpperLimitVec                   = self%SpecBase%DomainUpperLimitVec%Val &
                                                , chainSize                             = chainSize                             &
                                                , scaleFactor                           = scaleFactor                           &
                                                , startPointVec                         = startPointVec                         &
                                                , proposalModel                         = proposalModel                         &
                                                , proposalStartStdVec                   = proposalStartStdVec                   &
                                                , proposalStartCorMat                   = proposalStartCorMat                   &
                                                , proposalStartCovMat                   = proposalStartCovMat                   &
                                                , sampleRefinementCount                 = sampleRefinementCount                 &
                                                , sampleRefinementMethod                = sampleRefinementMethod                &
                                                , randomStartPointRequested             = randomStartPointRequested             &
                                                , randomStartPointDomainLowerLimitVec   = randomStartPointDomainLowerLimitVec   &
                                                , randomStartPointDomainUpperLimitVec   = randomStartPointDomainUpperLimitVec   &
                                                )
            call self%SpecDRAM%setFromInputArgs ( adaptiveUpdateCount                   = adaptiveUpdateCount                   &
                                                , adaptiveUpdatePeriod                  = adaptiveUpdatePeriod                  &
                                                , greedyAdaptationCount                 = greedyAdaptationCount                 &
                                                , delayedRejectionCount                 = delayedRejectionCount                 &
                                                , burninAdaptationMeasure               = burninAdaptationMeasure               &
                                                , delayedRejectionScaleFactorVec        = delayedRejectionScaleFactorVec        &
                                                )
        end if
        if (self%Err%occurred) then
            self%Err%msg = PROCEDURE_NAME // self%Err%msg
            call self%abort( Err = self%Err, prefix = self%brand, newline = "\n", outputUnit = self%LogFile%unit )
            return
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! Now depending on the requested parallelism type, determine the process master/slave type and open output files
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        self%Image%isMaster = .false.
        if (self%SpecBase%ParallelizationModel%isSinglChain) then
            if (self%Image%isFirst) self%Image%isMaster = .true.
        elseif (self%SpecBase%ParallelizationModel%isMultiChain) then
            self%Image%isMaster = .true.
        else
            self%Err%msg = PROCEDURE_NAME//": Error occurred. Unknown parallelism requested via the input variable parallelizationModel='"//self%SpecBase%ParallelizationModel%val//"'."
            call self%abort( Err = self%Err, prefix = self%brand, newline = "\n", outputUnit = self%LogFile%unit )
            return
        end if
        self%Image%isNotMaster = .not. self%Image%isMaster

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! setup log file and open output files
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        call self%setupOutputFiles()
        if (self%Err%occurred) then
            self%Err%msg = PROCEDURE_NAME // self%Err%msg
            call self%abort( Err = self%Err, prefix = self%brand, newline = NLC, outputUnit = self%LogFile%unit )
            return
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! report variable values to the log file
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (self%isFreshRun) then
            call self%SpecBase%reportValues(prefix=self%brand,outputUnit=self%LogFile%unit,isMasterImage=self%Image%isMaster)
            call self%SpecMCMC%reportValues(prefix=self%brand,outputUnit=self%LogFile%unit,isMasterImage=self%Image%isMaster,methodName=self%name,splashModeRequested=self%SpecBase%SilentModeRequested%isFalse)
            call self%SpecDRAM%reportValues(prefix=self%brand,outputUnit=self%LogFile%unit,isMasterImage=self%Image%isMaster,splashModeRequested=self%SpecBase%SilentModeRequested%isFalse)
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! perform variable value sanity checks
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        self%Err%msg = ""
        self%Err%occurred = .false.

        call self%SpecBase%checkForSanity   ( Err = self%Err          &
                                            , methodName = self%name  &
                                            )

        call self%SpecMCMC%checkForSanity   ( Err = self%Err                                                &
                                            , methodName = self%name                                        &
                                            , nd = ndim                                                     &
                                            , domainLowerLimitVec = self%SpecBase%DomainLowerLimitVec%Val   &
                                            , domainUpperLimitVec = self%SpecBase%DomainUpperLimitVec%Val   &
                                            )

        call self%SpecDRAM%checkForSanity   ( Err = self%Err            &
                                            , methodName = self%name    &
                                            , nd = ndim                 &
                                            )

        if (self%Image%isMaster) then

            if (self%Err%occurred) then
                self%Err%msg = PROCEDURE_NAME // self%Err%msg
                call self%abort( Err = self%Err, prefix = self%brand, newline = "\n", outputUnit = self%LogFile%unit )
                return
            end if

        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! setup output files
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        block
            use ParaDRAMChainFileContents_mod, only: ChainFileContents_type
            self%Chain = ChainFileContents_type( ndim = ndim, variableNameList = self%SpecBase%VariableNameList%Val )
        end block
        if (self%isFreshRun) then
            if (self%Image%isMaster) then
                write( self%TimeFile%unit, self%TimeFile%format ) "NumFuncCallTotal" &
                                                                , "NumFuncCallAccepted" &
                                                                , "MeanAcceptanceRateSinceStart" &
                                                                , "MeanAcceptanceRateSinceLastReport" &
                                                                , "TimeElapsedSinceLastReportInSeconds" &
                                                                , "TimeElapsedSinceStartInSeconds" &
                                                                , "TimeRemainedToFinishInSeconds"
                call self%Chain%writeHeader ( ndim              = ndim &
                                            , chainFileUnit     = self%ChainFile%unit &
                                            , isBinary          = self%SpecBase%ChainFileFormat%isBinary &
                                            , chainFileFormat   = self%ChainFile%format &
                                            )
            end if
        else
            if (self%Image%isMaster) read(self%TimeFile%unit,*) ! read the header line of the time file, only by master images
            call self%Chain%getLenHeader(ndim=ndim,isBinary=self%SpecBase%ChainFileFormat%isBinary,chainFileFormat=self%ChainFile%format)
        end if

        ! The format setup of setupOutputFiles() uses the generic g0 edit descriptor. Here the format is revised to be more specific.
        ! g0 edit descriptor format is slightly more arbitrary and compiler-dependent.

        if (self%SpecBase%OutputColumnWidth%val>0) then
            self%TimeFile%format  = "("     // &
                                    "2I"    // self%SpecBase%OutputColumnWidth%str // ",'" // self%SpecBase%OutputDelimiter%val // &
                                    "',5(E" // self%SpecBase%OutputColumnWidth%str // "." // self%SpecBase%OutputRealPrecision%str // &
                                    ",:,'"  // self%SpecBase%OutputDelimiter%val // "'))"
            self%ChainFile%format = "("     // &
                                    "2(I"   // self%SpecBase%OutputColumnWidth%str // &
                                    ",'"    // self%SpecBase%OutputDelimiter%val // "')," // &
                                    "2(E"   // self%SpecBase%OutputColumnWidth%str // "." // self%SpecBase%OutputRealPrecision%str // &
                                    ",'"    // self%SpecBase%OutputDelimiter%val // "')," // &
                                    "2(I"   // self%SpecBase%OutputColumnWidth%str // &
                                    ",'"    // self%SpecBase%OutputDelimiter%val // "')" // &
                                    ","     // num2str(3_IK+self%nd%val) // &
                                    "(E"    // self%SpecBase%OutputColumnWidth%str // "." // self%SpecBase%OutputRealPrecision%str // &
                                    ",:,'"  // self%SpecBase%OutputDelimiter%val // "')" // &
                                    ")"
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! setup the proposal distribution
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (self%SpecMCMC%ProposalModel%isNormal .or. self%SpecMCMC%ProposalModel%isUniform) then
            !ProposalSymmetric = ProposalSymmetric_type(ndim = ndim, PD = self)
            !self%Proposal => ProposalSymmetric
            allocate( self%Proposal, source = ProposalSymmetric_type( ndim          = ndim &
                                                                    , SpecBase      = self%SpecBase &
                                                                    , SpecMCMC      = self%SpecMCMC &
                                                                    , SpecDRAM      = self%SpecDRAM &
                                                                    , Image         = self%Image &
                                                                    , name          = self%name &
                                                                    , brand         = self%brand &
                                                                    , LogFile       = self%LogFile &
                                                                    , RestartFile   = self%RestartFile &
                                                                    ) )
#if MATLAB_ENABLED && !defined CAF_ENABLED && !defined MPI_ENABLED
            block
                use ParaDRAMProposal_mod, only: ProposalErr
                if(ProposalErr%occurred) return
            end block
#endif
        !elseif (self%SpecMCMC%ProposalModel%isUniform) then
        !    allocate( self%Proposal, source = ProposalUniform_type(ndim = ndim, PD = self) )
        else
            self%Err%msg = PROCEDURE_NAME // ": Internal error occurred. Unsupported proposal distribution for " // self%name // "."
            call self%abort( Err = self%Err, prefix = self%brand, newline = "\n", outputUnit = self%LogFile%unit )
            return
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! run ParaDRAM kernel
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (self%isFreshRun .and. self%Image%isMaster) then
            call self%Decor%writeDecoratedText  ( text = "\nStarting the " // self%name // " sampling - " // getNiceDateTime() // "\n" &
                                                , marginTop = 1_IK  &
                                                , marginBot = 1_IK  &
                                                , newline = "\n"    &
                                                , outputUnit = self%LogFile%unit )
        end if

        call self%runKernel( getLogFunc = getLogFunc )
        if(self%Err%occurred) return ! relevant only for MATLAB

        if (self%isFreshRun .and. self%Image%isMaster) then
            call self%Decor%writeDecoratedText  ( text = "\nExiting the " // self%name // " sampling - " // getNiceDateTime() // "\n" &
                                                , marginTop = 1_IK  &
                                                , marginBot = 1_IK  &
                                                , newline = "\n"    &
                                                , outputUnit = self%LogFile%unit )
        end if

        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ! start ParaDRAM post-processing
        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        blockMasterPostProcessing: if (self%Image%isMaster) then

            formatStrInt  = "('" // INDENT // "',1A" // self%LogFile%maxColWidth%str // ",*(I" // self%LogFile%maxColWidth%str // "))"
            formatStrReal = "('" // INDENT // "',1A" // self%LogFile%maxColWidth%str // ",*(E" // self%LogFile%maxColWidth%str // "." // self%SpecBase%OutputRealPrecision%str // "))"

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.numFuncCall.accepted"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%NumFunCall%accepted
            msg = "This is the total number of accepted function calls (unique samples)."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.numFuncCall.acceptedRejected"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%NumFunCall%acceptedRejected
            msg = "This is the total number of accepted or rejected function calls."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.numFuncCall.acceptedRejectedDelayed"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%NumFunCall%acceptedRejectedDelayed
            msg = "This is the total number of accepted or rejected or delayed-rejection (if any requested) function calls."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.numFuncCall.acceptedRejectedDelayedUnused"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%NumFunCall%acceptedRejectedDelayedUnused
            msg = "This is the total number of accepted or rejected or unused function calls (by all processes, including delayed rejections, if any requested)."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.efficiency.meanAcceptanceRate"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Chain%MeanAccRate(self%Stats%NumFunCall%accepted)
            msg = "This is the average MCMC acceptance rate."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            mcmcSamplingEfficiency = real(self%Stats%NumFunCall%accepted,kind=RK) / real(self%Stats%NumFunCall%acceptedRejected,kind=RK)

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.efficiency.acceptedOverAcceptedRejected"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) mcmcSamplingEfficiency
            msg =   "This is the MCMC sampling efficiency given the accepted and rejected function calls, that is, &
                    &the number of accepted function calls divided by the number of (accepted + rejected) function calls."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.efficiency.acceptedOverAcceptedRejectedDelayed"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) real(self%Stats%NumFunCall%accepted,kind=RK) / real(self%Stats%NumFunCall%acceptedRejectedDelayed,kind=RK)
            msg =   "This is the MCMC sampling efficiency given the accepted, rejected, and delayed-rejection (if any requested) function calls, that is, &
                    &the number of accepted function calls divided by the number of (accepted + rejected + delayed-rejection) function calls."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.efficiency.acceptedOverAcceptedRejectedDelayedUnused"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) real(self%Stats%NumFunCall%accepted,kind=RK) / real(self%Stats%NumFunCall%acceptedRejectedDelayedUnused,kind=RK)
            msg =   "This is the MCMC sampling efficiency given the accepted, rejected, delayed-rejection (if any requested), and unused function calls, that is, &
                    &the number of accepted function calls divided by the number of (accepted + rejected + delayed-rejection + unused) function calls."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.total"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Timer%Time%total
            msg = "This is the total runtime in seconds."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.perFuncCallAccepted"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Timer%Time%total / real(self%Stats%NumFunCall%accepted,kind=RK)
            msg = "This is the average effective time cost of each accepted function call, in seconds."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.perFuncCallAcceptedRejected"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Timer%Time%total / real(self%Stats%NumFunCall%acceptedRejected,kind=RK)
            msg = "This is the average effective time cost of each accepted or rejected function call, in seconds."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.perFuncCallAcceptedRejectedDelayed"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Timer%Time%total / real(self%Stats%NumFunCall%acceptedRejectedDelayed,kind=RK)
            msg = "This is the average effective time cost of each accepted or rejected function call (including delayed-rejections, if any requested), in seconds."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.perFuncCallAcceptedRejectedDelayedUnused"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Timer%Time%total / real(self%Stats%NumFunCall%acceptedRejectedDelayedUnused,kind=RK)
            msg = "This is the average effective time cost of each accepted or rejected or unused function call (including delayed-rejections, if any requested), in seconds."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if (self%Image%count==1_IK) then
                msg = UNDEFINED
            else
                msg = num2str( self%Stats%avgCommTimePerFunCall )
            end if

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.perInterProcessCommunication"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) msg
            msg = "This is the average time cost of inter-process communications per used (accepted or rejected or delayed-rejection) function call, in seconds."
            

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.time.perFuncCall"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%avgTimePerFunCalInSec
            msg = "This is the average pure time cost of each function call, in seconds."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.current.numProcess"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Image%count
            msg = "This is the number of processes (images) used in this simulation."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if (self%Image%count==1_IK .or. self%SpecBase%ParallelizationModel%isMultiChain) then

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.current.speedup"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Image%count
                msg = "This is the estimated maximum speedup gained via "//self%SpecBase%ParallelizationModel%val//" parallelization model compared to serial mode."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                if (self%SpecBase%ParallelizationModel%isMultiChain) then
                    msg = "+INFINITY"
                else
                    msg = UNDEFINED
                end if

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.current.numProcess"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) msg
                msg = "This is the predicted optimal number of physical computing processes for "//self%SpecBase%ParallelizationModel%val//" parallelization model, given the current MCMC sampling efficiency."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                if (self%SpecBase%ParallelizationModel%isMultiChain) then
                    msg = "+INFINITY"
                else
                    msg = UNDEFINED
                end if

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.current.speedup"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) msg
                msg = "This is the predicted optimal maximum speedup gained via "//self%SpecBase%ParallelizationModel%val//" parallelization model, given the current MCMC sampling efficiency."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                if (self%SpecBase%ParallelizationModel%isMultiChain) then
                    msg = "+INFINITY"
                else
                    msg = UNDEFINED
                end if

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.absolute.numProcess"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) msg
                msg = "This is the predicted absolute optimal number of physical computing processes for "//self%SpecBase%ParallelizationModel%val//" parallelization model, under any MCMC sampling efficiency."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                if (self%SpecBase%ParallelizationModel%isMultiChain) then
                    msg = "+INFINITY"
                else
                    msg = UNDEFINED
                end if

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.absolute.speedup"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) msg
#if defined CAF_ENABLED || defined MPI_ENABLED
                if (self%Image%count==1_IK) then
                    msg = self%name// " is being used in parallel mode but with only one processor. This is computationally inefficient. &
                                    &Consider using the serial version of the code or provide more processes at runtime."
                    call self%note( prefix     = self%brand         &
                                , outputUnit = output_unit      &
                                , newline    = NLC              &
                                , marginTop  = 3_IK             &
                                , marginBot  = 0_IK             &
                                , msg        = msg              )
                end if
#endif
                msg = "This is the predicted absolute optimal maximum speedup gained via "//self%SpecBase%ParallelizationModel%val//" parallelization model, under any MCMC sampling efficiency."//NLC//msg
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#if defined CAF_ENABLED || defined MPI_ENABLED
            else

                block

                    use Statistics_mod, only: getgeoPDF
                    logical     :: maxSpeedupFound
                    integer(IK) :: imageCount, maxSpeedupImageCount, lengeoPDF
                    real(RK)    :: seqSecTime, parSecTime, comSecTime, serialTime, avgCommTimePerFunCallPerNode
                    real(RK)    :: currentSpeedup, maxSpeedup
                    real(RK)    :: speedup, firstImageWeight
                    real(RK)    , allocatable :: geoPDF(:), speedupVec(:), tempVec(:)
                    character(:), allocatable :: formatIn, formatScaling

                    formatScaling = "('" // INDENT // "',10(E" // self%LogFile%maxColWidth%str // "." // self%SpecBase%OutputRealPrecision%str // "))" ! ,:,','

                    geoPDF = getgeoPDF(successProb=mcmcSamplingEfficiency,minSeqLen=10*self%Image%count)
                    lengeoPDF = size(geoPDF)

                    ! compute the serial and sequential runtime of the code per function call

                    seqSecTime = epsilon(seqSecTime) ! time cost of the sequential section of the code, which is negligible here
                    serialTime = self%Stats%avgTimePerFunCalInSec + seqSecTime ! serial runtime of the code per function call

                    ! compute the communication overhead for each additional image beyond master

                    avgCommTimePerFunCallPerNode = self%Stats%avgCommTimePerFunCall / real(self%Image%count-1_IK,kind=RK)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    ! compute the optimal parallelism efficiency with the current MCMC sampling efficiency
                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    ! compute fraction of points sampled by the first image

                    maxSpeedup = 1._RK
                    maxSpeedupImageCount = 1_IK
                    if (allocated(speedupVec)) deallocate(speedupVec); allocate(speedupVec(lengeoPDF))
                    speedupVec(1) = 1._RK
                    loopOptimalImageCount: do imageCount = 2, lengeoPDF
                        firstImageWeight = sum(geoPDF(1:lengeoPDF:imageCount))
                        parSecTime = self%Stats%avgTimePerFunCalInSec * firstImageWeight ! parallel-section runtime of the code per function call
                        comSecTime = (imageCount-1_IK) * avgCommTimePerFunCallPerNode  ! assumption: communication time grows linearly with the number of nodes
                        speedupVec(imageCount) = serialTime / (seqSecTime+parSecTime+comSecTime)
                        maxSpeedup = max( maxSpeedup , speedupVec(imageCount) )
                        if (maxSpeedup==speedupVec(imageCount)) maxSpeedupImageCount = imageCount
                        if (imageCount==self%Image%count) then
                            currentSpeedup = speedupVec(imageCount)
                            !if (maxSpeedup/=speedupVec(imageCount)) exit loopOptimalImageCount
                        end if
                    end do loopOptimalImageCount

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.current.speedup"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_TABBED_FORMAT) currentSpeedup
                    msg = "This is the estimated maximum speedup gained via "//self%SpecBase%ParallelizationModel%val//" parallelization model compared to serial mode."
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.current.numProcess"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_TABBED_FORMAT) maxSpeedupImageCount
                    msg = "This is the predicted optimal number of physical computing processes for "//self%SpecBase%ParallelizationModel%val//" parallelization model, given the current MCMC sampling efficiency."
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.current.speedup"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_TABBED_FORMAT) maxSpeedup
                    msg = ""
                    if (currentSpeedup<1._RK) then
                        formatIn = "(g0.6)"
                        msg =   "The time cost of calling the user-provided objective function must be at least " // &
                                num2str(1._RK/currentSpeedup,formatIn) // " times more (that is, ~" // &
                                num2str(10**6*self%Stats%avgTimePerFunCalInSec/currentSpeedup,formatIn) // &
                                " microseconds) to see any performance benefits from " // &
                                self%SpecBase%ParallelizationModel%val // " parallelization model for this simulation. "
                        if (maxSpeedupImageCount==1_IK) then
                            msg = msg// "Consider simulating in the serial mode in the future (if used within &
                                        &the same computing environment and with the same configuration as used here)."
                        else
                            msg = msg// "Consider simulating on " // num2str(maxSpeedupImageCount) // " processors in the future &
                                        &(if used within the same computing environment and with the same configuration as used here)."
                        end if
                        call self%note( prefix     = self%brand         &
                                    , outputUnit = output_unit      &
                                    , newline    = NLC              &
                                    , marginTop  = 3_IK             &
                                    , marginBot  = 0_IK             &
                                    , msg        = msg              )
                        msg = NLC // msg
                    end if
                    msg = "This is the predicted optimal maximum speedup gained via "//self%SpecBase%ParallelizationModel%val//" parallelization model, given the current MCMC sampling efficiency." // msg
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.current.scaling.strong.speedup"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    !write(self%LogFile%unit,formatStrInt) "numProcess", (imageCount, imageCount = 1, lengeoPDF)
                    !write(self%LogFile%unit,formatStrReal) "speedup" , (speedupVec(imageCount), imageCount = 1, lengeoPDF)
                    do imageCount = 1, lengeoPDF, 10
                        write(self%LogFile%unit,formatScaling) speedupVec(imageCount:min(imageCount+9_IK,lengeoPDF))
                    end do
                    msg =   "This is the predicted strong-scaling speedup behavior of the "//self%SpecBase%ParallelizationModel%val//" parallelization model, &
                            &given the current MCMC sampling efficiency, for increasing numbers of processes, starting from a single process."
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    ! compute the absolute optimal parallelism efficiency under any MCMC sampling efficiency
                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    imageCount = 1_IK
                    maxSpeedup = 1._RK
                    maxSpeedupImageCount = 1_IK
                    speedupVec(1) = 1._RK
                    maxSpeedupFound = .false.
                    lenGeoPDF = size(speedupVec)
                    loopAbsoluteOptimalImageCount: do 
                        imageCount = imageCount + 1_IK
                        if (imageCount>lenGeoPDF) then
                            if (maxSpeedupFound) exit loopAbsoluteOptimalImageCount
                            lenGeoPDF = 2_IK * lenGeoPDF
                            if (allocated(tempVec)) deallocate(tempVec); allocate(tempVec(lenGeoPDF))
                            tempVec(1:lenGeoPDF/2_IK) = speedupVec
                            call move_alloc(tempVec,speedupVec)
                        end if
                        parSecTime = self%Stats%avgTimePerFunCalInSec / imageCount
                        comSecTime = (imageCount-1_IK) * avgCommTimePerFunCallPerNode  ! assumption: communication time grows linearly with the number of nodes
                        speedupVec(imageCount) = serialTime / (seqSecTime+parSecTime+comSecTime)
                        if (.not.maxSpeedupFound .and. maxSpeedup>speedupVec(imageCount)) then
                            maxSpeedupImageCount = imageCount - 1_IK
                            maxSpeedupFound = .true.
                            !exit loopAbsoluteOptimalImageCount
                        end if
                        maxSpeedup = max( maxSpeedup , speedupVec(imageCount) )
                    end do loopAbsoluteOptimalImageCount

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.absolute.numProcess"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_TABBED_FORMAT) maxSpeedupImageCount
                    msg = "This is the predicted absolute optimal number of physical computing processes for "//self%SpecBase%ParallelizationModel%val//" parallelization model, under any MCMC sampling efficiency."
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.absolute.speedup"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_TABBED_FORMAT) maxSpeedup
                    msg =   "This is the predicted absolute optimal maximum speedup gained via "//self%SpecBase%ParallelizationModel%val//" parallelization model, under any MCMC sampling efficiency. &
                            &This simulation will likely NOT benefit from any additional computing processors beyond the predicted absolute optimal number, " // num2str(maxSpeedupImageCount) // ", &
                            &in the above. This is true for any value of MCMC sampling efficiency. Keep in mind that the predicted absolute optimal number of processors is just an estimate &
                            &whose accuracy depends on many runtime factors, including the topology of the communication network being used, the number of processors per node, &
                            &and the number of tasks to each processor or node."
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.parallelism.optimal.absolute.scaling.strong.speedup"
                    write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                    !write(self%LogFile%unit,formatStrInt) "numProcess", (imageCount, imageCount = 1, lengeoPDF)
                    !write(self%LogFile%unit,formatStrReal)"speedup"   , (speedupVec(imageCount), imageCount = 1, lengeoPDF)
                    do imageCount = 1, lengeoPDF, 10
                        write(self%LogFile%unit,formatScaling) speedupVec(imageCount:min(imageCount+9_IK,lengeoPDF))
                    end do
                    msg =   "This is the predicted absolute strong-scaling speedup behavior of the "//self%SpecBase%ParallelizationModel%val//" parallelization model, &
                            &under any MCMC sampling efficiency, for increasing numbers of processes, starting from a single process."
                    call self%reportDesc(msg)

                    !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                end block
#endif
            end if

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.compact.burnin.location.likelihoodBased"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%BurninLoc%compact
            msg = "This is the burnin location in the compact chain, based on the occurrence likelihood."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.compact.burnin.location.adaptationBased"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%AdaptationBurninLoc%compact
            msg = "This is the burnin location in the compact chain, based on the value of burninAdaptationMeasure simulation specification."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.burnin.location.likelihoodBased"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%BurninLoc%verbose
            msg = "This is the burnin location in the verbose (Markov) chain, based on the occurrence likelihood."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.burnin.location.adaptationBased"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%AdaptationBurninLoc%verbose
            msg = "This is the burnin location in the verbose (Markov) chain, based on the value of burninAdaptationMeasure simulation specification."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            ! reset BurninLoc to the maximum value

            if (self%Stats%AdaptationBurninLoc%compact>self%Stats%BurninLoc%compact) then
                self%Stats%BurninLoc%compact = self%Stats%AdaptationBurninLoc%compact
                self%Stats%BurninLoc%verbose = self%Stats%AdaptationBurninLoc%verbose
            end if

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.logFunc.max"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%LogFuncMode%val
            msg = "This is the maximum logFunc value (the maximum of the user-specified objective function)."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.compact.logFunc.max.location"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%LogFuncMode%Loc%compact
            msg = "This is the location of the first occurrence of the maximum logFunc in the compact chain."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.logFunc.max.location"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%LogFuncMode%Loc%verbose
            msg = "This is the location of the first occurrence of the maximum logFunc in the verbose (Markov) chain."
           call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            formatAllReal = "('" // INDENT // "',*(E" // self%LogFile%maxColWidth%str // "." // self%SpecBase%OutputRealPrecision%str // "))"

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.logFunc.max.state"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,self%LogFile%format) (trim(adjustl(self%SpecBase%VariableNameList%Val(i))), i=1, ndim)
            write(self%LogFile%unit,formatAllReal) self%Stats%LogFuncMode%Crd
            msg = "This is the coordinates, within the domain of the user-specified objective function, where the maximum logFunc occurs."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            ! Compute the statistical properties of the MCMC chain
            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if (self%Image%isFirst) then
                call self%note( prefix        = self%brand          &
                            , outputUnit    = output_unit       &
                            , newline       = NLC               &
                            , marginTop     = 3_IK              &
                            , msg           = "Computing the statistical properties of the Markov chain..." )
            end if

            call self%Decor%writeDecoratedText( text = "\nThe statistical properties of the Markov chain\n" &
                                            , marginTop = 1_IK  &
                                            , marginBot = 1_IK  &
                                            , newline = "\n"    &
                                            , outputUnit = self%LogFile%unit )

            self%Stats%Chain%count = sum(self%Chain%Weight(self%Stats%BurninLoc%compact:self%Chain%count%compact))

            ! compute the covariance and correlation upper-triangle matrices

            if (allocated(self%Stats%Chain%Mean)) deallocate(self%Stats%Chain%Mean); allocate(self%Stats%Chain%Mean(ndim))
            if (allocated(self%Stats%Chain%CovMat)) deallocate(self%Stats%Chain%CovMat); allocate(self%Stats%Chain%CovMat(ndim,ndim))
            call getWeiSamCovUppMeanTrans   ( np = self%Chain%count%compact - self%Stats%BurninLoc%compact + 1_IK &
                                            , sumWeight = self%Stats%Chain%count &
                                            , nd = ndim &
                                            , Point = self%Chain%State(1:ndim,self%Stats%BurninLoc%compact:self%Chain%count%compact) &
                                            , Weight = self%Chain%Weight(self%Stats%BurninLoc%compact:self%Chain%count%compact) &
                                            , CovMatUpper = self%Stats%Chain%CovMat &
                                            , Mean = self%Stats%Chain%Mean &
                                            )

            self%Stats%Chain%CorMat = getUpperCorMatFromUpperCovMat(nd=ndim,CovMatUpper=self%Stats%Chain%CovMat)

            ! transpose the covariance and correlation matrices

            do i = 1, ndim
                self%Stats%Chain%CorMat(i,i) = 1._RK
                self%Stats%Chain%CorMat(i+1:ndim,i) = self%Stats%Chain%CorMat(i,i+1:ndim)
                self%Stats%Chain%CovMat(i+1:ndim,i) = self%Stats%Chain%CovMat(i,i+1:ndim)
            end do

            ! compute the quantiles

            if (allocated(self%Stats%Chain%Quantile)) deallocate(self%Stats%Chain%Quantile)
            allocate(self%Stats%Chain%Quantile(QPROB%count,ndim))
            do i = 1, ndim
                self%Stats%Chain%Quantile(1:QPROB%count,i) = getQuantile  ( np = self%Chain%count%compact - self%Stats%BurninLoc%compact + 1_IK &
                                                                        , nq = QPROB%count &
                                                                        , SortedQuantileProbability = QPROB%Value &
                                                                        , Point = self%Chain%State(i,self%Stats%BurninLoc%compact:self%Chain%count%compact) &
                                                                        , Weight = self%Chain%Weight(self%Stats%BurninLoc%compact:self%Chain%count%compact) &
                                                                        , sumWeight = self%Stats%Chain%count &
                                                                        )
            end do

            ! report the MCMC chain statistics

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.length.burninExcluded"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%Chain%count
            msg = "This is the length of the verbose (Markov) Chain excluding burnin."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.avgStd"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,self%LogFile%format) "variableName", "Mean", "Standard Deviation"
            do i = 1, ndim
                write(self%LogFile%unit,formatStrReal) trim(adjustl(self%SpecBase%VariableNameList%Val(i))), self%Stats%Chain%Mean(i), sqrt(self%Stats%Chain%CovMat(i,i))
            end do
            msg = "This is the mean and standard deviation of the verbose (Markov) chain variables."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.covmat"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,self%LogFile%format) "", (trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
            do i = 1, ndim
                write(self%LogFile%unit,formatStrReal) trim(adjustl(self%SpecBase%VariableNameList%Val(i))), self%Stats%Chain%CovMat(1:ndim,i)
            end do
            msg = "This is the covariance matrix of the verbose (Markov) chain."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.cormat"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,self%LogFile%format) "", (trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
            do i = 1, ndim
                write(self%LogFile%unit,formatStrReal) trim(adjustl(self%SpecBase%VariableNameList%Val(i))), self%Stats%Chain%CorMat(1:ndim,i)
            end do
            msg = "This is the correlation matrix of the verbose (Markov) chain."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.verbose.quantile"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,self%LogFile%format) "Quantile", (trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
            do iq = 1, QPROB%count
                write(self%LogFile%unit,formatStrReal) trim(adjustl(QPROB%Name(iq))), (self%Stats%Chain%Quantile(iq,i),i=1,ndim)
            end do
            msg = "This is the quantiles table of the variables of the verbose (Markov) chain."
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            ! Generate the i.i.d. sample statistics and output file (if requested)
            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            ! report refined sample statistics, and generate output refined sample if requested.

            if (self%Image%isFirst) then
                call self%note  ( prefix        = self%brand    &
                                , outputUnit    = output_unit   &
                                , newline       = NLC           &
                                , msg           = "Computing the final decorrelated sample size..." )
            end if

            call self%RefinedChain%get  ( CFC                       = self%Chain                                  &
                                        , Err                       = self%Err                                    &
                                        , burninLoc                 = self%Stats%BurninLoc%compact                &
                                        , sampleRefinementCount     = self%SpecMCMC%SampleRefinementCount%val     &
                                        , sampleRefinementMethod    = self%SpecMCMC%SampleRefinementMethod%val    &
                                        )

            if (self%Err%occurred) then
                self%Err%msg = PROCEDURE_NAME // self%Err%msg
                call self%abort( Err = self%Err, prefix = self%brand, newline = NLC, outputUnit = self%LogFile%unit )
                return
            end if

            ! compute the maximum integrated autocorrelation times for each variable

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            formatStr = "('" // INDENT // "',2I" // self%LogFile%maxColWidth%str // ",*(E" // self%LogFile%maxColWidth%str // "." // self%SpecBase%OutputRealPrecision%str // "))"

            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.iac"
            write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
            write(self%LogFile%unit,self%LogFile%format) "RefinementStage","SampleSize","IAC_SampleLogFunc",("IAC_"//trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
            do i = 0, self%RefinedChain%numRefinement
                write(self%LogFile%unit,formatStr) i, self%RefinedChain%Count(i)%Verbose, self%RefinedChain%IAC(0:ndim,i)
            end do
            msg = "This is the table of the Integrated Autocorrelation (IAC) of individual variables in the verbose (Markov) chain, at increasing stages of chain refinements."
            if (self%RefinedChain%numRefinement==0_IK) then
                msg = msg // NLC // "The user-specified sampleRefinementCount ("// num2str(self%SpecMCMC%SampleRefinementCount%val) // ") &
                                    &is too small to ensure an accurate computation of the decorrelated i.i.d. effective sample size. &
                                    &No refinement of the Markov chain was performed."
            end if
            call self%reportDesc(msg)

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            ! report the final Effective Sample Size (ESS) based on IAC

            blockEffectiveSampleSize: associate( effectiveSampleSize => sum(self%RefinedChain%Weight(1:self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact)) )

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.ess"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) effectiveSampleSize
                msg = "This is the estimated Effective (decorrelated) Sample Size (ESS) of the final refined chain."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.efficiency.essOverAccepted"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) real(effectiveSampleSize,kind=RK) / real(self%Stats%NumFunCall%accepted,kind=RK)
                msg =   "This is the effective MCMC sampling efficiency given the accepted function calls, that is, &
                        &the final refined effective sample size (ESS) divided by the number of accepted function calls."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.efficiency.essOverAcceptedRejected"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) real(effectiveSampleSize,kind=RK) / real(self%Stats%NumFunCall%acceptedRejected,kind=RK)
                msg =   "This is the effective MCMC sampling efficiency given the accepted and rejected function calls, that is, &
                        &the final refined effective sample size (ESS) divided by the number of (accepted + rejected) function calls."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.efficiency.essOverAcceptedRejectedDelayed"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) real(effectiveSampleSize,kind=RK) / real(self%Stats%NumFunCall%acceptedRejectedDelayed,kind=RK)
                msg =   "This is the effective MCMC sampling efficiency given the accepted, rejected, and delayed-rejection (if any requested) function calls, that is, &
                        &the final refined effective sample size (ESS) divided by the number of (accepted + rejected + delayed-rejection) function calls."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.efficiency.essOverAcceptedRejectedDelayedUnused"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) real(effectiveSampleSize,kind=RK) / real(self%Stats%NumFunCall%acceptedRejectedDelayedUnused,kind=RK)
                msg =   "This is the effective MCMC sampling efficiency given the accepted, rejected, delayed-rejection (if any requested), and unused function calls, that is, &
                        &the final refined effective sample size (ESS) divided by the number of (accepted + rejected + delayed-rejection + unused) function calls."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end associate blockEffectiveSampleSize

            ! generate output refined sample if requested

            blockSampleFileGeneration: if (self%SpecBase%SampleSize%val==0_IK) then

                call self%note  ( prefix        = self%brand        &
                                , outputUnit    = self%LogFile%unit &
                                , newline       = NLC               &
                                , msg           = "Skipping the generation of the decorrelated sample and output file, as requested by the user..." )

            else blockSampleFileGeneration

                !*******************************************************************************************************************
                ! sample file generation report
                !*******************************************************************************************************************

                ! report to the report-file(s)

                call self%note  ( prefix        = self%brand        &
                                , outputUnit    = self%LogFile%unit &
                                , newline       = NLC               &
                                , msg           = "Generating the output " // self%SampleFile%suffix // " file:"//NLC // self%SampleFile%Path%original )


                if (self%Image%isFirst) then 

                    ! print the message for the generating the output sample file on the first image

                    call self%note  ( prefix     = self%brand       &
                                    , outputUnit = output_unit      &
                                    , newline    = NLC              &
                                    , marginBot  = 0_IK             &
                                    , msg        = "Generating the output " // self%SampleFile%suffix // " file:" )

                    call self%note  ( prefix     = self%brand       &
                                    , outputUnit = output_unit      &
                                    , newline    = NLC              &
                                    , marginTop  = 0_IK             &
                                    , marginBot  = 0_IK             &
                                    , msg = self%SampleFile%Path%original )

                    ! print the message for the generating the output sample file on the rest of the images in order

#if defined CAF_ENABLED || defined MPI_ENABLED
                    if (self%SpecBase%ParallelizationModel%isMultiChain) then
                        block
                            use String_mod, only: replaceStr, num2str
                            integer(IK) :: imageID
                            do imageID = 2, self%Image%count
                                call self%note  ( prefix = self%brand       &
                                                , outputUnit = output_unit  &
                                                , newline = NLC             &
                                                , marginTop = 0_IK          &
                                                , marginBot = 0_IK          &
                                                , msg = replaceStr( string = self%SampleFile%Path%original, search = "process_1", substitute = "process_"//num2str(imageID) ) )
                            end do
                        end block
                    end if
#endif
                    call self%Decor%write(output_unit,0,1)

                end if

                !*******************************************************************************************************************
                ! begin sample file generation
                !*******************************************************************************************************************

                if (self%SpecBase%SampleSize%val/=-1_IK) then

                    if (self%SpecBase%SampleSize%val<0_IK) self%SpecBase%SampleSize%val = abs(self%SpecBase%SampleSize%val) * self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose

                    if (self%SpecBase%SampleSize%val/=0_IK) then
                        if (self%SpecBase%SampleSize%val<self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose) then
                            call self%warn    ( prefix = self%brand &
                                            , newline = "\n" &
                                            , marginTop = 0_IK &
                                            , outputUnit = self%LogFile%unit &
                                            , msg = "The user-specified sample size ("// num2str(self%SpecBase%SampleSize%val) // ") &
                                                    &is smaller than the potentially-optimal i.i.d. sample size &
                                                    &(" // num2str(self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose) // "). &
                                                    &The output sample contains i.i.d. samples, however, the sample-size &
                                                    &could have been larger if it had been set to the optimal size. &
                                                    &To get the optimal size in the future runs, set sampleSize = -1, or drop&
                                                    &it from the input list." &
                                            )
                        elseif (self%SpecBase%SampleSize%val>self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose) then
                            call self%warn    ( prefix = self%brand &
                                            , newline = "\n" &
                                            , marginTop = 0_IK &
                                            , outputUnit = self%LogFile%unit &
                                            , msg = "The user-specified sample size ("// num2str(self%SpecBase%SampleSize%val) // ") &
                                                    &is larger than the potentially-optimal i.i.d. sample size &
                                                    &(" // num2str(self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose) // "). &
                                                    &The resulting sample likely contains duplicates and is not independently &
                                                    &and identically distributed (i.i.d.).\nTo get the optimal &
                                                    &size in the future runs, set sampleSize = -1, or drop &
                                                    &it from the input list." &
                                            )
                        else
                            call self%warn    ( prefix = self%brand &
                                            , newline = "\n" &
                                            , marginTop = 0_IK &
                                            , outputUnit = self%LogFile%unit &
                                            , msg = "How lucky that could be! &
                                                    &The user-specified sample size (" // num2str(self%SpecBase%SampleSize%val) // ") &
                                                    &is equal to the potentially-optimal i.i.d. sample size determined by "//self%name//"." &
                                            )
                        end if
                    end if

                    ! regenerate the refined sample, this time with the user-specified sample size.

                    call self%RefinedChain%get( CFC                       = self%Chain &
                                            , Err                       = self%Err &
                                            , burninLoc                 = self%Stats%BurninLoc%compact &
                                            , refinedChainSize          = self%SpecBase%SampleSize%val &
                                            , sampleRefinementCount     = self%SpecMCMC%SampleRefinementCount%val     &
                                            , sampleRefinementMethod    = self%SpecMCMC%SampleRefinementMethod%val    &
                                            )
                    if (self%Err%occurred) then
                        self%Err%msg = PROCEDURE_NAME // self%Err%msg
                        call self%abort( Err = self%Err, prefix = self%brand, newline = NLC, outputUnit = self%LogFile%unit )
                        return
                    end if

                end if

                ! open the output sample file

                self%SampleFile%unit = 3000001 + self%Image%id  ! for some unknown reason, if newunit is used, GFortran opens the file as an internal file
                open( unit      = self%SampleFile%unit            &
                    , file      = self%SampleFile%Path%original   &
                    , status    = self%SampleFile%status          &
                    , iostat    = self%SampleFile%Err%stat        &
#if defined IFORT_ENABLED && defined OS_IS_WINDOWS
                    , SHARED                                    &
#endif
                    , position  = self%SampleFile%Position%value  )
                self%Err = self%SampleFile%getOpenErr(self%SampleFile%Err%stat)
                if (self%Err%occurred) then
                    self%Err%msg = PROCEDURE_NAME//": Error occurred while opening the "//self%name//" "//self%SampleFile%suffix//" file='"//self%SampleFile%Path%original//"'. "
                    call self%abort( Err = self%Err, prefix = self%brand, newline = NLC, outputUnit = self%LogFile%unit )
                    return
                end if

                ! determine the sample file's contents' format

                if (self%SpecBase%OutputColumnWidth%val>0) then
                    formatStr = "(*(E"//self%SpecBase%OutputColumnWidth%str//"."//self%SpecBase%OutputRealPrecision%str//",:,'"//self%SpecBase%OutputDelimiter%val//"'))"
                else
                    formatStr = self%SampleFile%format
                end if

                ! write to the output sample file

                call self%RefinedChain%write(self%SampleFile%unit,self%SampleFile%format,formatStr)
                close(self%SampleFile%unit)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ! Compute the statistical properties of the refined sample
                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                if (self%Image%isFirst) then
                    call self%note  ( prefix        = self%brand        &
                                    , outputUnit    = output_unit       &
                                    , newline       = NLC               &
                                    , marginTop     = 2_IK              &
                                    , msg           = "Computing the statistical properties of the final refined sample..." )
                end if

                call self%Decor%writeDecoratedText  ( text = "\nThe statistical properties of the final refined sample \n" &
                                                    , marginTop = 1_IK  &
                                                    , marginBot = 1_IK  &
                                                    , newline = "\n"    &
                                                    , outputUnit = self%LogFile%unit )

                self%Stats%Sample%count = self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose

                ! compute the covariance and correlation upper-triangle matrices

                if (allocated(self%Stats%Sample%Mean)) deallocate(self%Stats%Sample%Mean); allocate(self%Stats%Sample%Mean(ndim))
                if (allocated(self%Stats%Sample%CovMat)) deallocate(self%Stats%Sample%CovMat); allocate(self%Stats%Sample%CovMat(ndim,ndim))
                call getWeiSamCovUppMeanTrans   ( np = self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact &
                                                , sumWeight = self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose &
                                                , nd = ndim &
                                                , Point = self%RefinedChain%LogFuncState(1:ndim,1:self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact) &
                                                , Weight = self%RefinedChain%Weight(1:self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact) &
                                                , CovMatUpper = self%Stats%Sample%CovMat &
                                                , Mean = self%Stats%Sample%Mean &
                                                )

                self%Stats%Sample%CorMat = getUpperCorMatFromUpperCovMat(nd=ndim,CovMatUpper=self%Stats%Sample%CovMat)

                ! transpose the covariance and correlation matrices

                do i = 1, ndim
                    self%Stats%Sample%CorMat(i,i) = 1._RK
                    self%Stats%Sample%CorMat(i+1:ndim,i) = self%Stats%Sample%CorMat(i,i+1:ndim)
                    self%Stats%Sample%CovMat(i+1:ndim,i) = self%Stats%Sample%CovMat(i,i+1:ndim)
                end do

                ! compute the quantiles

                if (allocated(self%Stats%Sample%Quantile)) deallocate(self%Stats%Sample%Quantile)
                allocate(self%Stats%Sample%Quantile(QPROB%count,ndim))
                do i = 1, ndim
                    self%Stats%Sample%Quantile(1:QPROB%count,i) = getQuantile   ( np = self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact &
                                                                                , nq = QPROB%count &
                                                                                , SortedQuantileProbability = QPROB%Value &
                                                                                , Point = self%RefinedChain%LogFuncState(i,1:self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact) &
                                                                                , Weight = self%RefinedChain%Weight(1:self%RefinedChain%Count(self%RefinedChain%numRefinement)%compact) &
                                                                                , sumWeight = self%RefinedChain%Count(self%RefinedChain%numRefinement)%verbose &
                                                                                )
                end do

                ! report the refined chain statistics

                !formatStr = "(1A" // self%LogFile%maxColWidth%str // ",*(E" // self%LogFile%maxColWidth%str // "." // self%SpecBase%OutputRealPrecision%str // "))"

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.length"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_TABBED_FORMAT) self%Stats%Sample%count
                msg = "This is the final output refined sample size."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.avgStd"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,self%LogFile%format) "variableName", "Mean", "Standard Deviation"
                do i = 1, ndim
                    write(self%LogFile%unit,formatStrReal) trim(adjustl(self%SpecBase%VariableNameList%Val(i))), self%Stats%Sample%Mean(i), sqrt(self%Stats%Sample%CovMat(i,i))
                end do
                msg = "This is the Mean and standard deviation table of the final output refined sample."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.covmat"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,self%LogFile%format) "", (trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
                do i = 1, ndim
                    write(self%LogFile%unit,formatStrReal) trim(adjustl(self%SpecBase%VariableNameList%Val(i))), self%Stats%Sample%CovMat(1:ndim,i)
                end do
                msg = "This is the covariance matrix of the final output refined sample."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.cormat"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,self%LogFile%format) "", (trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
                do i = 1, ndim
                    write(self%LogFile%unit,formatStrReal) trim(adjustl(self%SpecBase%VariableNameList%Val(i))), self%Stats%Sample%CorMat(1:ndim,i)
                end do
                msg = "This is the correlation matrix of the final output refined sample."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.quantile"
                write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                write(self%LogFile%unit,self%LogFile%format) "Quantile", (trim(adjustl(self%SpecBase%VariableNameList%Val(i))),i=1,ndim)
                do iq = 1, QPROB%count
                    write(self%LogFile%unit,formatStrReal) trim(adjustl(QPROB%Name(iq))), (self%Stats%Sample%Quantile(iq,i),i=1,ndim)
                end do
                msg = "This is the quantiles table of the variables of the final output refined sample."
                call self%reportDesc(msg)

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ! Begin inter-chain convergence test in multiChain parallelization mode
                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#if defined CAF_ENABLED || defined MPI_ENABLED

                blockInterChainConvergence: if (self%SpecBase%ParallelizationModel%isMultiChain .and. self%Image%count>1_IK) then

                    call self%note  ( prefix            = self%brand        &
                                    , outputUnit        = self%LogFile%unit &
                                    , newline           = NLC               &
                                    , marginTop         = 1_IK              &
                                    , marginBot         = 1_IK              &
                                    , msg               = "Computing the inter-chain convergence probabilities..." )
                    if (self%Image%isFirst) then ! print the message on stdout
                        call self%note  ( prefix        = self%brand        &
                                        , outputUnit    = output_unit       &
                                        , newline       = NLC               &
                                        , marginTop     = 1_IK              &
                                        , marginBot     = 1_IK              &
                                        , msg           = "Computing the inter-chain convergence probabilities..." )
                    end if

#if defined CAF_ENABLED
                    sync all
#elif defined MPI_ENABLED
                    block
                        use mpi
                        integer :: ierrMPI
                        call mpi_barrier(mpi_comm_world,ierrMPI)
                    end block
#endif

                    ! read the sample files generated by other images

                    multiChainConvergenceTest: block

                        use Sort_mod, only: sortAscending
                        use String_mod, only: replaceStr
                        use Statistics_mod, only: doSortedKS2
                        use ParaDRAMRefinedChain_mod, only: readRefinedChain
                        type(RefinedChain_type)     :: RefinedChainThisImage, RefinedChainThatImage
                        integer(IK)                 :: imageID,indexMinProbKS,imageMinProbKS
                        real(RK)                    :: statKS, minProbKS
                        real(RK)    , allocatable   :: ProbKS(:)
                        character(:), allocatable   :: inputSamplePath

                        minProbKS = huge(minProbKS)
                        allocate(ProbKS(0:ndim))

                        ! read the refined chain on the current image

                        RefinedChainThisImage = readRefinedChain( sampleFilePath=self%SampleFile%Path%original, delimiter=self%SpecBase%OutputDelimiter%val, ndim=ndim )
                        if (RefinedChainThisImage%Err%occurred) then
                            self%Err%msg = PROCEDURE_NAME//RefinedChainThisImage%Err%msg
                            call self%abort( Err = self%Err, prefix = self%brand, newline = NLC, outputUnit = self%LogFile%unit )
                            return
                        end if

                        ! sort the refined chain on the current image

                        do i = 0, ndim
                            call sortAscending  ( np = RefinedChainThisImage%Count(RefinedChainThisImage%numRefinement)%verbose &
                                                , Point = RefinedChainThisImage%LogFuncState(1:RefinedChainThisImage%Count(RefinedChainThisImage%numRefinement)%verbose,i) &
                                                )
                        end do

                        ! compute and report the KS convergence probabilities for all images

                        formatStr = "(1I" // self%LogFile%maxColWidth%str // ",*(E" // self%LogFile%maxColWidth%str // "." // self%SpecBase%OutputRealPrecision%str // "))"

                        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                        write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                        write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.kstest.prob"
                        write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                        write(self%LogFile%unit,self%LogFile%format) "ProcessID",("probKS("//trim(adjustl(self%RefinedChain%ColHeader(i)%record))//")",i=0,ndim)

                        do imageID = 1, self%Image%count

                            if (imageID/=self%Image%id) then

                                ! read the refined chain on the other image

                                inputSamplePath = replaceStr( string = self%SampleFile%Path%original &
                                                            , search = "process_"//num2str(self%Image%id) &
                                                            , substitute = "process_"//num2str(imageID) )

                                RefinedChainThatImage = readRefinedChain( sampleFilePath=inputSamplePath, delimiter=self%SpecBase%OutputDelimiter%val, ndim=ndim )
                                if (RefinedChainThatImage%Err%occurred) then
                                    self%Err%msg = PROCEDURE_NAME//RefinedChainThatImage%Err%msg
                                    call self%abort( Err = self%Err, prefix = self%brand, newline = NLC, outputUnit = self%LogFile%unit )
                                    return
                                end if

                                do i = 0, ndim

                                    ! sort the refined chain on the other image

                                    call sortAscending  ( np = RefinedChainThatImage%Count(RefinedChainThatImage%numRefinement)%verbose &
                                                        , Point = RefinedChainThatImage%LogFuncState(1:RefinedChainThatImage%Count(RefinedChainThatImage%numRefinement)%verbose,i) &
                                                        )

                                    ! compute the inter-chain KS probability table

                                    call doSortedKS2( np1 = RefinedChainThisImage%Count(RefinedChainThisImage%numRefinement)%verbose &
                                                    , np2 = RefinedChainThatImage%Count(RefinedChainThatImage%numRefinement)%verbose &
                                                    , SortedPoint1 = RefinedChainThisImage%LogFuncState(1:RefinedChainThisImage%Count(RefinedChainThisImage%numRefinement)%verbose,i) &
                                                    , SortedPoint2 = RefinedChainThatImage%LogFuncState(1:RefinedChainThatImage%Count(RefinedChainThatImage%numRefinement)%verbose,i) &
                                                    , statKS = statKS &
                                                    , probKS = ProbKS(i) &
                                                    )

                                    ! determine the minimum KS

                                    if (ProbKS(i)<minProbKS) then
                                        minProbKS = ProbKS(i)
                                        indexMinProbKS = i
                                        imageMinProbKS = imageID
                                    end if

                                end do

                                ! write the inter-chain KS probability table row

                                write(self%LogFile%unit, formatStr) imageID, (ProbKS(i), i = 0, ndim)

                            end if

                        end do
                        msg =   "This is the table pairwise inter-chain Kolmogorov-Smirnov (KS) convergence (similarity) probabilities. &
                                &Higher KS probabilities are better, indicating less evidence for a lack of convergence."
                        call self%reportDesc(msg)

                        ! write the smallest KS probabilities

                        !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                        write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                        write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT) "stats.chain.refined.kstest.prob.min"
                        write(self%LogFile%unit,GENERIC_OUTPUT_FORMAT)
                        write(self%LogFile%unit,GENERIC_TABBED_FORMAT) minProbKS
                        msg =   "This is the smallest KS-test probability for the inter-chain sampling convergence, which has happened between "//self%RefinedChain%ColHeader(indexMinProbKS)%record// &
                                " on the chains generated by processes "//num2str(self%Image%id)//" and "//num2str(imageMinProbKS)//"."
                        call self%reportDesc(msg)

                        ! report the smallest KS probabilities on stdout

                        if (self%Image%isFirst) call self%note  ( prefix     = self%brand       &
                                                                , outputUnit = output_unit      &
                                                                , newline    = NLC              &
                                                                , marginTop  = 2_IK             &
                                                                , marginBot  = 0_IK             &
                                                                , msg        = "The smallest KS probabilities for the inter-chain sampling convergence:" )

                        do imageID = 1, self%Image%count
                            if (imageID==self%Image%id) then
                                call self%note  ( prefix     = self%brand       &
                                                , outputUnit = output_unit      &
                                                , newline    = NLC              &
                                                , marginTop  = 0_IK             &
                                                , marginBot  = 0_IK             &
                                                , msg        = num2str(minProbKS)//" for "//self%RefinedChain%ColHeader(indexMinProbKS)%record//&
                                                               " on the chains generated by processes "//num2str(self%Image%id)//&
                                                               " and "//num2str(imageMinProbKS)//"." )
                            end if
#if defined CAF_ENABLED
                            sync all
#elif defined MPI_ENABLED
                            block
                                use mpi
                                integer :: ierrMPI
                                call mpi_barrier(mpi_comm_world,ierrMPI)
                            end block
#endif
                        end do

                    end block multiChainConvergenceTest

                end if blockInterChainConvergence
#endif

                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ! End inter-chain convergence test in multiChain parallelization mode
                !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end if blockSampleFileGeneration

            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            ! End of generating the i.i.d. sample statistics and output file (if requested)
            !%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            call self%Decor%write(self%LogFile%unit,1,1)

            ! Mission accomplished.

            call self%note( prefix = self%brand, outputUnit = self%LogFile%unit, newline = "\n", msg = "Mission Accomplished." )
            if (output_unit/=self%LogFile%unit .and. self%Image%isFirst) then
                call self%Decor%write(output_unit,1,1)
                call self%note( prefix = self%brand, outputUnit = output_unit, newline = "\n", msg = "Mission Accomplished." )
                call self%Decor%write(output_unit,1,1)
            end if

            close(self%TimeFile%unit)
            close(self%LogFile%unit)

        end if blockMasterPostProcessing

        !nullify(self%Proposal)

#if defined CAF_ENABLED
        sync all
#elif defined MPI_ENABLED
        block
            use mpi
            integer :: ierrMPI
            call mpi_barrier(mpi_comm_world,ierrMPI)
            if (self%SpecBase%MpiFinalizeRequested%val) then
                call mpi_finalize(ierrMPI)
            end if
        end block
#endif

    end subroutine runSampler

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    module subroutine getSpecFromInputFile(self,nd)
#if defined DLL_ENABLED && !defined CFI_ENABLED
        !DEC$ ATTRIBUTES DLLEXPORT :: getSpecFromInputFile
#endif
        use Constants_mod, only: IK, RK
        use String_mod, only: num2str

        ! ParaMonte namelist variables
        use SpecBase_SampleSize_mod                         , only: sampleSize
        use SpecBase_RandomSeed_mod                         , only: randomSeed
        use SpecBase_Description_mod                        , only: description
        use SpecBase_OutputFileName_mod                     , only: outputFileName
        use SpecBase_OutputDelimiter_mod                    , only: outputDelimiter
        use SpecBase_ChainFileFormat_mod                    , only: chainFileFormat
        use SpecBase_VariableNameList_mod                   , only: variableNameList
        use SpecBase_RestartFileFormat_mod                  , only: restartFileFormat
        use SpecBase_OutputColumnWidth_mod                  , only: outputColumnWidth
        use SpecBase_OutputRealPrecision_mod                , only: outputRealPrecision
        use SpecBase_SilentModeRequested_mod                , only: silentModeRequested
        use SpecBase_DomainLowerLimitVec_mod                , only: domainLowerLimitVec
        use SpecBase_DomainUpperLimitVec_mod                , only: domainUpperLimitVec
        use SpecBase_ParallelizationModel_mod               , only: parallelizationModel
        use SpecBase_InputFileHasPriority_mod               , only: inputFileHasPriority
        use SpecBase_ProgressReportPeriod_mod               , only: progressReportPeriod
        use SpecBase_targetAcceptanceRate_mod               , only: targetAcceptanceRate
        use SpecBase_MpiFinalizeRequested_mod               , only: mpiFinalizeRequested
        use SpecBase_MaxNumDomainCheckToWarn_mod            , only: maxNumDomainCheckToWarn
        use SpecBase_MaxNumDomainCheckToStop_mod            , only: maxNumDomainCheckToStop
#if defined CFI_ENABLED
        use SpecBase_InterfaceType_mod                      , only: interfaceType
#endif

        ! ParaMCMC namelist variables
        use SpecMCMC_ChainSize_mod                          , only: chainSize
        use SpecMCMC_ScaleFactor_mod                        , only: scaleFactor
        use SpecMCMC_StartPointVec_mod                      , only: startPointVec
        use SpecMCMC_ProposalModel_mod                      , only: proposalModel
        use SpecMCMC_proposalStartCovMat_mod                , only: proposalStartCovMat
        use SpecMCMC_proposalStartCorMat_mod                , only: proposalStartCorMat
        use SpecMCMC_proposalStartStdVec_mod                , only: proposalStartStdVec
        use SpecMCMC_SampleRefinementCount_mod              , only: sampleRefinementCount
        use SpecMCMC_sampleRefinementMethod_mod             , only: sampleRefinementMethod
        use SpecMCMC_RandomStartPointRequested_mod          , only: randomStartPointRequested
        use SpecMCMC_RandomStartPointDomainLowerLimitVec_mod, only: randomStartPointDomainLowerLimitVec
        use SpecMCMC_RandomStartPointDomainUpperLimitVec_mod, only: randomStartPointDomainUpperLimitVec

        ! ParaDRAM namelist variables
        use SpecDRAM_AdaptiveUpdateCount_mod                , only: adaptiveUpdateCount
        use SpecDRAM_AdaptiveUpdatePeriod_mod               , only: adaptiveUpdatePeriod
        use SpecDRAM_greedyAdaptationCount_mod              , only: greedyAdaptationCount
        use SpecDRAM_DelayedRejectionCount_mod              , only: delayedRejectionCount
        use SpecDRAM_BurninAdaptationMeasure_mod            , only: burninAdaptationMeasure
        use SpecDRAM_delayedRejectionScaleFactorVec_mod     , only: delayedRejectionScaleFactorVec

        implicit none
        class(ParaDRAM_type), intent(inout) :: self
        integer(IK), intent(in)             :: nd
        character(*), parameter             :: PROCEDURE_NAME = SUBMODULE_NAME//"@getSpecFromInputFile()"

        ! ParaMonte variables
        namelist /ParaDRAM/ sampleSize
        namelist /ParaDRAM/ randomSeed
        namelist /ParaDRAM/ description
        namelist /ParaDRAM/ outputFileName
        namelist /ParaDRAM/ outputDelimiter
        namelist /ParaDRAM/ ChainFileFormat
        namelist /ParaDRAM/ variableNameList
        namelist /ParaDRAM/ restartFileFormat
        namelist /ParaDRAM/ outputColumnWidth
        namelist /ParaDRAM/ outputRealPrecision
        namelist /ParaDRAM/ silentModeRequested
        namelist /ParaDRAM/ domainLowerLimitVec
        namelist /ParaDRAM/ domainUpperLimitVec
        namelist /ParaDRAM/ parallelizationModel
        namelist /ParaDRAM/ progressReportPeriod
        namelist /ParaDRAM/ inputFileHasPriority
        namelist /ParaDRAM/ targetAcceptanceRate
        namelist /ParaDRAM/ mpiFinalizeRequested
        namelist /ParaDRAM/ maxNumDomainCheckToWarn
        namelist /ParaDRAM/ maxNumDomainCheckToStop
#if defined CFI_ENABLED
        namelist /ParaDRAM/ interfaceType
#endif

        ! ParaMCMC variables
        namelist /ParaDRAM/ chainSize
        namelist /ParaDRAM/ scaleFactor
        namelist /ParaDRAM/ startPointVec
        namelist /ParaDRAM/ proposalModel
        namelist /ParaDRAM/ proposalStartStdVec
        namelist /ParaDRAM/ proposalStartCorMat
        namelist /ParaDRAM/ proposalStartCovMat
        namelist /ParaDRAM/ sampleRefinementCount
        namelist /ParaDRAM/ sampleRefinementMethod
        namelist /ParaDRAM/ randomStartPointRequested
        namelist /ParaDRAM/ randomStartPointDomainLowerLimitVec
        namelist /ParaDRAM/ randomStartPointDomainUpperLimitVec

        ! ParaDRAM variables
        namelist /ParaDRAM/ adaptiveUpdateCount
        namelist /ParaDRAM/ adaptiveUpdatePeriod
        namelist /ParaDRAM/ greedyAdaptationCount
        namelist /ParaDRAM/ delayedRejectionCount
        namelist /ParaDRAM/ burninAdaptationMeasure
        namelist /ParaDRAM/ delayedRejectionScaleFactorVec

        ! initialize/nullify all general input options

        call self%SpecBase%nullifyNameListVar(nd)
        call self%SpecMCMC%nullifyNameListVar(nd)
        call self%SpecDRAM%nullifyNameListVar(nd)

        ! read input options if input file is provided

        blockReadInputFile: if (self%inputFileArgIsPresent) then

            blockInputFileType: if (self%InputFile%isInternal) then

                ! read input file as an internal file
#if defined DBG_ENABLED
                read(self%InputFile%Path%original,nml=ParaDRAM)
#else
                read(self%InputFile%Path%original,nml=ParaDRAM,iostat=self%InputFile%Err%stat)
                self%Err = self%InputFile%getReadErr(self%InputFile%Err%stat,self%InputFile%Path%modified)
                if (self%Err%occurred) then
                    if (is_iostat_end(self%Err%stat)) then
                        call self%warnUserAboutMissingNamelist(self%brand,self%name,"ParaDRAM",self%LogFile%unit)
                    else
                        self%Err%msg = PROCEDURE_NAME // self%Err%msg
                        return
                    end if
                end if
#endif

            else blockInputFileType ! the input file is external

                ! close input file if it is open

                if (self%InputFile%isOpen) then
                    close(unit=self%InputFile%unit,iostat=self%InputFile%Err%stat)
                    self%Err = self%InputFile%getCloseErr(self%InputFile%Err%stat)
                    if (self%Err%occurred) then
                        self%Err%msg =    PROCEDURE_NAME // ": Error occurred while attempting to close the user-provided input file='" // &
                                        self%InputFile%Path%modified // "', unit=" // num2str(self%InputFile%unit) // ".\n" // &
                                        self%Err%msg
                        return
                    end if
                end if

                ! open input file

                open( newunit = self%InputFile%unit       &
                    , file = self%InputFile%Path%modified &
                    , status = self%InputFile%status      &
                    , iostat = self%InputFile%Err%stat    &
#if defined IFORT_ENABLED && defined OS_IS_WINDOWS
                    , SHARED                            &
#endif
                    )
                self%Err = self%InputFile%getOpenErr(self%InputFile%Err%stat)
                if (self%Err%occurred) then
                    self%Err%msg =    PROCEDURE_NAME // ": Error occurred while attempting to open the user-provided input file='" // &
                                    self%InputFile%Path%modified // "', unit=" // num2str(self%InputFile%unit) // ".\n" // &
                                    self%Err%msg
                    return
                end if

                ! read input file

#if defined DBG_ENABLED
                read(self%InputFile%unit,nml=ParaDRAM)
#else
                read(self%InputFile%unit,nml=ParaDRAM,iostat=self%InputFile%Err%stat)
                self%Err = self%InputFile%getReadErr(self%InputFile%Err%stat,self%InputFile%Path%modified)
                if (self%Err%occurred) then
                    if (is_iostat_end(self%Err%stat)) then
                        call self%warnUserAboutMissingNamelist(self%brand,self%name,"ParaDRAM",self%LogFile%unit)
                    else
                        self%Err%msg = PROCEDURE_NAME // self%Err%msg
                        return
                    end if
                end if
#endif
                ! close input file

                close(unit=self%InputFile%unit,iostat=self%InputFile%Err%stat)
                self%Err = self%InputFile%getCloseErr(self%InputFile%Err%stat)
                if (self%Err%occurred) then
                    self%Err%msg =    PROCEDURE_NAME // ": Error occurred while attempting to close the user-provided input file='" // &
                                    self%InputFile%Path%modified // "', unit=" // num2str(self%InputFile%unit) // ".\n" // &
                                    self%Err%msg
                    return
                end if

            end if blockInputFileType

        end if blockReadInputFile

        ! setup SpecBase variables that have been read form the input file

        call self%SpecBase%setFromInputFile( Err = self%Err )
        if (self%Err%occurred) then
            self%Err%msg = PROCEDURE_NAME // self%Err%msg
            return
        end if

        ! setup SpecMCMC variables that have been read form the input file

        call self%SpecMCMC%setFromInputFile( Err = self%Err                                                 &
                                         , nd = nd                                                      &
                                         , domainLowerLimitVec = self%SpecBase%DomainLowerLimitVec%Val    &
                                         , domainUpperLimitVec = self%SpecBase%DomainUpperLimitVec%Val    )
        if (self%Err%occurred) then
            self%Err%msg = PROCEDURE_NAME // self%Err%msg
            return
        end if

        ! setup SpecDRAM variables that have been read form the input file

        call self%SpecDRAM%setFromInputFile( self%Err )
        if (self%Err%occurred) then
            self%Err%msg = PROCEDURE_NAME // self%Err%msg
            return
        end if

  end subroutine getSpecFromInputFile

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end submodule Setup_smod