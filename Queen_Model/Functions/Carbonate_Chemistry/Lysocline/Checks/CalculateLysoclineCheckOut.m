function CalculateLysoclineCheckOut(SurfaceOmega,DeepOmega,SurfaceMidpoint,DeepMidpoint,DepthRange,NormalisedKSpConstants,SatWithDepth);

if (SatWithDepth(DepthRange==DeepMidpoint))~=DeepOmega;
%     warning(sprintf('%s %d','Calculation error, difference of',DeepOmega-SatWithDepth(DepthRange==DeepMidpoint)));
end

end

