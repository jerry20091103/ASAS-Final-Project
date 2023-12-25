%% function = lpc_pitchshift(inputFrame, shiftAmount)
% This function uses lpc to pitch-shift the excitation of the voice and
% re-apply the original lpc coefficients to keep the formants.
% 2023/12/23
%
% inputFrame: a square-windowed frame of a vocal data
% shiftAmount: the amount you want to pitch-shift in semitone
% return outputFrame: a square-windowed frame of the vocal that is
% pitch-shifted by the shiftAmount with the formants preserved

function outputFrame = lpc_pitchshift(inputFrame, shiftAmount)

% initalize parameters
frameLen = size(inputFrame);    % frame length in samples
p = 100;                        % lpc coefficient order
A = zeros(1,p+1);               % lpc coefficients
excitat = zeros(frameLen);      % excitation of the vocal
emphCoef = 0.99;                % pre-emphasis coefficient
outputFrame = zeros(frameLen);  % return

% pre-emphasis
inputFrameEmph = filter([1 -emphCoef],1,inputFrame);

% lpc
A = lpc(inputFrameEmph,p);                 % get coefficients
excitat = filter(A,1,inputFrameEmph);      % get excitation

% window for pitchshifter
window = rectwin(512);

% pitch-shift excitation
excitat = shiftPitch(excitat, shiftAmount, 'Window', window);

% re-apply cofficients
outputFrame = filter(1,A,excitat);

% de-emphasis
outputFrame = filter(1,[1 -emphCoef],outputFrame);

return 