test_that("expected recruitment time increases with N", {
  t1 <- fahb_problem(N = 100)$exp_T
  t2 <- fahb_problem(N = 200)$exp_T
  expect_gt(t2, t1)
})

test_that("fahb_problem returns a fahb_problem object", {
  prob <- fahb_problem()
  
  expect_s3_class(prob, "fahb_problem")
  expect_type(prob, "list")
})

test_that("fahb_problem contains required fields", {
  prob <- fahb_problem()
  
  expect_named(
    prob,
    c(
      "N", "m", "t", "n_ext", "m_ext", "internal", "rel_thr",
      "exp_T", "thr",
      "so_hp_a", "so_hp_b",
      "mean_rr_hp_a", "mean_rr_hp_b",
      "sd_rr_hp_a", "sd_rr_hp_b",
      "sims"
    )
  )
})

test_that("defaults are internally consistent", {
  prob <- fahb_problem()
  
  # Derived quantities
  expect_equal(prob$thr, prob$rel_thr * prob$exp_T)
  
  # Sims should be NULL on construction
  expect_null(prob$sims)
})

test_that("N and m must be >= 1", {
  expect_error(
    fahb_problem(N = 0),
    "N and m must be >= 1"
  )
  
  expect_error(
    fahb_problem(m = 0),
    "N and m must be >= 1"
  )
})

test_that("t must be > 0", {
  expect_error(
    fahb_problem(t = -0.1),
    "t must be > 0"
  )
})

test_that("hyperparameters must be positive", {
  expect_error(
    fahb_problem(so_hps = c(-1, 1)),
    "hyperparameters must be > 0"
  )
  
  expect_error(
    fahb_problem(mean_rr_hps = c(1, -0.1)),
    "hyperparameters must be > 0"
  )
  
  expect_error(
    fahb_problem(sd_rr_hps = c(0, 1)),
    "hyperparameters must be > 0"
  )
})

test_that("changing inputs propagates correctly into the object", {
  prob <- fahb_problem(
    N = 100,
    m = 10,
    t = 0.25,
    rel_thr = 1.5,
    so_hps = c(5, 2),
    mean_rr_hps = c(1, 0.5),
    sd_rr_hps = c(10, 20)
  )
  
  expect_equal(prob$N, 100)
  expect_equal(prob$m, 10)
  expect_equal(prob$t, 0.25)
  expect_equal(prob$rel_thr, 1.5)
  
  expect_equal(prob$so_hp_a, 5)
  expect_equal(prob$so_hp_b, 2)
  
  expect_equal(prob$mean_rr_hp_a, 1)
  expect_equal(prob$mean_rr_hp_b, 0.5)
  
  expect_equal(prob$sd_rr_hp_a, 10)
  expect_equal(prob$sd_rr_hp_b, 20)
})

test_that("expected recruitment time is positive and finite", {
  prob <- fahb_problem()
  
  expect_true(is.numeric(prob$exp_T))
  expect_true(is.finite(prob$exp_T))
  expect_gt(prob$exp_T, 0)
})
