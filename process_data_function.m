function process_data_function(sample_id,filename_no_number,bin_size, ...
    time_interval, ...
    start_file,end_file,start_time, ...
    PMT_integration_range,photodiode_integration_range,iteration_format)
%     process_data_function(C1_filename_no_number,C2_filename_no_number,number_of_files,iteration_format,time_interval,C1_integration_range,C2_integration_range)
%     sample_id is the desired output name for the excel doc
%     filename_no_number - whatever is in between the 'CX--' and '--00000'
%     number_of_files (1,1) {mustBeNumeric} = 1  %just the total number, if indexed at 0 add 1 to final iteration number
%     iteration_format string = '00000' %is a string so use ''
%     time_interval {mustBeNumeric} = 5
%     C1_integration_range (1,2) {mustBeNumeric} = [20 100] %in nanoseconds
%     C2_integration_range (1,2) {mustBeNumeric} = [-10 35] %in nanoseconds


%% Arguments
arguments
    sample_id {mustBeTextScalar} % Desired output name
    filename_no_number {mustBeTextScalar} %ignore the iteration number and the .txt extension
    bin_size {mustBeNumeric} = 10
    time_interval {mustBeNumeric} = 0.495
    start_file (1,1) {mustBeNumeric} = 0 %start iteration number
    end_file (1,1) {mustBeNumeric} = 998 %last iteration number
    start_time (1,1) {mustBeNumeric} = 0 %time started
    PMT_integration_range (1,2) {mustBeNumeric} = [20 200] %in nanoseconds
    photodiode_integration_range (1,2) {mustBeNumeric} = [-10 35] %in nanoseconds
    iteration_format {mustBeTextScalar} = '--00000' %is a string so use ''
end

%% define C1 and C2 files
PMT_filename_no_number = strcat('C1--',filename_no_number);
photodiode_filename_no_number = strcat('C2--',filename_no_number);
number_of_files = end_file-start_file+1;
%% Plan
% Call for data 
% Call for Parameters and define arguments
% Scrape data
% Process C1 (integrate)
% Process C2 (integrate)
% Relate C1 to C2
% Plot
% Export Corrected Data and Plot

%% Scrape Data
tic
PMT_data = scrape_text_files(PMT_filename_no_number,iteration_format,start_file,end_file);
toc
disp('read PMT');
time_took = toc;

tic
photodiode_data = scrape_text_files(photodiode_filename_no_number,iteration_format,start_file,end_file);
disp('read files');
time_took = time_took+toc;
toc
%% Process C1 (Fluorescence off of PMT) (function 1)
tic
% Sum over integration range
% Note max, min, and first shot integration
% Make Relative to first shot
PMT_integrated = integrate_and_relate(PMT_data,PMT_integration_range,'C1',bin_size);
%Working_Structure.C1_Relative = C1_integrated.Relative;
%Working_Structure.C1_values = C1_integrated.Scalars;

time_took = time_took+toc;
disp('processed files C1');
toc
%% Process C2 (Shot Power) (Function 1, different file)
tic
% Sum over integration range
% Not max, min integration
% Make relative to first shot
photodiode_integrated = integrate_and_relate(photodiode_data,photodiode_integration_range,'C2',bin_size);
%Working_Structure.C2_Relative = C2_integrated.Relative;
%Working_Structure.C2_values = C2_integrated.Scalars;

time_took = time_took+toc;
disp('processed files C2');
toc
%% Relate C1 to C2
tic
% "Correct" Data for shot power by dividing C1 by C2
PMT_corrected = zeros(number_of_files,1);
for i = 1:number_of_files
    PMT_corrected(i,1) = PMT_integrated.Relative(i)/photodiode_integrated.Relative(i);
end

PMT_binned = zeros(number_of_files,1);
for i = 1:length(PMT_integrated.Binned)
    PMT_binned(i,1) = PMT_integrated.Binned(i)/photodiode_integrated.Binned(i);
end

%Working_Structure.C1_corrected = C1_corrected;

time_took = time_took+toc;

disp('Corrected files');
toc
%% Collect data into pretty table
tic
% Output Structure
%Working_Structure.Time = [0:time_interval:time_interval*(number_of_files-1)]; 

% Make a document with time points and C1 relative, C2 relative, C1 corrected, C1 shot 1, C2 shot 1, C1 max/min, C2 max/min
time_matrix = zeros(number_of_files,1);
time_matrix(:,1) = (start_time:time_interval:start_time+time_interval*(number_of_files-1));
time_matrix_binned = zeros(number_of_files,1);
temp_bin_time = (start_time:bin_size*time_interval:start_time+time_interval*(number_of_files-1));
for i = 1:length(temp_bin_time)
    temp_bin_time(i) = mean(temp_bin_time(i):time_interval:i*time_interval*bin_size-1);
end
time_matrix_binned(1:length(temp_bin_time),1) = temp_bin_time;
PMT_Relative_values = zeros(number_of_files,1);
photodiode_Relative_values = zeros(number_of_files,1);
PMT_Relative_values(:,1) = PMT_integrated.Relative;
photodiode_Relative_values(:,1) = photodiode_integrated.Relative;


Output_Structure.Time_points = table(time_matrix, ...
    PMT_Relative_values,photodiode_Relative_values, PMT_corrected, ...
    time_matrix_binned,PMT_binned,...
    'VariableNames',{'Time','PMT Relative', 'Photodiode Relative', 'PMT Corrected','Binned Times','PMT Corrected and Binned'});
Output_Structure.Scaling_factors = [PMT_integrated.Scalars ; photodiode_integrated.Scalars];

time_took = time_took+toc;

disp('Collected data');
toc
%% Export
tic
filename = strcat(sample_id,'_processed_and_corrected','.xlsx');
writetable(Output_Structure.Time_points,filename,'Sheet','Data','Range','A1');
writetable(Output_Structure.Scaling_factors,filename,'Sheet','Factors','Range','A1');

time_took = time_took+toc;

disp('Exported data - total time took');
toc

disp(strcat('total time is: ~', num2str(time_took,3),' seconds'));
clear;
end