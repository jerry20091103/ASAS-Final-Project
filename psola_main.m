% ASAS 2023 FALL 
% Final Project
% Group 6

% parameters
audioDir = './AudioFiles/';
filename = 'male_vocal2.wav';

[audioInput, fs] = audioread([audioDir, filename]);

N = length(audioInput);

% Shift pitch
audioOutput = psola_shift_pitch(audioInput, fs, semitone);
soundsc(audioOutput, fs)

%% store audio
str = sprintf('psola_output_%d.wav', semitone);
audiowrite(str, audioOutput, fs);