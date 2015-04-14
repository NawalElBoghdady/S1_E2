function [c_thr,c_voc,m_thr,m_voc] = ExtractData_sql2(process)
close all

%Convert subject results into a database:
if process == 1
        expe_to_sql;
end

dbname = 'jvo_db.sqlite';

%Extract data from results database:
path = '/Users/nawalelboghdady/Library/Matlab/Frequency Table Experiment 2/results/';
filename = strcat(path,dbname);

%Open the database and extract the data:
mksqlite('open', filename);
query = 'SELECT vocoder,dir_voice,subject,threshold,sd FROM ''thr'' WHERE subject != "S15" ORDER BY vocoder,dir_voice ASC';
data = mksqlite(query);


%Extract vocoder types:
op = expe_options();
[expe, op] = expe_build_conditions_freq_tables(op);

for i = 1:length(data)
    
    voc_num = data(i).vocoder;
    
    ind = find(op.vocoder(voc_num).label,6,'last');
    ins_depth = op.vocoder(voc_num).label(ind);
    
    switch ins_depth
        case '21.5mm'
            ins_depth = 'D';
        case '18.5mm'
            ins_depth = 'S';
    end
    
    type = op.vocoder(voc_num).parameters.analysis_filters.type;
    
    switch type
        case 'greenwood'
            type = 'GW';
        case 'lin'
            type = 'LIN';
        case 'ci24'
            type = 'CI';
        case 'hr90k'
            type = 'HR';
    end
    
    data(i).ins_depth = ins_depth;
    data(i).FAT = type;
    

end


voc = zeros(length(data),1);
voice = cell(length(data),1);
thresh = voc;
ins_depth = voice;
FAT = voice;


for i = 1:length(data)
    
    voc(i) = data(i).vocoder;
    voice{i} = data(i).dir_voice;
    ins_depth{i} = data(i).ins_depth;
    FAT{i} = data(i).FAT;
    
    thresh(i) = data(i).threshold;
end



% boxplot(thresh,{FAT,voice,ins_depth},'colorgroup',{voice},'factorseparator',[1]);

tick_labels = {'C-D','C-S','M-D','M-S','C-D','C-S','M-D','M-S','C-D','C-S','M-D','M-S','C-D','C-S','M-D','M-S'}; %HARD CODED!!!!



boxplot(thresh,{FAT,voice,ins_depth},'colors','rrbb','factorseparator',[1],'symbol','+','labels',tick_labels);
ylabel('1/VTL (semitones re. reference)','FontSize',16);
xlabel('Condition Tested','FontSize',16);
ylim([0 max(thresh)]);
title('VTL JNDs as a function of Frequency Allocation for the 2 voice directions');

h=findobj(gca,'tag','Box'); % Get handles for boxes.
set(h(1:2:end),'LineStyle','-.'); % Change line style for the shallow insertion group.
%set(h(1:2:end),'Marker','o'); % Change symbols for all the shallow insertion group.
count = 0;
for j = 1:2:length(h)
    count = count + 1;
    if mod(count,2) == 1
        %patch(get(h(j),'XData'),get(h(j),'YData'),'y','FaceAlpha',[0.7,0,0]);
        patch(get(h(j),'XData'),get(h(j),'YData'),[0,0,0.9],'FaceAlpha',0.2);
        
        
        
    else
        %patch(get(h(j),'XData'),get(h(j),'YData'),'y','FaceAlpha',[0,0,0.7]);
        patch(get(h(j),'XData'),get(h(j),'YData'),[0.9,0,0],'FaceAlpha',0.2);
    end
end

h=findobj(gca,'tag','Outliers'); % Get handles for outlier lines.
set(h(1:2:end),'Marker','o'); % Change symbols for all the shallow insertion group.

%Label the different FAT regions:
fig = gcf;
annotation(fig,'textbox',...
    [0.17 0.8 0.07 0.04],...
    'String',{'GW'},...
    'FitBoxToText','on',...
    'FontSize',16,...
    'BackgroundColor',[1 0.949019610881805 0.866666674613953]);
annotation(fig,'textbox',...
    [0.35 0.8 0.07 0.04],...
    'String',{'LIN'},...
    'FitBoxToText','on',...
    'FontSize',16,...
    'BackgroundColor',[1 0.949019610881805 0.866666674613953]);
annotation(fig,'textbox',...
    [0.54 0.8 0.07 0.04],...
    'String',{'CI24'},...
    'FitBoxToText','on',...
    'FontSize',16,...
    'BackgroundColor',[1 0.949019610881805 0.866666674613953]);
annotation(fig,'textbox',...
    [0.747499999999998 0.782857142857143 0.133761160714286 0.0595238095238095],...
    'String',{'HR90K'},...
    'FitBoxToText','on',...
    'FontSize',16,...
    'BackgroundColor',[1 0.949019610881805 0.866666674613953]);

mksqlite('close');

legend('Child-Deep','Male-Deep','Child-Shallow','Male-Shallow')

end
