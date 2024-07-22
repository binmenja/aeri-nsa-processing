function discard = shouldDiscard(iyear, imonth, nsaC1_date)

    discard = [];
    % Convert the date to string format
    date_aeri = string(datestr(nsaC1_date, 'yyyymmddHHMM'));

    % Load met_flag.mat if year and month match specific conditions
    if (iyear == 18) && (ismember(imonth, [6, 7, 8]))
        load("met_flag.mat");
        discard = ismember(date_aeri, met_flag);
        return;
    end

    % Specific date checks based on year and month
    switch iyear
        case 4
            if imonth == 10
                wrong_dates = ["20011018", "20011019", "20011020", "20011021", "20011022", "20011023", "20011024"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 9
            if imonth == 6
                wrong_dates = ["20060627", "20060628", "20060629", "20060630"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 10
            if imonth == 4
                wrong_dates = ["20070417", "20070418"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 18
            if imonth == 7
                wrong_dates = ["20150707", "20150708", "20150709"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 19
            if ismember(imonth, [2, 9, 11])
                wrong_dates = ["20160216", "20160217", "20160921", "20160922", "20160923", "20160924", "20160925", "20160926", "20160927", "20160928", "20160929", "20160930", "20161101", "20161102", "20161103", "20161104", "20161105", "20161106", "20161107"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 20
            if imonth == 6
                wrong_dates = ["20170628", "20170629"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 23
            if imonth == 3
                wrong_dates = ["20200313", "20200314", "20200315", "20200316", "20200317", "20200318", "20200319"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            elseif ismember(imonth, [11, 12])
                wrong_dates = ["20201130", "20201201", "20201202", "20201203", "20201212", "20201213", "20201214"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 24
            if imonth == 9
                wrong_dates = ["20210906", "20210907", "20210908", "20210909", "20210910", "20210911", "20210912", "20210913"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 25
            if ismember(imonth, [5, 6])
                wrong_dates = ["20220517", "20220518", "20220628", "20220629"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
        case 26
            if ismember(imonth, [1, 2])
                wrong_dates = ["20230121", "20230122", "20230123", "20230124", "20230125", "20230126", "20230127", "20230128", "20230129", "20230130", "20230131", "20230201", "20230202", "20230203"];
                discard = checkDates(date_aeri, wrong_dates);
                return;
            end
    end
end

function discard = checkDates(date_aeri, wrong_dates)
    discard = ismember(date_aeri, wrong_dates);
end