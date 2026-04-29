
prog_crit_ocs <- function(problem){
  
  if(is.null(problem$sims)){
    stop("Simulations are missing - run forecast()")
  }
  
  df <- problem$sims
  df <- cbind(df, matrix(stats::runif(2*nrow(df)), ncol=2))
  
  max_m_p <- max(df$m_p)
  max_n_p <- max(df$n_p)
  max_r_p <- max(df$r_p)
  
  opt <- mco::nsga2(PC_OCs, 3, 2,
                    lower.bounds = rep(-1, 3),
                    upper.bounds = c(max_n_p, max_m_p, max_r_p),
                    popsize = 100, generations = 100,
                    thr = problem$thr, df = df)
  
  # Summarise rules by finding the optimal FNR for a series of nominal FPRs
  opt_vals <- cbind(opt$value, opt$par)
  
  ## Reduce down to a summary
  opt_vals <- opt_vals[order(-opt_vals[,1]),]
  
  nom_fprs <- seq(0, 1, 0.01)
  opt_vals <- t(sapply(nom_fprs, PC_opt_fnr, opt_vals = opt_vals))
  opt_vals[,1] <- nom_fprs
  
  opt_vals <- as.data.frame(opt_vals)
  names(opt_vals) <- c("FPR", "FNR", "n_p", "m_p", "r_p")
  
  return(opt_vals)
}

PC_OCs <- function(rule, thr, df){
  # Calculate FPR and FNR for a given rule
  
  feas <- df$rec_T < thr
  #go <- df$n_p >= rule[1] & df$m_p >= rule[2] & df$r_p >= rule[3]
  go <- (df[,5] > (rule[1] - df$n_p)) &
    (df[,6] > (rule[2] - df$m_p)) &
    df$r_p > rule[3]
  
  fpr <- sum(go[!feas])/sum(!feas)
  fnr <- sum(!go[feas])/sum(feas)
  
  return(c(fpr, fnr))
}

PC_opt_fnr <- function(nom_fpr, opt_vals){
  # Find the best FNR for a nominal FPR
  return(opt_vals[opt_vals[,1] <= nom_fpr, ,drop = FALSE][1,])
}
