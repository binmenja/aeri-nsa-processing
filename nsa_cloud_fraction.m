clear all ; clc ; close all ;
addpath('/lustre03/project/6003571/binmenja/aeri/nsa/matlabscripts');
month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
load('/lustre03/project/6003571/binmenja/aeri/nsa/matlabscripts/nsaC1_wnum.mat');
cloud.fraction = NaN(312,1);
cloud.fraction_clear = NaN(312,1);
cloud.fraction_thick = NaN(312,1);
cloud.fraction_thin = NaN(312,1);
cloud.unavailable = zeros(312,1);
cloud.date = strings(312,1);
cloud.missing = zeros(312,1);
cases_string = ["all_sky_","clear_","thick_low_","thin_high_"];

for iyear = 1:26 % Changing for 2021, from 17:18
    for imonth = 1:12
        pattern = strcat(year(iyear),month(imonth)); % Pattern we want to find - say for january 2020
        month_count = (iyear - 1) * 12 + imonth;
        disp(month_count)
        cloud.date(month_count) = pattern;

	 
        if should_skip(iyear, imonth) | ~exist(strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/processed_hourly/',year(iyear),month(imonth),'/monthly_radiance_',cases_string(1),year(iyear),month(imonth),'.mat'))
            disp(strcat('Skipping ',year(iyear),month(imonth)))
            cloud.missing(month_count) = 1;
            continue;
        end
        clearvars -except month year month_count iyear imonth nsaC1_wnum cloud icase cases_string
        disp(strcat('Processing ',year(iyear),month(imonth)))

        for icase=0:3
            caseString = cases_string(icase+1);
            % Load the data
            filefolder=strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/processed_hourly/',year(iyear),month(imonth));
            filename=strcat(filefolder,'/monthly_radiance_',caseString,year(iyear),month(imonth),'.mat');
            if icase ~=0
                load(filename)
            end

            if icase ==0
                for i = 2:3
                    load(strcat(filefolder,'/monthly_radiance_',cases_string(i+1),year(iyear),month(imonth),'.mat'))
                    temporary_flag(i-1,:) = aeri_monthly.spectra_count;
                end
                columns_with_positive_values = any(temporary_flag > 0);
                count_positive_columns = sum(columns_with_positive_values);
                size(columns_with_positive_values)
                load(strcat(filefolder,'/monthly_radiance_',cases_string(1),year(iyear),month(imonth),'.mat'))
                unavailable = sum(aeri_monthly.spectra_count==0);   
                disp(unavailable)

                cloud.fraction(month_count) = count_positive_columns./(length(aeri_monthly.spectra_count)-unavailable);
                cloud.missing(month_count) = unavailable./length(aeri_monthly.spectra_count);
                cloud.unavailable(month_count) = unavailable;
                disp(cloud.fraction(month_count))
            elseif icase == 1 % cloudy fraction
                cloud.fraction_clear(month_count) =sum(aeri_monthly.spectra_count>0)./(length(aeri_monthly.spectra_count)-unavailable); % clear fraction
                disp(cloud.fraction_clear(month_count))
            elseif icase ==2
                cloud.fraction_thick(month_count) = sum(aeri_monthly.spectra_count>0)./(length(aeri_monthly.spectra_count)-unavailable); % thick cloud fraction
                disp(cloud.fraction_thick(month_count))
            elseif icase ==3
                cloud.fraction_thin(month_count) = sum(aeri_monthly.spectra_count>0)./(length(aeri_monthly.spectra_count)-unavailable);   % thin cloud fraction
                disp(cloud.fraction_thin(month_count))
            end
            
            
        end
    end
end

save('/lustre03/project/6003571/binmenja/aeri/nsa/dataset_mat/nsaC1_cloud_fraction.mat','cloud','-v7.3')