function [dy,dy_Sub,dy_Outgas] = Core(t,y,y_Sub,y_Outgas,Model)
% Change Values
for n = 1:size(Model.Conditions.Variable,1);
    if numel(Model.Conditions.Constant.(Model.Conditions.Variable{n,1}{1}))==1;
        Model.Conditions.Present.(Model.Conditions.Variable{n,1}{1}) = feval(Model.Conditions.Variable{n,3},t,Model.Conditions);
    elseif ~isnan(Model.Conditions.Variable{n,2});
        Model.Conditions.Present.(Model.Conditions.Variable{n,1}{1})(Model.Conditions.Variable{n,2}) = feval(Model.Conditions.Variable{n,3},t,Model.Conditions);
    else %### Dangerous as it can produce an matrix of incorrect size
        Model.Conditions.Present.(Model.Conditions.Variable{n,1}{1}) = feval(Model.Conditions.Variable{n,3},t,Model.Conditions);
    end
end

% Preallocate
dy = zeros(numel(y),1);
dy_Sub = zeros(numel(y_Sub),1);
dy_Outgas = zeros(numel(y_Outgas),1);

%% Biology + Phosphate
% Biological export: Export = [A] * Ocean.Volume * Mortality
BiologicalExport = y(2)*Model.Architectures.Volumes(1)*Model.Conditions.Present.Mortality; %mol/yr

% Fluxes
PhosphateFluxRivers = (Model.Conditions.Present.Riverine_Phosphate.*Model.Conditions.Present.Riverine_Volume);
PhosphateFluxMixing = Model.Conditions.Present.Mixing_Coefficient.*Model.Architectures.BoxArea.*(y(4)-y(3));
BiologicalFlux = BiologicalExport.*Model.Conditions.Present.Phosphate_Remin;

Phosphate_Flux(1,1) = PhosphateFluxRivers + PhosphateFluxMixing + BiologicalFlux(1) - BiologicalExport;
Phosphate_Flux(2,1) = BiologicalFlux(2) - PhosphateFluxMixing;

%% Carbonate Chemistry
if Model.Conditions.Present.CCK_Mg_Ca_Correction;
    Coefficients = GetCoefficients(Model.Conditions.Constant,Model.Conditions.Present);
else
    Coefficients = [];
end
[Model.Conditions.Present.CCKs,~] = GetCCKConstants(Model.Conditions.Present.Salinity,[y(10);y(11)],Model.Conditions.Present.Pressure,Model.Conditions.Constant.Pressure_Correction,Coefficients);

[Model.Conditions.Present.pH,Model.Conditions.Present.CO2,~,~,Model.Conditions.Present.OmegaC,~] = CarbonateChemistry(Model.Conditions.Present,[y(5);y(6)],[y(7);y(8)],Model.Conditions.Present.HIn,Model.Conditions.Present.CCKs);

% Lysocline
Model.Conditions.Present.Lysocline = CalculateLysocline_Fun_RegulaFalsi(Model,y(6),y(10:11));

%% Sea level arrays
if y(18)<-5;
     Edge_Box_Fill = 1+rem(y(18)+5,10)/10;
else
    Edge_Box_Fill = rem(y(18)+5,10)/10;
end

OceanArray = double(Model.Conditions.Constant.Hypsometric_Bin_Midpoints<round(y(18)));
OceanArray(1001-round(y(18)/10)) = Edge_Box_Fill;

SurfArray =  double(OceanArray & Model.Conditions.Constant.Hypsometric_Bin_Midpoints>(round(y(18))-Model.Architectures.BoxDepths(1)));
SurfArray(1001-round(y(18)/10)) = Edge_Box_Fill;
SurfArray(1001-(round(y(18)/10))+(Model.Architectures.BoxDepths(1)/10)) = 1-Edge_Box_Fill;

DeepArray = double((Model.Conditions.Constant.Hypsometric_Bin_Midpoints>(-Model.Conditions.Present.Lysocline)) & OceanArray & ~SurfArray);
DeepArray(1001-(round(y(18)/10))+(Model.Architectures.BoxDepths(1)/10)) = Edge_Box_Fill;
DeepArray(1001+round(Model.Conditions.Present.Lysocline/10)) = rem(Model.Conditions.Present.Lysocline+5,10)/10;

%% Weathering
Silicate_Weathering = y(12)*y(14)*Model.Conditions.Present.Silicate_Weatherability;
% Carbonate_Weathering = y(13)*y(15)*Model.Conditions.Present.Carbonate_Weatherability;
Carbonate_Weathering = (1-OceanArray).*(y_Sub.*Model.Conditions.Present.Carbonate_Exposure).*y(15).*Model.Conditions.Present.Carbonate_Weatherability;

