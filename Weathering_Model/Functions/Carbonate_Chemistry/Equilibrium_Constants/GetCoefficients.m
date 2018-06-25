function Coefficients = GetCoefficients(Constant,Present);
    Coefficients{1} = Constant.k0_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{2} = Constant.k1_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{3} = Constant.k2_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{4} = Constant.kb_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{5} = Constant.kw_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{6} = Constant.ksp_cal_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{7} = Constant.ksp_arag_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
    Coefficients{8} = Constant.ks_Matrix(ceil(Present.Calcium(2)),ceil(Present.Magnesium(2)),:);
end