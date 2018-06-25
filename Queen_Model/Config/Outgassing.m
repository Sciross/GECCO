classdef Outgassing < matlab.mixin.Copyable & ParameterLoad
    properties
        Mean_Lag
        Spread        
        Temporal_Resolution
        Gauss
    end
    methods
        function self = Outgassing(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineOutgassingParameters(self);                
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
    end
end