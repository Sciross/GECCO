classdef Run < handle
    properties
        Chunks
    end
    methods
        % Constructor
        function self = Run(Chunks,Model);
            if nargin~=0;
                self.Chunks = Chunks;
            end
        end
        
        %% Addition methods
        function AddChunk(self,Chunk);
            self.Chunks = [self.Chunks,Chunk];
        end
        
        function RemoveChunk(self,ChunkNumber);
            self.Chunks = [self.Chunks(1:ChunkNumber-1),self.Chunks(ChunkNumber+1:end)];
        end
        
        function AddPerturbation(self,PerturbWhat,WhatTo);
            self.Perturbations = [self.Perturbations;{PerturbWhat,WhatTo}];        
        end
        
        function self = AddRun(self,TimeIn,TimeOut,Model)
            self = [self,Run(Chunk(TimeIn,TimeOut))];
            Model.Conditions.AddConstants();
            Model.Conditions.AddInitials();
        end
        
        %%
        function Total = Count(self);
            for Run = 1:numel(self);
                ChunkNumber = numel(self(Run).Chunks);
                for Chunk = 1:ChunkNumber;
                    TimeOutN{Run}(Chunk) = numel(self(Run).Chunks(Chunk).TimeOut(1):self(Run).Chunks(Chunk).TimeOut(3):self(Run).Chunks(Chunk).TimeOut(2));
                end
                Total(Run) = sum(TimeOutN{Run});
            end
            TotalTotal = max(Total);
        end
    end
end