function DefineBiologicalConstants_VariBox(Initial,Constant);

%% Biological Constants
Constant.GrowthRateMax = 0.25*365; %/yr
Constant.Mortality = 0.2*365; %/yr
Constant.HalfConstant = 0.03*(10^-3); %mol/m^3
Constant.BiologicalUsage = 1; %mol/d

Constant.Phosphate.SurfaceRemin = 0.85; %fraction
Constant.Phosphate.Burial = 0.0029; %fraction
Constant.Phosphate.DeepRemin = 1-(Constant.Phosphate.SurfaceRemin+Constant.Phosphate.Burial); %fraction
Constant.Phosphate.Remin = [Constant.Phosphate.SurfaceRemin,Constant.Phosphate.DeepRemin];

Constant.RedfieldRatio = 106; %P:C = 1:Constant.RedfieldRatio

assignin('base','Initial',Initial);
assignin('base','Constant',Constant);

end