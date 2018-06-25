function dy = Core(t,y,GECCOObject)
% Change Values
for n = 1:size(GECCOObject.Conditions.Variable,1);
    if numel(GECCOObject.Conditions.Constant.(GECCOObject.Conditions.Variable{n,1}{1}))==1;
        GECCOObject.Conditions.Present.(GECCOObject.Conditions.Variable{n,1}{1}) = feval(GECCOObject.Conditions.Variable{n,3},t,GECCOObject.Conditions);
    else
        GECCOObject.Conditions.Present.(GECCOObject.Conditions.Variable{n,1}{1})(GECCOObject.Conditions.Variable{n,2}) = feval(GECCOObject.Conditions.Variable{n,3},t,GECCOObject.Conditions);
    end
end

% Preallocate
dy = zeros(8,1);

% Combined rate expression for Algae number
dy(2) = y(2)*((GECCOObject.Conditions.Present.GrowthRateMax*(y(3)/(GECCOObject.Conditions.Present.HalfConstant+y(3))))-GECCOObject.Conditions.Present.Mortality); %mol/m3/yr

% Biological export: Export = [A] * Ocean.Volume * Mortality
BiologicalExport = y(2)*GECCOObject.Architectures.Volumes(1)*GECCOObject.Conditions.Present.Mortality; %mol/yr

% Fluxes
PhosphateFluxMixing = GECCOObject.Conditions.Present.MixingCoefficient.*GECCOObject.Architectures.BoxArea.*(y(4)-y(3));

BiologicalFlux = BiologicalExport.*GECCOObject.Conditions.Present.Phosphate_Remin;

Phosphate.Flux(1,1) = GECCOObject.Conditions.Present.Riverine_Input + PhosphateFluxMixing + BiologicalFlux(1) - BiologicalExport;
Phosphate.Flux(2,1) = BiologicalFlux(2) - PhosphateFluxMixing;

dy(3:4) = (Phosphate.Flux./GECCOObject.Architectures.Volumes)';

%% Carbonate Chemistry
Coefficients = GetCoefficients(GECCOObject.Conditions.Constant,GECCOObject.Conditions.Present);
[GECCOObject.Conditions.Present.CarbonateConstants,GECCOObject.Conditions.Present.Corr] = GetCCKConstants(GECCOObject.Conditions.Present.Salinity,GECCOObject.Conditions.Present.Temperature,GECCOObject.Conditions.Present.Pressure,GECCOObject.Conditions.Constant.PressureCorrection,Coefficients);

[GECCOObject.Conditions.Present.pH,GECCOObject.Conditions.Present.CO2,~,~,GECCOObject.Conditions.Present.OmegaC,~] = CarbonateChemistry(GECCOObject.Conditions.Present,[y(5);y(6)],[y(7);y(8)],GECCOObject.Conditions.Present.HIn,GECCOObject.Conditions.Present.CarbonateConstants);

% Lysocline
GECCOObject.Conditions.Present.Lysocline = CalculateLysocline_Fun_RegulaFalsi(GECCOObject,y(6));

% Deep Remin
GECCOObject.Conditions.Present.DIC_Burial = (CalculateRemin_MyLinear(GECCOObject.Conditions.Present.FitMatrix,GECCOObject.Conditions.Present.Lysocline)/100)*(1-GECCOObject.Conditions.Present.DIC_Remin(1));
GECCOObject.Conditions.Present.DIC_Remin(2) = GECCOObject.Conditions.Present.DIC_TotalRemin-(GECCOObject.Conditions.Present.DIC_Burial+GECCOObject.Conditions.Present.DIC_Remin(1));

%% Carbon Fluxes
% POC
BiologicalPOCExport = BiologicalExport*GECCOObject.Conditions.Present.RedfieldRatio;
POCBiologicalFlux = (BiologicalPOCExport.*GECCOObject.Conditions.Present.POC_Remin);
% POCBurialFlux = (BiologicalPOCExport.*(1-sum(GECCOObject.Conditions.Present.POC_Remin)));

% DIC
DICRiverineFlux = GECCOObject.Conditions.Present.Riverine_Carbon*GECCOObject.Architectures.BoxArea;

