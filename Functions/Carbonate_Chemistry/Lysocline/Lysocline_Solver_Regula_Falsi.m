function Lysocline_Out = Lysocline_Solver_Regula_Falsi(DIC,Midpoints,Temperature,Salinity,pH,Calcium,Calcium_Initial,Magnesium,Magnesium_Initial,Correction_Flag,Coefficients,Lysocline_In,Iteration_Flag,Tolerance);
%% CalculateLysocline calculates lysocline depth
% Of the form:
% Lysocline Depth - Logic
% Martin: Fq = Fs(q/s)^b    Fq = Fd(q/d)^b
% At 1m: Fq = 6*(3000/1)^0.1;
% b = log(7.5)/log(3.5*(1/1550));
% b = log(Fs)/log(Fd*(s/d))

% ##If the input is NaN then the output is always the first midpoint
if Correction_Flag==2;
    %% One input = direct, simple calculation
    b = log10(Temperature(1)/Temperature(2))/log10(Midpoints(1)/Midpoints(2));
    Q = Temperature(2)*((1/Midpoints(2)).^b);
    R = 83.131; %or 83.1457

    if any(Lysocline_In<=0);
        Lysocline_In(Lysocline_In<=0) = 1;
    end
    Lysocline_Query = Lysocline_In;

    Lysocline_Current = Lysocline_Query(1);
    [~,Ksp,CaCO3] = Lysocline_Calculation_Hain(Lysocline_Current,pH,DIC,Q,b,R,Salinity,Calcium,Coefficients);
                    
    if Lysocline_Current<10 && CaCO3<0.5 && numel(Lysocline_In)==1;
        Lysocline_Current = 0;
    elseif Lysocline_Current>9990 && CaCO3>5 && numel(Lysocline_In)==1;
        Lysocline_Current = 10000;
    else
        Disparity(1) = Ksp-CaCO3;
        if (numel(Lysocline_In)>1) || (abs(Disparity(1))>Tolerance);
            if (numel(Lysocline_In)<2)
                if Disparity(1)>0;
                    Lysocline_Query(2) = Lysocline_Query+(Disparity(1)*Lysocline_Query);
                else
                    Lysocline_Query(2) = Lysocline_Query-(Disparity(1)*Lysocline_Query);
                end
            else
                Lysocline_Query(2) = Lysocline_In(2);
            end
        
            Lysocline_Current = Lysocline_Query(2);
            [Disparity(2),~,~] = Lysocline_Calculation_Hain(Lysocline_Current,pH,DIC,Q,b,R,Salinity,Calcium,Coefficients);         
            
            Lysocline_Current = Lysocline_Query(2)-(Disparity(2).*((Lysocline_Query(2)-Lysocline_Query(1))./(Disparity(2)-Disparity(1))));
        
            if Iteration_Flag;
                Disparity_Current = Disparity(2);
                if Disparity_Current>0;
                    Lysocline_Query(2) = Lysocline_Current;
                else
                    Lysocline_Query(1) = Lysocline_Current;
                end
                if Lysocline_Current<0;
                    Lysocline_Current = 0;
                elseif Lysocline_Current>9990;
                    Lysocline_Current = 9990;
                else
                    while abs(Disparity_Current)>Tolerance && diff(Lysocline_Query)>1e-3;
                        Lysocline_Current = Lysocline_Query(2)-(Disparity(2).*((Lysocline_Query(2)-Lysocline_Query(1))./(Disparity(2)-Disparity(1))));
                        [Disparity_Current,~,~] = Lysocline_Calculation_Hain(Lysocline_Current,pH,DIC,Q,b,R,Salinity,Calcium,Coefficients);
                        
                        if Disparity_Current>0;
                            Lysocline_Query(2) = Lysocline_Current;
                            Disparity(2) = Disparity_Current;
                        else
                            Lysocline_Query(1) = Lysocline_Current;
                            Disparity(1) = Disparity_Current;
                        end
                    end
                end
            end
        else
            Lysocline_Current = Lysocline_Query(1);
        end
    end
    
    if Lysocline_Current<0;
        Lysocline_Current = 10;
    elseif Lysocline_Current>9990;
        Lysocline_Current = 9990;
    end

    Lysocline_Out = Lysocline_Current;
