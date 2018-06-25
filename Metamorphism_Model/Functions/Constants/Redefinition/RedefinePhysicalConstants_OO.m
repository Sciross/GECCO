%% Redefine Physical Constants
function Constant = RedefinePhysicalConstants_OO(Constant);
% Constant.Temperature = [Constant.Surface.Temperature;Constant.Deep.Temperature];

% Constant.Salinity = [Constant.Surface.Salinity;Constant.Deep.Salinity];

% Constant.Pressure = [Constant.Surface.Pressure;Constant.Deep.Pressure];

% Constant.WaterExchange = Constant.MixingCoefficient*Constant.Ocean.Area; %m^3/yr

% Constant.Rivers.Volume = Constant.Ocean.Area; %mol/yr
% Constant.Rivers.Input = Constant.Rivers.Volume*Constant.Rivers.Phosphate; %mol/yr

end
