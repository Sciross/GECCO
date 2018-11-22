

Change_Times = 10e6;
Magnesium_Change_Times = Change_Times;
Calcium_At_Change = [10;18];
Magnesium_At_Change = [50;34];

Calcium_Start = 20;
Calcium_End = 10;

Magnesium_Start = 30;
Magnesium_End = 50;

Coefficients = [-0.01;0;0.01;0.04;0.1;0.2];
                
Run_Length = 70e6;

% Upload 600ppm_14_Short before running

% Set up cluster
Cluster = parcluster();
Cluster.SubmitArguments = '-l walltime=16:00:00';

for Magnesium_Change_Index = 1:numel(Magnesium_At_Change);
    for Time_Index = 1:numel(Change_Times);
        for Calcium_Change_Index = 1:numel(Calcium_At_Change);
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
                Gecco.LoadFinal(File);
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Load(File);
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Weathering.Carbonate_Weathering_Coefficients(3) = 0;
                
                % CREATE THE DIRECTORY BEFORE RUNNING
                Gecco.Runs(Carbonate_Change_Index).Information.Output_Filepath = "/scratch/rw12g11/Ca_Mg_Carbonate_Ensemble/10e6";
                Gecco.Runs(Carbonate_Change_Index).Information.Output_Filename = strcat("T",num2str(Change_Times(Time_Index)),"CC",num2str(Calcium_At_Change(Calcium_Change_Index)),"MC",num2str(Magnesium_At_Change(Magnesium_Change_Index)),"SW",num2str(Carbonate_Change_Index),".nc");
                
                % Calculations for transients
                Calcium_Point = Calcium_At_Change(Calcium_Change_Index);
                Calcium_Time = Change_Times(Time_Index);
                
                Magnesium_Point = Magnesium_At_Change(Magnesium_Change_Index);
                Magnesium_Time = Magnesium_Change_Times(Time_Index);
                
                % Perform y = mx+c for both segments
                Calcium_m(1) = (Calcium_Point-Calcium_Start)/(Calcium_Time-0);
                Calcium_m(2) = (Calcium_End-Calcium_Point)/(Gecco.Runs(Carbonate_Change_Index).Chunks(2).Time_In(2)-Calcium_Time);
                
                Calcium_c(1) = Calcium_Start;
                Calcium_c(2) = Calcium_Point-(Calcium_m(2)*Calcium_Time);
                
                Magnesium_m(1) = (Magnesium_Point-Magnesium_Start)/(Magnesium_Time-0);
                Magnesium_m(2) = (Magnesium_End-Magnesium_Point)/(Gecco.Runs(Carbonate_Change_Index).Chunks(2).Time_In(2)-Magnesium_Time);
                
                Magnesium_c(1) = Magnesium_Start;
                Magnesium_c(2) = Magnesium_Point-(Magnesium_m(2)*Magnesium_Time);
                
                % Add the right transients
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Calcium(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Calcium_m(1)),".*t)+",num2str(Calcium_c(1))))};
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Calcium(2,:) = {2,':',str2func(strcat("@(t,Conditions)(",num2str(Calcium_m(2)),".*t)+",num2str(Calcium_c(2))))};
                
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Magnesium(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Magnesium_m(1)),".*t)+",num2str(Magnesium_c(1))))};
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Magnesium(2,:) = {2,':',str2func(strcat("@(t,Conditions)(",num2str(Magnesium_m(2)),".*t)+",num2str(Magnesium_c(2))))};
            
                % Manipulate the coefficients
                Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Weathering.Manipulate_Carbonate_Weathering([1;2;3],[NaN;Coefficients(Carbonate_Change_Index);Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Constants.Weathering.Carbonate_Weathering_Coefficients(3)],Gecco.Runs(Carbonate_Change_Index).Regions.Conditions.Initials.Atmosphere_Temperature);
            end
        
            % Submit job
            Gecco.RunModelOnIridis(Cluster);
        end        
    end
end
