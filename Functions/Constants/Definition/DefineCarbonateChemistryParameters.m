function Carbonate_Chemistry = DefineCarbonateChemistryParameters(Carbonate_Chemistry,Midpoints);
    % Carbonate Chemistry Parameters
    Carbonate_Chemistry.Salinity = [35;35];
    Carbonate_Chemistry.Pressure = Midpoints./10;
    
    Carbonate_Chemistry.Boron = [(4.5e-04);(4.9e-04)].*1000; %mol/m^3
    Carbonate_Chemistry.Silica = [15e-3;15e-3]; %mol/m^3
    Carbonate_Chemistry.Phosphate = [0.2e-3;1.9e-3];
    Carbonate_Chemistry.Fluoride = [(7e-5);(7e-5)].*1000; %From ZeebeWolfGladrow
    Carbonate_Chemistry.Sulphate = [8.07*35;8.07*35]; %Taken from CSys
    Carbonate_Chemistry.Calcium = [10.28;10.28];
    Carbonate_Chemistry.Magnesium = [53;53];

    % Pressure Correction Values
    Carbonate_Chemistry.Pressure_Correction = PressureCorrectionDefinition();

    % Run Functions for Carbonate Chemistry
    % Calculate carbonate chemistry constants and their correction
    if ispc || ismac;
        Temp = load('./../Resources/Coefficients.mat');
    elseif isunix;        
        Temp = load('/home/rw12g11/Queen_Model/Resources/Coefficients.mat');
    end
    Carbonate_Chemistry.k0_Matrix = Temp.k0;
    Carbonate_Chemistry.k1_Matrix = Temp.k1;
    Carbonate_Chemistry.k2_Matrix = Temp.k2;
    Carbonate_Chemistry.kw_Matrix = Temp.kw;
    Carbonate_Chemistry.kb_Matrix = Temp.kb;
    Carbonate_Chemistry.ksp_cal_Matrix = Temp.ksp_cal;
    Carbonate_Chemistry.ksp_arag_Matrix = Temp.ksp_arag;
    Carbonate_Chemistry.ks_Matrix = Temp.ks;
    
    Carbonate_Chemistry.CCK_Mg_Ca_Correction = 2;

%     Coefficients = GetCoefficients(Constant);

%     [Constant.CCKs,Constant.CCK_Depth_Correction] = GetCCKConstants(Big.Salinity,Initial.Ocean_Temperature,Big.Pressure,Constant.Pressure_Correction,Coefficients);
end
