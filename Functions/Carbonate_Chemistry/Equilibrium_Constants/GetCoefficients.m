function Coefficients = GetCoefficients(CarbChem);
if CarbChem.CCK_Mg_Ca_Correction==2;
    Coefficients{1} = CarbChem.k0_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{2} = CarbChem.k1_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{3} = CarbChem.k2_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{4} = CarbChem.kb_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{5} = CarbChem.kw_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{6} = CarbChem.ksp_cal_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{7} = CarbChem.ksp_arag_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
    Coefficients{8} = CarbChem.ks_Matrix(ceil(CarbChem.Calcium(2)),ceil(CarbChem.Magnesium(2)),:);
elseif CarbChem.CCK_Mg_Ca_Correction==1;
    Coefficients = [];
elseif CarbChem.CCK_Mg_Ca_Correction==0;
    Coefficients = [];    
end