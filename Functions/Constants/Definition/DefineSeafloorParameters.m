function Seafloor = DefineSeafloorParameters(Seafloor);
    %% Seafloor Parameters
    Seafloor.Subduction_Mean = 8000;
    Seafloor.Subduction_Spread = 500;
    Seafloor.Subduction_Rate = [zeros(1050,1);ones(950,1)*3.3333e-5;0]; %m/Ma
    Seafloor.Subduction_Risk = 0.001;
    Seafloor.Uplift_Rate = zeros(2001,1);
    Seafloor.Uplift_Rate(2:1050) = 1e-7;
    Seafloor.Core_Depths = [10000;8000;5000;3000;2000;1000;0;-1000;-2000;-3000;-5000;-8000;-10000];
end