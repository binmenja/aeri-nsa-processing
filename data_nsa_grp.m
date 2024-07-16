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
            %(iyear ==9) && (ismember(imonth,[1,2,3,4,5]));
            %(iyear==8)&&(ismember(imonth,[10,11,12]));
        ];

        if any(condition_list)
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
	    disp(size(nsa_qc.second,2)) 
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

            if (iyear == 18) && (ismember(imonth,[6,7,8])) % Hatch not closing properly, met flag has been used to discard HOUR where MET notices rain
                load("met_flag.mat")
                date_aeri = string(datestr(nsaC1.date,'yyyymmddHHMM'));
                wrong_logical = ismember(date_aeri, met_flag);
                iaeri = find(wrong_logical);                
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 4) && (ismember(imonth,[10])) % Detector temperature failure
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20011018","20011019","20011020","20011021","20011022","20011023","20011024"]
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 9) && (ismember(imonth,[6])) % Hatch not closing properly, met flag has been used to discard HOUR where MET notices rain
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20060627","20060628","20060629","20060630"]
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 10) && (ismember(imonth,[4])) % Snow in enclosure
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20070417","20070418"]
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 18) && (ismember(imonth,[7])) % detector temperature too high
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20150707","20150708","20150709"];
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                %disp(iaeri)
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end 
            if (iyear == 19) && (ismember(imonth,[2,9,11])) % Mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20160216","20160217","20160921","20160922","20160923","20160924","20160925","20160926","20160927","20160928","20160929","20160930","20161101","20161102","20161103","20161104","20161105","20161106","20161107"]
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 20) && (ismember(imonth,[6])) % Mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20170628","20170629"]
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
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
                clear iaeri date_aeri
            end
            
            if (iyear == 23) && (ismember(imonth,[3])) % mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20200313","20200314","20200315","20200316","20200317","20200318","20200319"] % Blizzard causing hatch issue 
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 23) && (ismember(imonth,[11,12])) % mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20201130","20201201","20201202","202001203","20201212","20201232","20201214"] % Multimeter malfunction
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
            if (iyear == 24) && (ismember(imonth,[9])) % mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20210906","20210907","20210908","20210909","20210910","20210911","20210912","20210913"] % Housekeeping Multimeter malfunction
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
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
                clear iaeri date_aeri
            end
            if (iyear == 25) && (ismember(imonth,[5,6])) % mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20220517","20220518","20220628","20220629"] % Keysight meters malfunction inducing poor calibration
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end

            if (iyear == 26) && (ismember(imonth,[1,2])) % mirror not rotating properly
                date_aeri = string(datestr(nsaC1.date,'yyyymmdd'));
                wrong = ["20230121","20230122","20230123","20230124","20230125","20230126","20230127","20230128","20230129","20230130","20230131","20230201","20230202","20230203"] % Keysight meters malfunction inducing poor calibration
                wrong_logical = ismember(date_aeri, wrong);
                iaeri = find(wrong_logical);
                nsaC1.radiance(:,iaeri) = [];
                nsaC1.lw_nesr_extrapolated(:,iaeri) = [];
                nsaC1.date(iaeri) = [];
                nsaC1.second(iaeri) = [];
                nsaC1.time(iaeri) = [];
                nsaC1.lwskynen_tf(iaeri) = [];
                nsaC1.lwskynen(iaeri) = [];
                nsaC1.airTemp(iaeri) = [];
                nsaC1.lw_nesr(:,iaeri) = [];
                nsaC1.dateraw(iaeri,:) = [];
                nsaC1.hatch(iaeri) = [];
                nsaC1.time1(iaeri,:) = [];
                nsaC1.time2(iaeri,:) = [];
                clear iaeri date_aeri
            end
        end
        nsaC1_total = nsaC1;

        system(['mkdir ',pathwork]);
        save(fullfile(pathwork,'nsaC1_total.mat'),'nsaC1_total', '-v7.3');
        disp('saved')
        noise(month_count).lwskynen = nsaC1.lwskynen;
        noise(month_count).lwskynen_tf = nsaC1.lwskynen_tf;
        noise(month_count).lwskynen = nsaC1.lwskynen;
        noise(month_count).second = nsaC1.second;
        noise(month_count).hatch = nsaC1.hatch;
    end
end

save(fullfile('/home/binmenja/direct/aeri/nsa/2023_rolls_2/','noise.mat'),'noise', '-v7.3');
