%RAM
[~, sysInfo] = memory;
totalRAM_GB = sysInfo.PhysicalMemory.Total / 1e9;
usedRAM_GB = (sysInfo.PhysicalMemory.Total - sysInfo.PhysicalMemory.Available) / 1e9;
ramUsedPercentage = (usedRAM_GB / totalRAM_GB) * 100; % As a percentage
fprintf('RAM memory %% used: %.2f%%\n', ramUsedPercentage);
fprintf('RAM Used (GB): %.2f GB\n', usedRAM_GB);


%CPU
% Get the system CPU usage
if isunix
    % On Unix-like systems, use the uptime command to fetch load averages
    [~, loadavg] = system('uptime');
    
    % Parse the load averages from the uptime command output
    loadValues = regexp(loadavg, 'load averages?:\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)', 'tokens');
    
    if isempty(loadValues)
        error('Unable to retrieve load averages. Ensure the uptime command works on your system.');
    end
    
    % Extract the 1-minute, 5-minute, and 15-minute load averages
    load1 = str2double(loadValues{1}{1});
    load5 = str2double(loadValues{1}{2});
    load15 = str2double(loadValues{1}{3});
    
    % Get the number of CPU cores
    cpuCount = feature('numcores');
    
    % Calculate CPU usage based on the 15-minute load average
    cpuUsage = (load15 / cpuCount) * 100;
    
elseif ispc
    % On Windows, use WMIC to fetch CPU usage
    [~, output] = system('wmic cpu get loadpercentage');
    
    % Clean up the output
    output = strtrim(output);  % Remove leading/trailing whitespace
    lines = strsplit(output, '\n');  % Split output by lines

    % Check if there are valid data lines
    if length(lines) >= 2
        % Extract the CPU load percentage from the second line (after the header)
        cpuUsage = str2double(strtrim(lines{2}));
    else
        error('Unable to extract CPU usage from WMIC output.');
    end
    
else
    error('Unsupported operating system. This script supports Unix-like systems and Windows.');
end

% Display CPU usage
fprintf('The CPU usage is: %.2f%%\n', cpuUsage);

% Generate random numbers using the enhanced LCG model

function R_sequence = enhanced_lcg_model(N,cpuUsage, usedRAM_GB, ramUsedPercentage)
    % Generate N random numbers
    % Dynamic seeding based on the current time
    X0 = mod(floor(now * 1e7), 100); % Initial seed
    R_sequence = zeros(1, N); % Preallocate array for speed

    for i = 1:N
        % Generate a random number using the enhanced model
        R_sequence(i) = enhanced_lcg(X0,cpuUsage, usedRAM_GB, ramUsedPercentage);
        % Update the seed for the next iteration
        X0 = R_sequence(i);
    end

    % Display the generated sequence
    disp('Generated Random Numbers:');
    disp(R_sequence);
end




% LCG Function
function X_next = lcg(X, a, c, m)
    X_next = mod(a * X + c, m);
end

% Enhanced LCG Model
function R_final = enhanced_lcg(X0,cpuUsage, usedRAM_GB, ramUsedPercentage)
    % Use cpuUsage, usedRAM_GB, and ramUsedPercentage to generate random numbers
    
    % Ensure all inputs are integers within a reasonable range
    % Keep within modulus range for LCG
    
    % Independent LCGs (LCG1 - LCG4 for parallel outputs)
    X1 = lcg(X0, 13, 7, 97);
    X2 = lcg(X0, 17, 11, 89);
    X3 = lcg(X0, 19, 3, 83);
    X4 = lcg(X0, 23, 5, 79);

    % Parallel combination (weighted by RAM usage)
    R_parallel = mod(usedRAM_GB*X1 + 3*X2 + cpuUsage*X3 + ramUsedPercentage*X4, 97);

    % Series Chain (LCG5 → LCG6 → LCG7)
    X5 = lcg(X0, 29, 2, 73);
    X6 = lcg(X5, 31, 9, 67);
    X7 = lcg(X6, 37, 13, 61);
    R_series = X7;

    % Feedback loop: LCG8
    X8 = lcg(X7, 41, 15, 59);

    % Convert to integer for bitwise operations
    R_parallel_int = uint32(R_parallel); 
    R_series_int = uint32(R_series); 
    X8_int = uint32(X8);

    % Final Mixing (combining all outputs with bitxor)
    R_final = mod(R_parallel_int + R_series_int + bitxor(R_parallel_int, R_series_int) * X8_int, 107);
end

R = enhanced_lcg_model(5,cpuUsage, usedRAM_GB, ramUsedPercentage); % Generate 10 random numbers
