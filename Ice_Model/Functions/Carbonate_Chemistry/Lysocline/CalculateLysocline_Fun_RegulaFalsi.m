function LysoclineDepth = CalculateLysocline_Fun_RegulaFalsi(GECCOObject,DIC,Temperature,Coefficients);
%% CalculateLysocline calculates lysocline depth

% Of the form:
% Lysocline Depth - Logic
% Martin: Fq = Fs(q/s)^b    Fq = Fd(q/d)^b
% At 1m: Fq = 6*(3000/1)^0.1;
% b = log(7.5)/log(3.5*(1/1550));
% b = log(Fs)/log(Fd*(s/d))

% ##If the input is NaN then the output is always the first midpoint

    %% One input = direct, simple calculation
    b = log10(Temperature(1)/Temperature(2))/log10(GECCOObject.Architectures.Midpoints(1)/GECCOObject.Architectures.Midpoints(2));
    Q = Temperature(2)*((1/GECCOObject.Architectures.Midpoints(2)).^b);
    R = 83.131; % Newer 83.14510
    
%     zi = [max([LysoclineIn-100,0]),min([LysoclineIn+100,9990])];
    zi = GECCOObject.Conditions.Present.Lysocline;

    z = zi;
%     Ksp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+(0.0028426*Q*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*GECCOObject.Conditions.Present.Salinity(2))+(0.0041249*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
%     K1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((1.758197781/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*GECCOObject.Conditions.Present.Salinity(2))-((2.841189244e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
%     K2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((10.41099418/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*GECCOObject.Conditions.Present.Salinity(2))-((3.678187627e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));
    
    K1_Uncorrected = Coefficients{2}(1) + (Coefficients{2}(2)./(Q.*(z.^b))) + (Coefficients{2}(3).*(log(Q.*(z.^b)))) + (Coefficients{2}(4).*GECCOObject.Conditions.Present.Salinity(2)) + (Coefficients{2}(5).*(GECCOObject.Conditions.Present.Salinity(2).^2));
    K1_Pressure_Correction = (1/(23.02585.*R.*Q)).*(-60.217365.*(z^(1-b)) + (Q.*z.*0.1271) + 0.05.*((-0.027055255).*(z.^(2-b)) + Q.*(z.^2).*(8.77e-5)));
    K1 = 1e3 .* 10.^(K1_Uncorrected+K1_Pressure_Correction);
    
    K2_Uncorrected = Coefficients{3}(1) + (Coefficients{3}(2)./(Q.*(z.^b))) + (Coefficients{3}(3).*(log(Q.*(z.^b)))) + (Coefficients{3}(4).*GECCOObject.Conditions.Present.Salinity(2)) + (Coefficients{3}(5).*(GECCOObject.Conditions.Present.Salinity(2).^2));
    K2_Pressure_Correction = (1/(23.02585.*R.*Q)).*(-9.838015.*(z^(1-b)) + (Q.*z.*0.0219) + 0.05.*((-0.039189625).*(z.^(2-b)) + Q.*(z.^2).*(1.475e-5)));
    K2 = 1e3 .* 10.^(K2_Uncorrected+K2_Pressure_Correction);
    
    Ksp_Uncorrected = (1/(23.02585.*R.*Q)).*(-193.63876.*(z^(1-b)) + (Q.*z.*0.5304) + 0.05.*((-0.11264698).*(z.^(2-b)) + Q.*(z.^2).*(3.692e-4)));
    Ksp_Pressure_Correction = Coefficients{6}(1) + (Coefficients{6}(2).*Q.*(z.^b)) + (Coefficients{6}(3)./(Q.*(z.^b))) + (Coefficients{6}(4).*log10(Q.*(z.^b))) + (sqrt(GECCOObject.Conditions.Present.Salinity(2)).*(Coefficients{6}(5) + (Coefficients{6}(6).*Q.*(z.^b)) + (Coefficients{6}(7)./(Q.*(z.^b))))) + (Coefficients{6}(8).*GECCOObject.Conditions.Present.Salinity(2)) + (Coefficients{6}(9).*(GECCOObject.Conditions.Present.Salinity(2).^(1.5)));
    Ksp = 1e6 .* 10.^(Ksp_Uncorrected+Ksp_Pressure_Correction);
    
    CO3_fraction = 1/(1+((1000*10^-GECCOObject.Conditions.Present.pH(2))/K2)+(((1000*10^-GECCOObject.Conditions.Present.pH(2))^2)/((K1)*(K2))));
    CO3 = DIC*CO3_fraction;
    CaCO3 = GECCOObject.Conditions.Present.Calcium(2)*CO3;

    Eqn(1) = Ksp-CaCO3;
    
    if zi<10 && CaCO3<0.5;
        z = 0;
    elseif zi>9990 && CaCO3>5;
        z = 10000;
    else
    if abs(Eqn(1))>1e-6;
        if Eqn(1)>0;
            zi(2) = GECCOObject.Conditions.Present.Lysocline-Eqn(1)*5000;
            if zi(2)<0;
                zi(2) = GECCOObject.Conditions.Present.Lysocline-Eqn(1)*1000;
            end
            if zi(2)<0;
                zi(2) = GECCOObject.Conditions.Present.Lysocline-Eqn(1)*100;
            end
        else
            zi(2) = GECCOObject.Conditions.Present.Lysocline+Eqn(1)*5000;
            if zi(2)<0;
                zi(2) = GECCOObject.Conditions.Present.Lysocline+Eqn(1)*1000;
            end
            if zi(2)<0;
                zi(2) = GECCOObject.Conditions.Present.Lysocline+Eqn(1)*100;
            end
        end
        
        z = zi(2);
        Ksp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+(0.0028426*Q*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*GECCOObject.Conditions.Present.Salinity(2))+(0.0041249*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
        K1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((1.758197781/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*GECCOObject.Conditions.Present.Salinity(2))-((2.841189244e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
        K2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((10.41099418/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*GECCOObject.Conditions.Present.Salinity(2))-((3.678187627e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));
        
        CO3_fraction = 1/(1+((1000*10^-GECCOObject.Conditions.Present.pH(2))/K2)+(((1000*10^-GECCOObject.Conditions.Present.pH(2))^2)/((K1)*(K2))));
        CO3 = DIC*CO3_fraction;
        CaCO3 = GECCOObject.Conditions.Present.Calcium(2)*CO3;
        
        Eqn(2) = Ksp-CaCO3;
        
        z = zi(2)-(Eqn(2).*((zi(2)-zi(1))./(Eqn(2)-Eqn(1))));
    else
        z = zi(1);
    end
    end
    

    if z<0;
        z = 0;
    elseif z>9990;
        z = 9990;
    end

    LysoclineDepth = z;

end

