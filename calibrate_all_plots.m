

for voc=0:8

    [~,x,fs] = calibrate(voc,1);
    [Leq, o3dBSPL, f] = machine_to_dB_SPL(x,fs);
    plot(f, o3dBSPL);
    
    hold on
end
hold off