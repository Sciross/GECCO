function Constant = DefineMetamorphismConstants_OO(Constant);
    
    %% Metamorphism Constants
    Constant.Metamorphism_Spread = 2000000;
    Constant.Metamorphism_Mean_Lag = 40000000;
    Constant.Metamorphism_Resolution = 10000;
    Constant.Metamorphism_Gauss = gaussmf([-Constant.Metamorphism_Spread*4:Constant.Metamorphism_Resolution:Constant.Metamorphism_Spread*4],[Constant.Metamorphism_Spread,0]');
    Constant.Metamorphism_Gauss = Constant.Metamorphism_Gauss/sum(Constant.Metamorphism_Gauss);
%     MaxMetamorphism_Tracked = (Constant.Metamorphism_Lag(2))+(2*Constant.Metamorphism_Lag(1))+10000;
%     Constant.Metamorphism_Removed = zeros(1,MaxMetamorphism_Tracked);
    
end
