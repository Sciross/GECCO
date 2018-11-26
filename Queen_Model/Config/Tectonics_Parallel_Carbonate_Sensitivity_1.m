clear

Change_Times = 10e6;
Lag_At_Change = [1.6e6,2.4e6,2.6e6,3.6e6];

Run_Length = 70e6;
Lag_Start = 2.5e6;

Coefficients = [-0.01;0;0.01;0.04;0.1;0.2];

% Upload 600ppm_14_Short before running

% Set up cluster
Cluster = parcluster();
Cluster.SubmitArguments = '-l walltime=12:00:00';

for Time_Index = 1:numel(Change_Times);
    for Lag_Change_Index = 1:numel(Lag_At_Change);
        Gecco = GECCO();
        
        % Make necessary changes
        Gecco.ShouldSaveFlag = 1;
        Gecco.SaveToSameFileFlag = 0;
        Gecco.SaveToRunFilesFlag = 1;
        
        for Carbonate_Change_Index = 1:numel(Coefficients);
            if Carbonate_Change_Index~=1;
                Gecco.AddRun();
            end
            Gecco.Runs(Carbonate_Change_Index).AddChunk();
            
            % Make necessary changes
            Gecco.Runs(Carbonate_Change_Index).Chunks(1).Time_In(2) = Change_Times(Time_Index);
            Gecco.Runs(Carbonate_Change_Index).Chunks(1).Time_Out(2) = Change_Times(Time_Index);
            Gecco.Runs(Carbonate_Change_Index).Chunks(2).Time_In(1) = Change_Times(Time_Index);
            Gecco.Runs(Carbonate_Change_Index).Chunks(2).Time_Out(1) = Change_Times(Time_Index);
            Gecco.Runs(Carbonate_Change_Index).Chunks(2).Time_In(2) = Run_Length;
            Gecco.Runs(Carbonate_Change_Index).Chunks(2).Time_Out(2) = Run_Length;
            
            File = "/home/rw12g11/600ppm_14_Short.nc"; 
            Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Load(File);
            Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Weathering.Carbonate_Weathering_Coefficients(3) = 0;
            Gecco.LoadFinal(File);
           
            % Need to change the core
            Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Functionals.SetCore("Core_Tectonics");
            
            % Need to add some outgassing space
            if Lag_At_Change(Lag_Change_Index)>Lag_Start;
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Initials.Outgassing = [Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Initials.Outgassing;zeros((Lag_At_Change(Lag_Change_Index)-Lag_Start)./Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Outgassing.Temporal_Resolution,1)];
            end
            
            % CREATE THE DIRECTORY BEFORE RUNNING
            Gecco.Runs(Carbonate_Change_Index).Information.Output_Filepath = "/scratch/rw12g11/Tectonics_Carbonate_Sensitivity/10e6";
            Gecco.Runs(Carbonate_Change_Index).Information.Output_Filename = strcat("T",num2str(Change_Times(Time_Index)),"LC",num2str(Lag_At_Change(Lag_Change_Index)),"SW",num2str(Carbonate_Change_Index),".nc");
            
            % Calculations for transients
            Lag_Point = Lag_At_Change(Lag_Change_Index);
            Lag_Time = Change_Times(Time_Index);
            
            % Perform y = mx+c for both segments
            Lag_m(1) = (Lag_Point-Lag_Start)/(Lag_Time-0);
            Lag_c(1) = Lag_Start;
            
            % Add the right transients
            Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Transients.Outgassing.Mean_Lag(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Lag_m(1)),".*t)+",num2str(Lag_c(1))))};
            
            % Manipulate the coefficients
            Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Weathering.Manipulate_Carbonate_Weathering([1;2;3],[NaN;Coefficients(Carbonate_Change_Index);Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Weathering.Carbonate_Weathering_Coefficients(3)],Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Initials.Atmosphere_Temperature);
        end
        
        % Submit job
        Gecco.RunModelOnIridis(Cluster);
    end
end



