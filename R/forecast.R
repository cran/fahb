#' Generate probabilistic forecasts of trial recruitment
#'
#' @param problem an object of class `fahb_problem`.
#' @param n_sims number of replicates to use in the simulation.
#' @param overwrite boolean indicating if we want to overwrite any simulation data
#' currently held (defaults to FALSE).
#'
#' @returns an object of class `fahb_problem`.
#' @export
#'
#' @examples
#' problem <- fahb_problem()
#' problem <- forecast(problem, n_sims = 10^3)
#' 
forecast <- function(problem, n_sims = 10^4, overwrite = FALSE){
  
  if(!is.null(problem$sims) & !overwrite){
    stop("Forecasts have been simulated already - to discard, use rewrite = TRUE")
  }
  
  r <- t(replicate(n_sims, 
                    simulate_data(beta_m=problem$mean_rr_hp_a, beta_s=problem$mean_rr_hp_b,
                                  v_sh=problem$sd_rr_hp_a, v_r=problem$sd_rr_hp_b,
                                  setup_r_a=problem$so_hp_a, setup_r_b=problem$so_hp_b,
                                  target_n=problem$N, m=problem$m, 
                                  internal=problem$internal, t=problem$t,
                                  n_ext=problem$n_ext, m_ext=problem$m_ext)))
  r <- as.data.frame(r)
  names(r) <- c("rec_T", "n_p", "m_p", "r_p")
   
  problem$sims <- r
  return(problem)
}
