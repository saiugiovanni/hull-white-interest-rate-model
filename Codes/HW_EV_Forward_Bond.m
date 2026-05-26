function Forward_Bond=HW_EV_Forward_Bond(settlement,issue,maturity,a,sigma,B_t0,Nsim) 
%  This function computes the forward bond using the Hull-White Extended Vasicek
%  model. The forward Bond computed is the one which is issued at "issue" date s 
%  with s>t_0 ( t_0 = settlement ) and has same expiry of the bond issued at 
%  settlement t_0. 
%  
%  INPUT 
%  settlement = settlement date of our contract
%  issue = issue date of the bond we compute 
%  maturity = maturity date of the bonds
%  a = mean reversion rate
%  sigma: annual standard deviation of the short rate 
%  B_t0 = disocunt value that we have already computed. 
%  Nsim= number of simulation
%  
%  OUTPUT
%  Forward_Bond = value of the forward bond.
%  
 
act=2; %act/360
Ta=yearfrac(settlement,issue,act); % time step between t_0 and t_i ( 6 months ) 

x0=0; % at time t0
dt=Ta; % 6 months is our step 
mu_hat=1-exp(-a*dt);
sigma_hat=sigma*sqrt((1-exp(-2*a*dt))/(2*a));
rng(1);
dx1=-mu_hat*x0+sigma_hat*rand(Nsim,1); % we simulate x1 
% dx1=x1-x0 where x0=0 and x1 is the dynamics at first time step which we
% consider to be 6 months (formulas from slides StructuredProductsIR pag 30-31 of professor Baviera)

integrand=@(u) ( (sigma.*((1-exp(-a*(maturity-u)))./a)).^2 - (sigma.*((1-exp(-a*(issue-u)))./a)).^2 );
tau=yearfrac(issue,maturity,act);
sigma_tau=sigma*((1-exp(-a*(tau)))/a);
Forward_Bond = B_t0 *exp( -dx1.*(sigma_tau/sigma) -0.5 .* quadgk( integrand, 0, dt ));

end 