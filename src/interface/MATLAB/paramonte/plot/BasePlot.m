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
%   BasePlot(varargin)
%
%   This is the class for generating instances of 
%   basic plots with minimally one (X)-axis. It serves as the 
%   superclass for a wide variety of other multi-axes ParaMonte plots.
%
%   Parameters
%   ----------
%
%       The number of input parameters is variable. This is a low-level ParaMonte class
%       and the user is not supposed to directly instantiate objects of this type.
%
%   Attributes
%   ----------
%
%       dfref
%
%           A reference to the input dataFrame whose data is used to generate plots.
%           Despite its name (dfref: reference to dataFrame), this attribute is not
%           a reference to the original input dataFrame but a deep copy of it.
%           Therefore, changing its values will change the corresponding values 
%           in the original dataFrame. 
%
%       xcolumns
%
%           optional property that determines the columns of dataFrame to serve as 
%           the x-values. It can have multiple forms:
%
%               1.  a numeric or cell array of column indices in the input dataFrame.
%               2.  a string or cell array of column names in dataFrame.Properties.VariableNames.
%               3.  a cell array of a mix of the above two.
%               4.  a numeric range.
%
%           Example usage:
%
%               1.  xcolumns = [7,8,9]
%               2.  xcolumns = ["SampleLogFunc","SampleVariable1"]
%               3.  xcolumns = {"SampleLogFunc",9,"SampleVariable1"}
%               4.  xcolumns = 7:9      # every column in the data frame starting from column #7 to #9
%               5.  xcolumns = 7:2:20   # every other column in the data frame starting from column #7 to #20
%
%           WARNING: In all cases, xcolumns must have a length that is either 0, or 1, or equal 
%           WARNING: to the length of ycolumns. If the length is 1, then xcolumns will be 
%           WARNING: plotted against data corresponding to each element of ycolumns.
%           WARNING: If it is an empty object having length 0, then the default value will be used.
%
%           The default value is the indices of the rows of the input dataFrame.
%
%       rows
%
%           a numeric vector that determines the rows of dataFrame 
%           to be visualized. It can be either:
%
%               1.  a numeric range, or, 
%               2.  a list of row indices of the dataFrame.
%
%           Example usage:
%
%               1.  rows = 15:-2:8
%               2.  rows = [12,46,7,8,9,4,7,163]
%
%           If not provided, the default includes all rows of the dataFrame.
%
%       gca_kws
%
%           A MATLAB struct() whose fields are directly passed to the current axis in the figure. 
%           This is done by calling set(gca,gca_kws{:}). For example: 
%
%           Example usage:
%
%               gca_kws.xscale = "log";
%
%           If a desired property is missing among the struct fields, simply add the field
%           and its value to gca_kws.
%
%           WARNING: keep in mind that MATLAB keyword arguments are case-INsensitive.
%           WARNING: therefore make sure you do not add the keyword as multiple different fields.
%           WARNING: gca_kws.xscale and gca_kws.Xscale are the same, 
%           WARNING: and only one of the two will be processed.
%
%       gcf_kws
%
%           A MATLAB struct() whose fields 
%           (with the exception of few, e.g., enabled, singleOptions, ...) 
%           are directly passed to the figure function of MATLAB. 
%
%           Example usage:
%
%               gcf_kws.enabled = false; % do not make new plot
%               gcf_kws.color = "none"; % set the background color to none (transparent)
%
%           If a desired property is missing among the struct fields, simply add the field
%           and its value to gcf_kws.
%
%           WARNING: keep in mind that MATLAB keyword arguments are case-INsensitive.
%           WARNING: therefore make sure you do not add the keyword as multiple different fields.
%           WARNING: gcf_kws.color and gcf_kws.Color are the same, 
%           WARNING: and only one of the two will be processed.
%
%       legend_kws
%
%           A MATLAB struct() whose components' values are passed to MATLAB's legend() function.
%           If your desired attribute is missing from the fieldnames of legend_kws, simply add
%           a new field named as the attribute and assign the desired value to it.
%
%           Example usage:
%
%               legend_kws.enabled = true; % add legend
%               legend_kws.labels = ["this object","that object"]; % legend labels
%
%           NOTE: A legend will be added to plot only if simple plots with no 
%           NOTE: colormap are requested.
%
%           NOTE: If no legend labels is provided and legend is enabled, the names 
%           NOTE: of the columns of the dataFrame will be used.
%
%           WARNING: keep in mind that MATLAB keyword arguments are case-INsensitive.
%           WARNING: therefore make sure you do not add the keyword as multiple different fields.
%           WARNING: legend_kws.color and legend_kws.Color are the same, 
%           WARNING: and only one of the two will be processed.
%
%       currentFig
%
%           A MATLAB struct() whose fields are the outputs of various plotting tools 
%           used to make the current figure. These include the handle to the current figure (gcf), 
%           the handle to the current axes in the plot (gca), the handle to colorbar (if any exists), 
%           and other MATLAB plotting tools used to make to generate the figure.
%
%       outputFile
%
%           optional string representing the name of the output file in which 
%           the figure will be saved. If not provided (is empty), 
%           no output file will be generated.
%
%   Returns
%   -------
%
%       an object of BasePlot class
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
classdef BasePlot < dynamicprops

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Access = public)

        dfref = [];
        gcf_kws
        currentFig
        outputFile

    end

    properties (Access = protected, Hidden)
        isdryrun = [];
    end

    properties (Access = private)
        isHeatmap
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Access = public)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function self = BasePlot(varargin)

            try
                self.dfref = varargin{1};
            catch
                self.dfref = [];
            end
            self.isHeatmap = false;
            if (nargin==2 && strcmp(varargin{2},"heatmap"))
                self.isHeatmap = true;
            else
                prop="rows"; if ~any(strcmp(properties(self),prop)); self.addprop(prop); end
                prop="gca_kws"; if ~any(strcmp(properties(self),prop)); self.addprop(prop); end
                prop="legend_kws"; if ~any(strcmp(properties(self),prop)); self.addprop(prop); end
            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function exportFig(self,varargin)

            set(0, "CurrentFigure", self.currentFig.gcf);
            if any(contains(string(varargin),"-transparent"))
                transparencyRequested = true;
                try
                    set(self.currentFig.gcf,"color","none");
                catch
                    warning("failed to set the color property of gcf to ""none"".");
                end
                try
                    set(gca,"color","none");
                catch
                    warning("failed to set the color property of gca to ""none"".");
                end
            else
                transparencyRequested = false;
            end
            %for i = 1:length(varargin)
            %    if contains(varargin{i},"-transparent")
            %        transparencyRequested = true;
            %        set(self.currentFig.gcf,"color","none");
            %        set(gca,"color","none");
            %    end
            %    if isa(varargin{i},"string")
            %        varargin{i} = convertStringsToChars(varargin{i});
            %    end
            %end
            export_fig(varargin{:});
            if transparencyRequested
                try
                    set(self.currentFig.gcf,"color","default");
                catch
                    warning("failed to set the color property of gcf back to ""default"".");
                end
                try
                    set(gca,"color","default");
                catch
                    warning("failed to set the color property of gca back to ""default"".");
                end
            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function helpme(self,varargin)
            if nargin==1
                doc BasePlot;
            else
                error("The helpme() method takes no input arguments.")
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end % methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Access=public,Hidden)

        function reset(self)

            if ~self.isHeatmap

                self.rows = {};

                self.legend_kws = struct();
                self.legend_kws.box = "off";
                self.legend_kws.labels = {};
                self.legend_kws.enabled = true;
                self.legend_kws.fontsize = [];
                self.legend_kws.location = "best";
                self.legend_kws.interpreter = "none";
                self.legend_kws.singleOptions = {};

                self.gca_kws = struct();
                self.gca_kws.xscale = "linear";
                self.gca_kws.yscale = "linear";

            end

            self.gcf_kws = struct();
            self.currentFig = struct();
            self.outputFile = [];

            self.gcf_kws.enabled = true;

        end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Hidden)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function parseArgs(self,varargin)

            vararginLen = length(varargin);
            selfProperties = properties(self);
            selfPropertiesLen = length(selfProperties);

            for i = 1:2:vararginLen
                propertyDoesNotExist = true;
                vararginString = string(varargin{i});
                for ip = 1:selfPropertiesLen
                    if strcmp(vararginString,string(selfProperties(ip)))
                        propertyDoesNotExist = false;
                        if i < vararginLen
                            if isa(self.(selfProperties{ip}),"struct") && isa(varargin{i+1},"cell")
                                self.(selfProperties{ip}) = parseArgs( self.(selfProperties{ip}) , varargin{i+1}{:} );
                            else
                                self.(selfProperties{ip}) = varargin{i+1};
                            end
                        else
                            error("The corresponding value for the property """ + string(selfProperties{ip}) + """ is missing as input argument.");
                        end
                        break;
                    end
                end
                if propertyDoesNotExist
                    error("The requested property """ + string(varargin{i}) + """ does not exist.");
                end
            end

        end

        % function parseArgs(self,varargin)

            % vararginLen = length(varargin);
            % for i = 1:2:vararginLen
                % propertyDoesNotExist = true;
                % selfProperties = properties(self);
                % selfPropertiesLen = length(selfProperties);
                % for ip = 1:selfPropertiesLen
                    % if strcmp(string(varargin{i}),string(selfProperties{ip}))
                        % propertyDoesNotExist = false;
                        % if i < vararginLen
                            % self.(selfProperties{ip}) = varargin{i+1};
                        % else
                            % error("The corresponding value for the property """ + string(selfProperties{ip}) + """ is missing as input argument.");
                        % end
                        % break;
                    % end
                % end
                % if propertyDoesNotExist
                    % error("The requested the property """ + string(varargin{i}) + """ does not exist.");
                % end
            % end

        % end % function parseArgs

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function doBasePlotStuff(self, lgEnabled, lglabels)

            if ~self.isHeatmap

                % add legend

                if lgEnabled
                    if isa(self.legend_kws.labels,"cell") || isa(self.legend_kws.labels,"string")
                        if getVecLen(self.legend_kws.labels)~=length(lglabels)
                            self.legend_kws.labels = {lglabels{:}};
                        end
                        if isempty(self.legend_kws.fontsize)
                            self.legend_kws.fontsize = self.currentFig.xlabel.FontSize;
                        end
                        legend_kws_cell = convertStruct2Cell(self.legend_kws,{"enabled","singleOptions","labels"});
                        self.currentFig.legend = legend(self.legend_kws.labels{:},legend_kws_cell{:},self.legend_kws.singleOptions{:});
                    else
                        error   ( newline ...
                                + "The input ""legend_kws.labels"" must be a cell array of string values." ...
                                + newline ...
                                );
                    end
                else
                    legend(self.currentFig.gca,"off");
                end

                if ~isempty(self.gca_kws)
                    gca_kws_cell = convertStruct2Cell(self.gca_kws,{"enabled","singleOptions","labels"});
                    if isfield(self.gca_kws,"singleOptions"); gca_kws_cell = { gca_kws_cell{:}, self.gca_kws.singleOptions{:} }; end
                    set(gca, gca_kws_cell{:});
                end

            end

            if isa(self.outputFile,"string") || isa(self.outputFile,"char")
                self.exportFig(self.outputFile,"-m2 -transparent");
            end

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end % methods (Access = private)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end % classdef BasePlot < dynamicprops