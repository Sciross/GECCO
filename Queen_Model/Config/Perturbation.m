classdef Perturbation < Parameter
    properties
        Output = Output();
    end
    properties (Hidden=true)
        Matrix = {};
    end
    methods
        function self = Perturbation();
            Shallow_Properties = properties(self);
            for Shallow_Index = 1:numel(Shallow_Properties);
                Deep_Properties = properties(self.(Shallow_Properties{Shallow_Index}));
                for Deep_Index = 1:numel(Deep_Properties);
                    self.(Shallow_Properties{Shallow_Index}).(Deep_Properties{Deep_Index}) = {};
                end
            end
        end
        function DealMatrix(self);
            for Perturbation_Index = 1:size(self.Matrix,1);
                self.(self.Matrix{Perturbation_Index,3}).(self.Matrix{Perturbation_Index,4}) = [self.Matrix(1),self.Matrix(4),self.Matrix(5)];
            end
        end
        function UndealMatrix(self);
            Matrix = [];
            Shallow_Properties = properties(self);
            for Shallow_Index = 1:numel(Shallow_Properties);
                Deep_Properties = properties(self.(Shallow_Properties{Shallow_Index}));
                for Deep_Index = 1:numel(Deep_Properties);
                    if ~isempty(self.(Shallow_Properties{Shallow_Index}).(Deep_Properties{Deep_Index}));
                        Matrix = [Matrix;self.(Shallow_Properties{Shallow_Index}).(Deep_Properties{Deep_Index})];
                    end
                end
            end
            self.Matrix = Matrix;
        end
    end
end