classdef Carbon < matlab.mixin.Copyable & ParameterLoad
    properties
        Riverine_Carbon
        Riverine_Alkalinity
        Redfield_Ratio
        Production_Ratio
        Calcifier_Fraction
        
        PIC_Neritic_Remineralisation
        PIC_Pelagic_Remineralisation
        PIC_Neritic_Burial
        PIC_Pelagic_Burial
        
        POC_Neritic_Remineralisation
        POC_Pelagic_Remineralisation
        POC_Neritic_Burial
        POC_Pelagic_Burial
        POC_Burial_Maximum_Depth
        
    end    
    methods
        function self = Carbon(Empty_Cell_Flag)
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineCarbonParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end        
    end
end