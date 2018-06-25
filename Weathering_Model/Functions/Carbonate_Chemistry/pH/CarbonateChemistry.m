function [pH,CO2,HCO3,CO3,Omega,Ab] = CarbonateChemistry(Constant,DIC,AlkalinityT,HIn,CarbonateConstants);
%% CarbonateChemistry Calculates carbonate system parameters using dissolved inorganic carbon and alkalinity.
% Uses inputs: Constant (for concentrations held constant - boron and silica), DIC - Dissolved inorganic carbon, Alkalinity - , H - Concentration of H ions and CarbonateConstants - Dissociation constants calculated using separate function.
% Produces outputs: pH, CO2, HCO3, CO3, Omega (calcite), Ab - Borate Alkainity

%% KConstants
% All constants are evaluated for the correct temperature/pressure/salinity
% in a vectorised manner, where the number of elements of
% temperature/pressure/salinity must match the size of the
% CarbonateConstants in the third dimension.

%% ##ISSUES
% This converges to the same as csys when only boron and OH groups are
% considered. Adding in phosphate and silica should make it more accurate.

% Iteration does make a difference to the final result, the importance of
% this will have to be evaluated.

% Do I need fluoride??

% Nansum is FAIRLY inefficient - replace!

%% Separate constants from input
k0 = CarbonateConstants(:,1);
k1 = CarbonateConstants(:,2);
k2 = CarbonateConstants(:,3);
kb = CarbonateConstants(:,4);
kw = CarbonateConstants(:,5);
ksi = CarbonateConstants(:,6);
kf = CarbonateConstants(:,7);
ksp_Cal = CarbonateConstants(:,8);
ksp_Arag = CarbonateConstants(:,9);
kp1 = CarbonateConstants(:,10);
kp2 = CarbonateConstants(:,11);
kp3 = CarbonateConstants(:,12);

%% Additional Alkalinity Contributions
% Phosphate constants not used
denom = HIn.^3 + (kp1.*HIn.^2) + (kp1.*kp2.*HIn) + (kp1.*kp2.*kp3); %## Could be condensed
Ah3po4g = (Constant.Phosphate.*HIn.^3)./denom;
%     Ah2po4g = (Constant.SurfacePhosphate*kp1*HIn.^2)/denom;
Ahpo4g = (Constant.Phosphate.*kp1.*kp2.*HIn)./denom;
Apo4g = (Constant.Phosphate.*kp1.*kp2.*kp3)./denom;

% Borate
Ab = (kb./(kb+HIn)).*(Constant.Boron);

% OH
Aoh = (kw./(HIn));

% Silica ##UNUSED
Asi = (ksi.*Constant.Silica)./(ksi+HIn);

% Correction
Fh = HIn+Ah3po4g-Ab-Aoh-Asi-Ahpo4g-(2*Apo4g);

% Calculate total alkalinity
AlkalinityC = AlkalinityT+Fh;

%% Solve
% Use derivable quadratic
gamma = DIC./AlkalinityC;

%
HOut = (0.5.*((gamma-1).*k1 + sqrt( (((1-gamma).^2).*(k1.^2)) - (4.*k1.*k2.*(1-(2*gamma))) )));

pH = -log10(HOut/1000);

% Calculate individual components ## NECESSARY?
CO2 = DIC./(1+ k1./HOut + (k2.*k1)./(HOut.^2));
HCO3 = DIC./((HOut./k1) + 1 + (k2./HOut)');
CO3 = DIC./((HOut.^2)./(k1.*k2) + HOut./k2 + 1);

%% Saturation State
% Ca = 10.28; %mol/m^3 ## SHOULD SPECIFY OUTSIDE OF FUNCTION
Ksp = ksp_Cal; %mol^2/m^

% Saturation State = Product of concentrations over solubility
Omega = (Constant.Calcium.*CO3)./(Ksp);

end