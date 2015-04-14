%EFI_Flexible_V1.m

%This script is adapted from Tim Hives script RunMonoralEFI_V02e.m
%(November 2013), which contained:


% dti 2013/10/21
% RunBEFI_V02b 
% Basic BEFI task:
% Three stimuli
% (1) Dichotic 500Hz SAM tone (100% modulated at 5Hz), either 0-phase or pi-phase
% (2) 500Hz 1 ERB wide noise band 60 dB SPL/ 40dB/Hz
% (3) Monoral 4kHz SAM tone 4kHz carrier @ 65dB  modulated at 5Hz (m=varied, tracking variable)
% dti 2013/11/27
%converted to 3AFC

%The script is adapted to:
% 1) Run the target in Monoral or Binaural Presentation mode
% 2a) Have a 1 ERB wide LF noise with or without an additional 1 ERB wide HF
% noise (centered at 0.5 kHz and 4 kHz respectively)
% 2b) Or have a wideband pink noise with cutoffs at 80 Hz and 8 kHz.
% 3) Change the modulation rate of the HF and LF tone independently

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CONDITIONS CHANGED FROM LINE 62 %%%%%%%%%%%%

function outVar=runProg(varargin); %#ok<NOSEM>




%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
close all hidden;
warning off MATLAB:divideByZero


% A Preliminary decisions
% A1. Decide on presentation mode

COMPUTER                    =   0;          %used for testing
%--------------------------------------------------------------------------
%determine operation mode (opmode)
if size(varargin,2)==0
     opmode                 =   'gui';
elseif size(varargin,2)==1
   opmode                   =   'script';
else
    return
end
%--------------------------------------------------------------------------
% if run in 'script' mode then we need to specify variables:
% if run in 'gui' mode then the user will be prompted to specify variables:
switch opmode
    case 'script'
        fprintf('%s\r','Running in SCRIPT mode')
        expVar              =   varargin{1};
        if ~all(isfield(expVar,{'SubID','Modulation','feedback','SNR','NR','COM'}));
            fprintf('%s\r','expVar incomplete');return
        end
        
    case 'gui'
        fprintf('%s\r','Running in GUI mode');
    
        
  
  

 %------------------------------------------------------------------
 % A2. Preset Variables for experimental setup
 %set variables in code:
        expVar.SubID        =   'DEJ';      %name        
        expVar.condition    =   1;          %Condition: (1)-N0S0   (2)-N0Spi
        expVar.TargetEar    =   0;          %DEJ270114: Insert ear of target presentation. 0 = both, 1= left, 2 = right
        expVar.SPLLF        =   66;         %level (SPL) of LF tone.
        expVar.feedback     =   'on';       %'on' or 'off'
        
        lang                =   'E';        %E=english, F=French
        expVar.NoiseType    =   1;          % noise type: 1 = 1ERB, 2 = pink
        expVar.mDepLF       =   0;           %modulation depth LF tone is 0 dB (i.e. maximum)
    
        expVar.SPLLFNoise   =   60;         %level (SPL) of LF noise band
        expVar.SPLHFNoise   =   0;         %level (SPL) of HF noise band
       
        expVar.SPLHF        =   65;         %level (SPL) of high freq tone.      
        expVar.FmLF         =   5;          %modulation rate of LF SAM
        expVar.FmHF         =   5;          %modulation rate of HF SAM

 

   
        
        % Making some string giving an overview on selected conditions:
WhichSel                   =   sprintf('%s%s%s%01.0f%s%02.0f%s%02.0f','Lang:',...
                                lang,'_nType:',expVar.NoiseType,'_HFn:',...
                                expVar.SPLHFNoise, '_LFfm:', expVar.FmLF);

        % Changing noise in band levels:
        % Spectrum level=Band Level - 10log(noise bandwidth in Hz)
        % http://www.auditory.org/mhonarc/2011/msg00452.html
        % so, Band level= spectrum Level+10log(Noise bandwidth)
        %               = 60dB +10log(100)
        %               = 80dB





 %------------------------------------------------------------------
 % GUI - get user input data for some variables
        promptstr = {'Subject ID (abc)',...
                     'Condition: 1=N0S0, 2=N0Spi',...
                     'Target Ear: 0 = both, 1=left, 2=right',...
                     'SPL: LF',...
                     'Feedback on/off',...
                     'Other Parameters selected'};
        initstr =   {expVar.SubID,...
                      num2str(expVar.condition),...
                      num2str(expVar.TargetEar),...
                      num2str(expVar.SPLLF),...  
                      expVar.feedback, ...
                      WhichSel};
        titlestr            =   'Exp. variables';
        nlines              =   1;
        dlgresult           =   inputdlg(promptstr,titlestr,nlines,initstr,'on');
        h                   =   findobj ;
        if ~isempty(dlgresult)
            expVar.SubID    =   dlgresult{1};
            expVar.condition=   eval(dlgresult{2});
            expVar.TargetEar=   eval(dlgresult{3});
            expVar.SPLLF    =   eval(dlgresult{4});
            expVar.feedback =   dlgresult{5};
        else isempty(dlgresult) %user pressed cancel
            return
        end
