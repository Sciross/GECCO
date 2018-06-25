%% Calculate Remin Gauss 4 Fun
function [DeepRemin] = CalculateRemin_MyLinear(FitMatrix,Lysocline);

Access = 1+(floor(Lysocline/10));
Grad = FitMatrix(Access,1);
Inter = FitMatrix(Access,2);

DeepRemin = (Lysocline.*Grad)+Inter;

end
