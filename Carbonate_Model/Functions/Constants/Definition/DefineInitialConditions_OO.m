function Initial = DefineInitialConditions_OO(Initial);

%% Define Initial Conditions
Initial.Mu = 0.2*365; %/yr
Initial.Algae = 2.74e-6; %8.25e-6;  %mol/m^3
Initial.Phosphate =  [0.12e-3;1.72e-3]; %0.7329e-3; %mol/m^3
% Initial.Deep.Phosphate = ; %1.8291e-3; %mol/m^3

Initial.DIC = [2.001;2.29]; %mol/m^3
% Initial.Deep.DIC = 2.2161; %mol/m^3

Initial.Alkalinity = [2.31;2.42]; %mol/m^3
% Initial.Deep.Alkalinity = 2.338; %mol/m^3

% Initial.Surface.POC = 0.2301; %mol/m3 (## ASSUMED ONE TENTH OF DIC)
% Initial.Deep.POC = 0.2124; %mol/m3 (## ASSUMED ONE TENTH OF DIC)

Initial.Atmosphere_CO2 = 300e-6; %atm

Initial.Conditions = [Initial.Atmosphere_CO2,Initial.Algae,Initial.Phosphate',Initial.DIC',Initial.Alkalinity'];

end