end

clear promptstr dlgresult initstr titlestr h nlines
%-------------------------------------------------------------------------
%perform checks on input
if (~strcmpi(expVar.feedback,'on') && ~strcmpi(expVar.feedback,'off'))
     fprintf('%s\r','expVar.feedback must be set to ''on'' or ''off'''); return;
elseif (expVar.condition~=1) &&  (expVar.condition~=2)
     fprintf('%s\r','expVar.condition must be set to 1 or 2'); return;
end




%-------------------------------------------------------------------------
%set remaining variables:
expVar.Fs                   =   44100;      %sampling frequency
expVar.isi                  =   0.5;        %inter stimulus interval
expVar.dur                  =   0.5;        %stimulus duration
expVar.StepSizeList         =   [8 8 4 4 2 2 2 2]; %step size in dB after reversals 1-8
expVar.TermRev              =   8;          %terminate after 8 reversals
expVar.FcLF                 =   500;        %carrier freq of LF tone
expVar.FcHF                 =   4000;       %carrier freq of HF tone





%--------------------------------------------------------------------------
% store variables independently for easy insert in Output Matrix:
SPLLF                       =   expVar.SPLLF;  %Store SPL of SAM
SPLHF                       =   expVar.SPLHF;  %Store SPL of HF
SPLLFNoise                  =   expVar.SPLLFNoise;%Store SPL of LFNoise
SPLHFNoise                  =   expVar.SPLHFNoise;%Store SPL of LFNoise
TargetEar                   =   expVar.TargetEar; %store ear (0 = b, 1 = l, 2=r)
NoiseType                   =   expVar.NoiseType; %store Noise Type (1 = 1erb, 2 = pink)
FmLF                        =   expVar.FmLF;    %store fm LF
FmHF                        =   expVar.FmHF;    %store fm HF
LFmdB                       =   expVar.mDepLF;           %modulation depth LF tone
CurrCond                    =   expVar.condition; %store condition of this run
StepSize                    =   8;
Direc                       =   0;
sam                         =   1/expVar.Fs;                %1/ sampling rate - time of one frame
t                           =   (0:sam:expVar.dur-sam)';    % time of interval in sampling frames

expVar.StepSizeList         =   [8 8 4 4 2 2 2 2 0];        %step size in dB after reversals 1-8 (9)






%-------------------------------------------------------------------------
% A3. Computer directory
%check availability of directories and assign correct values
dirCODEa                    =   'D:\Experimental\34__TFS_Paradigm\29_BMLD\'; %Tim's pc
dirCODEb                    =   'C:\Users\Experimentalists\Documents\Tim\Experimental\34__TFS_Paradigm\29_BMLD\'; %petite cabine
dirCODEc                    =   'C:\Tim\Experimental\34__TFS_Paradigm\29_BMLD\'; %grande cabine
dirCODEd                    =   'C:\Documents and Settings\Equipe Audition\Bureau\Experimental\34__TFS_Paradigm\29_BMLD\'; %Equipe Audition laptop 
dirCODEe                    =   'C:\Users\Enja\Documents\MATLAB\ENS_Tim_Matlab\';%enja's laptop
dirCodef                    =   'C:\Users\Experimentalists\Documents\Enja\'; %enja's folder


if exist(dirCODEa,'dir')
    dirCODE                 =   dirCODEa;
elseif exist(dirCODEb,'dir')
    dirCODE                 =   dirCODEb;
elseif exist(dirCODEc,'dir')
    dirCODE                 =   dirCODEc;
elseif exist(dirCODEd,'dir')
    dirCODE                 =   dirCODEd;
elseif exist(dirCODEe,'dir')
    dirCODE                 =   dirCODEe;
elseif exist (dirCODEf, 'dir')
    dirCODE                 =   dirCODEf;
end

dirDATAa                    =   'D:\Experimental\34__TFS_Paradigm\29_BMLD\02_Sub_data\'; %Tim's pc
dirDATAb                    =   'C:\Users\Experimentalists\Documents\Tim\Experimental\34__TFS_Paradigm\29_BMLD\02_Sub_data\'; %booth
dirDATAc                    =   'C:\Tim\Experimental\34__TFS_Paradigm\29_BMLD\02_Sub_data\'; %grande cabine
dirDATAd                    =   'C:\Documents and Settings\Equipe Audition\Bureau\Experimental\34__TFS_Paradigm\29_BMLD\02_Sub_data\'; %Equipe Audition laptop 
dirDATAe                    =   'C:\Users\Enja\Documents\MATLAB\ENS_Tim_Matlab\02_Sub_data\'; %enjas laptop
dirDATAf                    =   'C:\Users\Experimentalists\Documents\Enja\02_Sub_data\'; %enjas folder

if exist(dirDATAa,'dir')
    dirDATA                 =   dirDATAa;
elseif exist(dirDATAb,'dir')
    dirDATA                 =   dirDATAb;
