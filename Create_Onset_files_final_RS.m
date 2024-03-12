%------------------------------------------------------------------------------------------------------------------------------------%
% Creating Matlab Onset Files
% Bambi Langzeit: fMRI Odd-one-out task 
% Raphaela Schöpfer
%------------------------------------------------------------------------------------------------------------------------------------%

clc;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define the base directory where output folders should go
%base_directory = '/home/sabine/Dokumente/Raphaela/Data/source_data/';
base_directory = '/media/T7Shield/Raphaela/Data/source_data/'

% Define the list of subjects and sessions
subjects = [391,392,395,397,398,399,401,406,407,409,410,411,413,415]; % subjects
sessions = {'B'}; % sessions

for subject = subjects
    subjectStr = num2str(subject, '%02d');

    for session = sessions
        % Direction
        %data_dir = ['/home/sabine/Dokumente/Raphaela/Data/raw_data/sub-' subjectStr '/session_' session{1}];
        data_dir = ['/media/T7Shield/Raphaela/Data/raw_data/sub-' subjectStr '/session_' session{1}];
        
        
        log_dir = fullfile(data_dir, 'log');
        text_files_dir = fullfile(data_dir, 'log');

        % Get the log file for the subject and session
        log_files = dir(fullfile(log_dir, '*.log'));
        if isempty(log_files)
            fprintf('No log files found for subject %s session %s\n', subjectStr, session{1});
            continue;
        end

        % Extract the first trigger time from the first log file
        log_file_path = fullfile(log_dir, log_files(1).name);
        first_trigger_time = extract_first_trigger_time(log_file_path);

        % Process each text file in the directory
        text_files = dir(fullfile(text_files_dir, '*.txt'));
        for file = text_files'
            text_file_path = fullfile(text_files_dir, file.name);

            % Define the output folder
            output_folder = fullfile(base_directory, sprintf('sub-%s/session_%s/log', subjectStr, session{1}));

            % Call the process_fmri_text function, passing the first_trigger_time for adjustments
            [schwer, leicht, rest] = process_fmri_text(text_file_path, first_trigger_time, output_folder, subjectStr, session{1});

            % Save the processed data for each condition in a .mat file
            save_condition_data(schwer, leicht, rest, output_folder, file.name, subjectStr, session{1});
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to extract the first trigger time from the log file

function [first_trigger_time] = extract_first_trigger_time(log_file)
    fileID = fopen(log_file, 'r');
    first_trigger_time = NaN;
    while ~feof(fileID)
        line = fgetl(fileID);
        if contains(line, '13') % Looking for the first trigger line
            tokens = regexp(line, '\s13\s(\d+)', 'tokens');  % 
            if ~isempty(tokens)
                first_trigger_time = str2double(tokens{1}{1}) / 10000; % Convert from tenths of milliseconds to seconds
                break;
            end
        end
    end
    fclose(fileID);
    if isnan(first_trigger_time)
        error('First trigger time not found in .log file');
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to extract event information (condition, onsets, durations)

function [schwer, leicht, rest] = process_fmri_text(text_file, first_trigger_time, output_folder, subject, session)
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    fileID = fopen(text_file, 'r');
    if fileID == -1
        error('Cannot open file: %s', text_file);
    end

    % Initialize variables for storing event data
    events = []; 

    % Read the file line by line to extract event information
    while ~feof(fileID)
        line = fgetl(fileID);
        if contains(line, 'get_stimulus_info')
            tokens = regexp(line, 'event_code: (\S+)\s+time: (\d+)', 'tokens');
            if ~isempty(tokens)
                event_code = tokens{1}{1};
                % Adjusting time to seconds, considering first trigger time
                time = (str2double(tokens{1}{2}) - first_trigger_time * 1000) / 1000;
                events = [events; {time, event_code}];
            end
        end
    end
    fclose(fileID);
    
    % Sort events by time
    [sortedTimes, sortedIndices] = sort(cell2mat(events(:, 1)));
    sortedEvents = events(sortedIndices, :);
    
    % Initialize condition structures
    schwer = struct('onsets', [], 'durations', []);
    leicht = struct('onsets', [], 'durations', []);
    rest = struct('onsets', [], 'durations', []);

    % Pre-allocate durations array with NaNs to calculate them in the next step
    durations = nan(size(sortedEvents, 1), 1);
    
    % Calculate durations based on the difference between successive events
    for i = 1:length(sortedEvents)-1
        durations(i) = sortedEvents{i+1, 1} - sortedEvents{i, 1};
    end
    
    % Manually set the duration of the very last event in the dataset
    durations(end) = 20; % default 20 seconds
    
    % Assign events to conditions and their calculated durations
    for i = 1:length(sortedEvents)
        event_code = sortedEvents{i, 2};
        event_time = sortedEvents{i, 1};
        duration = durations(i);
        
        if contains(event_code, '4xgleich')
            leicht.onsets(end+1) = event_time;
            leicht.durations(end+1) = duration;
        elseif contains(event_code, 'bsl')
            rest.onsets(end+1) = event_time;
            rest.durations(end+1) = duration;
        else % Assuming other codes belong to 'schwer'
            schwer.onsets(end+1) = event_time;
            schwer.durations(end+1) = duration;
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to save the events to a .mat file

function save_condition_data(schwer, leicht, rest, output_folder, file_name, subject, session)
    timing_data = struct();
    timing_data.condition = {'schwer', 'leicht', 'rest'};
    timing_data.onsets = {schwer.onsets, leicht.onsets, rest.onsets};
    timing_data.durations = {schwer.durations, leicht.durations, rest.durations};
    
    mat_file_path = fullfile(output_folder, 'timing_data.mat');
    save(mat_file_path, '-struct', 'timing_data');
end




