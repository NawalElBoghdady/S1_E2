function csv_file = expe_to_csv(is_xls)

% csv_file = expe_to_csv(is_xls)
%   If is_xls is true, export in XLS format, otherwise in CSV format.
%   Default is CSV format.
%
%   Returns the CSV/XLS file name.

if nargin<1
    is_xls = false;
end

%addpath('./mksqlite');
addpath('/Users/nawalelboghdady/Library/Matlab/mksqlite-1.14');

disp('Calling "expe_to_sql2()"...');
db_filename = expe_to_sql2();
db = mksqlite('open', db_filename);

if is_xls
    csv_file = strrep(db_filename, '_db.sqlite', '.xls');
end

for t = {'thr', 'summary'}
    
    if ~is_xls
        csv_file = strrep(db_filename, '_db.sqlite', ['_', t{1}, '.csv']);
        fid = fopen(csv_file, 'w');
    end
    
    res = mksqlite(db, sprintf('SELECT * FROM %s', t{1}));
    keys = fieldnames(res);

    D = cell(length(res)+1, length(keys));
    
    % Headers
    
    for k = 1:length(keys)
        if ~is_xls
            if k>1
                p = ',';
            else
                p = '';
            end
            fprintf(fid, '%s"%s"', p, keys{k});
        else
            D{1,k} = keys{k};
        end
    end
    if ~is_xls
        fprintf(fid, '\n');
    end

    % Data
    for i=1:length(res)
        for k = 1:length(keys)
            D{i+1, k} = res(i).(keys{k});
            if ~is_xls
                if k>1
                    p = ',';
                else
                    p = '';
                end
                
                if ischar(D{i+1, k})
                    fprintf(fid, '%s"%s"', p, D{i+1, k});
                elseif D{i+1, k}==floor(D{i+1, k})
                    fprintf(fid, '%s%d', p, D{i+1, k});
                else
                    fprintf(fid, '%s%.5f', p, D{i+1, k});
                end
            end
        end
        if ~is_xls
            fprintf(fid, '\n');
        end
    end
    
    if is_xls
        xlswrite(csv_file, D, t{1}, 'A1');
    else
        fclose(fid);
    end
end

mksqlite(db, 'close');

rmpath('./mksqlite');