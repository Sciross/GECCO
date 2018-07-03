function [pH,CO2,HCO3,CO3,Omega,Ab] = Carbonate_Chemistry_Solver(DIC,Total_Alkalinity,Concentrations,HIn,CCKs,Iteration_Flag,Tolerance);
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

% Do I need fluoride??

% Nansum is FAIRLY inefficient - replace!

%% Separate constants from input
CCK0 = CCKs(:,1);
CCK1 = CCKs(:,2);
CCK2 = CCKs(:,3);
CCKb = CCKs(:,4);
CCKw = CCKs(:,5);
CCKsi = CCKs(:,6);
CCKf = CCKs(:,7);
CCKsp_Cal = CCKs(:,8);
CCKsp_Arag = CCKs(:,9);
CCKp1 = CCKs(:,10);
CCKp2 = CCKs(:,11);
CCKp3 = CCKs(:,12);

%% Separate concentrations from input
Boron = Concentrations{1};
Silica = Concentrations{2};
Fluoride = Concentrations{3};
Calcium = Concentrations{4};
Phosphate = Concentrations{5};

%% Prespecify
if Iteration_Flag;
    Anomaly = [10000;10000];
    if nargin<7;
        Tolerance = [0.0001;0.0001];
    elseif numel(Tolerance)==1;
        Tolerance = [Tolerance;Tolerance];
    end
end

if ~Iteration_Flag;
    %% Additional Alkalinity Contributions
    % Phosphate
    denom = HIn.^3 + (CCKp1.*HIn.^2) + (CCKp1.*CCKp2.*HIn) + (CCKp1.*CCKp2.*CCKp3);
    Ah3po4g = (Phosphate.*HIn.^3)./denom;
    %     Ah2po4g = (Constant.SurfacePhosphate*kp1*HIn.^2)/denom;
    Ahpo4g = (Phosphate.*CCKp1.*CCKp2.*HIn)./denom;
    Apo4g = (Phosphate.*CCKp1.*CCKp2.*CCKp3)./denom;
    
    % Borate
    Ab = (CCKb./(CCKb+HIn)).*(Boron);
    
    % OH
    Aoh = (CCKw./(HIn));
    
    % Silica ##UNUSED
    Asi = (CCKsi.*Silica)./(CCKsi+HIn);
    
    % Correction
    Fh = HIn+Ah3po4g-Ab-Aoh-Asi-Ahpo4g-(2*Apo4g);
    
    % Calculate alkalinity
    AlkalinityC = Total_Alkalinity+Fh;
    
    %% Solve
    % Use derivable quadratic
    gamma = DIC./AlkalinityC;
    HOut = (0.5.*((gamma-1).*CCK1 + sqrt( (((1-gamma).^2).*(CCK1.^2)) - (4.*CCK1.*CCK2.*(1-(2*gamma))) )));
    pH = H2pH(HOut);
    
    % Calculate individual components ## NECESSARY?
    CO2 = DIC./(1+ CCK1./HOut + (CCK2.*CCK1)./(HOut.^2));
    HCO3 = DIC./((HOut./CCK1) + 1 + (CCK2./HOut)');
    CO3 = DIC./((HOut.^2)./(CCK1.*CCK2) + HOut./CCK2 + 1);
    
    % Saturation State
    Ksp = CCKsp_Cal; %mol^2/m^
    % Saturation State = Product of concentrations over solubility
    Omega = (Calcium.*CO3)./(Ksp);
elseif Iteration_Flag;    
    while any(Anomaly>Tolerance);
        %% Additional Alkalinity Contributions
        % Phosphate
        denom = HIn.^3 + (CCKp1.*HIn.^2) + (CCKp1.*CCKp2.*HIn) + (CCKp1.*CCKp2.*CCKp3);
        Ah3po4g = (Phosphate.*HIn.^3)./denom;
        %     Ah2po4g = (Constant.SurfacePhosphate*kp1*HIn.^2)/denom;
        Ahpo4g = (Phosphate.*CCKp1.*CCKp2.*HIn)./denom;
        Apo4g = (Phosphate.*CCKp1.*CCKp2.*CCKp3)./denom;
        
        % Borate
        Ab = (CCKb./(CCKb+HIn)).*(Boron);
        
        % OH
        Aoh = (CCKw./(HIn));
        
        % Silica ##UNUSED
        Asi = (CCKsi.*Silica)./(CCKsi+HIn);
        
        % Correction
        Fh = HIn+Ah3po4g-Ab-Aoh-Asi-Ahpo4g-(2*Apo4g);
        
        % Calculate alkalinity
        AlkalinityC = Total_Alkalinity+Fh;
        
        %% Solve
        % Use derivable quadratic
        gamma = DIC./AlkalinityC;
        HOut = (0.5.*((gamma-1).*CCK1 + sqrt( (((1-gamma).^2).*(CCK1.^2)) - (4.*CCK1.*CCK2.*(1-(2*gamma))) )));
        pH = H2pH(HOut);
        
        % Calculate individual components ## NECESSARY?
        CO2 = DIC./(1+ CCK1./HOut + (CCK2.*CCK1)./(HOut.^2));
        HCO3 = DIC./((HOut./CCK1) + 1 + (CCK2./HOut)');
        CO3 = DIC./((HOut.^2)./(CCK1.*CCK2) + HOut./CCK2 + 1);
        
        % Saturation State
        Ksp = CCKsp_Cal; %mol^2/m^
        % Saturation State = Product of concentrations over solubility
        Omega = (Calcium.*CO3)./(Ksp);
        
        %% Anomaly
        Anomaly = abs(pH-H2pH(HIn));
        HIn = HOut;
    end
end

end