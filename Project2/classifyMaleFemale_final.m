% Digital Signal Processing (Fall 2015)
% Project 2: Predict whether a male/female is speaking in the mp3 file
% Classificaiton function
% By: Tyler Olivieri; Devin Trejo; Robert Irwin

function identity = classifyMaleFemale(fileN)

% - - - - - - - - - - - - Import Signal - - - - - - - - - - - - - - - - - 
% Read in speech signals
%
[~, nameSig, fileEXT] = fileparts(fileN);
[y, fs] = audioread(fileN);
% file = audioplayer(y,Fs);
% file.play

% Signals are mono so we remove the second channel 
%
y = y(:,1);

% Find total energy in the signal
%
energy_sig = sum(y.^2);

% Create a time vector
%
samL = length(y);
t = linspace(0,samL/fs,samL);

% Plot time signal
%
figure(); plot(t, y); hold on;
xlabel('time (secs)'); title(nameSig);
axisy = ylim();
ylim([0 axisy(2)])

% Low pass the signal. We really only care about frequencies 0-500Hz
%
lowp = designfilt('lowpassiir', 'FilterOrder', 8, 'PassbandFrequency', ...
     400, 'PassbandRipple', .2, 'SampleRate', fs);
y = filter(lowp, y);

% Frame and window Parameters. We round to nearest divisble by two number
%
% Window = Analysis window to consider
% Frame  = How much we shift our window by
%
winDur = .1; % in seconds
frmDur = 0; % in seconds
winLen = round(fs*winDur); % samples/sec*samples
frmLen = round(fs*frmDur); % samples

% Find the number of windows we will eventually have
%
winMax = 1+round(samL / winLen);

% Time between when we make a decision. (Decision interval)
decDur = 1; % in seconds

% Our window/frame analysis variables
%
indx_decWin = 1; % Index tracker for infomation we make at every decision
               % intervals
k = 1; % Keeps track of where we are in our buffer.
in_range = 1; % Keeps track if we have completed running windowing our sig
win_edge = 1; % Keeps track of what sample our window starts at
win_num = 1; % Keeps track of which window we are in
Fx_all_f = []; % Stores the frequencies of all the harmonic peaks 
                  % between decision intervals
F0_f = []; % Stores fundemental frequency value between decision intervals
energy_decWin = 0; % Keeps track of energy within decision intervals
winsam2_old = 1; % Holds the last edge of window between decision intervals

% Intilize array variables
%
buff = zeros(1,winMax+1);
while in_range
    % Define a variable for the sample the window contains
    %
    winsam = [win_edge win_edge+winLen];
    
    % Transfer signal into a windowed buffer. 
    %
    for j = winsam(1):winsam(2)
        % Account for end of data where window will exceed data
        %
        if j > length(y)
            y(j) = 0;
            % If we enter this code block, we have reached the end of the 
            % data set, so exit the while loop
            %
            in_range = 0;
        end
            
        % Transfer the signal into the windowed buffer
        %
        buff(k) = y(j);
        k = k + 1;
    end
    % Reset k
    %
    k = 1;
    
    % Find the total energy and add it to the sum of energy found within
    % our decesion window
    %
    energy_decWin = energy_decWin + sum(buff.^2);
    
    % Compute Autocorrelation for current window
    %
    win = window(@hamming, length(buff))';
    buff = buff.*win;
    buff = autocorr(buff, length(buff)-1);
    
    % Process the data in the window   
    % Compute the FFT
    %
    NFFT = length(buff);
    NFFT = 2^nextpow2(NFFT);
    X = fft(buff, NFFT)/NFFT;
    FTM = abs(X(1:NFFT/2+1));  % Truncate FFT to only fs/2
    f = fs/2*linspace(0,1,NFFT/2+1); % Create f vector
        
    % Find the peaks of our fft.
    %
    % Find the max peak fundemental frequency
    [F0_Max, F0_indx] = max(FTM);
    F0_f = [F0_f f(F0_indx)]; 
    
    [Fx_Amp, Fx_f] = findpeaks(FTM,f, 'MinPeakHeight', F0_Max*.4);
    Fx_all_f = [Fx_all_f Fx_f];
    
    % Make a decision every second or if we reach the end of signal
    %
    if ((mod(win_num, round(decDur/winDur)) == 0)|| (in_range == 0))
        % Compute mean of fundemental and harmonics seen between decision
        % interval
        %
        mean_F0(indx_decWin) = mean(F0_f);
        var_F0(indx_decWin) = var(F0_f);
        var_Fx_all(indx_decWin) = var(Fx_all_f);
        mean_Fx_all(indx_decWin)= mean(Fx_all_f);
        
        [win_identity(indx_decWin), coff(indx_decWin)] = classifyMaleFemaleWindow(...
            mean_F0(indx_decWin),...
            var_F0(indx_decWin), mean_Fx_all(indx_decWin),  ...
            var_Fx_all(indx_decWin));

        % Print the analysis window time frame we are currenlty looking at
        % to the console. 
        %
