% Digital Signal Processing (Fall 2015)
% Project 2: Predict whether a male/female is speaking in the mp3 file
% By: Tyler Olivieri; Devin Trejo; Robert Irwin

%% Training Female
clear;close all;

% Training data from:
% http://www.repository.voxforge1.org/downloads/
% Save to train folder (seperated by dirs male/female)

% Run training female files
%
trainDir = fullfile(pwd, 'data', 'female');
trainFiles = dir(fullfile(trainDir, '*.mp3'));
trainFiles = [trainFiles; dir(fullfile(trainDir, '*.wav'))];
F0_f_avg = [];
Fx_f_avg = [];
F0_f_var = [];
Fx_f_var = [];
for file = trainFiles'
    [F0i_f_avg, Fxi_f_avg, F0i_f_var, Fxi_f_var] = ...
        trainGenderIdent(fullfile(trainDir, file.name));
    F0_f_avg = [F0_f_avg F0i_f_avg];
    Fx_f_avg = [Fx_f_avg Fxi_f_avg];
    F0_f_var = [F0_f_var F0i_f_var];
    Fx_f_var = [Fx_f_var Fxi_f_var];
    clear F0i_f_avg Fxi_f_avg F0i_f_var Fxi_f_var; 
    clear F0_i Fx_i;
end

% fprintf('Female: \n\tF0 mu=%0.2f, std=%0.2f\n\tFx mu=%0.2f, std=%0.2f\n',...
%     mean(femaleF0), std(femaleF0), mean(femaleFx),std(femaleFx));
fprintf('Female: \n\tF0 meandiff=%0.2f, vardiff=%0.2f\n',...
    mean(Fx_f_avg-F0_f_avg),mean(abs(F0_f_var-Fx_f_var)));

% Save training output
%
%
dlmwrite(fullfile(pwd, 'train', 'out','female_F0avgdata.txt'),F0_f_avg);
dlmwrite(fullfile(pwd, 'train', 'out','female_Fxavgdata.txt'),Fx_f_avg);
dlmwrite(fullfile(pwd, 'train', 'out','female_F0vardata.txt'),F0_f_var);
dlmwrite(fullfile(pwd, 'train', 'out','female_Fxvardata.txt'),Fx_f_var);

clear trainFiles;

%% Training Male
clear; close all;
% Repeat for females
%
trainDir = fullfile(pwd,'data', 'male');
trainFiles = dir(fullfile(trainDir, '*.mp3'));
trainFiles = [trainFiles; dir(fullfile(trainDir, '*.wav'))];
F0_f_avg = [];
Fx_f_avg = [];
F0_f_var = [];
Fx_f_var = [];
for file = trainFiles'
    [F0i_f_avg, Fxi_f_avg, F0i_f_var, Fxi_f_var] = ...
        trainGenderIdent(fullfile(trainDir, file.name));
    F0_f_avg = [F0_f_avg F0i_f_avg];
    Fx_f_avg = [Fx_f_avg Fxi_f_avg];
    F0_f_var = [F0_f_var F0i_f_var];
    Fx_f_var = [Fx_f_var Fxi_f_var];
    clear F0i_f_avg Fxi_f_avg F0i_f_var Fxi_f_var; 
end
% fprintf('Male: \n\tF0 mu=%0.2f, std=%0.2f\n\tFx mu=%0.2f, std=%0.2f\n',...
%     mean(maleF0), std(maleF0), mean(maleFx),std(maleFx));
fprintf('Male: \n\tF0 meandiff=%0.2f, vardiff=%0.2f\n',...
    mean(Fx_f_avg-F0_f_avg),mean(abs(F0_f_var-Fx_f_var)));

% Save training output
%
dlmwrite(fullfile(pwd, 'train', 'out','male_F0avgdata.txt'),F0_f_avg);
dlmwrite(fullfile(pwd, 'train', 'out','male_Fxavgdata.txt'),Fx_f_avg);
dlmwrite(fullfile(pwd, 'train', 'out','male_F0vardata.txt'),F0_f_var);
dlmwrite(fullfile(pwd, 'train', 'out','male_Fxvardata.txt'),Fx_f_var);

%% Classfication
clear; clc; close all;

% Run Indentification
%
classDir = fullfile(pwd, 'data', 'male');
classFiles = dir(fullfile(classDir, '*.mp3'));
classFiles = [classFiles; dir(fullfile(classDir, '*.wav'))];

for file = classFiles'
    classifyMaleFemale(fullfile(classDir, file.name));
end


%% Unit testing
clear; clc; close all;
% Run unit testing
%
