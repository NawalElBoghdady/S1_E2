function x = e_loc(e_array,cochlear_length)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function x = e_loc(e_array,cochlear_length)
%
%INPUT ARGUMENTS:
%
%e_array is a struct:
%                       type          => The commercial name for this electrode
%                                        array model
%                       ins_depth     => electrode array insertion depth (in mm)
%                       tot_length    => length of the whole electrode array (in mm)
%                       active_length => length of the stimulating portion
%                                        (containing the electrodes) (in mm)
%                       nchs          => total number of electrodes
%                       e_width       => the width of a single electrode in the
%                                        model (in mm)
%                       e_spacing     => intra-electrode spacing (in mm)
%
%cochlear_length:       The length of the cochlea implanted in mm
%
%OUTPUT ARGUMENTS:
%
%x:                     The electrode locations as a ratio of the total 
%                       cochlear_length. Numbers are given from BASE-to-APEX.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



if e_array.ins_depth > e_array.tot_length
    error('Insertion depth must be <= the total electrode array length');
end

%a = e_array.e_width;  %the width of a single electrode is 0.4mm in an AB HiFocus electrode array.
%b = e_array.e_spacing; %the intra-electrode spacing is 0.85mm in an AB HiFocus electrode array, center to center.

b = e_array.active_length./e_array.nchs;
nchs = e_array.nchs;

c = e_array.ins_depth - e_array.active_length; %the spacing from the beginning of the base till the first electrode.

x = zeros(nchs,1);
x(1) = c;

for i = 2:nchs
%     x(i) = x(1) + (i-1)*(a+b); %electrode locations base-to-apex
    x(i) = x(i-1) + b; %electrode locations base-to-apex
end

%x = (cochlear_length - x)./cochlear_length; %the final electrode positions are output as a ratio of the total cochlear length APEX-to-BASE.






