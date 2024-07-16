clear;
close all;
clc;

month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
%hatch_iteration=1;
load("nsaC1_wnum.mat")


for iyear=26
    for imonth=1:12
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

        if any(condition_list)
            %monthly_time(month_count) = strcat(year(iyear), month(imonth));
            %month_count = month_count + 1;
            continue;
        end

       % p1=(iyear==1)&&(ismember(imonth,[10,11,12]));
       % p2=ismember(iyear,[2,3]);
       % p3=(iyear==4)&&(ismember(imonth,[1,2,3,4,5,6]));

       % p4=(iyear==4)&&(ismember(imonth,[7,8,9,10,11,12]));
       % p5=ismember(iyear,[5,6,7]);
       % p6=(iyear==8)&&(ismember(imonth,[1,2,3,4,5,6,7,8]));

       % p7=(iyear==9)&&(ismember(imonth,[5,6,7,8,9,10,11]));

       % p8=(iyear==9)&&(ismember(imonth,[11,12]));
       % p9=ismember(iyear,[10,11,12,13,14,15,16,17,18,19]);

       % if p1||p2||p3||p8||p9||p4||p5||p6
            bandsize=2904;
        %end

        %if p4||p5||p6
            %bandsize=5435;
        %end

        %if p7
        %    bandsize=2655;
        %end


        disp(iyear)
        disp(imonth)
	    %disp(bandsize)
        clearvars -except bandsize iyear imonth month year nsaC1_wnum;%hatch_iteration;

        filefoldername = strcat('nsaC1_raw_',year(iyear),month(imonth));
        pathwork = convertStringsToChars(strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/data_raw/',filefoldername));
        nsaC1.second = NaN(1,1);
        totalcount = 0;
        nsaC1.radiance = NaN(bandsize,1);
        nsaC1.hatch = NaN(1,1);
        if iyear == 8 && ismember(imonth,[10,11,12]) || iyear ==9 && ismember(imonth,[1,2,3,4,5,6])
            filefolder=fullfile('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/data_ch1_s01');
            filename=strcat(filefolder,'/*.',year(iyear),month(imonth),'*.cdf');
            dir_output=dir(filename);
		    disp(dir_output)
            day_count = length(dir_output);
		    disp(day_count)
            filename = {dir_output.name};
            filename = strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/data_ch1_s01/',filename);     
        else
            filefolder=fullfile('/home/binmenja/direct/aeri/nsa/data_ch1');
            filename=strcat(filefolder,'/*.',year(iyear),month(imonth),'*.cdf');
            dir_output=dir(filename);
	    %disp(dir_output)
            day_count = length(dir_output);
	        disp(day_count)
            filename = {dir_output.name};
            %disp(filename{23})
            filename = strcat('/home/binmenja/direct/aeri/nsa/data_ch1/',filename);
        end
        if (iyear > 2) && (iyear <=7) || (iyear == 8) && (imonth <= 9) || (iyear == 9) && (ismember(imonth,[7,8,9,10,11,12])) || (iyear == 10) || (iyear == 11) ;
       	%if (iyear > 2) && (iyear <=11)
            filefolder2=fullfile('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/hatch_neural_network_2');
            filename2=strcat(filefolder2,'/*.',year(iyear),month(imonth),'*.cdf');
            dir_output2=dir(filename2);
                filename2 = {dir_output2.name};
                filename2 = strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/hatch_neural_network_2/',filename2);
                hatch_corrected = ncread(filename2{1},'network_hatch');
                base_time2 = ncread(filename2{1},'base_time');
                time2 = ncread(filename2{1},'time_offset');
                realtime2 = int32(time2) + base_time2;
                nsaC1.hatch = [nsaC1.hatch, hatch_corrected'];
                nsaC1.second = [nsaC1.second, (realtime2)'];

        end
	    date_index = strcat(year(iyear),month(imonth));
        timekeep = NaN(1,1);
        for i=1:day_count% everyday
	        %disp(i)
		    disp(filename{i})
		    wnum_tempo_test  = ncread(filename{i},'wnum'); % wavelenghts number
		    if length(wnum_tempo_test)~=2904
			    if length(wnum_tempo_test)>2904
				    index_first_wv = find(wnum_tempo_test == nsaC1_wnum(1));
				    wnum_tempo  = ncread(filename{i},'wnum',index_first_wv,Inf); % wavelenghts number
				    disp(length(wnum_tempo))
                    wnum{i} = wnum_tempo;
                    mean_rad_tempo = ncread(filename{i},'mean_rad',[index_first_wv 1], [Inf Inf]); % mean radiance
                    mean_rad{i}  = mean_rad_tempo; % mean radiance
                    disp(length(wnum{i}))
			    elseif length(wnum_tempo_test)<2904
				    index_first_wv = find(nsaC1_wnum == wnum_tempo_test(1));
				    wnum_tempo  = ncread(filename{i},'wnum',1,Inf); % wavelenghts number
				    %disp(length(wnum_tempo))
                    wnum{i} = nsaC1_wnum;
                    mean_rad_tempo = ncread(filename{i},'mean_rad',[1 1], [Inf Inf]); % mean radiance
                    nanmatrix = NaN(index_first_wv-1,size(mean_rad_tempo,2));
                    mean_rad{i}  = cat(1,nanmatrix, double(mean_rad_tempo)); % mean radiance
                    disp(length(wnum{i}))
                end
                	base_time{i} = ncread(filename{i},'base_time');
            		time{i} = ncread(filename{i},'time_offset');
            		realtime{i} = int32(time{i}) + base_time{i};
		    else
            		wnum{i}  = ncread(filename{i},'wnum'); % wavelenghts number
            		mean_rad{i}  = ncread(filename{i},'mean_rad'); % mean radiance
		        %disp(size(mean_rad{i}))
	                [rad_neg1, rad_neg2] = find(mean_rad{i}<0); % get the negatives radiances
            		base_time{i} = ncread(filename{i},'base_time');
            		time{i} = ncread(filename{i},'time_offset');
            		realtime{i} = int32(time{i}) + base_time{i};
    		end
            if iyear > 2 && iyear <=7 || iyear == 8 && imonth <= 9 || (iyear == 9) &&(ismember(imonth,[7,8,9,10,11,12])) || iyear == 10 || iyear == 11;
	        %if (iyear > 2) && (iyear <=11)
                realtime{i} = unique(realtime{i});
		        [val, posh,hatch_location] = intersect(realtime{i}, realtime2); % time values in common, index in realtime{i}, index in hatch file time
		        rad = mean_rad{i};
		        rad = rad(:,posh)  ;
                nsaC1.radiance = [nsaC1.radiance, rad];
                nsaC1.wnum{i} = wnum{i};
           		timekeep = cat(1,timekeep, hatch_location); 
			    
            else
	                hatch{i}  = ncread(filename{i},'hatchOpen');
       	            nsaC1.hatch = [nsaC1.hatch, (hatch{i})'];
                    rad = mean_rad{i};
                    disp(size(rad));
                    nsaC1.radiance = [nsaC1.radiance, rad];
                    nsaC1.wnum{i} = wnum{i};
                    nsaC1.second = [nsaC1.second, (realtime{i})'];
    
            end
	    
        end

        if day_count ~= 0
            index = 0;
            for i=1:day_count
                if sum(nsaC1.wnum{i}==nsaC1.wnum{1}) == bandsize
                            index = index + 1;
                end
            end
            if any(~isnan(timekeep))
                timekeep(isnan(timekeep)) = [];
                nsaC1.second = nsaC1.second(timekeep);
                nsaC1.second = [NaN , nsaC1.second];
                nsaC1.hatch = nsaC1.hatch(timekeep);
                nsaC1.hatch = [NaN , nsaC1.hatch];

            end
            if index == day_count
                nsaC1.wnum = wnum{1};
            else
                nsaC1.wnum = wnum;
            end
        end
        %nsaC1.wnum = nsaC1_wnum; %for 201111 only
        nsaC1.second = nsaC1.second(2:end);
        nsaC1.radiance = nsaC1.radiance(:,2:end);
        nsaC1.hatch = nsaC1.hatch(2:end);
        nsaC1.second = double(nsaC1.second);
        nsaC1.dateraw = datestr(nsaC1.second/86400 + datenum(1970,1,1),30);% get the date
        nsaC1.date = nsaC1.dateraw(:,1:8);
	    disp(size(nsaC1.hatch))
        nsaC1.time1 = nsaC1.dateraw(:,10:11);
        nsaC1.time2 = nsaC1.dateraw(:,12:15);
        nsaC1.time = strcat(nsaC1.time1,'.',nsaC1.time2);
        nsaC1.date = str2num(nsaC1.date);
        nsaC1.time = str2num(nsaC1.time); % hours.minutes+seconds
        nsaC1.date = nsaC1.date';
        nsaC1.time = nsaC1.time';

        system(['mkdir ',pathwork]);
        save(fullfile(pathwork,'nsaC1_raw.mat'),'nsaC1', '-v7.3');
    end
end


