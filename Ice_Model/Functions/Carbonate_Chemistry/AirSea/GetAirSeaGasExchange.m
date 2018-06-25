function [AirSeaExchange,SeaAirExchange] = GetAirSeaGasExchange(CO2atm,CO2aq,Solubility)
%% GetAirSeaGasExchange Calculates air sea gas exchange using Henry's Law
% Uses a prescribed piston velocity to calculate mixing between the
% atmosphere and ocean. This acts to equalise the partial pressure between
% these reservoirs, given ocean solubility (calculated by CCK function).

PistonVelocity = 4.65 * 365.0;
% Solubility = CCKConstants(1,:,1);

AirSeaExchange = PistonVelocity * (CO2atm);
SeaAirExchange = PistonVelocity * (CO2aq./Solubility);

end