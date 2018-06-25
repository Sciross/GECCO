function [pH,CO2,HCO3,CO3,B3,B4,HPlus,OH,H3PO4,H2PO4,HPO4,PO4,H3SiO4,H4SiO4,F,HF] = CarbonateChemistry_FullSpeciesOut_Iter(Constant,DIC,AlkalinityT,HIn,CarbonateConstants);
%% CarbonateChemistry Calculates carbonate system parameters using dissolved inorganic carbon and alkalinity.
% Uses inputs: Constant (for concentrations held constant - boron and silica), DIC - Dissolved inorganic carbon, Alkalinity - , H - Concentration of H ions and CarbonateConstants - Dissociation constants calculated using separate function.
% Produces outputs: pH, CO2, HCO3, CO3, Omega (calcite), Ab - Borate Alkainity

%% KConstants
% All constants are evaluated for the correct depth excluding ksp_Cal,
% which is evaluated for surface conditions as it is later subject to
% correction. ##MIGHT NOT BE TRUE ANY MORE

%% ##ISSUES
% This converges to the same as csys when only boron and OH groups are
% considered. Adding in phosphate and silica should make it more accurate.

% Iteration does make a difference to the final result, the importance of
% this will have to be evaluated.

%%
% Separate constants from input
k0 = CarbonateConstants(1,:)';
k1 = CarbonateConstants(2,:)';
k2 = CarbonateConstants(3,:)';
kb = CarbonateConstants(4,:)';
kw = CarbonateConstants(5,:)';
ksi = CarbonateConstants(6,:)';
kf = CarbonateConstants(7,:)';
ksp_Cal = CarbonateConstants(8,:)';
ksp_Arag = CarbonateConstants(9,:)';
kp1 = CarbonateConstants(10,:)';
kp2 = CarbonateConstants(11,:)';
kp3 = CarbonateConstants(12,:)';

%% Set up tolerance and anomaly;
Anomaly = 10000;
Tol = 0.001;

%% Additional Alkalinity Contributions
while Anomaly>Tol;
    % Phosphate constants not used
    denom = HIn.^3 + (kp1*HIn.^2) + (kp1*kp2*HIn) + (kp1*kp2*kp3); %## Could be condensed
    Ah3po4g = (Constant.SurfacePhosphate*HIn.^3)/denom;
%     Ah2po4g = (Constant.SurfacePhosphate*kp1*HIn.^2)/denom;
    Ahpo4g = (Constant.SurfacePhosphate*kp1*kp2*HIn)/denom;
    Apo4g = (Constant.SurfacePhosphate*kp1*kp2*kp3)/denom;
    
    % Borate
    Ab = (kb*Constant.SurfaceBoron)/(kb+HIn);
    
    % OH
    Aoh = (kw/HIn);
    
    % Silica
    Asi = (ksi*Constant.SurfaceSilica)/(ksi+HIn);
    
    % Correction
    Fh = HIn+Ah3po4g-Ab-Aoh-Asi-Ahpo4g-(2*Apo4g);
    
    % Calculate total alkalinity
    AlkalinityC = AlkalinityT+Fh;
    
    %% Solve
    % Use derivable quadratic
    gamma = DIC./AlkalinityC;
    
    %
    HOut = (0.5*((gamma-1)*k1 + sqrt( (((1-gamma).^2)*k1.^2) - (4*k1*k2*(1-(2*gamma))) )));
    
    pH = -log10(HOut/1000);
    
    % Calculate individual components
    CO2 = DIC./(1+ k1/HOut + (k2*k1)/(HOut.^2))';
    HCO3 = DIC./((HOut/k1) + 1 + (k2/HOut)');
    CO3 = DIC./((HOut.^2)/(k1*k2) + HOut/k2 + 1);
    
    % Other components
    B3 = Constant.SurfaceBoron./(1 + kb/HOut);
    B4 = Constant.SurfaceBoron./(1 + HOut/kb);
    
    HPlus = HOut;
    OH = kw/HPlus;
    
    H3PO4 = Constant.SurfacePhosphate./(1 + kp1/HOut + (kp1.*kp2)/(HOut.^2) + (kp1.*kp2.*kp3)/(HOut.^3));
    H2PO4 = Constant.SurfacePhosphate./(HOut./kp1 + 1 + kp2./HOut + (kp2.*kp3)/(HOut.^2));
    HPO4 = Constant.SurfacePhosphate./((HOut.^2)/(kp1.*kp2) + HOut./kp2 + 1 + kp3/HOut);
    PO4 = Constant.SurfacePhosphate./((HOut.^3)/(kp1.*kp2.*kp3) + (HOut.^2)/(kp2.*kp3) + HOut./kp3 + 1);
    
    H3SiO4 = Constant.SurfaceSilica./(HOut/ksi + 1);
    H4SiO4 = Constant.SurfaceSilica./(1 + ksi/HOut);
    
    F = Constant.SurfaceFluoride./(HOut/kf + 1);
    HF = Constant.SurfaceFluoride./(1 + kf/HOut);
    
    %% Saturation State
    Ksp = ksp_Cal; %mol^2/m^
    
    % Saturation State = Product of concentrations over solubility
    Omega = (Constant.Calcium*CO3)/(Ksp);
    
    %% Anomaly
    Anomaly = abs(pH+log10(HIn/1000));
    HIn = HOut;
end

end