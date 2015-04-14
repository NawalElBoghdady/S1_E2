function [xOut, fs] = expe_make_training_stim(options, trial)

%--------------------------------------------------------------------------
% Etienne Gaudrain <etienne.gaudrain@mrc-cbu.cam.ac.uk>
% 2010-03-16, 2011-10-20
% Medical Research Council, Cognition and Brain Sciences Unit, UK
%--------------------------------------------------------------------------

xOut = cell(2,length(trial.words));
x_unvoc = cell(2,length(trial.words));

f0 = [trial.f0(1), trial.f0(2)];
ser = [trial.ser(1), trial.ser(2)];

for i=1:length(trial.words)
    
    word = trial.words{i};
    
    for j=1:2
    
        
        sf0 = f0(j); %*2^(options.f0_contour_step_size*trial.f0_contours(j)/12);
        
        [y, fs] = straight_process(word{1}, sf0, ser(j), options);

        if fs~=options.fs
            y = resample(y, options.fs, fs);
            fs = options.fs;
        end
        
        %{
        dl = round(options.word_duration*fs) - length(y);
        if dl>0
            npad_L = floor(dl/20);
            npad_R = dl-npad_L;
            nr = floor(1e-3*fs);
            y(1:nr) = y(1:nr)' .* linspace(0, 1, nr)';
            y(end-nr+1:end) = y(end-nr+1:end)' .* linspace(1, 0, nr)';
            %y needs to be a mono vector and so:
            y = y(:,1);
            y = [zeros(npad_L,1); y; zeros(npad_R,1)];
        elseif dl<0
            y = y(1:end);
            nr = floor(1e-3*fs); % 1 ms linear ramp at the end
            y(end-nr+1:end) = y(end-nr+1:end)' .* linspace(1, 0, nr)';
        else
            nr = floor(1e-3*fs);
            y(1:nr) = y(1:nr)' .* linspace(0, 1, nr)';
            y(end-nr+1:end) = y(end-nr+1:end)' .* linspace(1, 0, nr)';
        end
        %}
        
        

        x_unvoc{j,i} = y;
        
        %Vocode the words:
        if trial.vocoder>0
            [y, fs] = vocode(y, fs, options.vocoder(trial.vocoder).parameters);
        end
        
        % Apply a 1 ms ramp to avoid clicking
%         nrmp = floor(fs/1000);
%         y(1:nrmp) = y(1:nrmp) .* linspace(0,1,nrmp)';
%         y(end-nrmp+1:end) = y(end-nrmp+1:end) .* linspace(1,0,nrmp)';

        %This prevents the wavwrite from clipping the data; works better than snippet above:
        m = max(abs(min(y)),max(y)) + 0.001;
        y = y./m;

        switch options.ear
            case 'right'
                y  = [zeros(size(y)), y];
            case 'left'
                y = [x, zeros(size(y))];
            case 'both'
                y = repmat(y, 1, 2);
            otherwise
                error(sprintf('options.ear="%s" is not implemented', options.ear));
        end
        
        xOut{j,i} = y;

    end
    
end


%--------------------------------------------------------------------------
function fname = make_fname(wav, f0, ser, destPath)

[~, name, ext] = fileparts(wav);


fname = sprintf('%s_GPR%d_SER%.2f', name, floor(f0), ser);

fname = fullfile(destPath, [fname, ext]);
    

%--------------------------------------------------------------------------
function [y, fs] = straight_process(syll, t_f0, ser, options)

wavIn = fullfile(options.training_words, [syll, '.wav']);
wavOut = make_fname(wavIn, t_f0, ser, options.training_words_tmp);


if ~exist(wavOut, 'file') || options.force_rebuild_sylls
    
    if ~is_test_machine()
        straight_path = '../lib/STRAIGHTV40_006b';
    else
        straight_path = '~/Library/Matlab/STRAIGHTV40_006b';
    end
    addpath(straight_path);
    
    mat = strrep(wavIn, '.wav', '.straight.mat');
    
    if exist(mat, 'file')
        load(mat);
    else
        [x, fs] = wavread(wavIn);
        x = remove_silence(x(:,1), fs);
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
    
    wavwrite(y, fs, wavOut);
    
    rmpath(straight_path);
else
    [y, fs] = wavread(wavOut);
end

