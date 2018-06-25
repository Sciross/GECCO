classdef Architecture < matlab.mixin.Copyable & ParameterLoad
    properties
        Atmosphere_Volume        
        Riverine_Volume
        Ocean_Depths
        Ocean_Midpoints
        Ocean_Area
        Ocean_Volumes
        Mixing_Coefficient
        Hypsometric_Interpolation_Matrix
        Hypsometry
        Cumulative_Hypsometry
        Hypsometric_Bin_Midpoints
    end
    methods
        function self = Architecture(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineArchitectureParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
    end
end