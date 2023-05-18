function [output] = integrate_and_relate(data,integration_range,name,bin_size)
%%size of data\
output = struct;
data_size = length(data);
raw_integration_values = 1:length(data);
%%Convert integration range to nanoseconds
integration_range_nanosecond = integration_range * 1E-09;
%% "integrate" data over range defined as in sum it up
for i = 1:data_size
    working_matrix = data{i};
    raw_integration_values(i) = (sum( ...
        abs( ...
        working_matrix( ...
        working_matrix(:,1)<max(integration_range_nanosecond), ...
        2))* ...
        (working_matrix(2,1)-working_matrix(1,1))) - sum( ...
        abs( ...
        working_matrix( ...
        working_matrix(:,1)<min(integration_range_nanosecond), ...
        2))* ...
        (working_matrix(2,1)-working_matrix(1,1))));

    %index = and(working_matrix(:,1)<max(integration_range_nanosecond), ...
        %%working_matrix(:,1)>min(integration_range_nanosecond));
    %raw_integration_values(i) = sum(abs(working_matrix(index,2)));
end

relative_values = raw_integration_values/mean(raw_integration_values(1:bin_size)); % compare to binned first few values

%% Binning
rounded_number = round(data_size/bin_size);
binned_values = zeros(rounded_number,1);
for i = 1:data_size/bin_size
    bin_end = i*bin_size;
    bin_start = bin_end - (bin_size-1);
    binned_values(i) = mean(relative_values(bin_start:bin_end));
end

output.Relative = relative_values;
output.Binned = binned_values;
Scaling_Factor = raw_integration_values(1);
Max = max(raw_integration_values);
Min = min(raw_integration_values);
name = {name};
output.Scalars = table(Scaling_Factor,Max,Min,'RowNames',name);
end