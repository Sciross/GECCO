%% Calculate Remin Gauss 4 Fun
function [DeepRemin] = CalculateRemin_Gauss4(Lysocline);

DeepRemin = 106.3*exp(-((Lysocline-1.242e+04)/7267)^2) + 32.46*exp(-((Lysocline-5477)/1347)^2) + 29.82*exp(-((Lysocline-7174)/2157)^2) + 3.438*exp(-((Lysocline-4134)/764.7)^2);

end
