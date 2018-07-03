% My simple, Heun solver
% Uses an average of the forward and backward gradients to project forward
% in time
function DataOut = Heun_Solver_Unoptimised(ODE,Run,Chunk_Number);
    % Time_Out yt_Out,V_out,L_out,S_out,ST_out,P_out
    
    Time_In = Run.Chunks(Chunk_Number).TimeIn(1):Run.Chunks(Chunk_Number).TimeIn(3):Run.Chunks(Chunk_Number).TimeIn(2);
    Time_Out = Run.Chunks(Chunk_Number).TimeOut(1):Run.Chunks(Chunk_Number).TimeOut(3):Run.Chunks(Chunk_Number).TimeOut(2);
    Step_Size_In = Run.Chunks(1).TimeIn(3);
    Step_Size_Out = Run.Chunks(1).TimeOut(3);
    Transients_EmptyFlag =  isempty(Run.Regions(1).Conditions.Transients.Matrix);
    
    y0 = Run.Regions(1).Conditions.Initials.Conditions;
    y0_Sub = Run.Regions(1).Conditions.Initials.Seafloor;
    y0_Meta = Run.Regions(1).Conditions.Initials.Outgassing;
    
    % Preallocate the output vector and assign the first value
    yt_Out = NaN(numel(y0),numel(Time_Out));
    y_1(:,1) = y0;
    y_1_Sub(:,1) = y0_Sub;
    y_1_Meta(:,1) = y0_Meta;
    y_2(1:numel(y0),1) = NaN;
    dy_1(1:numel(y0),1) = NaN;
    dy_2(1:numel(y0),1) = NaN;
    V_out = NaN(1,numel(Time_Out));
    L_out = NaN(1,numel(Time_Out));
    ST_out = NaN(1,numel(Time_Out));
    if isnan(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths);
        S_out = NaN;
    else
        S_out = NaN(numel(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths),numel(Time_Out));
    end
    P_out = NaN(2,numel(Time_Out));
    
    % Run once to update present conditions ### WHY?
    ODE(0,y0,y0_Sub,y0_Meta,Chunk_Number);
    
    if ~Transients_EmptyFlag;
        for Parameter_Number = 1:size(Run.Regions(1).Conditions.Transients.Matrix,1);
            V0{Parameter_Number,1}(:) = Run.Regions(1).Conditions.Presents.(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,2}).(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,3})(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,4})';
        end
        V = V0;
    else
        V0 = [];
        V = V0;
    end
    
    V_out = {};
    
    L0 = Run.Regions(1).Conditions.Presents.Carbonate_Chemistry.Lysocline;
    L = L0;
    
    %% Assume that the output difference is an exact multiple of h, and the
    % starting time is the same, otherwise error out
    if rem(Step_Size_Out,Step_Size_In)==0 && Time_Out(1)==Time_In(1);
        % Same number of steps each time
        Count_Reached = (Time_Out(2)-Time_Out(1))/Step_Size_In;
        Place = 1;
        
        if Time_Out(1)==Time_In(1);
            yt_Out(:,1) = y0;
            if ~Transients_EmptyFlag;
                for Parameter_Number = 1:size(Run.Regions(1).Conditions.Transients.Matrix,1);
                    V_out{Parameter_Number,1}(:,1) = (V0{Parameter_Number,1})';
                end
            end
            L_out(1) = L0;
            if ~isnan(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths);
                S_out(:,1) = y0_Sub(1001-(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths/10));
            end
            ST_out(:,1) = sum(y0_Sub);
            P_out(:,1) = Run.Regions(1).Conditions.Presents.Carbon.PIC_Burial;
            
            if yt_Out(18,Place)<-5;
                Edge_Box_Fill = 1+rem(yt_Out(18,Place)+5,10)/10;
            else
                Edge_Box_Fill = rem(yt_Out(18,Place)+5,10)/10;
            end
            
            OceanArray = double(Run.Regions(1).Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints<round(yt_Out(17,Place)));
            OceanArray(1001-round(yt_Out(18,Place)/10)) = Edge_Box_Fill;
            
            % Carbonate_Weathering = (1-OceanArray).*(y_2_Sub.*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Exposure).*y(14).*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Weatherability;
            ST_out(2,Place) = sum((1-OceanArray).*(y_1_Sub).*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Exposure);
            
            Place = 2;
        end
        
        Count = 1;
