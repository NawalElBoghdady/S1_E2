function h = expe_gui(options)

%--------------------------------------------------------------------------
% Etienne Gaudrain <e.p.c.gaudrain@umcg.nl> - 2013-02-24
% RuG / UMCG KNO, Groningen, NL
%--------------------------------------------------------------------------

close all hidden

h = struct();

fntsz = 40;

scrsz = get(0,'ScreenSize');


test_machine = is_test_machine();
if ~test_machine
    left=scrsz(1); bottom=scrsz(2); width=scrsz(3); height=scrsz(4);
else
    left = -1024; bottom=0; width=1024; height=768;
end
scrsz = [left, bottom, width, height];

% scrsz = get(0, 'MonitorPositions');
% scrsz = scrsz(2,:);

h.background_color = [.6 .6 .6];
h.button_face_color = [0 0 .07]+.8;
h.button_border_color = h.button_face_color*.6;
h.button_press_color = .5*h.button_face_color+.5;
h.progress_bar_color = [.5 .8 .5];
h.main_text_color = [1 1 1]*.9;
h.button_right_color = h.progress_bar_color;
h.button_wrong_color = [1 .5 0];
h.button_highlight_color = [1 1 .87];
h.disabled_color = [1 1 1]*.4;

h.f = figure('Visible', 'off', 'Position', scrsz, 'Menubar', 'none', 'Resize', 'off', 'Color', h.background_color);

% Progress bar
h.waitbar = axes('Units', 'pixel', 'Position', [width/2-300, height-50, 600, 25], 'Box', 'off', ...
    'XColor', 'w', 'YColor', 'w', 'XTick', [], 'YTick', []);
h.waitbar_legend = uicontrol('Style', 'text', 'Units', 'pixel', 'Position', [width/2-300, height-101, 600, 50], ...
    'HorizontalAlignment', 'center', 'FontSize', round(fntsz*.5), 'ForegroundColor', h.main_text_color, 'BackgroundColor', h.background_color);

n_rows = 1; %options.n_rows;
n_cols = 3; % options.n_cols;

% Response area
grid_sz = [n_cols, n_rows]*300;
h.grid = axes('Units', 'pixel', 'Position', [width/2-grid_sz(1)/2, height/2-grid_sz(2)/2, grid_sz], ...
    'Box', 'off', 'Color', h.background_color);
h.instruction = uicontrol('Style', 'text', 'Units', 'pixel', 'Position', [width/2-grid_sz(1)/2, height/2-grid_sz(2)/2+grid_sz(2)+10, grid_sz(1), 50], ...
    'HorizontalAlignment', 'center', 'FontSize', fntsz, 'ForegroundColor', h.main_text_color, 'BackgroundColor', h.background_color);

h.training_instruction = uicontrol('Style', 'text', 'Units', 'pixel', 'Position', [width/2-grid_sz(1)/2, height/2-grid_sz(2)/2+grid_sz(2)+10, grid_sz(1), 70], ...
    'HorizontalAlignment', 'center', 'FontSize', 25, 'ForegroundColor', h.main_text_color, 'BackgroundColor', h.background_color);

h.training_word = uicontrol('Style', 'text', 'Units', 'pixel', 'Position', [width/2-grid_sz(1)/2, height/2, grid_sz(1), 140], ...
     'HorizontalAlignment', 'center', 'FontSize', 50, 'ForegroundColor', h.main_text_color, 'BackgroundColor', h.background_color);

%h.training_word = uicontrol('Style', 'text', 'Units', 'pixel', 'Position', [width/2-grid_sz(1)/2, height/2-grid_sz(2)/2+grid_sz(2)+13, grid_sz(1), 50], ...
 %   'HorizontalAlignment', 'center', 'FontSize', 25, 'ForegroundColor', h.main_text_color, 'BackgroundColor', h.background_color);

% Margin
m = .1;

set(h.grid, 'XLim', [0, n_cols], 'YLim', [0, n_rows]);

