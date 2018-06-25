%% Redefine Physical Constants
function RedefinePhysicalConstants(Initial,Constant);

Constant.Surface.Volume = Constant.Surface.Depth*Constant.Ocean.Area; %m^3
Constant.Deep.Volume = Constant.Deep.Depth*Constant.Ocean.Area; %m^3

Constant.WaterExchange = Constant.MixingCoefficient*Constant.Ocean.Area; %m^3/yr

Constant.Rivers.Volume = Constant.Ocean.Area; %mol/yr
Constant.Rivers.Input = Constant.Rivers.Volume*Constant.Rivers.Phosphate; %mol/yr

assignin('base','Initial',Initial);
assignin('base','Constant',Constant);

end
