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
N = 10;
Fs = 16000;

for i=1:N
    [audio, ~] = audioread(strcat(files(i).folder, '/', files(i).name));
    training_data{i}{1} = labels(i);
    training_data{i}{2} = audio;
    
    timeVector = (1/Fs) * (0:numel(audio)-1);
    audio = audio ./ max(abs(audio));           % Normalize amplitude
    windowLength = ceil(numel(audio)/50);
    win = hamming(windowLength,"periodic");
    S = stft(audio,"Window",win,"OverlapLength",floor(windowLength/2));
    coeffs = mfcc(S,Fs,"LogEnergy","Ignore");
    training_data{i}{3} = coeffs;
    
    filename = [labels(i), '.dat'];
    fid = fopen(fileName,'w');
    
    cnt=fwrite(fid,sign,'int');           wrErr = wrErr | (cnt~=1);
    cnt=fwrite(fid,1.0,'float');  wrErr = wrErr | (cnt~=1);
    cnt=fwrite(fid,1,'int');        wrErr = wrErr | (cnt~=1);
    cnt=fwrite(fid,1,'int8');  wrErr = wrErr | (cnt~=1);
    
    cnt=fwrite(fid,size(coeffs,1),'int');      wrErr = wrErr | (cnt~=1);
    cnt=fwrite(fid,size(coeffs,2),'int');     wrErr = wrErr | (cnt~=1);
    cnt=fwrite(fid,1,'int');     wrErr = wrErr | (cnt~=1);
    
    ss = permute(flipud(coeffs), [2 1 3 4]);
    cnt=fwrite(fid,ss*255,'uchar');
    
end