elseif exist(dirDATAc,'dir')
    dirDATA                 =   dirDATAc;
elseif exist(dirDATAd,'dir')
    dirDATA                 =   dirDATAd;
elseif exist(dirDATAe, 'dir')
    dirDATA                 =   dirDATAe;
elseif exist(dirDATAf, 'dir')
    dirDATA                 =   dirDATAf;
end
addpath (strcat(dirCODE,'gtfb\'));
clear dirCODEa dirCODEb dirCODEc dirCODEd dirDATAa dirDATAb dirDATAc dirDATAd








%-------------------------------------------------------------------------
% A4) File name

%Set ExpID depending on Condition - depending on ear presentation and noise
%type
if expVar.TargetEar == 0 & NoiseType == 1
        taskName                = 'bEFI_Cond';
        NoiseName               = '_1ERB';
    elseif expVar.TargetEar == 0 & NoiseType == 2
        taskName                = 'bEFI_Cond';
        NoiseName               = '_Pink';
    elseif expVar.TargetEar == 1 & NoiseType == 1
        taskName                = 'mlEF_Cond';
        NoiseName               = '_1ERB';
    elseif expVar.TargetEar == 1 & NoiseType == 2
        taskName                = 'mlEF_Cond';
        NoiseName               = '_Pink';
    elseif expVar.TargetEar == 2 & NoiseType == 1
        taskName                = 'mrEF_Cond';
        NoiseName               = '_1ERB';
    elseif expVar.TargetEar == 2 & NoiseType == 2
        taskName                = 'mrEF_Cond';
        NoiseName               = '_Pink';
else 
        disp('Error: TargetEar must be 0,1 or 2 OR NoiseType must be 1 or 2!')
end

%%generate runID based on SubjectID, ExpID and previous runs
expVar.ExpID                =   sprintf('%s%s',taskName,num2str(expVar.condition));
repIDX                      =   1;
runID                       =   sprintf('%s%s%s%s%02.0f%s',expVar.SubID,'_',expVar.ExpID,'_Rep',repIDX, NoiseName, '.mat');
FullOutputName              =   fullfile(dirDATA,runID);
while exist(FullOutputName,'file')
    repIDX                  =   repIDX+1;
    runID                   =   sprintf('%s%s%s%s%02.0f%s',expVar.SubID,'_',expVar.ExpID,'_Rep',repIDX, NoiseName, '.mat');
    FullOutputName          =   fullfile(dirDATA,runID);
end



%--------------------------------------------------
%USERFRIENDLINESS: Display information for summary
disp(strcat('Test = ', taskName));
disp(strcat('Condition =', num2str(expVar.condition)));
disp(strcat('Repetition =', num2str(repIDX)));
%---------------------------------------------------------



clear taskName
clear repIDX
clear NoiseName

%--------------------------------------------------------------------------
%A5) Calibration
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% Computer petit cabine ENS. With Sennheiser headphones installed in cabine.
%Level correction procedure (06/11/2013)
% With the sound card set to -20dB and a further +6dB (i.e. -14dB)
% Readings are LAF(SPL)
%------------------------------------------------
% RMS=0.05
% Now set the correct level based on the carrier frequency
% 
 expVar.Ref_500HzSin_dB      =   70.1; %tones
 expVar.Ref_4000HzSin_dB     =   77.7;
 expVar.Ref_500HzNoise_dB    =   71.7; % Noise Gammachirp
 expVar.Ref_4000HzNoise_dB   =   78.3; 
 expVar.Ref_lpNoise_dB       =   72.7; % Noise. LP filtered, CO 1000 Hz, 

% 
% % Enja's laptop with Sennheiser HD 215 headphones from upstairs. Loudness
% % set to 60% (3 clicks up)
% expVar.Ref_500HzSin_dB      =   59.1; %tones
% expVar.Ref_4000HzSin_dB     =   43.5;
% expVar.Ref_500HzNoise_dB    =   60.6; % Noise Gammachirp
% expVar.Ref_4000HzNoise_dB   =   48.8; 
% expVar.Ref_pinkNoise_dB     =   66.3; % Noise. Pink


%-------------------------------------------------------------------------
% A6) Output Matrix
%--------------------------------------------------------------------
% We'll need to construct outputMATRIX
%             
%specified as:  | col 1        | col 2             | col 3             | 
%               | TrialNo      | SPLLF             | SPLHF             | 
%               | Trial Number | LF tone intensity | HF tone intensity |
%
%               | col 4               | col 5  | col 6          | 
%               | HFmdB               | SAMint | resp           | 
%               | HF modulation depth | ?      | Response given | 
%
%               | col 7            | col 8                             | 
%               | correct          | NoCor                             | 
%               | Response correct | Number consecutive correct trials |
%
%               | col 9                           | col 10               |  
%               | NoWrg                           | Direc                | 
%               | Number consecutive wrong trials | Steps: -1 down, 1 up |
%
%               | col 11         | col 12            | col 13       |
%               | TotRev         | StepSize          | LevCh        |
%               | Reversals done | Stepsize reversal | Level change |
%
%               | col 14        | col 15           | col 16             |  
%               | TargetEar     | NoiseType        | SPLLFNoise         |  
%               | 0=b, 1=l, 2=r | 1= 1ERB, 2= pink | Intensity LF noise |
% 
%               | col 17             | col 18                  | 
%               | SPLHFNoise         | FmLF                    |
%               | Intensity HF noise | Modulation Rate LF tone |
%
%               | col 19                  | col 20                |
%               | FmHF                    | CurrCond              |
%               | Modulation Rate HF tone | Condition of this run |
%

