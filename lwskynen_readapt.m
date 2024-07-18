%% Program to find which values to discard based on the lwskynen values
load("/home/binmenja/projects/rrg-yihuang-ad/binmenja/aeri/nsa/2023_rolls_2/noise.mat")
year  = ["1998","1999","2000","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018","2019","2020","2021","2022","2023"];
months = 1:1:312;

%% Discard invalid noise and negative
for i =1:length(months)
    clear disc2
    %disc = find(nsaC1_lwskynen.hatch(i,:)~=1);
    disc2 = find(noise(i).lwskynen<0);
    noise(i).lwskynen_tf(disc2) = 0;
end
%% Find percent discarded during a stable period (2012-2015)
%period20122015 = 169:204;
correction_period =  57:81 % for sept 2002 to sept 2004
% Extract the lwskynen fields from elements 93 to 102
%lwskynen_corr_per = {noise(correction_period).lwskynen};
lwskynen_tf_corr_per = {noise(correction_period).lwskynen_tf};
hatch_corr_per = {noise(correction_period).hatch};

% Concatenate the fields horizontally
%flattened_lwskynen_corr_per = horzcat(lwskynen_corr_per{:});
flattened_lwskynen_tf_corr_per = horzcat(lwskynen_tf_corr_per{:});
flattened_hatch_corr_per = horzcat(hatch_corr_per{:});

flattened_lwskynen_tf_corr_per(flattened_hatch_corr_per~=1) = NaN;

keep_percent = sum(flattened_lwskynen_tf_corr_per==1)./sum(~isnan(flattened_lwskynen_tf_corr_per));
disp(keep_percent)
% for i = 1:length(length1_dis_p)
%     nsaC1_lwskynen.lwskynen(length1_dis_p(i),length2_dis_p(i)) = NaN;
% end


%% Adjust problematic period 1
%initial_problematic_period = 81:152; %period with NEN higher than usual
% Define the problematic period and the range to remove
%range_to_remove = 93:102;

% Use setdiff to remove the range from problematic_period
%problem_period = setdiff(initial_problematic_period, range_to_remove);
problem_period = 81:152;

% Flatten the array if necessary (depending on the structure of your data)
lwskynen_prob_per = {noise(problem_period).lwskynen};
flattened_lwskynen_prob_per = horzcat(lwskynen_prob_per{:});
hatch_prob_per = {noise(problem_period).hatch};
flattened_hatch_prob_per = horzcat(hatch_prob_per{:});
flattened_lwskynen_prob_per(flattened_hatch_prob_per~=1) = NaN;
isnt_nan_idx = ~isnan(flattened_lwskynen_prob_per);


% Calculate the proportion
disp('proportion less than two during problematic period:');
proportion = sum(flattened_lwskynen_prob_per<2)  / sum(~isnan(flattened_lwskynen_prob_per));
disp(proportion);



% Calculate the threshold value
threshold = prctile(flattened_lwskynen_prob_per(isnt_nan_idx), keep_percent*100);
disp(threshold)

noise_corrected = noise;
noise_corrected_2 = noise; % second dataset, more conservative
for i = 1:length(problem_period)
    noise_corrected(problem_period(i)).lwskynen_tf(noise_corrected(problem_period(i)).lwskynen<=threshold) = 1;
    noise_corrected_2(problem_period(i)).lwskynen_tf(noise_corrected_2(problem_period(i)).lwskynen<=2) = 1;
end


%

%% Save
%nsaC1_lwskynen_fixed = nsaC1_lwskynen.lwskynen_f;
save('noise_review.mat','noise_corrected', '-v7.3');
save('noise_2_review.mat','noise_corrected_2', '-v7.3');
disp("saved!")
%% Plot
%  tic
%  figure()
%  fig=gcf;
%  fig.Position(3:4)=[800,600];
%  plot(months,nsaC1_lwskynen.lwskynen,"k",'filled')
%  title("LWSKYNEN scatter (1000 cm^{-1})")
%  ylabel("LWSKYNEN Value (RU - mW(m^{2} sr cm^{-1}))")
%  xlabel("Date")
%  xticks(1:12:288)
%  xticklabels(year)
%  set_font_size(25)
%  toc


