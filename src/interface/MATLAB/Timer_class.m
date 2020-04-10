classdef Timer_class < handle

    properties (Constant)
        CLASS_NAME  = "@Timer_class"
    end

    properties
        delta       = []
        total       = []
        newTotal    = []
    end

%***********************************************************************************************************************************
%***********************************************************************************************************************************

    methods (Access = public)

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function tic(self)
            tic();
            self.total      = toc();
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

        function toc(self)
            self.newTotal   = toc();
            self.delta      = self.newTotal - self.total;
            self.total      = self.newTotal;
        end

    %*******************************************************************************************************************************
    %*******************************************************************************************************************************

    end

%***********************************************************************************************************************************
%***********************************************************************************************************************************

end