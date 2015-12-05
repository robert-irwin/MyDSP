clear;clc;
%read in speech signals
%
[y, Fs] = audioread('.wav');
file = audioplayer(y,Fs);
file.play
%remove second column
%all zeros, from mono recording possibly, reading stereo?
%
y = y(:,1);

lowp = designfilt('lowpassiir', 'FilterOrder', 8, 'PassbandFrequency', 400,...
     'PassbandRipple', .2, 'SampleRate', Fs);
y = filter(lowp, y);

window_duration = .1; %in seconds
overlap_duration = 0; %in seconds
winlen = round(Fs*window_duration); % samples/sec*samples

% we also need to define an overlap
overlap = round(Fs*overlap_duration); % samples
%initialize a counter
k = 1;

in_range = 1;
win_edge = 1;
win_num = 1;
all_locs = [-1];

while in_range
    %define a variable for the sample the window contains
    winsam = [win_edge win_edge+winlen];

    for j = winsam(1):winsam(2)
        
        %account for end of data where window will exceed data
        if j > length(y)
            y(j) = 0;
            %if we enter this code block, we have reached the end of the 
            %data set, so exit the while loop
            in_range = 0;
        end
            
        %obtain the data in the window
        temp(k) = y(j);
        k = k+1;
    end
    %reset k
    k = 1;
    win = window(@hamming, length(temp))';
    temp = temp.*win;
    temp = autocorr(temp, length(temp)-1);
    %process the data in the window
    NFFT = length(temp);
    NFFT = 2^nextpow2(NFFT);
    X = fft(temp, NFFT)/NFFT;
    FTM = abs(X(1:NFFT/2+1)); % Truncate FFT to only fs/2
    f = Fs/2*linspace(0,1,NFFT/2+1); % Create f vector
    [max_amp, max_index] = max(FTM);
    F0_win(win_num) = f(max_index);
    [peaks, locs] = findpeaks(FTM,f, 'MinPeakHeight', max_amp*.5);
    all_locs = [all_locs locs];
    win_num = win_num + 1;
    %move the window for the next iteration
    win_edge = winsam(2)-overlap;
    
end

F0 = mean(F0_win)
var_F0 = var(F0_win)
var_all_locs = var(all_locs(2:length(all_locs)))
mean_all_locs= mean(all_locs(2:length(all_locs)))

if mean_all_locs < F0
    disp('Male')
elseif (var_all_locs-var_F0) < 800
    disp('Male')
elseif (mean_all_locs-F0) < 5
    disp('Male')
else
    disp('Female')
end