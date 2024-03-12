% Define the base path where subject folders are located
basePath = '/media/T7Shield/Raphaela/Data/raw_data/';
subjectFolders = dir(fullfile(basePath, 'sub-*'));

% Initialize a cell array to store results
results = {};

% Loop through each subject folder
for i = 1:length(subjectFolders)
    subjectName = subjectFolders(i).name;
    for sessionFolderName = {'session_A', 'session_B'}
        logFolderPath = fullfile(basePath, subjectName, sessionFolderName{1}, 'log');
        if exist(logFolderPath, 'dir')
            txtFiles = dir(fullfile(logFolderPath, '*.txt'));
            for k = 1:length(txtFiles)
                filePath = fullfile(txtFiles(k).folder, txtFiles(k).name);
                fid = fopen(filePath, 'r');
                correctResponses = 0;
                shouldCheckButton = false; % Indicates if we're looking for a button line next
                
                while ~feof(fid)
                    line = fgetl(fid); % Read line by line
                    
                    % If we found an event_code line previously and are now looking for a button
                    if shouldCheckButton && ischar(line) && contains(line, 'button:')
                        button = str2double(extractAfter(line, 'button: '));
                        correctButton = getCorrectButtonForEventCode(eventCode);
                        if ~isempty(correctButton) && button == correctButton
                            correctResponses = correctResponses + 1;
                        end
                        shouldCheckButton = false; % Reset for the next event_code
                        continue;
                    end
                    
                    % Process event_code lines
                    if ischar(line) && contains(line, 'event_code:')
                        eventCode = extractAfter(line, 'event_code: ');
                        if strcmp(eventCode, 'bsl')  % Skip 'bsl' event codes
                            continue;
                        else
                            shouldCheckButton = true; % Next, we should check for a button
                        end
                    elseif shouldCheckButton % If we were expecting a button but found something else
                        shouldCheckButton = false; % Reset and continue looking for the next event_code
                    end
                end
                
                fclose(fid);
                results(end+1, :) = {subjectName, sessionFolderName{1}, correctResponses};
            end
        end
    end
end




% Output results to a text file
resultsFile = fullfile(basePath, 'summary_correct_responses.txt'); % Defines the filename and path
fid = fopen(resultsFile, 'w'); % Opens the file for writing
if fid ~= -1 % Checks if the file is successfully opened
    for i = 1:size(results, 1)
        fprintf(fid, '%s, %s, Correct Responses: %d\n', results{i, :}); % Writes each line of results to the file
    end
    fclose(fid); % Closes the file
else
    disp('Failed to open file for writing.'); % Error message if the file cannot be opened
end




% Function to return the correct button for a given event code
function correctButton = getCorrectButtonForEventCode(eventCode)
    mapping = {
        '7_2_1_Chi_h_f_4', 1; '7_1_2_Tem_h_f_4', 4; '5_1_3_h_f_4', 4;
        '6_2_6_h_f_4', 3; '6_1_2_h_f_4', 1; '6_2_5_Chi_h_f_4', 3;
        '7_1_4_4', 2; '7_2_2_4', 1; '6_1_4_Pap_h_f_4', 2;
        '6_2_5_Vin_h_f_4', 3; '7_1_6_h_f_4', 3; '6_2_2_Pap_4', 4;
        '7_1_4_Chi_h_f_4', 2; '6_2_4_Tem_h_f_4', 2; '6_1_2_ADi_4', 1;
        '7_2_1_Vin_h_f_4', 1; '5_1_5_Chi_h_f_4', 2; '5_1_6_h_f_4', 3;
    };
    correctButton = NaN; % Default to NaN
    for idx = 1:size(mapping, 1)
        if strcmp(mapping{idx, 1}, eventCode)
            correctButton = mapping{idx, 2};
            break;
        elseif endsWith(eventCode, '4xgleich')
            correctButton = 3; % Special handling for "4xgleich" event codes
            break;
        end
    end
end






















