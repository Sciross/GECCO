%% Calculate Remin Gauss 4 Fun
function Burial = CalculateRemin_MyLinear(FitMatrix,Lysocline);

Access = 1001-(round(-Lysocline/10));
Gradient = FitMatrix(Access,1);
Intercept = FitMatrix(Access,2);

Burial = (-Lysocline.*Gradient)+Intercept;

end
