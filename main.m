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

hopSize = frameLengthSamples / 2;
numFrames = floor(length(audioInput) / hopSize) - 1;
audioInput = audioInput(1:(numFrames*hopSize + hopSize));

% set output array
audioOutput = zeros(size(audioInput));

%
frameLengthSamples2 = 2048;
hopSize2 = frameLengthSamples2 / 2;
numFrames2 = floor(frameLengthSamples / hopSize2) - 1;

filteredFrame = zeros([frameLengthSamples,1]);
tic
% loop through the frames
for frameNum = 1:numFrames
    frameStart = (frameNum-1)*hopSize+1;
    frameEnd = (frameNum-1)*hopSize+frameLengthSamples;

    % get the current frame
    frame = audioInput(frameStart:frameEnd);
    
    % whattttttttt
    
    excitat = zeros([frameLengthSamples, 1]);
    for frameNum2 = 1:numFrames2
        frameStart2 = (frameNum2-1)*hopSize2+1;
        frameEnd2 = (frameNum2-1)*hopSize2+frameLengthSamples2;
        
        frame2 = frame(frameStart2:frameEnd2);

        p = 100;                         % lpc coefficient order
        emphCoef = 0.99;                % pre-emphasis coefficient
        frame2 = filter([1 -emphCoef],1,frame2);

        A = lpc(frame2,p);                 % get coefficients
        frame2 = filter(A,1,frame2);      % get excitation

        frame2 = apply_window(frame2);

        % overlap and add
        excitat(frameStart2:frameEnd2) = excitat(frameStart2:frameEnd2) + frame2;
    end
    
    if frameNum <= numFrames/2
        excitat = shiftPitch(excitat, 3, 'LockPhase',true);
    else
        excitat = shiftPitch(excitat, -3, 'LockPhase',true);
    end
    audiowrite("exc.wav", excitat, fs);
    filteredFrame = zeros([frameLengthSamples, 1]);
    for frameNum2 = 1:numFrames2
        frameStart2 = (frameNum2-1)*hopSize2+1;
        frameEnd2 = (frameNum2-1)*hopSize2+frameLengthSamples2;
        
        frame2 = frame(frameStart2:frameEnd2);
        frame_ex = excitat(frameStart2:frameEnd2);

        p = 100;                         % lpc coefficient order
        emphCoef = 0.99;                % pre-emphasis coefficient
        frame2 = filter([1 -emphCoef],1,frame2);

        A = lpc(frame2,p);                 % get coefficients

        frame2 = filter(1,A,frame_ex);

        frame2 = filter(1,[1 -emphCoef],frame2);

        frame2 = apply_window(frame2);

       
        % overlap and add
        filteredFrame(frameStart2:frameEnd2) = filteredFrame(frameStart2:frameEnd2) + frame2;
    end
    
    % apply the window
    filteredFrame = apply_window(filteredFrame);
    
    % overlap and add
    audioOutput(frameStart:frameEnd) = audioOutput(frameStart:frameEnd) + filteredFrame;
end
toc
% listen to the audio
soundsc(audioOutput, fs);

audiowrite("test.wav", audioOutput, fs);