OutputMATRIX=zeros(1,20);

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% End of preparing things
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@









%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% B Start the Experimental Procedure

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@




%--------------------------------------------------------------------------
% B1) put up gui boxes
scrsz                       =   get(0,'ScreenSize');
left=scrsz(1); bottom=scrsz(2); width=scrsz(3); height=scrsz(4);


figure('MenuBar','none','color','white','Position',[left+0*width bottom+0.005.*height width height],'Resize','off');
%figure('MenuBar','none','color','white','Position',[left+1*width bottom+0.005.*height width height],'Resize','off');
H_MainFig                   =   gcf;
set(gca,'XTick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1],'Position',[0 0 1 1]);
  
H_Rec1                      =   rectangle('Position',[0.1,0.4,0.2,0.2],'Curvature',[0.2,0.2],'FaceColor',[.95 .95 .95],'EdgeColor',[0 0 0],'linewidth',3);
H_Rec2                      =   rectangle('Position',[0.4,0.4,0.2,0.2],'Curvature',[0.2,0.2],'FaceColor',[.95 .95 .95],'EdgeColor',[0 0 0],'linewidth',3);
H_Rec3                      =   rectangle('Position',[0.7,0.4,0.2,0.2],'Curvature',[0.2,0.2],'FaceColor',[.95 .95 .95],'EdgeColor',[0 0 0],'linewidth',3);
   
H_WaitOut                   =   rectangle('Position',[0.2,0.1,0.6,0.03],'Curvature',[0.0,0.0],'FaceColor',[1 1 1],'EdgeColor',[0 0 0],'linewidth',2);
H_WaitIn                    =   rectangle('Position',[0.2,0.1,0.001,0.03],'Curvature',[0.0,0.0],'FaceColor',[0 0 0],'EdgeColor',[0 0 0],'linewidth',1);

if strcmpi(lang,'E')
    H_WaitText              =   text(0.5,0.16,'Progress...','FontName','Helvetica','FontSize',25,'FontWeight','normal','HorizontalAlignment','Center');
else
    H_WaitText              =   text(0.5,0.16,'en cours...','FontName','Helvetica','FontSize',25,'FontWeight','normal','HorizontalAlignment','Center');
end

if strcmpi(lang,'E')
    H_InstText              =   text(0.5,0.8,'Please wait...','FontName','Helvetica','FontSize',40,'FontWeight','bold','HorizontalAlignment','Center');
else
    H_InstText              =   text(0.5,0.8,'Attendez, s''il vous plait...','FontName','Helvetica','FontSize',40,'FontWeight','bold','HorizontalAlignment','Center');
end






%-------------------------------------------------------------------------
% B2) Set up starting screen

new_dir                     =   'down';   %direction set to 'down' i.e. task starts by getting harder
pause(0.5);

if strcmpi(lang,'E')
 set(H_InstText,'string','Press any key to start...');
else
    set(H_InstText,'string','Appuyer sur une touche pour commencer...');
end
ww                          =   waitforbuttonpress;
pause(1.0);




%-------------------------------------------------------------------------
% B3)start trials. Start running. we will now run eight reversals. 

% define variebles looped during trials
trialNo                     =   0;
NoCor                       =   0;
NoWrg                       =   0;
TotRev                      =   0;
NumOM                       =   0;          %number of times over-modulation has been requested


%Start loop of trials
while TotRev<8
    trialNo                 =   trialNo+1;
    OutputMATRIX(trialNo,1) =   trialNo;%Store trial number
   
    
    if trialNo==1  %special case
        HFmdB               =   0;          %HF modulation depth, varies as tracking threshold.
        OutputMATRIX(trialNo,12)=StepSize;
        TotRev              =   0;
    else
        StepSize            =   expVar.StepSizeList(TotRev+1);
        LevCh               =   Direc.*StepSize;
        HFmdB               =   HFmdB+LevCh; %level (SPL) of SAM tone
        OutputMATRIX(trialNo,12)=StepSize;  % store Stepsize of change
        OutputMATRIX(trialNo,13)=LevCh;     % store total level change
    end
OutputMATRIX(trialNo,2)     = SPLLF;        %Store SPL of LF
OutputMATRIX(trialNo,3)     = SPLHF;        %Store SPL of HF
OutputMATRIX(trialNo,4)     = HFmdB;        %HF modulation depth,





