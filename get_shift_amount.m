function shiftAmount = get_shift_amount(inputFrame, fs, key, interval)
%Calculate the shift amount for the given inputFrame, according to the given key and interval
% inputFrame: the audio frame to be analysized
% fs: (integer) the sampling rate of the inputFrame
% key: (Keys enum) the key of the inputFrame 
% interval: (integer) the interval to be shifted I->1, II->2, III->3, IV->4, V->5, VI->6, VII->7...
% shiftAmount: (integer) the calculated shift amount in semitones, returns -1 if the result is invalid

    % parameters
    LOW_NOTE = 40; % the lowest note to be detected (in midi note number)
    HIGH_NOTE = 100; % the highest note to be detected (in midi note number)
    % detect the pitch of the inputFrame
    freq = pitch(inputFrame, fs);
    % convert the frequency to midi note number (69 is A4 = 440Hz)
    midiNote = 12 * log2(freq / 440) + 69;
    if midiNote < LOW_NOTE | midiNote > HIGH_NOTE
        shiftAmount = -1;
        return;
    end
    % round the midiNote to the nearest majot note in the given key
    % first shift the note to C major
    midiNote = midiNote - key;
    % and convert it to 0-11 (range of a octave)
    midiNote = mod(midiNote, 12);
    % then round it to the nearest major note (0, 2, 4, 5, 7, 9, 11)
    if midiNote < 1
        detectedNote = 0; % C
    elseif midiNote < 3
        detectedNote = 1; % D
    elseif midiNote < 4.5
        detectedNote = 2; % E
    elseif midiNote < 6
        detectedNote = 3; % F
    elseif midiNote < 8
        detectedNote = 4; % G
    elseif midiNote < 10
        detectedNote = 5; % A
    elseif midiNote < 11.5
        detectedNote = 6; % B
    else
        detectedNote = 0; % C
    end
    % calculate the shift amount
    noteDistance = [2, 2, 1, 2, 2, 2, 1]; % the distance between each note in a major scale
    shiftAmount = 0;
    if interval > 0
        for i = 1:interval-1
            shiftAmount = shiftAmount + noteDistance(mod(detectedNote + i - 1, 7) + 1);
        end
    else
        for i = 1:(-interval)-1
            shiftAmount = shiftAmount - noteDistance(mod(detectedNote - i - 1 + 7, 7) + 1);
        end
    end
end