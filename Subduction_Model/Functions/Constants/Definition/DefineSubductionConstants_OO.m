function Constant = DefineSubductionConstants_OO(Constant);

%% Subduction Constants
% % Define Age Range
% Age = linspace(0,300,1000);
% 
% % Age-Subduction Relationship
% SubductionRisk = (1/2)*(1+erf((Age-100)/(40*sqrt(2))));
% 
% % Age-Depth Relationship
% Depth = (10000/2)*(1+erf((Age-80)/(30*sqrt(2))));

%% Declare carbonate matrix
% global Carbonate;
% Carbonate.Distribution = ones(1,1000);
Carbonate.DepthDistribution = [10:10:10000];
Carbonate.AgeDistribution = 300*Carbonate.DepthDistribution./10000;
Constant.SubductionRisk = (1/2)*(1+erf((Carbonate.AgeDistribution-100)/(70*sqrt(2))));
Constant.SubductionRate = 10000/(300*10^6); %m/Ma

end