%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% B4) Generate tones
  


    %   ------------------------------------------------------------------
    %   B4.1) Generate Low freq SAM tone

    LFm                     =   10.^(LFmdB/20);
    switch expVar.condition
        case 1 %N0S0
            LF(:,1)         =   (1+LFm.*sin(2.*pi.*expVar.FmLF.*t  +0) )...   %LEFT  -modulator
                                .* ( sin(2.*pi.*expVar.FcLF.*t+0) );     %LEFT  -carrier            
            LF(:,2)         =   (1+LFm.*sin(2.*pi.*expVar.FmLF.*t  +0) )...   %RIGHT -modulator
                                .* ( sin(2.*pi.*expVar.FcLF.*t+0) );     %RIGHT -carrier
            
        case 2 %N0Spi
            LF(:,1)         =   (1+LFm.*sin(2.*pi.*expVar.FmLF.*t  +0 ) )...   %LEFT  -modulator
                                 .* ( sin(2.*pi.*expVar.FcLF.*t+0 ) );     %LEFT  -carrier            
            LF(:,2)         =   (1+LFm.*sin(2.*pi.*expVar.FmLF.*t  +0 ) )...   %RIGHT -modulator
                                 .* ( sin(2.*pi.*expVar.FcLF.*t+pi) );     %RIGHT -carrier
    end


%   ------------------------------------------------------------------
%   B4.2) High freq tones
    
    
   %check for over-modulation
    if HFmdB>0
        NumOM               =   NumOM+1;
        HFmdB               =   0;
        if NumOM>1  %set to exit if over-modulation is requested twice
            delete(H_MainFig);
            disp('Run terminated: OVER-MODULATION');
            return;
        else
        end
    else
        %do nothing
    end
    
    
    
    % Generate HF tones
    if TargetEar == 0           % binaural presentation
        %   1. First the HF modulated one
        HFm                     = 10.^(HFmdB/20);
        HFmod(:,1)              = (1+HFm.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %LEFT  -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t+      0) );     %LEFT  -carrier
        HFmod(:,2)              = (1+HFm.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %RIGHT -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t+      0) );     %RIGHT -carrier 
        %   2. Second the un-modulated one
        HFunmod(:,1)            = (1+0.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %LEFT  -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t+      0) );     %LEFT  -carrier
        HFunmod(:,2)            = (1+0.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %RIGHT -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t      +0) );     %RIGHT -carrier   
                            
    elseif TargetEar == 2 %in case we want to only do the right ear (expVar.TargetEar = 2)
        %   1. First the HF modulated one
        HFm                     =   10.^(HFmdB/20);
        HFmod(:,1)              =   0.*t;         %LEFT  -silent
        HFmod(:,2)              =   (1+HFm.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %RIGHT -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t+      0) );     %RIGHT -carrier
       %   2. Second the un-modulated one
        HFunmod(:,1)            =   0.*t;         %LEFT  -silent
        HFunmod(:,2)            =   (1+0.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %RIGHT -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t      +0) );     %RIGHT -carrier     
             
    elseif TargetEar == 1 %in case we want to only do the left ear (expVar.TargetEar = 1)
        %   1. First the HF modulated one
        HFm                 =   10.^(HFmdB/20);
        HFmod(:,1)              =   (1+HFm.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %LEFT  -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t+      0) );     %LEFT  -carrier
        HFmod(:,2)              =   0.*t;        %RIGHT -silent
    
        %   2. Second the un-modulated one
        HFunmod(:,1)            = (1+0.*sin(2.*pi.*expVar.FmHF.*t  +(pi./2)) )...   %LEFT  -modulator
                                .* ( sin(2.*pi.*expVar.FcHF.*t+      0) );     %LEFT  -carrier
        HFunmod(:,2)            = 0.*t;                       %RIGHT -silent    
       
    else
            disp('Error: TargetEar must be 0, 1 or 2!')
    end
    
    
    
%   ------------------------------------------------------------------
%   B4.3) Noises


% 1 ERB wide noises
if expVar.NoiseType == 1

    %Low freq Noise 
    randn('state', sum(100*clock));         %reset noise seed
    NSL                     =   randn(expVar.Fs*expVar.dur,1); % noise.
    gtH                     =   GammaChirp(expVar.FcLF,expVar.Fs,4,1.019,0,0,[],'peak');
    NSL                     =   fftfilt(gtH,NSL); %pass signal through filter
    NSL                     =   [NSL, NSL];

    %   Generate HF Noise
    randn('state', sum(100*clock));         %reset noise seed
    NSH                     =   randn(expVar.Fs*expVar.dur,1); % noise.
    gtH                     =   GammaChirp(expVar.FcHF,expVar.Fs,4,1,0,0,[],'peak');
    NSH                     =   fftfilt(gtH,NSH); %pass signal through filter
    NSH                     =   [NSH, NSH]; 
 
