function [] = exercise3()
%% Request 3
clear all 
clc 
%%
% We derive from the time series of the 6m Libor, 1y IRS, 2y IRS rate the 
% time series of the zero-coupon curves (defined on three nodes: 6m, 1y, 2y) 
% at semiannual frequency (last working day of the semester) from H1-2001 to 
% H2-2015 and, based on these time series, we evaluate the historical (real-word) 
% distribution of realized percentage return of the investment into a 
% zero-coupon bond with 18 months original maturity sold six months later
%% load data
load('FRED_IRS.mat');
market_data1=mktDatawithFRED;
load('FRED_6m_LIBOR.mat');

%% Import only business dates every 6 months through the function dateMoveVec

startdate=datenum(datetime(2000,12,31));

for i=1:30    
market=market_data1(:,1);
datepart='m';
num=6;
businessdayconvention='MF';
t(i)=dateMoveVec(startdate, datepart, num, businessdayconvention, market);
startdate=t(i);
end
%% Import rates at 1y and 2y
load('market1_string.mat')
market_data5=mktDatawithFRED(:,1);
market_data1(:,1)=datenum(market_data5,'dd-mm-yyyy');
market_data1;

%% Import rates at 6 months (libor)
load('FRED_6m_LIBOR.mat');
market_data2=mktDatawithFREDS1;
load('market2_string.mat')
market_data4=mktDatawithFREDS1(:,1);
market_data2(:,1)=datenum(market_data4,'dd-mm-yyyy');
market_data2;
%% We create a single matrix with only the dates each 6 months
matrice=[zeros(length(t),5)];
k=1;
 for j=1:length(market_data1)
     if market_data1(j,1)==t(k)
         matrice(k,1)=t(k);  % date derived from the vector which contains 
                             % all the correct data (last business day of 
                             % the 6 months period)
         matrice(k,2)=0; % we will insert later the 0.5y values
         matrice(k,3)=market_data1(j,2); % 1y values
         matrice(k,4)=0; % we will insert later the 1.5y values
         matrice(k,5)=market_data1(j,3); % 2y values
         k=k+1;
     end
    
     if k==31 % we inserted all the data so we end the for cycle
         break
     end
 end
%% We do the same procedure to insert the libor 
k=1;
 for j=1:length(market_data2)
     if market_data2(j,1)==t(k)
         matrice(k,2)=market_data2(j,2); % 0.5y values
         k=k+1;
     end
    
     if k==31
         break
     end
 end
%% We interpolate in order to find the 1.5y values to fill the fourth column of the matrix
temp=[0.5 1 2];
midswap=zeros(length(matrice),1);
for i=1:length(matrice)
    a=[matrice(i,2) matrice(i,3) matrice(i,5)];
midswap(i) = interp1(temp,a, 1.5, 'linear');  
matrice(i,4)=midswap(i); %insert in the matrix
end

%% We extrapolate the rates at our settlement date and six months later based on the historical rates
t_0=datenum(datetime(2016,5,26)); %settlement date
t_6m=datenum(datetime(2016,11,25)); %six months later

rates_0 = interp1(matrice(:,1), matrice(:,2:5), t_0, 'linear','extrap'); 
rates_6m= interp1(matrice(:,1), matrice(:,2:5), t_6m, 'linear','extrap');
% We add the new rates into the matrix
matrice=[matrice;
    t_0 rates_0;
    t_6m rates_6m
    ];

%% Computation of the zc curve derived from the rates
matrice=matrice';
% We take into consideration the 1y 1.5y and 2y irs given that we will need only them later on
temp=[1 1.5 2]'; 

ZC=[temp']; %initialization
for i=1:length(matrice)
    % Market data with mid rates taken at 1 1.5 and 2 years
    market_data=[temp matrice(3:5,i)]; 
    Zrates=ZC_bootstrap_IRS_only(market_data);
    rates=Zrates(:,2)';
    ZC=[ZC;
        rates];
end
% ZC contains the dates and the respective zero rates 
ZC;

%% price of the zero coupon bond
% Given that we buy a zero coupon bond with 18m maturity left, we at first 
% calculate how much it would have cost to buy it at each semester and 
% we will have a curve of historical prices 
Price_bond_18m=exp(-ZC(2:end,2)*ZC(1,2));
mean_Price_bond_18m=mean(Price_bond_18m);
std_Price_bond_18m=std(Price_bond_18m);

% Then, we assume that when we will sell the zero coupon bond six months
% later it will have 1y maturity left, so we consider how much it would have
% cost to buy a 1y maturity zero coupon bond during those years and we
% obtain our second curve of prices
Price_bond_12m=exp(-ZC(2:end,1)*ZC(1,1));
mean_Price_bond_12m=mean(Price_bond_12m);
std_Price_bond_12m=std(Price_bond_12m);

%% rate distribution
% as in previous point in order to calulate the rate we exploit the formula
% Rate of return = [(Current value - Initial value) / Initial Value ] * 100

% In this case we take as initial value the Price_bond_18m(end-1) which is
% the value we assume we will buy a bond at settlement date (end-1 corresponds to 26 may 2016)
% and we take as selling value the whole historical distribution of prices
% of 12m zero coupon bonds because we assume it would be a more precise
% comparison than to only take the extrapolated price of the last date

rate_distribution =(( Price_bond_12m(1:end) - Price_bond_18m(end-1) ) / Price_bond_18m(end-1) )*100;


mean_rated=mean(rate_distribution);
std_rated=std(rate_distribution);

disp(['Real World Approach'])
disp(' ')
disp(['Values obtained considering the extrapolated 18m zcb and the whole series of 12m zcb'])
disp(['Expected return rate of our investment (real world approach): ', num2str(mean_rated)])
disp(['Standard deviation rate of our investment (real world approach): ', num2str(std_rated)])
disp(' ')

% If we consider as selling price only the 12m zero-coupon bond price
% extrapolated on november, 24th 2016 we have
rate =(( Price_bond_12m(end) - Price_bond_18m(end-1) ) / Price_bond_18m(end-1) )*100;
disp(['Value obtained considering both the extrapolated 18m zcb and 12m zcb'])
disp(['Expected return rate of our investment (Real-World approach): ', num2str(rate)])

%% plot
% Comparison between the trajectory of the prices of a zero coupon bond 18m
% with the ones of a zero coupon bond 12m valuated at the following semester

Price_bond_12m_shifted=Price_bond_12m(2:end); %one semester later
figure
title('Historical prices of 18m and 12m zero coupon bonds')
hold on
plot(matrice(1,1:end-1),Price_bond_18m(1:end-1),'g->',matrice(1,2:end),Price_bond_12m_shifted,'y->')
datetick('x','dd/mmm/yyyy','keepticks','keeplimits')
legend('ZCB 18m','ZCB 12m')

%% Plot
% Distribution of the return of the investment
figure
title('Distribution of the return of the investment')
hold on
plot(matrice(1,1:end),rate_distribution,'r',matrice(1,1:end),mean_rated,'g->')
datetick('x','dd/mmm/yyyy','keepticks','keeplimits')
legend('return on the investment', 'mean rate of return')

end