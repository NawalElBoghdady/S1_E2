function [expe, options] = expe_build_conditions_freq_tables(options)

%--------------------------------------------------------------------------
% Code modified on 20.11.14 by Nawal for the Frequency Allocation Tables
% Experiment
% Etienne Gaudrain <etienne.gaudrain@mrc-cbu.cam.ac.uk>
% 2010-03-15, 2011-10-20
% Medical Research Council, Cognition and Brain Sciences Unit, UK
%--------------------------------------------------------------------------


options.instructions.training = ['You are going to hear three triplets of different syllables.\nOne of the triplets is said with a different voice.\n'...
    'Your task is to click on the button that corresponds to the different voice.\n\n'...
    '-------------------------------------------------\n\n'...
    ''];

options.instructions.test = options.instructions.training;

test_machine = is_test_machine();

%----------- Signal options
options.fs = 44100;
if test_machine
    options.attenuation_dB = 3; % General attenuation
else
    options.attenuation_dB = 3; % General attenuation
end
options.ear = 'both'; % right, left or both

%----------- Design specification
options.test.n_repeat = 2; % Number of repetition per condition
options.test.step_size_modifier = 1/sqrt(2);
options.test.change_step_size_condition = 2; % When difference leq than this times step-size, decrease step-size
options.test.change_step_size_n_trials = 15; % Change step-size every...
options.test.initial_step_size  = 4;%2; % Semitones.
options.test.starting_difference = 12; % Semitones
options.test.down_up = [2, 1]; % 2-down, 1-up => 70.7%
options.test.terminate_on_nturns = 8;
options.test.terminate_on_ntrials = 150;
options.test.retry = 1; % Number of retry if measure failed
options.test.threshold_on_last_n_trials = 6;
%for the training words at the beginning of each run.
options.test.word_difference = 12; %Always have a 12 semitone difference between the reference and target words.

options.training.n_repeat = 2; %1;
options.training.step_size_modifier = 1/sqrt(2);
options.training.change_step_size_condition = 2; % When difference <= this, decrease step-size
options.training.change_step_size_n_trials = 15; % Change step-size every...
options.training.initial_step_size  = 4; % Semitones.
options.training.starting_difference = 12; % Semitones
options.training.down_up = [2, 1]; % 2-down, 1-up => 70.7%
options.training.terminate_on_nturns = 6;
options.training.terminate_on_ntrials = 6;
options.training.retry = 0; % Number of retry if measure failed
options.training.threshold_on_last_n_trials = 6;



%----------- Stimuli options
options.test.f0s  = [242, 121, round(242*2^(5/12))]; % 242 = average pitch of original female voice
options.test.sers = [1, 2^(-3.8/12), 2^(5/12)];

options.test.voices(1).label = 'female';
options.test.voices(1).f0 = 242;
options.test.voices(1).ser = 1;

options.test.voices(2).label = 'male';
options.test.voices(2).f0 = 121;
options.test.voices(2).ser = 2^(-3.8/12);

options.test.voices(3).label = 'child';
options.test.voices(3).f0 = round(242*2^(5/12));
options.test.voices(3).ser = 2^(7/12);

options.test.voices(4).label = 'male-gpr';
options.test.voices(4).f0 = 121;
options.test.voices(4).ser = 1;

options.test.voices(5).label = 'male-vtl';
options.test.voices(5).f0 = options.test.voices(1).f0;
options.test.voices(5).ser = 2^(-3.8/12);

options.test.voices(6).label = 'child-gpr';
options.test.voices(6).f0 = round(242*2^(5/12));
options.test.voices(6).ser = 1;

options.test.voices(7).label = 'child-vtl';
options.test.voices(7).f0 = options.test.voices(1).f0;
options.test.voices(7).ser = 2^(7/12);

options.training.voices = options.test.voices;

%--- Voice pairs
% [ref_voice, dir_voice]
options.test.voice_pairs = [...
%    1 2;  % Female -> Male
%    1 4;  % Female -> Male GPR
    1 5];  % Female -> Male VTL
