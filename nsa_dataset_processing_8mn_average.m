month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
month_count = 1;
day   = [31,28,31,30,31,30,31,31,30,31,30,31];
day_str = ["01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"];
hour_str = ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"];
pathwork = '/home/binmenja/direct/aeri/nsa/matlabscripts/';
filewnum = 'nsaC1_wnum.mat';
load(filewnum)
load("noise_review.mat") % threshold here is 2.4489 RU instead of 1 RU, keeping around 70% of the data
%load("noise_2_review.mat")%more conservative noise correction, 2 RU threshold
addpath('/lustre03/project/6003571/binmenja/matlab/mylib/')
for iyear=1:26
disp(iyear)
    for imonth=1:12
        disp(imonth)
        month_count = (iyear - 1) * 12 + imonth;
        
        if should_skip(iyear, imonth)
            continue;
        end

        filefoldername = strcat('nsaC1_8mn_ave_',year(iyear),month(imonth));
        pathwork = convertStringsToChars(strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/processed_8mn_averaged/',filefoldername));
        clearvars -except pathwork iyear turner_985 percent_discarded imonth month year wnum_resp month_count threshold_ts threshold_bt_std spectra_count day day_str hour_str resp responsivity_monthly rad rad_std radiance_monthly nsaC1_wnum hourly_time_monthly monthly_time nsaC1_lwskynen_fixed dateStringsArray noise_corrected noise_corrected_2;

        %filefolder=strcat('/Users/benjaminriot/Desktop/nsaC1_total_','2014','02');
        for icase =0:1
            filefolder=strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/data_total/nsaC1_total_',year(iyear),month(imonth));
            filename=strcat(filefolder,'/nsaC1_total.mat');
            load(filename)
            disp(size(nsaC1_total.radiance))
            if icase ==0
                discard = (nsaC1_total.hatch ~=1) | (noise_corrected(month_count).lwskynen_tf~=1); 
                disp(sum(discard))
            elseif icase ==1
                discard = (nsaC1_total.hatch ~=1) | (nsaC1_total.lwskynen_tf~=1); 
                disp(sum(discard))
            end
            % Logical mask for negative radiance with higher NESR
            discard_negative = false(size(nsaC1_total.radiance));
            [row_neg, col_neg] = find(nsaC1_total.radiance <= 0);
            for idx = 1:length(row_neg)
                row = row_neg(idx);
                col = col_neg(idx);
                if abs(nsaC1_total.lw_nesr_extrapolated(row, col)) > abs(nsaC1_total.radiance(row, col))
                    discard_negative(row, col) = true;
                end
            end

            nsaC1_total.radiance(discard_negative(:,1),discard_negative(:,2)) = NaN;
            nsaC1_total.radiance(:,discard) = NaN;
            nsaC1_total.lw_nesr_extrapolated(discard(:,1), discard(:,2)) = NaN;
            nsaC1_total.time(discard(:,2)) = NaN;
            nsaC1_total.airTemp(discard(:,2)) = NaN;
            nsaC1_total.hatch(discard(:,2)) = NaN;
            
            

            initial_second = (datenum(str2num(year(iyear)),str2num(month(imonth)),1,0,0,0)-datenum(1970,1,1,0,0,0))*86400;
            end_second = (datenum(str2num(year(iyear)),str2num(month(imonth)),day(imonth),23,59,59)-datenum(1970,1,1,0,0,0))*86400;
                counting_total = fix((end_second-initial_second)/480) + 1;

            nsaC1_8mn.rad = NaN(2904,counting_total);
            nsaC1_8mn.rad_std = NaN(2904,counting_total);
            nsaC1_8mn.lw_nesr_extrapolated = NaN(2904,counting_total);
                %nsaC1_average.resp = NaN(length(wnum_resp),counting_total);
            nsaC1_8mn.second = NaN;
            nsaC1_8mn.airTemp = NaN;
            nsaC1_8mn.year = str2num(year(iyear));
            nsaC1_8mn.month = str2num(month(imonth));             
            
            nsaC1_8mn.wnum = nsaC1_wnum;
            nsaC1_8mn.date = NaT(1,counting_total);
            nsaC1_8mn.time = NaN(1,counting_total);
            for h=1:counting_total % 8mn average
                    index = find((nsaC1_total.second<initial_second+h*480)&(nsaC1_total.second>=initial_second+(h-1)*480));
                nsaC1_8mn.second(h) = initial_second+240+(h-1)*480;
                nsaC1_8mn.date(h) = datetime(1970,1,1,0,0,0,'Format','yyyyMMddHHmm')+seconds(nsaC1_8mn.second(h));
                if ~isempty(index)
                        rad_select = nsaC1_total.radiance(:,index);
                        
                        % Add a line to delete spectra where NaN values exist
                        %[~, col] = find(isnan(rad_select));
                        %rad_select(:,col) = [];
                        %resp_select = responsivity(:,index);
                        time_select = nsaC1_total.time(index);
                        airTemp_select = nsaC1_total.airTemp(index);
                        nsaC1_8mn.airTemp(h) = mean(airTemp_select,'omitnan');
                        %time_select = time_select(~col);
                        nsaC1_8mn.rad(:,h) = mean(rad_select,2,'omitnan');
                        nsaC1_8mn.lw_nesr_extrapolated(:,h) = mean(nsaC1_total.lw_nesr_extrapolated(:,index),2,'omitnan');
                        nsaC1_8mn.rad_std(:,h) = std(rad_select,0,2,'omitnan');
                        %nsaC1_average.resp(:,h) = mean(resp_select,2,'omitnan');
                        nsaC1_8mn.time(h) = mean(time_select,'omitnan');
                else
                        nsaC1_8mn.rad(:,h) = NaN;
                        nsaC1_8mn.lw_nesr_extrapolated(:,h) = NaN;
                        nsaC1_8mn.rad_std(:,h) = NaN;
                        nsaC1_8mn.airTemp(h) = NaN;
                        %nsaC1_average.resp(:,h) = NaN;
                        nsaC1_8mn.time(h) = NaN;
                end
            end 
            system(['mkdir ',pathwork]);
            if icase ==0
                save(fullfile(pathwork,'nsaC1_8mn_adj.mat'),'nsaC1_8mn', '-v7.3');
                disp('adjusted version saved')
            elseif icase ==1
                save(fullfile(pathwork,'nsaC1_8mn.mat'),'nsaC1_8mn', '-v7.3');  
                disp('original version saved')      
            end
        end
    end
end
