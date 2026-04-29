test_that("simulate_data returns a numeric vector of length 4", {
  set.seed(123)
  
  out <- simulate_data(
    beta_m = 2,
    beta_s = 0.3,
    v_sh = 30,
    v_r = 100,
    setup_r_a = 30,
    setup_r_b = 2.85,
    target_n = 50,
    m = 10,
    internal = TRUE,
    t = 1
  )
  
  expect_type(out, "double")
  expect_length(out, 4)
})

test_that("simulate_data returns finite, non-negative values", {
  set.seed(123)
  
  out <- simulate_data(
    beta_m = 2,
    beta_s = 0.3,
    v_sh = 30,
    v_r = 100,
    setup_r_a = 30,
    setup_r_b = 2.85,
    target_n = 50,
    m = 10,
    internal = TRUE,
    t = 1
  )
  
  expect_true(all(is.finite(out)))
  expect_true(all(out >= 0))
})

test_that("simulate_data recruitment time is positive", {
  set.seed(456)
  
  rec_time <- simulate_data(
    beta_m = 2,
    beta_s = 0.3,
    v_sh = 30,
    v_r = 100,
    setup_r_a = 30,
    setup_r_b = 2.85,
    target_n = 50,
    m = 10,
    internal = TRUE,
    t = 1
  )[1]
  
  expect_gt(rec_time, 0)
})

test_that("cond_sim returns a matrix with expected structure", {
  set.seed(123)
  
  lambdas <- rgamma(10, shape = 2, rate = 1)
  
  rec_rates <- cond_sim(
    m = 10,
    target_n = 50,
    m_p = 10,
    setup_r = 1,
    lambdas = lambdas
  )
  
  expect_true(is.matrix(rec_rates))
  expect_gte(ncol(rec_rates), 6)
  expect_gte(nrow(rec_rates), 2)
})

test_that("cond_sim reaches exactly the target sample size", {
  set.seed(456)
  
  lambdas <- rgamma(10, shape = 2, rate = 1)
  target_n <- 50
  
  rec_rates <- cond_sim(
    m = 10,
    target_n = target_n,
    m_p = 10,
    setup_r = 1,
    lambdas = lambdas
  )
  
  total_recruited <- sum(rec_rates[, 5])
  
  expect_equal(total_recruited, target_n)
})

test_that("cond_sim times are non-decreasing", {
  set.seed(789)
  
  lambdas <- rgamma(10, shape = 2, rate = 1)
  
  rec_rates <- cond_sim(
    m = 10,
    target_n = 50,
    m_p = 10,
    setup_r = 1,
    lambdas = lambdas
  )
  
  expect_true(all(diff(rec_rates[, 2]) >= 0))
  expect_true(all(diff(rec_rates[, 3]) >= 0))
})

test_that("site_dist handles zero sites open at interim", {
  rec_rates <- matrix(
    c(0, 1, 2, 1, 10, 0.5),
    ncol = 2
  )
  
  df <- site_dist(rec_rates, int_t = 0)
  
  expect_true(is.data.frame(df))
  expect_equal(nrow(df), 1)
  expect_equal(df$y[1], 0)
  expect_equal(df$t[1], 0)
})

test_that("site_dist returns sensible output when sites are open", {
  set.seed(123)
  
  lambdas <- rgamma(5, 2, 1)
  rec_rates <- cond_sim(
    m = 5,
    target_n = 20,
    m_p = 5,
    setup_r = 1,
    lambdas = lambdas
  )
  
  int_t <- rec_rates[nrow(rec_rates), 2] / 2
  df <- site_dist(rec_rates, int_t)
  
  expect_true(is.data.frame(df))
  expect_named(df, c("y", "c", "t"))
  
  expect_true(all(df$y >= 0))
  expect_true(all(df$t >= 0))
})
