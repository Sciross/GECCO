function [dy,dy_Sub,dy_Outgas] = Core(t,y,y_Sub,y_Outgas,Chunk_Number,Model)
% Change Values
for Transient_Index = 1:size(Model.Conditions.Transients.Matrix,1);
    if Model.Conditions.Transients.Matrix{Transient_Index,1}==Chunk_Number || strcmp(Model.Conditions.Transients.Matrix{Transient_Index,1},':');
        Model.Conditions.Presents.(Model.Conditions.Transients.Matrix{Transient_Index,2}).(Model.Conditions.Transients.Matrix{Transient_Index,3})(Model.Conditions.Transients.Matrix{Transient_Index,4}) = feval(Model.Conditions.Transients.Matrix{Transient_Index,5},t,Model.Conditions);
    end
end

% Preallocate
dy = zeros(numel(y),1);
dy_Sub = zeros(numel(y_Sub),1);
dy_Outgas = zeros(numel(y_Outgas),1);

%% Biology + Phosphate
% Biological export: Export = [A] * Ocean.Volume * Mortality
BiologicalExport = y(2)*Model.Conditions.Presents.Architecture.Ocean_Volumes(1)*Model.Conditions.Presents.Phosphate.Mortality; %mol/yr

% Fluxes
PhosphateFluxRivers = (Model.Conditions.Presents.Phosphate.Riverine_Concentration.*Model.Conditions.Presents.Architecture.Riverine_Volume);
PhosphateFluxMixing = Model.Conditions.Presents.Architecture.Mixing_Coefficient.*Model.Conditions.Presents.Architecture.Ocean_Area.*(y(4)-y(3));
BiologicalFlux = BiologicalExport.*Model.Conditions.Presents.Phosphate.Remineralisation;

Phosphate_Flux(1,1) = PhosphateFluxRivers + PhosphateFluxMixing + BiologicalFlux(1) - BiologicalExport;
Phosphate_Flux(2,1) = BiologicalFlux(2) - PhosphateFluxMixing;

%% Carbonate Chemistry
Model.Conditions.Presents.Carbonate_Chemistry.DIC = [y(5);y(6)];
Model.Conditions.Presents.Carbonate_Chemistry.Alkalinity = [y(7);y(8)];
Model.Conditions.Presents.Carbonate_Chemistry.Temperature = [y(10);y(11)];
Model.Conditions.Presents.Carbonate_Chemistry.Phosphate = [y(3);y(4)];

% Model.Conditions.Presents.Carbonate_Chemistry.Coefficients = GetCoefficients(Model.Conditions.Presents.Carbonate_Chemistry);
Model.Conditions.Presents.Carbonate_Chemistry.SetCoefficients();
% [Model.Conditions.Presents.Carbonate_Chemistry.CCKs,Model.Conditions.Presents.Carbonate_Chemistry.CCK_Depth_Correction] = GetCCKs(Model.Conditions.Presents.Carbonate_Chemistry.Salinity,Model.Conditions.Presents.Carbonate_Chemistry.Temperature,Model.Conditions.Presents.Carbonate_Chemistry.Pressure,Model.Conditions.Presents.Carbonate_Chemistry.Pressure_Correction,Model.Conditions.Presents.Carbonate_Chemistry.Coefficients);
Model.Conditions.Presents.Carbonate_Chemistry.SetCCKs();
% [Model.Conditions.Presents.Carbonate_Chemistry.pH,Model.Conditions.Presents.Carbonate_Chemistry.CO2,~,~,Model.Conditions.Presents.Carbonate_Chemistry.Saturation_State_C,~] = Model.Conditions.Presents.Carbonate_Chemistry.Solver_Handle(Model.Conditions.Presents.Carbonate_Chemistry.DIC,Model.Conditions.Presents.Carbonate_Chemistry.Alkalinity,{Model.Conditions.Presents.Carbonate_Chemistry.Boron,Model.Conditions.Presents.Carbonate_Chemistry.Silica,NaN,Model.Conditions.Presents.Carbonate_Chemistry.Calcium,Model.Conditions.Presents.Carbonate_Chemistry.Phosphate},Model.Conditions.Presents.Carbonate_Chemistry.HIn,Model.Conditions.Presents.Carbonate_Chemistry.CCKs,Model.Conditions.Presents.Carbonate_Chemistry.Iteration_Flag,Model.Conditions.Presents.Carbonate_Chemistry.Tolerance);
Model.Conditions.Presents.Carbonate_Chemistry.Solve();
% Model.Conditions.Presents.Carbonate_Chemistry.pH = Model.Conditions.Presents.Carbonate_Chemistry.pH;
Model.Conditions.Presents.Carbonate_Chemistry.H_In = pH2H(Model.Conditions.Presents.Carbonate_Chemistry.pH);

