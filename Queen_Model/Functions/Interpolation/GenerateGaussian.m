function Gaussian = GenerateGaussian(X_Values,Spread_Mean);
    Spread = Spread_Mean(1);
    Mean = Spread_Mean(2);

    Gaussian = (1/(2.506628274631.*Spread)).*exp(-0.5.*(((X_Values-Mean)./Spread).^2));
end