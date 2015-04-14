function b = mapChs(FAT,target_chs)

%b = mapChs(FAT,target_chs)
%function that maps a frequency distribution 'FAT' to a different number of
%channels than the ones specified in FAT => This function either expands or
%compresses the FAT in a new vector 'b' as specified by the value of
%'target_chs'.

%compute the number of edge frequencies for the given FAT:
edges_old = length(FAT);

%compute the number of edge frequencies for the new FAT:
edges_new = target_chs + 1;

%compute the 3rd degree polynomial coefficients used to fit the FAT data
%points:
p = polyfit(1:edges_old,FAT,3);

%map the FAT to the new number of channels specified in target_chs:
a = linspace(1,edges_old,edges_new);

%finally, get the corresponding frequency values for the new compressed/
%expanded FAT:
b = polyval(p,a);

if b(1) < FAT(1)
    b(1) = FAT(1);
end


end