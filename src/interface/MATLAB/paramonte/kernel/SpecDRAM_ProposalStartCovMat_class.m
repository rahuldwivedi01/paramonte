%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   ParaMonte: plain powerful parallel Monte Carlo library.
%
%   Copyright (C) 2012-present, The Computational Data Science Lab
%
%   This file is part of the ParaMonte library.
%
%   ParaMonte is free software: you can redistribute it and/or modify it 
%   under the terms of the GNU Lesser General Public License as published 
%   by the Free Software Foundation, version 3 of the License.
%
%   ParaMonte is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU Lesser General Public License for more details.
%
%   You should have received a copy of the GNU Lesser General Public License
%   along with the ParaMonte library. If not, see, 
%
%       https://github.com/cdslaborg/paramonte/blob/master/LICENSE
%
%   ACKNOWLEDGMENT
%
%   As per the ParaMonte library license agreement terms, 
%   if you use any parts of this library for any purposes, 
%   we ask you to acknowledge the use of the ParaMonte library
%   in your work (education/research/industry/development/...)
%   by citing the ParaMonte library as described on this page:
%
%       https://github.com/cdslaborg/paramonte/blob/master/ACKNOWLEDGMENT.md
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef SpecDRAM_ProposalStartCovMat_class < handle

    properties (Constant)
        CLASS_NAME  = "@SpecDRAM_ProposalStartCovMat_class"
    end

    properties
        isPresent   = []
        Val         = []
        Def         = []
        desc        = []
    end

%***********************************************************************************************************************************
%***********************************************************************************************************************************

    methods (Access = public)

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function self = SpecDRAM_ProposalStartCovMat_class(nd, methodName)
            self.isPresent  = false;
            self.Def        = eye(nd, nd);
            self.desc       = "ProposalStartCovMat is a real-valued positive-definite matrix of size (ndim,ndim), where ndim is the dimension of the "                  ...
                            + "sampling space. It serves as the best-guess starting covariance matrix of the proposal distribution. "                                   ...
                            + "To bring the sampling efficiency of " + methodName + " to within the desired requested range, the covariance matrix "                    ...
                            + "will be adaptively updated throughout the simulation, according to the user's requested schedule. If ProposalStartCovMat is not "        ...
                            + "provided by the user, its value will be automatically computed from the input variables ProposalStartCorMat and ProposalStartStdVec. "   ...
                            + "The default value of ProposalStartCovMat is an ndim-by-ndim Identity matrix."                                                            ...
                            ;
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function set(self, ProposalStartCovMat)
            if isempty(ProposalStartCovMat)
                self.Val        = self.Def;
            else
                self.Val        = ProposalStartCovMat;
                self.isPresent  = true;
            end
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function Err = checkForSanity(self, Err, methodName, nd)
            FUNCTION_NAME   = "@checkForSanity()";

            [~,dummy]       = chol(self.Val(1:nd,1:nd));
            isPosDef        = ~dummy;
            if ~isPosDef
                Err.occurred    = true;
                Err.msg         = Err.msg                                                                       ...
                                + self.CLASS_NAME + FUNCTION_NAME + ": Error occurred. "                        ...
                                + "The input requested proposalStartCovMat for the proposal of " + methodName   ...
                                + " is not a positive-definite matrix." + newline + newline                     ...
                                ;
            end
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

    end

%***********************************************************************************************************************************
%***********************************************************************************************************************************

end