DICMixingFlux = (y(6)-y(5)).*GECCOObject.Conditions.Present.MixingCoefficient.*GECCOObject.Architectures.BoxArea;

BiologicalPICExport = BiologicalExport*GECCOObject.Conditions.Present.RedfieldRatio*GECCOObject.Conditions.Present.RainRatio;
PICBiologicalFlux = (BiologicalPICExport.*GECCOObject.Conditions.Present.DIC_Remin);
PICBurialFlux = BiologicalPICExport.*(GECCOObject.Conditions.Present.DIC_TotalRemin-(sum(GECCOObject.Conditions.Present.DIC_Remin)));

[AirSeaExchange,SeaAirExchange] = GetAirSeaGasExchange(y(1),GECCOObject.Conditions.Present.CO2(1),GECCOObject.Conditions.Present.CarbonateConstants(1));

%% Atmosphere - 1
GasFlux = ((SeaAirExchange-AirSeaExchange).*GECCOObject.Architectures.BoxArea);
dy(1) = GasFlux./GECCOObject.Conditions.Present.Atmosphere_Volume;

%% Surface DIC - 5
DIC.Flux(1,1) = DICRiverineFlux + DICMixingFlux - BiologicalPICExport + PICBiologicalFlux(1) - BiologicalPOCExport + POCBiologicalFlux(1) - GasFlux;

%% Deep DIC - 6
DIC.Flux(2,1) = PICBiologicalFlux(2) - DICMixingFlux + POCBiologicalFlux(2);

dy(5:6) = DIC.Flux./GECCOObject.Architectures.Volumes;

%% Alkalinity Fluxes
AlkalinityRiverineFlux = GECCOObject.Conditions.Present.Riverine_Alkalinity*GECCOObject.Architectures.BoxArea;

AlkalinityMixingFlux = (y(8)-y(7)).*GECCOObject.Conditions.Present.MixingCoefficient.*GECCOObject.Architectures.BoxArea;

BiologicalAlkalinityExport = BiologicalExport*GECCOObject.Conditions.Present.RedfieldRatio*GECCOObject.Conditions.Present.RainRatio*2;
AlkalinityBiologicalFlux = (BiologicalAlkalinityExport.*GECCOObject.Conditions.Present.DIC_Remin);

%% Surface Alkalinity - 7
Alkalinity.Flux(1,1) = AlkalinityRiverineFlux + AlkalinityMixingFlux - BiologicalAlkalinityExport + AlkalinityBiologicalFlux(1);

%% Deep Alkalinity - 8
Alkalinity.Flux(2,1) = AlkalinityBiologicalFlux(2) - AlkalinityMixingFlux;

dy(7:8) = Alkalinity.Flux./GECCOObject.Architectures.Volumes;

%% Subduction
AddArray = double(GECCOObject.Conditions.Constant.BinMids<GECCOObject.Conditions.Present.Lysocline);
AddArray(ceil(GECCOObject.Conditions.Present.Lysocline/10)) = rem(GECCOObject.Conditions.Present.Lysocline,10)/10;
Carbonate.Buried = (AddArray./(sum(AddArray)))';

Carbonate.ShiftedIn = [0;GECCOObject.Carbonate.Distribution(1:end-1)].*GECCOObject.Conditions.Present.SubductionRate;
Carbonate.ShiftedOut = [GECCOObject.Carbonate.Distribution.*GECCOObject.Conditions.Present.SubductionRate];

Carbonate.Removed = (GECCOObject.Carbonate.Distribution.*GECCOObject.Conditions.Present.SubductionRisk'.*GECCOObject.Conditions.Present.SubductionRate);

GECCOObject.Carbonate.Distribution = GECCOObject.Carbonate.Distribution + (Carbonate.Buried+Carbonate.ShiftedIn-Carbonate.ShiftedOut-Carbonate.Removed);

% figure(2);
% clf
% plot(GECCOObject.Carbonate.Distribution);
% drawnow;

%% Assign Globals
GECCOObject.Conditions.Present.HIn_s = (10^(-GECCOObject.Conditions.Present.pH(1)))*1000;
GECCOObject.Conditions.Present.HIn_d = (10^(-GECCOObject.Conditions.Present.pH(2)))*1000;

end
