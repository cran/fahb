test_that("prog_crit_ocs errors if simulations are missing", {
  problem <- fahb_problem()
  
  expect_error(
    prog_crit_ocs(problem),
    "Simulations"
  )
})

test_that("prog_crit_ocs returns a data frame with expected columns", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 50)
  
  ocs <- prog_crit_ocs(problem)
  
  expect_true(is.data.frame(ocs))
  expect_named(
    ocs,
    c("FPR", "FNR", "n_p", "m_p", "r_p")
  )
})

test_that("prog_crit_ocs returns sensible operating characteristics", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 50)
  
  ocs <- prog_crit_ocs(problem)
  
  expect_true(all(is.finite(ocs$FPR)))
  expect_true(all(is.finite(ocs$FNR)))
  
  expect_true(all(ocs$FPR >= 0 & ocs$FPR <= 1))
  expect_true(all(ocs$FNR >= 0 & ocs$FNR <= 1))
})

test_that("prog_crit_ocs FPR grid is increasing", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 50)
  
  ocs <- prog_crit_ocs(problem)
  
  expect_true(all(diff(ocs$FPR) >= 0))
})

test_that("PC_OCs returns FPR and FNR", {
  df <- data.frame(
    rec_T = c(1, 2, 3, 4),
    n_p   = c(5, 5, 1, 1),
    m_p   = c(2, 2, 1, 1),
    r_p   = c(1, 1, 0.2, 0.2),
    j1    = runif(4),
    j2    = runif(4)
  )
  
  rule <- c(2, 1, 0.5)
  thr <- 2.5
  
  out <- PC_OCs(rule, thr, df)
  
  expect_type(out, "double")
  expect_length(out, 2)
})

test_that("PC_OCs returns values in [0,1]", {
  df <- data.frame(
    rec_T = c(1, 2, 3, 4),
    n_p   = c(5, 5, 1, 1),
    m_p   = c(2, 2, 1, 1),
    r_p   = c(1, 1, 0.2, 0.2),
    j1    = runif(4),
    j2    = runif(4)
  )
  
  rule <- c(2, 1, 0.5)
  thr <- 2.5
  
  out <- PC_OCs(rule, thr, df)
  
  expect_true(all(out >= 0 & out <= 1))
})


test_that("PC_opt_fnr returns best FNR under nominal FPR", {
  opt_vals <- matrix(
    c(
      0.10, 0.40, 1, 1, 1,
      0.20, 0.30, 2, 2, 2,
      0.30, 0.20, 3, 3, 3
    ),
    ncol = 5,
    byrow = TRUE
  )
  
  res <- PC_opt_fnr(0.2, opt_vals)
  
  expect_equal(res[1], 0.10)
  expect_equal(res[2], 0.40)
})

test_that("PC_opt_fnr respects FPR constraint", {
  opt_vals <- matrix(
    c(
      0.05, 0.50, 1, 1, 1,
      0.10, 0.30, 2, 2, 2,
      0.20, 0.10, 3, 3, 3
    ),
    ncol = 5,
    byrow = TRUE
  )
  
  res <- PC_opt_fnr(0.1, opt_vals)
  
  expect_lte(res[1], 0.1)
})
