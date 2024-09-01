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
possible_cases{1} = [0,1,2]; % [NaN,0,1,2,-1]; % -1 is missing (8mn avail but not enough 70mn avail.,eg start of day of after restart), NaN means no 8mn avg. avail. Update: do not include in all-sky when misclassified

for iyear = 1:26
    disp(iyear)

    for imonth = 1:12
        disp(imonth)
        clearvars -except pathwork iyear imonth month year days day_str hour_str filewnum_resp filewnum save_dir_month icase case_string possible_cases;
        
        % Initialize a skip flag
        skip = false;

        for icase = 0:3
            radiance_hourly = NaN(2904,24*days(imonth));
            lw_nesr_extrapolated_hourly = NaN(2904,24*days(imonth));
            temperature_hourly = NaN(1,24*days(imonth));
            rad_std_hourly = NaN(2904,24*days(imonth));
            spectra_count = zeros(1,24*days(imonth));
            hourly_time = strings(24*days(imonth),1);
            cf = NaN(1,24*days(imonth));
            thin_fraction = NaN(1,24*days(imonth));
            thick_fraction = NaN(1,24*days(imonth));
            clear_fraction = NaN(1,24*days(imonth));
            available_fraction = NaN(1,24*days(imonth));

            if should_skip(iyear, imonth)
                continue;
            end
            disp('case:')
            disp(case_string(icase+1))

            filefolder = strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/processed_8mn_averaged/nsaC1_8mn_ave_', year(iyear), month(imonth));
            disp(filefolder)
            
            filename = strcat(filefolder, '/nsaC1_8mn.mat');
            if ~exist(char(filename), 'file')
                disp(['File not found: ', char(filename)])
                continue;
            end
            
            load(filename)
            
            
            hour_idx = 1;
            for i = 1:days(imonth)
                for j = 0:23
                    % Get the condition time for the current sky condition
                    condition_time = find(double(day(nsaC1_8mn.date)) == i & double(hour(nsaC1_8mn.date)) == j & ismember(nsaC1_8mn.skyclass.', possible_cases{icase+1}) & all(~isnan(nsaC1_8mn.rad),1));
                    if icase == 0
                        % If it's the all-sky case, count the spectra
                        total_spectra_all_sky(hour_idx) = 0;
                        if length(condition_time) > 3
                            disp(sum(nsaC1_8mn.rad(:,condition_time)>=0))
                            total_spectra_all_sky(hour_idx) = total_spectra_all_sky(hour_idx) + length(condition_time);
                            % Save the results for all-sky
                            radiance_hourly(:,hour_idx) = mean(nsaC1_8mn.rad(:,condition_time),2, 'omitnan');
                            lw_nesr_extrapolated_hourly(:,hour_idx) = mean(nsaC1_8mn.lw_nesr_extrapolated(:,condition_time),2, 'omitnan');
                            temperature_hourly(hour_idx) = mean(nsaC1_8mn.airTemp(condition_time),2, 'omitnan');
                            rad_std_hourly(:,hour_idx) = std(nsaC1_8mn.rad(:,condition_time),0,2,'omitmissing');
                            spectra_count(hour_idx) = sum(any(~isnan(nsaC1_8mn.rad(:,condition_time)))); % Count hours with non-NaN values
                            hourly_time(hour_idx) = string(strcat(year(iyear), month(imonth), day_str(i), hour_str(j+1)));
                            cf(hour_idx) = sum(nsaC1_8mn.skyclass(condition_time)>=1)./sum(nsaC1_8mn.skyclass(condition_time)>= 0);
                            thin_fraction(hour_idx) = sum(nsaC1_8mn.skyclass(condition_time)==2)./sum(nsaC1_8mn.skyclass(condition_time)>= 0);
                            thick_fraction(hour_idx) = sum(nsaC1_8mn.skyclass(condition_time)==1)./sum(nsaC1_8mn.skyclass(condition_time)>= 0);
                            clear_fraction(hour_idx) = sum(nsaC1_8mn.skyclass(condition_time)==0)./sum(nsaC1_8mn.skyclass(condition_time)>= 0);
                        end
                    elseif total_spectra_all_sky(hour_idx) > 3
                        % For other cases, only calculate if total all-sky spectra > 3
                        radiance_hourly(:,hour_idx) = mean(nsaC1_8mn.rad(:,condition_time),2, 'omitnan');
                        lw_nesr_extrapolated_hourly(:,hour_idx) = mean(nsaC1_8mn.lw_nesr_extrapolated(:,condition_time),2, 'omitnan');
                        temperature_hourly(hour_idx) = mean(nsaC1_8mn.airTemp(condition_time),2, 'omitnan');
                        rad_std_hourly(:,hour_idx) = std(nsaC1_8mn.rad(:,condition_time),0,2,'omitmissing');
                        spectra_count(hour_idx) = sum(any(~isnan(nsaC1_8mn.rad(:,condition_time)))); % Count hours with non-NaN values
                        hourly_time(hour_idx) = string(strcat(year(iyear), month(imonth), day_str(i), hour_str(j+1)));
                    else
                        disp('not enough spectra in all-sky to compute hourly mean for other conditions')
                    end
                    hour_idx = hour_idx + 1;
                end
            end

            % Create directory if it doesn't exist
            save_dir = strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/processed_hourly/', year(iyear), month(imonth));
            if ~exist(save_dir, 'dir')
                mkdir(save_dir);
            end

            % Save hourly radiance data for the month and year
            aeri_monthly.radiance_hourly = radiance_hourly;
            aeri_monthly.lw_nesr_extrapolated_hourly = lw_nesr_extrapolated_hourly;
            aeri_monthly.rad_std_hourly = rad_std_hourly;
            aeri_monthly.hourly_time = hourly_time;
            if icase == 0
                aeri_monthly.cf = cf;
                aeri_monthly.thin_fraction = thin_fraction;
                aeri_monthly.thick_fraction = thick_fraction;
                aeri_monthly.clear_fraction = clear_fraction;
                aeri_monthly.available = sum(~isnan(cf))/length(spectra_count);
                disp('Monthly CF:')
                disp(mean(cf,'omitnan'))
                disp('sum clear and cloudy: ')
                disp(mean(cf,'omitnan') + mean(clear_fraction,'omitnan'))
            end
            save_dir_month = strcat(save_dir, '/', case_string(icase+1));
            save(save_dir_month, 'aeri_monthly')
            disp('-------------------------')
        end
    end
end
