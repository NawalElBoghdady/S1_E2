function f_SG = spiral_ganglion(elec_locs)
%
% function f_SG = spiral_ganglion(elec_locs)
% function that takes in an array of electrode locations as a ratio of the
% total cochlear length (elec_locs) and outputs the corresponding spiral
% ganglion freqeuncy bands (f_SG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Define the Spiral Ganglion location conversion: (Grasmeder et al.,2014)
m = -5.7 * 10^(-5);
n = 0.0014;
l = 1.43;

%y = @(x) (m .* (x.*100).^3) + (n .* (x.*100).^2) + (l .* (x.*100)); %the input locations must be in terms of 100%

%The following equation is the inverse transformation of the equation
%provided in (Grasmeder et al.,2014). This computes the OC locations that 
%correspond to the stimulated SG cell bodies:  
x = @(y) (((- n.^2/(90000*m.^2) + l./(30000*m)).^3 + (y./(2000000*m) - n.^3/(27000000*m.^3)...
    + (l*n)./(6000000*m.^2)).^2).^(1/2) + y./(2000000*m) - n.^3/(27000000*m.^3) + (l*n)./(6000000*m.^2)).^(1/3)...
    - n./(300*m) - (- n.^2/(90000*m.^2) + l./(30000*m))/(((l./(30000*m) - n.^2/(90000*m.^2)).^3 + ...
    (y./(2000000*m) - n.^3/(27000000*m.^3) + (l*n)./(6000000*m.^2)).^2).^(1/2)...
    + y./(2000000*m) - n.^3/(27000000*m.^3) + (l*n)./(6000000*m.^2)).^(1/3);

%Define the Greenwood function: (Grasmeder et al.,2014)
A = 165.4;
a = 2.1;
k = 0.88;

F = @(x) A .* (10.^(a .* x) - k);

%Compute the corresponding OC locations from the SG cell bodies:
x_SG = x(elec_locs) ./ 100; 

%Compute the corresponding center frequencies:
fc_SG = sort(F(x_SG),'ascend'); 

upper = fc_SG(2);
fc = fc_SG(1);
lower = 2*fc - upper;

f_SG = [lower fc_SG'];


