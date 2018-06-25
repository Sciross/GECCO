%% Calculate Remin Gauss 4 Fun
function Burial = CalculateRemin_MyLinear(FitMatrix,Lysocline);

Access = 1+(floor(Lysocline/10));
Grad = FitMatrix(Access,1);
Inter = FitMatrix(Access,2);

Burial = (Lysocline.*Grad)+Inter;

end
