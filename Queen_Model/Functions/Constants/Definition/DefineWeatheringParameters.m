function Weathering = DefineWeatheringParameters(Weathering);   
    % Weathering Parameters
    Weathering.Silicate_Replenishment = 0; %1e12; % ### Not real

    Weathering.Silicate_Weathering_Coefficients = [1.876625323804900e-15;0.068551565356742;0];
    Weathering.Carbonate_Weathering_Coefficients = [1.876625323804900e-15;0.068551565356742;0];

    Weathering.Silicate_Replacement = 1; %fraction

    Weathering.Silicate_Weatherability = 1;
    Weathering.Carbonate_Weatherability = 1;
    
    Weathering.Carbonate_Exposure = 1/20;
end