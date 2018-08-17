function Carbon = DefineCarbonParameters(Carbon);
    % Carbon Parameters
    Carbon.Redfield_Ratio = 117; %P:C = 1:Constant.RedfieldRatio
    
    Carbon.PIC_Neritic_Remineralisation = [0;0];
    Carbon.PIC_Neritic_Burial = [1;0];
    Carbon.PIC_Pelagic_Remineralisation = [0;0]; %fraction
    Carbon.PIC_Pelagic_Burial = [0;0];

    Carbon.POC_Neritic_Remineralisation = [1;0];
    Carbon.POC_Neritic_Burial = [0;0];
    Carbon.POC_Pelagic_Remineralisation = [0.9125;0.0874]; %fraction %FOR REALITY: [0.9260,xx] 
    Carbon.POC_Pelagic_Burial = [0;1].*(1-sum(Carbon.POC_Pelagic_Remineralisation));
    Carbon.POC_Burial_Maximum_Depth = 8000;

    Carbon.Production_Ratio = [0.1;0.1]; %fraction
    Carbon.Calcifier_Fraction = [0.5;0.035];
    
end