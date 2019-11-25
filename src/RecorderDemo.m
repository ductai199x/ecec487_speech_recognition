classdef RecorderDemo < handle
    %% PROPERTIES
    % public
    properties (SetAccess = private)
        recorderObj;
        audioSignal;
    end
    
    % private
    properties (Hidden, Access = private)
        quitRecorder;
        startRecording;
        doneRecording;
        playRecording;
        plotAudioSignal;
	end
    
    
    %% PUBLIC METHODS
    methods
        function obj = RecorderDemo()
            obj.loadDefaultParams()
        end
        
        function delete(obj)
            % destructor
        end

        function record(obj)
            figure()
            title("DEMO RECORDER");
            text(0.5,0.5,{"Press r to start recording", ...
                "Press s to stop recording",...
                "Press l to listen to the recording",...
                "Press p to pause recording",...
                "Press q to quit recorder"});
            set(gcf,'KeyPressFcn',@obj.recordOnKeyPressCallback)
            
            while ~obj.quitRecorder
                plot(obj.audioSignal)
                drawnow
                
                if obj.startRecording
                    record(obj.recorderObj);
                end
                
                if ~obj.startRecording && ~obj.doneRecording
                    pause(obj.recorderObj);
                end
                
                if obj.doneRecording
                    stop(obj.recorderObj);
                    obj.audioSignal = getaudiodata(obj.recorderObj, 'double');
                end
                
                if obj.playRecording
                    obj.playRecording = false;
                    play(obj.recorderObj);
                    waitforbuttonpress;
                end
            end
        end
    end
    
    
    %% PRIVATE METHODS
    methods (Hidden, Access = private)
        
        function loadDefaultParams(obj)
            obj.recorderObj = audiorecorder(16000, 8, 1);
            obj.quitRecorder = false;
            obj.plotAudioSignal = false;
            obj.startRecording = false;
            obj.doneRecording = false;
            obj.playRecording = false;
			% disable backtracing for warnings and errors
			warning off backtrace
        end
        
        function recordOnKeyPressCallback(obj,~,eventData)
            % Callback function to pause plotting
            switch eventData.Key
                case 'p'
                    obj.quitRecorder = false;
                    obj.plotAudioSignal = false;
                    obj.startRecording = false;
                    obj.doneRecording = false;
                    obj.playRecording = false;
                    disp('Paused Recording..');
                    waitforbuttonpress;
                case 's'
                    obj.quitRecorder = false;
                    obj.plotAudioSignal = false;
                    obj.startRecording = false;
                    obj.doneRecording = true;
                    obj.playRecording = false;
                    disp('Stopped Recording. Audio Signal Recorded.');
                case 'l'
                    obj.quitRecorder = false;
                    obj.plotAudioSignal = false;
                    obj.startRecording = false;
                    obj.doneRecording = false;
                    obj.playRecording = true;
                    disp('Playing recorded signal...');
                case 'k'
                    obj.quitRecorder = false;
                    obj.plotAudioSignal = false;
                    obj.startRecording = false;
                    obj.doneRecording = false;
                    obj.playRecording = false;
                    obj.audioSignal = [];
                    obj.recorderObj = audiorecorder;
                    disp('Restarting Recorder...');
                case 'q'
                    obj.quitRecorder = true;
                    disp('Quitting Demo. Bye.');
                case 'r'
                    obj.quitRecorder = false;
                    obj.plotAudioSignal = false;
                    obj.startRecording = true;
                    obj.doneRecording = false;
                    obj.playRecording = false;
                    disp('Recording Audio Signal. Say something...');
                otherwise
            end
        end
    end
end