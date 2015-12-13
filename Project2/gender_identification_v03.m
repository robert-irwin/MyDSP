clear;clc;

%generate classifier
%MALE = [.9903 1.2762e3];
%FEMALE = [17.6844 2.6318e3];

MALE = [-2.4907 1.28e3];  
FEMALE = [11.54 1.963e3];
%generate a line for classification
%change in x
dx1 = FEMALE(1)-MALE(1);
dx2 = FEMALE(2)-MALE(2);

mid1 = (FEMALE(1)+MALE(1))/2;
mid2 = (FEMALE(2)+MALE(2))/2;

%we want the range to be 100 [-50 50]
m1 = 100/dx1;
m2 = 100/dx2;


%read in speech signals
%
count = 1;
[y, Fs] = audioread('Male 1.wav');
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
    [peaks, locs] = findpeaks(FTM,f, 'MinPeakHeight', max_amp*.4);
    all_locs = [all_locs locs];
    %win_num = win_num + 1;
    
    %move the window for the next iteration
    win_edge = winsam(2)-overlap;
    
    
    
    %make a decision once a second
    if ((win_num == round(1/window_duration)) || (in_range == 0))
        F0(count) = mean(F0_win);
        var_F0(count) = var(F0_win);
        var_all_locs(count) = var(all_locs(2:length(all_locs)));
        mean_all_locs(count)= mean(all_locs(2:length(all_locs)));
        
        %get estimator mean and variance
        VAR = abs(var_all_locs(count) - var_F0(count));
        MEAN = mean_all_locs(count) - F0(count);
        
        %begin making decision
        if MEAN >= mid1
            if MEAN <= FEMALE(1)
                ymean = m1*(MEAN-mid1);
            else
                ymean = 50;
            end
        else
            if MEAN >= MALE(1)
                ymean = m1*(MEAN-mid1);
            else
                ymean = -50;
            end
        end
        
        if VAR >= mid2
            if VAR <= FEMALE(2)
                yvar = m2*(VAR-mid2);
            else
                yvar = 50;
            end
        else
            if VAR >= MALE(2)
                yvar = m2*(VAR-mid2);
            else
                yvar = -50;
            end
        end
        
        fprintf('Decision at %.4fs\n',winsam(2)/Fs);
       
        %make decision
        dec = ymean+yvar;
        if dec > 0
            fprintf('Female: %.4f percent confident\n\n', dec);
        elseif dec < 0
            fprintf('Male: %.4f percent confident\n\n', abs(dec));
        else
            fprintf('Male: %.4f percent confident\n\n', .001');
        end
           
        
%         %reset counters and variables
        win_num = 1;
        all_locs = -1;
        F0_win = 0;
        count = count+1;
        continue
    end
    win_num = win_num+1;
end
