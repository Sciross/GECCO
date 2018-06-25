function Constant = DefineCarbonateChemistryConstants_OO(Constant);

%% Carbonate Chemistry
%% Define Constants
Constant.DIC_Remin = [0.3;0]; %fraction
% Constant.DIC.DeepRemin = 0.0; %fraction
Constant.DIC_TotalRemin = 1.0; %fraction

Constant.Riverine_Carbon = 0.055; %mol/m^2
Constant.Riverine_Alkalinity = 0.099; %mol/m^2

Constant.POC_Remin = [0.926;(1-(0.926+(5.188679245356671e-04)))]; %fraction %FOR REALITY: [0.9260,xx] 

Constant.RainRatio = 0.03; %fraction

Constant.Carbonate_Boron = [(4.5e-04);(4.9e-04)].*1000; %mol/m^3

Constant.Carbonate_Silica = [15e-3;15e-3]; %mol/m^3

Constant.Carbonate_Phosphate = [0.2e-3;1.9e-3];

Constant.Carbonate_Fluoride = [(7e-5);(7e-5)].*1000; %From ZeebeWolfGladrow

Constant.Carbonate_Sulphate = [8.07*35;8.07*35]; %Taken from CSys

Constant.Carbonate_Calcium = [10.28;10.28];
Constant.Carbonate_Magnesium = [53;53];

%% Pressure Correction Values
Constant.PressureCorrection = PressureCorrectionDefinition();

%% Run Functions for Carbonate Chemistry
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

Coefficients = GetCoefficients(Constant,Constant);

[Constant.CarbonateConstants,Constant.Corr] = GetCCKConstants(Constant.Salinity,Constant.Temperature,Constant.Pressure,Constant.PressureCorrection,Coefficients);



end