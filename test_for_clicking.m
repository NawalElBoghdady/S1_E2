function test_for_clicking()

%Test to see where the clicking happens:


%-------------------------------------------------
% Set appropriate path

current_dir = fileparts(mfilename('fullpath'));
added_path  = {};

added_path{end+1} = '~/Library/Matlab/vocoder_2015';
addpath(added_path{end});



save_path = '/Users/denizbaskent/Experiments/Nawal/FATs-Exp2/test_stim_clicking/';
options = struct();
options = expe_options(options);


phase = 'test';
[expe, options] = expe_build_conditions_freq_tables(options);

n_conditions = length(expe.(phase).conditions);

for j = 1:n_conditions
    
    fprintf('\n============================ Testing condition %d / %d ==========\n', j, length(expe.( phase ).conditions))
    condition = expe.( phase ).conditions(j);


    files = dir(strcat(options.tmp_path,'/*.wav'));

    for i = 1:5

        file = files(i).name;
        disp(file);
        disp('===========');
        
        file_path = strcat(options.tmp_path,'/',file);
        [x,fs] = wavread(file_path);

        [x, fs] = vocode(x, fs, options.vocoder(condition.vocoder).parameters);
        
        type = options.vocoder(condition.vocoder).parameters.analysis_filters.type;
        type = [type,'-',options.vocoder(condition.vocoder).label,'-'];
        disp(type);
        disp('===========');
        
        x = x(:);

        % Apply a 1 ms ramp to avoid clicking
%         nrmp = floor(fs/1000);
%         x(1:nrmp) = x(1:nrmp) .* linspace(0,1,nrmp)';
%         x(end-nrmp+1:end) = x(end-nrmp+1:end) .* linspace(1,0,nrmp)';

        %normalize x to avoid clipping
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


        wavwrite(x,fs,[save_path,type,file]);
        type = [];
    end
end

%------------------------------------------
% Clean up the path

for i=1:length(added_path)
    rmpath(added_path{i});
end