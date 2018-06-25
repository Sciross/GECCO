classdef Chunk < handle
    properties
        TimeIn
        TimeOut
        Perturbations
    end
    methods
        function self = Chunk(TimeIn,TimeOut);
            if nargin>1;
                self.TimeIn = TimeIn;
                self.TimeOut = TimeOut;
            else
                self.TimeIn = [0,1e6,20];
                self.TimeOut = [0,1e6,100];
            end
        end
        function AddPerturbation(self,PerturbWhat,Number,WhatTo);
            self.Perturbations = [self.Perturbations;{PerturbWhat,Number,WhatTo}];
        end
    end
end