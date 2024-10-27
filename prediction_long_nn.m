
% Data Generation with Extended Time Range 
num_samples = 100; % Number of samples
temperature = 20 + (32 - 20) * rand(num_samples, 1); % Temperature (°C)
humidity = 50 + (100 - 50) * rand(num_samples, 1); % Humidity (%)
time_extended = linspace(4000, 5080, num_samples)'; % Extended time steps up to 5080s

% Feature Scaling (Normalization)
temperature_norm = (temperature - min(temperature)) / (max(temperature) - min(temperature));
humidity_norm = (humidity - min(humidity)) / (max(humidity) - min(humidity));
time_norm = (time_extended - min(time_extended)) / (max(time_extended) - min(time_extended));

% Prepare feature matrix X_train_extended
X_train_extended = [temperature_norm, humidity_norm, time_norm]'; % Transpose to make each feature a row

% Target Data (Y_train) based on a model for internalization time
Y_train_extended = (50 - 2 * (temperature - 20)) .* (1 + 0.01 * (humidity - 50)) + time_extended' + randn(1, num_samples); % Transpose target

% Neural Network Configuration with more complex architecture for extended data
hidden_layer_size = [50, 30, 10]; % Define layers and neurons
net = fitnet(hidden_layer_size, 'trainlm'); % Using Levenberg-Marquardt algorithm

% Set up data division ratios for training, validation, and testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 20/100;
net.divideParam.testRatio = 10/100;

% Apply L2 Regularization to avoid overfitting
net.performParam.regularization = 0.1;

% Train the network on the extended dataset
[net, tr] = train(net, X_train_extended, Y_train_extended);

% Test the network with the extended dataset
Y_pred_extended = net(X_train_extended);

% Calculate R-squared value to evaluate model performance
SS_res = sum((Y_train_extended - Y_pred_extended).^2);
SS_tot = sum((Y_train_extended - mean(Y_train_extended)).^2);
R2 = 1 - SS_res / SS_tot;

% Plotting True vs Predicted Internalization Time
figure;
plot(Y_train_extended, Y_pred_extended, 'o');
hold on;
plot([min(Y_train_extended), max(Y_train_extended)], [min(Y_train_extended), max(Y_train_extended)], '--r');
xlabel('True Internalization Time');
ylabel('Predicted Internalization Time');
title(sprintf('True vs Predicted Internalization Time (R^2 = %.4f)', R2));
legend('Predictions', 'Ideal Fit');
grid on;
hold off;

% Plot the error histogram to evaluate prediction errors over the broader range
figure;
ploterrhist(Y_train_extended - Y_pred_extended);
title('Error Histogram (Extended Time Range)');

% Plot model performance for training, validation, and testing errors
figure;
plotperform(tr);
title('Model Performance: Training, Validation, and Testing Errors');
