classdef Run < handle
    properties
%         Constant
        Chunks
        Perturbations
    end
    methods
        function self = Run(Chunks);
            if nargin~=0;
                self.Chunks = Chunks;
            end
%             
%             self.Constant = DefinePhysicalConstants_OO(self.Constant);
%             self.Constant = DefineBiologicalConstants_OO(self.Constant);
        end
        function self = AddChunk(self,Chunk);
            self.Chunks = [self.Chunks,Chunk];
        end
        function self = RemoveChunk(self,ChunkNumber);
            self.Chunks = [self.Chunks(1:ChunkNumber-1),self.Chunks(ChunkNumber+1:end)];
        end
    end
end