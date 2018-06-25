classdef GECCO < handle
    properties
        Architectures
        Runs
        MixingMatrix
    end
    methods
        function self = GECCO(Architectures,Runs)
            if nargin~=0;
                self.Architectures = Architectures;
                self.Runs = Runs;
            end
        end
        function self = AddRun(self,Run);
            self.Runs = [self.Runs,Run];
        end
        function self = AddArchitecture(self,Architecture);
            self.Architectures = [self.Architectures,Architecture];
        end
        function CleanMixingMatrix(self);
            MaxBoxNumber = max(self.Architectures.TotalBoxes);
            self.MixingMatrix = NaN(numel(self.Architectures),MaxBoxNumber,numel(self.Architectures),MaxBoxNumber);
            for n = 1:numel(self.Architectures);
                self.MixingMatrix(n,1:self.Architectures(n).TotalBoxes,:,:) = 0;
            end
        end
        function AddMixing(self,Mixing);
%             if isnan(self.MixingMatrix(Mixing(1),Mixing(2),Mixing(3),Mixing(4)));
%                 error('Box does not exist');
%             else
%                 self.MixingMatrix(Mixing(1),Mixing(2),Mixing(3),Mixing(4)) = Mixing(5);
%             end
            self.MixingMatrix = [self.MixingMatrix;Mixing(1:5)];
        end
    end
end