test_that("fahb_design errors if simulations are missing", {
  problem <- fahb_problem()
  
  expect_error(
    fahb_design(problem),
    "does not contain trial simulations"
  )
})

test_that("fahb_design returns a fahb_design object with problem included", {
  set.seed(123)
  
  problem <- fahb_problem()
  problem <- forecast(problem, n_sims = 20)
  
  design <- fahb_design(problem)
  
  expect_s3_class(design, "fahb_design")
  expect_type(design, "list")
  
  expect_named(
    design,
    c("problem", "Prog_Crit_OCs", "Bayes_OCs")
  )
})

test_that("fahb_design stores the original problem object", {
  set.seed(123)
  
  problem <- fahb_problem()
  problem <- forecast(problem, n_sims = 20)
  
  design <- fahb_design(problem)
  
  expect_identical(design$problem, problem)
})

test_that("fahb_design components are data frames", {
  set.seed(123)
  
  problem <- fahb_problem()
  problem <- forecast(problem, n_sims = 20)
  
  design <- fahb_design(problem)
  
  expect_true(is.data.frame(design$Prog_Crit_OCs))
  expect_true(is.data.frame(design$Bayes_OCs))
})

test_that("print.fahb_design produces output without error", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 20)
  
  design <- fahb_design(problem)
  
  expect_output(
    print(design),
    "Standard progression criteria"
  )
})

test_that("plot.fahb_design returns a ggplot object", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 20)
  
  design <- fahb_design(problem)
  
  p <- plot(design)
  
  expect_s3_class(p, "ggplot")
})

test_that("plot.fahb_design includes PC and Bayesian methods", {
  set.seed(123)
  
  problem <- fahb_problem() |>
    forecast(n_sims = 20)
  
  design <- fahb_design(problem)
  
  p <- plot(design)
  plot_data <- p$data
  
  expect_true(all(c("PC", "Bayes") %in% plot_data$type))
})

