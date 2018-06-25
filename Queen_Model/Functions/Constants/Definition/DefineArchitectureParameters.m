function Architecture = DefineArchitectureParameters(Architecture);
    %% Architecture Parameters
    Architecture.Atmosphere_Volume = (1.8e20); %mols
    Architecture.Riverine_Volume = 4e13; %m^3/yr;
    
    Architecture.Ocean_Depths = [500;3200];
    Architecture.Ocean_Midpoints = Architecture.Ocean_Depths/2+[0;Architecture.Ocean_Depths(1:end-1)/2];
    Architecture.Ocean_Area = 362e12;
    Architecture.Ocean_Volumes = Architecture.Ocean_Area.*Architecture.Ocean_Depths;
        
    Architecture.Mixing_Coefficient = 5; %m/yr

    load('./../Resources/Hypsometry.mat');
    [Gradient,YIntercept] = PiecewiseLinearFit(Hypsometric_Bin_Midpoints,Cumulative_Hypsometry);
    Architecture.Hypsometric_Interpolation_Matrix = [Gradient,YIntercept];
    Architecture.Hypsometry = Hypsometry;
    Architecture.Cumulative_Hypsometry = Cumulative_Hypsometry;
    Architecture.Hypsometric_Bin_Midpoints = Hypsometric_Bin_Midpoints;
end