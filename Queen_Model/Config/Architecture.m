classdef Architecture < matlab.mixin.Copyable & ParameterLoad
    properties
        Atmosphere_Volume        
        Riverine_Volume
        Ocean_Depths
        Ocean_Midpoints
        Ocean_Area
        Ocean_Volumes
        Mixing_Coefficient
        Hypsometric_Interpolation_Matrix
        Hypsometry
        Cumulative_Hypsometry
        Hypsometric_Bin_Midpoints
    end
    methods
        function self = Architecture(Empty_Cell_Flag);
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineArchitectureParameters(self);
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
        function EditHypsometry(self,Spreads,Means,Maximums);
            for Index = 1:numel(Spreads);
                Gaussian{Index} = GenerateGaussian(self.Hypsometric_Bin_Midpoints,[Spreads(Index),Means(Index)]);
            end
            Normalised_First_Gaussian = ((Gaussian{1})./nanmax(Gaussian{1})).*Maximums(1);
            Corrected_First_Gaussian = Normalised_First_Gaussian.*self.Hypsometry;
            Normalised_Second_Gaussian = (Gaussian{2})./nansum(Gaussian{2});
            Corrected_Second_Gaussian = Normalised_Second_Gaussian.*(nansum(Corrected_First_Gaussian));
            
            Normalised_Third_Gaussian = ((Gaussian{3})./nanmax(Gaussian{3})).*Maximums(3);
            Corrected_Third_Gaussian = Normalised_Third_Gaussian.*self.Hypsometry;
            Normalised_Fourth_Gaussian = (Gaussian{4})./nansum(Gaussian{4});
            Corrected_Fourth_Gaussian = Normalised_Fourth_Gaussian.*(nansum(Corrected_Third_Gaussian));
            
            Net_Change = Corrected_First_Gaussian-Corrected_Second_Gaussian+Corrected_Third_Gaussian-Corrected_Fourth_Gaussian;
            
            self.Hypsometry = self.Hypsometry+Net_Change;
            
            self.RecalculateCumulativeHypsometry();
            self.RecalculateInterpolationMatrix();
        end
        function RecalculateCumulativeHypsometry(self);
            self.Cumulative_Hypsometry = cumsum(self.Hypsometry);
        end
        function RecalculateInterpolationMatrix(self);            
            Bin_Midpoints = self.Hypsometric_Bin_Midpoints; %[0,BinMids];
            Hypsometry = self.Cumulative_Hypsometry; %[0,Hypsometry];
            
            % y = mx + c
            % m = (y2-y1)/(x2-x1)
            Gradient = diff(Hypsometry)./diff(Bin_Midpoints);
            YIntercept = Hypsometry(1:end-1)-(Gradient.*Bin_Midpoints(1:end-1));
            
            self.Hypsometric_Interpolation_Matrix = [Gradient,YIntercept];
            
        end
    end
end