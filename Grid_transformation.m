% Create function that reads in a grid (user-defined to begin) and performs
% the various transforms on the matrix for the different processes.
%   Grid-space:  Column model.  Divide grid by lat / lon but keep Z cst
%   FFT:  Divide grid by Z and lat, but keep lon (m) constant
%   Legendre:  Divide grid by Z and lon (m), but keep lat (n) constant
%   Spectral:  Divide grid by lat (n) and lon (m), but keep Z constant

clc; clear all; close all;

% Define initial grid
lat = 8;
lon = 16;
Z = 4;

proc_x = 4;
proc_y = 2;

% Create full grid array (lat, lon, Z)
Full_Grid = zeros(lat, lon, Z);
count = 0;
for k=1:Z
    for i=1:lat
        for j=1:lon
            count = count + 1;
            Full_Grid(i,j,k) = count;
        end
    end
end

%% Split grid onto separate processors
lat_per_proc = lat / proc_x;
lon_per_proc = lon / proc_y;
count = 0;
for i=1:proc_x
    for j=1:proc_y
        count = count + 1;
        start_lat = lat_per_proc * (i - 1) + 1;
        end_lat = start_lat + lat_per_proc - 1;
        start_lon = lon_per_proc * (j - 1) + 1;
        end_lon = start_lon + lon_per_proc - 1;
        Processor{count} = Full_Grid(start_lat:end_lat,start_lon:end_lon,:);
    end
end

%% Transform to FFT space
z_per_proc = Z / proc_y;
count = 0;
for i=1:proc_x
    for j=1:proc_y
        count = count + 1;
        start_z = z_per_proc * (j - 1) + 1;
        end_z = start_z + z_per_proc - 1;
        FFT_Processor{count} = Processor{proc_y * floor((count-1)/proc_y)...
            + 1}(:,:,start_z:end_z);
        for proc=2:proc_y
            FFT_Processor{count} = [FFT_Processor{count}...
                Processor{proc_y * floor((count-1)/proc_y) + ...
                proc}(:,:,start_z:end_z)];
        end
    end
end

%% Transform to Legendre space
lon_per_proc = lon / proc_x;
count = 0;
for i=1:proc_x
    for j=1:proc_y
        count = count + 1;
        start_lon = lon_per_proc * (i - 1) + 1;
        end_lon = start_lon + lon_per_proc - 1;
        Legendre_Processor{count} = [FFT_Processor{rem(count-1,proc_y) ...
            + 1}(:,start_lon:end_lon,:)];
        for proc=2:proc_x
            Legendre_Processor{count} = [Legendre_Processor{count};...
                FFT_Processor{rem((count-1),proc_y) + 1 + proc_y * ...
                (proc - 1)}(:,start_lon:end_lon,:)];
        end
    end
end
