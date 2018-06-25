classdef Chunk < handle
    properties
        TimeIn
        TimeOut
        Perturbations
    end
    methods
        function self = Chunk(TimeIn,TimeOut);
            self.TimeIn = TimeIn;
            self.TimeOut = TimeOut;
        end
        function AddPerturbation(self,PerturbWhat,Number,WhatTo);
            self.Perturbations = [self.Perturbations;{PerturbWhat,Number,WhatTo}];
        end
    end
end