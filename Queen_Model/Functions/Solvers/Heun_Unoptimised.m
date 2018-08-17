% My simple, Heun solver
% Uses an average of the forward and backward gradients to project forward
% in time
function [Compiled_Outputs,Flag_Out] = Heun_Unoptimised(ODE,Run,Chunk_Number);
    % Time_Out yt_Out,V_out,L_out,S_out,ST_out,P_out
    
    Time_In = Run.Chunks(Chunk_Number).Time_In(1):Run.Chunks(Chunk_Number).Time_In(3):Run.Chunks(Chunk_Number).Time_In(2);
    Time_Out = Run.Chunks(Chunk_Number).Time_Out(1):Run.Chunks(Chunk_Number).Time_Out(3):Run.Chunks(Chunk_Number).Time_Out(2);
    Step_Size_In = Run.Chunks(1).Time_In(3);
    Step_Size_Out = Run.Chunks(1).Time_Out(3);
    TransientsEmpty_Flag =  isempty(Run.Regions(1).Conditions.Transients.Matrix);
    
    Initial_Conditions = Run.Regions(1).Conditions.Initials.Conditions;
    Initial_Seafloor = Run.Regions(1).Conditions.Initials.Seafloor;
    Initial_Outgassing = Run.Regions(1).Conditions.Initials.Outgassing;
    
    % Preallocate the output vector and assign the first value
    Outputs = NaN(numel(Initial_Conditions),numel(Time_Out));
    Temporary_Outputs_1(:,1) = Initial_Conditions;
    Temporary_Seafloor_1(:,1) = Initial_Seafloor;
    Temporary_Outgassing_1(:,1) = Initial_Outgassing;
    
    Temporary_Outputs_2(1:numel(Initial_Conditions),1) = NaN;
    Temporary_Seafloor_2(1:numel(Initial_Seafloor),1) = NaN;
    Temporary_Outgassing_2(1:numel(Initial_Outgassing),1) = NaN;
    
    Gradients_1(1:numel(Initial_Conditions),1) = NaN;
    Gradients_2(1:numel(Initial_Conditions),1) = NaN;
    
    Transients = NaN(1,numel(Time_Out));
    Lysocline = NaN(1,numel(Time_Out));
    Seafloor_Total = NaN(1,numel(Time_Out));
    Cores = NaN;
    PIC_Burial = NaN(2,numel(Time_Out));
    pH = NaN(2,numel(Time_Out));
    
    if ~isnan(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths);
        Cores = NaN(numel(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths),numel(Time_Out));
    end
    
    % Run once to update present conditions ### WHY?
    ODE(0,Initial_Conditions,Initial_Seafloor,Initial_Outgassing,Chunk_Number);
    
    if ~TransientsEmpty_Flag;
        for Parameter_Number = 1:size(Run.Regions(1).Conditions.Transients.Matrix,1);
            Initial_Transients{Parameter_Number,1}(:) = Run.Regions(1).Conditions.Presents.(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,2}).(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,3})(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,4})';
        end
        Temporary_Transients = Initial_Transients;
    else
        Initial_Transients = [];
        Temporary_Transients = Initial_Transients;
    end
    
    Transients = {};
    
    Initial_Lysocline = Run.Regions(1).Conditions.Presents.Carbonate_Chemistry.Lysocline;
    Temporary_Lysoline = Initial_Lysocline;
    
    %% Assume that the output difference is an exact multiple of h, and the
    % starting time is the same, otherwise error out
    if rem(Step_Size_Out,Step_Size_In)==0 && Time_Out(1)==Time_In(1);
        % Same number of steps each time
        Count_Reached = (Time_Out(2)-Time_Out(1))/Step_Size_In;
        Place = 1;
        
        if Time_Out(1)==Time_In(1);
            Outputs(:,1) = Initial_Conditions;
            if ~TransientsEmpty_Flag;
                for Parameter_Number = 1:size(Run.Regions(1).Conditions.Transients.Matrix,1);
                    Transients{Parameter_Number,1}(:,1) = (Initial_Transients{Parameter_Number,1})';
                end
            end
            Lysocline(1) = Initial_Lysocline;            
            Seafloor_Total(:,1) = sum(Initial_Seafloor);
            PIC_Burial(:,1) = Run.Regions(1).Conditions.Presents.Carbon.PIC_Pelagic_Burial;
            pH(:,1) = Run.Regions(1).Conditions.Presents.Carbonate_Chemistry.pH;
            if ~isnan(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths);
                Cores(:,1) = Initial_Seafloor(1001-(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths/10));
            end
            
            if Outputs(18,Place)<-5;
                Edge_Box_Fill = 1+rem(Outputs(18,Place)+5,10)/10;
            else
                Edge_Box_Fill = rem(Outputs(18,Place)+5,10)/10;
            end
            
            OceanArray = double(Run.Regions(1).Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints<round(Outputs(17,Place)));
            OceanArray(1001-round(Outputs(18,Place)/10)) = Edge_Box_Fill;
            
            Seafloor_Total(2,Place) = sum((1-OceanArray).*(Temporary_Seafloor_1).*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Exposure);
            
            Place = 2;
        end
        
        Count = 1;
        try
            for Current_Step = 2:numel(Time_In);
                % Calculate gradient at point 1
                [Gradients_1,dy_1_Sub,dy_1_Meta] = ODE(Time_In(Current_Step-1),Temporary_Outputs_1,Temporary_Seafloor_1,Temporary_Outgassing_1,Chunk_Number);
                % Calculate y value using that gradient
                Temporary_Outputs_2 = Temporary_Outputs_1+(Gradients_1.*Step_Size_In);
                Temporary_Seafloor_2 = Temporary_Seafloor_1+(dy_1_Sub.*Step_Size_In);
                Temporary_Outgassing_2 = Temporary_Outgassing_1+(dy_1_Meta.*Step_Size_In);
                % Calculate gradient using new y value
                [Gradients_2,dy_2_Sub,dy_2_Meta] = ODE(Time_In(Current_Step),Temporary_Outputs_2,Temporary_Seafloor_2,Temporary_Outgassing_2,Chunk_Number);
                % Recalculate y at point 2
                Temporary_Outputs_2 = Temporary_Outputs_1+(((Gradients_1+Gradients_2)/2).*Step_Size_In);
                Temporary_Seafloor_2 = Temporary_Seafloor_1+(((dy_1_Sub+dy_2_Sub)/2).*Step_Size_In);
                Temporary_Outgassing_2 = Temporary_Outgassing_1+(((dy_1_Meta+dy_2_Meta)/2).*Step_Size_In);
                
                
                if Count==Count_Reached;
                    Outputs(:,Place) = Temporary_Outputs_2;
                    % Lysocline
                    Lysocline(:,Place) = Run.Regions(1).Conditions.Presents.Carbonate_Chemistry.Lysocline;
                    Seafloor_Total(1,Place) = sum(Temporary_Seafloor_2);
                    PIC_Burial(:,Place) = Run.Regions(1).Conditions.Presents.Carbon.PIC_Pelagic_Burial;
                    pH(:,Place) = Run.Regions(1).Conditions.Presents.Carbonate_Chemistry.pH;
                    if ~isnan(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths);
                        Cores(:,Place) = Temporary_Seafloor_2(1001-(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths/10));
                    end
                    
                    if Outputs(18,Place)<-5;
                        Edge_Box_Fill = 1+rem(Outputs(18,Place)+5,10)/10;
                    else
                        Edge_Box_Fill = rem(Outputs(18,Place)+5,10)/10;
                    end
                    
                    OceanArray = double(Run.Regions(1).Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints<round(Outputs(17,Place)));
                    OceanArray(1001-round(Outputs(18,Place)/10)) = Edge_Box_Fill;
                    
                    Seafloor_Total(2,Place) = sum((1-OceanArray).*(Temporary_Seafloor_2).*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Exposure);
                    
                    if ~TransientsEmpty_Flag;
                        for Parameter_Number = 1:size(Run.Regions(1).Conditions.Transients.Matrix,1);
                            Temporary_Transients{Parameter_Number,1} = Run.Regions(1).Conditions.Presents.(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,2}).(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,3})(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,4});
                            Transients{Parameter_Number,1}(:,Place) = Temporary_Transients{Parameter_Number,1};
                        end
                    end
                    
                    Count = 1;
                    Place = Place+1;
                else
                    Count = Count+1;
                end
                Temporary_Outputs_1 = Temporary_Outputs_2;
                Temporary_Seafloor_1 = Temporary_Seafloor_2;
                Temporary_Outgassing_1 = Temporary_Outgassing_2;
            end
        catch Error_Object
            if ~isnan(Cores);
                Compiled_Outputs = {Outputs,[Time_Out;Lysocline;Seafloor_Total;pH;Cores],Transients,PIC_Burial};
            else
                Compiled_Outputs = {Outputs,[Time_Out;Lysocline;Seafloor_Total;pH],Transients,PIC_Burial};
            end
            Run.Regions(1).Outputs.Outgassing = Temporary_Outgassing_2;
            Run.Regions(1).Outputs.Seafloor = Temporary_Seafloor_2;
            Flag_Out = 0;
            return
        end
    else
        error("The input and output times are not aligned. Output spacing must be a multiple of solver spacing, and must start at the same time.");
    end
    
    if ~isnan(Cores);
        Compiled_Outputs = {Outputs,[Time_Out;Lysocline;Seafloor_Total;pH;Cores],Transients,PIC_Burial};
    else
        Compiled_Outputs = {Outputs,[Time_Out;Lysocline;Seafloor_Total;pH],Transients,PIC_Burial};
    end
    Run.Regions(1).Outputs.Outgassing = Temporary_Outgassing_2;
    Run.Regions(1).Outputs.Seafloor = Temporary_Seafloor_2;
    Flag_Out = 1;
end