%LP filtered noise, CO: 1000 Hz, 2nd order (12 dB/Octave)
elseif expVar.NoiseType == 2
    randn('state', sum(100*clock));         %reset noise seed
    NSL                     =   randn(expVar.Fs*expVar.dur,1); % noise.
    [butFiltA, butFiltB]    =   butter(2, 1000*2/expVar.Fs); %butterworth LP filter, CO: 1000 Hz, 2nd order (12 dB/Oct)
    NSL                     =   filter(butFiltA, butFiltB, NSL);
    NSL                     =   [NSL, NSL];
    
    NSH                     =   zeros(length(t),2);
    
end
    
    
    
    
 %-----------------------------------------------------------------------
 % B5) Levels and RMS

 
 %   B5.1) Set levels. Set to rms=0.05 (Ref_dB level)

   % Binaural ears
   if TargetEar == 0
        HFmod                   =   HFmod *max((0.05./(mean(HFmod .^2)).^0.5));
        HFunmod                 =   HFunmod *max((0.05./(mean(HFunmod .^2)).^0.5));
   
    %Levels in monaural depend on ear.
   elseif TargetEar == 2 %right ear
        HFmod(:,2)              =   HFmod(:,2) *max((0.05./(mean(HFmod(:,2) .^2)).^0.5));
        HFunmod(:,2)            =   HFunmod(:,2) *max((0.05./(mean(HFunmod(:,2) .^2)).^0.5));
    elseif TargetEar ==1 %left ear
        HFmod(:,1)              =   HFmod(:,1) *max((0.05./(mean(HFmod(:,1) .^2)).^0.5));
        HFunmod(:,1)            =   HFunmod(:,1) *max((0.05./(mean(HFunmod(:,1) .^2)).^0.5));
   end
   
        LF                      =   LF*max((0.05./(mean(LF.^2)).^0.5));
        NSL                     =   NSL *max((0.05./(mean(NSL .^2)).^0.5));
        NSH                     =   NSH *max((0.05./(mean(NSH .^2)).^0.5));  
        
        
        
 %   B5.2) Calculate gain
    gainLF                  =   SPLLF   - expVar.Ref_500HzSin_dB;
    gainHFmod               =   SPLHF   - expVar.Ref_4000HzSin_dB;
    gainHFunmod             =   SPLHF   - expVar.Ref_4000HzSin_dB;
    gainHFNoise             =   SPLHFNoise - expVar.Ref_4000HzNoise_dB;  
    if expVar.NoiseType == 1 % if we want 1 erb wide noise
        gainLFNoise         =   SPLLFNoise - expVar.Ref_500HzNoise_dB;
    elseif expVar.NoiseType ==2 % if we want pink noise
        gainLFNoise         =   SPLLFNoise - expVar.Ref_lpNoise_dB;
    else 
    end
    
    
%   B5.3) Apply gain
    LF                      =   LF      .*10.^(gainLF/20);
    HFmod                   =   HFmod   .*10.^(gainHFmod/20);
    HFunmod                 =   HFunmod .*10.^(gainHFunmod/20);
    NSH                     =   NSH      .*10.^(gainHFNoise/20);   
    NSL                     =   NSL      .*10.^(gainLFNoise/20);
        
%   B5.4) Possibly apply intensity correction
     corrLF                 =   (1+(LFm.^2)/2).^0.5;
     corrHF                 =   (1+(HFm.^2)/2).^0.5;

     
     
  %-------------------------------------------------------------------
  %B5.5) zero out stuff in case it is db SPL == 0  
  
        if expVar.SPLLF        ==   0 % LF tone
        LF                     =   zeros(length(t),2);     
        end
        if expVar.SPLHF        ==   0 % HF tone
        HFmod                   =   zeros(length(t),2);
        HFunmod                 =   zeros(length(t),2);        
        end
        if expVar.SPLLFNoise   ==   0 % LF noise/ pink noise
        NSL                     = zeros(length(t),2);  
        end
        if expVar.SPLHFNoise   ==   0 % HF noise
        NSH                    = zeros(length(t),2);
        end
  
     
 %-----------------------------------------------------------------------
 % B6)   Construct the two intervals (1)with SAM, (2) without SAM

 
    INTwithSAM              =   NSL+NSH+LF+HFmod;
    INTwithoutSAM           =   NSL+NSH+LF+HFunmod;
    
    %   Apply a 50ms onset and offset ramp to INTwithSAM
    [INTwithSAM(:,1),dummy] =   EnvV02a(0.05,0.05,INTwithSAM(:,1),    expVar.Fs);
    [INTwithSAM(:,2),dummy] =   EnvV02a(0.05,0.05,INTwithSAM(:,2),    expVar.Fs);
    
    %   Apply a 50ms onset and offset ramp to INTwithoutSAM
    [INTwithoutSAM(:,1),dummy] =EnvV02a(0.05,0.05,INTwithoutSAM(:,1), expVar.Fs);
    [INTwithoutSAM(:,2),dummy] =EnvV02a(0.05,0.05,INTwithoutSAM(:,2), expVar.Fs);
    
    %   Add 50ms to the end of the sound (sound card truncating sound)
    silence                 =   zeros(round(0.05.*expVar.Fs),2);
    INTwithSAM              =   [INTwithSAM;    silence];
    INTwithoutSAM           =   [INTwithoutSAM; silence];
    
    %   Assign to SigOut
    SigOut(:,:,1)           =   INTwithSAM;
    SigOut(:,:,2)           =   INTwithoutSAM;
    SigOut(:,:,3)           =   INTwithoutSAM;
    
    
    
