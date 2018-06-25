function Ice = DefineIceParameters(Ice);   
    %% Ice Parameters
    Ice.Angle = 0.07; %degrees
    Ice.Density = 0.9167e6; %g/m^3
    Ice.Growth_Rate = 50; %mol/yr/m^3 above snow line
    Ice.Melt_Rate = 1.3567e-6; %mol/yr/mol of ice present
    Ice.Water_Density = 1.0292e6; %g/m^3
    Ice.Water_Molar_Mass = 18; %g/mol
    Ice.Snow_Line_Sensitivity = 100; %m/degreeC
    Ice.Sea_Level_Forcing = 0; %m/yr
end