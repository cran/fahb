
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fahb <a href="https://lictr.github.io/fahb/"><img src="man/figures/logo.png" align="right" height="139" alt="tout website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/lictr/fahb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lictr/fahb/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/DTWilson/fahb//branch/main/graph/badge.svg)](https://app.codecov.io/gh/DTWilson/fahb)
<!-- badges: end -->

The goal of `fahb` is to help with clinical trial **f**easibility
**a**ssessment via **h**ierarchical **B**ayesian recruitment models,
fitted to (internal or external) pilot date. It can be used at the
design stage to optimise the pilot and any pre-specified decision rules
to guide progression, and at the analysis stage to produce a
probabilistic prediction of the time until the main trial recruits to
target.

## Installation

Install the released version of `fahb` from CRAN:

``` r
install.packages("fahb")
```

Or you can install the development version of `fahb` from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("DTWilson/fahb")
```

## Example

Suppose we are planning an internal pilot for a trial which aims to
recruit `N = 320` participants from `m = 20` sites, and that we expect
recruitment to complete in three years. The pilot analysis will happen
at `t = 0.5` years, and we would class the trial as infeasible if
recruitment took longer than `rel_thr = 1.2` times the expected
recruitment time.

The variables `N, m, t` and `rel_thr` define the design variables. For
the model parameters, for the purpose of illustration we use the package
defaults (but see the vignette and the associated paper for more
discussion of these). To use `fahb` we first encode all design variables
and model parameters in a `fahb_problem` object, then run some
simulations via `forecast()` before finding possible decision rules and
the operating characteristics they lead to:

``` r
library(fahb)

problem <- fahb_problem(N = 320, m = 20, t = 0.5, rel_thr = 1.2)

# Run the simulations
problem <- forecast(problem)

# Find some candidate decision rules are their OCs
design <- fahb_design(problem)

print(design)
#> Standard progression criteria
#> 
#>     FPR        FNR         n_p         m_p        r_p
#> 1   0.0 0.87800497 14.89113845  5.23821827 11.2983982
#> 11  0.1 0.47333518  9.75445041 -0.09309377  6.6868158
#> 21  0.2 0.33766234  5.58934399  0.63584854  6.7071152
#> 41  0.4 0.18941697  4.14297592  0.66606272  5.3705821
#> 51  0.5 0.12848853  2.59814424  1.86456234  4.6667348
#> 71  0.7 0.05733628 -0.15483242  1.23632359  3.6095247
#> 81  0.8 0.03799392  0.28706465 -0.80286063  3.0726292
#> 91  0.9 0.01809892 -0.93786254  0.07155125  1.6746750
#> 101 1.0 0.00000000 -0.05764603 -0.51362184 -0.1510998
#> 
#> Bayesian approximation
#> 
#>     FPR        FNR      T_p
#> 1   0.0 1.00000000 1.370305
#> 11  0.1 0.44639403 3.119537
#> 21  0.2 0.31749102 3.294461
#> 41  0.4 0.16869301 3.563093
#> 51  0.5 0.12047527 3.688038
#> 71  0.7 0.05692180 3.900445
#> 81  0.8 0.03481625 4.009772
#> 91  0.9 0.01782260 4.184695
#> 101 1.0 0.00000000 4.475193
#> 
#> FPR - False Positive Rate
#> FNR - False Negative Rate
#> 
#> n_p, m_p, r_p - Probabilistic thresholds for standard
#>                 progression criteria on the number recruited,
#>                 number of sites opened, and the recruitment rate
#>                 (participants per site per year) respectively
#> 
#> T_p - Bayesian decision rule threshold for the posterior predictive
#>       expected time until full recruitment
plot(design)
```

<img src="man/figures/README-unnamed-chunk-2-1.png" alt="" width="100%" />

Two types of decision rules are considered here. Firstly, we consider
rules which take the same form as the standard progression criteria
suggested by the NIHR. In the table output, `n_p` is a minimum number of
participants recruited, `m_p` is a minimum number of sites opened, and
`r_p` is a minimum rate of recruitment (participants per site-year), and
we progress to the main trial only if all of these thresholds are met.

The second type of decision rules is defined by `T_p`, the maximum
expected time until full recruitment conditional on the pilot data. We
progress to the main trial only if the actual posterior predictive
expectation is lower than this threshold.

Decision rules of both types are characterised by their false positive
(`FPR`) and false negative (`FNR`) rates. These are estimated via
simulation by comparing the decisions made with the underlying
feasibility, as determined by the threshold `rel_thr`. For example, we
can attain `FPR = 0.15` and `FNR = 0.34` if we proceed only if we
recruit at least $10.48$ participants from at least $1$ site, with an
overall rate of at least $6.57$ participants per site-year. We can get
slightly better operating characteristics if we use a Bayesian
progression rules instead. If we want to improve the pilot further we
can increase the design variable `t_int` so that the internal pilot will
have more data.
