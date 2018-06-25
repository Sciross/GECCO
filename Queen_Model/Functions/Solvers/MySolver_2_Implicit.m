% My simple, first order, Euler solver
function [ytout,Cout,Lout] = MySolver_2_Implicit(ODE,Time_In,y0,Time_Out,Model);
    % Where Times are vectors    
    Step_Size = Model.dt;
    Var_EmptyFlag =  isempty(Model.Conditions.Variable);
    
    % Preallocate the output vector and assign the first value
    ytout = NaN(numel(Time_Out)-1,numel(y0));
    y(1,:) = y0;
    dy2(1,1:numel(y0)) = NaN;
    
    % Run once to update present conditions ### WHY?
    ODE(0,y0);
    
    if ~Var_EmptyFlag;
        for ParameterNumber = 1:size(Model.Conditions.Variable,1);
            C0(1,ParameterNumber) = Model.Conditions.Present.(Model.Conditions.Variable{ParameterNumber,1}{1})(Model.Conditions.Variable{ParameterNumber,2});
        end
        C = C0;
    else
        C0 = [];
        C = C0;
    end
      
    Cout = [];
    
    L0 = Model.Conditions.Present.Lysocline;
    L = L0;
    
    %% No interpolation
    % If the input matrix is exactly equal to the output matrix
    if length(Time_In)==length(Time_Out);
        if sum(Time_In == Time_Out)==numel(Time_Out);
            for CurrentStep = 1:numel(Time_In)-1;
                dy = ODE(Time_In(CurrentStep),y)';
                y2 = y+(dy*Step_Size);
                
                dy2 = ODE(Time_In(CurrentStep),y2)';
                y = y+(dy2*Step_Size);
                ytout(CurrentStep+1,:) = y;
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
%     % Else if the output difference is an exact multiple of h, and the
%     % starting time is the same
%     elseif sum(rem(diff(TimeOut),h))==0 && TimeOut(1)==TimeIn(1);
%     CountReached = (TimeOut(2)-TimeOut(1))/h;
%     ytout(1,:) = y0;
%     Place = 2;
%     Count = 0;
%     for n = 1:numel(TimeIn)-1;
%         dy = ODE(TimeIn(n),y)';
%         y2 = y+(dy*TimeIn(2));
%         
%         dy2 = ODE(TimeIn(n),y2)';
%         y = y+(dy2*TimeIn(2));
%         
%         if Count==CountReached;
%             ytout(Place,:) = y;
%             Count = 0;
%             Place = Place+1;
%         end
%         
%         Count = Count+1;
%     end
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
    elseif Step_Size<mean(diff(Time_Out));
        StepsRequired = ceil((Time_Out-Time_In(1))./Step_Size);
        StaircaseStart = 1;
        if StepsRequired(1)==0;
            ytout(1,:) = y0;
            if ~Var_EmptyFlag;
                Cout(1,:) = C0;
            end
            Lout(1,:) = L0;
            StepsRequired = StepsRequired+1;
        end
        
        for Staircase = StaircaseStart:(numel(StepsRequired)-1);
            for CurrentStep = StepsRequired(Staircase):StepsRequired(Staircase+1);
                dyprev = dy2;
                yprev = y;
                Cprev = C;
                Lprev = L;
                
                dy = ODE(Time_In(CurrentStep),y)';
                y2 = y+(dy.*Step_Size);

                dy2 = ODE(Time_In(CurrentStep),y2)';
                y = y+(dy2*Step_Size);
            end
                ytout(Staircase+1,:) = HermiteCubicInterp([Time_In(CurrentStep);Time_In(CurrentStep-1)],[y;yprev],[dy2;dyprev],Time_Out(Staircase+1));
                
                if ~Var_EmptyFlag;
                    for ParameterNumber = 1:size(Model.Conditions.Variable,1);
                        C(1,ParameterNumber) = Model.Conditions.Present.(Model.Conditions.Variable{ParameterNumber,1}{1})(Model.Conditions.Variable{ParameterNumber,2});
                    end
                    Cout(Staircase+1,:) = LinearInterp([Time_In(CurrentStep);Time_In(CurrentStep-1)],[C;Cprev],Time_Out(Staircase+1));
                end
                L = Model.Conditions.Present.Lysocline;
                Lout(Staircase+1,:) = LinearInterp([Time_In(CurrentStep);Time_In(CurrentStep-1)],[L;Lprev],Time_Out(Staircase+1));
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
    end
end
