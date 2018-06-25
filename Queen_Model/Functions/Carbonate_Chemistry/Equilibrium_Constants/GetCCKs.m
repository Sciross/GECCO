function [CorrectedConstants,Corr] = GetCCKConstants(Salinity,Temperature,Pressure,PressureCorrection,Coefficients);
%% GetCCKConstants calculates the dissociation constants of the carbonate system.
% Temperature, pressure and salinity are reshaped into vectors in the third
% dimension to facilitate code vectorisation.
% K constants are calculated using equations from Zeebe+Wolf-Gladrow for each pressure, temperature and salinity.
% These constants are combined into a 3D matrix.
% The temperature and pressure vectors are replicated for code
% vectorisation purposes. Then put together in the form ^0, ^1, ^2 by use
% of a scaling matrix. Each three columns are then summed and the
% correction is calculated using the equation in Zeebe+Wolf-Gladrow. The
% correction is applied to the constants before output.

%% Call for input check ##CURRENTLY UNUSED
% GetCCKConstantsCheck(Salinity,Temperature,Pressure);

%% Equalise Size of Matrices for Vectorisation
% Tk = reshape(Temperature,[1,1,length(Temperature)]); %degK
Tk = Temperature;
Tc = Tk-273.15; %degC
% S = reshape(Salinity,[1,1,length(Temperature)]); %unitless
S = Salinity;
% R = 83.131; %cm^3.bar/mol/K %From Book - replaced by CSys
% R = 83.1451; %cm^3.bar/mol/K % FROM CSYS
% P = reshape(Pressure,[1,1,length(Temperature)]); %bar
P = Pressure;

% Zeebe + Wolf-Gladrow
I = (19.924.*S)./(1000-1.005.*S); %#UNCHECKED

if isempty(Coefficients);
    K0 = exp((9345.17./Tk)-60.2409+(23.3585.*log(Tk./100))+(S.*(0.023517-(0.00023656.*Tk)+(0.0047036.*(Tk./100).^2))));
    % DOE (1994) based on Roy et al. (1993a)
    K1 = exp(2.83655-(2307.1266./Tk)-(1.5529413.*log(Tk))-((0.207608410+(4.0484./Tk)).*S.^(1/2))+(0.08468345.*S)-(0.00654208.*S.^(3/2))+log(1-(0.001005.*S)));
    % DOE (1994) based on Roy et al. (1993a)
    K2 = exp(-9.226508-(3351.6106./Tk)-(0.2005743.*log(Tk))-((0.106901773+(23.9722./Tk)).*S.^(1/2))+(0.1130822.*S)-(0.00846934.*S.^(3/2))+log(1-(0.001005.*S)));
    % DOE (1994) based on Dickson (1990)
    Kb = exp(((-8966.9-(2890.53.*S.^(1/2))-(77.942.*S)+(1.728.*S.^(3/2))-(0.0996.*S.^2))./Tk)+148.0248+(137.1942*S.^(1/2))+(1.62142.*S)-((24.4344+(25.085.*S.^(1/2))+0.2474.*S).*log(Tk))+(0.053105.*S.^(1/2).*Tk));
    % DOE (1994)
    Kw = exp(148.9652-(13847.26./Tk)-(23.6521*log(Tk))+(((118.67./Tk)-5.977+(1.0495.*log(Tk))).*S.^(1/2))-(0.01615.*S));
    % DOE (1994)
    Ks = exp((-4276.1./Tk)+141.328-(23.093.*log(Tk))+(((-13856./Tk)+324.57-(47.986.*log(Tk))).*(I.^(0.5)))+(((35474./Tk)-771.54+(114.723.*log(Tk))).*I)-((2698./Tk).*(I.^(3/2)))+((1776./Tk).*(I.^2))+(log(1-(0.001005.*S))));%#UNCHECKED
    % Mucci (1983)
    Ksp_Cal = 10.^(-171.9065-(0.077993.*Tk)+(2839.319./Tk)+(71.595.*log10(Tk))+((-0.77712+(0.0028426.*Tk)+(178.34./Tk)).*S.^(1/2))-(0.07711*S)+(0.0041249*S.^(3/2)));
    % Mucci (1983)
    Ksp_Arag = 10.^(-171.945-(0.077993.*Tk)+(2903.293./Tk)+(71.595.*log10(Tk))+((-0.068393+(0.0017276.*Tk)+(88.135./Tk)).*S.^(1/2))-(0.10018*S)+(0.0059415*S.^(3/2)));
