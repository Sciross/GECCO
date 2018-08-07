function Initial = DefineInitial(Initial);

%% Define Initial Conditions
% Initial.Mu = 0.2*365; %/yr
Initial.Algae = 2.0548e-6; %8.25e-6;  %mol/m^3
Initial.Phosphate =  [0.12e-3;0.84e-3]; %0.7329e-3; %mol/m^3

Initial.Atmosphere_CO2 = 300.0e-6; %atm
Initial.DIC = [2.04;2.2]; %mol/m^3
Initial.Alkalinity = [2.22;2.31]; %mol/m^3

Initial.Atmosphere_Temperature =15+273.15;
Initial.Ocean_Temperature = [14;3]+273.15;

Initial.Silicate = 1.667e19; %3.4953e19; %mol Assumes 5e19molCaCO3 exposed, and 75:25 sedimentary:igneous ratio
% Initial.Carbonate = 1.6664e20; %mol ### Random Guess

Initial.Silicate_Weathering_Fraction = NaN; % LOSCAR = 12e12mol/yr
Initial.Carbonate_Weathering_Fraction = NaN; % ### Random Guess

Initial.Radiation = 0; % Start with no extra

Initial.Ice = 1.5e21; %mol

Initial.Sea_Level = 0; %m

Initial.Snow_Line = 500; %m

Initial.Seafloor = [zeros(500,1);linspace(0,8e19,551)';zeros(2001-(551+500),1)];
Initial.Outgassing = [];

end
