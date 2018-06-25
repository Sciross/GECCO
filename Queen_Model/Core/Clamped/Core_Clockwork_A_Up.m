function [dy,dy_Sub,dy_Meta] = Core(t,y,y_Sub,y_Meta,GECCOObject)
% Change Values
for n = 1:size(GECCOObject.Conditions.Variable,1);
    if numel(GECCOObject.Conditions.Constant.(GECCOObject.Conditions.Variable{n,1}{1}))==1;
        GECCOObject.Conditions.Present.(GECCOObject.Conditions.Variable{n,1}{1}) = feval(GECCOObject.Conditions.Variable{n,3},t,GECCOObject.Conditions);
    else
        GECCOObject.Conditions.Present.(GECCOObject.Conditions.Variable{n,1}{1})(GECCOObject.Conditions.Variable{n,2}) = feval(GECCOObject.Conditions.Variable{n,3},t,GECCOObject.Conditions);
    end
end

% Preallocate
dy = zeros(numel(y),1);
dy_Sub = zeros(numel(y_Sub),1);
dy_Meta = zeros(numel(y_Meta),1);

%% Biology + Phosphate
% Biological export: Export = [A] * Ocean.Volume * Mortality
BiologicalExport = y(2)*GECCOObject.Architectures.Volumes(1)*GECCOObject.Conditions.Present.Mortality; %mol/yr

% Fluxes
PhosphateFluxMixing = GECCOObject.Conditions.Present.MixingCoefficient.*GECCOObject.Architectures.BoxArea.*(y(4)-y(3));

BiologicalFlux = BiologicalExport.*GECCOObject.Conditions.Present.Phosphate_Remin;

Phosphate.Flux(1,1) = GECCOObject.Conditions.Present.Riverine_Input + PhosphateFluxMixing + BiologicalFlux(1) - BiologicalExport;
Phosphate.Flux(2,1) = BiologicalFlux(2) - PhosphateFluxMixing;

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
DICRiverineFlux = y(17)*GECCOObject.Architectures.BoxArea;

DICMixingFlux = (y(6)-y(5)).*GECCOObject.Conditions.Present.MixingCoefficient.*GECCOObject.Architectures.BoxArea;

BiologicalPICExport = BiologicalExport*GECCOObject.Conditions.Present.RedfieldRatio*GECCOObject.Conditions.Present.RainRatio;
PICBiologicalFlux = (BiologicalPICExport.*GECCOObject.Conditions.Present.DIC_Remin);
PICBurialFlux = BiologicalPICExport.*(GECCOObject.Conditions.Present.DIC_TotalRemin-(sum(GECCOObject.Conditions.Present.DIC_Remin)));

[AirSeaExchange,SeaAirExchange] = GetAirSeaGasExchange(y(1),GECCOObject.Conditions.Present.CO2(1),GECCOObject.Conditions.Present.CarbonateConstants(1));

%% Atmosphere
GasFlux = ((SeaAirExchange-AirSeaExchange).*GECCOObject.Architectures.BoxArea);

%% DIC
DIC.Flux(1,1) = DICRiverineFlux + DICMixingFlux - BiologicalPICExport + PICBiologicalFlux(1) - BiologicalPOCExport + POCBiologicalFlux(1) - GasFlux;
DIC.Flux(2,1) = PICBiologicalFlux(2) - DICMixingFlux + POCBiologicalFlux(2);

%% Alkalinity Fluxes
AlkalinityRiverineFlux = y(18)*GECCOObject.Architectures.BoxArea;

AlkalinityMixingFlux = (y(8)-y(7)).*GECCOObject.Conditions.Present.MixingCoefficient.*GECCOObject.Architectures.BoxArea;

BiologicalAlkalinityExport = BiologicalExport*GECCOObject.Conditions.Present.RedfieldRatio*GECCOObject.Conditions.Present.RainRatio*2;
AlkalinityBiologicalFlux = (BiologicalAlkalinityExport.*GECCOObject.Conditions.Present.DIC_Remin);

%% Alkalinity
Alkalinity.Flux(1,1) = AlkalinityRiverineFlux + AlkalinityMixingFlux - BiologicalAlkalinityExport + AlkalinityBiologicalFlux(1);
Alkalinity.Flux(2,1) = AlkalinityBiologicalFlux(2) - AlkalinityMixingFlux;

%% Subduction
AddArray = double(GECCOObject.Conditions.Constant.BinMids<GECCOObject.Conditions.Present.Lysocline);
AddArray(floor(GECCOObject.Conditions.Present.Lysocline/10)+1) = rem(GECCOObject.Conditions.Present.Lysocline,10)/10;
Carbonate.Buried = (AddArray./(sum(AddArray))).*PICBurialFlux;

Carbonate.ShiftedIn = [0;y_Sub(1:end-1)].*GECCOObject.Conditions.Present.Subduction_Rate;
Carbonate.ShiftedOut = y_Sub.*GECCOObject.Conditions.Present.Subduction_Rate;

