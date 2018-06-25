function DefinePhysicalConstants_VariBox(Initial,Constant);

%% Physical Constants
Constant.Ocean.Area = (361*10.^12); %m^2
Constant.Surface.Depth = 100; %m
Constant.Surface.Volume = Constant.Surface.Depth*Constant.Ocean.Area; %m^3
% Surface.Mass = 1000*(Constant.Surface.Volume*1000^3); %kg

Constant.Deep.Depth = 3600; %m
Constant.Deep.Volume = Constant.Deep.Depth*Constant.Ocean.Area; %m^3
% Deep.Mass = 1000*(Constant.Deep.Volume*1000^3); %kg

Constant.Volume = [Constant.Surface.Volume,Constant.Deep.Volume];

Constant.Atmosphere.Volume = (1.8*10.^20); %mols

Constant.MixingCoefficient = 3; %m/yr
Constant.WaterExchange = Constant.MixingCoefficient*Constant.Ocean.Area; %m^3/yr

Constant.Rivers.Volume = (Constant.Ocean.Area); %m^2/yr;
Constant.Rivers.Phosphate = (1.04531*10^-4); %mol/m^2
Constant.Rivers.Input = Constant.Rivers.Volume*Constant.Rivers.Phosphate; %mol/yr

Constant.Surface.Pressure = 1; %bars
Constant.Deep.Pressure = 150; %bars

Constant.Surface.Temperature = 25+273.15; %degrees kelvin
Constant.Deep.Temperature = 3+273.15; %degrees kelvin

Constant.Surface.Salinity = 35; %unitless
Constant.Deep.Salinity = 35; %unitless

DepthResolution = 100; %m
DepthMin = DepthResolution; %m
DepthMax = 10000; %m
Constant.DepthRange = [1,DepthMin:DepthResolution:(DepthMax-DepthResolution)];
clear DepthResolution DepthMin DepthMax

% [bTemp,Constant.TemperatureProfile] = CalculateTempProfile(Constant.Surface.Temperature,Constant.Deep.Temperature,1,1000,Constant.DepthRange);
% Constant.SalinityProfile = 35*ones(length(Constant.DepthRange),1);
% Constant.PressureProfile = (Constant.DepthRange)/10;

assignin('base','Initial',Initial);
assignin('base','Constant',Constant);

end