function Phosphate = DefinePhosphateParameters(Phosphate);
    %% Phosphate Parameters
    Phosphate.Maximum_Growth_Rate = 0.25*365; %/yr
    Phosphate.Mortality = 0.2*365; %/yr
    Phosphate.Biological_Half_Constant = 0.03*(10^-3); %0.183225e-3;  %mol/m^3 ##UNCERTAINTY
    Phosphate.Algal_Slowing_Factor = 0.001;
    Phosphate.Riverine_Concentration = 0.002; %mol/m^3/yr
    
    SurfaceRemin = 0.95; %fraction
    Burial = 0.002; %fraction
    DeepRemin = 1-(SurfaceRemin+Burial); %fraction

    Phosphate.Remineralisation = [SurfaceRemin;DeepRemin];
end