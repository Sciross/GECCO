function Initial = DefineInitialConditions_OO(Initial);

%% Define Initial Conditions
% Initial.Mu = 0.2*365; %/yr
Initial.Algae = 2.0548e-6; %8.25e-6;  %mol/m^3
Initial.Phosphate =  [0.12e-3;0.84e-3]; %0.7329e-3; %mol/m^3

Initial.Atmosphere_CO2 = 300.0e-6; %atm
Initial.DIC = [2.04;2.2]; %mol/m^3
Initial.Alkalinity = [2.22;2.31]; %mol/m^3

Initial.Atmosphere_Temperature =15+273.15;
Initial.Ocean_Temperature = [14;3]+273.15;

Initial.Silicate = 3.4953e19; %mol ### Random Guess
Initial.Carbonate = 1.6664e20; %mol ### Random Guess

Initial.Silicate_Weathering_Fraction = NaN; % LOSCAR = 12e12mol/yr
Initial.Carbonate_Weathering_Fraction = NaN; % ### Random Guess

Initial.Radiation = 0; % Start with no extra

Initial.Conditions = [Initial.Atmosphere_CO2; %1
                      Initial.Algae; %2
                      Initial.Phosphate; %3,4
                      Initial.DIC; %5,6
                      Initial.Alkalinity; %7,8
                      Initial.Atmosphere_Temperature; %9
                      Initial.Ocean_Temperature; %10,11
                      Initial.Silicate; %12
                      Initial.Carbonate; %13
                      Initial.Silicate_Weathering_Fraction; %14
                      Initial.Carbonate_Weathering_Fraction; %15
                      Initial.Radiation;]; %16

Initial.Seafloor = zeros(1000,1);
Initial.Outgassing = [];

end
