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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SpecDRAM specification type-checking class
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef SpecDRAMVerify < SpecVerification

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

    properties(Access=public,Hidden)
        delayedRejectionCountVal = [];
    end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

    methods (Access = public)

        function self = SpecDRAMVerify(objectName,ndim)
            self.objectName = objectName;
            self.ndim = ndim;
        end

        function result = adaptiveUpdateCount(self,adaptiveUpdateCount)
            result = self.verifySpec(adaptiveUpdateCount,"integer",1);
        end

        function result = adaptiveUpdatePeriod(self,adaptiveUpdatePeriod)
            result = self.verifySpec(adaptiveUpdatePeriod,"integer",1);
        end

        function result = greedyAdaptationCount(self,greedyAdaptationCount)
            result = self.verifySpec(greedyAdaptationCount,"integer",1);
        end

        function result = delayedRejectionCount(self,delayedRejectionCount)
            result = self.verifySpec(delayedRejectionCount,"integer",1);
            self.delayedRejectionCountVal = delayedRejectionCount;
        end

        function result = burninAdaptationMeasure(self,burninAdaptationMeasure)
            result = self.verifySpec(burninAdaptationMeasure,"integer",1);
        end

        function result = delayedRejectionScaleFactorVec(self,delayedRejectionScaleFactorVec)
            result = self.verifySpec(delayedRejectionScaleFactorVec,"real",self.delayedRejectionCountVal);
        end

    end % methods (dynamic)

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

end % classdef SpecDRAMVerify