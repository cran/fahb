test_that("new_fahb_analysis creates a fahb_analysis object", {
  out <- new_fahb_analysis(
    PC_stats = c(n_p = 10, m_p = 2, r_p = 1.5),
    Bayes_stats = c(exp_pp_T = 12.3),
    PP_rec_times = c(10, 11, 12),
    so_post_hps = c(35, 5),
    model_fit = "dummy_model"
  )
  
  expect_s3_class(out, "fahb_analysis")
  expect_type(out, "list")
})

test_that("fahb_analysis object has expected components", {
  out <- new_fahb_analysis(
    PC_stats = c(n_p = 10, m_p = 2, r_p = 1.5),
    Bayes_stats = c(exp_pp_T = 12.3),
    PP_rec_times = c(10, 11, 12),
    so_post_hps = c(35, 5),
    model_fit = "dummy_model"
  )
  
  expect_named(
    out,
    c("PC_stats",
      "Bayes_stats",
      "PP_rec_times",
      "so_post_hps",
      "model_fit")
  )
})

test_that("fahb_analysis errors when pilot inputs are inconsistent", {
  problem <- fahb_problem()
  
  expect_error(
    fahb_analysis(
      n_pilot = c(1, 2),
      t_pilot = c(1),   # length mismatch
      problem = problem
    )
  )
})

test_that("post_pred_rec_time returns a positive finite time", {
  set.seed(123)
  
  m <- 3
  target_n <- 20
  
  post_samples <- c(
    # recruitment rates
    1.2, 1.0, 0.8,
    # setup times
    0, 0.5, 1
  )
  
  t <- post_pred_rec_time(
    post_samples = post_samples,
    m = m,
    target_n = target_n
  )
  
  expect_type(t, "double")
  expect_true(is.finite(t))
  expect_gt(t, 0)
})

test_that("print.fahb_analysis produces output", {
  obj <- new_fahb_analysis(
    PC_stats = c(n_p = 10, m_p = 2, r_p = 1.5),
    Bayes_stats = c(exp_pp_T = 12.3),
    PP_rec_times = c(10, 11, 12),
    so_post_hps = c(35, 5),
    model_fit = "dummy_model"
  )
  
  expect_output(
    print(obj),
    "Standard progression criteria statistics"
  )
})



