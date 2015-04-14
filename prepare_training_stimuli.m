% Prepare all the training stimuli

[~, options] = expe_build_conditions_freq_tables();


for i = 1:length(options.words)
    
    training.words = {options.words(i)};
    
    fprintf('----- %s\n', options.words{i});

    for ref_voice = unique(options.test.voice_pairs(:,1))'

        for dir_voice = unique(options.test.voice_pairs(:,2))'

            fprintf('Doing ref_voice %d and dir_voice %d...\n', ref_voice, dir_voice);

            u_f0  = 12*log2(options.test.voices(dir_voice).f0 / options.test.voices(ref_voice).f0);
            u_ser = 12*log2(options.test.voices(dir_voice).ser / options.test.voices(ref_voice).ser);
            u = [u_f0, u_ser];
            u = u / sqrt(sum(u.^2));

            training.vocoder = 0;

            new_voice_st = options.test.word_difference*u; %Always use a 12 semitone difference
            training.f0 = options.test.voices(ref_voice).f0 * [1, 2^(new_voice_st(1)/12)];
            training.ser = options.test.voices(ref_voice).ser * [1, 2^(new_voice_st(2)/12)];

            xOut = expe_make_training_stim(options, training);
            
            plot(xOut{1})
            drawnow()
        end
    end
end
