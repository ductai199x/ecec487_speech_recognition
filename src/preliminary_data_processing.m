clear, clc, close all
% delete(gcp('nocreate'))
tic
%% Find all audio training files

current_path = strcat(mfilename('fullpath'), '.m');

[path,~,~] = fileparts(current_path);
path = strrep(path,'src','data/TRAIN/');
% path = '~/Desktop/TIMIT/TIMIT/TRAIN/';

train_folder_path = dir(fullfile(path));

files = [];
labels = [];

parfor i = 1:length(train_folder_path)
    if strcmp(train_folder_path(i).name, '.') || strcmp(train_folder_path(i).name, '..')
        continue
    end
    temp_path = dir(fullfile(strcat(path, train_folder_path(i).name)));
    for j = 1:length(temp_path)
        if strcmp(temp_path(j).name, '.') || strcmp(temp_path(j).name, '..')
            continue
        end
        labels = [labels; temp_path(j).name];
        folders = strcat(path, train_folder_path(i).name, '/', temp_path(j).name);
        files = [files; dir(fullfile(folders, '/*.WAV'))];
    end
end


%% Import all training data

training_data = cell(size(files, 1),3);
N = length(training_data);
Fs = 16000;

% for i=1:size(files, 1)
for i=1:N
    [x, ~] = audioread(strcat(files(i).folder, '/', files(i).name));
    training_data{i}{1} = x;
    training_data{i}{3} = labels(floor(i/10) + 1);
end


%% Do speech detection and silence clipping

% parpool('local', 6);
parfor i=1:N
    audio = training_data{i}{1};
    timeVector = (1/Fs) * (0:numel(audio)-1);
    audio = audio ./ max(abs(audio));           % Normalize amplitude
    windowLength = 50e-3 * Fs;
    segments = buffer(audio,windowLength);      % Break the audio into 50-millisecond non-overlapping frames
%     win = hann(windowLength,'periodic');
    win = hamming(windowLength,'periodic');
    signalEnergy = sum(segments.^2,1)/windowLength;
    
%   centroid = SpectralCentroid(audio,windowLength,windowLength,Fs); % Use this when run with MATLAB < 2019
    centroid = spectralCentroid(segments, Fs, 'Window', win, 'OverlapLength', 0);
    T_E = mean(signalEnergy)/2;
    T_C = 5000;
    isSpeechRegion = (signalEnergy >= T_E) & (centroid <= T_C);
%   isSpeechRegion = isSpeechRegion(1,:);       % Use this when run with MATLAB < 2019
    CC = repmat(centroid, windowLength, 1);
    CC = CC(:);
    EE = repmat(signalEnergy, windowLength, 1);
    EE = EE(:);
    flags2 = repmat(isSpeechRegion, windowLength, 1);
    flags2 = flags2(:);
    
    clipped_audio = audio(flags2 > 0);
    training_data{i}{1} = clipped_audio;
    
    fftVal = abs(fft(clipped_audio, 64));       % take 63 point FFT of signal and get magnitudes of the frequency components, increase number of points as you might require more frequency samples
    mags = fftshift(fftVal);                    % perform an FFT shift to shift the negative frequencies
    freqs = linspace(-Fs/2, Fs/2, length(mags))'; % create a proper frequency axis depending on the FFT length
    mags(freqs < 0) = 0;
    mergedData = [freqs, mags];                 % merge the frequency data and magnitude data into a Nx2 matrix
    sortedFreq = sortrows(mergedData, [-2 1]);  % sort the merged columns by descending order wrt mags and then ascending order to freqs
    top10freqs = sortedFreq(1:10, 1);           % get the first 10 frequency components
    top10mags = sortedFreq(1:10, 2);            % get the first 10 frequency magnitudes
    
    training_data{i}{2} = top10freqs;

    win = hamming(length(clipped_audio),"periodic");
    S = stft(clipped_audio, Fs, "Window", win, "OverlapLength", length(clipped_audio)/2);
    coefsampleFreq = mfcc(S, Fs, "LogEnergy", "Ignore");
    training_data{i}{4} = S;
    training_data{i}{5} = coefsampleFreq;

%     nbins = 60;
%     for i = 1:size(coefsampleFreq,2)
%         figure
%         histogram(coefsampleFreq(:,i),nbins,"Normalization","pdf")
%         title(sprintf("Coefficient %d",i-1))
%     end
    
end

maleFreqData = [];
femaleFreqData = [];
for idx = 1:N
    top10freqs = training_data{idx}{2};
    if strcmp(training_data{idx}{3}, 'F')
        femaleFreqData = [femaleFreqData; top10freqs];
    else
        maleFreqData = [maleFreqData; top10freqs];
    end
end

%%
maleFreqData = maleFreqData(1:length(femaleFreqData));
freqData = [maleFreqData, femaleFreqData];

figure
hist(freqData);
legend('Male', 'Female');
xlabel('Frequency'); ylabel('Counts'); title('Frequency Distribution');
xlim([0 8000]);

%% Do frequency analysis
toc

