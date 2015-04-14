function f_GW = GW(elec_locs)
%
% function f_GW = GW(elec_locs)
% function that takes in an array of electrode locations as a ratio of the
% total cochlear length (elec_locs) and outputs the corresponding Greenwood
% freqeuncy bands (f_GW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Define the Greenwood function: (Grasmeder et al.,2014)
A = 165.4;
a = 2.1;
k = 0.88;

F = @(x) A .* (10.^(a .* x) - k);

%Compute the corresponding center frequencies:
fc_GW = F(elec_locs); 

lower = fc_GW(2);
fc = fc_GW(1);
df = fc-lower;
upper = fc+df;

f_GW = sort([upper fc_GW'],'ascend');



