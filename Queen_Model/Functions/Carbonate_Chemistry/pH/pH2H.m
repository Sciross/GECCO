function H = pH2H(pH);
    % Assuming total scale (input and output)
    H = (10.^(-pH)).*1e3;
end
