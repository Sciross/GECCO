%% Redefine Physical Constants
function RedefineBiologicalConstants(Initial,Constant);

Constant.Phosphate.Burial = 1-(Constant.Phosphate.SurfaceRemin+Constant.Phosphate.DeepRemin); %fraction

assignin('base','Initial',Initial);
assignin('base','Constant',Constant);

end
