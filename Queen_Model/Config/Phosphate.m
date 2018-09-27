classdef Phosphate < matlab.mixin.Copyable & ParameterLoad
    properties
        Riverine_Concentration        
        Maximum_Growth_Rate
        Mortality
        Biological_Half_Constant
        Algal_Slowing_Factor
        Neritic_Remineralisation
        Pelagic_Remineralisation
        Productivity_Split
        Proportionality_To_Silicate
    end    
    methods
        function self = Phosphate(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefinePhosphateParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
    end
end