%         fprintf('From time = %0.2fs -> %0.2fs\n', ...
%             winsam2_old/fs, winsam(2)/fs);
        % If the energy is really low in the decision inteval we say there
        % is silence
        %
        if (energy_decWin < energy_sig*.25/100)
            area([winsam2_old/fs, winsam(2)/fs], ...
                [axisy(2) axisy(2)], 'FaceColor', [0 0 0],...
                'FaceAlpha', 0.2);
            %fprintf('\tDecision: Silence \n\n');
        % Else Classify based off the higher correlation
        %
        elseif (win_identity(indx_decWin)==0)
            % Overlay decision on signal plot
            area([winsam2_old/fs, winsam(2)/fs], ...
                [axisy(2) axisy(2)], 'FaceColor', [0.45 0.6 1],...
                'FaceAlpha', coff(indx_decWin)/105);
                text((winsam(2)/fs+winsam2_old/fs)/2,axisy(2)/2,...
                    [int2str(coff(indx_decWin)) '%'], ...
                    'HorizontalAlignment','center');
            % Print decision to console
            %fprintf('\tDecision: Male (Conf = %0.2f%%)\n\n', coff);
        else
            % Overlay decision on signal plot
            area([winsam2_old/fs, winsam(2)/fs], ...
                [axisy(2) axisy(2)], 'FaceColor', [1 0.6 .75],...
                'FaceAlpha', coff(indx_decWin)/105);
                text((winsam(2)/fs+winsam2_old/fs)/2,axisy(2)/2,...
                    [int2str(coff(indx_decWin)) '%'], ...
                    'HorizontalAlignment','center');
            %fprintf('\tDecision: Female (Conf = %0.2f%%)\n\n', coff);
        end
        
        % Increase the index tracker for decision window variables
        indx_decWin = indx_decWin + 1;
        winsam2_old = winsam(2);
        % Clear our fundemental frequency infomation
        %
        F0_f = [];
        Fx_all_f = [];
        
        % Clear energy found in decision interval
        %
        energy_decWin = 0;
    end
    
    % Move the window edge pointer for the next iteration
    %
    win_edge = winsam(2)-frmLen;
    win_num = win_num + 1;
end
% Find the most common identification and assign that identification
%
%identity = mode(win_identity);

% Display signal statistics
%
fprintf('Signal Statistics:\n');
fprintf('\tSignal Name = ''%s%s''\n',nameSig, fileEXT)
fprintf('\tSignal Legnth = %0.3f seconds\n',max(t));
fprintf('\tTotal Signal Energy = %0.3f V^2*sec\n',energy_sig);
% Print whether final decision is female or male
%
% if (identity==0)
%     % Final decision is male
%     fprintf('\tSignal Gender = Male\n\n');
% else
%     fprintf('\tSignal Gender = Female\n\n');
% end