% Digital Signal Processing (Fall 2015)
% Project 2: Predict whether a male/female is speaking in the mp3 file
% Classificaiton by window function
% By: Tyler Olivieri; Devin Trejo; Robert Irwin

% Returns 0 for male, 1 for female
function [win_identity, coff] = classifyMaleFemaleWindow(F0_mean,...
    F0_var, Fx_mean, Fxvar)

% Read in training results
%
maleF0_f_avg = dlmread(fullfile(pwd, 'train', 'out','male_F0avgdata.txt'));
maleFx_f_avg = dlmread(fullfile(pwd, 'train', 'out','male_Fxavgdata.txt'));
maleF0_f_var = dlmread(fullfile(pwd, 'train', 'out','male_F0vardata.txt'));
maleFx_f_var = dlmread(fullfile(pwd, 'train', 'out','male_Fxvardata.txt'));

femaleF0_f_avg = dlmread(fullfile(pwd, 'train', 'out','female_F0avgdata.txt'));
femaleFx_f_avg = dlmread(fullfile(pwd, 'train', 'out','female_Fxavgdata.txt'));
femaleF0_f_var = dlmread(fullfile(pwd, 'train', 'out','female_F0vardata.txt'));
femaleFx_f_var = dlmread(fullfile(pwd, 'train', 'out','female_Fxvardata.txt'));

% Generate classifier
%
MALE1 = mean(maleFx_f_avg-maleF0_f_avg);
MALE2 = mean(abs(maleFx_f_var-maleF0_f_var));
FEMALE1 = mean(femaleFx_f_avg-femaleF0_f_avg);
FEMALE2 = mean(abs(femaleFx_f_var-femaleF0_f_var));

MALE = [MALE1 MALE2];
FEMALE = [FEMALE1 FEMALE2];

%generate a line for classification
%change in x
dx1 = FEMALE(1)-MALE(1);
dx2 = FEMALE(2)-MALE(2);

mid1 = (FEMALE(1)+MALE(1))/2;
mid2 = (FEMALE(2)+MALE(2))/2;

%we want the range to be 100 [-50 50]
m1 = 100/dx1;
m2 = 100/dx2;

VAR = abs(Fxvar - F0_var);
MEAN = Fx_mean - F0_mean;

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
% Make Decision
%
coff = ymean+yvar;
if(coff > 0)
    win_identity = 1;
else
    win_identity = 0;
end

% Coff to absolute
coff = abs(coff);
