%plot the RMS distribution for the different frequency bands for the CVs to
%be utilized:

% Base parameters
fs = 44100;
filter_order = 1;
p = struct();
p.envelope = struct();
p.envelope.method = 'low-pass';
p.envelope.rectify = 'half-wave';
p.envelope.order = 2;

p.synth = struct();
p.synth.carrier = 'noise';
p.synth.filter_before = false;
p.synth.filter_after  = true;
p.synth.f0 = 1;

p.envelope.fc = 300;

p.random_seed = 1;

nc = 16; %run for 16 chs only
elec_array = struct('type','AB-HiFocus','ins_depth',[],'tot_length',24.5,'e_width',0.4,'e_spacing',0.85,'nchs',16, 'active_length',15.5);
c_length = 35; %33 mm average cochlear length

range = [170 8700];
tables = {'greenwood','lin','ci24','hr90k'};

ins_depth = [21.5, 18.5]; %shallow = 18.5mm, %deep insertion = 21.5mm for HiFocus => data from AB surgeon's guide for HiRes90K implant

P1 = 20*10^(65/20);
P1RMS = 0.1711;
%Get all the CV filenames:
CVs = dir('/Users/nawalelboghdady/Library/Matlab/Sounds/Dutch_CV/processed/*.wav');
nCVs = length(CVs);

cv_list = cell(nCVs,1);

 for i = 1:nCVs
    cv_list{i} = CVs(i).name;
 end

for i = 1:length(ins_depth)  
    
    elec_array.ins_depth = ins_depth(i);
    x = e_loc(elec_array,c_length);
    
    
    for i_freq_table = 1:1%length(tables) %loop on the vocoder types 
        
        %define the vocoder:
        p.analysis_filters  = estfilt_shift(nc, tables{i_freq_table}, fs, range, filter_order);
        p.synthesis_filters = estfilt_shift(nc, 'greenwood', fs, x, filter_order);
        
        b = p;
        b.analysis_filters = p.synthesis_filters;

        yvoc_dbspl = zeros(nc,100);
        
        for cv = 1:100
            disp(strcat(num2str(cv),'/',num2str(nCVs)));
            [y,fs_y] = audioread(cv_list{cv});
            [y_voc,fs_yvoc] = vocode(y,fs_y,p);
            %y_voc = y_voc.*10^(-3/20);
            [y_voc_bands,~] = analyze_chs(y_voc,fs_yvoc,b);
            
            
            for n = 1:nc
                yvoc_dbspl(n,cv) = P1.*(rms(y_voc_bands(n,:)))./P1RMS;
                
            end
            
            plot(1:nc,yvoc_dbspl(:,cv),'o');
            title(strcat(num2str(ins_depth(i)),' Vocoder ',tables{i_freq_table}));
            hold on;
            
            
            
        end
        figure();
        
        
        
        
    end
    
end


%% 

%pd = fitdist(yvoc_dbspl(1,:)','Normal')
%out = pdf(pd,yvoc_dbspl(1,:)');
%plot(yvoc_dbspl(1,:)',out,'or');