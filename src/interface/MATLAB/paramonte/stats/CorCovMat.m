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
%   CorCovMat   ( dataFrame ...
%               , columns ...
%               , method ...
%               , rows ...
%               , Err ...
%               )
%
%   This is the CorCovMat class for generating objects
%   containing the computed correlation or covariance matrices of the input data.
%
%   NOTE: This is a low-level ParaMonte class and is not meant
%   NOTE: to be directly instantiated by the user.
%
%   Parameters
%   ----------
%
%       dataFrame
%
%           a MATLAB data Table from which the selected data will be plotted.
%           This is a low-level internal argument and is not meant
%           to be manipulated or be provided by the user.
%
%       columns
%
%           an array of strings or numbers corresponding to column names or indices 
%           of the input dataFrame for which the correlation/covariance matrix is computed.
%           This is a low-level internal argument and is not meant
%           to be accessed or be provided by the user.
%
%           If the input value is empty, the default will be the names of all columns 
%           of the input dataFrame.
%
%           Example usage:
%
%               1.  columns = [7,8,9]
%               2.  columns = ["SampleLogFunc","SampleVariable1"]
%               3.  columns = {"SampleLogFunc",9,"SampleVariable1"}
%               4.  columns = 7:9      # every column in the data frame starting from column #7 to #9
%               5.  columns = 7:2:20   # every other column in the data frame starting from column #7 to #20
%
%       method
%
%           a string or char vector with one of the following possible values:
%
%               "pearson"   : compute the Pearson's correlation matrix of the input data
%               "kendall"   : compute the Kendall's correlation matrix of the input data
%               "spearman"  : compute the Spearman's correlation matrix of the input data
%
%           If an empty object is provided as input, the covariance matrix 
%           of the input dataFrame will be computed for the selected columns.
%           This is a low-level internal argument and is not meant
%           to be accessed or be provided by the user.
%
%       rows
%
%           a numeric vector that represents the rows of the dataFrame that have been used or will be used 
%           to compute the correlation/covariance matrix. It can be either: 
%
%               1.  a numeric range, or, 
%               2.  a list of row indices of the dataFrame.
%
%           Example usage:
%
%               1.  rows = 10000:-2:3
%               2.  rows = [12,46,7,8,9,4,7,163]
%
%           If not provided, the default includes all rows of the input dataFrame.
%
%       Err
%
%           an object of class Err_class for error reporting and warnings.
%
%   Attributes
%   ----------
%
%       df
%
%           a MATLAB data Table that contains the computed correlation/covariance matrix of the input 
%           dataFrame (MATLAB Table). This is a low-level internal argument and is not meant
%           to be manipulated or be provided by the user.
%
%       columns
%
%           optional property that determines the columns of the dataFrame for which the 
%           correlation/covariance matrix must be computed. It can have multiple forms:
%
%               1.  a numeric or cell array of column indices in the input dataFrame.
%               2.  a string or cell array of column names in dataFrame.Properties.VariableNames.
%               3.  a cell array of a mix of the above two.
%               4.  a numeric range.
%
%           Example usage:
%
%               1.  columns = [7,8,9]
%               2.  columns = ["SampleLogFunc","SampleVariable1"]
%               3.  columns = {"SampleLogFunc",9,"SampleVariable1"}
%               4.  columns = 7:9      # every column in the data frame starting from column #7 to #9
%               5.  columns = 7:2:20   # every other column in the data frame starting from column #7 to #20
%
%           The default value is the names of all columns of the input dataFrame.
%
%       method (available only in correlation matrix objects)
%
%           a string or char vector with one of the following possible values:
%
%               "pearson"   : compute the Pearson's correlation matrix of the input data
%               "kendall"   : compute the Kendall's correlation matrix of the input data
%               "spearman"  : compute the Spearman's correlation matrix of the input data
%
%       rows
%
%           a numeric vector that represents the rows of the dataFrame that have been used or will be used 
%           to compute the correlation/covariance matrix. It can be either: 
%
%               1.  a numeric range, or, 
%               2.  a list of row indices of the dataFrame.
%
%           Example usage:
%
%               1.  rows = 15:-2:8
%               2.  rows = [12,46,7,8,9,4,7,163]
%
%           If not provided, the default includes all rows of the input dataFrame.
%
%       plot
%           a structure containing several plotting tools for visualization of the 
%           computed correlation/covariance matrix as reported in the component `df`.
%
%   Superclass Attributes
%   ----------------------
%
%       See the documentation for the BasePlot class
%
%   Returns
%   -------
%
%       an object of CorCovMat class
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef CorCovMat < dynamicprops

    properties(Access = public)
        columns
        rows
        df
    end

    properties(Hidden)
        cormatPrecision
        matrixType
        isCorMat
        dfref
        title
        Err
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods(Access=public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function self = CorCovMat   ( dataFrame ...
                                    , columns ...
                                    , method ...
                                    , rows ...
                                    , Err ...
                                    )
            self.Err = Err;
            self.dfref = dataFrame;
            self.columns = columns;
            self.cormatPrecision = 2;
            if ~isempty(method)
                prop="method"; if ~any(strcmp(properties(self),prop)); self.addprop(prop); end
                self.method = method;
            end
            self.columns = columns;
            self.rows = []; if ~isempty(rows); self.rows = rows; end
            self.df = [];

            prop="plot"; if ~any(strcmp(properties(self),prop)); self.addprop(prop); end
            self.plot = struct();
            self.plot.helpme = @self.helpme;

            self.get();

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function helpme(self,varargin)
            %
            %   Open the documentation for the input object's name in string format, otherwise, 
            %   open the documentation page for the class of the object owning the helpme() method.
            %
            %   Parameters
            %   ----------
            %
            %       This function takes at most one string argument, 
            %       which is the name of the object for which help is needed.
            %
            %   Returns
            %   -------
            %
            %       None. 
            %
            %   Example
            %   -------
            %
            %       helpme("plot")
            %
            methodNotFound = true;
            if nargin==2
                if contains(varargin{1},"reset")
                    cmd = "doc self.resetPlot";
                    methodNotFound = false;
                else
                    methodList = ["plot","helpme","get"];
                    for method = methodList
                        if strcmpi(varargin{1},method)
                            methodNotFound = false;
                            cmd = "doc self." + method;
                        end
                    end
                end
            elseif nargin~=1
                error("The helpme() method takes at most one argument that must be string.");
            end
            if methodNotFound
                cmd = "doc self";
            end
            eval(cmd);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function get(self,varargin)
            %
            %   Compute the correlation matrix of the selected columns of the object's dataFrame.
            %
            %   Parameters
            %   ----------
            %
            %       Any property,value pair of the object.
            %       If the property is a struct(), then its value must be given as a cell array,
            %       with consecutive elements representing the struct's property-name,property-value pairs.
            %       Note that all of these property-value pairs can be also directly set directly via the 
            %       object's attributes, before calling the plot() method.
            %
            %   Returns
            %   -------
            %
            %       None. However, this method causes side-effects by manipulating
            %       the existing attributes of the object.
            %
            %   Example
            %   -------
            %
            %       get("columns",[8,9,13]) % compute only for the column numbers 8, 9, 13 in the input dataFrame
            %       get("columns",7:10)     % compute only for the column numbers 7, 8, 9, 10 in the input dataFrame
            %       get("rows", 1:5:10000)  % refine the input data every other 5 points, then compute the quantities.
            %
            parseArgs(self,varargin{:});

            if isprop(self,"method")
                self.isCorMat = true;
                self.matrixType = "correlation";
                if ~any(strcmp(["pearson","kendall","spearman"],self.method))
                    error   ( newline ...
                            + "The requested correlation type must be one of the following string values, " + newline + newline ...
                            + "    pearson  : standard correlation coefficient" + newline ...
                            + "    kendall  : Kendall Tau correlation coefficient" + newline ...
                            + "    spearman : Spearman rank correlation." + newline ...
                            + newline ...
                            );
                end
            else
                self.isCorMat = false;
                self.matrixType = "covariance";
            end

            % check columns presence

            if getVecLen(self.columns)
                [colnames, ~] = getColNamesIndex(self.dfref.Properties.VariableNames,self.columns); % colindex
            else
                %colindex = 1:length(self.dfref.Properties.VariableNames);
                colnames = string(self.dfref.Properties.VariableNames);
            end

            % check rows presence

            if getVecLen(self.rows)
                rowindex = self.rows;
            else
                rowindex = 1:1:length(self.dfref{:,1});
            end

            % construct the matrix dataframe

            rowindexLen = length(rowindex);
            colnamesLen = length(colnames);
            if  rowindexLen > colnamesLen
                if  self.isCorMat
                    self.df = array2table( corr( self.dfref{rowindex,colnames} , "type" , self.method ) );
                else
                    self.df = array2table( cov( self.dfref{rowindex,colnames} ) );
                end
            else
                warning ( "The number of columns (" + string(colnamesLen) + ") is more than the number of rows (" + string(rowindexLen) + ") in the data-frame (Table). " ...
                        + "The " + self.matrixType + " matrix cannot be computed." ...
                        ...+ newline ...
                        );
                self.df = array2table( NaN(colnamesLen , colnamesLen) );
            end

            self.df.Properties.VariableNames = colnames;
            self.df.Properties.RowNames = colnames;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% graphics
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            for plotType = ["heatmap"]
                self.resetPlot(plotType,"hard");
            end
            self.plot.reset = @self.resetPlot;
            self.plot.heatmap.title = self.title;
            if self.isCorMat; self.plot.heatmap.precision = self.cormatPrecision; end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % set title for the heatmap

            if isempty(self.title)
                if self.isCorMat
                    self.title = "The " + self.method + "'s Correlation Strength Matrix";
                else
                    self.title = "The Covariance Matrix";
                end
            end
            try
                self.plot.heatmap.title = self.title;
                if self.isCorMat; self.plot.heatmap.precision = self.cormatPrecision; end
            end

        end % get

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Access = public, Hidden)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function resetPlot(self,varargin)
            %
            %   Reset the properties of the plot to the original default settings.
            %   Use this method when you change many attributes of the plot
            %   and you want to clean up
            %
            %   Parameters
            %   ----------
            %
            %       plotNames
            %
            %           An optional string or array of string values representing the names of plots to reset.
            %           If no value is provided, then all plots will be reset.
            %
            %       resetType
            %
            %           An optional string with possible value of "hard".
            %           If provided, the plot object will be regenerated from scratch.
            %           This includes reading the original data frame again and reseting everything.
            %
            %   Returns
            %   -------
            %
            %       None. 
            %
            %   Example
            %   -------
            %
            %       reset("heatmap") % reset line plot to the default dettings
            %       reset("heatmap","hard") % regenerate line plot from scratch
            %       reset("hard") % regenrate all plots from scratch
            %
            requestedPlotTypeList = [];
            plotTypeList = ["heatmap"];

            if nargin==1
                requestedPlotTypeList = plotTypeList;
            else
                for requestedPlotTypeCell = varargin{1}
                    if isa(requestedPlotTypeCell,"cell")
                        requestedPlotType = string(requestedPlotTypeCell{1});
                    else
                        requestedPlotType = string(requestedPlotTypeCell);
                    end
                    plotTypeNotFound = true;
                    for plotTypeCell = plotTypeList
                        plotType = string(plotTypeCell{1});
                        if strcmp(plotType,requestedPlotType)
                            requestedPlotTypeList = [ requestedPlotTypeList , plotType ];
                            plotTypeNotFound = false;
                            break;
                        end
                    end
                    if plotTypeNotFound
                        error   ( newline ...
                                + "The input plot-type argument, " + varargin{1} + ", to the resetPlot method" + newline ...
                                + "did not match any plot type. Possible plot types include:" + newline ...
                                + "line, lineScatter." + newline ...
                                );
                    end
                end
            end

            resetTypeIsHard = false;
            if nargin==3 && strcmpi(varargin{2},"hard")
                resetTypeIsHard = true;
                msgPrefix = "creating the ";
                msgSuffix = " plot object from scratch...";
            else
                msgPrefix = "reseting the properties of the ";
                msgSuffix = " plot...";
            end

            self.Err.marginTop = 0;
            self.Err.marginBot = 0;

            for requestedPlotTypeCell = requestedPlotTypeList

                self.Err.msg = msgPrefix + requestedPlotType + msgSuffix;
                self.Err.note();

                requestedPlotType = string(requestedPlotTypeCell);
                requestedPlotTypeLower = lower(requestedPlotType);
                plotName = "";

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % heatmap

                if strcmp(requestedPlotTypeLower,"heatmap")
                    plotName = "heatmap";
                    if resetTypeIsHard
                        self.plot.(plotName) = HeatmapPlot( self.df );
                    else
                        self.plot.(plotName).reset();
                    end
                    if self.isCorMat
                        self.plot.(plotName).heatmap_kws.ColorLimits = [-1 1];
                    end
                    self.plot.(plotName).xcolumns = self.df.Properties.VariableNames;
                    self.plot.(plotName).ycolumns = self.df.Properties.RowNames;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end % methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end