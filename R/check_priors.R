#' Plot prior distributions
#' 
#' Given the hyperparameters encoded in a `fahb_problem` object, return plots of
#' the three prior distributions and a plot of the prior predictive distribution
#' of the recruitment rate at a randomly selected site.
#'
#' @param problem an object of class `fahb_problem`.
#'
#' @returns a list of `ggplot2` plots.
#' @export
#'
#' @examples
#' problem <- fahb_problem()
#' check_priors(problem)
#' 
check_priors <- function(problem){
  # Plot prior densities for the three model parameters, and the prior 
  # predictive densities for the recruitment rate at a random site and
  # the time needed to fully recruit
  p_so <- plot_gamma_prior(problem$so_hp_a, problem$so_hp_b, "Site opening rate")
  p_mean_rr <- plot_normal_prior(problem$mean_rr_hp_a, problem$mean_rr_hp_b, 
                                  "Participant recruitment rate (LogNormal mean)")
  p_sd_rr <- plot_gamma_prior(problem$sd_rr_hp_a, problem$sd_rr_hp_b, 
                              "Participant recruitment rate (LogNormal SD)")
  p_pp_rr <- plot_rr_prior_predictive(problem)
  #p_pp_t <- plot_t_prior_predictive(problem)
  
  return(list(p_so,
              p_mean_rr,
              p_sd_rr,
              p_pp_rr))
}

plot_gamma_prior <- function(shape, rate, par_name, post = FALSE){
  
  lower <- max(0, shape/rate - 4*sqrt(shape/rate^2))
  upper <- shape/rate + 4*sqrt(shape/rate^2)
  
  x <- seq(lower, upper, length.out = 10^3)
  df <- data.frame(x = x,
                   pr = stats::dgamma(x, shape, rate=rate))
  
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$pr)) + ggplot2::geom_line() +
    ggplot2::xlab(par_name) +
    ggplot2::theme_minimal()
  if(post){ 
    p <- p + ggplot2::ylab("Posterior prob.")
  } else {
    p <- p + ggplot2::ylab("Prior prob.")
  }
    
  return(p)
}

plot_normal_prior <- function(mean, sd, par_name){
  
  lower <- mean - 4*sd
  upper <- mean + 4*sd
  
  x <- seq(lower, upper, length.out = 10^3)
  df <- data.frame(x = x,
                   pr = stats::dnorm(x, mean, sd))
  
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$pr)) + ggplot2::geom_line() +
    ggplot2::xlab(par_name) + ggplot2::ylab("Prior prob.") +
    ggplot2::theme_minimal()
  
  return(p)
}

plot_rr_prior_predictive <- function(problem){
  df <- data.frame(beta = stats::rnorm(10^5, problem$mean_rr_hp_a, problem$mean_rr_hp_b),
                   sig = stats::rgamma(10^5, problem$sd_rr_hp_a, rate = problem$sd_rr_hp_b))
  df$gamma <- exp(stats::rnorm(10^5, df$beta, df$sig))
  
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$gamma)) + 
    ggplot2::stat_density(alpha = 0, colour = "black") +
    ggplot2::xlab("Participant recruitment rate at random site") +
    ggplot2::ylab("Prior pred. prob.") +
    ggplot2::xlim(as.numeric(stats::quantile(df$gamma, c(0.001, 0.999)))) +
    ggplot2::theme_minimal()
  
  return(p)
}
  
  
