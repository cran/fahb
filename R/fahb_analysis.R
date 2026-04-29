new_fahb_analysis <- function(PC_stats, Bayes_stats,
                              PP_rec_times, so_post_hps,
                              model_fit){
  structure(list(PC_stats = PC_stats, Bayes_stats = Bayes_stats,
                 PP_rec_times = PP_rec_times, so_post_hps = so_post_hps,
                 model_fit = model_fit),
            class = "fahb_analysis")
}

#' Build a `fahb` analysis object
#' 
#' Given a `fahb_problem` object calculate summary statistics which can inform
#' progression decisions. These include both standard progression criteria 
#' statistics, and the expectation of the posterior predictive distribution of 
#' the time until the trial recruits.
#'
#' @param n_pilot integer vector of numbers recruited at each open site.
#' @param t_pilot numeric vector of time (in years) each site has been open.
#' @param problem object of class `fahb_problem`.
#' @param site_t In the case of an external pilot, the time taken for all 
#' pilot sites to open.
#' @param bayes_model optional object of class `brmsfit` which will be used in
#' the Bayesian analysis via `brms::update()` to avoid compiling a new model.
#'
#' @returns An object of class `fahb_analysis`.
#' @export
#'
#' @examples
#' ## Example illustrating a full analysis workflow
#' ## (Not run on CRAN due to Bayesian model fitting)
#'
#' \donttest{
#' problem <- fahb_problem()
#' problem <- forecast(problem)
#'
#' ## Pilot trial data
#' n_pilot <- c(3, 5, 2)
#' t_pilot <- c(0.5, 0.6, 0.4)
#'
#' analysis <- fahb_analysis(
#'   n_pilot = n_pilot,
#'   t_pilot = t_pilot,
#'   problem = problem
#' )
#'
#' print(analysis)
#' plot(analysis)
#' }
fahb_analysis <- function(n_pilot, t_pilot, 
                          problem, 
                          site_t = NULL,
                          bayes_model = NULL){
  
  if(is.null(site_t)){
    site_t <- problem$t
    if(!problem$internal){
      stop("External pilots require site_t to be specified")
    }
  }
  
  if(length(n_pilot) != length(t_pilot)){
    stop("Lengths of n_pilot and t_pilot must match")
  }
  
  m <- problem$m
  
  # Get standard PC summaries
  n_p <- sum(n_pilot)
  m_p <- length(n_pilot)
  r_p <- n_p/sum(t_pilot)
  
  # Fit a Bayesian model
  if(is.null(bayes_model)){
    message("Compiling the model...")
    bayes_model <- compile_bayes_model(n_pilot, t_pilot, problem)
  }
  
  int_data <- data.frame(y = n_pilot,
                         t = t_pilot,
                         c = 1:length(n_pilot))
  
  # Generate posterior samples
  output <- utils::capture.output(fit <- stats::update(bayes_model, 
                                                          backend = "cmdstanr",
                                                          recompile = FALSE, 
                                                          newdata = int_data, 
                                                          iter = 3000, 
                                                          warmup = 500,
                                                          control = list(adapt_delta = 0.95)))
  
  # Get vectors of posterior samples for the mean and SD parameters of the 
  # log-normal model for site recruitment rates
  s <- brms::as_draws(fit)
  beta_0 <- posterior::extract_variable(s, "b_Intercept")
  sd_r <- posterior::extract_variable(s, "sd_c__Intercept")
  
  # First deal with cases where not all sites have yet opened
  if(m - m_p > 0){
    
    # Generate posterior samples of recruitment rates at all future sites,
    # Using the posterior samples of the log-normal recruitment rate model.
    # Each column of u is a yearly rate at that site, each row a sample from the 
    # posterior.
    us <- sapply(1:(m-m_p), function(x) exp(stats::rnorm(length(beta_0), beta_0, sd_r)))
    
    # Add to that matrix the posterior samples for the sites which have already
    # opened
    r <- brms::ranef(fit, summary = F)
    us <- cbind(us, exp(r$c[,1:m_p,1] + beta_0))
    
    # For site setup rates we have a simple conjugate analysis
    setup_r_a1 <- problem$so_hp_a + m_p
    setup_r_b1 <- problem$so_hp_b + site_t
    
    # We can then generate samples from the posterior of setup rate
    setup_rates <- stats::rgamma(nrow(us), setup_r_a1, setup_r_b1)
    
    if(problem$internal){
      # Now sample actual site setup times from the posterior predictive
      setup_times <- t(sapply(setup_rates, function(x) cumsum(stats::rexp(m-m_p, x))))
      if(m-m_p == 1) setup_times <- t(setup_times)
      
      # Add pilot sites using a setup time of 0
      setup_times <- cbind(setup_times, matrix(rep(0, m_p*nrow(us)), ncol = m_p))
      
      site_matrix <- cbind(us, setup_times)
      
      rec_times <- apply(site_matrix, 1, post_pred_rec_time, 
                         m=m, target_n=(problem$N - n_p)) + problem$t
    } else {
      # For external, we want setup times for all m sites
      setup_times <- t(sapply(setup_rates, function(x) cumsum(stats::rexp(m, x))))
      
      site_matrix <- cbind(us, setup_times)
      
      rec_times <- apply(site_matrix, 1, post_pred_rec_time, 
                         m=m, target_n=problem$N)
    }
    
  } else {
    # Case where all sites in the main have also opened in the pilot
    # Get the posterior samples for the sites which have already
    # opened (i.e. all sites)
    r <- brms::ranef(fit, summary = F)
    us <- exp(r$c[,1:m_p,1] + beta_0)
    
    if(problem$internal){
      # Add pilot sites using a setup time of 0
      setup_times <- matrix(rep(0, m_p*nrow(us)), ncol = m_p)
      
      site_matrix <- cbind(us, setup_times)
      
      rec_times <- apply(site_matrix, 1, post_pred_rec_time, 
                         m=m, target_n=(problem$N - n_p)) + problem$t
    } else {
      # For external, we want setup times for all m sites
      setup_times <- t(sapply(setup_rates, function(x) cumsum(stats::rexp(m, x))))
      
      site_matrix <- cbind(us, setup_times)
      
      rec_times <- apply(site_matrix, 1, post_pred_rec_time, 
                         m=m, target_n=problem$N)
    }
  }
  
  new_fahb_analysis(c(n_p=n_p, m_p=m_p, r_p=r_p), c(exp_pp_T=mean(rec_times)),
                    rec_times, so_post_hps = c(setup_r_a1, setup_r_b1),
                    fit)
}

