% Parameters for Humidity Variation
stomatal_density = 300; % Stomata per unit area
lambda = 50; % Bacterial arrival rate per unit time
bacterium_speed = 10; % μm/s
bacterium_diffusion_coeff = 20; % μm^2/s
stomatal_size = 30; % μm
stomatal_accessibility_prob = 0.2; % Probability of stomata accessibility
time_interval = 1; % in hours
num_simulations = 1000; % Monte Carlo simulations
leaf_area = [1, 1]; % Leaf area in mm²

% Generate random stomatal positions within the leaf area
num_stomata = poissrnd(stomatal_density * prod(leaf_area));
stomatal_positions = rand(num_stomata, 2) .* repmat(leaf_area, num_stomata, 1);

% Humidity values
humidity_values = [70, 100]; % Testing for 50% and 100% humidity

for humidity = humidity_values
    num_internalized = 0;
    droplet_positions = [];
    
    % Adjust diffusion and speed based on humidity
    if humidity == 100
        bacterium_speed = 8; % Slower at lower humidity
        bacterium_diffusion_coeff = 15; % Lower diffusion at 50% humidity
    elseif humidity == 70
        bacterium_speed = 12; % Faster at higher humidity
        bacterium_diffusion_coeff = 25; % Higher diffusion at 100% humidity
    end

    % Monte Carlo simulation
    for i = 1:num_simulations
        % Generate random droplet position
        droplet_position = rand(1, 2) .* leaf_area;
        droplet_positions = [droplet_positions; droplet_position];

        % Check if the droplet lands on a stoma
        distances = sqrt(sum(bsxfun(@minus, stomatal_positions, droplet_position).^2, 2));
        if any(distances < stomatal_size / 2) % Droplet near stoma
            agrobacterium_arrival = poissrnd(lambda / time_interval); % Bacterial arrival rate

            % Simulate Agrobacterium movement and internalization
            for j = 1:agrobacterium_arrival
                dx = sqrt(2 * bacterium_diffusion_coeff * time_interval) * randn();
                dy = sqrt(2 * bacterium_diffusion_coeff * time_interval) * randn();
                droplet_position = droplet_position + [bacterium_speed * time_interval, 0] + [dx, dy];

                % Check for internalization
                if any(sqrt(sum(bsxfun(@minus, stomatal_positions, droplet_position).^2, 2)) < stomatal_size / 2)
                    num_internalized = num_internalized + 1;
                    break; % Exit inner loop once internalization occurs
                end
            end
        end
    end

    % Calculate likelihood of successful internalization
    likelihood_of_internalization = num_internalized / num_simulations;

    % Display results
    fprintf('Humidity: %d%% - Likelihood of internalization: %.4f\n', humidity, likelihood_of_internalization);
end

% Visualize droplet and stomatal positions
figure;
plot(stomatal_positions(:, 1), stomatal_positions(:, 2), 'ko', 'MarkerSize', 4); % Stomata
hold on;
plot(droplet_positions(:, 1), droplet_positions(:, 2), 'b.'); % Droplets
title('Leaf Area with Stomatal and Droplet Positions (Humidity)');
xlabel('Length (cm)');
ylabel('Width (cm)');
legend('Stomata', 'Droplet Positions');
