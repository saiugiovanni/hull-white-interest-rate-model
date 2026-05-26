function [total_dates, total_discount] = bootstrap(settlement,dates_depos,dates_Swap,market_data3)
% This function makes a boostrap computation and it returns the
% bootstraped dates and discounts 
% INPUT
% settlement: settlement date
% dates_depos: depos dates 
% dates_Swap: Swap dates
% market_data3: it contains information about maturities and Bid/Ask rate of both 
%               Money Market Deposits and Interest Rate Swaps (IRS)
%               
% OUTPUT
% total_dates: bootstrapped dates 
% total_discount: bootstrapped discounts

% I compute the MID rate for both Depos and Swap 
Data_Depos=[market_data3(15:16,2:3)];
L_rates_D=(Data_Depos(:,1)+Data_Depos(:,2))/2;

Data_Swap=[market_data3(1:10,2:3)];
L_rates_S=(Data_Swap(:,1)+Data_Swap(:,2))/2;

% I compute the discount for depos
depos_discount(1:2)= 1 ./(1+yearfrac(settlement,dates_depos(1:2),2) .* L_rates_D(1:2));
% I add such values to the total discount vector. 
total_discount=[1;depos_discount'];

BVPpart = 0;
dates=[settlement;dates_depos];
ZeroRate = zeroRates(dates, total_discount)./100;
% initialZeroRates = interp1(dates(2:end),ZeroRate(2:end),dates_Swap(1), 'linear');
discount_sim =  exp(-ZeroRate(end) .* yearfrac(dates(1), dates_Swap(1), 3));
 % for the first delta we need a special case
lastInterval = yearfrac(settlement, dates_Swap(1), 6);
BVPpart = BVPpart + lastInterval*discount_sim;
total_discounts=zeros(10,1);
total_discounts(1) = ...
        (1-L_rates_S(1)*BVPpart)/(1+L_rates_S(1)*lastInterval);
    
for n = 2:10
    lastInterval = yearfrac(dates_Swap(n-1), dates_Swap(n), 6);
    total_discounts(n) = ...
        (1-L_rates_S(n)*BVPpart)/(1+L_rates_S(n)*lastInterval);
    
    % BPVpart = sum( delta*B ) without last payment is cumulative,
    % as Swaps share fixed-leg payment dates. 
    % we update BPV at each iteration
    BVPpart = BVPpart + lastInterval*total_discounts(n);
    % red_dates((n-1)+Count) = total_dates (n+datesCount);
end

total_dates=[dates;dates_Swap];
total_discount=[total_discount;total_discounts];

end 