post_pred_rec_time <- function(post_samples, m, target_n){
  # post_samples is a vector of one draw from the posterior distribution.
  # The first m elements are recruitment rates for the m sites; the next m 
  # elements are the corresponding opening times, relative to the interim 
  # analysis point.
  # Returns a sample time to hit recruitment target from the posterior
  # predictive distribution.
  # Note- target_n is number needed to recruit in addiiton to those
  # recruited by interim
  
  end_rec <- 1000
  
  # Split up into the site rates and site setup times
  us <- post_samples[1:m]; setup_ts <- post_samples[(m+1):(2*m)]
  # Re-order each vector in order of site setup times
  us <- us[order(setup_ts)]; setup_ts <- setup_ts[order(setup_ts)]
  
  #################
  # Note - duplicating elements from the DGM function, need to tidy
  #################
  
  # Build a matrix of the recruitment periods with their start times, end
  # times, and overall recruitment rates
  rec_rates <- matrix(c(0, setup_ts,
                        setup_ts, end_rec,
                        0, cumsum(us)), ncol = 3)
  
  # Simulate numbers recruited in each period and add these as a column
  ## First get the vector of expected numbers recruited in each period
  exp_rec <- (rec_rates[,3]*(rec_rates[,2] - rec_rates[,1]))[2:(m+1)]
  ## Now sample from a Poisson for each period
  rec_rates <- cbind(rec_rates, c(0, stats::rpois(m, exp_rec)))
  
  # Get time at which total target n is hit
  ## First get the period when it happens
  fin_period <- which(cumsum(rec_rates[,4]) > target_n)[1]
  ## Determine how many people need to arrive in that final period
  n_needed <- target_n  -  sum(rec_rates[1:(fin_period-1), 4])
  ## Simulate when the target is hit, which follows a gamma distribution
  rec_time <- rec_rates[fin_period, 1] + stats::rgamma(1, shape = n_needed, rate = rec_rates[fin_period, 3])
  
  return(rec_time)
}

