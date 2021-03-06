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
classdef SpecBase_RestartFileFormat_class < handle

    properties (Constant)
        CLASS_NAME                  = "@SpecBase_RestartFileFormat_class"
        MAX_LEN_RESTART_FILE_FORMAT = 63
    end

    properties
        isBinary                    = []
        isAscii                     = []
        binary                      = []
        ascii                       = []
        def                         = []
        val                         = ''
        desc                        = []
    end

%***********************************************************************************************************************************
%***********************************************************************************************************************************

    methods (Access = public)

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function self = SpecBase_RestartFileFormat_class(methodName)
            self.isBinary   = false;
            self.isAscii    = false;
            self.binary     = Constants.FILE_TYPE.binary;
            self.ascii      = Constants.FILE_TYPE.ascii;
            self.def        = self.ascii;

            self.desc       = "restartFileFormat is a string variable that represents the format of the output restart file(s) which are used to restart "  ...
                            + "an interrupted " + methodName + " simulation. The string value must be enclosed by either single or double quotation "       ...
                            + "marks when provided as input. Two values are possible:" + newline + newline                                                  ...
                            + "    restartFileFormat = '" + self.binary + "'" + newline + newline                                                           ...
                            + "            This is the binary file format which is not human-readable, but preserves the exact values of the "              ...
                            + "specification variables required for the simulation restart. This full accuracy representation is required "                 ...
                            + "to exactly reproduce an interrupted simulation. The binary format is also normally the fastest mode of restart file "        ...
                            + "generation. Binary restart files will have the " + Constants.FILE_EXT.binary + " file extensions." + newline + newline       ...
                            + "    restartFileFormat = '" + self.ascii + "'" + newline + newline                                                            ...
                            + "            This is the ASCII (text) file format which is human-readable but does not preserve the full accuracy of "        ...
                            + "the specification variables required for the simulation restart. It is also a significantly slower mode of "                 ...
                            + "restart file generation, compared to the binary format. Therefore, its usage should be limited to situations where "         ...
                            + "the user wants to track the dynamics of simulation specifications throughout the simulation time. "                          ...
                            + "ASCII restart file(s) will have the " + Constants.FILE_EXT.ascii + " file extensions." + newline + newline                   ...
                            + "The default value is restartFileFormat = '" + self.def + "'. Note that the input values are case-insensitive."               ...
                            ;
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function set(self, restartFileFormat)

            if isempty(restartFileFormat)
                self.val = strtrim(self.def);
            else
                self.val = strtrim(restartFileFormat);
            end

            if lower(self.val) == lower(self.binary),   self.isBinary   = true; end
            if lower(self.val) == lower(self.ascii),    self.isAscii    = true; end

        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function Err = checkForSanity(self, Err, methodName)
            FUNCTION_NAME = "@checkForSanity()";
            if ~(self.isBinary || self.isAscii)
                Err.occurred    = true;
                Err.msg         = Err.msg                                                                                   ...
                                + self.CLASS_NAME + FUNCTION_NAME + ": Error occurred. "                                    ...
                                + "The input requested restart file format ('" + self.val                                   ...
                                + "') represented by the variable restartFileFormat cannot be set to anything other than '" ...
                                + char(self.binary) + "' or '" + char(self.ascii) + "'. If you don't know an appropriate "  ...
                                + "value for RestartFileFormat, drop it from the input list. " + methodName                 ...
                                + " will automatically assign an appropriate value to it." + newline + newline              ...
                                ;
            end
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

    end

%***********************************************************************************************************************************
%***********************************************************************************************************************************

end