function LysoclineDepth = CalculateLysocline_Fun_RegulaFalsi_Full_Iter(GECCOObject,DIC,Temperature);
%% CalculateLysocline calculates lysocline depth

% Of the form:
% Lysocline Depth - Logic
% Martin: Fq = Fs(q/s)^b    Fq = Fd(q/d)^b
% At 1m: Fq = 6*(3000/1)^0.1;
% b = log(7.5)/log(3.5*(1/1550));
% b = log(Fs)/log(Fd*(s/d))

% ##If the input is NaN then the output is always the first midpoint

    % Calculate the repeatedly used values
    b = log10(Temperature(1)/Temperature(2))/log10(GECCOObject.Architectures.Midpoints(1)/GECCOObject.Architectures.Midpoints(2));
    Q = Temperature(2)*((1/GECCOObject.Architectures.Midpoints(2)).^b);
    Ca = GECCOObject.Conditions.Present.Calcium(2);

     % Take the full range
    zi = [1,9990];

    % Do the calculation for the first value
    z = zi(1);
    LogKsp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+(0.0028426*Q*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*GECCOObject.Conditions.Present.Salinity(2))+(0.0041249*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
    LogK1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((1.758197781/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*GECCOObject.Conditions.Present.Salinity(2))-((2.841189244e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
    LogK2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((10.41099418/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*GECCOObject.Conditions.Present.Salinity(2))-((3.678187627e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));

    CO3_fraction = 1/(1+((1000*10^-GECCOObject.Conditions.Present.pH(2))/LogK2)+(((1000*10^-GECCOObject.Conditions.Present.pH(2))^2)/((LogK1)*(LogK2))));
    CO3 = DIC*CO3_fraction;
    CaCO3 = Ca*CO3;

    Eqn(1) = LogKsp-CaCO3;

    % Do the calculation for the second value
    z = zi(2);
    LogKsp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+(0.0028426*Q*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*GECCOObject.Conditions.Present.Salinity(2))+(0.0041249*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
    LogK1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((1.758197781/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*GECCOObject.Conditions.Present.Salinity(2))-((2.841189244e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
    LogK2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((10.41099418/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*GECCOObject.Conditions.Present.Salinity(2))-((3.678187627e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));

    CO3_fraction = 1/(1+((1000*10^-GECCOObject.Conditions.Present.pH(2))/LogK2)+(((1000*10^-GECCOObject.Conditions.Present.pH(2))^2)/((LogK1)*(LogK2))));
    CO3 = DIC*CO3_fraction;
    CaCO3 = Ca*CO3;

    Eqn(2) = LogKsp-CaCO3;
    
    if Eqn(1)<0 && Eqn(2)<0;
        z = 9990;
        LysoclineDepth = z;
        return;
    elseif Eqn(1)>0 && Eqn(2)>0;
        z = 0;
        LysoclineDepth = z;
        return;
    end
    
    EqnT = 10000;
    Tol = 0.000001;

    % Calculate a new lysocline by interpolation
    while abs(EqnT)>Tol;
        z = zi(2)-(Eqn(2).*((zi(2)-zi(1))./(Eqn(2)-Eqn(1))));
        
        LogKsp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+(0.0028426*Q*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*GECCOObject.Conditions.Present.Salinity(2))+(0.0041249*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
        LogK1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((1.758197781/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*GECCOObject.Conditions.Present.Salinity(2))-((2.841189244e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
        LogK2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(GECCOObject.Conditions.Present.Salinity(2)^(1/2)))+((10.41099418/Q)*(GECCOObject.Conditions.Present.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*GECCOObject.Conditions.Present.Salinity(2))-((3.678187627e-3)*(GECCOObject.Conditions.Present.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*GECCOObject.Conditions.Present.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));
        
        CO3_fraction = 1/(1+((1000*10^-GECCOObject.Conditions.Present.pH(2))/LogK2)+(((1000*10^-GECCOObject.Conditions.Present.pH(2))^2)/((LogK1)*(LogK2))));
        CO3 = DIC*CO3_fraction;
        CaCO3 = Ca*CO3;
        
        EqnT = LogKsp-CaCO3;
        
        if EqnT>0;
            zi(2) = z;
        else
            zi(1) = z;
        end
    end
    
    % Final check against crazy values
    if z<0;
        z = 0;
    elseif z>9990;
        z = 9990;
    end

    LysoclineDepth = z;

end

