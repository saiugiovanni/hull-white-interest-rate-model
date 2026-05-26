function [dates] = paymentDates(startdate,years)
% Compute Payments  dates of the bond for n years 
% INPUT
%   dateSet = struct of dates for depos, futures and swaps
% OUTPUT
%   dates = Vector of Payment Dates for the bond
% FUNCTION
%   dateMoveVec = Moves a given date forward or backward by a given number of time units
%                   according to a given business days convention on a given market

datepart = 'y';
businessdayconvention = 'MF';
market = eurCalendar;
dates = zeros(1,years);

for i=1:years
    T = dateMoveVec(startdate, datepart,i, businessdayconvention, market);
    dates(i) = T;
end 

dates= dates';

end