%-----------------------------------------------------------------------
 % B7) Randomise order of intervals and save correct response
 
    indexRAND               =   [randperm(3)];
    expVar.indexRAND        =   indexRAND;
        if indexRAND(1) ==1
             corrRespo      =   1;
            else if indexRAND(2) == 1
            corrRespo       =   2;
            else if indexRAND(3) ==1
            corrRespo       =   3;
                end
                end
        end
    OutputMATRIX(trialNo,5) =   corrRespo;  %Interval containing SAM
    
    
    
    
    
    
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%  B8) PLAY the three intervals
%   ------------------------------------------------------------------- 


   if COMPUTER~=1
     if strcmpi(lang,'E')
            set(H_InstText,'string','Listen');
        else
            set(H_InstText,'string','Ecoutez');
        end
    set(H_Rec1,'FaceColor',[.9 .9 .1]); drawnow;
    wavplay([SigOut(:,1,indexRAND(1)) , SigOut(:,2,indexRAND(1))],expVar.Fs); 
    set(H_Rec1,'FaceColor',[.95 .95 .95]); drawnow;
    pause(expVar.isi);
    set(H_Rec2,'FaceColor',[.9 .9 .1]); drawnow;
    wavplay([SigOut(:,1,indexRAND(2)) , SigOut(:,2,indexRAND(2))],expVar.Fs);
    set(H_Rec2,'FaceColor',[.95 .95 .95]); drawnow;
    pause(expVar.isi);
    set(H_Rec3,'FaceColor',[.9 .9 .1]); drawnow;
    wavplay([SigOut(:,1,indexRAND(3)) , SigOut(:,2,indexRAND(3))],expVar.Fs);
    set(H_Rec3,'FaceColor',[.95 .95 .95]); drawnow;
    else end    
    
    
    
    
    
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%  B8) Get response and Interpret
%   ------------------------------------------------------------------- 
         if strcmpi(lang,'E')
            set(H_InstText,'string','Which sound is different (1), (2) or (3)');
        else
            set(H_InstText,'string','Quel son est different (1), (2) or (3)');
         end
         
         
         
         
         % B8.1) Start the timer
    tic;
    if COMPUTER==1
        responseLIST        =   [1 2 2 2 2];
        choice              =   randperm(size(responseLIST,2)); choice=choice(1);
        response            =   responseLIST(choice);
        max(max(SigOut));
    else
        keepwaiting         =   1;
        while keepwaiting==1;
            k               =   waitforbuttonpress;
            %             bt_res=get(H_MainFig,'CurrentCharacter');
            response=str2num(get(H_MainFig,'CurrentCharacter'));
            if response==1 || response==2 || response==3
                keepwaiting =   0;
            else
                keepwaiting =   1;
            end
        end
    end
    %------------
    respTime                =   toc;
    set(H_InstText,'string',' ')
    expVar.response         =   response;
    expVar.respTime         =   respTime;
    OutputMATRIX(trialNo,6) =   response;   %response (1 or 2)
    clear respTime;
    
    
%-------------------------------------------------------------------------
% B8.2) indicate to user which button they pressed
if response==1
    set(H_Rec1,'FaceColor',[.3 .3 .3]);drawnow;
    pause(0.2);
    set(H_Rec1,'FaceColor',[.95 .95 .95]); drawnow;
    pause(0.2);
elseif response==2
    set(H_Rec2,'FaceColor',[.3 .3 .3]);drawnow;
    pause(0.2);
    set(H_Rec2,'FaceColor',[.95 .95 .95]); drawnow;
    pause(0.2);
elseif response==3
    set(H_Rec3,'FaceColor',[.3 .3 .3]);drawnow;
    pause(0.2);
    set(H_Rec3,'FaceColor',[.95 .95 .95]); drawnow;
    pause(0.2);
else
    warndlg('Unknown response');
    return
end



%-------------------------------------------------------------------------
% B8.3) interpret response and store in Output MATRIX
if corrRespo==response
    correct                 =   1;      %correct
else
    correct                 =   0;      %incorrect
end
OutputMATRIX(trialNo,7)=correct;



