function [player, x, fs] = calibrate(voc, voice)


%load calibration matrices:
calib_mat_dir = '/Users/denizbaskent/Experiments/Nawal/FATs-Exp2/calibration mats/';

vocoder_path = '/Users/denizbaskent/Library/Matlab/vocoder_2015';
addpath(vocoder_path);

%load(strcat(calib_mat_dir,'options'));
[~, options] = expe_build_conditions_freq_tables();
%load(strcat(calib_mat_dir,'trial_d.mat'));
%load(strcat(calib_mat_dir,'trial_sh.mat'));

%trial = trial_d;
%trial{2} = trial_sh;
trial = struct();

trial.ref_voice = 1;
trial.syllables = { options.syllables , {}, {} };

tic();
     
trial.dir_voice = voice;
trial.vocoder = voc;

if trial.dir_voice ~= trial.ref_voice
% Prepare unitary vector for this voice direction
    u_f0  = 12*log2(options.test.voices(trial.dir_voice).f0 / options.test.voices(trial.ref_voice).f0);
    u_ser = 12*log2(options.test.voices(trial.dir_voice).ser / options.test.voices(trial.ref_voice).ser);
    u = [u_f0, u_ser];
    u = u / sqrt(sum(u.^2));

    difference = options.test.starting_difference;

    new_voice_st = difference*u;
    trial.f0 = options.test.voices(trial.ref_voice).f0 * [1, 2^(new_voice_st(1)/12)];
    trial.ser = options.test.voices(trial.ref_voice).ser * [1, 2^(new_voice_st(2)/12)];
else
    trial.f0 = [1,1]*options.test.voices(trial.ref_voice).f0;
    trial.ser = [1,1]*options.test.voices(trial.ref_voice).ser;
end

%ifc = randperm(size(options.f0_contours, 1)); 
trial.f0_contours = repmat(reshape(options.f0_contours',1,[]), 1, ceil(numel(options.f0_contours)/3));


switch voice
    case 5
        target = 'male';
    case 7
        target = 'child';
    case 1
        target = 'female';
    otherwise
        target = 'other';
end

%[xOut, fs] = calib_make_stim(options, trial);
[xOut, fs] = expe_make_stim(options, trial);
player = {};


disp('----------------');
if voc>0
    fprintf('Vocoder %s %s\n, Voice %s\n',options.vocoder(voc).label,options.vocoder(voc).parameters.analysis_filters.type,target);
else
    fprintf('No vocoder, Voice %s\n', target);
end
disp('----------------');


for i=1:length(xOut)
    if numel(xOut{i})>0
        x = xOut{i}*10^(-options.attenuation_dB/20);
        break
    end
end

player = audioplayer([zeros(1024*3, 2); x; zeros(1024*3, 2)], fs, 16);

%isi = audioplayer(zeros(floor(.005*fs), 2), fs);

%pause(.5);

% Play the stimuli
%play(player);


toc();

rmpath(vocoder_path);
    
end