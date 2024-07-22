clear;
close all;
clc;
addpath('/home/binmenja/direct/matlab/mylib')
month = ["01","02","03","04","05","06","07","08","09","10","11","12"];
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
noise = struct('second',[],'lwskynen',[],'lwskynen_tf',[],'hatch',[]);
for iyear=1:26
    for imonth=1:12
        month_count = (iyear - 1) * 12 + imonth;

        if should_skip(iyear, imonth)
            noise(month_count).lwskynen = [];
            noise(month_count).lwskynen_tf = [];
            noise(month_count).second = [];
            noise(month_count).hatch = [];
            continue;
        end
        bandsize=2904;
        clearvars -except bandsize iyear imonth month year noise month_count;% hatch_iteration;

        filefoldername = strcat('nsaC1_total_',year(iyear),month(imonth));
        pathwork = convertStringsToChars(strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/data_total/',filefoldername));

        monthlyfilename = strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/data_raw/nsaC1_raw_',year(iyear),month(imonth),'/nsaC1_raw.mat');
        monthlyfilename_qc = strcat('/home/binmenja/direct/aeri/nsa/2023_rolls_2/data_qc/nsa_qc_',year(iyear),month(imonth),'/nsa_qc.mat');
        load(monthlyfilename);
        load(monthlyfilename_qc);
        
        current_year = iyear+1997;
        current_month = imonth;
	    %disp(size(nsa_qc.second,2)) 
        if size(nsa_qc.second,2)>1
            day_total = nsa_qc.date-current_year*10000-current_month*100;
            day_total(day_total < 1 & day_total > 31) = NaN;
            day_unique = unique(day_total);
            nsaC1.radiance(nsaC1.radiance<=-9999)=NaN; % needs discussion with Yi
            nsaC1.radiance(nsaC1.radiance>9999)=NaN; % needs discussion with Yi

            [val,pos,pos2]=intersect(nsaC1.second,nsa_qc.second);
	        disp(length(val))
            %[val2,pos2]=intersect(nsa_qc.second,nsaC1.second);
            if (length(pos)) > 0 && (length(pos2)) >0
                nsaC1.second = nsaC1.second(pos);
                nsaC1.radiance =  nsaC1.radiance(:,pos);
                nsaC1.hatch = nsaC1.hatch(pos);
                nsaC1.dateraw = nsaC1.dateraw(pos,:);
                nsaC1.date = nsaC1.date(pos);
                if isfield(nsaC1,'time')==1
                    nsaC1.time = nsaC1.time(pos);
                end
                nsaC1.time1 = nsaC1.time1(pos,:);
                nsaC1.time2 = nsaC1.time2(pos,:);
                %nsaC1.lwhbbnen = nsa_qc.lwhbbnen(pos2);
                nsaC1.lwskynen_tf = nsa_qc.lwskynen_tf(pos2);
                nsaC1.lwskynen = nsa_qc.lwskynen(pos2);
                nsaC1.lw_nesr = nsa_qc.lw_nesr(:,pos2);
                nsaC1.airTemp = nsa_qc.airTemp(pos2);
                %nsaC1.LWresponsivity = nsa_qc.LWresponsivity(:,pos2);
                day = nsa_qc.date(pos2)-current_year*10000-current_month*100;
                nsaC1.wv_nesr = nsa_qc.wv_nesr;
                %nsaC1.wv_resp = nsa_qc.wv_resp;
            end
%             
            load('nsaC1_wnum.mat');
            for k=1:length(nsaC1.second)
                nsaC1.lw_nesr_extrapolated(1:bandsize,k) = interp1(nsaC1.wv_nesr(:,2),nsaC1.lw_nesr(:,k),nsaC1_wnum,'linear','extrap');
            end


            % Handle short period issues:
            nsaC1.date = datetime(1970,1,1,0,0,0,'Format','yyyyMMddHHmmss')+seconds(nsaC1.second);

            iaeri = shouldDiscard(iyear,imonth,nsaC1.date);
            size(iaeri)
            if sum(iaeri~=0)
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
            end
        end
        nsaC1_total = nsaC1;
        clear nsaC1;

        system(['mkdir ',pathwork]);
        save(fullfile(pathwork,'nsaC1_total.mat'),'nsaC1_total', '-v7.3');
        disp('saved')
        noise(month_count).lwskynen = nsaC1_total.lwskynen;
        noise(month_count).lwskynen_tf = nsaC1_total.lwskynen_tf;
        noise(month_count).lwskynen = nsaC1_total.lwskynen;
        noise(month_count).second = nsaC1_total.second;
        noise(month_count).hatch = nsaC1_total.hatch;
    end
end

save(fullfile('/home/binmenja/direct/aeri/nsa/2023_rolls_2/','noise.mat'),'noise', '-v7.3');
