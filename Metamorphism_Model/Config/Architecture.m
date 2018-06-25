classdef Architecture < matlab.mixin.Copyable
    properties
        BoxDepths
        BoxArea
        TotalBoxes
        Volumes
        Midpoints
    end
    methods
        function self = Architecture(BoxDepths,Area)
            if nargin~=0;
                self.BoxArea = Area;
                self.BoxDepths = BoxDepths;
            else
                self.BoxArea = 362e12;
                self.BoxDepths = [500;3200];
            end
            self.TotalBoxes = numel(self.BoxDepths);
            self.Volumes = self.BoxArea.*self.BoxDepths;
            self.Midpoints = [self.BoxDepths./2]-[0;self.BoxDepths(1)/2];
        end
    end
end