function [dy,dy_Sub,dy_Meta] = Core(t,y,y_Sub,y_Meta,Model)
% Change Values
for n = 1:size(Model.Conditions.Variable,1);
    if numel(Model.Conditions.Constant.(Model.Conditions.Variable{n,1}{1}))==1;
        Model.Conditions.Present.(Model.Conditions.Variable{n,1}{1}) = feval(Model.Conditions.Variable{n,3},t,Model.Conditions);
    else
        Model.Conditions.Present.(Model.Conditions.Variable{n,1}{1})(Model.Conditions.Variable{n,2}) = feval(Model.Conditions.Variable{n,3},t,Model.Conditions);
    end
end

% Preallocate
dy = zeros(numel(y),1);
dy_Sub = zeros(numel(y_Sub),1);
dy_Meta = zeros(numel(y_Meta),1);

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

%% Weathering
Silicate_Weathering = y(12)*y(14)*Model.Conditions.Present.Silicate_Weatherability;
Carbonate_Weathering = y(13)*y(15)*Model.Conditions.Present.Carbonate_Weatherability;

Carbonate_Unearthed = Carbonate_Weathering.*Model.Conditions.Present.Carbonate_Replacement;
Silicate_Unearthed = Silicate_Weathering.*Model.Conditions.Present.Silicate_Replacement;

%% Carbon Fluxes
% POC
BiologicalPOCExport = BiologicalExport*Model.Conditions.Present.Redfield_Ratio;
POCBiologicalFlux = BiologicalPOCExport.*Model.Conditions.Present.POC_Remin;
POCBurialFlux = BiologicalPOCExport.*Model.Conditions.Present.POC_Burial;

BiologicalPICExport = BiologicalExport*Model.Conditions.Present.Redfield_Ratio*Model.Conditions.Present.Production_Ratio;

% Deep Remin
if Model.Conditions.Present.Carbonate_Surface_Sediment_Lock;
    Model.Conditions.Present.PIC_Burial(1,1) = (Carbonate_Weathering-POCBurialFlux(1))/BiologicalPICExport;
end
Model.Conditions.Present.PIC_Burial(2,1) = ((CalculateRemin_MyLinear(Model.Conditions.Present.Hypsometric_Interpolation_Matrix,Model.Conditions.Present.Lysocline)/100)-Model.Conditions.Present.PIC_Burial(1,1)).*(1-Model.Conditions.Present.PIC_Remin(1));
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
SurfArray = [ones(50,1);zeros(950,1)];
DeepArray = double((Model.Conditions.Constant.Hypsometric_Bin_Midpoints<Model.Conditions.Present.Lysocline)&~SurfArray);
DeepArray(floor(Model.Conditions.Present.Lysocline/10)+1) = rem(Model.Conditions.Present.Lysocline,10)/10;

Carbonate_SurfBuried = (SurfArray./(sum(SurfArray))).*PICBurialFlux(1);
Carbonate_DeepBuried = (DeepArray./(sum(DeepArray))).*PICBurialFlux(2);
Carbonate_Buried = Carbonate_SurfBuried+Carbonate_DeepBuried;

if sum(DeepArray)==0;
    Carbonate_Buried = zeros(numel(DeepArray),1);
end

% POCSurfArray = [ones(50,1);zeros(950,1)];
POCDeepArray = [zeros(50,1);ones((Model.Conditions.Present.POC_Burial_Max_Depth/10)-51,1);zeros(1000-(Model.Conditions.Present.POC_Burial_Max_Depth/10)+1,1)];

% Carbonate_POCSurfBuried = (POCSurfArray./(sum(POCSurfArray))).*POCBurialFlux(1);
Carbonate_POCDeepBuried = (POCDeepArray./(sum(POCDeepArray))).*POCBurialFlux(2);
Carbonate_POCBuried = Carbonate_POCDeepBuried; %Carbonate_POCSurfBuried+Carbonate_POCDeepBuried;

Carbonate_ShiftedIn = [0;y_Sub(1:end-1)].*[0;Model.Conditions.Present.Subduction_Rate(1:end-1)];
Carbonate_ShiftedOut = y_Sub.*Model.Conditions.Present.Subduction_Rate;
Carbonate_Obducted = [y_Sub((Model.Conditions.Present.Obduction_Depths(1)/10):(Model.Conditions.Present.Obduction_Depths(2)/10)).*Model.Conditions.Present.Obduction_Rate;zeros(numel(((Model.Conditions.Present.Obduction_Depths(2)/10)+1):1000),1)];
Carbonate_Removed = (y_Sub.*Model.Conditions.Present.Subduction_Gauss);

dy_Sub = (Carbonate_Buried+Carbonate_POCBuried+Carbonate_ShiftedIn-Carbonate_ShiftedOut-Carbonate_Removed-Carbonate_Obducted);