%    1 3;  % Female -> Child
%    1 6;  % Female -> Child GPR
%    1 7]; % Female -> Child VTL
options.training.voice_pairs = [...
    1 5];  % Female -> Male VTL
%    1 7]; % Female -> Child VTL

% if ~test_machine %If it's computer in Stille Kamer
%     options.sound_path = '~/projects/00 stimuli/Dutch_CV/equalized';
%     options.tmp_path   = '~/projects/00 stimuli/Dutch_CV/processed';
%     options.training_words = '~/projects/00 stimuli/NVA/equalized';
%     options.training_words_tmp   = '~/projects/00 stimuli/NVA/processed';

if test_machine %If it's computer in Tinnitus Room
    disp('-------------------------');
    disp('--- In Tinnitus Room ---');
    disp('-------------------------');
    options.sound_path = '/Users/denizbaskent/Sounds/Dutch_CV/equalized';
    options.tmp_path   = '/Users/denizbaskent/Sounds/Dutch_CV/processed';
    options.training_words = '/Users/denizbaskent/Sounds/NVA/equalized';
    options.training_words_tmp   = '/Users/denizbaskent/Sounds/NVA/processed';
    
else %If it's experimenter's OWN computer:
    disp('-------------------------');
    disp('--- On coding machine ---');
    disp('-------------------------');
    options.sound_path = '~/Library/Matlab/Sounds/Dutch_CV/equalized';
    options.tmp_path   = '~/Library/Matlab/Sounds/Dutch_CV/processed';
    options.training_words = '~/Library/Matlab/Sounds/NVA/equalized';
    options.training_words_tmp   = '~/Library/Matlab/Sounds/NVA/processed';
end

if ~exist(options.tmp_path, 'dir')
    mkdir(options.tmp_path);
end

if ~exist(options.training_words_tmp, 'dir')
    mkdir(options.training_words_tmp);
end

dir_waves = dir([options.sound_path, '/*.wav']);
syllable_list = {dir_waves.name};
for i= 1:length(syllable_list)
    syllable_list{i} = strrep(syllable_list{i}, '.wav', '');
end

dir_words = dir([options.training_words, '/*.wav']);
word_list = {};
for i = 1:length(dir_words)
    switch dir_words(i).name
        case '00 Spraakruis.wav'
            continue
        otherwise
            word_list{end+1} = strrep(dir_words(i).name, '.wav', '');
    end
end

options.syllables = syllable_list;
options.n_syll = 3;

options.words = word_list;
options.n_words = 1;

options.inter_syllable_silence = 50e-3;
options.syllable_duration = 200e-3;

options.word_duration = 500e-3;

options.f0_contour_step_size = 1/3; % semitones
options.f0_contours = [[-1 0 +1]; [+1 0 -1]; [-1 1 -1]+1/3; [1 -1 1]-1/3; [-1 -1 1]+1/3; [1 1 -1]-1/3; [-1 1 1]-1/3; [1 -1 -1]+1/3];

options.inter_triplet_interval = 250e-3;

options.inter_word_interval = 250e-3;

options.force_rebuild_sylls = 0;

%--- Vocoder options

%addpath('./vocoder_2013');

% Base parameters
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

%p.random_seed = 1;

%--

%Modifications made by Nawal--20.11.2014-- for test experiment
%---------------------------------------------------------------

%The code for my frequency alloc tables goes in this block:
%Should add an extra loop for testing the different freq alloc tables

vi = 1; %vocoder index (how many vocoder instances u are simulating)
vo = 1; %butterworth filter order fixed to 4th order.

nc = 16; %run for 16 chs only
elec_array = struct('type','AB-HiFocus','ins_depth',[],'tot_length',24.5,'e_width',0.4,'e_spacing',0.85,'nchs',16, 'active_length',15.5);
c_length = 35; %33 mm average cochlear length

range = [170 8700];
%tables = {'greenwood','lin','ci24','hr90k'};
%Train on only one FAT:
%===============================
tables = {'hr90k'};

