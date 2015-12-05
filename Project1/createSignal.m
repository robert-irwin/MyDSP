%% variable sampling rate signals

clear;

% start by creating a 'full' sampling rate signal

fs = 44.1e3;            % define the 'full-rate' sampling rate
t = 0 : 1/fs : 15;      % define the time vector
x = 0*t;                % initialize "x" to all zeros

%% Create bursts
% each burst is creating on a region "r" that is defined as the range
% between two given times. "x" is defined as a cosine at a user specified
% frequency. The Blackman window smooths the edges of the burst.

r1 = (t>1 & t<4);
x1 = cos(2*pi*22*t(r1)) .* window(@blackman,sum(r1)).';

r2 = (t>5 & t<10);
x2 = cos(2*pi*11*t(r2)) .* window(@blackman,sum(r2)).';

r3 = (t>12 & t<15);
x3 = cos(2*pi*1.5*t(r3)) .* window(@blackman,sum(r3)).';

% add the bursts into the signal
x(r1) = x1;
x(r2) = x2;
x(r3) = x3;

% add a slowly varying background signal
x = x + 0.1*cos(2*pi*1*t);

%% Define variable sampling frequency

% Create an ideal instantaneous "dt" for each point in x by mapping regions
% of high variability (derivatives) to "maxFs" and low variability to
% "minFs"

% take the derivative of x: deriv = dx / dt
dt = 1/fs;
deriv = diff(x)/dt;

% define max and min Fs - I picked this number somewhat randomly - feel
% free to try others yourself
maxFs = 200;        % max Fs in Hz
minFs = 15;         % min Fs in Hz

% take the absolute value of the derivative and smooth it with a 1000-point
% moving average filter (this bit was a bit of a hack that I threw together
% to make the results work out a little more cleanly)

derivAbs = conv(abs(deriv) , ones(1,1000)/1000 , 'same');

% normalize derivAbs by mapping it into the range 0 to 1
xx = (derivAbs-min(derivAbs)) / (max(derivAbs)-min(derivAbs));

% define the new instantaneous sampling rates
fs_instantaneous = xx*(maxFs-minFs) + minFs;

% define the new instantaneous dt's
dt_instantaneous = 1./fs_instantaneous;

%% apply the variable sampling rate
% this section works by starting with the first point, adding the
% dt_instantaneous, and interpolating a value of "x" for that new time
% point. Then, figure out the next best "dt_instantaneous" for that new
% time point and repeat the process until the end of the signal is reached.


% allocate memory for y and t_resamp
y        = nan * x;
t_resamp = nan * t;

% assign the first value of y and t_resamp
y(1) = x(1);
t_resamp(1) = t(1);

% determine the current value of "dt"
dtCurr = dt_instantaneous(1);
tCurr = 0 + dtCurr;

% initialize the indexing variable
i = 2;

% continue until we reach the end of the "t" vector
while tCurr <= t(end)

    % define the new value of t_resamp
    t_resamp(i) = tCurr;

    % interpolate a new value of y at t = tCurr
    y(i) = interp1(t,x,tCurr);
    
    % figure out where we are in the "t" vector
    ind = find(t>=tCurr,1,'first');

    % update dtCurr with the value of dt_instantanous that corresponds to
    % the current time
    dtCurr = dt_instantaneous(ind);

    % update the current time by adding dtCurr
    tCurr = tCurr + dtCurr;
    
    % increment the indexing vector
    i = i + 1;
end

% remove all the values of t_resamp and y that don't have values assigned
% to them
r        = ~isnan(t_resamp);
t_resamp = t_resamp(r);
y        = y(r);

%% create plots to show results (optional: uncomment to see plots)

 figure(1);clf;
 plot(t,x,t_resamp,y);
 legend('orig','varsamp');
 xlabel('time (s)');
 title('original signal x(t) and variable fs version y(t)');

 figure(2);clf;
 [X f] = myFFT(x,fs);
 plot(f, 2*abs(X));
 xlim([0 30]);
 xlabel('freq (Hz)');
 title('FFT of original signal x(t)');
%%
fs = 50;

t_interpol = t_resamp(1):1/fs:t_resamp(length(t_resamp));
Vq = interp1(t_resamp,y,t_interpol, 'spline');
