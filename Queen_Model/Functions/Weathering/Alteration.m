function Coefficients = Alteration(Coefficients,Number,Value,X_Lock);
    if numel(Number)==1;
%         x = [0;15]+273.15;
        y = (Coefficients(1)*exp(Coefficients(2)*X_Lock)+Coefficients(3));
        
        if Number == 1;
            % Assign tolerance
            Tolerance = 1e-12;
            
            % Assign b
            b_Query = Coefficients(2);
            b_Current = b_Query;
            
            % Calculate the difference
            Disparity = Weathering_One(X_Lock,y,Value,b_Current);
            
            % Estimate a new value for b through extrapolation
            if Disparity>0;
                b_Query(2) = b_Query(1)-(Disparity(1)/1e6*b_Query(1));
            else
                b_Query(2) = b_Query(1)+(Disparity(1)/1e6*b_Query(1));
            end
            
            b_Current = b_Query(2);
            Disparity(2) = Weathering_One(X_Lock,y,Value,b_Current);
            Disparity_Current = max(abs(Disparity));
            
            % Perform the iteration
            while abs(Disparity_Current)>Tolerance;
                % Estimate magical B value by interpolation
                b_Current = b_Query(2)-(Disparity(2).*((b_Query(2)-b_Query(1))./(Disparity(2)-Disparity(1))));
                % Now calculate disparity
                Disparity_Current = Weathering_One(X_Lock,y,Value,b_Current);
                % Replace the b value
                if Disparity_Current>0;
                    b_Query(2) = b_Current;
                    Disparity(2) = Disparity_Current;
                else
                    b_Query(1) = b_Current;
                    Disparity(1) = Disparity_Current;
                end
            end
            Coefficients(1) = Value;
            Coefficients(2) = b_Current;
            Coefficients(3) = y(2)-(Coefficients(1).*exp(Coefficients(2).*X_Lock(2)));
        end
    elseif numel(Number)==3;
%         x = 15+273.15;
        y = (Coefficients(1)*exp(Coefficients(2)*X_Lock)+Coefficients(3));
        
        if isnan(Value(1));
            Value(1) = (y-Value(3))./(exp(Value(2).*X_Lock));
        elseif isnan(Value(2));
            Value(2) = (1./X_Lock).*(log((y-Value(3))/Value(1)));
        elseif isnan(Value(3));
            Value(3) = y-(Value(1).*exp(Value(2).*X_Lock));
        end
        Coefficients(1) = Value(1);
        Coefficients(2) = Value(2);
        Coefficients(3) = Value(3);
        
    end
end
function Disparity = Weathering_One(x,y,a,b_in);
    Disparity = a.*(exp(b_in.*x(2))-exp(b_in.*x(1)))-(y(2)-y(1));    
end