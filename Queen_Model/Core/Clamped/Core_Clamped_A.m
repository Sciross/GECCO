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
    Phosphate_Neritic_Biological_Export = y(2)*Model.Conditions.Presents.Architecture.Ocean_Volumes(1)*Model.Conditions.Presents.Phosphate.Mortality.*Model.Conditions.Presents.Phosphate.Productivity_Split(1); %mol/yr
    Phosphate_Pelagic_Biological_Export = y(2)*Model.Conditions.Presents.Architecture.Ocean_Volumes(1)*Model.Conditions.Presents.Phosphate.Mortality.*Model.Conditions.Presents.Phosphate.Productivity_Split(2); %mol/yr

    Phosphate_Biological_Neritic_Influx = Phosphate_Neritic_Biological_Export.*Model.Conditions.Presents.Phosphate.Neritic_Remineralisation;
    Phosphate_Biological_Pelagic_Influx = Phosphate_Pelagic_Biological_Export.*Model.Conditions.Presents.Phosphate.Pelagic_Remineralisation;
    
    % Fluxes
    Phosphate_Flux_Rivers = (Model.Conditions.Presents.Phosphate.Riverine_Concentration.*Model.Conditions.Presents.Architecture.Riverine_Volume);
    Phosphate_Flux_Mixing = Model.Conditions.Presents.Architecture.Mixing_Coefficient.*Model.Conditions.Presents.Architecture.Ocean_Area.*(y(4)-y(3));

    Phosphate_Flux_Total(1,1) = Phosphate_Flux_Rivers + Phosphate_Flux_Mixing + Phosphate_Biological_Neritic_Influx(1) + Phosphate_Biological_Pelagic_Influx(1) - Phosphate_Neritic_Biological_Export - Phosphate_Pelagic_Biological_Export;
    Phosphate_Flux_Total(2,1) = Phosphate_Biological_Pelagic_Influx(2) - Phosphate_Flux_Mixing;
    % Phosphate_Burial = Phosphate_Flux_Rivers-sum(Phosphate_Flux_Total);

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

    %% POC Fluxes
    Neritic_Biological_POC_Export = Phosphate_Neritic_Biological_Export*Model.Conditions.Presents.Carbon.Redfield_Ratio;
    Pelagic_Biological_POC_Export = Phosphate_Pelagic_Biological_Export*Model.Conditions.Presents.Carbon.Redfield_Ratio;

    POC_Neritic_Biological_Influx = (Neritic_Biological_POC_Export.*Model.Conditions.Presents.Carbon.POC_Neritic_Remineralisation);
    POC_Pelagic_Biological_Influx = (Pelagic_Biological_POC_Export.*Model.Conditions.Presents.Carbon.POC_Pelagic_Remineralisation);

    POC_Burial_Flux(1) = Neritic_Biological_POC_Export.*Model.Conditions.Presents.Carbon.POC_Neritic_Burial(1);
    POC_Burial_Flux(2) = Pelagic_Biological_POC_Export.*Model.Conditions.Presents.Carbon.POC_Pelagic_Burial(2);
    
    %% PIC Coefficients    
    % Calculate PIC Remineralisation and Burial Coefficients
    Ocean_Area_Fraction = 1-(CalculateRemin_MyLinear(Model.Conditions.Presents.Architecture.Hypsometric_Interpolation_Matrix,-y(17))/100);
    Fraction_Above_Lysocline = (CalculateRemin_MyLinear(Model.Conditions.Presents.Architecture.Hypsometric_Interpolation_Matrix,Model.Conditions.Presents.Carbonate_Chemistry.Lysocline)/100);
    
    Model.Conditions.Presents.Carbon.PIC_Pelagic_Burial(2,1) = ((Fraction_Above_Lysocline-(1-Ocean_Area_Fraction))./Ocean_Area_Fraction)-Model.Conditions.Presents.Carbon.PIC_Pelagic_Remineralisation(1);
    Model.Conditions.Presents.Carbon.PIC_Pelagic_Remineralisation(2,1) = 1-(Model.Conditions.Presents.Carbon.PIC_Pelagic_Burial(2));
    
    %% PIC Fluxes
    PIC_Neritic_Biological_Export = Phosphate_Neritic_Biological_Export*Model.Conditions.Presents.Carbon.Redfield_Ratio*Model.Conditions.Presents.Carbon.Calcifier_Fraction(1)*Model.Conditions.Presents.Carbon.Production_Ratio(1);
    PIC_Pelagic_Biological_Export = Phosphate_Pelagic_Biological_Export*Model.Conditions.Presents.Carbon.Redfield_Ratio*Model.Conditions.Presents.Carbon.Calcifier_Fraction(2)*Model.Conditions.Presents.Carbon.Production_Ratio(2);

    PIC_Biological_Neritic_Influx = PIC_Neritic_Biological_Export.*Model.Conditions.Presents.Carbon.PIC_Neritic_Remineralisation;
    PIC_Biological_Pelagic_Influx = PIC_Pelagic_Biological_Export.*Model.Conditions.Presents.Carbon.PIC_Pelagic_Remineralisation;
    
    PIC_Burial_Flux(1) = PIC_Neritic_Biological_Export.*Model.Conditions.Presents.Carbon.PIC_Neritic_Burial(1);
    PIC_Burial_Flux(2) = PIC_Pelagic_Biological_Export.*Model.Conditions.Presents.Carbon.PIC_Pelagic_Burial(2);
    
    %% Atmosphere
    [AirSeaExchange,SeaAirExchange] = GetAirSeaGasExchange(y(1),Model.Conditions.Presents.Carbonate_Chemistry.CO2(1),Model.Conditions.Presents.Carbonate_Chemistry.CCKs(1));
    GasFlux = ((SeaAirExchange-AirSeaExchange).*Model.Conditions.Presents.Architecture.Ocean_Area);

    %% DIC Fluxes
    DIC_Riverine_Flux = Model.Conditions.Presents.Carbon.Riverine_Carbon.*Model.Conditions.Presents.Architecture.Riverine_Volume;
    DIC_Mixing_Flux = (y(6)-y(5)).*Model.Conditions.Presents.Architecture.Mixing_Coefficient.*Model.Conditions.Presents.Architecture.Ocean_Area;
    
    DIC_Flux(1,1) = DIC_Riverine_Flux + DIC_Mixing_Flux - PIC_Neritic_Biological_Export + PIC_Biological_Neritic_Influx(1) - PIC_Pelagic_Biological_Export + PIC_Biological_Pelagic_Influx(1) - Neritic_Biological_POC_Export + POC_Neritic_Biological_Influx(1) - Pelagic_Biological_POC_Export + POC_Pelagic_Biological_Influx(1) - GasFlux;
    DIC_Flux(2,1) = PIC_Biological_Neritic_Influx(2) + PIC_Biological_Pelagic_Influx(2) - DIC_Mixing_Flux + POC_Neritic_Biological_Influx(2) + POC_Pelagic_Biological_Influx(2);

    %% Alkalinity Fluxes
    Alkalinity_Riverine_Flux = Model.Conditions.Presents.Carbon.Riverine_Alkalinity*Model.Conditions.Presents.Architecture.Riverine_Volume;
    Alkalinity_Mixing_Flux = (y(8)-y(7)).*Model.Conditions.Presents.Architecture.Mixing_Coefficient.*Model.Conditions.Presents.Architecture.Ocean_Area;

    Alkalinity_Biological_Neritic_Export = PIC_Neritic_Biological_Export.*2;
    Alkalinity_Biological_Pelagic_Export = PIC_Pelagic_Biological_Export.*2;

    Alkalinity_Biological_Neritic_Influx = Alkalinity_Biological_Neritic_Export.*Model.Conditions.Presents.Carbon.PIC_Neritic_Remineralisation;
    Alkalinity_Biological_Pelagic_Influx = Alkalinity_Biological_Pelagic_Export.*Model.Conditions.Presents.Carbon.PIC_Pelagic_Remineralisation;

    Alkalinity_Neritic_Burial_Flux = Alkalinity_Biological_Neritic_Export.*Model.Conditions.Presents.Carbon.PIC_Neritic_Burial;
    Alkalinity_Pelagic_Burial_Flux = Alkalinity_Biological_Pelagic_Export.*Model.Conditions.Presents.Carbon.PIC_Pelagic_Burial;

    %% Alkalinity
    Alkalinity_Flux(1,1) = Alkalinity_Riverine_Flux + Alkalinity_Mixing_Flux - Alkalinity_Biological_Neritic_Export + Alkalinity_Biological_Neritic_Influx(1) - Alkalinity_Biological_Pelagic_Export + Alkalinity_Biological_Pelagic_Influx(1);
    Alkalinity_Flux(2,1) = Alkalinity_Biological_Neritic_Influx(2) + Alkalinity_Biological_Pelagic_Influx(2) - Alkalinity_Mixing_Flux;

    %% Subduction
    Carbonate_SurfBuried = ((SurfArray.*Model.Conditions.Presents.Architecture.Hypsometry)./(sum(SurfArray.*Model.Conditions.Presents.Architecture.Hypsometry))).*PIC_Burial_Flux(1);
    Carbonate_DeepBuried = ((DeepArray.*Model.Conditions.Presents.Architecture.Hypsometry)./(sum(DeepArray.*Model.Conditions.Presents.Architecture.Hypsometry))).*PIC_Burial_Flux(2);

    if sum(DeepArray)==0;
        Carbonate_DeepBuried = zeros(numel(DeepArray),1);
    end

    POCDeepArray = zeros(numel(y_Sub),1);
    POCDeepArray(1051:(1000+Model.Conditions.Presents.Carbon.POC_Burial_Maximum_Depth/10)) = Model.Conditions.Presents.Architecture.Hypsometry(1051:(1000+Model.Conditions.Presents.Carbon.POC_Burial_Maximum_Depth/10));

    Carbonate_POCBuried = (POCDeepArray./(sum(POCDeepArray))).*POC_Burial_Flux(2);

    Carbonate_Downgoing_Leaving = y_Sub.*Model.Conditions.Presents.Seafloor.Subduction_Rate;
    Carbonate_Downgoing_Entering = [0;Carbonate_Downgoing_Leaving(1:end-1)];
    Carbonate_Upgoing_Leaving = y_Sub.*Model.Conditions.Presents.Seafloor.Uplift_Rate;
    Carbonate_Upgoing_Entering = [Carbonate_Upgoing_Leaving(2:end);0];
    Carbonate_Subducted = (y_Sub.*Model.Conditions.Presents.Seafloor.Subduction_Gauss);

    dy_Sub = (Carbonate_SurfBuried+Carbonate_DeepBuried+Carbonate_POCBuried+Carbonate_Downgoing_Entering+Carbonate_Upgoing_Entering-Carbonate_Downgoing_Leaving-Carbonate_Subducted-Carbonate_Upgoing_Leaving-Carbonate_Weathering);

    %% Outgassing
    Outgassing_Added = sum(Carbonate_Subducted);
    OutBoxes = floor((t+Model.Conditions.Presents.Outgassing.Mean_Lag)/Model.Conditions.Presents.Outgassing.Temporal_Resolution)+[-(numel(Model.Conditions.Presents.Outgassing.Gauss)-1)/2,(numel(Model.Conditions.Presents.Outgassing.Gauss)-1)/2];
    
    dy_Outgas(OutBoxes(1):OutBoxes(2)) = (Outgassing_Added.*Model.Conditions.Presents.Outgassing.Gauss);
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
    dy(1) = 0; % CO2_Flux./Model.Conditions.Presents.Architecture.Atmosphere_Volume;
    % Algae
    dy(2) = y(2)*((Model.Conditions.Presents.Phosphate.Maximum_Growth_Rate*(y(3)/(Model.Conditions.Presents.Phosphate.Biological_Half_Constant+y(3))))-Model.Conditions.Presents.Phosphate.Mortality)*Model.Conditions.Presents.Phosphate.Algal_Slowing_Factor; %mol/m3/yr
    % Phophate
    dy(3:4) = (Phosphate_Flux_Total./Model.Conditions.Presents.Architecture.Ocean_Volumes);
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
    Model.Conditions.Presents.Carbon.Riverine_Carbon = (2*(Silicate_Weathering+sum(Carbonate_Weathering)))./Model.Conditions.Presents.Architecture.Riverine_Volume;
    Model.Conditions.Presents.Carbon.Riverine_Alkalinity =(2*(Silicate_Weathering+sum(Carbonate_Weathering)))./Model.Conditions.Presents.Architecture.Riverine_Volume;

    if any(isnan(y_Sub)) || any(y_Sub<0) || any(isnan(dy)) || any(y(1:8)<0) || any(~isreal(dy));
      error('Something broke');
    end

    Model.Conditions.Presents.Phosphate.Riverine_Concentration = Model.Conditions.Constants.Phosphate.Riverine_Concentration*(y(13)./Model.Conditions.Initials.Silicate_Weathering_Fraction);
end
