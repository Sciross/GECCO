classdef Ice < matlab.mixin.Copyable & ParameterLoad
    properties
        Angle
        Density
        Growth_Rate
        Melt_Rate
        Water_Density
        Water_Molar_Mass
        Snow_Line_Sensitivity
        Sea_Level_Forcing
    end
    methods
        function self = Ice(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineIceParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end        
    end
end