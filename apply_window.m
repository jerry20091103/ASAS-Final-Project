function outputData = apply_window(inputData)
% Applys hann window to the inputData and returns the result as outputData
% inputData: data to be windowed
% outputData: windowed data

    window = hann(length(inputData)+1);
    window = window(1:end-1);
    outputData = inputData .* window;
end