% Model.Conditions.Presents.Carbonate_Chemistry.Lysocline = Model.Conditions.Presents.Carbonate_Chemistry.Lysocline_Solver_Handle(Model.Conditions.Presents.Carbonate_Chemistry.DIC(2),Model.Conditions.Presents.Carbonate_Chemistry.Depths,Model.Conditions.Presents.Carbonate_Chemistry.Temperature,Model.Conditions.Presents.Carbonate_Chemistry.Salinity,Model.Conditions.Presents.Carbonate_Chemistry.pH,Model.Conditions.Presents.Carbonate_Chemistry.Calcium,Model.Conditions.Presents.Carbonate_Chemistry.Coefficients,Model.Conditions.Presents.Carbonate_Chemistry.Lysocline_In,Model.Conditions.Presents.Carbonate_Chemistry.Lysocline_Iteration_Flag,Model.Conditions.Presents.Carbonate_Chemistry.Lysocline_Tolerance);
Model.Conditions.Presents.Carbonate_Chemistry.Solve_Lysocline();
Model.Conditions.Presents.Carbonate_Chemistry.Lysocline_In = Model.Conditions.Presents.Carbonate_Chemistry.Lysocline;


%% Sea level arrays
if y(18)<-5;
     Edge_Box_Fill = 1+rem(y(18)+5,10)/10;
else
    Edge_Box_Fill = rem(y(18)+5,10)/10;
end

OceanArray = double(Model.Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints<round(y(17)));
OceanArray(1001-round(y(17)/10)) = Edge_Box_Fill;

SurfArray =  double(OceanArray & Model.Conditions.Presents.Architecture.Hypsometric_Bin_Midpoints>(round(y(17))-Model.Conditions.Presents.Architecture.Ocean_Depths(1)));
SurfArray(1001-round(y(17)/10)) = Edge_Box_Fill;
SurfArray(1001-(round(y(17)/10))+(Model.Conditions.Presents.Architecture.Ocean_Depths(1)/10)) = 1-Edge_Box_Fill;

DeepArray = double((Model.Conditions.Presents.Architecture.Hypsometric_Bin_Midpoints>(-Model.Conditions.Presents.Carbonate_Chemistry.Lysocline)) & OceanArray & ~SurfArray);
DeepArray(1001-(round(y(17)/10))+(Model.Conditions.Presents.Architecture.Ocean_Depths(1)/10)) = Edge_Box_Fill;
DeepArray(1001+round(Model.Conditions.Presents.Carbonate_Chemistry.Lysocline/10)) = rem(Model.Conditions.Presents.Carbonate_Chemistry.Lysocline+5,10)/10;

%% Weathering
Silicate_Weathering = y(12)*y(13)*Model.Conditions.Presents.Weathering.Silicate_Weatherability;
Silicate_Unearthed = Silicate_Weathering.*Model.Conditions.Presents.Weathering.Silicate_Replacement;

Carbonate_Weathering = (1-OceanArray).*(y_Sub.*Model.Conditions.Presents.Weathering.Carbonate_Exposure).*y(14).*Model.Conditions.Presents.Weathering.Carbonate_Weatherability;

%% Carbon Fluxes
% POC
BiologicalPOCExport = BiologicalExport*Model.Conditions.Presents.Carbon.Redfield_Ratio;
POCBiologicalFlux = BiologicalPOCExport.*Model.Conditions.Presents.Carbon.POC_Remineralisation;
POCBurialFlux = BiologicalPOCExport.*Model.Conditions.Presents.Carbon.POC_Burial;

BiologicalPICExport = sum(BiologicalExport*Model.Conditions.Presents.Carbon.Redfield_Ratio.*Model.Conditions.Presents.Carbon.Production_Ratio.*Model.Conditions.Presents.Carbon.Calcifier_Fraction);

% Deep Remineralisation
Ocean_Area_Fraction = 1-(CalculateRemin_MyLinear(Model.Conditions.Presents.Architecture.Hypsometric_Interpolation_Matrix,-y(17))/100);
Fraction_Above_Lysocline = (CalculateRemin_MyLinear(Model.Conditions.Presents.Architecture.Hypsometric_Interpolation_Matrix,Model.Conditions.Presents.Carbonate_Chemistry.Lysocline)/100);
Model.Conditions.Presents.Carbon.PIC_Burial(2,1) = ((Fraction_Above_Lysocline-(1-Ocean_Area_Fraction))./Ocean_Area_Fraction)-(Model.Conditions.Presents.Carbon.PIC_Remineralisation(1)+Model.Conditions.Presents.Carbon.PIC_Burial(1,1));
if Model.Conditions.Presents.Carbon.PIC_Burial(2,1)<0;
    Model.Conditions.Presents.Carbon.PIC_Burial(2,1) = 0;