% Carbonate_Unearthed = Carbonate_Weathering.*Model.Conditions.Present.Carbonate_Replacement;
Silicate_Unearthed = Silicate_Weathering.*Model.Conditions.Present.Silicate_Replacement;

%% Carbon Fluxes
% POC
BiologicalPOCExport = BiologicalExport*Model.Conditions.Present.Redfield_Ratio;
POCBiologicalFlux = BiologicalPOCExport.*Model.Conditions.Present.POC_Remin;
POCBurialFlux = BiologicalPOCExport.*Model.Conditions.Present.POC_Burial;

BiologicalPICExport = BiologicalExport*Model.Conditions.Present.Redfield_Ratio*Model.Conditions.Present.Production_Ratio;

% Deep Remin
if Model.Conditions.Present.Carbonate_Surface_Sediment_Lock;
    Model.Conditions.Present.PIC_Burial(1,1) = (sum(Carbonate_Weathering)-POCBurialFlux(1))/BiologicalPICExport;
end
Ocean_Area_Fraction = 1-(CalculateRemin_MyLinear(Model.Conditions.Present.Hypsometric_Interpolation_Matrix,-y(18))/100);
Fraction_Above_Lysocline = (CalculateRemin_MyLinear(Model.Conditions.Present.Hypsometric_Interpolation_Matrix,Model.Conditions.Present.Lysocline)/100);
Model.Conditions.Present.PIC_Burial(2,1) = ((Fraction_Above_Lysocline-(1-Ocean_Area_Fraction))./Ocean_Area_Fraction)-(Model.Conditions.Present.PIC_Remin(1)+Model.Conditions.Present.PIC_Burial(1,1));
if Model.Conditions.Present.PIC_Burial(2,1)<0;
    Model.Conditions.Present.PIC_Burial(2,1) = 0;
end
Model.Conditions.Present.PIC_Remin(2,1) = 1-(sum(Model.Conditions.Present.PIC_Burial) + Model.Conditions.Present.PIC_Remin(1));

% DIC
DICRiverineFlux = Model.Conditions.Present.Riverine_Carbon*Model.Conditions.Present.Riverine_Volume;

DICMixingFlux = (y(6)-y(5)).*Model.Conditions.Present.Mixing_Coefficient.*Model.Architectures.BoxArea;

PICBiologicalFlux = (BiologicalPICExport.*Model.Conditions.Present.PIC_Remin);
PICBurialFlux = BiologicalPICExport.*Model.Conditions.Present.PIC_Burial;

[AirSeaExchange,SeaAirExchange] = GetAirSeaGasExchange(y(1),Model.Conditions.Present.CO2(1),Model.Conditions.Present.CCKs(1));

%% Atmosphere
GasFlux = ((SeaAirExchange-AirSeaExchange).*Model.Architectures.BoxArea);

%% DIC
DIC_Flux(1,1) = DICRiverineFlux + DICMixingFlux - BiologicalPICExport + PICBiologicalFlux(1) - BiologicalPOCExport + POCBiologicalFlux(1) - GasFlux;
DIC_Flux(2,1) = PICBiologicalFlux(2) - DICMixingFlux + POCBiologicalFlux(2);

%% Alkalinity Fluxes
AlkalinityRiverineFlux = Model.Conditions.Present.Riverine_Alkalinity*Model.Conditions.Present.Riverine_Volume;

AlkalinityMixingFlux = (y(8)-y(7)).*Model.Conditions.Present.Mixing_Coefficient.*Model.Architectures.BoxArea;

BiologicalAlkalinityExport = BiologicalExport*Model.Conditions.Present.Redfield_Ratio*Model.Conditions.Present.Production_Ratio*2;
AlkalinityBiologicalFlux = (BiologicalAlkalinityExport.*Model.Conditions.Present.PIC_Remin);

%% Alkalinity
Alkalinity_Flux(1,1) = AlkalinityRiverineFlux + AlkalinityMixingFlux - BiologicalAlkalinityExport + AlkalinityBiologicalFlux(1);
Alkalinity_Flux(2,1) = AlkalinityBiologicalFlux(2) - AlkalinityMixingFlux;

%% Subduction
Carbonate_SurfBuried = ((SurfArray.*Model.Conditions.Present.Hypsometry)./(sum(SurfArray.*Model.Conditions.Present.Hypsometry))).*PICBurialFlux(1);
Carbonate_DeepBuried = ((DeepArray.*Model.Conditions.Present.Hypsometry)./(sum(DeepArray.*Model.Conditions.Present.Hypsometry))).*PICBurialFlux(2);
% Carbonate_Buried = Carbonate_SurfBuried+Carbonate_DeepBuried;

if sum(DeepArray)==0;
    Carbonate_DeepBuried = zeros(numel(DeepArray),1);
end

