function Constant = DefinePhysicalConstants_OO(Constant);

%% Physical Constants
Constant.Atmosphere_Volume = (1.8*10.^20); %mols

Constant.MixingCoefficient = 3; %m/yr

Constant.Riverine_Volume = (362*10.^12); %m^2/yr;
Constant.Riverine_Phosphate = (0.2e-3); %mol/m^2
Constant.Riverine_Input = Constant.Riverine_Volume*Constant.Riverine_Phosphate; %mol/yr

Surface.Pressure = 1; %bars
Deep.Pressure = 150; %bars
Constant.Pressure = [Surface.Pressure;Deep.Pressure];

Surface.Temperature = 15+273.15; %degrees kelvin
Deep.Temperature = 3+273.15; %degrees kelvin
Constant.Temperature = [Surface.Temperature;Deep.Temperature];

Surface.Salinity = 35; %unitless
Deep.Salinity = 35; %unitless
Constant.Salinity = [Surface.Salinity;Deep.Salinity];

load('./../../Small_Data/HistogramCorrected.mat');
Constant.Hypsometry = Hypsometry;
Constant.BinMids = -(-BinLimits(1:end-1)+(diff(BinLimits)/2));
load('./../../Small_Data/FitMatrix.mat');
Constant.FitMatrix = FitMatrix;
% clear FitMatrix
% clear Hypsometry BinLimits

end