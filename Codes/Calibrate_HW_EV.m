function [A,Sigma]=Calibrate_HW_EV(settlement,total_dates,total_discount,ZeroRate,market_data3,flag)

%  This function calibrates the Single-factor Hull-White Extended Vasicek 
%  (1994) model in order to find the a and sigma parameters. 
%  INPUT 
%  settlement: settlement date
%  total_dates: vector of maturity dates 
%  total_discount: vector of total disocunt values in the maturity dates
%  ZeroRate: vector of the zero rates 
%  market_data3: USD MM IRS and Swaptions market data 
%  flag:
%     flag = 0 : options with maturity 6 months 
%     flag = 1 : options with maturity 3 years 
% 
%  OUTPUT
%  A: mean reversion rate
%  Sigma: annual standard deviation of the short rate 

%% We construct the discount Curve struct
D2=[1;2;3;4;5]; % Swap maturities 
if flag == 0 
    D1=0.5; % Maturity of the swaption. 
end 
if flag == 1 
    D1=3; % Maturity of the swaption. 
end

% We create the discountCurve struct 
discountCurve.dates=total_dates;
discountCurve.discounts =total_discount;

% We compue the swaption strike
for i=1:5
    strike(i)= Swaption_strike_ATM(D1, D2(i), discountCurve);
end
strike_swaption=strike';

% Now we construct the interest-rate curve object from dates and data
Dates_curve=total_dates(2:end);
IR_termstructure = intenvset('Rates',ZeroRate,'EndDates',Dates_curve,'StartDate',settlement);

Maturity_5y = datenum('26-May-2021');

if flag == 0 
    ATM_Swaptions_Black_Volatilities=market_data3(3,7:11)'; 
    Swaption_date = 2; % it refers to 6 months 
end 

if flag == 1 
    ATM_Swaptions_Black_Volatilities=market_data3(8,7:11)'; 
    Swaption_date = 3; % it refers to 3 years
end 
IRS_maturities=[1:5];

Bond_exercise_dates = repmat(daysadd(settlement,Swaption_date*360,1)',length(IRS_maturities),1); 
%   Bond_exercise_dates = datenum(datetime(2016,11,28))*ones(5,1);
Maturity = reshape(daysadd(Bond_exercise_dates,repmat(360*IRS_maturities,1,length(Swaption_date)),1),size(Bond_exercise_dates));
% Find the swaptions that expire on or before the maturity date of the
% sample swaption
swaptions_before_mat = find(Maturity <= Maturity_5y); % price of the swaption before maturity 

for j=1:length(IRS_maturities)
    [~,Strike_Swaption(j,1)] = swapbyzero(IR_termstructure,[NaN 0], settlement, Maturity(j,1),...
        'StartDate',Bond_exercise_dates(j,1),'LegReset',[1 1]);
    Price_s(j,1) = swaptionbyblk(IR_termstructure, 'call', Strike_Swaption(j,1),settlement, ...
        Bond_exercise_dates(j,1), Maturity(j,1), ATM_Swaptions_Black_Volatilities(j,1));
end

%%  Trinomial tree to calibrate

% We compute the time structure for a Hull White tree.
HW_time = hwtimespec(settlement,daysadd(settlement,360*(1:6),1), 2);

% Price of the swaptions that expire befor the maturity via Black model 
Price_till_Maturity= Price_s(swaptions_before_mat);

% We exploit the matlab function "hwvolspec" in order to find the Structure specifying 
% the volatility model for HWTREE
if flag == 0 
    Reference_date=datenum(datetime(2016,11,26)); % 6 months after settlement date 
end 

if flag == 1
    Reference_date=datenum(datetime(2019,05,27)); % 3 years after settlement date 
end 

% Since we are calibrating in order to find a and sigma, we use a
% function handle in which param(1)=a and param(2)=sigma relative to our
% 6 months reference date. 
HW_IR_Vol_process=@(param) hwvolspec(settlement,Reference_date,param(2),Reference_date,param(1),'linear');

% We exploit the matlab function "hwtree" in order to build a Hull White
% interest rate tree
HW_IR_Tree=@(param) hwtree(HW_IR_Vol_process(param), IR_termstructure, HW_time);
% We obtain a Structure containing time and interest rate information of a 
% trinomial recombining tree.

% Now we want to price a swaption from a Hull White interest rate tree, we
% use the Matlab function "swaptionbyhw"
Swaption_Price=@(param) swaptionbyhw(HW_IR_Tree(param), 'call', strike_swaption(swaptions_before_mat),...
    Bond_exercise_dates(swaptions_before_mat),0, Bond_exercise_dates(swaptions_before_mat),...
    Maturity(swaptions_before_mat)); 
 
% Now we compute the difference between the prices via Black Model and
% prices via Tree approach  
HW_param_function =@(param) Price_till_Maturity -  Swaption_Price(param);

% In order to minimize the L2 price-distance we use the Matlab function
% lsqnonlin which solves non-linear least squares problems

% Firstly, we create an optimization OPTIONS structure containing all the
% parameter names and default values relevant to the function needed for
% the minimization.
options = optimset('disp','iter','MaxFunEvals',1000,'TolFun',1e-5);

% We set the matrix x0 from which "lsqnonlin" should start
x0 = [0.01 0.05];
% We define a set of lower and upper bound bounds on the design variables,
% X, so that the solution will be in this range. 
lb = [0 0];
ub = [1 1];
Params = lsqnonlin(HW_param_function,x0,lb,ub,options);

% We obtain the following param
A = Params(1);
Sigma = Params(2);

if flag == 0
    % Now we plot the evolution of the zero curve 
    nPeriods = 20; % 20 semesters in 10 years
    DeltaTime = 0.5; % we consider half year as step 

    Semesters = (1:20)';
    Dates = daysadd(settlement,360*DeltaTime*(0:nPeriods),1);
end 

if flag == 1
     % Now we plot the evolution of the zero curve 
    nPeriods = 10; % 10 years
    DeltaTime = 1; % we consider a year as step 

    Semesters = (1:10)';
    Dates = daysadd(settlement,360*DeltaTime*(0:nPeriods),1);
end 
    
% We create a Hull White 1 Factor Model
HW1F = HullWhite1F(IR_termstructure,A,Sigma);

% We simulate term structure using the simTermStructs method with the HullWhite1F model.
HW1FSimPaths = HW1F.simTermStructs(nPeriods,'NTRIALS',1000,'DeltaTime',DeltaTime,'Tenor',Semesters,'antithetic',true);
figure
surf(Semesters,Dates,HW1FSimPaths(:,:,1))
datetick y keepticks keeplimits
title(['Evolution of the Zero Curve of Hull White Model'])
if flag == 0 
    xlabel('Number of semesters')
end

if flag == 1
        xlabel('Number of years')
end 


