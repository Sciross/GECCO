classdef Seafloor < matlab.mixin.Copyable & ParameterLoad
    properties
        Subduction_Mean
        Subduction_Spread
        Subduction_Rate
        Subduction_Risk
        Subduction_Gauss
        Uplift_Rate
        Core_Depths
    end
    methods
        function self = Seafloor(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineSeafloorParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
    end
end