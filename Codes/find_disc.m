function disc = find_disc(dates,discounts,dates_new) 
% function that computes discount factors at dates_new using discount curve obtained from bootstrap 
%
% INPUTS: 
% dates: dates of discount curve, output of bootstrap function 
% discounts: discount factors from discount curve, output of bootstrap function 
% dates_new: dates at which the function computes discount factors 
% 
% OUTPUTS: 
% disc: discount factors at dates_new 

settlement = dates(1); 
zRates = [1; zeroRates(dates, discounts)/100]; %zero rates at dates 

zRates_new = interp1(dates,zRates,dates_new); %zero rates at dates_new obtained interpolating on zero rates 

disc = exp(-yearfrac(settlement, dates_new(1:end), 3).*zRates_new); %discount factors at dates_new 
end