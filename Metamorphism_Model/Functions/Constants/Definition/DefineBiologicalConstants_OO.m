function Constant = DefineBiologicalConstants_OO(Constant);

%% Biological Constants
Constant.GrowthRateMax = 0.25*365; %/yr
Constant.Mortality = 0.2*365; %/yr
Constant.HalfConstant = 0.03*(10^-3); %0.183225e-3;  %mol/m^3 ##UNCERTAINTY
Constant.BiologicalUsage = 1; %mol/d

SurfaceRemin = 0.95; %fraction
Burial = 0.002; %fraction
DeepRemin = 1-(SurfaceRemin+Burial); %fraction

Constant.Phosphate_Remin = [SurfaceRemin;DeepRemin];
Constant.RedfieldRatio = 106; %P:C = 1:Constant.RedfieldRatio

end