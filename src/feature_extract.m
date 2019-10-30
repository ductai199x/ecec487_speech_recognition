clear, clc, close all
% delete(gcp('nocreate'))
tic
%% Find all audio training files

current_path = strcat(mfilename('fullpath'), '.m');

[current_path,~,~] = fileparts(current_path);
path = strrep(current_path,'src','data/TRAIN/');
% path = '~/Desktop/TIMIT/TIMIT/TRAIN/';

train_folder_path = dir(fullfile(path));

files = [];
labels = [];

for i = 1:length(train_folder_path)
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
% N = length(training_data);
N = 1;
Fs = 16000;

for i=1:N
    [audio, ~] = audioread(strcat(files(i).folder, '/', files(i).name));
    training_data{i}{1} = labels(i,:);
    
    timeVector = (1/Fs) * (0:numel(audio)-1);
    audio = audio ./ max(abs(audio));           % Normalize amplitude
    windowLength = 50e-3 * Fs;
    segments = buffer(audio,windowLength);      % Break the audio into 50-millisecond non-overlapping frames
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
    training_data{i}{2} = clipped_audio;
    
    windowLength = ceil(numel(clipped_audio)/50);
    win = hamming(windowLength,"periodic");
    S = stft(clipped_audio,"Window",win,"OverlapLength",floor(windowLength/2));
    coeffs = mfcc(S,Fs,"LogEnergy","Ignore");
    
    training_data{i}{3} = coeffs;

    filename = strcat(current_path, "/processed_data/", labels(i,:), '.jpg');
    outputfile = strcat(current_path, "/processed_data/", labels(i,:), '.dat');
    
    imwrite(coeffs,filename)
    
    processed = PictureStim(char(filename));
    processed.save(outputfile);
    
end
