## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(fahb)
# library(patchwork)

## -----------------------------------------------------------------------------
# problem <- fahb_problem(N = 320, m = 20, t = 0.5, rel_thr = 1.2,
#                         so_hps = c(30, 2.85),
#                         mean_rr_hps = c(2, 0.329),
#                         sd_rr_hps = c(30, 100))

## -----------------------------------------------------------------------------
# plots <- check_priors(problem)
# 
# (plots[[1]] + plots[[2]]) / (plots[[3]] + plots[[4]])

## -----------------------------------------------------------------------------
# set.seed(9278635)
# 
# # Run the simulations
# problem <- forecast(problem)
# 
# # Find some candidate decision rules are their OCs
# design <- fahb_design(problem)
# 
# plot(design)

## -----------------------------------------------------------------------------
# design

## -----------------------------------------------------------------------------
# # Standard progression criteria:
# design$Prog_Crit_OCs[design$Prog_Crit_OCs$FPR == 0.2,]
# 
# # Approximate Bayesian decision rule:
# design$Bayes_OCs[design$Bayes_OCs == 0.2,]

## -----------------------------------------------------------------------------
# problem <- fahb_problem(N = 320, m = 20 , t = 1, rel_thr = 1.2,
#                         so_hps = c(30, 2.85),
#                         mean_rr_hps = c(2, 0.329),
#                         sd_rr_hps = c(30, 100))
# 
# # Run the simulations
# problem <- forecast(problem)
# 
# # Find some candidate decision rules are their OCs
# design <- fahb_design(problem)
# 
# plot(design)
# design$Prog_Crit_OCs[design$Prog_Crit_OCs$FPR == 0.2,]

## -----------------------------------------------------------------------------
# n_pilot <- c(4, 8, 0, 2)
# t_pilot <- c(0.5, 0.4, 0.3, 0.2)
# 
# analysis <- fahb_analysis(n_pilot, t_pilot, problem)

## -----------------------------------------------------------------------------
# print(analysis)
# 
# plots <- plot(analysis)
# (plots[[1]] + plots[[2]]) / (plots[[3]] + plots[[4]])

## -----------------------------------------------------------------------------
# problem <- fahb_problem(n_ext = 80, m_ext = 6, t_int = 0.33)
# 
# problem <- forecast(problem)
# 
# design <- fahb_design(problem)
# 
# plot(design)
# design

## -----------------------------------------------------------------------------
# n_pilot <- c(4, 8, 0, 2)
# t_pilot <- c(0.5, 0.4, 0.3, 0.2)
# site_t <- 0.6
# 
# analysis <- fahb_analysis(n_pilot, t_pilot, problem, site_t)
# 
# print(analysis)
# 
# plots <- plot(analysis)
# (plots[[1]] + plots[[2]]) / (plots[[3]] + plots[[4]])