% POCSurfArray = [ones(50,1);zeros(950,1)];
% POCDeepArray = [zeros(1050,1);ones((Model.Conditions.Present.POC_Burial_Max_Depth/10)-51,1);zeros(2001-(Model.Conditions.Present.POC_Burial_Max_Depth/10)+1,1)];
POCDeepArray = zeros(numel(y_Sub),1);
POCDeepArray(1051:(1000+Model.Conditions.Present.POC_Burial_Max_Depth/10)) = Model.Conditions.Present.Hypsometry(1051:(1000+Model.Conditions.Present.POC_Burial_Max_Depth/10));

% Carbonate_POCSurfBuried = (POCSurfArray./(sum(POCSurfArray))).*POCBurialFlux(1);
Carbonate_POCBuried = (POCDeepArray./(sum(POCDeepArray))).*POCBurialFlux(2);

Carbonate_Downgoing_Leaving = y_Sub.*Model.Conditions.Present.Subduction_Rate;
Carbonate_Downgoing_Entering = [0;Carbonate_Downgoing_Leaving(1:end-1)];
Carbonate_Upgoing_Leaving = y_Sub.*Model.Conditions.Present.Uplift_Rate;
Carbonate_Upgoing_Entering = [Carbonate_Upgoing_Leaving(2:end);0];
% Carbonate_Uplifted = [y_Sub((Model.Conditions.Present.Obduction_Depths(1)/10):(Model.Conditions.Present.Obduction_Depths(2)/10)).*Model.Conditions.Present.Obduction_Rate;zeros(numel(((Model.Conditions.Present.Obduction_Depths(2)/10)+1):2001),1)];
% Carbonate_Uplifted = zeros(numel(y_Sub),1);
% Carbonate_Uplifted(1000+(Model.Conditions.Present.Obduction_Depths(1)/10) : 1000+(Model.Conditions.Present.Obduction_Depths(2))/10) = Model.Conditions.Present.Obduction_Rate;
% Carbonate_Uplifted = Carbonate_Uplifted.*y_Sub;
Carbonate_Subducted = (y_Sub.*Model.Conditions.Present.Subduction_Gauss);

dy_Sub = (Carbonate_SurfBuried+Carbonate_DeepBuried+Carbonate_POCBuried+Carbonate_Downgoing_Entering+Carbonate_Upgoing_Entering-Carbonate_Downgoing_Leaving-Carbonate_Subducted-Carbonate_Upgoing_Leaving-Carbonate_Weathering);

%% Outgassing
Outgassing_Added = sum(Carbonate_Subducted);
% OutBoxes = floor(t/Model.Conditions.Present.Outgassing_Temporal_Resolution) + (Model.Conditions.Present.Outgassing_Mean_Lag + [(-3*Model.Conditions.Present.Outgassing_Spread),(3*Model.Conditions.Present.Outgassing_Spread)])/Model.Conditions.Present.Outgassing_Temporal_Resolution;
OutBoxes = floor((t+Model.Conditions.Present.Outgassing_Mean_Lag)/Model.Conditions.Present.Outgassing_Temporal_Resolution)+[-(numel(Model.Conditions.Present.Outgassing_Gauss)-1)/2,(numel(Model.Conditions.Present.Outgassing_Gauss)-1)/2];
dy_Outgas(OutBoxes(1):OutBoxes(2)) = (Outgassing_Added.*Model.Conditions.Present.Outgassing_Gauss);
% 
% Carbonate_Assimilated = 0.5*((y_Outgas(1+floor((t)/Model.Conditions.Present.Outgassing_Temporal_Resolution))/Model.Conditions.Present.Outgassing_Temporal_Resolution));
Outgassing = ((y_Outgas(1+floor((t)/Model.Conditions.Present.Outgassing_Temporal_Resolution))/Model.Conditions.Present.Outgassing_Temporal_Resolution));

%% Ice
Ice_Radius = ((3*Model.Conditions.Present.Water_Molar_Mass*y(17))./(Model.Conditions.Present.Ice_Density.*tand(Model.Conditions.Present.Ice_Angle))).^(1/3);
Ice_Height = Ice_Radius.*tand(Model.Conditions.Present.Ice_Angle);
Ice_Area = pi.*Ice_Radius.*sqrt(Ice_Radius.^2 + Ice_Height.^2);

Ice_Height_Top = Ice_Height-y(19);
if Ice_Height_Top>0;
    Ice_Radius_Top = Ice_Height_Top./tand(Model.Conditions.Present.Ice_Angle);
    Ice_Area_Top = pi.*Ice_Radius_Top.*sqrt(Ice_Radius_Top.^2 + Ice_Height_Top.^2);
else
    Ice_Height_Top = 0;
    Ice_Radius_Top = 0;
    Ice_Area_Top = 0;
end

