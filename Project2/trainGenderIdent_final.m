% This program will read in a audio file and find the fundemental 
% and harmonics frequencies
%
function [F0_f_avg, Fx_f_avg, F0_f_var, Fx_f_var] = trainGenderIdent(fileN)

% Read in file
[sig, fs] = audioread(fileN);
samL = length(sig);

% Signals are mono so we remove the second channel 
%
sig = sig(:,1);

% Low pass the signal. We really only care about frequencies 0-500Hz
%
lowp = designfilt('lowpassiir', 'FilterOrder', 8, 'PassbandFrequency', ...
     400, 'PassbandRipple', .2, 'SampleRate', fs);
sig = filter(lowp, sig);

% Find total energy in the signal
%
energy_sig = sum(sig.^2);

% Frame and window Parameters. We round to nearest divisble by two number
%
% Window = Analysis window to consider
%
%
winDur = .1; % in seconds
frmDur = 0; % in seconds
winLen = round(fs*winDur); % samples/sec*sec
frmLen = round(fs*frmDur); % samples

% Find the number of windows we will eventually have
%
winMax = 1+round(samL / winLen);

% Our window/frame analysis variables
%
k = 1; % Keeps track of where we are in our buffer.
in_range = 1; % Keeps track if we have completed running windowing our sig
win_edge = 1; % Keeps track of what sample our window starts at
Fx_all_f = []; % Stores the frequencies of all the harmonic peaks 
                  % between decision intervals
F0_f = []; % Stores fundemental frequency value between decision intervals

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
        if j > length(sig)
            sig(j) = 0;
            % If we enter this code block, we have reached the end of the 
            % data set, so exit the while loop
            %
            in_range = 0;
        end
            
        % Transfer the signal into the windowed buffer
        %
        buff(k) = sig(j);
        k = k + 1;
    end
    % Reset k
    %
    k = 1;
    
    % Find the total energy in buffer
    %
    energy_buff = sum(buff.^2);
    
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
    
    % Keep data only if there is substantial energy in this portion of
    % the signal
    if(energy_buff > energy_sig*1/100)
        % Find the peaks of our fft.
        %
        % Find the max peak fundemental frequency
        [F0_Max, F0_indx] = max(FTM);
        F0_f = [F0_f f(F0_indx)]; 

        [Fx_Amp, Fx_f] = findpeaks(FTM,f, 'MinPeakHeight', F0_Max*.4);
        Fx_all_f = [Fx_all_f Fx_f];
    end
    % Move window
    %
    win_edge = winsam(2)-frmLen;
end

% Return output
%
F0_f_avg = mean(F0_f);
Fx_f_avg = mean(Fx_all_f);
F0_f_var = var(F0_f);
Fx_f_var = var(Fx_all_f);
