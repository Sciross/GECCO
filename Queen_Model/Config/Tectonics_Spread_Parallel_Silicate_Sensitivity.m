clear

Change_Times = 10e6;
Spread_At_Change = [0.2e6,0.4e6,0.6e6,0.8e6];%:0.5e6:3.5e6;

Run_Length = 70e6;
Spread_Start = 0.5e6;

Coefficients = [-0.02;0;0.02;0.1;0.2];

% Upload 600ppm_14_Short before running

% Set up cluster
Cluster = parcluster();
Cluster.SubmitArguments = '-l walltime=12:00:00';

for Time_Index = 1:numel(Change_Times);
    for Spread_Change_Index = 1:numel(Spread_At_Change);
        Gecco = GECCO();
        
        % Make necessary changes
        Gecco.ShouldSaveFlag = 1;
        Gecco.SaveToSameFileFlag = 0;
        Gecco.SaveToRunFilesFlag = 1;
    
        for Silicate_Change_Index = 1:numel(Coefficients);
            if Silicate_Change_Index~=1;
                Gecco.AddRun();
            end
            Gecco.Runs(Silicate_Change_Index).AddChunk();
            
            % Make necessary changes
            Gecco.Runs(Silicate_Change_Index).Chunks(1).Time_In(2) = Change_Times(Time_Index);
            Gecco.Runs(Silicate_Change_Index).Chunks(1).Time_Out(2) = Change_Times(Time_Index);
            Gecco.Runs(Silicate_Change_Index).Chunks(2).Time_In(1) = Change_Times(Time_Index);
            Gecco.Runs(Silicate_Change_Index).Chunks(2).Time_Out(1) = Change_Times(Time_Index);
            Gecco.Runs(Silicate_Change_Index).Chunks(2).Time_In(2) = Run_Length;
            Gecco.Runs(Silicate_Change_Index).Chunks(2).Time_Out(2) = Run_Length;
            
            File = "/home/rw12g11/600ppm_14_Short.nc";
            Gecco.LoadFinal(File);
            Gecco.Runs(Silicate_Change_Index).Regions.Conditions.Constants.Load(File);
            
            % Need to change the core
            Gecco.Runs(Silicate_Change_Index).Regions.Conditions.Functionals.SetCore("Core_Tectonics");
            
            % Need to add some outgassing space
            if Spread_At_Change(Spread_Change_Index)>Spread_Start;
                Gecco.Runs(Silicate_Change_Index).Regions.Conditions.Initials.Outgassing = [Gecco.Runs(Silicate_Change_Index).Regions.Conditions.Initials.Outgassing;zeros((Spread_At_Change(Spread_Change_Index)-Spread_Start)./Gecco.Runs(Silicate_Change_Index).Regions.Conditions.Constants.Outgassing.Temporal_Resolution,1)];
            end
            
            % CREATE THE DIRECTORY BEFORE RUNNING
            Gecco.Runs(Silicate_Change_Index).Information.Output_Filepath = "/scratch/rw12g11/Tectonics_Spread_Silicate_Sensitivity/10e6";
            Gecco.Runs(Silicate_Change_Index).Information.Output_Filename = strcat("T",num2str(Change_Times(Time_Index)),"LC",num2str(Spread_At_Change(Spread_Change_Index)),"SW",num2str(Silicate_Change_Index),".nc");
            
            % Calculations for transients
            Spread_Point = Spread_At_Change(Spread_Change_Index);
            Spread_Time = Change_Times(Time_Index);
            
            % Perform y = mx+c for both segments
            Spread_m(1) = (Spread_Point-Spread_Start)/(Spread_Time-0);
            Spread_c(1) = Spread_Start;
            
            % Add the right transients
            Gecco.Runs(Silicate_Change_Index).Regions.Conditions.Transients.Outgassing.Spread(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Spread_m(1)),".*t)+",num2str(Spread_c(1))))};
            
        end
        % Submit job
        Gecco.RunModelOnIridis(Cluster);
    end
end



