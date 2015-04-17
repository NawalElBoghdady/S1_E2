function rng(seed)

%rand('state', seed);

warning('off', 'MATLAB:RandStream:SetDefaultStream');

switch seed
    case 'shuffle'
        RandStream.setDefaultStream(RandStream('mt19937ar','Seed',sum(clock*100)));
    otherwise
        RandStream.setDefaultStream(RandStream('mt19937ar','Seed',seed));
end



