function [] = exercise1and2(flag)
% Resolution of requests 1 , 2, 5 
% This function takes in input a flag which will be used as follows:
% flag=0      Calibration with reference to the 6 months swaption
%             volatilities (Request one)
% flag=1      Calibration with reference to the 3 years swaption
%             volatilities (Request five)
% 
%% First Request

%%
% We import from Excel the tables containing Interest Rate Swaps and 
% Money Market Deposits 
load('USD_MM_IRS_and_Swaption.mat');
market_data3=mktDatawithFREDS2;

settlement = datenum(datetime(2016,5,26));
% Selecting depos dates
dates_depos=[datenum(datetime(2016,8,26))
             datenum(datetime(2016,11,28))];

% Selecting Swap dates (annual dates considering only business days)
dates_Swap=[datenum(datetime(2017,5,26))
            datenum(datetime(2018,5,28))
            datenum(datetime(2019,5,27))
            datenum(datetime(2020,5,26))
            datenum(datetime(2021,5,26))
            datenum(datetime(2022,5,26))
            datenum(datetime(2023,5,26))
            datenum(datetime(2024,5,27))
            datenum(datetime(2025,5,26))
            datenum(datetime(2026,5,26))];

%  bootstrap of the curve containing depos and swap     
[total_dates, total_discount] = bootstrap(settlement,dates_depos,dates_Swap,market_data3);
% derive the zero rates from the discount curve
ZeroRate = zeroRates(total_dates, total_discount)./100;

%% Plot Discounts and Zero Rates
figure
title('Bootstrap')
hold on

%discount curve
yyaxis left
plot(total_dates,total_discount,'b->')
datetick('x','dd/mmm/yyyy','keepticks','keeplimits')
ylim([0.8 1.0])

%zero-rates
yyaxis right
plot(total_dates(2:end),ZeroRate.*100,'r-d')
datetick('x','dd/mmm/yyyy','keepticks','keeplimits')
ylim([0.3 2])
legend('Discount Curve','Zero Rates Curve')
%% Calibration 
% Calibration with reference to the 6 months swaption volatilities if flag=0
% Calibration with reference to the 3 years swaption volatilities if flag=1

[a,sigma]=Calibrate_HW_EV(settlement,total_dates,total_discount,ZeroRate,market_data3,flag);
clc
if flag == 0 
    disp(['Calibration of the Single-factor Hull-White Extended Vasicek model to the options with maturity 6 months'] )
end 
if flag == 1
    disp(['Calibration of the Single-factor Hull-White Extended Vasicek model to the options with maturity 3 years'] )
end  
disp(' ')
disp(['Parameter a derived from calibration: ', num2str(a)] )
disp(['Parameter sigma derived from calibration: ', num2str(sigma)])
disp(' ')
%% We compute B(t=0;Ta=0.5,Ti=1.5)
% This is the discount of a financial isntrument issued today that will
% start in six months and end in a year and an half

% B(t=0;Ta=0.5,Ti=Ta+1) = B(t=0,Ta+1=1.5) / (B(t=0,Ta=0.5));
% In order to find B(t=0,Ta+1) we need to interpolate the zero rate. 
ZR=[0; ZeroRate];
t_1y6m=datenum(datetime(2017,11,25));
% zero rate at 1y and 6m
ZR_1y6m= interp1(total_dates,ZR, t_1y6m, 'linear'); 

% We add the zero rate at 1y6m in the zero rate vector and also the date in
% total_dates. 
ZR=[ZeroRate(1:4); ZR_1y6m; ZeroRate(5:end)];
total_dates=[total_dates(1:4); t_1y6m; total_dates(5:end)];

% From the zero rates interpolated we derive the discounts
disc_6m=exp(-(ZR(3)*yearfrac(total_dates(1),total_dates(3),2)));
disc_1y6m=exp(-(ZR(5)*yearfrac(total_dates(1),total_dates(5),2)));
% We compute B(t=0;Ta=0.5,Ti=1.5)
disc_0_6m_1y6m=disc_1y6m/disc_6m;

%% We compute B(0.5,0.5,1.5) with Girsanov and Corollary of Lemma 1 

% This is the discount of a financial isntrument issued in six months that 
% will start immediately and end one year from then

% 6 months later
issue=datenum(datetime(2016,11,25)); 
% 1 year and  6 months later, we take the previous business day, since  
% the 26/11/2017 was holiday
maturity=datenum(datetime(2017,11,24)); 
dT=yearfrac(issue,maturity,2); %act/360
% Computation of the distribution of B(0.5,0.5,1.5) through simulation

% We choose as number of simulation 500,because among different trials 
% it seems to be a good compromise between computational runtime and 
% precision of results
Nsim=500;
          
B_6m_6m_1y6m = HW_EV_Forward_Bond(settlement,issue,maturity,a,sigma,disc_0_6m_1y6m,Nsim);