%         try
            for Current_Step = 2:numel(Time_In);
                % Calculate gradient at point 1
                [dy_1,dy_1_Sub,dy_1_Meta] = ODE(Time_In(Current_Step-1),y_1,y_1_Sub,y_1_Meta,Chunk_Number);
                % Calculate y value using that gradient
                y_2 = y_1+(dy_1.*Step_Size_In);
                y_2_Sub = y_1_Sub+(dy_1_Sub.*Step_Size_In);
                y_2_Meta = y_1_Meta+(dy_1_Meta.*Step_Size_In);
                % Calculate gradient using new y value
                [dy_2,dy_2_Sub,dy_2_Meta] = ODE(Time_In(Current_Step),y_2,y_2_Sub,y_2_Meta,Chunk_Number);
                % Recalculate y at point 2
                y_2 = y_1+(((dy_1+dy_2)/2).*Step_Size_In);
                y_2_Sub = y_1_Sub+(((dy_1_Sub+dy_2_Sub)/2).*Step_Size_In);
                y_2_Meta = y_1_Meta+(((dy_1_Meta+dy_2_Meta)/2).*Step_Size_In);
%                 ODE(Time_In(Current_Step),y_2,y_2_Sub,y_2_Meta);
                
                
                if Count==Count_Reached;
                    yt_Out(:,Place) = y_2;
                    % Lysocline
                    L_out(:,Place) = Run.Regions(1).Conditions.Presents.Carbonate_Chemistry.Lysocline;
                    if ~isnan(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths);
                        S_out(:,Place) = y_2_Sub(1001-(Run.Regions(1).Conditions.Presents.Seafloor.Core_Depths/10));
                    end
                    ST_out(1,Place) = sum(y_2_Sub);
                    P_out(:,Place) = Run.Regions(1).Conditions.Presents.Carbon.PIC_Burial;
                    
                    if yt_Out(18,Place)<-5;
                        Edge_Box_Fill = 1+rem(yt_Out(18,Place)+5,10)/10;
                    else
                        Edge_Box_Fill = rem(yt_Out(18,Place)+5,10)/10;
                    end
                    
                    OceanArray = double(Run.Regions(1).Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints<round(yt_Out(17,Place)));
                    OceanArray(1001-round(yt_Out(18,Place)/10)) = Edge_Box_Fill;
                    
%                     Carbonate_Weathering = (1-OceanArray).*(y_2_Sub.*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Exposure).*y(14).*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Weatherability;
                    ST_out(2,Place) = sum((1-OceanArray).*(y_2_Sub).*Run.Regions(1).Conditions.Presents.Weathering.Carbonate_Exposure);
                    
                    if ~Transients_EmptyFlag;
                        for Parameter_Number = 1:size(Run.Regions(1).Conditions.Transients.Matrix,1);
                            V{Parameter_Number,1} = Run.Regions(1).Conditions.Presents.(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,2}).(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,3})(Run.Regions(1).Conditions.Transients.Matrix{Parameter_Number,4});
                            V_out{Parameter_Number,1}(:,Place) = V{Parameter_Number,1};
                        end
                    end
                    
                    Count = 1;
                    Place = Place+1;
                else
                    Count = Count+1;
                end
                y_1 = y_2;
                y_1_Sub = y_2_Sub;
                y_1_Meta = y_2_Meta;
            end
    else
        error("The input and output times are not aligned. Output spacing must be a multiple of solver spacing, and must start at the same time.");
    end
    
    if ~isnan(S_out);
        DataOut = {[Time_Out;yt_Out;L_out,ST_out,S_out],V_out,P_out};
    else
        DataOut = {[Time_Out;yt_Out;L_out;ST_out],V_out,P_out};
    end
    Run.Regions(1).Outputs.Outgassing = y_2_Meta;
    Run.Regions(1).Outputs.Seafloor = y_2_Sub;
end
