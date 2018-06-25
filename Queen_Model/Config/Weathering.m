classdef Weathering < matlab.mixin.Copyable & ParameterLoad
    properties
        Silicate_Replenishment
        Silicate_Replacement
        Silicate_Weathering_Coefficients
        Carbonate_Weathering_Coefficients
        Silicate_Weatherability
        Carbonate_Weatherability
        Carbonate_Exposure
    end
    methods
        function self = Weathering(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineWeatheringParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
    end
end