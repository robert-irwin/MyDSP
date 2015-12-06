clear;clc;

%generate classifier
Male1 = .9903;
Male2 = 1.2762e3;
Female1 = 17.6844;
Female2 = 2.6318e3;
%create a normal distribution from the mean and variance
ymclass = sqrt( Male2 ) .* randn(1000,1) + Male1;
yfclass = sqrt( Female2 ) .* randn(1000,1) + Female1;

ymclass = sort(ymclass,'ascend');
yfclass = sort(yfclass,'ascend');

normm = fitdist(ymclass,'Normal');
normf = fitdist(yfclass,'Normal');

classm = pdf(normm,ymclass);
classf = pdf(normf,yfclass);


%read in speech signals
%
count = 1;
[y, Fs] = audioread('bush.mp3');
% file = audioplayer(y,Fs);
% file.play
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
    win_num = win_num + 1;
    
    %move the window for the next iteration
    win_edge = winsam(2)-overlap;
    
    %pdf 
    %
    total_peak_energy = sum(peaks);
    normalized_peaks = peaks./total_peak_energy;
    mean_normalized_peaks = mean(normalized_peaks);
    
    %find what normalized_peaks value is closest to mean_normalized_peaks
    %
    tmp = abs(mean_normalized_peaks - normalized_peaks); %subtract peaks
    
    %the minimum would then indicate the closest value
    %grab that index
    %
    [~, idx] = min(tmp); 
    
    %use the index to get peak and location
    %
    closest_value = peaks(idx);
    closest_loc = locs(idx);
    
    %make a decision once a second
    if ((win_num == round(1/window_duration)) || (in_range == 0))
        F0(count) = mean(F0_win);
        var_F0(count) = var(F0_win);
        var_all_locs(count) = var(all_locs(2:length(all_locs)));
        mean_all_locs(count)= mean(all_locs(2:length(all_locs)));
        
        %get estimator mean and variance
        VAR = abs(var_all_locs(count) - var_F0(count));
        MEAN = mean_all_locs(count) - F0(count);
        
        yest = sqrt( VAR ) .* randn(1000,1) + MEAN;
        yest = sort(yest,'ascend');
        normest = fitdist(yest,'Normal');
        est = pdf(normest,yest);
        male = xcorr(classm,yest);
        female = xcorr(classf,yest);
        male = male./sum(male);
        female = female./sum(female);
        maxm = max(male);
        maxf = max(female);
        
        fprintf('Decision at %ds\n',winsam(2)/Fs);
        %classify based off the higher correlation
        if maxm > maxf
            fprintf('Male: Conf = %d\n\n', maxm*100);
        else
            fprintf('Female: Conf = %d\n\n', maxf*100);
        end
        %get classifiers
%         VAR(count) = var_all_locs(count) - var_F0(count);
%         MEAN(count) = mean_all_locs(count)-F0(count);
%         fprintf('Decision at %ds\n',winsam(2)/Fs);
%         if mean_all_locs(count) < F0(count)
%             fprintf('Male\n\n')
%             
%         elseif (var_all_locs(count)-var_F0(count)) < 800
%             fprintf('Male\n\n')
%             
%         elseif (mean_all_locs(count)-F0(count)) < 5
%             fprintf('Male\n\n')
%             
%         else
%             fprintf('Female\n\n')
%             
%         end
%         %reset counters and variables
        win_num = 1;
        all_locs = -1;
        F0_win = 0;
        count = count+1;
    end
end
% mean(VAR)
% mean(MEAN)