%ins_depth = [21.5, 18.5]; %shallow = 18.5mm, %deep insertion = 21.5mm for HiFocus => data from AB surgeon's guide for HiRes90K implant
%Train on only one vocoder type:
%===============================
ins_depth = 21.5;

for i = 1:length(ins_depth)  
    
    elec_array.ins_depth = ins_depth(i);
    x = e_loc(elec_array,c_length);
    
    
    for i_freq_table = 1:length(tables) %loop on the type of frequency tables 

        p.analysis_filters  = estfilt_shift(nc, tables{i_freq_table}, options.fs, range, vo);
        p.synthesis_filters = estfilt_shift(nc, 'greenwood', options.fs, x, vo);

        options.vocoder(vi).label = sprintf('n-%dch-%dord-%gmm', nc, 4*vo, ins_depth(i));
        options.vocoder(vi).description = sprintf('Noise-band vocoder, type %s ,%i bands from %d to %d Hz, insertion depth %g mm, order %i, %i Hz envelope cutoff.',...
            tables{i_freq_table}, nc, range(1),range(2) ,ins_depth(i), 4*vo, p.envelope.fc);
        options.vocoder(vi).parameters = p;

        vi = vi +1;
    end
end


%==================================================== Build test block

test = struct();


for ir = 1:options.test.n_repeat
    baseline = 1;
    
    for i = 1:14 %Equate total number of sessions to that of those used in the actual FAT experiment
        for i_voc = 1:length(options.vocoder)
            for i_vp = 1:size(options.test.voice_pairs, 1)
                
                condition = struct();

                condition.ref_voice = options.test.voice_pairs(i_vp, 1);
                condition.dir_voice = options.test.voice_pairs(i_vp, 2);           

                condition.vocoder = i_voc;

                condition.visual_feedback = 1;

                % Do not remove these lines
                %condition.i_repeat = ir;
                condition.session = ir;
                condition.done = 0;
                condition.attempts = 0;
                condition.baseline = baseline;

                if ~isfield(test,'conditions')
                    if baseline == 1
                    
                        
                        test.conditions = orderfields(condition);
                        test.conditions(end+1) = orderfields(condition);
                        %test.conditions(end+1) = orderfields(condition);
                        
                        baseline = 0;
                        condition.baseline = baseline;
                        
                        test.conditions(end+1) = orderfields(condition);
                    else
                        test.conditions = orderfields(condition);
                    end
                else
                    if baseline == 1
                    
                        test.conditions(end+1) = orderfields(condition);
                        test.conditions(end+1) = orderfields(condition);
                        %test.conditions(end+1) = orderfields(condition);
                        
                        baseline = 0;
                        condition.baseline = 0;
                        test.conditions(end+1) = orderfields(condition);
                    else
                         test.conditions(end+1) = orderfields(condition);
                    end
                   
                    
                end
                
                

            end
        end
    end
end

% Randomization of the order
%options.n_blocks = length(test.conditions)/options.test.block_size;
%test.conditions = test.conditions(randperm(length(test.conditions)));

%================================================== Build training block

training = struct();

for ir = 1:options.training.n_repeat
    for i_voc = [1,5]
        for i_vp = 1:size(options.training.voice_pairs, 1)
        
            condition = struct();

            condition.ref_voice = options.training.voice_pairs(i_vp, 1);
            condition.dir_voice = options.training.voice_pairs(i_vp, 2);           

            condition.vocoder = i_voc;

            condition.visual_feedback = 1;

            % Do not remove these lines
            condition.i_repeat = ir;
            condition.done = 0;
            condition.attempts = 0;

            if ~isfield(training,'conditions')
                training.conditions = orderfields(condition);
            else
                training.conditions(end+1) = orderfields(condition);
            end
            
        end
    end
end


% Randomization of the order
%options.n_blocks = length(training.conditions)/options.training.block_size;
training.conditions = training.conditions(randperm(length(training.conditions)));

%====================================== Create the expe structure and save

expe.test = test;
expe.training = training;

%--
                
if isfield(options, 'res_filename')
    save(options.res_filename, 'options', 'expe');
    
else
    warning('The test file was not saved: no filename provided.');
end



