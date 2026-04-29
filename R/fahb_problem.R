new_fahb_problem <- function(N, m, t, n_ext, m_ext,
                             internal,
                             rel_thr,
                             exp_T, thr,
                             so_hp_a, so_hp_b,
                             mean_rr_hp_a, mean_rr_hp_b,
                             sd_rr_hp_a, sd_rr_hp_b,
                             sims){
  
  structure(list(N=N, m=m, t=t, n_ext=n_ext, m_ext=m_ext,
                 internal=internal,
                 rel_thr=rel_thr,
                 exp_T=exp_T, thr=thr,
                 so_hp_a=so_hp_a, so_hp_b=so_hp_b,
                 mean_rr_hp_a=mean_rr_hp_a, mean_rr_hp_b = mean_rr_hp_b,
                 sd_rr_hp_a=sd_rr_hp_a, sd_rr_hp_b=sd_rr_hp_b,
                 sims=sims),
            class = "fahb_problem")
}

validate_fahb_problem <- function(y){

  return(TRUE)  
}

#' Build a `fahb_problem` object
#' 
#' Given a trial design and a set of model hyperparameters, build an object
#' of class `fahb_problem`.
#'
#' @param N target sample size.
#' @param m number of recruiting sites.
#' @param t timing of the pilot analysis in years.
#' @param n_ext number of participants to recruit to an external pilot.
#' @param m_ext number of sites to open in an external pilot.
#' @param rel_thr threshold which discriminates feasible and infeasible trials,
#'  as a multiple of the expected time to recruit.
#' @param so_hps site opening rate hyperparameters (shape and rate for a Gamma prior).
#' @param mean_rr_hps mean site recruitment rate hyperparameters (mean and sd 
#' for a lognormal prior).
#' @param sd_rr_hps variance in site recruitment rates hyperparameters (shape 
#' and rate for a Gamma prior).
#'
#' @returns an object of class `fahb_problem`
#' @export
#'
#' @examples 
#' fahb_problem()
#' 
fahb_problem <- function(N = 320, m = 20 , t = 0.5, 
                         n_ext = NULL, m_ext = NULL,
                         rel_thr = 1.2,
                         so_hps = c(30, 2.85), 
                         mean_rr_hps = c(2, 0.329), 
                         sd_rr_hps = c(30, 100)){
  # Defaults from our GUSTO example
  
  if(!is.null(n_ext)){
    if(!is.null(m_ext)){
      internal <- FALSE
      if(n_ext < 1 | m_ext < 1){
        stop("n_ext and m_ext must be >= 1")
      }
    } else {
      stop("Both n_ext and m_ext must be supplied for the external pilot case")
    }
  } else {
    internal <- TRUE
    if(!is.null(m_ext)){
      stop("Both n_ext and m_ext must be supplied for the external pilot case")
    }
  }
  
  if(t < 0){
    stop("t must be > 0")
  }
  
  # Check inputs make sense
  if(N < 1 | m < 1){
    stop("N and m must be >= 1")
  }

  if(any(c(so_hps, mean_rr_hps, sd_rr_hps) <= 0)){
    stop("All hyperparameters must be > 0")
  }
  
  # Calculate exp_T - the expected time for trial to recruit
  exp_T <- exp_rec_time(m, N, so_hps, mean_rr_hps)
  
  # Get the threshold of rec time which denotes feasibility
  thr <- rel_thr*exp_T
  
  new_fahb_problem(N, m, t, 
                   n_ext, m_ext, internal,
                   rel_thr,
                   exp_T, thr,
                   so_hp_a = so_hps[1], so_hp_b = so_hps[2],
                   mean_rr_hp_a = mean_rr_hps[1], mean_rr_hp_b = mean_rr_hps[2],
                   sd_rr_hp_a = sd_rr_hps[1], sd_rr_hp_b = sd_rr_hps[2],
                   sims = NULL)
  
  }
  
exp_rec_time <- function(m, N, so_hps, mean_rr_hps){
  
  lambda_a <- so_hps[1]; lambda_b <- so_hps[2]
  beta_m <- mean_rr_hps[1]; beta_s <- mean_rr_hps[2]
  
  # Expected rate of recruitment after all sites open
  final_rate <- exp(beta_m + beta_s^2/2)*m
  # Expected time until all sites open
  all_open <- m/(lambda_a/lambda_b)
  # Expected number recruited when all sites open
  n_0 <- final_rate*all_open/2
  if(n_0 >= N){
    exp_time <- sqrt(2*N*all_open/final_rate)
  } else {
    exp_time <- (N - (n_0 - final_rate*all_open))/final_rate
  }
  return(exp_time)
}