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
for iyear=24:26
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
        for nenCase = 1
            filefolder = strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/data_total/nsaC1_total_', num2str(year(iyear)), num2str(month(imonth)));
            filename = strcat(filefolder, '/nsaC1_total.mat');
            load(filename)
        
            % Determine discard mask based on nenCase condition
            if nenCase == 0
                discard = (nsaC1_total.hatch ~= 1) | (noise_corrected(month_count).lwskynen_tf ~= 1);
                disp('Number of spectra:')
                disp(length(nsaC1_total.hatch)) 
                disp('Sum of discarding based on hatch or noise - adjusted version:')
                disp(sum(discard))
            else 
                discard = (nsaC1_total.hatch ~= 1) | (nsaC1_total.lwskynen_tf ~= 1); 
                disp('Number of spectra:')
                disp(length(nsaC1_total.hatch))
                disp('Sum of discarding based on hatch or noise - classic version:')
                disp(sum(discard))

            end
        

            %disp(size(discard))
        
            % Create a logical matrix for the condition abs(lw_nesr_extrapolated) > abs(radiance)
            condition_mask = abs(nsaC1_total.lw_nesr_extrapolated) > abs(nsaC1_total.radiance);
        
            % Combine the two conditions: radiance <= 0 and condition_mask
            combined_mask = (nsaC1_total.radiance <= 0 & nsaC1_total.lw_nesr_extrapolated <0) & condition_mask;

            condition_mask2 = any(nsaC1_total.lw_nesr_extrapolated <0,1);
            disp('Sum of discarding based on nesr <0:')
            disp(sum(condition_mask2))
            %disp(combined_mask)


        
            % Apply the discard mask to the data arrays
            nsaC1_total.radiance(:, discard) = NaN;
            nsaC1_total.lw_nesr_extrapolated(:, discard) = NaN;
            nsaC1_total.time(discard) = NaN;
            nsaC1_total.airTemp(discard) = NaN;
            nsaC1_total.hatch(discard) = NaN;
            nsaC1_total.lwskynen(discard) = NaN;


            nsaC1_total.radiance(:, condition_mask2) = NaN;
            nsaC1_total.lw_nesr_extrapolated(:, condition_mask2) = NaN;
            nsaC1_total.time(condition_mask2) = NaN;
            nsaC1_total.airTemp(condition_mask2) = NaN;
            nsaC1_total.hatch(condition_mask2) = NaN;
            nsaC1_total.lwskynen(condition_mask2) = NaN;



            nsaC1_total.radiance(combined_mask) = NaN;
            nsaC1_total.lw_nesr_extrapolated(combined_mask) = NaN;

            cond = false; % for when i want to add the small radiance condition
            countt = 0;
            if cond
                [~, wn_982] = min(abs(nsaC1_wnum-982));
                [~, wn_987] = min(abs(nsaC1_wnum-987));
                
                num_spectra = size(nsaC1_total.radiance, 2);
                
                for i = 1:num_spectra
                    noise_value = mean(nsaC1_total.lw_nesr_extrapolated(wn_982:wn_987, i), 1, 'omitnan');
                    
                    if ~isnan(noise_value)
                        if mean(nsaC1_total.radiance(wn_982:wn_987, i), 1) < abs(2 * noise_value)
                            countt = countt + 1;
                            % Mark the low radiance spectra
                            nsaC1_total.radiance(:, i) = NaN;
                            nsaC1_total.lw_nesr_extrapolated(:, i) = NaN;
                            nsaC1_total.time(i) = NaN;
                            nsaC1_total.airTemp(i) = NaN;
                            nsaC1_total.hatch(i) = NaN;
                            nsaC1_total.lwskynen(i) = NaN;
                        end
                    %else
                        %disp(['No low radiance condition applied for spectrum ', num2str(i)]);
                    end
                end
                
                disp('Sum of discarding based on low radiance:')
                disp(countt)  % Count the number of discarded spectra
            end


            
            

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
                index = find((nsaC1_total.second<initial_second+h*480)&(nsaC1_total.second>=initial_second+(h-1)*480) & ~isnan(nsaC1_total.time));
                nsaC1_8mn.second(h) = initial_second+240+(h-1)*480;
                nsaC1_8mn.date(h) = datetime(1970,1,1,0,0,0,'Format','yyyyMMddHHmm')+seconds(nsaC1_8mn.second(h));
                if (~isempty(index)) %& (length(index) >= 3)
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
            if ~exist(pathwork, 'dir')
    system(['mkdir ', pathwork]);
end
            if nenCase == 0
                save(fullfile(pathwork,'nsaC1_8mn_adj.mat'),'nsaC1_8mn', '-v7.3');
                disp('adjusted version saved')
            else 
                if cond
                    save(fullfile(pathwork,'nsaC1_8mn_lowrad.mat'),'nsaC1_8mn', '-v7.3');
                    disp('classic version saved')
                else
                    save(fullfile(pathwork,'nsaC1_8mn.mat'),'nsaC1_8mn', '-v7.3');
                    disp('classic version saved')
                end
                
                disp('original version saved')      
            end
        end
    end
end