% We derive the zero rate
zerorate = -log(B_6m_6m_1y6m)./ dT;
% Price of the Bond 
Price_bond_zr=exp(-zerorate*dT); 
% For the sake of completeness we compute the mean, the variance and 
% the confidence interval of the distribution
[Check_mean,Check_std,Check_IC]=normfit( B_6m_6m_1y6m);
B_6m_6m_1y6m_mean=mean(Price_bond_zr);
B_6m_6m_1y6m_std=std(Price_bond_zr);

disp(['Expected value of the forward price of the zcb: ', num2str(B_6m_6m_1y6m_mean)])
disp(['95% confidence interval of the forward price of the zcb: [', num2str(Check_IC(1)),',',num2str(Check_IC(2)),']'])
disp(['Standard deviation of the forward price of the zcb: ', num2str(B_6m_6m_1y6m_std)])
disp(' ')
%% Request 2
%%
% You are an investor in fixed-income instruments. Derive from the results of the point i) the 
% (risk-neutral) expected percentage return and its standard deviation of the following 
% investment: buy on May 26th, 2016 a USD zero-coupon bond with maturity 18 months and sell 
% it six months later.
%%
% From point i) we have B(t=0.5,Ta=0.5,Ti=1.5) and B(t=0,Ta=0.5,Ti=1.5)
% In order to estimate the return we assume we can consider our investment
% as follows:
%   -we buy a 18 months zcb now and therefore we calculate its price
%   -we seel it six months later therefore we use its estimated value already computed in point i)
%%

%% Price of a 18 months zcb issued today. We use Hull-White model and therefore affine trick
% Reference page 122 of Brigo Mercuri
%% dates
act=2; %act/360
settlement = datenum(datetime(2016,5,26));
issue=datenum(datetime(2016,5,26)); % same day
% We take the previous business day since the 26/11/2017 was holiday
maturity=datenum(datetime(2017,11,24)); 
dT1=yearfrac(settlement,maturity,act); 

%% We compute the ZC_curve giving the following input matrix
%  INPUT data are stored as:
%  Market_data: table of ICAP quotes for the strip of IRS
%       Column #1: IRS maturity (year frac)
%       Column #2: MID rate


temp=[1:10]';
maturities=[0.25; 0.5; temp];
ZC_curve = [maturities ZeroRate]; % From point 1

%% Grid construction for affine trick
% Since we have a zero coupon bond we have only one payment date at
% maturity and its value will be the face value as follows: 
pricing_grid=dT1; %payment date

%% Affine Trick
%   Pricing of a ZCB issued at t with maturity T is given by Brigo-Mercurio
%   3.39: P(t,T) = A(t,T) * exp(-B(t,T)*r(t)) 
%   Given t=0 and a future maturity T_j (stored in input vector
%   pricing_grid), corresponding values of A(t,T) and B(t,T) are stored in 
%   the (vector) function outputs: A_vec, B_vec
%   function [ A_vec, B_vec ] = Affine_trick( t, pricing_grid, a, sigma, ZC_curve )

t = 0; % start date of the bond
[A_vec, B_vec] = Affine_trick(t, pricing_grid, a, sigma, ZC_curve );

% We need spot rate r(t) in t=0 therefore we interpolate the zero curve
spot_rate = interp1(ZC_curve(:,1), ZC_curve(:,2), 0, 'linear','extrap'); %r(t)
% Finally, we compute the price through the formula
P_vec = (A_vec .* exp( - B_vec * spot_rate));

disp(['Price of the 18m ZCB: ', num2str(P_vec)])
disp(' ')

%% In order to calculate the expected percentage return we use the following formula
% Rate of return = [(Selling value - Initial value) / Initial Value ] * 100

rate_distribution =((B_6m_6m_1y6m-P_vec)./(P_vec)).*100; 
% where P_vec is the price at which we buy the asset 
% while B_6m is the value at which we expect to sell it six months later
% (derived from the distribution of point 1)

% we compute mean standard deviation and 95% confidence interval of the distribution
[Check_mean,Check_std,IC]=normfit( rate_distribution);
expected_return_ratedistribution = mean(rate_distribution);
standard_dev_ratedistribution = std(rate_distribution);

disp(['Expected return rate distribution of the investment: ', num2str(expected_return_ratedistribution)])
disp(['95% confidence interval of the distribution of the investment: [', num2str(IC(1)),',',num2str(IC(2)),']'])
disp(['Standard deviation rate distribution of the investment: ', num2str(standard_dev_ratedistribution)])

%% plot the forward price simulation in comparison with the price at which we buy the bond
figure
plot(Price_bond_zr,'g')
hold on
plot(0:500,B_6m_6m_1y6m_mean*ones(1,501),'bo')
hold on 
plot(0:500,P_vec*ones(1,501),'r*')
title('Simulated Price')
legend('Simulated selling price','Expected value of the selling price','Buying price')


%% plot the return distribution
figure
plot(rate_distribution,'y')
hold on
plot(0:500,expected_return_ratedistribution*ones(1,501),'bo')
title('Return distribution and its mean value')
legend('Return distribution','Mean value')

end