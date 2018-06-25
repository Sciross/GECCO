classdef Transient < Parameter
    properties
    end
    properties (Hidden=true)
        Matrix = {};
    end
    methods
        function self = Transient();
            Shallow_Properties = properties(self);
            for Shallow_Index = 1:numel(Shallow_Properties);
                Deep_Properties = properties(self.(Shallow_Properties{Shallow_Index}));
                for Deep_Index = 1:numel(Deep_Properties);
                    self.(Shallow_Properties{Shallow_Index}).(Deep_Properties{Deep_Index}) = {};
                end
            end
        end
        function DealMatrix(self);
            for Transient_Index = 1:size(self.Matrix,1);
                self.(self.Matrix{Transient_Index,2}).(self.Matrix{Transient_Index,3}) = [self.Matrix(1),self.Matrix(4),self.Matrix(5)];
            end
        end
        function UndealMatrix(self);
            Transient_Matrix = [];
            Shallow_Properties = properties(self);
            for Shallow_Index = 1:numel(Shallow_Properties);
                Deep_Properties = properties(self.(Shallow_Properties{Shallow_Index}));
                for Deep_Index = 1:numel(Deep_Properties);
                    if ~isempty(self.(Shallow_Properties{Shallow_Index}).(Deep_Properties{Deep_Index}));
                        Transient_Matrix = [Transient_Matrix;self.(Shallow_Properties{Shallow_Index}).(Deep_Properties{Deep_Index})];
                    end
                end
            end
            self.Matrix = Transient_Matrix;
        end
        function Names = GetNames(self);
            for Transient_Index = 1:size(self.Matrix,1);
                Names{Transient_Index,1} = self.Matrix{Transient_Index,2};
                Names{Transient_Index,2} = self.Matrix{Transient_Index,3};
            end
        end
    end
end