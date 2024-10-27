% Data Generation
num_samples = 1000; 
temperature = 20 + (32 - 20) * rand(num_samples, 1); % Temperature (°C)
humidity = 50 + (100 - 50) * rand(num_samples, 1); % Humidity (%)

% Diffusion/Advection Model Parameters
A = 0.001; % Area of domain
D = 10e-11; % Bacterial diffusion constant (average value)
velocity = 15e-6; % Velocity of Agrobacterium in m/s
pore_size_range = linspace(10e-6, 90e-6, 50); % Pore size range
pore_length_range = linspace(15.6e-6, 26.914e-6, 50); % Pore length range
temp_range_C = linspace(20, 32, 50); % Temperature range in Celsius
temp_range_K = temp_range_C + 273.15; % Convert to Kelvin
humidity_range = linspace(50, 100, 10); % Humidity range in %
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

% Prepare data for neural network
additional_feature = average_total_time * ones(num_samples, 1);
internalization_time = (50 - 2 * (temperature - 20)) .* (1 + 0.01 * (humidity - 50)) + additional_feature + randn(num_samples, 1);

% Split into training/testing sets
train_ratio = 0.7;
train_size = floor(train_ratio * num_samples);
X_train = [temperature(1:train_size), humidity(1:train_size), additional_feature(1:train_size)]';
Y_train = internalization_time(1:train_size)';
X_test = [temperature(train_size+1:end), humidity(train_size+1:end), additional_feature(train_size+1:end)]';
Y_test = internalization_time(train_size+1:end)';

% Create and train the neural network
hidden_layer_size = [10, 5]; % Two hidden layers
net = fitnet(hidden_layer_size, 'trainlm'); % Using Levenberg-Marquardt
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

% Train the network
[net, tr] = train(net, X_train, Y_train);

% Test the network
Y_pred = net(X_test);
performance = perform(net, Y_test, Y_pred);
fprintf('Test Set Performance (MSE): %.4f\n', performance);

% Calculate R²
SS_res = sum((Y_test - Y_pred).^2);  
SS_tot = sum((Y_test - mean(Y_test)).^2);  
R2 = 1 - (SS_res / SS_tot);  

fprintf('R^2: %.4f\n', R2);
if R2 < 1
    fprintf('R^2 is less than 1, as expected.\n');
else
    fprintf('Warning: R^2 is not less than 1, something may be wrong.\n');
end

% Plotting True vs Predicted Internalization Time
figure;
plot(Y_test, Y_pred, 'o');
hold on;
plot(linspace(min(Y_test), max(Y_test)), linspace(min(Y_test), max(Y_test)), '--r');
xlabel('True Internalization Time');
ylabel('Predicted Internalization Time');
title(sprintf('True vs Predicted Internalization Time (R^2 = %.4f)', R2));
grid on;
hold off;

% Additional regression plot for visualizing performance
figure;
plotregression(Y_test, Y_pred);
title('Regression Plot: True vs Predicted');

% Performance and error plots
figure;
plotperform(tr); % Performance plot during training
figure;
ploterrhist(Y_test - Y_pred); % Error histogram
