% ASAS 2023 FALL 
% Final Project
% Group 2
% Tzu-Tsing Hung, Jih-Wei Yeh

% parameters
audioDir = './AudioFiles/';
filename = 'male_vocal2.wav';

[audioInput, fs] = audioread([audioDir, filename]);

N = length(audioInput);

f_ratio = 2^(3/12);

% Shift pitch
audioOutput = psola_shift_pitch(audioInput, fs, f_ratio);
soundsc(audioOutput, fs)

fprintf("Hi\n")

%% store audio
str = sprintf('psola_output_%d.wav', f_ratio);
audiowrite(str, audioOutput, fs);