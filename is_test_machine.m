function b = is_test_machine()

[c, s] = system('hostname');
s = strtrim(s);
switch s
    case {'hoogglans', 'Nawals-MacBook-Pro.local', 'mw161070.med.rug.nl'}
        b = 0;
    otherwise
        b = 1;
end 