% if Ice_Height_Top>0;
%     Ice_Radius_Top = Ice_Height_Top./tand(Model.Conditions.Present.Ice_Angle);
%     Ice_Area_Top = pi.*Ice_Radius_Top.*sqrt(Ice_Radius_Top.^2 + Ice_Height_Top.^2);
%     Ice_Area_Bottom = Ice_Area-Ice_Area_Top;
% else
%     Ice_Area_Top = 0;
%     Ice_Area_Bottom = Ice_Area;
% end

Ice_Flux = (Ice_Area_Top.*Model.Conditions.Present.Ice_Growth_Rate)-(y(17).*Model.Conditions.Present.Ice_Melt_Rate);

%% CO2
CO2_Flux = GasFlux + Outgassing - (2*Silicate_Weathering) - sum(Carbonate_Weathering);

%% Assign dys
% CO2
dy(1) = CO2_Flux./Model.Conditions.Present.Atmosphere_Volume;
% Algae
dy(2) = y(2)*((Model.Conditions.Present.Max_Growth_Rate*(y(3)/(Model.Conditions.Present.Biological_Half_Constant+y(3))))-Model.Conditions.Present.Mortality); %mol/m3/yr
% Phophate
dy(3:4) = (Phosphate_Flux./Model.Architectures.Volumes);
% DIC
dy(5:6) = DIC_Flux./Model.Architectures.Volumes;
% Alkalinity
dy(7:8) = Alkalinity_Flux./Model.Architectures.Volumes;
% Equilibrium temperature
T_eq = ((Model.Conditions.Present.Solar_Constant.*(1-Model.Conditions.Present.Albedo) + (4.*Model.Conditions.Present.Climate_Sensitivity.*y(16)))./(4.*Model.Conditions.Present.Emissivity*Model.Conditions.Present.Stefan_Boltzmann)).^0.25;
T_eq_Ocean = T_eq-Model.Conditions.Present.Ocean_Temperature_Offset;
% Temperature
dy(9) = (T_eq-y(9))./Model.Conditions.Present.Atmosphere_Equilibration_Timescale;
dy(10:11) = (T_eq_Ocean-y(10:11))./Model.Conditions.Present.Ocean_Equilibration_Timescale;
% Rocks
dy(12) = Model.Conditions.Present.Silicate_Replenishment + Silicate_Unearthed - Silicate_Weathering;
% dy(13) = sum(Carbonate_Uplifted)/(1/(1-Model.Conditions.Present.Carbonate_Replacement)) + Carbonate_Unearthed - Carbonate_Weathering;
% Weathering fraction
dy(14) = (((Model.Conditions.Present.Silicate_Weathering_Coefficient(1).*Model.Conditions.Present.Silicate_Weathering_Coefficient(2).*exp(Model.Conditions.Present.Silicate_Weathering_Coefficient(2).*y(9)))*(dy(9)))/2 + (((2*exp((-y(12)/Model.Conditions.Present.Silicate_Limiting_Threshold)).^2)/sqrt(pi))));
dy(15) = (((Model.Conditions.Present.Carbonate_Weathering_Coefficient(1).*Model.Conditions.Present.Carbonate_Weathering_Coefficient(2).*exp(Model.Conditions.Present.Carbonate_Weathering_Coefficient(2).*y(9)))*(dy(9)))/2 + (((2*exp((-y(13)/Model.Conditions.Present.Carbonate_Limiting_Threshold)).^2)/sqrt(pi))));
% Radiative forcing
dy(16) = Model.Conditions.Present.Radiative_Sensitivity.*1.4427.*log((y(1)+dy(1))/y(1));
% Ice
dy(17) = Ice_Flux;
% Sea level
dy(18) = (-((Ice_Flux*Model.Conditions.Present.Water_Molar_Mass)/Model.Conditions.Present.Ice_Density)./Model.Architectures.BoxArea) + Model.Conditions.Present.Sea_Level_Forcing;
% Snow Line
dy(19) = Model.Conditions.Present.Snow_Line_Sensitivity*dy(9);

%% Assign Globals
Model.Conditions.Present.HIn = (10.^(-Model.Conditions.Present.pH))*1000;

Model.Conditions.Present.Riverine_Carbon = (2*(Silicate_Weathering+sum(Carbonate_Weathering)))./Model.Conditions.Present.Riverine_Volume;
Model.Conditions.Present.Riverine_Alkalinity =(2*(Silicate_Weathering+sum(Carbonate_Weathering)))./Model.Conditions.Present.Riverine_Volume;

if any(isnan(y_Sub)) || any(y_Sub<0) || any(isnan(dy)) || any(y(1:8)<0);
  error('Something broke');
end

Model.Conditions.Present.Riverine_Phosphate = Model.Conditions.Constant.Riverine_Phosphate.*(y(14)./Model.Conditions.Initial.Silicate_Weathering_Fraction);
end
