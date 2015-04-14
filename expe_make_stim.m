 function [xOut, fs, i_correct] = expe_make_stim(options, trial)

%--------------------------------------------------------------------------
% Etienne Gaudrain <etienne.gaudrain@mrc-cbu.cam.ac.uk>
% 2010-03-16, 2011-10-20
% Medical Research Council, Cognition and Brain Sciences Unit, UK
%--------------------------------------------------------------------------

xOut = {};

f0 = [trial.f0(1), trial.f0(1), trial.f0(2)];
ser = [trial.ser(1), trial.ser(1), trial.ser(2)];

for i=1:length(trial.syllables)
    
    sylls = trial.syllables{i};
    x = [];
    
    for j=1:length(sylls)
    
        
        sf0 = f0(i)*2^(options.f0_contour_step_size*trial.f0_contours(j)/12);
        
        [y, fs] = straight_process(sylls{j}, sf0, ser(i), options);

        if fs~=options.fs
            y = resample(y, options.fs, fs);
            fs = options.fs;
        end
        
        dl = round(options.syllable_duration*fs) - length(y);
        if dl>0
            npad_L = floor(dl/20);
            npad_R = dl-npad_L;
            nr = floor(5e-3*fs);
            y(1:nr) = y(1:nr) .* linspace(0, 1, nr)';
            y(end-nr+1:end) = y(end-nr+1:end) .* linspace(1, 0, nr)';
            y = [zeros(npad_L,1); y; zeros(npad_R,1)];
        elseif dl<0
            y = y(1:end-dl);
            nr = floor(5e-3*fs); % 1 ms linear ramp at the end
            y(end-nr+1:end) = y(end-nr+1:end) .* linspace(1, 0, nr)';
        else
            nr = floor(5e-3*fs);
            y(1:nr) = y(1:nr) .* linspace(0, 1, nr)';
            y(end-nr+1:end) = y(end-nr+1:end) .* linspace(1, 0, nr)';
        end 

        x = [x; y];

        if j~=length(sylls)
            x = [x; zeros(floor(fs*options.inter_syllable_silence), 1)];
        end
    end
    
    
    if numel(x)>0
    
        if trial.vocoder>0
            [x, fs] = vocode(x, fs, options.vocoder(trial.vocoder).parameters);
        end

        x = x(:);

        % Apply a 1 ms ramp to avoid clicking
%         nrmp = floor(fs/1000);
%         x(1:nrmp) = x(1:nrmp) .* linspace(0,1,nrmp)';
%         x(end-nrmp+1:end) = x(end-nrmp+1:end) .* linspace(1,0,nrmp)';
        
        
        %This prevents the wavwrite from clipping the data; works better
        %than snippet above:
        m = max(abs(min(x)),max(x)) + 0.001;
        x = x./m;

        switch options.ear
            case 'right'
                x  = [zeros(size(x)), x];
            case 'left'
                x = [x, zeros(size(x))];
            case 'both'
                x = repmat(x, 1, 2);
            otherwise
                error(sprintf('options.ear="%s" is not implemented', options.ear));
        end

    end
    
    xOut{i} = x;
end

i_order = randperm(length(xOut));
xOut = xOut(i_order);

i_correct = find(i_order==3);

%--------------------------------------------------------------------------
function fname = make_fname(wav, f0, ser, d, destPath)

[~, name, ext] = fileparts(wav);

if isnan(d)
    fname = sprintf('%s_GPR%d_SER%.2f', name, floor(f0), ser);
else
    fname = sprintf('%s_GPR%d_SER%.2f_D%d', name, floor(f0), ser, floor(d*1e3));
end
fname = fullfile(destPath, [fname, ext]);
    

%--------------------------------------------------------------------------
function [y, fs] = straight_process(syll, t_f0, ser, options)

wavIn = fullfile(options.sound_path, [syll, '.wav']);
wavOut = make_fname(wavIn, t_f0, ser, options.syllable_duration, options.tmp_path);

% if ~exist('audioread')
%     audioread = @wavread;
% end
% 
% if ~exist('audiowrite')
%     audiowrite = @(fname, x, fs) wavwrite(x,fs,fname);
% end

if ~exist(wavOut, 'file') || options.force_rebuild_sylls
    
    if ~is_test_machine()
        straight_path = '~/Library/Matlab/STRAIGHTV40_006b';
    else
        straight_path = '~/Library/Matlab/STRAIGHTV40_006b';
    end
    addpath(straight_path);
    
    mat = strrep(wavIn, '.wav', '.straight.mat');
    
    if exist(mat, 'file')
        load(mat);
    else
        [x, fs] = audioread(wavIn);
        [f0, ap] = exstraightsource(x, fs);
        %old_f0 = f0;
        %f0(f0<80) = 0;

        sp = exstraightspec(x, f0, fs);
        x_rms = rms(x);

        save(mat, 'fs', 'f0', 'sp', 'ap', 'x_rms');
    end
    
    mf0 = exp(mean(log(f0(f0~=0))));

    f0(f0~=0) = f0(f0~=0) / mf0 * t_f0;

    %p.timeAxisMappingTable = (d*1e3)/length(f0);
    p.frequencyAxisMappingTable = ser;
    y = exstraightsynth(f0, sp, ap, fs, p);

    y = y/rms(y)*x_rms;
    if max(abs(y))>1
        warning('Output was renormalized for "%s".', wavOut);
        y = 0.98*y/max(abs(y));
    end 
    
    audiowrite(wavOut, y, fs);
    
    rmpath(straight_path);
else
    
    
    
    [y, fs] = audioread(wavOut);
    %[y, fs] = wavread(wavOut);
end

