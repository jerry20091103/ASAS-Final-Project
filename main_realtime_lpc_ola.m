clear;

Key.C = 0;
Key.CSharp = 1;
Key.D = 2;
Key.DSharp = 3;
Key.E = 4;
Key.F = 5;
Key.FSharp = 6;
Key.G = 7;
Key.GSharp = 8;
Key.A = 9;
Key.ASharp = 10;
Key.B = 11;

% Set up parameters
frameLengthSamples = 2048*4;
fs = 44100;

% index for the big frame

% Create an audio input and output object
inputDevice = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameLengthSamples);
outputDevice = audioDeviceWriter('SampleRate', fs);
fileWriter = dsp.AudioFileWriter(SampleRate=outputDevice.SampleRate);


inputBuffer = zeros(frameLengthSamples, 1);    % Display buffer is a first in first out queue
timeAxis = [0:1/fs:(frameLengthSamples-1)/fs]; % Time axis of the display buffer

numFrame = 1000;
currentFrame = zeros(frameLengthSamples, 1);
prevFrame = zeros(frameLengthSamples, 1);
nextFrame = zeros(frameLengthSamples, 1);
outputFrame = zeros(frameLengthSamples*3, 1);

%% Main processing loop
for i = 1:numFrame
    % Read a frame of audio data
    audioInput = inputDevice();
    
    % update prevFrame
    prevFrame = currentFrame;

    % update currentFrame
    currentFrame = nextFrame;

    %toc
    % Add data to display buffer
    if i <= frameLengthSamples
        nextFrame = audioInput;
    else
        nextFrame = [nextFrame(2:end) audioInput]; % first in first out
    end
    
    % reset outputFrame
    outputFrame = zeros(frameLengthSamples*3, 1);
    
    % two windows for OLA
    frame1 = apply_window([prevFrame;currentFrame]) + 0.000001;
    frame2 = apply_window([currentFrame;nextFrame]) + 0.000001;
    
    % pitch up both frame
    semitone = get_shift_amount(frame2, fs, Key.C, 3);
    frame1 = lpc_pitchshift(frame1, semitone);
    frame2 = lpc_pitchshift(frame2, semitone);
    
    % OLA
    outputFrame(1:frameLengthSamples*2) = frame1;
    outputFrame(end-frameLengthSamples*2+1:end) = outputFrame(end-frameLengthSamples*2+1:end) + frame2;

    % select only the middle frame for output
    outputFrame = outputFrame(frameLengthSamples + 1:end - frameLengthSamples);
    
    % write the processed frame to the output
    outputDevice(outputFrame);
    %fileWriter(outputFrame);
end

% Release the audio devices
release(inputDevice);
release(outputDevice);