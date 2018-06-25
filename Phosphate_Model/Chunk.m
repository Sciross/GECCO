classdef Chunk < handle
    properties
        TimeIn
        TimeOut
        Perturbations
    end
    methods
        function self = Chunk(TimeIn,TimeOut,Initial);
            self.TimeIn = TimeIn;
            self.TimeOut = TimeOut;
        end
    end
end