%% create plot of inst fs
for i = 1:length(t_resamp)-1
    fs_vec(i) = 1/(t_resamp(i+1)-t_resamp(i));                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
end
figure(1);clf;
plot(t_resamp, [fs_vec(1) fs_vec], 'r')
title('Sampling Frequency as a Function of Time')
xlabel('time (sec)')
ylabel('Instantaneous fs (Hz)')
ylim([0 215])

%% create plot of yi(t) 
% vs_vec is defined above.
fs = max(fs_vec);
t_interpol = t_resamp(1):1/fs:t_resamp(length(t_resamp));
yi = interp1(t_resamp,y,t_interpol, 'spline');
figure(2); clf;
plot(t_interpol, yi, 'm')
xlabel('time (s)')
title('Signal yi(t) vs Time')
ylabel('Magnitude')
ylim([-1.25 1.25])

%% compute the FFT of yi(t)
L = length(yi);
% define a frequency vector
NFFT = 2^nextpow2(L);
[four_yi, f] = myFFT(yi, fs, NFFT); %compute fourier transform


figure(3); clf;
%plot(f,2*abs(four_Vq(1:NFFT/2+1)));
plot(f, 2*abs(four_yi), 'm')
title('FFT of yi(t)')
xlabel('frequency (Hz)');
ylabel('Magnitude')
xlim([0 25])

%% create the plot of the instantaneous fs for yi(t)
for i = 1:length(t_interpol)-1
    fsint_vec(i) = 1/(t_interpol(i+1)-t_interpol(i));                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
end
figure(1);clf;
plot(t_interpol, [fsint_vec(1) fsint_vec], 'm')
title('Sampling Frequency of yi(t) as a Function of Time')
xlabel('time (s)')
ylabel('Instantaneous fs (Hz)')
ylim([195 205])

%% demonstrate interpolation difference
%define a signal for comparison
t = linspace(0,1,200);
yorig = sin(2*pi.*t);

%show a slowly sampled version of ygood
tsam = linspace(0,1,7);
ysam = sin(2*pi.*tsam);

%do linear interpolation
tlin = tsam(1):1/300:tsam(length(tsam));
ylin = interp1(tsam,ysam,tlin,'linear');

%do spline interpolation
tspline = tsam(1):1/300:tsam(length(tsam));
yspline = interp1(tsam,ysam,tlin,'spline');

figure(1); clf;
plot(t, yorig, 'k--')
hold on
title('Interpolation Comparison')
xlabel('Time (s)')

scatter(tsam, ysam, 'k', 'filled')
plot(tlin,ylin, 'r')
plot(tspline, yspline, 'b')
legend('Original Signal', 'Samples of that Signal',...
    'Linear Interpolation', 'Cubic Spline Interpolation')

%% other plots

t_new = linspace(0,15,661500);
figure(3);clf;
plot(t_new, fs_instantaneous)
xlabel('Time (s)');
ylabel('Instantaneous fs (Hz)');
ylim([10 205]);
title('Sampling Frequency Vs. Time');

figure(4);clf;
plot(t_resamp, y,'r')
xlabel('Time (s)');
ylabel('Magnitude');
ylim([-1.25 1.25]);
title('Resampled Signal y(t) Vs. Time');

figure(5);clf;
[Y f1] = myFFT(y,200);
plot(abs(fft(y,1e6)),'r')
title('FFT of y(t)');
xlim([0 1e6/2])
ylim([0 100])

