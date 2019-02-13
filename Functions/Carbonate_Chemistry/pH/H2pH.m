function pH = H2pH(H);
    % Assuming total scale (input and output)
    pH = -log10(H/1e3);
end