%-------------------------------------------------------------------------
% B8.4) feedback if required
if COMPUTER~=1
    if strcmpi(expVar.feedback,'on')
        pause(0.3);
        if OutputMATRIX(trialNo,7)==1  %correct
            set(H_Rec1,'FaceColor',[.2 .8 .2]); set(H_Rec2,'FaceColor',[.2 .8 .2]);  set(H_Rec3,'FaceColor',[.2 .8 .2]); drawnow;
            pause(0.5);
            set(H_Rec1,'FaceColor',[.95 .95 .95]); set(H_Rec2,'FaceColor',[.95 .95 .95]);  set(H_Rec3,'FaceColor',[.95 .95 .95]); drawnow;
            pause(0.2);
        elseif OutputMATRIX(trialNo,7)==0  %incorrect
            set(H_Rec1,'FaceColor',[.8 .2 .2]); set(H_Rec2,'FaceColor',[.8 .2 .2]);  set(H_Rec3,'FaceColor',[.8 .2 .2]); drawnow;
            pause(0.5);
            set(H_Rec1,'FaceColor',[.95 .95 .95]); set(H_Rec2,'FaceColor',[.95 .95 .95]);  set(H_Rec3,'FaceColor',[.95 .95 .95]); drawnow;
            pause(0.2);
        end
    else
    end
else end




%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%  B9) store other useful variables about the run
%   ------------------------------------------------------------------- 


%----------------------------------------------------------------------
% B9.1) General parameters

OutputMATRIX(trialNo,14)    = TargetEar;        %0 = binaural presentation; 1 =target in left ear; 2 = right ear
OutputMATRIX(trialNo,15)    = NoiseType;        % 1 = 1ERB wide gammachirp; 2 = wideband pink noise
OutputMATRIX(trialNo,16)    = SPLLFNoise;       % Intensity LF noise
OutputMATRIX(trialNo,17)    = SPLHFNoise;       % Intensity HF noise
OutputMATRIX(trialNo,18)    = FmLF;             % Modulation rate LF tone
OutputMATRIX(trialNo,19)    = FmHF;             % Modulation rate HF tone
OutputMATRIX(trialNo,20)    = CurrCond;         % Condition used in run


%%----------------------------------------------------------------------
% B9.2) -- Store parameters for CURRENT trial --
% (1) NoCor & NoWrg
if correct==1          %% >>CORRECT<<
        NoCor               =   NoCor+1;    %number correct increases by 1
        NoWrg               =   0;          %set number wrong to 0
elseif correct==0      %   >>WRONG<<
        NoCor               =   0;          %number correct set to zero
        NoWrg               =   NoWrg+1;    %number wrong increases by one
end
OutputMATRIX(trialNo,8)     =   NoCor;
OutputMATRIX(trialNo,9)     =   NoWrg; 

%——————————————————————————————————————————————

if NoCor==2                                 %2 correct answers
    Direc                   =   -1;
    NoCor                   =   0;
    old_dir                 =   new_dir;    % store previous direction
    new_dir                 =   'down';     % assign new direction as down
    if ~strcmp(old_dir,new_dir)
        TotRev              =   TotRev+1;
    else
    end
       
elseif NoWrg==1                             %1 incorrect answer
    Direc                   =   1;
    NoWrg                   =   0;
    old_dir=new_dir;                        % store previous direction
    new_dir                 =   'up';       % assign new direction as up    
    if ~strcmp(old_dir,new_dir)
        TotRev              =   TotRev+1;
    else
    end
else
    Direc                   =   0;
    
end
OutputMATRIX(trialNo,10)    =   Direc;
OutputMATRIX(trialNo,11)    =   TotRev;
set(H_WaitIn,'Position',[0.2,0.1, (max(TotRev,0.001)./8).*0.6 ,0.03]);%Progressbar


allVar.expVar(trialNo)      =   expVar;



%-------------------------------------------------------------------------
%B9.3) temporarily save some useful variables after each trial 
[a b c]                     =   fileparts(FullOutputName);
b                           =   sprintf('%s%s',b,'TEMP.mat');
FullOutputNameTEMP          =   fullfile(a,b);
save(FullOutputNameTEMP,'allVar','OutputMATRIX');



%-------------------------------------------------------------------------
%wait before next trial
if COMPUTER~=1 pause(0.100); else end



end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% End of trial looping
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@





%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% C) Save data
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


%-------------------------------------------------------------------------
%C.1) quick output score
%mean of the final four reversal levels, (i.e. reversals 5,6,7,8)
TrRv5                       =   min(find(OutputMATRIX(:,11)==5))+1; %trialNo for 5th reversal
RES.Thres                   =   mean(OutputMATRIX(TrRv5:end,4));
RES.STD                     =   std(OutputMATRIX(TrRv5:end,4));


%-------------------------------------------------------------------------
% C.2) save full results
save(FullOutputName,'allVar','OutputMATRIX','RES');




%--------------------------------------------------
%USERFRIENDLINESS: display mean, sd and lf intensity for easier overview
disp(strcat('Mean =', num2str(RES.Thres)));
disp(strcat('sd =', num2str(RES.STD)));
disp(strcat('LF intensity =', num2str(SPLLF)));
%----------------------------------------------------



%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% Clean up
%-------------------------------------------------------------------------
%delete temporary file
delete(FullOutputNameTEMP);
if strcmpi(lang,'E')
    set(H_InstText,'string','Press any key to exit...');
else
    set(H_InstText,'string','Merci, tapez sur une touche pour terminer...');
end

 ww                         =   waitforbuttonpress;
delete(H_MainFig);

outVar.successful           =   'yes';







return
















