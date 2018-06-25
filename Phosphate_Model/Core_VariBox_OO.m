function dy = Core_VariBox_OO(t,y,n,GECCOObject,Time_Max,Time_Min)

% Preallocate
dy{n} = zeros(2+numel(GECCOObject.Architectures(n).BoxDepths),1);

% Combined rate expression for Algae number
dy{n}(2) = y{n}(2)*((GECCOObject.Architectures(n).Constant.GrowthRateMax*(y{n}(3)/(GECCOObject.Architectures(n).Constant.HalfConstant+y{n}(3))))-GECCOObject.Architectures(n).Constant.Mortality); %mol/m3/yr
% Biological export: Export = [A] * Ocean.Volume * Mortality
BiologicalExport = y{n}(2)*GECCOObject.Architectures(n).Volumes(1)*GECCOObject.Architectures(n).Constant.Mortality; %mol/yr

% Fluxes
% PhosphateFluxMixing = -sum([[0;diff(y(3:end))'.*GECCOObject.Architectures(n).Constant.MixingCoefficient'.*GECCOObject.Architectures(n).Constant.Ocean.Area],[-diff(y(3:end))'.*GECCOObject.Architectures(n).Constant.MixingCoefficient'.*GECCOObject.Architectures(n).Constant.Ocean.Area;0]],2); %mol/yr
TempMixingMatrix = NaN(1,size(GECCOObject.MixingMatrix,1));
for m = 1:size(GECCOObject.MixingMatrix,1);
    TempMixingMatrix(m) = GECCOObject.MixingMatrix(m,5).*y{GECCOObject.MixingMatrix(m,1)}(2+GECCOObject.MixingMatrix(m,2)).*GECCOObject.Architectures(GECCOObject.MixingMatrix(m,1)).BoxArea;
end

for l = 1:numel(GECCOObject.Architectures(n).BoxDepths);
    QualOut = GECCOObject.MixingMatrix(:,1)==n & GECCOObject.MixingMatrix(:,2)==l;
    if sum(QualOut) > 0;
        PhosphateOut(l,1) = sum(TempMixingMatrix(QualOut));
    else
        PhosphateOut(l,1) = 0;
    end
    
    QualIn = GECCOObject.MixingMatrix(:,3)==n & GECCOObject.MixingMatrix(:,4)==l;
    if sum(QualIn) > 0;
        PhosphateIn(l,1) = sum(TempMixingMatrix(QualIn));
    else
        PhosphateIn(l,1) = 0;
    end
    

end
PhosphateFluxMixing = PhosphateIn-PhosphateOut;

BiologicalFlux = BiologicalExport.*GECCOObject.Architectures(n).Constant.Phosphate.Remin;

Phosphate.Flux = PhosphateFluxMixing+BiologicalFlux';
Phosphate.Flux(1) = Phosphate.Flux(1)+GECCOObject.Architectures(n).Constant.Rivers.Input-BiologicalExport;

dy{n}(3:end) = (Phosphate.Flux'./GECCOObject.Architectures(n).Volumes)';

persistent Time_Prev
if isempty(Time_Prev)||(t==0);
    Time_Prev = 0;
    fprintf('Starting');
end
if t>(Time_Prev+((Time_Max-Time_Min)/100));
    fprintf('\b\b\b\b\b\b\b\b')
    fprintf('%.2d%s',(round(((t-Time_Min)/(Time_Max-Time_Min))*100,0)),'% done');
%     disp([num2str(round((t/Time_Max)*100,0)),'% done']);
    Time_Prev = t;
%     pause(0.1)
%     if t>=(Time_Max-1);
%         fprintf('\b\b\b\b\b\b\b\b Run Complete \n');
%     end
end

end