for i=1:n_rows
    
    for j=1:n_cols
        
        h.patch(j+(i-1)*n_cols) = patch([0, 1, 1, 0]*(1-2*m)+m+j-1, [0, 0, 1, 1]*(1-2*m)+m+i-1, h.button_face_color, ...
            'FaceColor', h.button_face_color, 'EdgeColor', h.button_border_color, 'LineWidth', 2);
        hold on
        %plot([0, 1, 1, 0, 0]*(1-2*m)+m+j-1, [0, 0, 1, 1, 0]*(1-2*m)+m+i-1, '-', 'Color', h.button_border_color, 'LineWidth', 2);
        h.t(j+(i-1)*n_cols) = text(j-.5, i-.5, int2str(j+(i-1)*n_cols), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', fntsz);    
    end
        
end
%{
h.instruction = text(n_cols/2, n_rows/2, 'Instruction', 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', fntsz, 'Color', h.main_text_color);
%}

hold off
set(h.grid, 'Xtick', [], 'YTick', [], 'Visible', 'off');
%set(h.t(1), 'Color', h.disabled_color);

%-------- Actions
h.hide_buttons = @() set([h.patch(:), h.t(:)], 'Visible', 'off');
h.show_buttons = @() set([h.patch(:), h.t(:)], 'Visible', 'on');
h.hide_instruction = @() set(h.instruction, 'Visible', 'off');
h.show_instruction = @() set(h.instruction, 'Visible', 'on');
h.set_instruction = @(t) set(h.instruction, 'String', t);
h.set_progress = @(t, i, n) set_progress(h, t, i, n);
h.set_sylls = @(sylls) set_sylls(h, sylls);
h.patch_click = @CB_patch_click;
h.highlight_button = @(i, s) highlight_button(h, i, s);
h.disable_buttons = @() switch_buttons(h, 'off');
h.enable_buttons = @() switch_buttons(h, 'on');

%---Training Actions:

h.hide_training_instruction = @() set(h.training_instruction, 'Visible', 'off');
h.show_training_instruction = @() set(h.training_instruction, 'Visible', 'on');
h.set_training_instruction = @(t) set(h.training_instruction, 'String', t);

h.set_training_word = @(t) set(h.training_word, 'String', t);
h.set_training_word_color = @(t) set(h.training_word, 'ForegroundColor', t);
h.hide_training_word = @() set(h.training_word, 'Visible', 'off');
h.show_training_word = @() set(h.training_word, 'Visible', 'on');


%-------- Events
set(h.f, 'WindowButtonUpFcn', {@CB_reset_colors, h});
for i=1:length(h.patch)
    set([h.patch(i), h.t(i)], 'ButtonDownFcn', {h.patch_click, i});
end

%-------- Initialize
h.hide_buttons();
h.last_clicked = NaN;
set(h.f, 'UserData', h);
set(h.f, 'Visible', 'on');
drawnow();

%feedback_colors = {[.5, 0, 0], [0, .5, 0]};

%--------------------------------------------------------------------------
function CB_patch_click(src, event, i)

h = get(gcf, 'UserData');
set(h.patch(i), 'FaceColor', h.button_press_color);
h.last_clicked = i;
set(h.f, 'UserData', h);

%fprintf('-> Clicked on %d\n', i);

%--------------------------------------------------------------------------
function CB_reset_colors(src, event, h)

set(h.patch(:), 'FaceColor', h.button_face_color);
uiresume();

%--------------------------------------------------------------------------
function set_progress(h, t, i, n)

if n>0
    set(h.waitbar_legend, 'String', sprintf('%s: %d/%d', t, i, n));
    fill([0 1 1 0] * i/n, [0 0 1 1], h.progress_bar_color, 'Parent', h.waitbar, 'EdgeColor', 'none');
else
    set(h.waitbar_legend, 'String', t);
    fill([0 1 1 0] * 0, [0 0 1 1], h.progress_bar_color, 'Parent', h.waitbar, 'EdgeColor', 'none');
end
set(h.waitbar, 'XColor', 'w', 'YColor', 'w', 'XTick', [], 'YTick', [], 'Xlim', [0 1], 'YLim', [0 1]);

%--------------------------------------------------------------------------
function set_sylls(h, sylls)

for i=1:length(h.t(:))
    set(h.t(i), 'String', sylls{i});
end

%--------------------------------------------------------------------------
function highlight_button(h, i, s)

switch s
    case 'on'
        set(h.patch(i), 'FaceColor', h.button_highlight_color);
    case 'off'
        set(h.patch(i), 'FaceColor', h.button_face_color);
end

drawnow();

%--------------------------------------------------------------------------
function switch_buttons(h, s)

switch s
    case 'on'
        col = 'k';
        set(h.f, 'WindowButtonUpFcn', {@CB_reset_colors, h});
    case 'off'
        col = h.disabled_color;
        set(h.f, 'WindowButtonUpFcn', []);
end
set([h.patch(1:end), h.t(1:end)], 'HitTest', s)
set(h.t(1:end), 'Color', col);


