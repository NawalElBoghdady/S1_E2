

load('/Users/nawalelboghdady/Library/Matlab/Frequency Tables Experiment/results/matlab_data.mat');

c0_m = zeros(4,1);
c5_m = c0_m;
m0_m = c0_m;
m5_m = c0_m;

c0_std = zeros(4,1);
c5_std = c0_m;
m0_std = c0_m;
m5_std = c0_m;

voc0 = [1,3,5,7];
voc5 = [2,4,6,8];

for ivoc = 1:4
    
    i = child_0.vocoder == voc0(ivoc);
    c0_m(ivoc) = mean(child_0.threshold(i));
    c0_std(ivoc) = std(child_0.threshold(i));
    
    i = male_0.vocoder == voc0(ivoc);
    m0_m(ivoc) = mean(male_0.threshold(i));
    m0_std(ivoc) = std(male_0.threshold(i));
    
    i = child_5.vocoder == voc5(ivoc);
    c5_m(ivoc) = mean(child_5.threshold(i));
    c5_std(ivoc) = std(child_5.threshold(i));
    
    i = male_5.vocoder == voc5(ivoc);
    m5_m(ivoc) = mean(male_5.threshold(i));
    m5_std(ivoc) = std(male_5.threshold(i));
    
end

yaxis_max = max(max([c0_m+c0_std c5_m+c5_std m0_m+m0_std m5_m+m5_std]));

figure(1);
plot(1:4,c0_m,'b^', 1:4,c5_m,'c*', 1:4,m0_m,'r^', 1:4,m5_m,'m*');
h = gca;
h.XTick = 1:4;
h.XTickLabel = {'GW','LIN','CI24','HR90K'};
xlabel('Frequency Allocation Table');
ylabel('VTL JND (st)');
legend('child-vtl 0mm','child-vtl 5mm','male-vtl 0mm','male-vtl 5mm');
title('Mean VTL JND for the various frequency maps for 5 pilot subjects');
ylim([0 yaxis_max]);

figure(2);
errorbar(1:4,c0_m,c0_std,'b^');
hold on;
errorbar(1:4,c5_m,c5_std,'c*');
errorbar(1:4,m0_m,m0_std,'r^');
errorbar(1:4,m5_m,m5_std,'m*');
hold off;
g = gca;
g.XTick = 1:4;
g.XTickLabel = {'GW','LIN','CI24','HR90K'};
xlabel('Frequency Allocation Table');
ylabel('VTL JND (st)');
legend('child-vtl 0mm','child-vtl 5mm','male-vtl 0mm','male-vtl 5mm');
title('Mean and Std Dev VTL JND for the various frequency maps for 5 pilot subjects');
ylim([0 yaxis_max]);