end
Model.Conditions.Presents.Carbon.PIC_Remineralisation(2,1) = 1-(sum(Model.Conditions.Presents.Carbon.PIC_Burial) + Model.Conditions.Presents.Carbon.PIC_Remineralisation(1));

% DIC
DICRiverineFlux = Model.Conditions.Presents.Carbon.Riverine_Carbon.*Model.Conditions.Presents.Architecture.Riverine_Volume;

DICMixingFlux = (y(6)-y(5)).*Model.Conditions.Presents.Architecture.Mixing_Coefficient.*Model.Conditions.Presents.Architecture.Ocean_Area;

PICBiologicalFlux = (BiologicalPICExport.*Model.Conditions.Presents.Carbon.PIC_Remineralisation);
PICBurialFlux = BiologicalPICExport.*Model.Conditions.Presents.Carbon.PIC_Burial;

[AirSeaExchange,SeaAirExchange] = GetAirSeaGasExchange(y(1),Model.Conditions.Presents.Carbonate_Chemistry.CO2(1),Model.Conditions.Presents.Carbonate_Chemistry.CCKs(1));

%% Atmosphere
GasFlux = ((SeaAirExchange-AirSeaExchange).*Model.Conditions.Presents.Architecture.Ocean_Area);

%% DIC
DIC_Flux(1,1) = DICRiverineFlux + DICMixingFlux - BiologicalPICExport + PICBiologicalFlux(1) - BiologicalPOCExport + POCBiologicalFlux(1) - GasFlux;
DIC_Flux(2,1) = PICBiologicalFlux(2) - DICMixingFlux + POCBiologicalFlux(2);

%% Alkalinity Fluxes
AlkalinityRiverineFlux = Model.Conditions.Presents.Carbon.Riverine_Alkalinity*Model.Conditions.Presents.Architecture.Riverine_Volume;

AlkalinityMixingFlux = (y(8)-y(7)).*Model.Conditions.Presents.Architecture.Mixing_Coefficient.*Model.Conditions.Presents.Architecture.Ocean_Area;

BiologicalAlkalinityExport = BiologicalExport*Model.Conditions.Presents.Carbon.Redfield_Ratio*Model.Conditions.Presents.Carbon.Production_Ratio*2;
AlkalinityBiologicalFlux = (BiologicalAlkalinityExport.*Model.Conditions.Presents.Carbon.PIC_Remineralisation);

%% Alkalinity
Alkalinity_Flux(1,1) = AlkalinityRiverineFlux + AlkalinityMixingFlux - BiologicalAlkalinityExport + AlkalinityBiologicalFlux(1);
Alkalinity_Flux(2,1) = AlkalinityBiologicalFlux(2) - AlkalinityMixingFlux;

%% Subduction
Carbonate_SurfBuried = ((SurfArray.*Model.Conditions.Presents.Architecture.Hypsometry)./(sum(SurfArray.*Model.Conditions.Presents.Architecture.Hypsometry))).*PICBurialFlux(1);
Carbonate_DeepBuried = ((DeepArray.*Model.Conditions.Presents.Architecture.Hypsometry)./(sum(DeepArray.*Model.Conditions.Presents.Architecture.Hypsometry))).*PICBurialFlux(2);
% Carbonate_Buried = Carbonate_SurfBuried+Carbonate_DeepBuried;

if sum(DeepArray)==0;
    Carbonate_DeepBuried = zeros(numel(DeepArray),1);
end

% POCSurfArray = [ones(50,1);zeros(950,1)];
% POCDeepArray = [zeros(1050,1);ones((Model.Conditions.Presents.POC_Burial_Max_Depth/10)-51,1);zeros(2001-(Model.Conditions.Presents.POC_Burial_Max_Depth/10)+1,1)];
POCDeepArray = zeros(numel(y_Sub),1);
POCDeepArray(1051:(1000+Model.Conditions.Presents.Carbon.POC_Burial_Maximum_Depth/10)) = Model.Conditions.Presents.Architecture.Hypsometry(1051:(1000+Model.Conditions.Presents.Carbon.POC_Burial_Maximum_Depth/10));

