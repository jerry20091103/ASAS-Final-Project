%% The main script for the project
% reads in audio and divided it into overlapping frames
clear; close all;

% parameters
audioDir = './AudioFiles/';
filename = 'male_vocal2.wav';
frameLengthSamples = 2048;

[audioInput, fs] = audioread([audioDir, filename]);

% listen to the audio
% soundsc(audioInput, fs);
% pause(length(audioInput)/fs);

hopSize = frameLengthSamples / 2;
numFrames = floor(length(audioInput) / hopSize) - 1;
audioInput = audioInput(1:(numFrames*hopSize + hopSize));

% set output array
audioOutput = zeros(size(audioInput));

% loop through the frames
for frameNum = 1:numFrames
    frameStart = (frameNum-1)*hopSize+1;
    frameEnd = (frameNum-1)*hopSize+frameLengthSamples;

    % get the current frame
    frame = audioInput(frameStart:frameEnd);

    % do processing here
    frame = lpc_pitchshift(frame, 2);
    
    % apply the window
    frame = apply_window(frame);
    
    % overlap and add
    audioOutput(frameStart:frameEnd) = audioOutput(frameStart:frameEnd) + frame;
end

% listen to the audio
soundsc(audioOutput, fs);