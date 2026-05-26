# Hull-White Extended Vasicek Interest Rate Model

This repository contains a university project developed during my MSc in Mathematical Engineering, with a focus on Quantitative Finance and Financial Engineering.

The project focuses on interest rate modelling using the one-factor Hull-White Extended Vasicek model. It includes yield curve construction, calibration to swaption market data, and the comparison between risk-neutral and historical real-world distributions for a fixed-income investment.

## Main objectives

- Bootstrap discount and zero-coupon curves from money market deposits and interest rate swaps
- Calibrate the Hull-White Extended Vasicek model to market swaption volatilities
- Price forward-starting zero-coupon bond investments
- Compare risk-neutral and historical return distributions
- Analyse fixed-income investment opportunities under different calibration assumptions

## Repository structure

- `Codes/` contains the MATLAB implementation
- `run_finalproject_RM5_Group1.m` is the main script to run the project
- `exercise1and2.m` implements the first, second and fifth requests of the project
- `exercise3.m` implements the historical real-world distribution analysis
- `.mat` and `.xlsx` files contain the market data used in the analysis
- `Project_RM_5.pdf` contains the project assignment
- `Report-Final_Project_RM5_Group1.pdf` contains the final report

## How to run the code

Open MATLAB and set the working directory to the `Codes/` folder.

Then run:

```matlab
run_finalproject_RM5_Group1
