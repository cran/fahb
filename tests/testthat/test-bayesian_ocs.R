test_that("bayesian_ocs errors if simulations are missing", {
  problem <- fahb_problem()
  
  expect_error(
    bayesian_ocs(problem),
    "Simulations"
  )
})

test_that("bayesian_ocs returns a data frame with expected columns", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 50)
  
  ocs <- bayesian_ocs(problem)
  
  expect_true(is.data.frame(ocs))
  expect_named(ocs, c("FPR", "FNR", "T_p"))
})

test_that("bayesian_ocs returns sensible operating characteristics", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 50)
  
  ocs <- bayesian_ocs(problem)
  
  expect_true(all(is.finite(ocs$FPR)))
  expect_true(all(is.finite(ocs$FNR)))
  expect_true(all(is.finite(ocs$T_p)))
  
  expect_true(all(ocs$FPR >= 0 & ocs$FPR <= 1))
  expect_true(all(ocs$FNR >= 0 & ocs$FNR <= 1))
})

test_that("bayesian_ocs nominal FPR grid is increasing", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 50)
  
  ocs <- bayesian_ocs(problem)
  
  expect_true(all(diff(ocs$FPR) >= 0))
})


test_that("Bayes_OCs returns FPR and FNR", {
  df <- data.frame(
    rec_T  = c(1, 2, 3, 4),
    pred_T = c(1.5, 2.5, 0.5, 1.0)
  )
  
  thr <- 2
  rule <- 1.5
  
  out <- Bayes_OCs(rule, thr, df)
  
  expect_type(out, "double")
  expect_length(out, 2)
})

test_that("Bayes_OCs returns values in [0,1]", {
  df <- data.frame(
    rec_T  = c(1, 2, 3, 4),
    pred_T = c(1.5, 2.5, 0.5, 1.0)
  )
  
  thr <- 2
  rule <- 1.5
  
  out <- Bayes_OCs(rule, thr, df)
  
  expect_true(all(out >= 0 & out <= 1))
})

test_that("Bayes_opt_fnr returns best FNR under nominal FPR", {
  opt_vals <- matrix(
    c(
      0.10, 0.40, 1.0,
      0.20, 0.30, 1.5,
      0.30, 0.20, 2.0
    ),
    ncol = 3,
    byrow = TRUE
  )
  
  res <- Bayes_opt_fnr(0.2, opt_vals)
  
  expect_equal(res[1], 0.10)
  expect_equal(res[2], 0.40)
})

test_that("Bayes_opt_fnr respects FPR constraint", {
  opt_vals <- matrix(
    c(
      0.05, 0.50, 1.0,
      0.10, 0.30, 1.5,
      0.20, 0.10, 2.0
    ),
    ncol = 3,
    byrow = TRUE
  )
  
  res <- Bayes_opt_fnr(0.1, opt_vals)
  
  expect_lte(res[1], 0.1)
})