function DefineInitialConditions_VariBox(Initial,Constant);

%% Define Initial Conditions
Initial.Mu = 0.2*365; %/yr
Initial.Algae = 0.01372265e-6; %8.25e-6;  %mol/m^3
% Initial.Surface.Phosphate =  0.12e-3; %0.7329e-3; %mol/m^3
% Initial.Deep.Phosphate = 1.90454e-3; %1.8291e-3; %mol/m^3
Initial.Phosphate = [0.12e-3,1.90454e-3];

% Initial.Surface.DIC = 2.001; %mol/m^3
% Initial.Deep.DIC = 2.2161; %mol/m^3

% Initial.Surface.Alkalinity = 2.301; %mol/m^3
% Initial.Deep.Alkalinity = 2.338; %mol/m^3

% Initial.Surface.POC = 0.2301; %mol/m3 (## ASSUMED ONE TENTH OF DIC)
% Initial.Deep.POC = 0.2124; %mol/m3 (## ASSUMED ONE TENTH OF DIC)

% Initial.Atmosphere.CO2 = 270*10^(-6); %atm

assignin('base','Initial',Initial);
assignin('base','Constant',Constant);

end
