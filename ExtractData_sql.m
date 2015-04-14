function [c_thr,c_voc,m_thr,m_voc] = ExtractData_sql()
close all

%Convert subject results into a database:
%expe_to_sql;
dbname = 'jvo_db.sqlite';

%Extract data from results database:
path = '/Users/nawalelboghdady/Library/Matlab/Frequency Table Experiment 2/results/';
filename = strcat(path,dbname);

%Open the database
mksqlite('open', filename);

%Query the database
%queries = ['SELECT id,subject,vocoder,threshold,sd FROM "thr" WHERE dir_voice = ''child-vtl'' AND vocoder_name LIKE ''%18.5mm%''ORDER BY vocoder ASC;'...
%    'SELECT id,subject,vocoder,threshold,sd FROM "thr" WHERE dir_voice = ''child-vtl'' AND vocoder_name LIKE ''%21.5mm%''ORDER BY vocoder ASC;'...
%    'SELECT id,subject,vocoder,threshold,sd,i FROM "thr" WHERE dir_voice = ''male-vtl'' AND vocoder_name LIKE ''%18.5mm%''ORDER BY vocoder ASC;'...
%    'SELECT id,subject,vocoder,threshold,sd,i FROM "thr" WHERE dir_voice = ''male-vtl'' AND vocoder_name LIKE ''%21.5mm%''ORDER BY vocoder ASC;'];
% child_shallow = mksqlite(queries(1));
% child_deep = mksqlite(queries(2));
% 
% male_shallow = mksqlite(queries(3));
% male_deep = mksqlite(queries(4));

queries = {'SELECT subject,vocoder,threshold,sd FROM ''thr'' WHERE dir_voice = ''child-vtl'' ORDER BY vocoder ASC',...
    'SELECT subject,vocoder,threshold,sd,i FROM ''thr'' WHERE dir_voice = ''male-vtl'' ORDER BY vocoder ASC'};

child = mksqlite(queries{1});
male = mksqlite(queries{2});

c_thr = zeros(length(child),1);
c_voc = c_thr;

m_thr = zeros(length(male),1);
m_voc = m_thr;

for i = 1:length(child)
    c_thr(i) = child(i).threshold;
    c_voc(i) = child(i).vocoder;
end

for i = 1:length(male)
    m_thr(i) = male(i).threshold;
    m_voc(i) = male(i).vocoder;
end

%Extract vocoder types:
op = expe_options();
[expe, op] = expe_build_conditions_freq_tables(op);

tick_labels = cell(1,length(op.vocoder));

for i = 1:length(op.vocoder)
    ind = find(op.vocoder(i).label,6,'last');
    ins_depth = op.vocoder(i).label(ind);
    
    switch ins_depth
        case '21.5mm'
            ins_depth = 'D';
        case '18.5mm'
            ins_depth = 'S';
    end
    
    type = op.vocoder(i).parameters.analysis_filters.type;
    
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
    
    tick_labels{i} = strcat(type,'-',ins_depth);
    
%     qc = sprintf('SELECT subject,vocoder,threshold,sd FROM ''thr'' WHERE dir_voice = ''child-vtl'' AND vocoder = %s ORDER BY vocoder ASC',num2str(i));
%     qm = sprintf('SELECT subject,vocoder,threshold,sd FROM ''thr'' WHERE dir_voice = ''male-vtl'' AND vocoder = %s ORDER BY vocoder ASC',num2str(i));
%     
%     child_pdf = mksqlite(qc);
%     male_pdf = mksqlite(qm);
%     
%     figure();
%     title(sprintf('Child Distr, Voc type %s',tick_labels{i}));
%     histogram()
end

figure();
boxplot(c_thr,c_voc);
title('Child VTL');
ylabel('VTL JND in semitones');
xlabel('FATs');
ylim([0 30]);
h = gca;
h.XTickLabel = tick_labels;

figure();
boxplot(m_thr,m_voc);
title('Male VTL');
ylabel('VTL JND in semitones');
xlabel('FATs');
ylim([0 30]);
h = gca;
h.XTickLabel = tick_labels;

% figure();
% histogram(c_thr);


%Close the database
mksqlite('close');



end