else
        %% One input = direct, simple calculation
    b = log10(Temperature(1)/Temperature(2))/log10(Midpoints(1)/Midpoints(2));
    Q = Temperature(2)*((1/Midpoints(2)).^b);
    R = 83.131; %or 83.1457

    if any(Lysocline_In<=0);
        Lysocline_In(Lysocline_In<=0) = 1;
    end
    Lysocline_Query = Lysocline_In;

    Lysocline_Current = Lysocline_Query(1);
    [~,Ksp,CaCO3] = Lysocline_Calculation_Zeebe(Lysocline_Current,pH,DIC,Q,b,R,Salinity,Calcium,Calcium_Initial,Magnesium,Magnesium_Initial,Correction_Flag,Coefficients);
                    
    if Lysocline_Current<10 && CaCO3<0.5 && numel(Lysocline_In)==1;
        Lysocline_Current = 0;
    elseif Lysocline_Current>9990 && CaCO3>5 && numel(Lysocline_In)==1;
        Lysocline_Current = 10000;
    else
        Disparity(1) = Ksp-CaCO3;
        if (numel(Lysocline_In)>1) || (abs(Disparity(1))>Tolerance);
            if (numel(Lysocline_In)<2)
                if Disparity(1)>0;
                    Lysocline_Query(2) = Lysocline_Query+(10*Disparity(1)*Lysocline_Query);
                else
                    Lysocline_Query(2) = Lysocline_Query-(10*Disparity(1)*Lysocline_Query);
                end
            else
                Lysocline_Query(2) = Lysocline_In(2);
            end
        
            Lysocline_Current = Lysocline_Query(2);
            [Disparity(2),~,~] = Lysocline_Calculation_Zeebe(Lysocline_Current,pH,DIC,Q,b,R,Salinity,Calcium,Calcium_Initial,Magnesium,Magnesium_Initial,Correction_Flag,Coefficients);
            
            Lysocline_Current = Lysocline_Query(2)-(Disparity(2).*((Lysocline_Query(2)-Lysocline_Query(1))./(Disparity(2)-Disparity(1))));
        
            if Iteration_Flag;
                Disparity_Current = Disparity(2);
                if Disparity_Current>0;
                    Lysocline_Query(2) = Lysocline_Current;
                    Disparity(2) = Disparity_Current;
                else
                    Lysocline_Query(1) = Lysocline_Current;
                    Disparity(1) = Disparity_Current;
                end
                if Lysocline_Current<0;
                    Lysocline_Current = 0;
                elseif Lysocline_Current>9990;
                    Lysocline_Current = 9990;
                else
                    while abs(Disparity_Current)>Tolerance && diff(Lysocline_Query)>1e-3;
                        Lysocline_Current = Lysocline_Query(2)-(Disparity(2).*((Lysocline_Query(2)-Lysocline_Query(1))./(Disparity(2)-Disparity(1))));
                        [Disparity_Current,~,~] = Lysocline_Calculation_Zeebe(Lysocline_Current,pH,DIC,Q,b,R,Salinity,Calcium,Calcium_Initial,Magnesium,Magnesium_Initial,Correction_Flag,Coefficients);
                        
                        if Disparity_Current>0;
                            Lysocline_Query(2) = Lysocline_Current;
                            Disparity(2) = Disparity_Current;
                        else
                            Lysocline_Query(1) = Lysocline_Current;
                            Disparity(1) = Disparity_Current;
                        end
                    end
                end
            end
        else
            Lysocline_Current = Lysocline_Query(1);
        end
    end
    
    if Lysocline_Current<0;
        Lysocline_Current = 10;
    elseif Lysocline_Current>9990;
        Lysocline_Current = 9990;
    end

    Lysocline_Out = Lysocline_Current;
end
end

