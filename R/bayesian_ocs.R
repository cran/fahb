bayesian_ocs <- function(problem){
  if(is.null(problem$sims)){
    stop("Simulations are missing - run forecast()")
  }
  
  df <- problem$sims
  unique_m_ps <- length(unique(df$m_p))
  if(unique_m_ps >= 5){
    fit <- mgcv::gam(rec_T ~ ti(n_p) + ti(m_p) + ti(r_p) + ti(m_p, n_p), data = df)
  } else {
    fit <- mgcv::gam(rec_T ~ ti(n_p) + ti(r_p), data = df)
  }
  df$pred_T <- mgcv::predict.gam(fit)
  
  rules <- seq(min(df$pred_T), max(df$pred_T), length.out = 1000)
  vals <- t(sapply(rules, Bayes_OCs, thr = problem$thr, df = df))
  opt_vals <- cbind(vals, rules)
  
  ## Reduce down to a summary
  opt_vals <- opt_vals[order(-opt_vals[,1]),]
  
  nom_fprs <- seq(0, 1, 0.01)
  opt_vals <- t(sapply(nom_fprs, Bayes_opt_fnr, opt_vals = opt_vals))
  opt_vals[,1] <- nom_fprs
  
  opt_vals <- as.data.frame(opt_vals)
  names(opt_vals) <- c("FPR", "FNR", "T_p")
  
  return(opt_vals)
}

Bayes_OCs <- function(rule, thr, df){
  # Calculate FPR and FNR for a given Bayes rule
  
  feas <- df$rec_T < thr
  go <- !((df$pred_T >= rule) | (df$pred_T < 0))
  
  fpr <- sum(go[!feas])/(sum(!feas))
  fnr <- sum(!go[feas])/(sum(feas))
  
  return(c(fpr, fnr))
}

Bayes_opt_fnr <- function(nom_fpr, opt_vals){
  # Find the best FNR for a nominal FPR
  return(opt_vals[opt_vals[,1] <= nom_fpr, ,drop = FALSE][1,])
}
