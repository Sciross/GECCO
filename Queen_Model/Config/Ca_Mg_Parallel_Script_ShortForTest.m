Calcium_Change_Times = 5e5:1e5:7e5;
Magnesium_Change_Times = 5e5;
Calcium_At_Change = 20:2:24;
Magnesium_At_Change = 50;

Calcium_Start = 20;
Calcium_End = 10;

Magnesium_Start = 30;
Magnesium_End = 50;
                
Run_Length = 1e6;

% Upload 600ppm_5 before running

% Set up cluster
% Cluster = parcluster();
% Cluster.SubmitArguments = '-l walltime=10:00:00';

for Magnesium_Time_Index = 1:numel(Magnesium_Change_Times);
    for Magnesium_Change_Index = 1:numel(Magnesium_At_Change);
        for Calcium_Time_Index = 1:numel(Calcium_Change_Times);
            Gecco = GECCO();
            
            % Make necessary changes
            Gecco.ShouldSaveFlag = 1;
            Gecco.SaveToSameFileFlag = 0;
            Gecco.SaveToRunFilesFlag = 1;
            
            for Calcium_Change_Index = 1:numel(Calcium_At_Change);
                if Calcium_Change_Index~=1;
                    Gecco.AddRun();
                end
                Gecco.Runs(Calcium_Change_Index).AddChunk();
                
                % Make necessary changes
                Gecco.Runs(Calcium_Change_Index).Chunks(1).Time_In(2) = Calcium_Change_Times(Calcium_Time_Index);
                Gecco.Runs(Calcium_Change_Index).Chunks(1).Time_Out(2) = Calcium_Change_Times(Calcium_Time_Index);
                Gecco.Runs(Calcium_Change_Index).Chunks(2).Time_In(1) = Calcium_Change_Times(Calcium_Time_Index);
                Gecco.Runs(Calcium_Change_Index).Chunks(2).Time_Out(1) = Calcium_Change_Times(Calcium_Time_Index);
                Gecco.Runs(Calcium_Change_Index).Chunks(2).Time_In(2) = Run_Length;
                Gecco.Runs(Calcium_Change_Index).Chunks(2).Time_Out(2) = Run_Length;
                
                Gecco.LoadFinal("C:\Users\Ross\Documents\Work\PhD\Results\Queen_Model\Steady_States\Maastrictian/600ppm_5.nc");
                
                % CREATE THE DIRECTORY BEFORE RUNNING
                Gecco.Runs(Calcium_Change_Index).Information.Output_Filepath = ".";
                Gecco.Runs(Calcium_Change_Index).Information.Output_Filename = strcat("CC",num2str(Calcium_At_Change(Calcium_Change_Index)),"CT",num2str(Calcium_Change_Times(Calcium_Time_Index)),"MC",num2str(Magnesium_At_Change(Magnesium_Change_Index)),"MT",num2str(Magnesium_Change_Times(Magnesium_Time_Index)));
                
                % Calculations for transients                
                Calcium_Point = Calcium_At_Change(Calcium_Change_Index);
                Calcium_Time = Calcium_Change_Times(Calcium_Time_Index);
                
                Magnesium_Point = Magnesium_At_Change(Magnesium_Change_Index);
                Magnesium_Time = Magnesium_Change_Times(Magnesium_Time_Index);
                
                % Perform y = mx+c for both segments
                Calcium_m(1) = (Calcium_Point-Calcium_Start)/(Calcium_Time-0);
                Calcium_m(2) = (Calcium_End-Calcium_Point)/(Gecco.Runs(Calcium_Change_Index).Chunks(2).Time_In(2)-Calcium_Time);
                
                Calcium_c(1) = Calcium_Start;
                Calcium_c(2) = Calcium_Point-(Calcium_m(2)*Calcium_Time);
                
                Magnesium_m(1) = (Magnesium_Point-Magnesium_Start)/(Magnesium_Time-0);
                Magnesium_m(2) = (Magnesium_End-Magnesium_Point)/(Gecco.Runs(Calcium_Change_Index).Chunks(2).Time_In(2)-Magnesium_Time);
                
                Magnesium_c(1) = Magnesium_Start;
                Magnesium_c(2) = Calcium_Point-(Magnesium_m(2)*Magnesium_Time);
                
                % Add the right transients
                Gecco.Runs(Calcium_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Calcium(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Calcium_m(1)),".*t)+",num2str(Calcium_c(1))))};
                Gecco.Runs(Calcium_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Calcium(2,:) = {2,':',str2func(strcat("@(t,Conditions)(",num2str(Calcium_m(2)),".*t)+",num2str(Calcium_c(2))))};
                
                Gecco.Runs(Calcium_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Magnesium(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Magnesium_m(1)),".*t)+",num2str(Magnesium_c(1))))};
                Gecco.Runs(Calcium_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Magnesium(2,:) = {2,':',str2func(strcat("@(t,Conditions)(",num2str(Magnesium_m(2)),".*t)+",num2str(Magnesium_c(2))))};
            end
            % Submit job
            Gecco.RunModel();
            
        end
    end
end



