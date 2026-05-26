function BPV = calcBPV_fwd(Ta, paymentdates, discountCurve)
% Computes the BPV on the corrisponding dates of paymentdate given the
% curve dates, discounts.
%
% INPUT
%  Ta:date of maturity of the swaption
%  paymentdate: vector of dates correspoding to the BPV calc
%  discountCurve: struct with date and discount from the bootstrap
%
% OUTPUT
% BPV
%
%

%%
thirty360 = 6;

dt = yearfrac([Ta; paymentdates(1:end-1)],...
    paymentdates,thirty360);

B = find_disc(discountCurve.dates,discountCurve.discounts,paymentdates)/...
    find_disc(discountCurve.dates,discountCurve.discounts,Ta);

BPV = dt'*B;   

end