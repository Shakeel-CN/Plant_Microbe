% Define the domain and initial conditions
A = 0.001; % Area of domain
N = 100; % Number of grid points
dx = A/N; % Grid spacing
x = linspace(0, A, N+1); % Grid points

% Varying parameters
D = 10e-11; % Bacterial diffusion constant (average value)
velocity = 15e-6; % Velocity of Agrobacterium in m/s
pore_size_range = linspace(20e-6, 80e-6, 50); % Reduced number of steps for speed
pore_length_range = linspace(15.6e-6, 26.914e-6, 50); % Reduced number of steps
temp_range_C = linspace(20, 32, 50); % Temperature range in Celsius
temp_range_K = temp_range_C + 273.15; % Convert temperature to Kelvin
humidity_range = linspace(50, 100, 10); % Humidity range in %, fewer points for speed
time_range = linspace(0, 100, 50); % Time range in seconds

% Preallocate matrices for total time and concentration
total_time_matrix = zeros(length(pore_size_range), length(pore_length_range), length(temp_range_K), length(humidity_range));

% Parallelize the outer loop
parfor p_idx = 1:length(pore_size_range)  % Parallelize over pore size
    temp_local_matrix = zeros(length(pore_length_range), length(temp_range_K), length(humidity_range));  % Preallocate local matrix

    for l_idx = 1:length(pore_length_range)  % Inner loops remain serial
        for temp_idx = 1:length(temp_range_K)
            for hum_idx = 1:length(humidity_range)
                pore_size = pore_size_range(p_idx);
                pore_length = pore_length_range(l_idx);
                T = temp_range_K(temp_idx);
                humidity = humidity_range(hum_idx);

                % Calculate temperature and humidity effects
                temp_effect = exp(-(T - min(temp_range_K)) / (max(temp_range_K) - min(temp_range_K)));
                humidity_effect = 1 + 0.005 * (humidity - 50); % Same humidity effect

                % Adjusted velocity and diffusion coefficient
                adjusted_velocity = velocity * (pore_size / max(pore_size_range)) * temp_effect * humidity_effect;
                D_eff = D * humidity_effect;

                % Calculate diffusion and advection times
                time_diffusion = (A^2) / (2 * D_eff);
                time_advection = A / adjusted_velocity;

                % Running and tumbling times
                running_time = 1.25; % sec
                tumbling_time = 0.17; % sec

                % Total time calculation
                time_total = time_diffusion + time_advection + running_time - tumbling_time;

                % Store the result in the local matrix
                temp_local_matrix(l_idx, temp_idx, hum_idx) = time_total;
            end
        end
    end

    % After computing for one pore size, store it in the main matrix
    total_time_matrix(p_idx, :, :, :) = temp_local_matrix;
end
average_total_time = mean(total_time_matrix(:));

% After the loop, calculate the average total time for 50% and 100% humidity

% Find the indices for 50% and 100% humidity
hum_idx_50 = find(abs(humidity_range - 50) < 1e-3, 1);  % Closest index to 50% humidity
hum_idx_100 = find(abs(humidity_range - 100) < 1e-3, 1); % Closest index to 100% humidity

% Extract total time for 50% and 100% humidity
total_time_50 = total_time_matrix(:, :, :, hum_idx_50);   % Extract the data for 50% humidity
total_time_100 = total_time_matrix(:, :, :, hum_idx_100); % Extract the data for 100% humidity

% Calculate the average total time for 50% and 100% humidity
average_total_time_50 = mean(total_time_50(:));
average_total_time_100 = mean(total_time_100(:));

% Print the average total time for 50% and 100% humidity
fprintf('The average total propagation time at 50%% humidity is %.2f seconds.\n', average_total_time_50);
fprintf('The average total propagation time at 100%% humidity is %.2f seconds.\n', average_total_time_100);

% Create the slider-based 4D visualization for different humidity levels
figure;
humidity_slider = uicontrol('Style', 'slider', 'Min', min(humidity_range), 'Max', max(humidity_range), ...
                            'Value', min(humidity_range), 'Position', [400 20 120 20]);

% Define a default pore length index
pore_length_idx = 1; % You can adjust this to a different index if needed

% Initial plot
update_plot(humidity_slider.Value, humidity_range, total_time_matrix, temp_range_C, pore_size_range, pore_length_idx);

% Set up callback for slider movement
addlistener(humidity_slider, 'Value', 'PostSet', @(src, event) update_plot(get(event.AffectedObject, 'Value'), ...
                       humidity_range, total_time_matrix, temp_range_C, pore_size_range, pore_length_idx));

% Move the function to the end of the script
function update_plot(humidity_value, humidity_range, total_time_matrix, temp_range_C, pore_size_range, pore_length_idx)
    % Find the closest humidity index
    hum_idx = find(abs(humidity_range - humidity_value) < 1e-3, 1); % Closest humidity index
    average_total_time_fixed_length = squeeze(total_time_matrix(:, pore_length_idx, :, hum_idx));

    % Create 3D surface plot for the given humidity value
    surf(temp_range_C, pore_size_range, average_total_time_fixed_length, 'EdgeColor', 'none');
    xlabel('Temperature (°C)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Pore Size (µm)', 'FontSize', 12, 'FontWeight', 'bold');
    zlabel('Average Total Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Effect of Temperature and Humidity (%.1f%% RH) on Propagation Time', humidity_value), ...
          'FontSize', 14, 'FontWeight', 'bold');
    colorbar;
    colormap jet;
    shading interp;
end
