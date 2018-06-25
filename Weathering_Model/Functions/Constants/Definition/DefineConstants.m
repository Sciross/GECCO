function Constant = DefineConstants(Constant,Initial);

    %% Physical Constants
    Constant.Atmosphere_Volume = (1.8e20); %mols

    Constant.Mixing_Coefficient = 5; %m/yr

    Constant.Riverine_Volume = 4e13; %(362*10.^12); %m^2/yr;
    Constant.Riverine_Phosphate = 0.13575e-2; %mol/m^2

    Surface_Pressure = 1; %bars
    Deep_Pressure = 150; %bars
    Constant.Pressure = [Surface_Pressure;Deep_Pressure];

    Surface_Salinity = 35; %unitless
    Deep_Salinity = 35; %unitless
    Constant.Salinity = [Surface_Salinity;Deep_Salinity];

    load('./../../Small_Data/HistogramCorrected.mat');    
    load('./../../Small_Data/FitMatrix.mat');
    
    Constant.Hypsometry = Hypsometry';
    Constant.Hypsometric_Bin_Midpoints = -(-BinLimits(1:end-1)+(diff(BinLimits)/2))';

    Constant.Hypsometric_Interpolation_Matrix = FitMatrix;

    %% Biological Constants
    Constant.Max_Growth_Rate = 0.25*365; %/yr
    Constant.Mortality = 0.2*365; %/yr
    Constant.Biological_Half_Constant = 0.03*(10^-3); %0.183225e-3;  %mol/m^3 ##UNCERTAINTY

    SurfaceRemin = 0.95; %fraction
    Burial = 0.002; %fraction
    DeepRemin = 1-(SurfaceRemin+Burial); %fraction

    Constant.Phosphate_Remin = [SurfaceRemin;DeepRemin];
    Constant.Redfield_Ratio = 106; %P:C = 1:Constant.RedfieldRatio
    
    %% Carbonate Chemistry Constants
    Constant.PIC_Remin = [0;0]; %fraction
    Constant.PIC_Burial = [0.0748;0];

    Constant.POC_Remin = [0.9125;0.0874]; %fraction %FOR REALITY: [0.9260,xx] 
    Constant.POC_Burial = [0;1].*(1-sum(Constant.POC_Remin));
    Constant.POC_Burial_Max_Depth = 8000;

    Constant.Production_Ratio = 0.03; %fraction

    Constant.Boron = [(4.5e-04);(4.9e-04)].*1000; %mol/m^3
    Constant.Silica = [15e-3;15e-3]; %mol/m^3
    Constant.Phosphate = [0.2e-3;1.9e-3];
    Constant.Fluoride = [(7e-5);(7e-5)].*1000; %From ZeebeWolfGladrow
    Constant.Sulphate = [8.07*35;8.07*35]; %Taken from CSys
    Constant.Calcium = [10.28;10.28];
    Constant.Magnesium = [53;53];

    % Pressure Correction Values
    Constant.Pressure_Correction = PressureCorrectionDefinition();

    % Run Functions for Carbonate Chemistry
    % Calculate carbonate chemistry constants and their correction
    Temp = load('./../../Small_Data/Coefficients.mat');
    Constant.k0_Matrix = Temp.k0;
    Constant.k1_Matrix = Temp.k1;
    Constant.k2_Matrix = Temp.k2;
    Constant.kw_Matrix = Temp.kw;
    Constant.kb_Matrix = Temp.kb;
    Constant.ksp_cal_Matrix = Temp.ksp_cal;
    Constant.ksp_arag_Matrix = Temp.ksp_arag;
    Constant.ks_Matrix = Temp.ks;
    
    Constant.CCK_Mg_Ca_Correction = 1;
    Constant.Carbonate_Surface_Sediment_Lock = 1;

    Coefficients = GetCoefficients(Constant,Constant);

    [Constant.CCKs,Constant.CCK_Depth_Correction] = GetCCKConstants(Constant.Salinity,Initial.Ocean_Temperature,Constant.Pressure,Constant.Pressure_Correction,Coefficients);

    %% Subduction Constants
    Constant.Subduction_Mean = 8000;
    Constant.Subduction_Spread = 500;
    Constant.Subduction_Rate = [ones(50,1)*(00/(100*10^6))/10;ones(950,1)*10000/(100*10^6)]; %m/Ma
    Constant.Subduction_Risk = 0.001;
    
    Constant.Core_Depths = NaN;
    
    %% Geological Constants
    Constant.Outgassing_Spread = 1e6;
    Constant.Outgassing_Mean_Lag = 1e7;
    Constant.Outgassing_Temporal_Resolution = 1000;
    
    Constant.Silicate_Replenishment = 0; %1e12; % ### Not real

    Constant.Silicate_Weathering_Coefficient = [1.481407718e-14;0.059018]; %[1.1057e-4;0.13603];
    Constant.Carbonate_Weathering_Coefficient = [1.481407718e-14;0.059018];

    Constant.Silicate_Replacement = 1; %fraction
    Constant.Carbonate_Replacement = 0.99; %fraction

    Constant.Silicate_Limiting_Threshold = 0.01e18; % ### random
    Constant.Carbonate_Limiting_Threshold = 0.01e18; % ### random

    Constant.Silicate_Weatherability = 1;
    Constant.Carbonate_Weatherability = 1;

    Constant.Obduction_Depths = [10;500]; % ### random
    Constant.Obduction_Rate = 1e-6; % ### random
    
    %% Energy Constants
    Constant.Radiative_Sensitivity = 3.7; %W/m^2 / doubling
    Constant.Climate_Sensitivity = 1.5; %decC/doubling CO2
    Constant.Solar_Constant = 1370; %W/m^2
    Constant.Albedo = 0.3; %fraction
    Constant.Emissivity = 0.62;
    Constant.Stefan_Boltzmann = 5.67e-8;
    
    Constant.Ocean_Temperature_Offset = [1;12];
    Constant.Atmosphere_Equilibration_Timescale = 50;
    Constant.Ocean_Equilibration_Timescale = [100;1000];
end