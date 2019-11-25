

%%
clear all; close all;

%%
recDemo = RecorderDemo();
recDemo.record();

audio = recDemo.audioSignal;
Fs = recDemo.recorderObj.SampleRate;

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

windowLength = ceil(numel(clipped_audio)/50);
overlapLength = floor(windowLength*0.5);
win = hamming(windowLength,"periodic");
S = stft(clipped_audio, "Window", win, "OverlapLength", overlapLength);
mfcc_coeffs = mfcc(clipped_audio,Fs,"LogEnergy","Ignore",...
    "WindowLength", windowLength,"OverlapLength", overlapLength);


imgfile = '/home/sweet/2-coursework/spreg487/src/demo.jpg';
datfile = '/home/sweet/2-coursework/spreg487/src/demo/demo.dat';

imwrite([mfcc_coeffs],imgfile);

processed = PictureStim(char(imgfile));
processed.save(datfile);

% delete(imgfile);

%%
knn = load('/home/sweet/2-coursework/spreg487/src/knn_trained.mat');

output_spk_folder = '/home/sweet/1-workdir/carlsim4_ductai199x/projects/demo_spreg487/results/';
output_spk_fname = 'spk_pooling.dat';

file_path = strcat(output_spk_folder, output_spk_fname);

SR = SpikeReader(file_path);
spk = SR.readSpikes(1000);

predict(knn.knn,spk)


