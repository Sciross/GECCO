classdef Carbon < matlab.mixin.Copyable & ParameterLoad
    properties
        Riverine_Carbon
        Riverine_Alkalinity
        Redfield_Ratio
        Production_Ratio
        
        PIC_Remineralisation
        PIC_Burial
        POC_Remineralisation
        POC_Burial
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