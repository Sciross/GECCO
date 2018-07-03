% My simple, first order, Euler solver
function DataOut = MySolver_15_Implicit_Trial(ODE,Run,Chunk_Number);
% Time_Out yt_Out,V_out,L_out,S_out,ST_out,P_out
    % Where Times are vectors  
%     Run.Regions(1),Time_In,Time_Out,y0,y0_Sub,y0_Meta
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
    
    %% No interpolation
    % If the input matrix is exactly equal to the output matrix
    if numel(Time_In)==numel(Time_Out);
        if sum(Time_In==Time_Out)==numel(Time_Out);
            
            % Sort out first step
            if Time_Out(1)==0 && Time_In(1)==0;
                yt_Out(:,1) = y0;
                if ~Transients_EmptyFlag;
                    V_out(:,1) = V0;
                end
                L_out(:,1) = L0;
                if ~isnan(Run.Regions(1).Conditions.Present.Core_Depths);
                    S_out(:,1) = y0_Sub(Run.Regions(1).Conditions.Present.Core_Depths);
                end
                ST_out(:,1) = sum(y0_Sub);
                Time_Out = Time_Out(2:end);
                Time_In = Time_In(2:end);
            end
            
            % 
            for Current_Step = 1:numel(Time_In);
                % Calculate the gradient at point 1
                dy_1 = ODE(Time_In(Current_Step),y_1)';
                % Calculate the value at point 2
                y_2 = y_1+(dy_1*Step_Size_In);
                % Calculate he gradient at point 2
                dy_2 = ODE(Time_In(Current_Step),y_2)';
                % Recalculate y2 using the later gradient
                y_2 = y_1+(dy_2*Step_Size_In);
                % Push to output matrix
                yt_Out(Current_Step+1,:) = y_2;
                % Assign to point one for next round
                y_1 = y_2;
            end
        end
        
%     % Else if the output time is an exact multiple of h, but the
%     % starting time is different
%     elseif sum(rem(TimeOut,h))==0;
%     CountOneReached = TimeOut(1)/h;
%     CountReached = (TimeOut(2)-TimeOut(1))/h;
%     Count = 1;
%     Flag = 0;
%     for n = 1:numel(TimeIn)-1;
%         dy = ODE(TimeIn(n),y)';
%         y2 = y+(dy*TimeIn(2));
%         
%         dy2 = ODE(TimeIn(n),y2)';
%         y = y+(dy2*TimeIn(2));
%         
%         if Count==CountOneReached;
%             Flag =1;
%         end
%         
%         if Count==CountReached && Flag==1;
%             yout(CountReached+1,:) = y;
%             Count = 1;
%         end
%         
%         Count = Count+1;
%     end
    % Else if the output difference is an exact multiple of h, and the
    % starting time is the same
    elseif rem(Step_Size_Out,Step_Size_In)==0 && Time_Out(1)==Time_In(1);
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
%         catch
%             DataOut = {Time_Out,yt_Out,V_out,L_out,S_out,ST_out,P_out};
%             Run.Regions(1).Outputs.Outgassing = y_2_Meta;
%             Run.Regions(1).Outputs.Seafloor = y_2_Sub;
%             return;
%         end
            
            
%             if rem(Time_In(Current_Step),10)==0;
%                 figure(5);
%                 s1 = subplot(7,1,1);
%                 hold on
%                 plot(Time_In(Current_Step),y_1(1).*Run.Regions(1).Conditions.Present.Atmosphere_Volume,'.k');
%                 
%                 s2 = subplot(7,1,2);
%                 hold on
%                 plot(Time_In(Current_Step),y_1(5).*Run.Regions(1).Architectures.BoxDepths(1).*Run.Regions(1).Architectures.BoxArea,'.k');
%                 
%                 s3 = subplot(7,1,3);
%                 hold on
%                 plot(Time_In(Current_Step),y_1(6).*Run.Regions(1).Architectures.BoxDepths(2).*Run.Regions(1).Architectures.BoxArea,'.k');
%                 
%                 s4 = subplot(7,1,4);
%                 hold on
%                 plot(Time_In(Current_Step),y_1(13),'.k');
%                 
%                 s5 = subplot(7,1,5);
%                 hold on
%                 plot(Time_In(Current_Step),sum(y_1_Sub),'.k');
%                 
%                 s6 = subplot(7,1,6);
%                 hold on
%                 plot(Time_In(Current_Step),sum(y_1_Meta),'.k');
%                 
%                 if rem(Time_In(Current_Step),Run.Regions(1).Conditions.Present.Metamorphism_Resolution)==0;
%                     RemainingInBox = 0;
%                 else
%                     RemainingInBox = (1-rem(Time_In(Current_Step),Run.Regions(1).Conditions.Present.Metamorphism_Resolution)/Run.Regions(1).Conditions.Present.Metamorphism_Resolution)*(y_1_Meta(1+floor(Time_In(Current_Step)/Run.Regions(1).Conditions.Present.Metamorphism_Resolution)));
%                 end
%                 Total = (y_1(1).*Run.Regions(1).Conditions.Present.Atmosphere_Volume) + (y_1(5).*Run.Regions(1).Architectures.BoxDepths(1).*Run.Regions(1).Architectures.BoxArea) + (y_1(6).*Run.Regions(1).Architectures.BoxDepths(2).*Run.Regions(1).Architectures.BoxArea) + y_1(13) + sum(y_1_Sub) + sum(y_1_Meta((2+floor(Time_In(Current_Step-1)/Run.Regions(1).Conditions.Present.Metamorphism_Resolution)):end)) + RemainingInBox;
%                 
%                 subplot(7,1,7);
%                 hold on
%                 plot(Time_In(Current_Step),Total,'.g');
%                 
%                 set([s1,s2,s3,s4,s5,s6],'XTick',[]);
%                 drawnow;
%             end

