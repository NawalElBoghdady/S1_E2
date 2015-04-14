

options = expe_options();
[expe, options] = expe_build_conditions(options);

options.inter_syllable_silence = 50e-3;

trial = expe.test.conditions(1);
ifc = randperm(size(options.f0_contours, 1));
trial.f0_contours = options.f0_contours(ifc(1:3), :);

isyll = [3, 14, 23]; %randperm(length(options.syllables));
%isyll = ones(1, 20); %1:length(options.syllables);

for i_int=1:3
    %trial.syllables{i_int} = options.syllables(isyll(((i_int-1)*options.n_syll+(1:options.n_syll))));
    %trial.syllables{i_int} = options.syllables(isyll(1:options.n_syll));
    trial.syllables{i_int} = options.syllables(isyll);
end

trial.f0_contours = zeros(3, length(isyll));

trial.syllables{1}

cols = 'rb';

voices = [1,5];

for i=1:2 %length(options.test.voice_pairs)

    trial.f0 = [options.test.voices(voices(i)).f0, options.test.voices(voices(i)).f0];
    trial.ser = [options.test.voices(voices(i)).ser, options.test.voices(voices(i)).ser]/i;
    
    col = cols(i);

    for j=1:length(options.vocoder)
        trial.vocoder = j;
        
        [x, fs, i_correct] = expe_make_stim(options, trial);

        s = zeros(floor(.250*fs),2);
        %wavwrite(mean([x{2}; s; x{1}; s; x{3}],2), fs, sprintf('Demo_jvo_%d_%s.wav', i, voc_suff));
        wavwrite(mean(x{i_correct},2), fs, sprintf('Demo_jvo_%s_voc%s.wav', options.test.voices(voices(i)).label, options.vocoder(j).label));
        figure(j)
        n = 1024*2;
        [S, F, T, P] = spectrogram(mean(x{i_correct},2), hann(n), floor(n*.75), n, fs);
        plot(F, 10*log10(mean(P(:,:), 2)), ['-', col], 'LineWidth', 2);
        hold on
        f = options.vocoder(j).parameters.analysis_filters.lower(1);
        plot([1 1]*f, [-100, 0], '--', 'Color', [.5 .7 .5], 'LineWidth', 1.5);
        for k=1:length(options.vocoder(j).parameters.analysis_filters.upper)
            f = options.vocoder(j).parameters.analysis_filters.upper(k);
            plot([1 1]*f, [-100, 0], '--', 'Color', [.5 .7 .5], 'LineWidth', 1.5);
        end
        f = options.vocoder(j).parameters.synthesis_filters.lower(1);
        plot([1 1]*f, [-100, 0], ':', 'Color', [.8 .7 .5], 'LineWidth', 1.5);
        for k=1:length(options.vocoder(j).parameters.synthesis_filters.upper)
            f = options.vocoder(j).parameters.synthesis_filters.upper(k);
            plot([1 1]*f, [-100, 0], ':', 'Color', [.8 .7 .5], 'LineWidth', 1.5);
        end
        
        set(gca, 'xscale', 'log')
        xlim([100, 20000]);
        ylim([-100, -35])
        title(options.vocoder(j).label)
        %k = 1:length(x);
        %k = k(k~=i_correct);
        %wavwrite(mean(x{k(1)},2), fs, sprintf('Demo_jvo_%s_voc%d.wav', options.test.voices(options.test.voice_pairs(i,1)).label, j));
        
        xlabel('Frequency (Hz)')
        ylabel('Amplitude (dB)')
        
        if i==2
            set(gcf, 'PaperPosition', [0 0 4 4])
            print(gcf, '-dpng', '-r200', sprintf('Demo_jvo_%s_voc%s.png', options.test.voices(voices(i)).label, options.vocoder(j).label));
        end
    end
    
end

for j=1:length(options.vocoder)
	figure(j)
    hold off
end