function [Eqn,Ksp,CaCO3] = Lysocline_Calculation_Zeebe(L,pH,DIC,Q,b,R,Salinity,Calcium,Calcium_Initial,Magnesium,Magnesium_Initial,Correction_Flag,Coefficients);
    Ksp = 10^(((-171.9065-(0.077993*Q*(L^b))+((2839.319/Q)*(L^(-b)))+(71.595*log10(Q*(L^b)))-(0.77712*(Salinity(2)^(1/2)))+(0.0028426*Q*(Salinity(2)^(1/2))*(L^b))+((178.34/Q)*(Salinity(2)^(1/2))*(L^(-b)))-(0.07711*Salinity(2))+(0.0041249*(Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*L^(1-b))/Q)-((2.770925325e-4)*L)-(((2.941417163e-6)*(L^(2-b)))/Q)+((9.643906767e-9)*L^2) )));
    K1 = 10^((1.231898013)-((1001.972357/Q)*(L^(-b)))-(0.674338373*log(Q*(L^b)))-(0.09016318686*(Salinity(2)^(1/2)))+((1.758197781/Q)*(Salinity(2)^(1/2))*(L^(-b)))+(0.03677753333*Salinity(2))-((2.841189244e-3)*(Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(L^(1-b)))-((6.634757094e-5)*L)-(((7.06190354e-7)/Q)*(L^(2-b)))+((2.290819674e-9)*(L^2)));
    K2 = 10^((-4.007021512)-((1542.444885/Q)*(L^(-b)))-(0.0871083117*log(Q*(L^b)))-(0.04642685012*(Salinity(2)^(1/2)))+((10.41099418/Q)*(Salinity(2)^(1/2))*(L^(-b)))+(0.04911097546*Salinity(2))-((3.678187627e-3)*(Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(L^(1-b)))+((1.144103707e-5)*L)+(((1.081925791e-6)/Q)*(L^(2-b)))-((3.852860911e-9)*(L^2)));
    
    if Correction_Flag == 1;
        K1_Ca_Sensitivity = 33.73e-3;
        K1_Mg_Sensitivity = 155.05e-3;
        K1_Ca_Correction = K1_Ca_Sensitivity.*((Calcium(2)-Calcium_Initial(2))./Calcium_Initial(2));
        K1_Mg_Correction = K1_Mg_Sensitivity.*((Magnesium(2)-Magnesium_Initial(2))./Magnesium_Initial(2));
        K1_Correction = K1_Ca_Correction.*K1_Mg_Correction;
        
        K2_Ca_Sensitivity = 38.85e-3;
        K2_Mg_Sensitivity = 442.24e-3;
        K2_Ca_Correction = K2_Ca_Sensitivity.*((Calcium(2)-Calcium_Initial(2))./Calcium_Initial(2));
        K2_Mg_Correction = K2_Mg_Sensitivity.*((Magnesium(2)-Magnesium_Initial(2))./Magnesium_Initial(2));
        K2_Correction = K2_Ca_Correction.*K2_Mg_Correction;
        
        Alpha = 3.6655e-8;
        Ksp_Correction = - Alpha.*(5.14-Magnesium(2)./Calcium(2));
        
        K1 = K1+(K1.*K1_Correction);
        K2 = K2+(K2.*K2_Correction);
        Ksp = Ksp-Ksp_Correction;
    end    
    
    CO3_fraction = 1/(1+((1000*10^-pH(2))/K2)+(((1000*10^-pH(2))^2)/((K1)*(K2))));
    CO3 = DIC*CO3_fraction;
    CaCO3 = Calcium(2)*CO3;
    
    Eqn = Ksp-CaCO3;
end
function [Eqn,Ksp,CaCO3] = Lysocline_Calculation_Hain(L,pH,DIC,Q,b,R,Salinity,Calcium,Coefficients);
    K1_Uncorrected = Coefficients{2}(1) + (Coefficients{2}(2)./(Q.*(L.^b))) + (Coefficients{2}(3).*(log(Q.*(L.^b)))) + (Coefficients{2}(4).*Salinity(2)) + (Coefficients{2}(5).*(Salinity(2).^2));
    K1_Pressure_Correction = (1/(23.02585.*R.*Q)).*(60.217365.*(L^(1-b)) - (0.1271.*Q.*L) + 0.05.*(-0.027055255.*(L.^(2-b)) + (8.77e-5).*Q.*(L.^2)));
    K1 = 1e3 .* 10.^(K1_Uncorrected+K1_Pressure_Correction);
    
    K2_Uncorrected = Coefficients{3}(1) + (Coefficients{3}(2)./(Q.*(L.^b))) + (Coefficients{3}(3).*(log(Q.*(L.^b)))) + (Coefficients{3}(4).*Salinity(2)) + (Coefficients{3}(5).*(Salinity(2).^2));
    K2_Pressure_Correction = (1/(23.02585.*R.*Q)).*(9.838015.*(L^(1-b)) + (0.0219.*Q.*L) + 0.05.*(-0.039189625.*(L.^(2-b)) + (1.475e-4).*Q.*(L.^2)));
    K2 = 1e3 .* 10.^(K2_Uncorrected+K2_Pressure_Correction);
    
    Ksp_Uncorrected = Coefficients{6}(1) + (Coefficients{6}(2).*Q.*(L.^b)) + (Coefficients{6}(3)./(Q.*(L.^b))) + (Coefficients{6}(4).*log10(Q.*(L.^b))) + (sqrt(Salinity(2)).*(Coefficients{6}(5) + (Coefficients{6}(6).*Q.*(L.^b)) + (Coefficients{6}(7)./(Q.*(L.^b))))) + (Coefficients{6}(8).*Salinity(2)) + (Coefficients{6}(9).*(Salinity(2).^(1.5)));
    Ksp_Pressure_Correction = (1/(23.02585.*R.*Q)).*(193.63876.*(L^(1-b)) - (0.5304.*Q.*L) + 0.05.*(-0.11264698.*(L.^(2-b)) + (3.692e-4).*Q.*(L.^2)));
    Ksp = 1e6 .* 10.^(Ksp_Uncorrected+Ksp_Pressure_Correction);
    
    CO3_fraction = 1/(1+((1000*10^-pH(2))/K2)+(((1000*10^-pH(2))^2)/((K1)*(K2))));
    CO3 = DIC*CO3_fraction;
    CaCO3 = Calcium(2)*CO3;
    
    Eqn = Ksp-CaCO3;
end

