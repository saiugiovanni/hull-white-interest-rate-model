function [ZC_curve] = ZC_bootstrap(market_data)
%Bootstrap method to derive the curve of the discount factors
%   take a matrix containing date and rate for only swaps,
%   starting from those data the function compute the discount factor  
%
%INPUT:
% market_data: matrix containing expiries and MID values of swaps
%
%OUTPUT:
% ZC_curve: matrix containing expiries and zero rates for those swaps
%
%

% Initialize the values given
MID_swap = market_data(:,4)/100; % cambiato il 2 prima c'era un 4

dates_swap = market_data(:,1);

% Distance between dates_swap is constant, so:
delta =yearfrac( dates_swap(1),dates_swap(2),2); %act/360
%settlement=datenum(datetime(2000,12,31));
%deltas =yearfrac( settlement,dates_swap,2); %act/360
deltas=1.5;

len = length(dates_swap);
disc_swap = zeros(len,1);
disc_swap(1) = exp(-MID_swap(1)*delta);

% Compute all the discount factors
for i = 2:len
    temp =  sum (delta.*disc_swap(1:i,1));
    disc_swap(i) = (1 - MID_swap(i)*temp)/(1+delta*MID_swap(i));
end

% Convert from discount factor to zero rate
ZR = -log(disc_swap)./ deltas;

% Values returned
ZC_curve = [dates_swap, ZR];

end
