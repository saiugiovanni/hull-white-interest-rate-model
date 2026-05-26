function [A_vec, B_vec] = Affine_trick(t, pricing_grid, a, sigma, ZC_curve)
% Compute A(t,T) and B(t,T) needed to pricing of a ZCB issued at t with maturity T
%
% INPUTS
% t:                ZCB issue date
% pricing_grid:     Vector of future maturities T_j
% a:                Rates Mean reversion speed parameter 'a' on the slides
% sigma:            Short-rate volatility 'sigma' on the slides
% ZC_curve:         Table of ZC rates (cont. comp. 30/360)
%
% OUTPUTS:
% A_vec:            Vector of A(t,T_j) computed at each maturity T_j in pricing_grid
% B_vec:            Vector of B(t,T_j) computed at each maturity T_j in pricing_grid
%
%
%

%%
% Computation of instantaneous forward rate f(0,t) through numerical derivative (backward method)
z_rates = @(t) interp1(ZC_curve(:,1), ZC_curve(:,2), t, 'linear', ZC_curve(1,2));

shift = 0.001;
t_shift = t - shift;
f_M = (t.*z_rates(t) - z_rates(t_shift) * t_shift)/shift ;  

P = @(t) exp(-z_rates(t).*t)';

% finds first maturity date (first date grater than issue date t)
index = find(pricing_grid > t, 1, 'first');  

B_vec = zeros(length(pricing_grid), 1);     
B_vec(index:end) = (1/a)*(1-exp(-a.*(pricing_grid(index:end)-t)));  

A_vec = zeros(length(pricing_grid), 1);
A_vec(index:end) = (P(pricing_grid(index:end))/P(t)).*...
    exp(B_vec(index:end)*f_M - sigma^2/(4*a)*(1-exp(-2*a*t))*B_vec(index:end).^2);
end