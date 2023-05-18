function [data_cell_array] = scrape_text_files(iterated_file_name_no_number, iteration_format, start_file, end_file)
length_iteration = length(iteration_format);
data_cell_array = cell(1+end_file-start_file,1);
for i = start_file:end_file
    %% Set up iteration
    iteration_number_file_name = iteration_format; %Reset loop variable to match standard format
    iteration_value = num2str(i); %Convert iteration number to string
    iteration_number_file_name = iteration_number_file_name(1:length_iteration-length(iteration_value)); %Remove unused spots in str
    iteration_number_file_name = strcat(iteration_number_file_name, iteration_value); %concatenate (i think theres a faster way to do  this but this works)

    %% Scrape file
    file = strcat(iterated_file_name_no_number,iteration_number_file_name,'.csv'); %Finalize file name
    %% Read and convert to matrix
    dummy_data = readcell(file);
    data_cell_array{i+1-start_file} = cell2mat(dummy_data(6:length(dummy_data),1:2));
end
end