% Carbonate_POCSurfBuried = (POCSurfArray./(sum(POCSurfArray))).*POCBurialFlux(1);
Carbonate_POCBuried = (POCDeepArray./(sum(POCDeepArray))).*POCBurialFlux(2);

Carbonate_Downgoing_Leaving = y_Sub.*Model.Conditions.Presents.Seafloor.Subduction_Rate;
Carbonate_Downgoing_Entering = [0;Carbonate_Downgoing_Leaving(1:end-1)];
Carbonate_Upgoing_Leaving = y_Sub.*Model.Conditions.Presents.Seafloor.Uplift_Rate;
Carbonate_Upgoing_Entering = [Carbonate_Upgoing_Leaving(2:end);0];
% Carbonate_Uplifted = [y_Sub((Model.Conditions.Presents.Obduction_Depths(1)/10):(Model.Conditions.Presents.Obduction_Depths(2)/10)).*Model.Conditions.Presents.Obduction_Rate;zeros(numel(((Model.Conditions.Presents.Obduction_Depths(2)/10)+1):2001),1)];
% Carbonate_Uplifted = zeros(numel(y_Sub),1);
% Carbonate_Uplifted(1000+(Model.Conditions.Presents.Obduction_Depths(1)/10) : 1000+(Model.Conditions.Presents.Obduction_Depths(2))/10) = Model.Conditions.Presents.Obduction_Rate;
% Carbonate_Uplifted = Carbonate_Uplifted.*y_Sub;
Carbonate_Subducted = (y_Sub.*Model.Conditions.Presents.Seafloor.Subduction_Gauss);

dy_Sub = (Carbonate_SurfBuried+Carbonate_DeepBuried+Carbonate_POCBuried+Carbonate_Downgoing_Entering+Carbonate_Upgoing_Entering-Carbonate_Downgoing_Leaving-Carbonate_Subducted-Carbonate_Upgoing_Leaving-Carbonate_Weathering);

%% Outgassing
Outgassing_Added = sum(Carbonate_Subducted);
% OutBoxes = floor(t/Model.Conditions.Presents.Outgassing_Temporal_Resolution) + (Model.Conditions.Presents.Outgassing_Mean_Lag + [(-3*Model.Conditions.Presents.Outgassing_Spread),(3*Model.Conditions.Presents.Outgassing_Spread)])/Model.Conditions.Presents.Outgassing_Temporal_Resolution;
OutBoxes = floor((t+Model.Conditions.Presents.Outgassing.Mean_Lag)/Model.Conditions.Presents.Outgassing.Temporal_Resolution)+[-(numel(Model.Conditions.Presents.Outgassing.Gauss)-1)/2,(numel(Model.Conditions.Presents.Outgassing.Gauss)-1)/2];
dy_Outgas(OutBoxes(1):OutBoxes(2)) = (Outgassing_Added.*Model.Conditions.Presents.Outgassing.Gauss);
% 
% Carbonate_Assimilated = 0.5*((y_Outgas(1+floor((t)/Model.Conditions.Presents.Outgassing_Temporal_Resolution))/Model.Conditions.Presents.Outgassing_Temporal_Resolution));
Outgassing = ((y_Outgas(1+floor((t)/Model.Conditions.Presents.Outgassing.Temporal_Resolution))/Model.Conditions.Presents.Outgassing.Temporal_Resolution));

%% Ice
Ice_Radius = ((3*Model.Conditions.Presents.Ice.Water_Molar_Mass*y(16))./(Model.Conditions.Presents.Ice.Density.*tand(Model.Conditions.Presents.Ice.Angle))).^(1/3);
Ice_Height = Ice_Radius.*tand(Model.Conditions.Presents.Ice.Angle);
Ice_Area = pi.*Ice_Radius.*sqrt(Ice_Radius.^2 + Ice_Height.^2);

Ice_Height_Top = Ice_Height-y(18);
if Ice_Height_Top>0;
    Ice_Radius_Top = Ice_Height_Top./tand(Model.Conditions.Presents.Ice.Angle);
    Ice_Area_Top = pi.*Ice_Radius_Top.*sqrt(Ice_Radius_Top.^2 + Ice_Height_Top.^2);
else
    Ice_Height_Top = 0;
    Ice_Radius_Top = 0;
    Ice_Area_Top = 0;
end
Ice_Flux = (Ice_Area_Top.*Model.Conditions.Presents.Ice.Growth_Rate)-(y(16).*Model.Conditions.Presents.Ice.Melt_Rate);

%% CO2
CO2_Flux = GasFlux + Outgassing - (2*Silicate_Weathering) - sum(Carbonate_Weathering);

