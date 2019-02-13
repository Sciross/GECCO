classdef Energy < matlab.mixin.Copyable & ParameterLoad
    properties
        Radiative_Sensitivity
        Climate_Sensitivity
        Solar_Constant
        Albedo
        Emissivity
        Stefan_Boltzmann
        Ocean_Temperature_Offset
        Atmosphere_Equilibration_Timescale
        Ocean_Equilibration_Timescale
    end
    methods
        function self = Energy(Empty_Cell_Flag); 
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineEnergyParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
    end
end