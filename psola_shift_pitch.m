%% Functions
% 1. psola_shift_pitch
% input:
%   signal: the input audio signal
%   fs: sampling rate
%   f_ratio: frequency ratio(the changing in semitone)
% output:
%   new_signal: audioOutput
function [new_signal] = psola_shift_pitch(signal, fs, f_ratio)
    % some parameters we can modifiy
    peaks = find_peaks(signal, fs, 1500, 50, 40, 1.3, 0.7);
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
        [~, I] = max(autoc(min_period: max_period));
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