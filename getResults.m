%get data

current_loc = cd;
results = '/Users/nawalelboghdady/Library/Matlab/Frequency Tables Experiment/results';

cd(results);

%% get results:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

files = dir('jvo_*');
nfiles = length(files);

for n = 1:nfiles
    load(files(n).name);
    
    if ~exist(strcat('FAT_',files(n).name),'file')
        n_conditions = length(expe.test.conditions);
        FAT = cell(n_conditions,1);
        JND = zeros(n_conditions,1);
        stdev = JND;
        shift = JND;
        table = JND;
        data = zeros(n_conditions,3);

        if length(results.test.conditions) == n_conditions
            fprintf('Extracting data from "%s"...\n',files(n).name);
            for i = 1:n_conditions
                a = expe.test.conditions(i).vocoder;
                FAT{i} = options.vocoder(a).parameters.analysis_filters.type;
                shift(i) = str2double(options.vocoder(a).label(end-2));
                JND(i) = results.test.conditions(i).att.threshold;
                stdev(i) = results.test.conditions(i).att.sd;

            end

            i = strcmp(FAT, 'greenwood');
            table(i) = 1;
            
            i = strcmp(FAT, 'lin');
            table(i) = 2;
            
            i = strcmp(FAT, 'ci24');
            table(i) = 3;
            
            i = strcmp(FAT, 'hr90k');
            table(i) = 4;
            
            data(:,1) = table';
            data(:,2) = shift;
            data(:,3) = JND;
            
            data2 = sortrows(data,1);
            data2 = sortrows(data2,2);
            out0 = zeros(4,2);
            out5 = zeros(4,2);
            
            for j = 1:4
                
                i = (data2(:,1) == j & data2(:,2) == 0);
                out0(j,1) = j;
                out0(j,2) = sum(data2(i,3))/length(data2(i,3));
                
                i = (data2(:,1) == j & data2(:,2) == 5);
                out5(j,1) = j;
                out5(j,2) = sum(data2(i,3))/length(data2(i,3));
            end
            
            
            
            
            save(strcat('FAT_',files(n).name), 'FAT', 'shift', 'JND','stdev','out0','out5');
        else
            warning('Not all conditions have been tested for subject "%s" yet!!',files(n).name);
        end
    end

end



%% plot results
%%%%%%%%%%%%%%%%%%%%%%%%

subj = dir('FAT_*');
nsubj = length(subj);

load(subj(1).name);

avg0 = out0(:,2);
avg5 = out5(:,2);

for i = 2:nsubj
    
    load(files(i).name);
    
    avg0 = avg0 + out0(:,2);
    avg5 = avg5 + out5(:,2);
        
end

avg0 = avg0 ./ nsubj;
avg5 = avg5 ./ nsubj;

plot(1:4,avg0,'ob',1:4,avg5,'^r');
h = gca;
h.XTick = [1:4];
h.XTickLabel = {'GW','LIN','CI24','HR90K'};
xlabel('Frequency Allocation Table');
ylabel('VTL JND');

legend('Shift = 0mm','Shift = 5mm');

%clear all;















