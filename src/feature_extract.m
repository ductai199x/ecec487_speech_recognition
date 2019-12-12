clear, clc, close all
% delete(gcp('nocreate'))
tic
%% Find all audio training files

current_path = strcat(mfilename('fullpath'), '.m');

[current_path,~,~] = fileparts(current_path);
path = strrep(current_path,'src','data/TRAIN/');

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

path = strrep(current_path,'src','data/TEST/');

train_folder_path = dir(fullfile(path));

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

training_audio = cell(size(files, 1),1);
% training_data = cell(size(files, 1),1);
training_data = [];
training_labels = cell(size(files, 1),1);

N = length(files);
training_labels_bin = zeros([N,1]);
% N = 1;
Fs = 16000;
textprogressbar('calculating outputs: ');
parfor i=1:N
%     textprogressbar(i,N);
    [audio, ~] = audioread(strcat(files(i).folder, '/', files(i).name));
%     audio = awgn(audio,5,'measured');
    idx = floor((i-1)/10)+1;
    trainig_labels{i} = labels(idx,:); 
    if trainig_labels{i}(1) == 'M'
        training_labels_bin(i) = 1
    end
    
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
    training_audio{i} = clipped_audio;
    
    windowLength = ceil(numel(clipped_audio)/50);
    overlapLength = floor(windowLength*0.5);
    win = hamming(windowLength,"periodic");
    S = stft(clipped_audio, "Window", win, "OverlapLength", overlapLength);
%     mfcc_coeffs = mfcc(S,Fs,"LogEnergy","Ignore");
    mfcc_coeffs = mfcc(clipped_audio,Fs,"LogEnergy","Ignore",...
        "WindowLength", windowLength,"OverlapLength", overlapLength);
%     mfcc_coeffs = mfcc_coeffs + abs(min(mfcc_coeffs(:)));
%     median_mfcc = median(mfcc_coeffs(:));
%     stddev_mfcc = std(mfcc_coeffs(:));
%     mfcc_coeffs_tmp = abs(mfcc_coeffs - median_mfcc);
%     mfcc_coeffs(mfcc_coeffs < 0 & mfcc_coeffs_tmp > stddev_mfcc*1) = 0;
%     mfcc_coeffs(mfcc_coeffs < 0) = 0;
%     norm_mfcc_coeffs = normalize(mfcc_coeffs,'range',[0 1]);
%     norm_mfcc_coeffs = (mfcc_coeffs - mean(mfcc_coeffs))./var(mfcc_coeffs);
%     norm_mfcc_coeffs = mfcc_coeffs + abs(min(min(mfcc_coeffs)));
    
%     training_data(:,:,i) = mfcc_coeffs + abs(min(mfcc_coeffs(:)));
    f0 = pitch(clipped_audio, Fs, "WindowLength", windowLength, ...
        "OverlapLength", overlapLength, "Method", "PEF");
%     mfcc_coeffs = (mfcc_coeffs - mean(mfcc_coeffs))./var(mfcc_coeffs);
%     X = [f0 mfcc_coeffs];
%     X = (X-mean(X))./var(X);
%     X(:,1) = X(:,1)*5;
%     X = bsxfun(@minus,mfcc_coeffs,mean(mfcc_coeffs));
%     [coeff,score,latent] = pca(X);
%     dataInPrincipalComponentSpace = X*coeff;
%     training_data(:,:,i) = mfcc_coeffs(:,[2:end]);
    training_data(:,:,i) = mfcc_coeffs;
%     training_data{i} = mfcc_coeffs;
    
%     processed_data = "";
%     if trainig_labels{i}(1) == 'F'
%         processed_data = "/processed_data/female/";
%     else
%         processed_data = "/processed_data/male/";
%     end
%     
%     imgfile = strcat(current_path, processed_data, trainig_labels{i}, '_', files(i).name, '.jpg');
%     datfile = strcat(current_path, processed_data, trainig_labels{i}, '_', files(i).name, '.dat');
%     
% %     imwrite(dataInPrincipalComponentSpace(:,1:10),imgfile);
%     imwrite(training_data(:,:,i),imgfile);
% 
%     processed = PictureStim(char(imgfile));
%     processed.save(datfile);
%     
%     delete(imgfile);
end
textprogressbar('done');