else
    %% Equations for Constants from Zeebe+Wolf-Gladrow (2001)
    % Weiss (1974)
    K0 = exp(Coefficients{1}(1) + ((Coefficients{1}(2)*100)./Tk) + (Coefficients{1}(3).*log(Tk./100)) + (S.*(Coefficients{1}(4) + (Coefficients{1}(5).*(Tk./100)) + (Coefficients{1}(6).*((Tk./100).^2)))));
    K1 = 10.^(Coefficients{2}(1) + (Coefficients{2}(2)./Tk) + (Coefficients{2}(3).*(log(Tk))) + (Coefficients{2}(4).*S) + (Coefficients{2}(5).*(S.^2)));
    K2 = 10.^(Coefficients{3}(1) + (Coefficients{3}(2)./Tk) + (Coefficients{3}(3).*(log(Tk))) + (Coefficients{3}(4).*S) + (Coefficients{3}(5).*(S.^2)));
    Kb = exp(Coefficients{4}(1) + (Coefficients{4}(2).*S.^(1/2)) + (Coefficients{4}(3).*S) + ((1./Tk).*(Coefficients{4}(4) + (Coefficients{4}(5).*(S.^(1/2))) + (Coefficients{4}(6).*S) + (Coefficients{4}(7).*(S.^(3/2))) + (Coefficients{4}(8).*(S.^2)))) + ((log(Tk)).*(Coefficients{4}(9) + (Coefficients{4}(10).*(S.^(1/2))) + (Coefficients{4}(11).*S)) + (Coefficients{4}(12).*Tk.*(S.^(1/2)))));
    Kw = exp(Coefficients{5}(1) + (Coefficients{5}(2)./Tk) + (Coefficients{5}(3).*(log(Tk))) + ((S.^(1/2)).*((Coefficients{5}(4)./Tk) + Coefficients{5}(5) + (Coefficients{5}(6).*(log(Tk))))) + (Coefficients{5}(7).*S));
    Ks = exp(Coefficients{8}(1) + (Coefficients{8}(2)./Tk) + (Coefficients{8}(3).*(log(Tk))) + ((I.^(1/2)).*((Coefficients{8}(4)./Tk) + Coefficients{8}(5) + (Coefficients{8}(6).*(log(Tk))))) + (I.*((Coefficients{8}(7)./Tk) + Coefficients{8}(8) + (Coefficients{8}(9).*(log(Tk))))) + ((Coefficients{8}(10)./Tk).*(I.^(3/2))) + ((Coefficients{8}(11)./Tk).*(I.^2)) + log(1-(0.001005.*S)));
    Ksp_Cal = 10.^(Coefficients{6}(1) + (Coefficients{6}(2).*Tk) + (Coefficients{6}(3)./Tk) + (Coefficients{6}(4).*log10(Tk)) + ((S.^(1/2)).*(Coefficients{6}(5) + (Coefficients{6}(6).*Tk) + (Coefficients{6}(7)./Tk))) + (S.*Coefficients{6}(8)) + (S.*Coefficients{6}(9).*(S.^(3/2))));
    Ksp_Arag = 10.^(Coefficients{7}(1) + (Coefficients{7}(2).*Tk) + (Coefficients{7}(3)./Tk) + (Coefficients{7}(4).*log10(Tk)) + ((S.^(1/2)).*(Coefficients{7}(5) + (Coefficients{7}(6).*Tk) + (Coefficients{7}(7)./Tk))) + (S.*Coefficients{7}(8)) + (S.*Coefficients{7}(9).*(S.^(3/2))));
end

% DOE (1994)
Ksi = exp((-8904.2./Tk)+117.385-(19.334.*log(Tk))+((3.5913-(458.79./Tk)).*(I.^(0.5)))+(((188.74./Tk)-1.5998).*I)+((0.07871-(12.1652./Tk)).*(I.^2))+log(1-(0.001005.*S)));%#UNCHECKED
% DOE (1994)
Kf = exp((1590.2./Tk)-12.641+(1.525.*(I.^0.5))+log(1-(0.001005.*S))+log(1+([8.07*35;8.07*35]./Ks))); %#UNCHECKED
% DOE (1994)
Kp_1 = exp((-4576.752./Tk)+115.525-(18.453.*log(Tk))+(((-106.736./Tk)+0.69171).*S.^(0.5))+(((-0.65643./Tk)-0.01844).*S));%#UNCHECKED
Kp_2 = exp((-8814.715./Tk)+172.0883-(27.927.*log(Tk))+(((-160.34./Tk)+1.3566).*S.^(0.5))+(((0.37335./Tk)-0.05778).*S));%#UNCHECKED
Kp_3 = exp((-3070.75./Tk)-18.141+(((17.27039./Tk)+2.81197).*S.^(0.5))+(((-44.99486./Tk)-0.09984).*S));%#UNCHECKED

% Combine constants
AllConstants = ([K0,K1,K2,Kb,Kw,Ksi,Ks,Kf,Ksp_Cal,Ksp_Arag,Kp_1,Kp_2,Kp_3]);

%% Pressure/Temperature Correction
Corr = GetPressureCorrection(Tk,Tc,P,PressureCorrection);
% Output corrected constants
% Output into mol/m3
UnitCorrectionMatrix = [1000,1000,1000,1000,10^6,1000,1000,1000,10^6,10^6,1000,1000,1000;
                        1000,1000,1000,1000,10^6,1000,1000,1000,10^6,10^6,1000,1000,1000,];
CorrectedConstants = (AllConstants).*Corr.*UnitCorrectionMatrix;


%% ### CHECK CORRECTION FOR KS

end