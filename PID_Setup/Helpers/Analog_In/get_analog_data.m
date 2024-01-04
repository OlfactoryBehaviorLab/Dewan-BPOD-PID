function get_analog_data(a_in, BpodSystem)
    % Adapted from BpodAnalogIn updatePlot function
    % Copyright (C) 2023 Sanworks LLC, Rochester, New York, USA
    % Modified and redistributed under GNU General Public License v3

    % if is_streaming == 0
    %     fprintf('Error, the Analog input module is not streaming data!');
    %     return
    % end
    num_bytes_to_read = a_in.Port.bytesAvailable;
    num_bytes_per_frame = 4; % num frames (1) * 2 + 2
    data_packet = struct;
    if num_bytes_to_read > num_bytes_per_frame % Are there at least 4 bytes (1 frame) available to read?
        % disp('We got bytes!');

        number_of_bytes_to_read = floor(num_bytes_to_read/num_bytes_per_frame) * num_bytes_per_frame; % Depending on sampling rate, there may be multiple bytes to read
        % fprintf('There are %d bytes available!\n', number_of_bytes_to_read)

        data = a_in.Port.read(number_of_bytes_to_read, 'uint8'); % Read in the data
        data_prefix = data(1); % The first byte should be an identifier prefix

        if data_prefix == 'R' || data_prefix == '#' % R is raw data, # is sync events; if neither, something is awry
            %% Byte 1
            prefixes = data(1:num_bytes_per_frame:end); % Looks every 4 bytes for prefixes
            data(1:num_bytes_per_frame:end) = []; % Remove prefixes from the data stream
            %assignin('base', 'prefixes', prefixes);

            %% Byte 2
            sync_bytes = data(1:num_bytes_per_frame-1:end); % Sync byte is now every third byte in frame (originally the second byte)
            data(1:num_bytes_per_frame-1:end) = []; % Remove the sync data from the data stream; if no sync data, this is a spacer of 0
            %assignin('base', 'sync_bytes', sync_bytes);

            %% Byte 3 & 4
            data_samples = double(typecast(data(1:end), 'uint16')); % Cast all the data to 16-bit ints (2 byte message -> 1 value); this is ugly, thank matlab for it; int * double = int
            %assignin('base', 'raw_data', data);
            %assignin('base', 'cast_data', data_samples);
            num_data_samples = length(data_samples); % Get the number of samples

            sync_prefixes = (prefixes == '#'); % Look and see if any of the frames received are for sync events
            sync_prefixes_index = find(sync_prefixes); % Get sync event indexes
           
            data_samples_volts = bits2volts(a_in, data_samples); % Convert raw signal in bits to volts
            

            data_packet.samples = data_samples; %  Raw Measurements in bits
            data_packet.samples_volts = data_samples_volts; % Raw Measurements in volts
            data_packet.sync_indexes = double(sync_bytes(sync_prefixes_index)); % Save the sync bytes (this allows us to know what events happened where during data capture)
            data_packet.sync_time = double((sync_prefixes_index + num_data_samples)); % Not really sure how, but the indexes and sample indexes are used to save times?
            
            % disp('Put data where it goes')
            BpodSystem.Data.analog_stream_swap =  [BpodSystem.Data.analog_stream_swap data_packet];
            % assignin('base', 'data_packet', data_packet)
            % disp('Saved Data');
        else
            stop(a_in.Timer);
            delete(a_in.Timer);
            error('Error: invalid frame returned.')
        end
    end



    function voltage = bits2volts(a_in, new_samples)
        % 16-bit ADC
        % 0V-10V: 0-65,536 bits
        % 1V = 6,553.6 bits
        % bits / 6,553.6 = volts
        
        resolution = get_voltage_resolution(a_in);

        voltage = new_samples * resolution;
    
        end 
    
    function resolution = get_voltage_resolution(a_in)
    
        channel_1_range = a_in.InputRange{1}; % Get the recorded voltage range for CH1
        voltage_ranges = split(channel_1_range, ':'); % Separate into upper and lower voltage range
        range_low = voltage_ranges{1}; % Get lower voltage and remove the V
        range_low = range_low(1:end-1);
        range_high = voltage_ranges{2}; % Get higher voltage and remove the V
        range_high = range_high(1:end-1);
    
        range_high_numeric = str2double(range_high); % Convert the two numeric values from strings to doubles
        range_low_numeric = str2double(range_low);
    
        total_range = abs(range_high_numeric-range_low_numeric); % Get the total voltage range
    
        resolution = total_range / 2^16; % Divide total range by bit resolution of ADC (16-bit) should give V/bit (very small number)
    
    end


end

