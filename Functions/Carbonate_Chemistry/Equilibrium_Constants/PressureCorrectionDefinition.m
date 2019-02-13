function [PressureCorrection,varargout] = PressureCorrectionDefinition(WhatYouWant);
%% PressureCorrectionDefinition gives values from Zeebe for pressure dependence of carbonate chemistry.
% Typical usage is without input argument, however you can give specific
% coefficients if required.
%% ### VALUES REQUIRE CHECKING

PressureCorrection = [ 00.000, 0.0000, 0.0000e-3, 00.00e-3, 0.0000e-3, 0.0;
                      -25.500, 0.1271, 0.0000e-3,-03.08e-3, 0.0877e-3, 0.0;
                      -15.820,-0.0219, 0.0000e-3, 01.13e-3,-0.1475e-3, 0.0;
                      -29.480, 0.1622,-2.6080e-3,-02.84e-3, 0.0000e-3, 0.0;
                      -20.020, 0.1119,-1.4090e-3,-05.13e-3, 0.0794e-3, 0.0;
                      -00.000, 0.0000, 0.0000e-3,-00.00e-3, 0.0000e-3, 0.0;
                      -18.030, 0.0466, 0.3160e-3,-04.53e-3, 0.0900e-3, 0.0;
                      -09.780,-0.0090,-0.9420e-3,-03.91e-3, 0.0540e-3, 0.0;
                      -48.760, 0.5304, 0.0000e-3,-11.76e-3, 0.3692e-3, 0.0;
                      -46.000, 0.5304, 0.0000e-3,-11.76e-3, 0.3692e-3, 0.0;
                      -14.510, 0.1211,-0.3210e-3,-02.67e-3, 0.0427e-3, 0.0;
                      -23.120, 0.1758,-2.6470e-3,-05.15e-3, 0.0900e-3, 0.0;
                      -26.570, 0.2020,-3.0420e-3,-04.08e-3, 0.0714e-3, 0.0];
           
NamesY = {'K0','K1','K2','Kb','Kw','Ksi','Ks','Kf','Ksp_Ca','Ksp_Ar','Kp1','Kp2','Kp3'};
NamesX = {'a0','a1','a2','b0','b1','b2'};

if nargin>0;
    for n = 2:size(WhatYouWant,2);
        varargout{n-1} = eval(WhatYouWant{n});
    end
end
end
                  