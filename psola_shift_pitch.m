%{
Author: Sanna Wager
Created on: 9/18/19

This script provides an implementation of pitch shifting using the "time-domain pitch synchronous
overlap and add (TD-PSOLA)" algorithm. The original PSOLA algorithm was introduced in [1].

Description
The main script td_psola.py takes raw audio as input and applies steps similar to those described in [2].
First, it locates the time-domain peaks using auto-correlation. It then shifts windows centered at the
peaks closer or further apart in time to change the periodicity of the signal, which shifts the pitch
without affecting the formant. It applies linear cross-fading as introduced in [3] and implemented in
[4], the algorithm used for Audacity's simple pitch shifter.

Notes:
- Some parameters in the program related to frequency are hardcoded for singing voice. They can be
    adjusted for other usages.
- The program is designed to process sounds whose pitch does not vary too much, as this could result
    in glitches in peak detection (e.g., octave errors). Processing audio in short segment (e.g.,
    notes or words) is recommended. Another option would be to use a more robust peak detection
    algorithm, for example, pYIN [5]
- Small pitch shifts (e.g., up to 700 cents) should not produce many artifacts. Sound quality degrades
    if the shift is too large.
- The signal is expected to be voiced. Unexpected results may occur in the case of unvoiced signals

References:
Overlap and add algorithm exercise from UIUC
[1] F. Charpentier and M. Stella. "Diphone synthesis using an overlap-add technique for speech waveforms
    concatenation." In Int. Conf. Acoustics, Speech, and Signal Processing (ICASSP). Vol. 11. IEEE, 1986.
[2] https://courses.engr.illinois.edu/ece420/lab5/lab/#overlap-add-algorithm
[3] https://www.surina.net/article/time-and-pitch-scaling.html
[4] https://gitlab.com/soundtouch
[5] https://code.soundsoftware.ac.uk/projects/pyin
%}

%% Functions
% 1. psola_shift_pitch
% input:
%   signal: the input audio signal
%   fs: sampling rate
%   f_ratio: frequency ratio(the changing in semitone)
% output:
%   new_signal: audioOutput
function [new_signal] = psola_shift_pitch(signal, fs, semitone)
    % some parameters we can modifiy
    peaks = find_peaks(signal, fs, 1500, 50, 40, 1.3, 0.7);
    f_ratio = 2^(semitone/12);
    new_signal = psola(signal, peaks, f_ratio);
end

%%
% 2. find_peaks
% input:
%   signal: the input audio signal
%   fs: sampling rate
%   max_hz: maximum frequency
%   min_hz: minimum frequency
%   analysis_win_ms: analysis window length in ms
%   max_change: maximum change in period length
%   min_change: minimum change in period length
% output:
%   peaks: the peaks of the signal, which store the index of the peaks
function [peaks] = find_peaks(signal, fs, max_hz, ...
        min_hz, analysis_win_ms, max_change, min_change)

    
    N = length(signal);
    min_period = fix(fs/max_hz); % unit: samples
    max_period = fix(fs/min_hz); % unit: samples

    % compute pitch periodicity
    sequence = round(analysis_win_ms / 1000 * fs);  % analysis sequence length in samples
    periods = compute_periods_per_sequence(signal, sequence, min_period, max_period);

    % find the peaks
    [~, I] = max(signal(1:round(periods(1)*1.1)));
    peaks = (I);
    while true
        prev = peaks(end);
        idx = ceil(prev/sequence);  % current autocorrelation analysis window
        if prev + fix(periods(idx) * max_change) > N
            break
        end
        % find maximum near expected location
        % print(int(periods[idx] * max_change)-int(periods[idx] * min_change))
        [~, I] = max(signal(prev + round(periods(idx) * min_change): prev + round(periods(idx) * max_change)));
        peaks(end+1) = prev + round(periods(idx) * min_change) + I;
    end
end

%%
% 3. compute_periods_per_sequence
% input:
%   signal: the input audio signal
%   sequence: analysis sequence length in samples
%   min_period: minimum period length in samples
%   max_period: maximum period length in samples
% output:
%   periods: the period length of each analysis sequence, which store the index
function [periods] = compute_periods_per_sequence(signal, sequence, min_period, max_period)
    N = length(signal);
    offset = 1;  % current sample offset
    periods = [];  % period length of each analysis sequence
    while offset <= N
        if offset + sequence > length(signal)
            fourier = fft(signal(offset:end));
        else
            fourier = fft(signal(offset: offset + sequence));
        end
        fourier(1) = 0;  % remove DC component
        autoc = ifft(fourier.*conj(fourier)); % auto-correlation in time <=> conjugate multiplication in frequency
        max_period_limit = min(max_period, length(autoc));
        [~, I] = max(autoc(min_period: max_period_limit));
        autoc_peak = min_period + I;
        periods(end+1) = autoc_peak;
        offset = offset + sequence;
    end
end

%%
% 4. psola
% input:
%   signal: the input audio signal
%   peaks: the peaks of the signal, which store the index of the peaks
%   f_ratio: frequency ratio(the changing in semitone)
% output:
%   new_signal: the output audio signal
function [new_signal] = psola(signal, peaks, f_ratio)
    N = length(signal);
    % Interpolate
    new_signal = zeros(N, 1);
    new_peaks_ref = linspace(1, length(peaks), round(length(peaks) * f_ratio));
    new_peaks = zeros(length(new_peaks_ref), 1);

    for i = 1:length(new_peaks)
        weight = mod(new_peaks_ref(i), 1);
        left = floor(new_peaks_ref(i));
        right = ceil(new_peaks_ref(i));
        new_peaks(i) = round(peaks(left) * (1 - weight) + peaks(right) * weight);
    end
    % PSOLA
    for j = 1:length(new_peaks)
        % find the corresponding old peak index
        [~, i] = min(abs(peaks - new_peaks(j)));
        % get the distances to adjacent peaks
        if j == 1
            P1(1) = new_peaks(j);
        else
            P1(1) = new_peaks(j) - new_peaks(j-1);
        end
        if j == length(new_peaks)
            P1(2) = N - new_peaks(j);
        else
            P1(2) = new_peaks(j+1) - new_peaks(j);
        end
        % edge case truncation
        if peaks(i) - P1(1) < 1
            P1(1) = peaks(i);
        end
        if peaks(i) + P1(2) > N
            P1(2) = N - peaks(i);
        end
        % linear OLA window
        tempA = linspace(0, 1, P1(1) + 1);
        tempB = linspace(1, 0, P1(2) + 1);
        window = [tempA(2:end), tempB(2:end)]';
        % center window from original signal at the new peak
        new_signal(new_peaks(j) - P1(1) + 1: new_peaks(j) + P1(2)) = ...
            new_signal(new_peaks(j) - P1(1) + 1: new_peaks(j) + P1(2)) ...
            + window .* signal(peaks(i) - P1(1) + 1: peaks(i) + P1(2));
    end
end