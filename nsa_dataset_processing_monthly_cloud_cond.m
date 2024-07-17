%radiance_hourly = aeri_nsaC1_processed.radiance_hourly;
clear; close all; clc;
addpath('/lustre03/project/6003571/binmenja/matlab/mylib/')
filewnum = '/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/matlabscripts/nsaC1_wnum.mat';
load(filewnum)
month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
days   = [31,28,31,30,31,30,31,31,30,31,30,31];
case_string = ["all_sky","clear", "thick_low","thin_high"];
% case: 0: clear, 1: thick_low, 2: thin_high
unav = [];
for icase=0:3
    disp(icase)
    clear monthly;
    month_count = 1;
    for iyear =1:numel(year)
        for imonth = 1:numel(month)
            
            condition_list = [
                (iyear == 13) && ismember(imonth, [9,10,11,12]);
                (iyear == 14) && ismember(imonth, [1,2,3,4,5,9,10]); % Missing and then partial data because crashing file
                (iyear ==15) && ismember(imonth, [12]); % missing data
                (iyear == 16) && (imonth == 1); % missing data
                (iyear == 19) && (ismember(imonth,[10])); % Stirling cooler bad state and metrology laser problem.
                (iyear == 23) && (imonth == 8);
                (iyear == 12) && ismember(imonth,[1,2,3]); % Intermittent incorrect black body support temperature
                (iyear == 1) && (imonth == 1);
                (iyear == 2) && ismember(imonth, [1,2,5]);
                (iyear == 3) && ismember(imonth, [11,12]);
                (iyear == 19) && (imonth == 10); % Metrology laser problem
                (iyear == 5) && ismember(imonth, [3,4,5,6,7]); % Missing data
                % (iyear ==9) && (ismember(imonth,[1,2,3,4,5]));
                % (iyear==8)&&(ismember(imonth,[10,11,12]));
            ];
            month_count = (iyear - 1) * 12 + imonth;
            if any(condition_list)
                monthly.radiance(:,month_count) = NaN(2904,1);
                monthly.std(:,month_count) = NaN(2904,1);
                monthly.airTemperature(month_count) = NaN;
                if icase == 0
                    monthly.Missing(month_count) = NaN;
                    monthly.classMissing8mn(month_count) = NaN;
                    %monthly.airTemperature(month_count) = NaN;
                end
                monthly.time(month_count) = strcat(year(iyear),month(imonth));
                monthly.counting(month_count) = 0;
                unav = [unav, month_count];

                continue;
            end

            load(strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/processed_hourly/',year(iyear),month(imonth),'/monthly_radiance_',case_string(icase+1),'_',year(iyear),month(imonth),'.mat'));
            monthly.radiance(:,month_count) = mean(aeri_monthly.radiance_hourly,2,'omitnan');
            monthly.std(:,month_count) = std(aeri_monthly.radiance_hourly,0,2,'omitmissing');
            monthly.time(month_count) = strcat(year(iyear),month(imonth));
            monthly.counting(month_count) = sum(aeri_monthly.spectra_count>0);
            monthly.case = case_string(icase+1);
            monthly.airTemperature(month_count) = mean(aeri_monthly.temperature_hourly,'omitnan');
            if icase == 0
                monthly.Missing(month_count) = aeri_monthly.Missing;
                monthly.classMissing8mn(month_count) = aeri_monthly.classMissing8mn;
                %monthly.airTemperature(month_count) = mean(aeri_monthly.temperature_hourly,'omitnan');
            end
            clear aeri_monthly;
            save(strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/processed_monthly/processed_monthly_',case_string(icase+1),'.mat'),'monthly')
        end
    end
end

