clear;
close all;
clc;

month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];

for iyear=1:25
    for imonth=12

        clearvars -except iyear imonth month year;
	    disp(imonth)
        filefoldername = strcat('nsa_qc_',year(iyear),month(imonth));
        pathwork = convertStringsToChars(strcat('/lustre03/project/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/data_qc/',filefoldername));
        nsa_qc.second = NaN(1,1);
        nsa_qc.lw_nesr = NaN(71,1); % noise equivalent spectral radiance (71 wavenumbers)
        nsa_qc.wv_nesr = NaN(71,1);
        nsa_qc.lwskynen = NaN(1,1); % The noise equivalent radiance observed in the longwave channel during a sky view at 1000 cm-1unitsmw/(m2 sr cm-1)
        nsa_qc.lwskynen_tf = NaN(1,1);
        nsa_qc.airTemp = NaN(1,1);
	    nsa_qc.LWresponsivity = NaN(71,1);
        %nsa_qc.lwhbbnen = NaN(1,1)
        %if iyear == 8 && ismember(imonth,[10,11,12]) || iyear ==9 && ismember(imonth,[1,2,3,4,5,6])
                    %filefolder=fullfile('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/data_summary_s01');
        %else
            filefolder=fullfile('/lustre03/project/rrg-yihuang-ad/binmenja/aeri/nsa/data_summary');
        %end
        date_index = strcat(year(iyear),month(imonth));

        if ~isempty(dir(strcat(filefolder,'/*.',year(iyear),month(imonth),'*.cdf')))
            filename=strcat(filefolder,'/*.',year(iyear),month(imonth),'*.cdf');
        else 
            disp('nc files')
            filename=strcat(filefolder,'/*.',year(iyear),month(imonth),'*.nc');
        end
        dir_output=dir(filename);

        day_count = length(dir_output);
        filename = {dir_output.name};
        %if iyear == 8 && ismember(imonth,[10,11,12]) || iyear ==9 && ismember(imonth,[1,2,3,4,5,6])
                %filename=strcat('/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/data_summary_s01/',filename);
        %else
            filename = strcat('/lustre03/project/rrg-yihuang-ad/binmenja/aeri/nsa/data_summary/',filename);
            disp(filename)
        %end
        for i=1:day_count
	
            finfo = ncinfo(filename{i});

            for k=1:size(finfo.Variables,2)
                varname{k} = finfo.Variables(1,k).Name;
            end

    

            if  ismember('LWskyNENAcceptable',varname)==1
                lwskynen_tf{i} = ncread(filename{i},'LWskyNENAcceptable');%Logical flag indicating whether longwave channel noise equivalent radiance is acceptable in sky view (true/false).  Determined using LWskyNEN and LWskyNENlimit.units
            else
                lwskynen_tf{i} = ncread(filename{i},'LWskyNENacceptable');
            end

            outAirTemp{i} = ncread(filename{i},'outsideAirTemp');
            outAirTemp{i}(outAirTemp{i}<100) = NaN;
	 

            wv_nesr{i} = ncread(filename{i},'wnumsum5'); %Wave number in reciprocal centimetersunitscm-1independent_interval
            wv_resp{i} = ncread(filename{i},'wnumsum1');
            if ismember('SkyNENCh1',varname)==1
	    	    lw_nesr{i} = ncread(filename{i},'SkyNENCh1');% AERI LW Scene NESR Spectral Averages (Ch1)unitsmw/(m2 sr cm-1)
	        else
                lw_nesr{i} = ncread(filename{i},'SkyNENch1');% AERI LW Scene NESR Spectral Averages (Ch1)unitsmw/(m2 sr cm-1)
            end
            index = length(wv_nesr{i});

            if index<71
                wv_nesr{i}(index+1:71)=NaN;
                lw_nesr{i}(index+1:71,:)=NaN;
                %hbb2mn{i}(index+1:71,:)=NaN;
            end

            base_time = ncread(filename{i},'base_time');
            time{i} = ncread(filename{i},'time_offset');
            realtime{i} = int32(time{i}) + base_time;

            if  ismember('LWskyNEN',varname)==1
                lwskynen{i} = ncread(filename{i},'LWskyNEN'); %The noise equivalent radiance observed in the longwave channel during a sky view at 1000 cm-1unitsmw/(m2 sr cm-1)
            else
                lwskynen{i} = NaN(size(realtime{i},1),1);
            end

	        
	        if  ismember('ResponsivitySpectraAveragesCh1',varname)==1
                LWresponsivity{i} = ncread(filename{i},'ResponsivitySpectraAveragesCh1');%Longwave resp
            else
                LWresponsivity{i} = ncread(filename{i},'ResponsivitySpectralAveragesCh1');
            end


            nsa_qc.second = [nsa_qc.second, (realtime{i})'];
            nsa_qc.second = double(nsa_qc.second);
            nsa_qc.dateraw = datestr(nsa_qc.second/86400 + datenum(1970,1,1),30);
            nsa_qc.date = nsa_qc.dateraw(:,1:8);
            nsa_qc.time1 = nsa_qc.dateraw(:,10:11);
            nsa_qc.time2 = nsa_qc.dateraw(:,12:15);
            nsa_qc.time = strcat(nsa_qc.time1,'.',nsa_qc.time2);
            nsa_qc.date = str2num(nsa_qc.date);
            nsa_qc.time = str2num(nsa_qc.time); % hours.minutes+seconds
            nsa_qc.date = nsa_qc.date';
            nsa_qc.time = nsa_qc.time';
            %nsa_qc.hbb2mn = [nsa_qc.hbb2mn, hbb2mn{i}];
            nsa_qc.lwskynen = [nsa_qc.lwskynen, (lwskynen{i})'];
	        %nsa_qc.lwhbbnen = [nsa_qc.lwhbbnen, (lwhbbnen{i})'];
	        nsa_qc.LWresponsivity = [nsa_qc.LWresponsivity, LWresponsivity{i}];
            nsa_qc.lwskynen_tf = [nsa_qc.lwskynen_tf, (lwskynen_tf{i})'];
            nsa_qc.lw_nesr = [nsa_qc.lw_nesr, lw_nesr{i}];
            nsa_qc.wv_nesr = [nsa_qc.wv_nesr, wv_nesr{i}];
            nsa_qc.airTemp = [nsa_qc.airTemp, outAirTemp{i}.'];
            %nsa_qc.wv_resp = [nsa_qc.wv_resp, wv_resp{i}];
        end

        system(['mkdir ',pathwork]);
        save(fullfile(pathwork,'nsa_qc.mat'),'nsa_qc', '-v7.3');

    end
end


