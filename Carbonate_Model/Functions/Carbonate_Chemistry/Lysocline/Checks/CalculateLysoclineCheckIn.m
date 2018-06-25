function CalculateLysoclineCheckIn(SurfaceOmega,DeepOmega,SurfaceMidpoint,DeepMidpoint,DepthRange,NormalisedKSpConstants);

assert(SurfaceMidpoint>0 && DeepMidpoint>0,'Depth must be greater than 0');
assert(numel(SurfaceOmega)==numel(DeepOmega),'Number of elements in temperature matrices is inconsistent.');
assert(min(DepthRange)>=0,'Minimum of depth range must be greater than 0');

end