function zRates = zeroRates(dates, discounts)
%Compute the zero rates starting from a set of dates and the corresponding 
% discount factor 
%
% INPUT:
% dates: settlement date and expiries of quoted underlying
% discounts:  IB discount factors of quoted underlying in percantage (ex.
% 2.13 is 2.13%)
%
% OUTPUT:
% zRates:  zero rates

%% Zero Rates formula
zRates = -100*log(discounts(2:end))./ (yearfrac(dates(1),dates(2:end),2)); % 3 - actual/365;                                

end 
