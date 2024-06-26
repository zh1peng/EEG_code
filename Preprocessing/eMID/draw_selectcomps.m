function [EEG, com] =draw_selectcomps( EEG, compnum, fig );

COLREJ = '[1 0.6 0.6]';
COLACC = '[0 0 0]';
PLOTPERFIG = 35;

com = '';
if nargin < 1
	help pop_selectcomps;
	return;
end;	

if nargin < 2
    uilist = { { 'style' 'text' 'string' 'Components to plot:' } ...
               { 'style' 'edit' 'string'  ['1:' int2str(size(EEG.icaweights,1)) ] } ...
               {} ...
               { 'style' 'text' 'string' [ 'Note: in the next interface, click on buttons to see' char(10) ... 
                                           'component properties and label them for rejection.' char(10) ...
                                           'To actually reject labelled components use menu item' char(10) ...
                                           '"Tools > Remove components" or use STUDY menus.' ] } };
                                       
    result = inputgui('uilist', uilist, 'geometry', { [1 1] 1 1 }, 'geomvert', [1 0.3 3], 'title', 'Reject comp. by map -- pop_selectcomps');
    if isempty(result), return; end
    compnum = eval( [ '[' result{1} ']' ]);

    if length(compnum) > PLOTPERFIG
        ButtonName=questdlg2(strvcat(['More than ' int2str(PLOTPERFIG) ' components so'],'this function will pop-up several windows'), ...
                             'Confirmation', 'Cancel', 'OK','OK');
        if ~isempty( strmatch(lower(ButtonName), 'cancel')), return; end
    end

end
fprintf('Drawing figure...\n');
currentfigtag = ['selcomp' num2str(rand)]; % generate a random figure tag

if length(compnum) > PLOTPERFIG
    for index = 1:PLOTPERFIG:length(compnum)
        pop_selectcomps(EEG, compnum([index:min(length(compnum),index+PLOTPERFIG-1)]));
    end

    com = [ 'pop_selectcomps(EEG, ' vararg2str(compnum) ');' ];
    return;
end

if isempty(EEG.reject.gcompreject)
	EEG.reject.gcompreject = zeros( size(EEG.icawinv,2));
end
try, icadefs; 
catch, 
	BACKCOLOR = [0.8 0.8 0.8];
	GUIBUTTONCOLOR   = [0.8 0.8 0.8]; 
end

% set up the figure
% -----------------
column =ceil(sqrt( length(compnum) ))+1;
rows = ceil(length(compnum)/column);
if ~exist('fig','var')
	figure('name', [ 'Reject components by map - pop_selectcomps() (dataset: ' EEG.setname ')'], 'tag', currentfigtag, ...
		   'numbertitle', 'off', 'color', BACKCOLOR);
	set(gcf,'MenuBar', 'none');
	pos = get(gcf,'Position');
	set(gcf,'Position', [pos(1) 20 800/7*column 600/5*rows*1.2]);
    incx = 120;
    incy = 110;
    sizewx = 100/column;
    if rows > 2
        sizewy = 90/rows;
	else 
        sizewy = 80/rows;
    end
    pos = get(gca,'position'); % plot relative to current axes
	hh = gca;
	q = [pos(1) pos(2) 0 0];
	s = [pos(3) pos(4) pos(3) pos(4)]./100;
	axis off;
end

% figure rows and columns
% -----------------------  
if EEG.nbchan > 64
    disp('More than 64 electrodes: electrode locations not shown');
    plotelec = 0;
else
    plotelec = 1;
end
count = 1;
for ri = compnum
    % compute coordinates
    % -------------------
    X = mod(count-1, column)/column * incx-10;  
    Y = (rows-floor((count-1)/column))/rows * incy - sizewy*1.3;  

    % plot the head
    % -------------
    if ~strcmp(get(gcf, 'tag'), currentfigtag);
        figure(findobj('tag', currentfigtag));
    end
    ha = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q);
    
    topoplot(EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
          'off', 'electrodes','off', 'chaninfo', EEG.chaninfo, 'numcontour', 8);

    % labels
		% -------------
		if isfield(EEG.etc, 'ic_classification')
			classifiers = fieldnames(EEG.etc.ic_classification);
			if ~isempty(classifiers)
				if ~exist('classifier_name', 'var') || isempty(classifier_name)
					if any(strcmpi(classifiers, 'ICLabel'));
						classifier_name = 'ICLabel';
					else
						classifier_name = classifiers{1};
					end
				else
					classifier_name = classifiers{strcmpi(classifiers, classifier_name)};
				end
				if ri == compnum(1) && size(EEG.icawinv, 2) ...
						~= size(EEG.etc.ic_classification.(classifier_name).classifications, 1)
					warning(['The number of ICs do not match the number of IC classifications. This will result in incorrectly plotted labels. Please rerun ' classifier_name])
				end
				[prob, classind] = max(EEG.etc.ic_classification.(classifier_name).classifications(ri, :));
				t = title(sprintf('%s : %.1f%%', ...
					EEG.etc.ic_classification.(classifier_name).classes{classind}, ...
					prob*100));
				set(t, 'Position', get(t, 'Position') .* [1 -1.2 1])
			end
		end
		axis square;

    % Display the component number as colored text instead of a button
    textColor = eval(fastif(EEG.reject.gcompreject(ri), 'COLREJ', 'COLACC'));
    % Create bold text on top of the rectangle
    text('Units', 'Normalized', 'Position', [0.5, -0.2], 'String', int2str(ri), ...
         'HorizontalAlignment', 'center', 'Color', textColor, 'FontSize', 12, 'FontWeight', 'bold');

    drawnow;
    count = count + 1;
end
return;		