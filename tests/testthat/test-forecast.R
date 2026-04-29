test_that("forecast returns a fahb_problem object", {
  problem <- fahb_problem()
  out <- forecast(problem, n_sims = 10)
  
  expect_s3_class(out, "fahb_problem")
})

test_that("forecast adds a sims data frame", {
  problem <- fahb_problem()
  out <- forecast(problem, n_sims = 10)
  
  expect_true(is.data.frame(out$sims))
})

test_that("forecast produces the correct number of simulations", {
  problem <- fahb_problem()
  n_sims <- 25
  out <- forecast(problem, n_sims = n_sims)
  
  expect_equal(nrow(out$sims), n_sims)
})

test_that("forecast simulation output has expected columns", {
  problem <- fahb_problem()
  out <- forecast(problem, n_sims = 5)
  
  expect_named(out$sims, c("rec_T", "n_p", "m_p", "r_p"))
})

test_that("forecast simulation columns are numeric", {
  problem <- fahb_problem()
  out <- forecast(problem, n_sims = 5)
  
  expect_true(all(vapply(out$sims, is.numeric, logical(1))))
})

test_that("forecast errors if simulations already exist and overwrite is FALSE", {
  problem <- fahb_problem()
  problem <- forecast(problem, n_sims = 5)
  
  expect_error(
    forecast(problem, n_sims = 5),
    "Forecasts have been simulated already"
  )
})

test_that("forecast overwrites existing simulations when overwrite = TRUE", {
  problem <- fahb_problem()
  problem <- forecast(problem, n_sims = 5)
  
  old_sims <- problem$sims
  
  problem <- forecast(problem, n_sims = 10, overwrite = TRUE)
  
  expect_equal(nrow(problem$sims), 10)
  expect_false(identical(problem$sims, old_sims))
})

test_that("forecast does not modify problem metadata", {
  problem <- fahb_problem()
  out <- forecast(problem, n_sims = 5)
  
  expect_equal(out$N, problem$N)
  expect_equal(out$m, problem$m)
  expect_equal(out$t, problem$t)
  expect_equal(out$exp_T, problem$exp_T)
})

