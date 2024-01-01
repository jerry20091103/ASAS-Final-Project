%% function = lpc_pitchshift(inputFrame, shiftAmount)
% This function uses lpc to pitch-shift the excitation of the voice and
% re-apply the original lpc coefficients to keep the formants.
% 2023/12/23
%
% inputFrame: a square-windowed frame of a vocal data
% shiftAmount: the amount you want to pitch-shift in semitone
% formantShift: the amount you want to shift the formant in semitone
% return outputFrame: a square-windowed frame of the vocal that is
% pitch-shifted by the shiftAmount with the formants preserved

function outputFrame = lpc_pitchshift(inputFrame, shiftAmount, formantShift)

% initalize parameters
frameLengthSamples = size(inputFrame);    % frame length in samples
p = 100;                        % lpc coefficient order
A = zeros(1,p+1);               % lpc coefficients
excitat = zeros(frameLengthSamples);      % excitation of the vocal
emphCoef = 0.99;                % pre-emphasis coefficient
outputFrame = zeros([frameLengthSamples, 1]);  % return

%
frameLengthSamples2 = 2048;
hopSize2 = frameLengthSamples2 / 2;
numFrames2 = floor(frameLengthSamples / hopSize2) - 1;

if formantShift ~= 0
    inputFrameShifted = shiftPitch(inputFrame, formantShift, 'LockPhase',true);
end


for frameNum2 = 1:numFrames2
    frameStart2 = (frameNum2-1)*hopSize2+1;
    frameEnd2 = (frameNum2-1)*hopSize2+frameLengthSamples2;
        
    % get the small frame
    frame2 = inputFrame(frameStart2:frameEnd2);
    if formantShift ~= 0
        frame2Shifted = inputFrameShifted(frameStart2:frameEnd2);
    end

    % pre-emphasis
    frame2 = filter([1 -emphCoef],1,frame2);
    if formantShift ~= 0
        frame2Shifted = filter([1 -emphCoef],1,frame2Shifted);
    end

    A(frameNum2,:) = lpc(frame2,p);           % get lpc coefficients
    frame2 = filter(A(frameNum2,:),1,frame2); % get excitation

    % use the shifted frame to get the coefficients
    if formantShift ~= 0
        A(frameNum2,:) = lpc(frame2Shifted,p);    % get shifted lpc coefficients
    end
        
    % apply window
    frame2 = apply_window(frame2);

    % overlap and add
    excitat(frameStart2:frameEnd2) = excitat(frameStart2:frameEnd2) + frame2;
end

% pitch shift excitation
excitat = shiftPitch(excitat, shiftAmount, 'LockPhase',true);

% looping through small frames to do lpc filtering
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
    outputFrame(frameStart2:frameEnd2) = outputFrame(frameStart2:frameEnd2) + frame2;
end

return 