%% The main script for the project
% reads in audio and divided it into overlapping frames
clear; close all;

% parameters
audioDir = './';
filename = 'male_vocal2.wav';
frameLengthSamples = 2048*8;

[audioInput, fs] = audioread([audioDir, filename]);
audioInput = audioInput(1:end,1);

% listen to the audio
% soundsc(audioInput, fs);
% pause(length(audioInput)/fs);

% index for the big frame
hopSize = frameLengthSamples / 2;
numFrames = floor(length(audioInput) / hopSize) - 1;
audioInput = audioInput(1:(numFrames*hopSize + hopSize));

% set output array
audioOutput = zeros(size(audioInput));

% index for the small frame
frameLengthSamples2 = 2048;
hopSize2 = frameLengthSamples2 / 2;
numFrames2 = floor(frameLengthSamples / hopSize2) - 1;

tic
% loop through the frames
for frameNum = 1:numFrames
    frameStart = (frameNum-1)*hopSize+1;
    frameEnd = (frameNum-1)*hopSize+frameLengthSamples;

    % get the current frame
    frame = audioInput(frameStart:frameEnd);
    
    % lpc pitch shift
    filteredFrame = lpc_pitchshift(frame, shiftAmount);
    
    % apply the window
    filteredFrame = apply_window(filteredFrame);
    
    % overlap and add
    audioOutput(frameStart:frameEnd) = audioOutput(frameStart:frameEnd) + filteredFrame;
end
toc
% listen to the audio
soundsc(audioOutput, fs);

%audiowrite("test.wav", audioOutput, fs);