Carbonate.Removed = (y_Sub.*GECCOObject.Conditions.Present.Subduction_Gauss);

dy_Sub = (Carbonate.Buried+Carbonate.ShiftedIn-Carbonate.ShiftedOut-Carbonate.Removed);

%% Metamorphism
Metamorphism.Added = sum(Carbonate.Removed);
MetaBoxes = floor(t/GECCOObject.Conditions.Present.Metamorphism_Resolution) + (GECCOObject.Conditions.Present.Metamorphism_Mean_Lag + [(-4*GECCOObject.Conditions.Present.Metamorphism_Spread),(4*GECCOObject.Conditions.Present.Metamorphism_Spread)])/GECCOObject.Conditions.Present.Metamorphism_Resolution;
dy_Meta(MetaBoxes(1):MetaBoxes(2)) = (Metamorphism.Added.*GECCOObject.Conditions.Present.Metamorphism_Gauss);

Outgassing = (y_Meta(1+floor(t/GECCOObject.Conditions.Present.Metamorphism_Resolution))/GECCOObject.Conditions.Present.Metamorphism_Resolution);

%% Weathering
Carbonate_Weathering = (y(12).*y(14));
Silicate_Weathering = (y(13).*y(15));

Weathering = (Silicate_Weathering + Carbonate_Weathering);

%% CO2
CO2.Flux = GasFlux + Outgassing - Silicate_Weathering - (2.*Carbonate_Weathering);

%% Assign dys
% Flux over volume
dy(1) = (300e-6)/100000; %CO2.Flux./GECCOObject.Conditions.Present.Atmosphere_Volume;

%% Temperature
dy(16) = GECCOObject.Conditions.Present.Radiative_Sensitivity.*1.4427.*log((y(1)+dy(1))/y(1));
T_eq = ((GECCOObject.Conditions.Present.Solar_Constant.*(1-GECCOObject.Conditions.Present.Albedo) + (4.*GECCOObject.Conditions.Present.Climate_Sensitivity.*y(16)))./(4.*GECCOObject.Conditions.Present.Emissivity*GECCOObject.Conditions.Present.Stef_Boltz)).^0.25;
T_eq_Ocean = T_eq-GECCOObject.Conditions.Present.Temp_Grad;

% Combined rate expression for Algae number
dy(2) = y(2)*((GECCOObject.Conditions.Present.GrowthRateMax*(y(3)/(GECCOObject.Conditions.Present.HalfConstant+y(3))))-GECCOObject.Conditions.Present.Mortality)*0.001; %mol/m3/yr
% Flux over volume
dy(3:4) = (Phosphate.Flux./GECCOObject.Architectures.Volumes);
% Flux over volume
dy(5:6) = DIC.Flux./GECCOObject.Architectures.Volumes;
% Flux over volume
dy(7:8) = Alkalinity.Flux./GECCOObject.Architectures.Volumes;
% Approach equilibrium temperature over specified timescale
dy(9) = (T_eq-y(9))./GECCOObject.Conditions.Present.Atmosphere_Timescale;
% Approach equilibrium ocean temperature at specified timescales
dy(10:11) = (T_eq_Ocean-y(10:11))./GECCOObject.Conditions.Present.Ocean_Timescale;
dy(12) = GECCOObject.Conditions.Present.Silicate_Replenishment - Silicate_Weathering;
dy(13) = GECCOObject.Conditions.Present.Carbonate_Replenishment - Carbonate_Weathering;

%% Assign Globals
GECCOObject.Conditions.Present.HIn_s = (10^(-GECCOObject.Conditions.Present.pH(1)))*1000;
GECCOObject.Conditions.Present.HIn_d = (10^(-GECCOObject.Conditions.Present.pH(2)))*1000;

dy(14) = y(14).*(dy(9).*GECCOObject.Conditions.Present.Silicate_Coefficient(1).*GECCOObject.Conditions.Present.Silicate_Coefficient(2)*(exp(GECCOObject.Conditions.Present.Silicate_Coefficient(2)*y(9))));
dy(15) = y(15).*(dy(9).*GECCOObject.Conditions.Present.Carbonate_Coefficient(1).*GECCOObject.Conditions.Present.Carbonate_Coefficient(2).*(exp(GECCOObject.Conditions.Present.Carbonate_Coefficient(2)*y(9))));

dy(17:18) = (2*((y(12).*dy(14)) + (y(14).*dy(12)) + (y(13).*dy(15)) + (y(15).*dy(13)))./GECCOObject.Conditions.Present.Riverine_Volume);
% dy(18) = (2*((y(12).*dy(14)) + (y(14).*dy(12)) + (y(13).*dy(15)) + (y(15).*dy(13)))./GECCOObject.Conditions.Present.Riverine_Volume);

end
