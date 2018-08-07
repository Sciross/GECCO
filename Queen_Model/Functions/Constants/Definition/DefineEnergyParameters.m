function Energy = DefineEnergyParameters(Energy);    
    %% Energy Parameters
    Energy.Radiative_Sensitivity = 3.7; %W/m^2 / doubling
    Energy.Climate_Sensitivity = 3.5; %degC/doubling CO2
    Energy.Solar_Constant = 1370; %W/m^2
    Energy.Albedo = 0.3; %fraction
    Energy.Emissivity = 0.61334;
    Energy.Stefan_Boltzmann = 5.67e-8;
    
    Energy.Ocean_Temperature_Offset = [1;12];
    Energy.Atmosphere_Equilibration_Timescale = 50;
    Energy.Ocean_Equilibration_Timescale = [100;1000];
end