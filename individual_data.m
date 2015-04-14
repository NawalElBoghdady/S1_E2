dbname = 'jvo_db.sqlite';

%Extract data from results database:
path = '/Users/nawalelboghdady/Library/Matlab/Frequency Table Experiment 2/results/';
filename = strcat(path,dbname);

%Open the database and extract the data:
mksqlite('open', filename);

q = 'SELECT subject from thr WHERE subject != "S15" GROUP BY subject';

s = mksqlite(q);

col = jet(length(s));

q = 'SELECT FAT from thr GROUP BY FAT';

f = mksqlite(q);

H = [];
L = {};

for i = 1:length(s)
    
    subj = s(i).subject;
    
    for dir_voice = {'child-vtl','male-vtl'}
        
        for ins_depth = {'D','S'}
            
            q = sprintf('SELECT AVG(threshold) as threshold from thr WHERE subject = "%s" AND dir_voice = "%s" AND ins_depth = "%s" GROUP BY FAT',subj,dir_voice{1},ins_depth{1});
            
            d = mksqlite(q);
            
            h = plot(1:length(d),[d.threshold],'color',col(i,:));
            hold on;

            
        end
        
    end
    
    H = [H, h];
    L{end+1} = subj;
    
end

set(gca,'XTick',1:4,'XTickLabel',{f.FAT});
xlim([0.5 4.5])
legend(H,L)