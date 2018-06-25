function Seafloor = DefineSeafloorParameters(Seafloor);
    %% Seafloor Parameters
    Seafloor.Subduction_Mean = 8000;
    Seafloor.Subduction_Spread = 500;
    Seafloor.Subduction_Rate = [ones(1050,1)*(00/(100*10^6))/10;ones(951,1)*10000/(100*10^6)]; %m/Ma
    Seafloor.Subduction_Risk = 0.001;
    Seafloor.Uplift_Rate = zeros(2001,1);
    Seafloor.Uplift_Rate(2:1050) = 1e-7;
    Seafloor.Core_Depths = NaN;
end