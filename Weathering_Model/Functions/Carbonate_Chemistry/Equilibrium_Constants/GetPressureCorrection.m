%% Do Pressure Correction
function Corr = GetPressureCorrection(Tk,Tc,P,PressureCorrection);
    R = 83.1451; %cm^3.bar/mol/K % FROM CSYS
    
    TMatrix = [[1;1],Tc,Tc.^2]';
    
    V = PressureCorrection(:,1:3)*TMatrix;
    K = PressureCorrection(:,4:6)*TMatrix;
    
    RT = R.*Tk;
    FH = [(V(:,1)/RT(1))*P(1),(V(:,2)/RT(2))*P(2)];
    SH = [(K(:,1)/RT(1))*(P(1).^2),(K(:,2)/RT(2))*(P(2).^2)];
    
    Corr = exp(-FH + 0.5*SH)';
end