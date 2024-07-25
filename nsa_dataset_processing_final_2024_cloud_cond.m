month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
days   = [31,28,31,30,31,30,31,31,30,31,30,31];
day_str = ["01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"];
hour_str = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"];

pathwork = '/home/binmenja/direct/aeri/nsa/matlabscripts/';
filewnum = 'nsaC1_wnum.mat';
filewnum_resp = 'nsaC1_wnum_resp.mat';
load(filewnum)
addpath('/lustre03/project/6003571/binmenja/matlab/mylib/')
case_string = ["all_sky","clear", "thick_low","thin_high"];
% case: 0:allsky;1: clear, 2: thick_low, 3: thin_high%
possible_cases{2} = [0];
possible_cases{3} = [1];
possible_cases{4} = [2];
possible_cases{1} = [NaN,0,1,2,-1]; % -1 is missing (8mn and 70mn avail.), NaN means only 70mn roundabout missing (8mn is not classified but data for this 8 mn is available)
for icase = 0:3
    disp(icase)
    for iyear=1:26
        disp(iyear)

        for imonth=1:12
            disp(imonth)
            clearvars -except pathwork iyear imonth month year days day_str hour_str filewnum_resp filewnum save_dir_month icase case_string possible_cases;

            radiance_hourly = NaN(2904,24*days(imonth)) ;
            lw_nesr_extrapolated_hourly = NaN(2904,24*days(imonth));
            temperature_hourly = NaN(1,24*days(imonth));
            rad_std_hourly = NaN(2904,24*days(imonth));
            spectra_count = zeros(1,24*days(imonth));
            hourly_time = strings(24*days(imonth),1);

            if should_skip(iyear, imonth)
                continue;
            end

            %filefolder=strcat('/Users/benjaminriot/Desktop/nsaC1_processed_','2014','02');
            filefolder=strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/processed_8mn_averaged/nsaC1_8mn_ave_',year(iyear),month(imonth));
            for nenCase = 0:1
                if nenCase == 0
                    filename=strcat(filefolder,'/nsaC1_8mn_ajd.mat');
                else
                    filename=strcat(filefolder,'/nsaC1_8mn.mat');
                end
            
                load(filename)
            
                hour_idx = 1;
                for i=1:days(imonth)
                    for j=0:23 % Corrected to 24 hours
                        %disp(possible_cases{icase+1})
                        condition_time = find(double(day(nsaC1_8mn.date)) == i & double(hour(nsaC1_8mn.date)) == j & ismember(nsaC1_8mn.skyclass.', possible_cases{icase+1}));
                        %disp(condition_time)
                        if isempty(condition_time) | all(isnan(nsaC1_8mn.rad(:,condition_time)))
                            %disp('empty hour')
                            hourly_time(hour_idx) = string(strcat(year(iyear),month(imonth),day_str(i),hour_str(j+1))); 
                            hour_idx = hour_idx + 1;
                        else
                            %rad_hourly = mean(nsaC1_8mn.rad(:,condition_time),2, 'omitnan'); % hourly mean
                            %rad_std_hourly = mean(nsaC1_8mn.rad_std(:,condition_time),2,'omitnan');
                            radiance_hourly(:,hour_idx) = mean(nsaC1_8mn.rad(:,condition_time),2, 'omitnan');
                            lw_nesr_extrapolated_hourly(:,hour_idx) = mean(nsaC1_8mn.lw_nesr_extrapolated(:,condition_time),2, 'omitnan');
                            temperature_hourly(hour_idx) = mean(nsaC1_8mn.airTemp(condition_time),2, 'omitnan');
                            rad_std_hourly(:,hour_idx) = std(nsaC1_8mn.rad(:,condition_time),0,2,'omitmissing');
                            spectra_count(hour_idx) = sum(any(~isnan(nsaC1_8mn.rad(:,condition_time)))); % Count hours with non-NaN values
                            hourly_time(hour_idx) = string(strcat(year(iyear),month(imonth),day_str(i),hour_str(j+1))); 
                            hour_idx = hour_idx + 1;
                        end
                    end
                end
                
                % Create directory if it doesn't exist
                save_dir = strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/processed_hourly/', year(iyear), month(imonth));
                if ~exist(save_dir, 'dir')
                    mkdir(save_dir);
                end
                % Save hourly radiance data for the month and year
                if icase == 0
                    aeri_monthly.classMissing8mn = sum(isnan(nsaC1_8mn.skyclass));
                    aeri_monthly.Missing = sum(nsaC1_8mn.skyclass == -1); % not enough 70mn
                    disp(aeri_monthly.classMissing8mn)
                    disp(aeri_monthly.Missing)
                end
                aeri_monthly.radiance_hourly = radiance_hourly;
                aeri_monthly.lw_nesr_extrapolated_hourly = lw_nesr_extrapolated_hourly;
                aeri_monthly.rad_std_hourly = rad_std_hourly;
                aeri_monthly.hourly_time = hourly_time;
                disp(hourly_time(1))
                aeri_monthly.spectra_count = spectra_count; 
                %if icase == 0
                aeri_monthly.temperature_hourly = temperature_hourly;
                %end
                % Save hourly radiance data for the month
                if nenCase = 0
                    save_filename = fullfile(save_dir, strcat('monthly_radiance_adj_', case_string(icase+1),'_',year(iyear), month(imonth), '.mat'));
                else
                    save_filename = fullfile(save_dir, strcat('monthly_radiance_', case_string(icase+1),'_',year(iyear), month(imonth), '.mat'));
                end
                save(save_filename, 'aeri_monthly', '-v7.3');
                clear aeri_monthly;
            end
        end
    end
end