%% Assign dys
% CO2
dy(1) = CO2_Flux./Model.Conditions.Presents.Architecture.Atmosphere_Volume;
% Algae
dy(2) = y(2)*((Model.Conditions.Presents.Phosphate.Maximum_Growth_Rate*(y(3)/(Model.Conditions.Presents.Phosphate.Biological_Half_Constant+y(3))))-Model.Conditions.Presents.Phosphate.Mortality)*Model.Conditions.Presents.Phosphate.Algal_Slowing_Factor; %mol/m3/yr
% Phophate
dy(3:4) = (Phosphate_Flux./Model.Conditions.Presents.Architecture.Ocean_Volumes);
% DIC
dy(5:6) = DIC_Flux./Model.Conditions.Presents.Architecture.Ocean_Volumes;
% Alkalinity
dy(7:8) = Alkalinity_Flux./Model.Conditions.Presents.Architecture.Ocean_Volumes;
% Equilibrium temperature
T_eq = ((Model.Conditions.Presents.Energy.Solar_Constant.*(1-Model.Conditions.Presents.Energy.Albedo) + (4.*Model.Conditions.Presents.Energy.Climate_Sensitivity.*y(15)))./(4.*Model.Conditions.Presents.Energy.Emissivity*Model.Conditions.Presents.Energy.Stefan_Boltzmann)).^0.25;
T_eq_Ocean = T_eq-Model.Conditions.Presents.Energy.Ocean_Temperature_Offset;
% Temperature
dy(9) = (T_eq-y(9))./Model.Conditions.Presents.Energy.Atmosphere_Equilibration_Timescale;
dy(10:11) = (T_eq_Ocean-y(10:11))./Model.Conditions.Presents.Energy.Ocean_Equilibration_Timescale;
% Rocks
dy(12) = Model.Conditions.Presents.Weathering.Silicate_Replenishment + Silicate_Unearthed - Silicate_Weathering;
% dy(13) = sum(Carbonate_Uplifted)/(1/(1-Model.Conditions.Presents.Carbonate_Replacement)) + Carbonate_Unearthed - Carbonate_Weathering;
% Weathering fraction
dy(13) = ((Model.Conditions.Presents.Weathering.Silicate_Weathering_Coefficients(1).*Model.Conditions.Presents.Weathering.Silicate_Weathering_Coefficients(2).*exp(Model.Conditions.Presents.Weathering.Silicate_Weathering_Coefficients(2).*y(9)))*(dy(9)))/2;
dy(14) = ((Model.Conditions.Presents.Weathering.Carbonate_Weathering_Coefficients(1).*Model.Conditions.Presents.Weathering.Carbonate_Weathering_Coefficients(2).*exp(Model.Conditions.Presents.Weathering.Carbonate_Weathering_Coefficients(2).*y(9)))*(dy(9)))/2;
% Radiative forcing
dy(15) = Model.Conditions.Presents.Energy.Radiative_Sensitivity.*1.4427.*log((y(1)+dy(1))/y(1));
% Ice
dy(16) = Ice_Flux;
% Sea level
dy(17) = (-((Ice_Flux*Model.Conditions.Presents.Ice.Water_Molar_Mass)/Model.Conditions.Presents.Ice.Density)./Model.Conditions.Presents.Architecture.Ocean_Area) + Model.Conditions.Presents.Ice.Sea_Level_Forcing;
% Snow Line
dy(18) = Model.Conditions.Presents.Ice.Snow_Line_Sensitivity*dy(9);

%% Assign Globals
% Model.Conditions.Presents.Carbonate_Chemistry.HIn = (10.^(-Model.Conditions.Presents.Carbonate_Chemistry.pH))*1000;

Model.Conditions.Presents.Carbon.Riverine_Carbon = (2*(Silicate_Weathering+sum(Carbonate_Weathering)))./Model.Conditions.Presents.Architecture.Riverine_Volume;
Model.Conditions.Presents.Carbon.Riverine_Alkalinity =(2*(Silicate_Weathering+sum(Carbonate_Weathering)))./Model.Conditions.Presents.Architecture.Riverine_Volume;

if any(isnan(y_Sub)) || any(y_Sub<0) || any(isnan(dy)) || any(y(1:8)<0) || any(~isreal(dy));
  error('Something broke');
end

Model.Conditions.Presents.Phosphate.Riverine_Concentration = Model.Conditions.Constants.Phosphate.Riverine_Concentration*(y(13)./Model.Conditions.Initials.Silicate_Weathering_Fraction);
end
