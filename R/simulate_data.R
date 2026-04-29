simulate_data <- function(beta_m, beta_s,
                          v_sh, v_r,
                          setup_r_a, setup_r_b,
                          target_n, m, 
                          internal,
                          t = t,
                          n_ext = NULL, m_ext = NULL){

  
  int_t <- t
  # True per year recruitment rates for each site
  ## Sample beta_0 from prior
  beta_0 <- stats::rnorm(1, mean = beta_m, sd = beta_s)
  ## Sample var_l from prior
  #var_l <- abs(rlst(1, df = v_df, mu = 0, sigma = v_sc))^2
  sd_l <- stats::rgamma(1, shape = v_sh, rate = v_r)
  ## Sample the site rates from a log-normal 
  lambdas <- exp(stats::rnorm(m, beta_0, sd_l))
  
  # True setup rate, from the prior
  setup_r <- stats::rgamma(1, setup_r_a, setup_r_b)
  
  # Simulate the site openings and participant recruitment over time
  rec_rates <- cond_sim(m, target_n, m, setup_r, lambdas)
  
  rec_time <- rec_rates[nrow(rec_rates), 3]

  if(internal){
    df <- site_dist(rec_rates, int_t)
  } else {
    # If the pilot is external we generate a new set of data using the same 
    # parameters
    rec_rates_p <- cond_sim(m, n_ext, m_ext, setup_r, lambdas)
    int_t <- min(int_t, rec_rates_p[nrow(rec_rates_p), 3])
    #site_t <- min(int_t, rec_rates_p[nrow(rec_rates_p), 2])
    
    df <- site_dist(rec_rates_p, int_t)
  }
  
  n_p <- sum(df$y)
  m_p <- nrow(df)
  if(nrow(df) == 1 & df$y[1] == 0){ 
    n_p <- 0
    m_p <- 0
    r_p <- 0
  } else {
    n_p <- sum(df$y)
    m_p <- nrow(df)
    r_p <- n_p / sum(df$t)
  }
  
  # Output the interim data and the time to reach target n
  return(c(rec_time, n_p, m_p, r_p))
}

cond_sim <- function(m, target_n, m_p,
                     setup_r, lambdas){
  # Given the true parameter values, simulate recruitment of
  # target_n participants from m_p sites chosen from a set of
  # m sites
  
  # Simulate setup times
  setup_ts <- cumsum(stats::rexp(m_p, setup_r))
  end_rec <- setup_ts[m_p] + 20
  setup_order <- sample(1:m, m_p)
  
  # Get the different recruitment rates over time
  ## Each row is a recruitment period, changing when a site comes online
  ## Columns are start times, end times, and true overall recruitment rates
  rec_rates <- matrix(c(0, setup_order, 
                        0, setup_ts,
                        setup_ts, end_rec,
                        0, cumsum(lambdas[setup_order])), 
                      ncol = 4)
  
  # Simulate numbers recruited in each period and add these as a column
  ## First get the vector of expected numbers recruited in each period
  exp_rec <- (rec_rates[,4]*(rec_rates[,3] - rec_rates[,2]))[2:(m_p+1)]
  ## Now sample from a Poisson for each period
  rec_rates <- cbind(rec_rates, c(0, stats::rpois(m_p, exp_rec)))
  
  # Get time at which total target n is hit
  ## First get the period when it happens
  ## If it is not hit in the (arbitrary) 10 year period, add another period for 
  ## the remainder
  if(sum(rec_rates[,5]) < target_n){
    # Recruit to target in the final period
    rec_rates[nrow(rec_rates), 5] <- target_n - sum(rec_rates[1:m_p, 5])
  }
  
  ## Add the lambdas as a column
  rec_rates <- cbind(rec_rates, c(0, lambdas[setup_order]))
  
  fin_period <- which(cumsum(rec_rates[,5]) >= target_n)[1]
  ## Determine how many people need to arrive in that final period
  n_needed <- target_n - sum(rec_rates[1:(fin_period-1), 5])
  ## Simulate when the target is hit, which follows a gamma distribution
  rec_time <- rec_rates[fin_period, 2] + stats::rgamma(1, shape = n_needed, rate = rec_rates[fin_period, 4])
  ## Update the rec_rates summary
  rec_rates <- rec_rates[1:fin_period,]
  rec_rates[fin_period, c(3,5)] <- c(rec_time, n_needed)
  
  return(rec_rates)
}

site_dist <- function(rec_rates, int_t){
  # For a give recruitment process and interim timing, return a df listing the
  # sites, how long they were open for (up to interim), and how many were
  # recruited.
  
  ## Note how many sites are set up at interim
  m_p <- sum(rec_rates[2:nrow(rec_rates),2] <= int_t)
  if(m_p > 0){
    ## Get period (row in matrix) where interim occurs
    int_period <- utils::tail(which(rec_rates[,2] <= int_t), n=1)
    ## Start with the number recruited from all previous periods
    n_p <- sum(rec_rates[1:(int_period-1), 5])
    ## Simulate the extra number recruited in the final period, using the fact
    ## that arrivals will be uniformly distributed over the period
    n_p <- n_p +  sum(stats::runif(rec_rates[int_period, 5], rec_rates[int_period, 2], rec_rates[int_period, 3]) < int_t)
    ## Distribute these participants to sites in proportion to their expected
    ## numbers, given their true rates and times open
    n_ps <- stats::rmultinom(1, n_p, prob = (int_t- rec_rates[2:(m_p+1), 2])*
                        rec_rates[2:(m_p+1), 6])
    
    # Create a data frame storing the sites open at interim, the numbers 
    # they each recruited, and how long they were recruiting for
    df <- data.frame(y = n_ps[1:m_p],
                     c = rec_rates[2:(m_p+1), 1],
                     t = int_t - rec_rates[2:(m_p+1), 2])
  } else {
    # If no sites are recruited by interim, handle this manually
    df <- data.frame(y = 0, c = 0, t = 0)
  }
  
  return(df)
}