%% Outgassing
Outgassing_Added = sum(Carbonate_Removed);
MetaBoxes = floor(t/Model.Conditions.Present.Outgassing_Temporal_Resolution) + (Model.Conditions.Present.Outgassing_Mean_Lag + [(-4*Model.Conditions.Present.Outgassing_Spread),(4*Model.Conditions.Present.Outgassing_Spread)])/Model.Conditions.Present.Outgassing_Temporal_Resolution;
dy_Meta(MetaBoxes(1):MetaBoxes(2)) = (Outgassing_Added.*Model.Conditions.Present.Outgassing_Gauss);

Outgassing_Amp = ((y_Meta(1+floor((t)/Model.Conditions.Present.Outgassing_Temporal_Resolution))/Model.Conditions.Present.Outgassing_Temporal_Resolution))/(Model.Conditions.Initial.Outgassing(1)/Model.Conditions.Present.Outgassing_Temporal_Resolution);
Carbonate_Amp = y(13)/(Model.Conditions.Initial.Carbonate);
Carbonate_Assimilated = (3e12).*Outgassing_Amp.*Carbonate_Amp;
Outgassing = ((y_Meta(1+floor((t)/Model.Conditions.Present.Outgassing_Temporal_Resolution))/Model.Conditions.Present.Outgassing_Temporal_Resolution)) + Carbonate_Assimilated;

%% CO2
CO2_Flux = GasFlux + Outgassing - (2*Silicate_Weathering) - Carbonate_Weathering;

%% Assign dys
% Flux over volume
dy(1) = 0; %CO2_Flux./Model.Conditions.Present.Atmosphere_Volume;

%% Temperature
dy(16) = Model.Conditions.Present.Radiative_Sensitivity.*1.4427.*log((y(1)+dy(1))/y(1));
T_eq = ((Model.Conditions.Present.Solar_Constant.*(1-Model.Conditions.Present.Albedo) + (4.*Model.Conditions.Present.Climate_Sensitivity.*y(16)))./(4.*Model.Conditions.Present.Emissivity*Model.Conditions.Present.Stefan_Boltzmann)).^0.25;
T_eq_Ocean = T_eq-Model.Conditions.Present.Ocean_Temperature_Offset;

% Combined rate expression for Algae number
dy(2) = y(2)*((Model.Conditions.Present.Max_Growth_Rate*(y(3)/(Model.Conditions.Present.Biological_Half_Constant+y(3))))-Model.Conditions.Present.Mortality)*0.001; %mol/m3/yr
% Flux over volume
dy(3:4) = (Phosphate_Flux./Model.Architectures.Volumes);
% Flux over volume
dy(5:6) = DIC_Flux./Model.Architectures.Volumes;
% Flux over volume
dy(7:8) = Alkalinity_Flux./Model.Architectures.Volumes;
% Approach equilibrium temperature over specified timescale
dy(9) = (T_eq-y(9))./Model.Conditions.Present.Atmosphere_Equilibration_Timescale;
% Approach equilibrium ocean temperature at specified timescales
dy(10:11) = (T_eq_Ocean-y(10:11))./Model.Conditions.Present.Ocean_Equilibration_Timescale;
dy(12) = Model.Conditions.Present.Silicate_Replenishment + Silicate_Unearthed - Silicate_Weathering;
dy(13) = sum(Carbonate_Obducted)/(1/(1-Model.Conditions.Present.Carbonate_Replacement)) + Carbonate_Unearthed - Carbonate_Weathering - Carbonate_Assimilated;

%% Assign Globals
Model.Conditions.Present.HIn = (10.^(-Model.Conditions.Present.pH))*1000;

dy(14) = (((Model.Conditions.Present.Silicate_Weathering_Coefficient(1).*Model.Conditions.Present.Silicate_Weathering_Coefficient(2).*exp(Model.Conditions.Present.Silicate_Weathering_Coefficient(2).*y(9)))*(dy(9)))/2 + (((2*exp((-y(12)/Model.Conditions.Present.Silicate_Limiting_Threshold)).^2)/sqrt(pi))));
dy(15) = (((Model.Conditions.Present.Carbonate_Weathering_Coefficient(1).*Model.Conditions.Present.Carbonate_Weathering_Coefficient(2).*exp(Model.Conditions.Present.Carbonate_Weathering_Coefficient(2).*y(9)))*(dy(9)))/2 + (((2*exp((-y(13)/Model.Conditions.Present.Carbonate_Limiting_Threshold)).^2)/sqrt(pi))));

Model.Conditions.Present.Riverine_Carbon = (2*(Silicate_Weathering+Carbonate_Weathering))./Model.Conditions.Present.Riverine_Volume;
Model.Conditions.Present.Riverine_Alkalinity =(2*(Silicate_Weathering+Carbonate_Weathering))./Model.Conditions.Present.Riverine_Volume;

% Model.Conditions.Present.Riverine_Phosphate = Model.Conditions.Present.Riverine_Phosphate+((dy(14).*1e-3)./Model.Conditions.Present.Riverine_Volume);


end
