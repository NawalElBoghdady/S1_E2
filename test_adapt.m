
change_step_size_conditions = linspace(3, 2.1+sqrt(2), 40);

vD = [];

for change_step_size_condition = change_step_size_conditions


    d = 12;

    step_size = 2;
    step_size_modifier = 1/sqrt(2);



    for i=1:150

        d = d-step_size;

        if d<step_size*change_step_size_condition
            step_size = step_size * step_size_modifier;
        end
    end

    %plot(vD, '-+')

    vD = [vD, d];
end

figure(1)
plot(change_step_size_conditions(vD>0), vD(vD>0), '-o')
hold on
plot(change_step_size_conditions(vD<=0), vD(vD<=0), '-+r')
hold off