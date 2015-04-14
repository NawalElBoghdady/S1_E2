function expe_main(options, phase, session)

%GUI

%--------------------------------------------------------------------------
% Etienne Gaudrain <e.p.c.gaudrain@umcg.nl> - 2013-02-24
% RuG / UMCG KNO, Groningen, NL
%--------------------------------------------------------------------------

results = struct();
load(options.res_filename); % options, expe, results

h = expe_gui(options);
h.hide_instruction();
h.hide_training_instruction();
h.set_progress(strrep(phase, '_', ' '), 0, 0);
h.set_sylls({'1', '2', '3'});
h.disable_buttons();
drawnow()

nbreak = 0;
starting = 1;

% Set Level
if ispc()
    pa_init(options.fs);
    setPA4(3, 0);
    setPA4(4, 0);
    setPA4(1, options.attenuation_dB);
    setPA4(2, options.attenuation_dB);
end

DEBUG = true;
SIMUL = 0;

test_machine = is_test_machine();

opt = char(questdlg2(sprintf('Ready to start?'),h,'Go','Cancel','Go'));
    switch lower(opt)
        case 'cancel'
            return
    end

beginning_of_session = now();

rng('shuffle');

%=============================================================== MAIN LOOP

while mean([expe.( phase ).conditions.done])~=1 % Keep going while there are some conditions to do
    
    
    % Find first condition not done
    i_condition = find([expe.( phase ).conditions.done]==0, 1);
    fprintf('\n============================ Testing condition %d / %d ==========\n', i_condition, length(expe.( phase ).conditions))
    condition = expe.( phase ).conditions(i_condition);
    
    if condition.session > session %If the first session is done
        questdlg2(sprintf('Session "%s" is finished. Thank you!', strrep(num2str(session), '_', ' ')),h,'OK','OK');
        break
    end

    if condition.vocoder==0
        fprintf('No vocoder\n\n');
    else
        if condition.dir_voice == 5
            target = 'male';
        elseif condition.dir_voice == 7
            target = 'child';
        else
            target = 'other';
        end
        fprintf('Vocoder: %s\n %s\n %s\n\n', options.vocoder(condition.vocoder).label, options.vocoder(condition.vocoder).parameters.analysis_filters.type,target);
    end
    
    % Prepare unitary vector for this voice direction
    u_f0  = 12*log2(options.test.voices(condition.dir_voice).f0 / options.test.voices(condition.ref_voice).f0);
    u_ser = 12*log2(options.test.voices(condition.dir_voice).ser / options.test.voices(condition.ref_voice).ser);
    u = [u_f0, u_ser];
    u = u / sqrt(sum(u.^2));
    
    fprintf('----------\nUnitary vector: %s\n', num2str(u));
    
    %---------------------------------- Adaptive Procedure
    
    difference = options.(phase).starting_difference;
    step_size  = options.(phase).initial_step_size;
    
    response_correct = [];
    decision_vector  = [];
    steps = [];
    differences = [difference];
    
    
    %% Training on the vocoder:
    if test_machine
        tic
        h.hide_buttons();
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Vocoder Training Sentences
        prompt = char(questdlg2(sprintf(...
            'In the experiments you will hear three sounds: two are the same and one is different. Now you will be given a short training in which a word will be shown on the screen, once in BLUE and once in RED. The BLUE version sounds like the 2 identical sounds in the test, while the RED version sounds like the odd sound you should detect.'),...
            h,'OK','OK'));
        switch prompt
            case 'OK'

                h.show_training_instruction();
                h.set_training_instruction(sprintf('Listen carefully to the differences between the BLUE and RED words.'));

        end



        training = condition;

        new_voice_st = options.test.word_difference*u; %Always use a 12 semitone difference
        training.f0 = options.test.voices(training.ref_voice).f0 * [1, 2^(new_voice_st(1)/12)];
        training.ser = options.test.voices(training.ref_voice).ser * [1, 2^(new_voice_st(2)/12)];

        iword = randperm(length(options.words));
        for i_int=1:5
            training.words{i_int} = options.words(iword(i_int));
        end

        [xOut, fs] = expe_make_training_stim(options, training);

        player = cell(size(xOut,1),size(xOut,2));

        for i = 1:size(xOut,2)

            x = xOut{1,i}*10^(-options.attenuation_dB/20);
            player{1,i} = audioplayer([zeros(1024*3, 2); x; zeros(1024*3, 2)], fs, 16);

            x = xOut{2,i}*10^(-options.attenuation_dB/20);
            player{2,i} = audioplayer([zeros(1024*3, 2); x; zeros(1024*3, 2)], fs, 16);
        end

        ibi = audioplayer(zeros(floor(.05*fs), 2), fs); %interblock interval
        iwi = audioplayer(zeros(floor(.025*fs), 2), fs); %interword interval

        pause(.5);

        % Play the stimuli
        for i = 1:size(xOut,2)

            %h.highlight_button(i, 'on');
            disp(training.words{i});
            disp('=====');
            h.set_training_word(['reference:';upper(training.words{i})]);
            h.set_training_word_color([0 0 0.8]);
            h.show_training_word();
            drawnow();
            pause(.5);
            playblocking(player{1,i});
            playblocking(iwi);
            h.set_training_word(['target:';upper(training.words{i})]);
            h.set_training_word_color([0.8 0 0]);
            drawnow();
            playblocking(player{2,i});
            h.hide_training_word();
            %h.highlight_button(i, 'off');

            if i~=size(xOut,2)
                playblocking(ibi);
            end
        end
        toc
        h.hide_training_instruction();

        
        opt = char(questdlg2(sprintf('Continue to actual test?'),h,'Yes','No','Yes'));
        switch opt
            case 'No'
                break
        end
    end
    
    %% If we start the actual testing phase, display a message
    instr = strrep(options.instructions.(phase), '\n', sprintf('\n'));
    if ~isempty(instr) && starting
        scrsz = get(0,'ScreenSize');
        if ~test_machine
            left=scrsz(1); bottom=scrsz(2); width=scrsz(3); height=scrsz(4);
        else
            left = -1024; bottom=0; width=1024; height=768;
        end
        scrsz = [left, bottom, width, height];

        msg = struct();
        msgw = 900;
        msgh = 650;
        mr = 60;
        msg.w = figure('Visible', 'off', 'Position', [left+(width-msgw)/2, (height-msgh)/2, msgw, msgh], 'Menubar', 'none', 'Resize', 'off', 'Color', [1 1 1]*.9, 'Name', 'Instructions');

        msg.txt = uicontrol('Style', 'text', 'Position', [mr, 50+mr*2, msgw-mr*2, msgh-(50+mr)-mr*2], 'Fontsize', 18, 'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1]*.9);
        
        instr = textwrap(msg.txt, {instr});
        set(msg.txt, 'String', instr);
        msg.bt = uicontrol('Style', 'pushbutton', 'Position', [msgw/2-50, mr, 100, 50], 'String', 'OK', 'Fontsize', 14, 'Callback', 'uiresume');
        set(msg.w, 'Visible', 'on');
        uicontrol(msg.bt);

        uiwait(msg.w);
        close(msg.w);
    end
    
    starting = 0;
    beginning_of_run = now();
    
    % Prepare the GUI
    h.show_instruction();
    h.show_buttons();
    h.set_instruction(sprintf('Which interval is different?'));
    h.set_progress(strrep(phase, '_', ' '), sum([expe.( phase ).conditions.done])+1, length([expe.( phase ).conditions.done]));
    
    
    
    while true
        
        tstart = tic; %find out how long each trial lasts
        
        fprintf('\n------------------------------------ Trial\n');
        
        if ~SIMUL
            figure(h.f);
        end
        
        % Prepare the trial
        trial = condition;
        
        % Compute test voice
        new_voice_st = difference*u;
        trial.f0 = options.test.voices(trial.ref_voice).f0 * [1, 2^(new_voice_st(1)/12)];
        trial.ser = options.test.voices(trial.ref_voice).ser * [1, 2^(new_voice_st(2)/12)];
        
        ifc = randperm(size(options.f0_contours, 1)); 
        trial.f0_contours = options.f0_contours(ifc(1:3), :);
        
        isyll = randperm(length(options.syllables));
        for i_int=1:3
            trial.syllables{i_int} = options.syllables(isyll(1:options.n_syll));
        end
        
        options.syllables(isyll(1:options.n_syll))
        
        
        % Prepare the stimulus
        if SIMUL>=2
            i_correct = 1;
        else
            [xOut, fs, i_correct] = expe_make_stim(options, trial);
            
            
            player = {};
            for i=1:length(xOut)
                x = xOut{i}*10^(-options.attenuation_dB/20);
                player{i} = audioplayer([zeros(1024*3, 2); x; zeros(1024*3, 2)], fs, 16);
                fprintf('Interval %d max: %.2f\n', i, max(abs(x(:))));
            end
            
            isi = audioplayer(zeros(floor(.2*fs), 2), fs);

            pause(.5);

            % Play the stimuli
            for i=1:length(xOut)
                h.highlight_button(i, 'on');
                playblocking(player{i});
                h.highlight_button(i, 'off');
                if i~=length(xOut)
                    playblocking(isi);
                end
            end
        end
        h.enable_buttons();

        tic();

        % Collect the response
        if SIMUL
            if difference+randn(1)>1
                i_clicked = i_correct;
            else
                i_clicked = i_correct+1;
            end
            response.response_time = toc();
            response.timestamp = now();
        else
            ok = false;
            while ~ok
                uiwait(h.f); %you need to wait for user input to the GUI instead of the plot figure. 
                response.response_time = toc();
                response.timestamp = now();
                h = get(h.f, 'UserData');
                i_clicked = h.last_clicked;
                if ~isnan(i_clicked)
                    ok = true;
                    fprintf('Click!\n');
                end
            end
        end

        h.last_clicked = NaN;
        set(h.f, 'UserData', h);

        h.disable_buttons();

        % Fill the response structure
        response.button_correct = i_correct;
        response.button_clicked = i_clicked;
        response.correct = (response.button_clicked == response.button_correct);
        response_correct = [response_correct, response.correct];
        decision_vector  = [decision_vector,  response.correct];
        response.condition = condition;
        response.condition.u = u;
        response.trial = trial;
        response.trial.v = difference*u;
        
        fprintf('Difference    : %.1f st (%.1f st GPR, %.1f st VTL)\n', difference, difference*u(1), difference*u(2));
        fprintf('Correct button: %d\n', i_correct);
        fprintf('Clicked button: %d\n', i_clicked);
        fprintf('Response time : %d ms\n', round(response.response_time*1000));
        fprintf('Time since beginning of run    : %s\n', datestr(response.timestamp-beginning_of_run, 'HH:MM:SS.FFF'));
        fprintf('Time since beginning of session: %s\n', datestr(response.timestamp-beginning_of_session, 'HH:MM:SS.FFF'));

        % Visual feedback:
        %================
        if condition.visual_feedback == 1
            if response.correct
                feedback_color = h.button_right_color;
            else
                feedback_color = h.button_wrong_color;
            end
            for k=1:3
                pause(.1);
                set(h.patch(response.button_correct), 'FaceColor', feedback_color);
                drawnow();
                pause(.1);
                set(h.patch(response.button_correct), 'FaceColor', h.button_face_color);
                drawnow();
            end
        end
        
        %Auditory feedback for training:
        %===============================
        
        if (condition.baseline == 0) && ~(response.correct)
            if response.correct
                feedback_color = h.button_right_color;
            else
                feedback_color = h.button_wrong_color;
            end

            pause(.1);
            set(h.patch(response.button_correct), 'FaceColor', feedback_color);
            drawnow();
            pause(.1);
                
            % Play sounds again, while correct button is highlighted:
            for i=1:length(xOut)
                h.highlight_button(i, 'on');
                set(h.patch(response.button_correct), 'FaceColor', feedback_color);
                drawnow();
                pause(.1);
                playblocking(player{i});
                h.highlight_button(i, 'off');
                set(h.patch(response.button_correct), 'FaceColor', feedback_color);
                drawnow();
                pause(.1);
                if i~=length(xOut)
                    playblocking(isi);
                end
            end
            
            set(h.patch(response.button_correct), 'FaceColor', h.button_face_color);
            drawnow();
        end

        % Add the response to the results structure
        n_attempt = expe.( phase ).conditions(i_condition).attempts + 1;
        if ~isfield(results, phase) || i_condition==length(results.( phase ).conditions)+1
            results.( phase ).conditions(i_condition) = struct('att', struct('responses', struct(), 'differences', [], 'steps', [], 'diff_i_tp', [], 'threshold', NaN, 'sd', []));
        end
        if isempty(fieldnames(results.( phase ).conditions(i_condition).att(n_attempt).responses)) ...
                || isempty(results.( phase ).conditions(i_condition).att(n_attempt).responses)
            results.( phase ).conditions(i_condition).att(n_attempt).responses = orderfields( response );
        else
            results.( phase ).conditions(i_condition).att(n_attempt).responses(end+1) = orderfields( response );
        end
        
        % Prepare the parameters for the next trial
        if length(decision_vector)>=options.(phase).down_up(1) && all(decision_vector(end-(options.(phase).down_up(2)-1):end)==1)
            % The last n_down responses were correct -> Reduce
            % difference by step_size, then update step_size
            
            fprintf('--> We are going down by %f st\n', step_size);
            
            difference = difference - step_size;
            steps = [steps, -step_size];
            differences = [differences, difference];
            
            % Reset decision vector
            decision_vector = [];
                
            
        elseif length(decision_vector)>=options.(phase).down_up(2) && all(decision_vector(end-(options.(phase).down_up(2)-1):end)==0)
            % The last n_up responses were incorrect -> Increase
            % difference by step_size.
            
            fprintf('--> We are going up by %f st\n', step_size);
            
            difference = difference + step_size;
            steps = [steps, step_size];
            differences = [differences, difference];
            
            % Reset decision vector
            decision_vector = [];
                
        else
            % Not going up nor down
            
            fprintf('--> We are going neither down nor up\n');
            
            steps = [steps, 0];
            differences = [differences, difference];
            
        end
        
        % Update step_size
        if difference <= options.(phase).change_step_size_condition*step_size ...
                        || mod(length(differences), options.(phase).change_step_size_n_trials)==0
            fprintf('--> Step size is getting updated: was %f st', step_size);
            step_size = step_size * options.(phase).step_size_modifier;
            fprintf(', is now %f st\n', step_size);
        end
        
        nturns = sum(diff(sign(steps(steps~=0)))~=0);
        
        % Have we reached an exit condition?
        if nturns >= options.(phase).terminate_on_nturns 
            
            fprintf('====> END OF RUN because enough turns\n');
            
            results.( phase ).conditions(i_condition).att(n_attempt).exit_reason = 'nturns';
            expe.( phase ).conditions(i_condition).done = 1;
            expe.( phase ).conditions(i_condition).attempts = expe.( phase ).conditions(i_condition).attempts + 1;
            
            i_nz = find(steps~=0);
            i_d  = find(diff(sign(steps(i_nz)))~=0);
            i_tp = i_nz(i_d)+1;
            i_tp = [i_tp, length(differences)];
            i_tp = i_tp(end-(options.(phase).threshold_on_last_n_trials-1):end);

            results.( phase ).conditions(i_condition).att(n_attempt).diff_i_tp = i_tp;
            thr = mean(differences(i_tp)); %exp(mean(log(differences(i_tp))));
            results.( phase ).conditions(i_condition).att(n_attempt).threshold = thr;
            sd = std(differences(i_tp));
            results.( phase ).conditions(i_condition).att(n_attempt).sd = sd;
            
            fprintf('Threshold: %f st (%f st GPR, %f st VTL) [%f st] \n', thr, thr*u(1), thr*u(2), sd);
            
            break
            
        elseif length(response_correct) >= options.(phase).terminate_on_ntrials
            
            fprintf('====> END OF RUN because too many trials\n');
            
            results.( phase ).conditions(i_condition).att(n_attempt).exit_reason = 'ntrials';
            expe.( phase ).conditions(i_condition).attempts = expe.( phase ).conditions(i_condition).attempts + 1;
            
            % Should we retry again?
            if expe.( phase ).conditions(i_condition).attempts >= options.(phase).retry + 1
                fprintf('      (will not try again)\n');
                expe.( phase ).conditions(i_condition).done = 1;
            end
            
            results.( phase ).conditions(i_condition).att(n_attempt).diff_i_tp = [];
            results.( phase ).conditions(i_condition).att(n_attempt).threshold = NaN;
            results.( phase ).conditions(i_condition).att(n_attempt).sd = NaN;
            
            break
        elseif length(response_correct) >= options.(phase).change_step_size_n_trials ...
                && all(response_correct(end-(options.(phase).change_step_size_n_trials-1):end)==0)
            % All last n trials are incorrect
            
            fprintf('====> END OF RUN because too many wrong answers\n');
            
            results.( phase ).conditions(i_condition).att(n_attempt).exit_reason = 'nwrong';
            expe.( phase ).conditions(i_condition).attempts = expe.( phase ).conditions(i_condition).attempts + 1;
            
            % Should we retry again?
            if expe.( phase ).conditions(i_condition).attempts >= options.(phase).retry + 1
                fprintf('      (will not try again)\n');
                expe.( phase ).conditions(i_condition).done = 1;
            end
            
            break
        end
        
        results.( phase ).conditions(i_condition).att(n_attempt).differences = differences;
        results.( phase ).conditions(i_condition).att(n_attempt).steps = steps;
        
        % Save the response
        save(options.res_filename, 'options', 'expe', 'results')
        
        % DEBUG
        if DEBUG
            figure(98)
            set(gcf, 'Position', [50, 350, 500, 500]);
            x = 1:length(differences)-1;
            y = differences(1:end-1);
            plot(x, y, '-b')
            hold on
            plot(length(differences)+[-1 0], differences(end-1:end), '--b')
            plot(x(response_correct==1), y(response_correct==1), 'ob')
            plot(x(response_correct==0), y(response_correct==0), 'xb')
            
            hold off
        end
        
       
    end
    
    time = toc(tstart);
    %---------- End of adaptive loop
    
    
    %============================== DEBUG
    if DEBUG && strcmp(phase, 'training')==0
        figure()
        set(gcf, 'Position', [550, 350, 700, 500]);
        subplot(1, 2, 1)
        x = 1:length(differences)-1;
        y = differences(1:end-1);
        plot(x, y, '-b')
        hold on
        plot(length(differences)+[-1 0], differences(end-1:end), '--b')
        plot(x(response_correct==1), y(response_correct==1), 'ob')
        plot(x(response_correct==0), y(response_correct==0), 'xb')
        
        plot(i_tp, differences(i_tp), 'sr')
        
        plot([i_tp(1), i_tp(end)], [1 1]*thr, '--k');

        hold off
        title(sprintf('Condition %d', i_condition));
        
        subplot(1, 2, 2)
        plot([options.test.voices(condition.ref_voice).f0, options.test.voices(condition.dir_voice).f0], ...
                [options.test.voices(condition.ref_voice).ser, options.test.voices(condition.dir_voice).ser], '--b')
        hold on
        plot(options.test.voices(condition.ref_voice).f0, options.test.voices(condition.ref_voice).ser, 'ob')
        plot(options.test.voices(condition.dir_voice).f0, options.test.voices(condition.dir_voice).ser, 'sr')
        for i_resp=1:length(results.( phase ).conditions(i_condition).att(n_attempt).responses)
            if results.( phase ).conditions(i_condition).att(n_attempt).responses(i_resp).correct
                plot(results.( phase ).conditions(i_condition).att(n_attempt).responses(i_resp).trial.f0(2), ...
                    results.( phase ).conditions(i_condition).att(n_attempt).responses(i_resp).trial.ser(2), 'xk')
            else
                plot(results.( phase ).conditions(i_condition).att(n_attempt).responses(i_resp).trial.f0(2), ...
                    results.( phase ).conditions(i_condition).att(n_attempt).responses(i_resp).trial.ser(2), '+', 'Color', [1 1 1]*.5)
            end
        end
        
        for i_sp=1:length(options.test.voices)
            plot(options.test.voices(i_sp).f0, options.test.voices(i_sp).ser, '+g');
        end
        
        hold off
        
    end 
        
    % Save the response
    save(options.res_filename, 'options', 'expe', 'results');
    
    % Report status
    report_status(options.subject_name, phase, sum([expe.( phase ).conditions.done])+1, length([expe.( phase ).conditions.done]), options.log_file);
    
    
    h.show_instruction();
    h.set_instruction(sprintf('Done!'));
    
    % Wait a bit before to go to next condition
    pause(1);
    %starting = true;
    
    opt = char(questdlg2(sprintf('Would you like to continue testing or take a break?'),h,'Continue','Take a Break','Continue'));
    switch opt
        case 'Take a Break'
            break
    end
end

% If we're out of the loop because the phase is finished, tell the subject
if mean([expe.( phase ).conditions.done])==1
    questdlg2(sprintf('The "%s" phase is finished. Thank you!', strrep(phase, '_', ' ')),h,'OK','OK');
end



close(h.f);

%--------------------------------------------------------------------------
function report_status(subj, phase, i, n, logFile)

try
    fd = fopen(logFile, 'w');
    fprintf(fd, '%s : %s : %d/%d\r\n', subj, phase, i, n);
    fclose(fd);
catch ME
    % Stay silent if it failed
end