compile_bayes_model <- function(n_pilot, t_pilot,
                                problem){
  
  beta_m <- problem$mean_rr_hp_a; beta_s <- problem$mean_rr_hp_b
  v_sh <- problem$sd_rr_hp_a; v_r <- problem$sd_rr_hp_b
  setup_r_a <- problem$so_hp_a; setup_r_b <- problem$so_hp_b
  target_n <- problem$N; m <- problem$m; int_t <- problem$t
  
  stanvars <- brms::stanvar(beta_m, name='beta_m') + 
    brms::stanvar(beta_s, name='beta_s') + 
    brms::stanvar(v_sh, name='v_sh') + brms::stanvar(v_r, name='v_r')
  
  bprior <- c(
    brms::set_prior(
      paste0("normal(", beta_m, ", ", beta_s, ")"), 
      class = "Intercept"),
    brms::set_prior(
      paste0("gamma(", v_sh, ", ", v_r, ")"),
      class = "sd"))
    
  int_data <- data.frame(y = n_pilot,
                     t = t_pilot,
                     c = 1:length(n_pilot))
  
  bayes_model <- brms::brm(y | rate(t) ~ 1 + (1 | c), data = int_data, family = stats::poisson(),
                     prior = bprior, 
                     stanvars = stanvars,
                     chains = 0, silent = 2)
  
  return(bayes_model)
}

#' Print a `fahb` analysis object
#' 
#' The default print method for a `fahb_analysis` object.
#' 
#' @param x object of class `fahb_analysis` as produced by `fahb_analysis()`.
#' @param ... further arguments passed to or from other methods.
#' 
#' @return no return value, called for side effects.
#' 
#' @export
print.fahb_analysis <- function(x, ...){
  cat("Standard progression criteria statistics:\n")
  print(x$PC_stats)
  cat("\n")
  cat("Expected posterior predictive time to recruit:\n")
  print(x$Bayes_stats)
  cat("\n")
  cat("Posterior predictive distribution quantiles:\n")
  print(stats::quantile(x$PP_rec_times, c(0.005, 0.025, 0.2, 0.5, 0.8, 0.975, 0.995)))
  cat("\n")
  cat("Posterior site opening rate hyperparamaters (Gamma):\n")
  print(c(shape = x$so_post_hps[1], rate = x$so_post_hps[2]))
  cat("\n")
}


#' Plot posterior distributions from a `fahb` analysis
#' 
#' Takes an object of class `fahb_analysis` and plots the posterior 
#' distributions of the predicted time for the trial to recruit and of the three
#' model parameters.
#' 
#' @param x object of class `fahb_analysis` as produced by `fahb_analysis().`
#' @param ... further arguments passed to or from other methods.
#' 
#' @return no return value, called for side effects.
#' 
#' @export
plot.fahb_analysis <- function(x, ...){
  
  p1 <- plot_post_samples(x$PP_rec_times, "Predicted time to recruit")
  p2 <- plot_gamma_prior(shape = x$so_post_hps[1], rate = x$so_post_hps[2], 
                         par_name = "Site opening rate", post = TRUE)
  
  s <- brms::as_draws(x$model_fit)
  beta_0 <- posterior::extract_variable(s, "b_Intercept")
  sd_r <- posterior::extract_variable(s, "sd_c__Intercept")
  
  p3 <- plot_post_samples(beta_0, "Mean of log(recruitment rate)")
  p4 <- plot_post_samples(sd_r, "S.D. of log(recruitment rate)")
  
  return(c(p1, p2, p3, p4))
}

plot_post_samples <- function(samples, par_name){
  df <- data.frame(x = samples)
  ggplot2::ggplot(df, ggplot2::aes(x=.data$x)) +
  ggplot2::geom_density() +
    ggplot2::xlab(par_name) +
    ggplot2::ylab("Posterior prob.") +
    ggplot2::xlim(as.numeric(stats::quantile(df$gamma, c(0.0001, 0.9999)))) +
    ggplot2::theme_minimal()
}
