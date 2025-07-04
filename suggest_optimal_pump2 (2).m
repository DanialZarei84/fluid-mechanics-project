function suggest_optimal_pump()
     head = input('enter required head');
     flow = input('enter required flow rate');
    pump_list = {
        'Family_32_125.xlsx', '32-125'
        'Family_32_160.xlsx', '32-160'
        'Family_32_200.xlsx', '32-200'
        'Family_40_125.xlsx', '40-125'
        'Family_40_160.xlsx', '40-160'
        'Family_40_200.xlsx', '40-200'
        'Family_50_125.xlsx', '50-125'
        'Family_50_160.xlsx', '50-160'
        'Family_50_200.xlsx', '50-200'
    };
    best_model = '';best_diameter = 0;best_efficiency = 0;best_power = 0;closest_distance = Inf;
    for i = 1:size(pump_list,1)
        try
            file_name = pump_list{i,1};
            label = pump_list{i,2};
            boundary_data = readtable(file_name, 'Sheet', 'Boundary');
            q_values = boundary_data{:,1};h_values = boundary_data{:,2};
             if inpolygon(flow, head, q_values, h_values)
                center_q = mean(q_values); center_h = mean(h_values);
                distance = sqrt((flow - center_q)^2 + (head - center_h)^2);
               if distance < closest_distance
                    diameter_table = readtable(file_name, 'Sheet', 'Diameter');
                    efficiency_table = readtable(file_name, 'Sheet', 'Efficiency');
                    power_table = readtable(file_name, 'Sheet', 'Power');
                    [~, nearest_idx] = min(sqrt((diameter_table{:,1} - flow).^2 + (diameter_table{:,2} - head).^2));
                    interpolated_diameter = diameter_table{nearest_idx, 3};
                    available_diameters = unique(diameter_table{:,3});
                    valid_diameters = available_diameters(available_diameters >= interpolated_diameter);
                     if ~isempty(valid_diameters)
                        chosen_diameter = min(valid_diameters);
                    else
                        chosen_diameter = max(available_diameters);
                     end
                    eff_interp = scatteredInterpolant(efficiency_table{:,1}, efficiency_table{:,2}, efficiency_table{:,3}, 'natural');
                    estimated_eff = eff_interp(flow, head);
                    estimated_eff = max(min(efficiency_table{:,3}), min(max(efficiency_table{:,3}), estimated_eff));
                    power_interp = scatteredInterpolant(power_table{:,1}, power_table{:,3}, power_table{:,2}, 'natural');
                    estimated_power = power_interp(flow, chosen_diameter);
                    best_model = label;
                    best_diameter = chosen_diameter;
                    best_efficiency = estimated_eff;
                    best_power = estimated_power;
                    closest_distance = distance;
                end
            end
        catch ME
            fprintf('error reading file\n');
            continue;
        end
    end
    if ~isempty(best_model)
        fprintf('\nsuggested pump:\n');
        fprintf('model: %s\n', best_model);
        fprintf('diameter: %.1f mm\n', best_diameter);
        fprintf('eta: %.2f%%\n', best_efficiency);
        fprintf('power: %.2f kW\n', best_power);
    else
        fprintf('\no pump\n');
    end
end
