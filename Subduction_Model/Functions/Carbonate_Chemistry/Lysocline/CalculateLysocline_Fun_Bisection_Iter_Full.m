function LysoclineDepth = CalculateLysocline_Fun_Bisection_Iter(SurfaceMidpoint,DeepMidpoint,Constant,pH,DIC,LysoclineIn);
%% CalculateLysocline calculates lysocline depth
% #Is slow
% #If theinput is NaN then the output is always the first midpoint

%% Check for bad input
% global LysoclineIn

%% One input = direct, simple calculation
b = log10(Constant.Temperature(1)/Constant.Temperature(2))/log10(SurfaceMidpoint/DeepMidpoint);
%     c = log(SurfaceCO3./DeepCO3)/log(SurfaceMidpoint/DeepMidpoint);
Q = Constant.Temperature(2)*((1/DeepMidpoint).^b);
Ca = 10.28;

% if LysoclineIn == 9990 || LysoclineIn == 0;
%     zi = [0,9990];
%     
%     z = zi(1);
%     LogKsp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(Constant.Salinity(2)^(1/2)))+(0.0028426*Q*(Constant.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*Constant.Salinity(2))+(0.0041249*(Constant.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
%     LogK1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(Constant.Salinity(2)^(1/2)))+((1.758197781/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*Constant.Salinity(2))-((2.841189244e-3)*(Constant.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Constant.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
%     LogK2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(Constant.Salinity(2)^(1/2)))+((10.41099418/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*Constant.Salinity(2))-((3.678187627e-3)*(Constant.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Constant.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));
%     CO3_fraction = 1/(1+((1000*10^-pH)/LogK2)+(((1000*10^-pH)^2)/((LogK1)*(LogK2))));
%     CO3 = DIC*CO3_fraction;
%     CaCO3 = Ca*CO3;
%     Eqn = LogKsp-CaCO3;
%     Anomaly(1) = Eqn;
%     
%     z = zi(2);
%     LogKsp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(Constant.Salinity(2)^(1/2)))+(0.0028426*Q*(Constant.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*Constant.Salinity(2))+(0.0041249*(Constant.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
%     LogK1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(Constant.Salinity(2)^(1/2)))+((1.758197781/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*Constant.Salinity(2))-((2.841189244e-3)*(Constant.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Constant.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
%     LogK2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(Constant.Salinity(2)^(1/2)))+((10.41099418/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*Constant.Salinity(2))-((3.678187627e-3)*(Constant.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Constant.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));
%     CO3_fraction = 1/(1+((1000*10^-pH)/LogK2)+(((1000*10^-pH)^2)/((LogK1)*(LogK2))));
%     CO3 = DIC*CO3_fraction;
%     CaCO3 = Ca*CO3;
%     Eqn = LogKsp-CaCO3;
%     Anomaly(2) = Eqn;
%     
%     if zi(1)==1 && zi(2)==9990 && Anomaly(1)>0 && Anomaly(2)>0;
%         z = 0;
%         Anomaly = 0;
%     elseif zi(1)==1 && zi(2)==9990 && Anomaly(1)<0 && Anomaly(2)<0;
%         z = 9990;
%         Anomaly = 0;
%     else
%         Anomaly = 10000;
%     end
% else
    zi = [1,9990];
% end

Tol = 0.001;
Anomaly = 10000;

while abs(Anomaly)>Tol;
    z = (zi(1)+zi(2))/2;
    LogKsp = 10^(((-171.9065-(0.077993*Q*(z^b))+((2839.319/Q)*(z^(-b)))+(71.595*log10(Q*(z^b)))-(0.77712*(Constant.Salinity(2)^(1/2)))+(0.0028426*Q*(Constant.Salinity(2)^(1/2))*(z^b))+((178.34/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))-(0.07711*Constant.Salinity(2))+(0.0041249*(Constant.Salinity(2)^(3/2)))+log10(10^6)))+(( ((0.1011611131*z^(1-b))/Q)-((2.770925325e-4)*z)-(((2.941417163e-6)*(z^(2-b)))/Q)+((9.643906767e-9)*z^2) )));
    LogK1 = 10^((1.231898013)-((1001.972357/Q)*(z^(-b)))-(0.674338373*log(Q*(z^b)))-(0.09016318686*(Constant.Salinity(2)^(1/2)))+((1.758197781/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))+(0.03677753333*Constant.Salinity(2))-((2.841189244e-3)*(Constant.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Constant.Salinity(2)))+(log10(10^3))+((0.031458865332/Q)*(z^(1-b)))-((6.634757094e-5)*z)-(((7.06190354e-7)/Q)*(z^(2-b)))+((2.290819674e-9)*(z^2)));
    LogK2 = 10^((-4.007021512)-((1542.444885/Q)*(z^(-b)))-(0.0871083117*log(Q*(z^b)))-(0.04642685012*(Constant.Salinity(2)^(1/2)))+((10.41099418/Q)*(Constant.Salinity(2)^(1/2))*(z^(-b)))+(0.04911097546*Constant.Salinity(2))-((3.678187627e-3)*(Constant.Salinity(2)^(3/2)))+(0.4342944819*log(1-0.001005*Constant.Salinity(2)))+(log10(10^3))+(((5.139593466e-3)/Q)*(z^(1-b)))+((1.144103707e-5)*z)+(((1.081925791e-6)/Q)*(z^(2-b)))-((3.852860911e-9)*(z^2)));
    
    CO3_fraction = 1/(1+((1000*10^-pH)/LogK2)+(((1000*10^-pH)^2)/((LogK1)*(LogK2))));
    CO3 = DIC*CO3_fraction;
    CaCO3 = Ca*CO3;
    
    Eqn = LogKsp-CaCO3;
    Anomaly = Eqn;
    
    if Eqn>0;
        zi(2) = z;
    else
        zi(1) = z;
    end
    
    hold on
    plot(z,Eqn,'xb');
    drawnow;

end

    z = (zi(1)+zi(2))/2;
    
% end

LysoclineDepth = z;
% LysoclineIn = z;

% if ~isreal(LysoclineDepth);
%     error('Lysocline depth is a complex number...');
% end

%% Check for sensible output ##Currently unused
% CalculateLysoclineCheckOut(SurfaceOmega,DeepOmega,SurfaceMidpoint,DeepMidpoint,DepthRange,NormalisedKSpConstants,SatWithDepth);

end

% Lysocline Depth - Logic
% Martin: Fq = Fs(q/s)^b    Fq = Fd(q/d)^b
% At 1m: Fq = 6*(3000/1)^0.1;
% b = log(7.5)/log(3.5*(1/1550));
% b = log(Fs)/log(Fd*(s/d))

