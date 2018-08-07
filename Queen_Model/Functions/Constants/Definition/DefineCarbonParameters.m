function Carbon = DefineCarbonParameters(Carbon);
    % Carbon Parameters
    Carbon.Redfield_Ratio = 117; %P:C = 1:Constant.RedfieldRatio
    Carbon.PIC_Remineralisation = [0;0]; %fraction
    Carbon.PIC_Burial = [0.4;0];

    Carbon.POC_Remineralisation = [0.9125;0.0874]; %fraction %FOR REALITY: [0.9260,xx] 
    Carbon.POC_Burial = [0;1].*(1-sum(Carbon.POC_Remineralisation));
    Carbon.POC_Burial_Maximum_Depth = 8000;

    Carbon.Production_Ratio = 0.1; %fraction
end