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
    
    % looping through small frames to get the excitation and OLA
    excitat = zeros([frameLengthSamples, 1]);
    
    % for lpc
    p = 100;                          % lpc coefficient order
    emphCoef = 0.99;                  % pre-emphasis coefficient
    A = zeros([numFrames2, p+1]);     % lpc coef matrix
    
    for frameNum2 = 1:numFrames2
        frameStart2 = (frameNum2-1)*hopSize2+1;
        frameEnd2 = (frameNum2-1)*hopSize2+frameLengthSamples2;
        
        % get the small frame
        frame2 = frame(frameStart2:frameEnd2);

        % pre-emphasis
        frame2 = filter([1 -emphCoef],1,frame2);    

        A(frameNum2,:) = lpc(frame2,p);           % get lpc coefficients
        frame2 = filter(A(frameNum2,:),1,frame2); % get excitation
        
        % apply window
        frame2 = apply_window(frame2);

        % overlap and add
        excitat(frameStart2:frameEnd2) = excitat(frameStart2:frameEnd2) + frame2;
    end
    
    if frameNum <= numFrames/2
        excitat = shiftPitch(excitat, 3, 'LockPhase',true);
    else
        excitat = shiftPitch(excitat, -4, 'LockPhase',true);
    end

    % looping through small frames to do lpc filtering
    filteredFrame = zeros([frameLengthSamples, 1]);
    for frameNum2 = 1:numFrames2
        frameStart2 = (frameNum2-1)*hopSize2+1;
        frameEnd2 = (frameNum2-1)*hopSize2+frameLengthSamples2;
        
        % get the small frame of excitation
        frame_ex = excitat(frameStart2:frameEnd2);
        
        % re-apply the original lpc coef
        frame2 = filter(1,A(frameNum2,:),frame_ex);

        % de-emphasis
        frame2 = filter(1,[1 -emphCoef],frame2);
        
        % apply window
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

%audiowrite("test.wav", audioOutput, fs);