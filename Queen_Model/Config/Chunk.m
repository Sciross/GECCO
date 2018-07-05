classdef Chunk < handle
    properties
        Time_In
        Time_Out
        Perturbations
    end
    methods
        function self = Chunk(Time_In,Time_Out);
            if nargin>1;
                self.Time_In = Time_In;
                self.Time_Out = Time_Out;
            else
                self.Time_In = [0,1e6,20];
                self.Time_Out = [0,1e6,100];
            end
        end
        function AddPerturbation(self,PerturbWhat,Number,WhatTo);
            self.Perturbations = [self.Perturbations;{PerturbWhat,Number,WhatTo}];
        end
    end
end