%     % Else if the output difference is an exact multiple of h, and the
%     % starting time is different
%     elseif sum(rem(diff(TimeOut),h))==0;
%     CountOneReached = TimeOut(1)-rem(TimeOut(1)/h);
%     CountReached = (TimeOut(2)-TimeOut(1))/h;
%     Count = 1;
%     Flag = 0;    
%     for n = 1:numel(TimeIn)-1;
%         dy = ODE(TimeIn(n),y)';
%         y2 = y+(dy*TimeIn(2));
%         
%         dy2 = ODE(TimeIn(n),y2)';
%         y = y+(dy2*TimeIn(2));
%         
%         if CountOneReached==Count && Flag==0;
%             Flag = 1;
%             h = rem(TimeOut(1)/h);
%             
%             % #UNSURE WHICH TO USE
%             n = n+1;
% %             TimeIn(n) = TimeIn(n+1);
%             
%             dy = ODE(TimeIn(n),y)';
%             y2 = y+(dy*h);
%         
%             dy2 = ODE(TimeIn(n),y2)';
%             y = y+(dy2*h);
%         end
%         
%         if Count==CountReached && Flag==1;
%             yout(CountReached+1,:) = y;
%             Count = 1;
%         end
%         
%         Count = Count+1;
%     end
%     % Assuming we need to interpolate and tout interval>h
    elseif Step_Size_Out>Step_Size_In;

        Interpolation_At = (ceil((Time_Out-Time_In(1))./Step_Size_In))+1;
        Count = 1;
        % Sort out first step
        if Time_Out(1)==0 && Time_In(1)==0;
            yt_Out(1,:) = y0;
            if ~Transients_EmptyFlag;
                V_out(1,:) = V0;
            end
            L_out(1,:) = L0;
%             Time_Out = Time_Out(2:end);
%             Time_In = Time_In(2:end);
            
            Count = Count+1;
        end
        
        for Current_Step = 1:numel(Time_In);
            Vprev = V;
            Lprev = L;
            
            % Calculate gradient at point 1
            [dy_1,dy_1_Sub,dy_1_Meta] = ODE(Time_In(Current_Step),y_1,y_1_Sub,y_1_Meta);
            % Calculate y value using that gradient
            y_2 = y_1+(dy_1'.*Step_Size_In);
            y_2_Sub = y_1_Sub+(dy_1_Sub'.*Step_Size_In);
            y_2_Meta = y_1_Meta+(dy_1_Meta'.*Step_Size_In);
            % Calculate gradient using new y value
            [dy_2,dy_2_Sub,dy_2_Meta] = ODE(Time_In(Current_Step),y_2,y_2_Sub,y_2_Meta);
            % Recalculate y at point 2
            y_2 = y_1+(dy_2'.*Step_Size_In);
            y_2_Sub = y_1_Sub+(dy_2_Sub'.*Step_Size_In);
            y_2_Meta = y_1_Meta+(dy_2_Meta'.*Step_Size_In);
            
            if Current_Step==Interpolation_At(Count);
               yt_Out(Count,:) = HermiteCubicInterp([Time_In(Current_Step-1);Time_In(Current_Step)],[y_1;y_2],[dy_1;dy_2],Time_Out(Count));
                       
               % Variables
               if ~Transients_EmptyFlag;
                   for Parameter_Number = 1:size(Run.Regions(1).Conditions.Variable,1);
                       V(1,Parameter_Number) = Run.Regions(1).Conditions.Present.(Run.Regions(1).Conditions.Variable{Parameter_Number,1}{1})(Run.Regions(1).Conditions.Variable{Parameter_Number,2});
                   end
                   V_out(Count,:) = LinearInterp([Time_In(Current_Step-1);Time_In(Current_Step)],[Vprev;V],Time_Out(Count));
               end
               
               % Lysocline
               L = Run.Regions(1).Conditions.Present.Lysocline;
               L_out(Count,:) = LinearInterp([Time_In(Current_Step-1);Time_In(Current_Step)],[Lprev;L],Time_Out(Count));
               
                Count = Count+1;
            end
            
            % Assign to point one for next round
            y_1 = y_2;
            y_1_Sub = y_2_Sub;
            y_1_Meta = y_2_Meta;
        end
    end
        
%     elseif StepSize>mean(diff(TimeOut));
%         for CurrentStep = 1:numel(TimeIn)-1;
%             dy = ODE(TimeIn(CurrentStep),y)';
%             y2 = y+(dy*StepSize);
%             
%             dy2 = ODE(TimeIn(CurrentStep),y2)';
%             yN = y+(dy2*StepSize);
%             
%             TRight = TimeOut>=TimeIn(CurrentStep) & TimeOut<TimeIn(CurrentStep+1);
%             Times = TimeOut(TRight);
%             ytout(TRight) = HermiteCubicInterp([TimeIn(CurrentStep);TimeIn(CurrentStep+1)],[y;yN],[dy;dy2],Times);
%         
%             y = yN;
%         
%         end
%         ytout = [y0;ytout];
%     end
    if ~isnan(S_out);
        DataOut = {[Time_Out;yt_Out;L_out,ST_out,S_out],V_out,P_out};
    else
        DataOut = {[Time_Out;yt_Out;L_out;ST_out],V_out,P_out};
    end
    Run.Regions(1).Outputs.Outgassing = y_2_Meta;
    Run.Regions(1).Outputs.Seafloor = y_2_Sub;
%     if isnan(Run.Regions(1).Conditions.Present.Core_Depths);
%         S_out = NaN;
%     end
end
