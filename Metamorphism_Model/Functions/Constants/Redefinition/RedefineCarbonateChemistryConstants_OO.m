%% Redefine Carbonate Chemistry Constants
function Constant = RedefineCarbonateChemistryConstants_OO(Constant);

% global LysoclineIn
% global HIn_s
% global HIn_d

%% Run Functions for Carbonate Chemistry
% Calculate carbonate chemistry constants and their correction

Coefficients = GetCoefficients(Constant,Constant);
[Constant.CarbonateConstants,Constant.Corr] = GetCCKConstants(Constant.Salinity,Constant.Temperature,Constant.Pressure,Constant.PressureCorrection,Coefficients);

% Quantify initial carbonate system for surface and deep
% [GECCOObject.Conditions.Present.pH,GECCOObject.Conditions.Present.CO2,~,~,GECCOObject.Conditions.Present.OmegaC,~] = CarbonateChemistry(GECCOObject.Conditions.Present,[y(5);y(6)],[y(7);y(8)],[GECCOObject.Conditions.Present.HIn_s;GECCOObject.Conditions.Present.HIn_d],GECCOObject.Conditions.Present.CarbonateConstants);

% 
% % Calculate lysocline depth and remineralisation coefficient
% [Initial.LysoclineDepth] = CalculateLysocline_Fun_Bisection_Iter(Constant.Surface.Depth,Constant.Deep.Depth,Constant,Initial.Deep.pH,Initial.Deep.DIC,LysoclineIn);
% Initial.DeepRemin = (CalculateRemin_MyLinear(Constant.FitMatrix,Initial.LysoclineDepth)/100)*(1-Constant.DIC.SurfaceRemin);

% LysoclineIn = Initial.LysoclineDepth;

end
