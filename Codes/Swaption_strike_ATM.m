function strike_swaption = Swaption_strike_ATM(D1, D2, discountCurve)
% Compute the swaption price with Jamshidian Formula
% 
% INPUT
%  D1: maturity of the swaption
%  D2: maturity of the swap
%  discountCurve: struct with date and discount from the bootstrap
%
% OUTPUT
%  strike 
%
%
    
%% dates
datepart = 'y';
businessdayconvention = 'MF';
market = eurCalendar;
setDate = discountCurve.dates(1);

Ta  = dateMoveVec(setDate, datepart, D1, businessdayconvention, market);
couponsPaymentDates = paymentDates(Ta,D2);

%% yearfrac
thirty360 = 3;
dt_a  = yearfrac(setDate, Ta, thirty360);
dt_0i = yearfrac(setDate, couponsPaymentDates, thirty360); 

% discounts
Ba  = find_disc(discountCurve.dates, discountCurve.discounts, Ta);
B0i = find_disc(discountCurve.dates, discountCurve.discounts, couponsPaymentDates)/Ba;

% strike ATM
BPV = calcBPV_fwd(Ta, couponsPaymentDates, discountCurve);
strike_swaption = (1-B0i(end))/BPV;
end