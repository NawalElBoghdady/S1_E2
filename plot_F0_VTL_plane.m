%Plot F0-VTL plane

y_axis = [-15,15; 0,0];
x_axis = [0,0; -15,15];

plot(x_axis(1,:),x_axis(2,:),'k',...
    y_axis(1,:),y_axis(2,:),'k','LineStyle','--')
xlabel('\Delta F0 (semitones re. reference)')
ylabel('1/VTL (semitones re. reference)')
title('The F0-VTL Plane')