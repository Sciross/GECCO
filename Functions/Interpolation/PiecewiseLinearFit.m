function [Gradient,YIntercept] = PiecewiseLinearFit(x,y);
% y = mx + c
% m = (y2-y1)/(x2-x1)
Gradient = diff(y)./diff(x);
YIntercept = y(2:end)-(Gradient.*x(2:end));

end