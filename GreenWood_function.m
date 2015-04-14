%Greenwood_function                                                                   %
%-------------------------------------------------------------------------------------%
% This Function calculates the center frequencies of electrodes according to Greenwood%
%                                                                                     % 
% syntax: Output=GreenWood_function(Cochlea_length,Insertion_depth,mode)              %
%                                                                                     %
% Inputs:                                                                             %
% -------                                                                             %
% Cochlea_length   : length of the cochlear in mm(default = 35 mm)                    %
% Insertion_Depth  : Insertion depth of electrodes. It is normally 22 mm              %
% mode             :- 1=>22 Channels, 2=> 43 Channels                                 %
%                                                                                     %
% Output:                                                                             %
% ------                                                                              %
% Frequencies vector sorted descending (basal to apical)                              %
%                                                                                     %
% More info:                                                                          % 
% ---------                                                                           %  
% To know more about the values used in Greenwood equations, please refere to         %
% http://en.wikipedia.org/wiki/Greenwood_Function                                     %
% http://www.irf.uka.de/~feldbus/AFM/BMGammaT.html                                    %
%                                                                                     %
% Examples:                                                                           %
% ---------                                                                           %   
% frequencies=GreenWood_function(35,22,1) -> for 22 channels                          %
% frequencies=GreenWood_function(35,22,2) -> for 43 channels                          %
%                                                                                     %
%-------------------------------------------------------------------------------------%
% Diagram: (Implant shape)                                                            %
% |Start of Implant                                                                   %
% Outside Cochlea:                                                                    %
%                  Base:[01]- 0.45mm -[02]  .... [20]   [21]   [22]___Abstand___:Apex % 
%                        |-   0.7mm  -|                                               %                                     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author:Sherif Omran                                                                 %
% University hospital of zurich                                                       %
% Part of my phd Thesis                                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Output=GreenWood_function(Cochlea_length,Insertion_depth,mode);

if Insertion_depth>25,
     disp ('Maximum Insertion Depth is 25');
end

if Cochlea_length==nan,
    Cochlea_length=35;           %  Default value of cochlea length
end




Electrode_size=0.3;                   % 0.45 mm distance between electrode edjes
spacing_between_electrodes=0.75;      % 0.75 mm mid-mid electrode spacing
                                      %electrode_number=1 for the 1st Electrode from Base
Implant_Length=25;                    % 25 mm lenth of implant
ShittenyRings=Implant_Length-Insertion_depth; %  space before the electrodes start
End_tip=0;                            % space after the 22 electrode
                                      
Space_between_apex_and_electrode   =   Cochlea_length-Insertion_depth; %ex: 10 mm


if mode==1,
       % 22 Channels
    oz=22;
elseif mode==2,
       % 43 Channels
    %spacing_between_electrodes= spacing_between_electrodes/2;  
    oz=43;
end

Output=0;

% this part has to calculate the first electrode number inside the cochlea
% after the base.
Full_Electrode_Length=((Electrode_size/2)*2+(22-1)*spacing_between_electrodes);

Outside_Cochlea  =  (Implant_Length - Insertion_depth); % Distance outside the cochlea without the rings

PositionOfTheFirstElectrodeFromBase = Insertion_depth-Full_Electrode_Length-End_tip;
if PositionOfTheFirstElectrodeFromBase<0, % The first electrode is somewhere outside the cochlea
                                          % it is required to find the first electrode inside the
                                          % cochlea
     First_electrode_inside_cochlea=ceil(-1*PositionOfTheFirstElectrodeFromBase/spacing_between_electrodes);   
else
     First_electrode_inside_cochlea=1;
end


% Implant_length can't be greater than the insertion_depth

%First_electrode_inside_cochlea=Number_of_electrode_outside_cochlea+1;   % First electrode no in the cochlea,elec=1 beside base

if mode==2,
    Output=zeros(1,43-First_electrode_inside_cochlea);
elseif mode==1,
    Output=zeros(1,22-First_electrode_inside_cochlea);
end

Counter=First_electrode_inside_cochlea;
for electrode_number=First_electrode_inside_cochlea:22

    % Get the electrode number and calculate the position in the cochlea
    % corresponds to this electrode position
    ElectrodePositionFromBase=PositionOfTheFirstElectrodeFromBase+(electrode_number-1)*(spacing_between_electrodes)+Electrode_size/2; %mid point
    place_from_apex=Cochlea_length-ElectrodePositionFromBase

    x=place_from_apex;%/Cochlea_length;     % Must not be in mm, but in ratio See [Ref1] Above
    TonoFreq=Tonotopical_Frequency(x);    % real frequency in the ear at position x
    Output(1,Counter)=TonoFreq;
    if mode==2,
        Counter=Counter+2;
    elseif mode==1,
        Counter=Counter+1;
    end
    %Output= [Output TonoFreq];
end

%Output=Output(2:end);                 % Remove the 0 padded from line 45

Counter=First_electrode_inside_cochlea+1;
if mode==2, % calculate virtual channel values, by shifting the electrodes
%    VEOutput=0;
    for electrode_number=First_electrode_inside_cochlea:22
        % Get the electrode number and calculate the position in the cochlea
        % corresponds to this electrode position but shift one Electrode distance to right because it is virual
        ElectrodePositionFromBase=PositionOfTheFirstElectrodeFromBase+(electrode_number-1)*(spacing_between_electrodes)+Electrode_size/2+Electrode_size; %same as previous but shift one electrode to right
        place_from_apex=Cochlea_length-ElectrodePositionFromBase;
        x=place_from_apex;%/Cochlea_length;     % Must not be in mm, but in ratio See [Ref1] Above
        TonoFreq=Tonotopical_Frequency(x);    % real frequency in the ear at position x
        Output(1,Counter)=TonoFreq;
        Counter=Counter+2;
%        VEOutput= [Output TonoFreq];
    end
%    VEOutput=VEOutput(2:end);                 % Remove the 0 padded from line 45


end
    



return;




function GWF=Tonotopical_Frequency(position_ratio_from_apex)
% Position_ratio_from_apex=x_from_apex(mm)/length(mm)
% GreenWood Parameters for Human
A=165.4;
a=0.06;
k=1;
%165.4*(10.^(2.1*0.1250/35)-0.88)
Tonotopical_Frequency = A * (10.^(a*position_ratio_from_apex) - k);
GWF=Tonotopical_Frequency;
return;