%%Tyler Olivieri 
%Gender Identification

clc;clear;clf; %clean up

%read in speech signals
%
[y, Fs] = audioread('clinton.mp3');
%[y1, Fs1]= audioread('couric.mp3');

%remove second column
%all zeros, from mono recording possibly, reading stereo?
%
y = y(:,1);

% lowpass filter the signal because were interested in fundamental freq
lowp = designfilt('lowpassiir', 'FilterOrder', 8, 'PassbandFrequency', 300,...
     'PassbandRipple', .2, 'SampleRate', Fs);
y = filter(lowp, y);


%plot time signal
%
% figure(1);
% stem(y)

% define frame and window in seconds
M = [Fs * .01]; %sam/sec * sec
N = [Fs * .01]; %sam/sec * sec

%M = [100];
%N = [1200];


% loop over the a set of frame/window combinations.
index2 = 1;



for m = 1:length(M)
    for n = 1:length(N)
        % local variables
       sig_a = y;
       fdur_a = M(m);
       wdur_a = N(n);
       sig_wbuf = zeros(1, wdur_a);
       num_samples = length(sig_a);
       num_frames = 1+round(num_samples / fdur_a);
       Rt = zeros(length(sig_a),1);
       high_ind = 1;
       winds_calc = 1;
       var_ind = 1;
       mean_ind = 1;
       end_sig = 0;
% loop over the entire signal
%
       for i = 1:num_frames
    
    % generate the pointers for how we will move through the data signal.
    % the center tells us where our frame is located and the ptr and right
    % indicate the reach of our window around that frame
    %
                n_center = (i - 1) * fdur_a + (fdur_a / 2);
                n_left = n_center - (wdur_a / 2);
                n_right = n_left + wdur_a ;
    
    % when the pointers exceed the index of the input data we won't be
    % adding enough samples to fill the full window. to solve this zero
    % stuffing will occur to ensure the buffer is always full of the same
    % number of samples
    %
                 if( (n_left < 0) || (n_right > num_samples) )
                     sig_wbuf = zeros(1, wdur_a);
                     %end of signal flag
                     end_sig = 1;
                 end
    
    % transfer the data to this buffer:
    %  note that this is really expensive computationally
    %
                 for j = 1:wdur_a
                    index = n_left + (j - 1);
                    if ((index > 0) && (index <= num_samples))
                        sig_wbuf(j) = sig_a(index);
                    end
                 end
                 
                 %calculate autocorrelation for current window
                 %
                 Rt = autocorr(sig_wbuf,wdur_a -1);
                 
                NFFT = 2^nextpow2(wdur_a); 
                X = fft(Rt, NFFT)/wdur_a;
                FTM = abs(X(1:NFFT/2+1)); % Truncate FFT to only fs/2
                f = Fs/2*linspace(0,1,NFFT/2+1); % Create f vector
                 
                 [peaks, locs] = findpeaks(FTM, f);
                 winds_calc = winds_calc+1;
                 %find the most prominent peaks
                 if size(locs) ~= [0 0]
                     
                    for count = 1:5
                        temp = max(peaks);
                        freq_index = find((peaks == temp),1);
                        if locs(freq_index) <= 300
                            high_loc(high_ind) = locs(freq_index);
                     
                            %set the current max to 0
                            peaks(freq_index) = 0;
                     
                            %increment the index
                            high_ind = high_ind + 1;
                        end
                    end
                 end
                 
                 %we will calculate the variance every 10 windows
                     loc_mean(mean_ind) = mean(high_loc);
                     %increment the index
                     mean_ind = mean_ind + 1;
                     if ((winds_calc == 10) || (end_sig == 1));
                        %reset the location index
                        loc_var(var_ind) = var(loc_mean);
                        high_ind = 1;
                        %reset the window index
                        winds_calc = 1;
                        %reset the mean index
                        mean_ind = 1;
                        %increment the variance count
                        var_ind = var_ind + 1;
                     end
                 
                 
                 % assign the mean/variance value to the output signal:
                 %  note that we write fdur_a values
                 %
                 %for j = 1:fdur_a
                    %index = n_center + (j - 1) - (fdur_a/2);
                    %if ((index > 0) && (index <= num_samples))
                        %Rt_full(index) = Rt;
                    %end
                 %end
         end
       
    
    end
end

