new_fahb_design <- function(problem,
                            PC_OCs, Bayes_OCs){
  structure(list(problem = problem,
                 Prog_Crit_OCs = PC_OCs,
                 Bayes_OCs = Bayes_OCs),
            class = "fahb_design")
}

#' Build a `fahb` design object
#' 
#' Given a `fahb_problem` object, find efficient progression decision rules. 
#' These can include rules of the standard "progression criteria form", or rules
#' based on a Bayesian analysis of the pilot trial data, or both. 
#'
#' @param problem an object of class `fahb_problem`.
#' @param quietly if this argument is set to FASLE then information about which
#' steps have been completed will be printed to the console. Defaults to TRUE.
#'
#' @returns an object of class `fahb_design`.
#' @export
#'
#' @examples
#' problem <- forecast(fahb_problem(), n_sims = 500)
#' fahb_design(problem)
#' 
fahb_design <- function(problem, quietly = TRUE){
  if(is.null(problem$sims)){
    stop("Problem does not contain trial simulations - see fahb::forecast()")
  }
  
  if(!quietly){
    message("Searching for efficient progression criteria...\n")
  }
  PC_OCs <- prog_crit_ocs(problem)

  if(!quietly){
    message("Approximating Bayesian operating characteristics...\n")
  }
  Bayes_OCs <- bayesian_ocs(problem)

  new_fahb_design(problem,
                  PC_OCs, Bayes_OCs)
}


#' Print a fahb design object
#' 
#' The default print method for a `fahb_design` object.
#' 
#' @param x object of class `fahb_design` as produced by `fahb_design()`.
#' @param coarse binary indicator that only a coarse subset of all decision 
#' rules should be printed. Defaults to TRUE.
#' @param ... further arguments passed to or from other methods.
#' 
#' @return no return value, called for side effects.
#' 
#' @export
print.fahb_design <- function(x, coarse = TRUE, ...){
  cat("Standard progression criteria\n")
  cat("\n")
  if(coarse){
    print(x$Prog_Crit_OCs[x$Prog_Crit_OCs$FPR %in% seq(0,1,0.1),])
  } else {
    print(x$Prog_Crit_OCs)
  }
  cat("\n")
  
  cat("Bayesian approximation\n")
  cat("\n")
  if(coarse){
    print(x$Bayes_OCs[x$Bayes_OCs$FPR %in% seq(0,1,0.1),])
  } else {
    print(x$Bayes_OCs)
  }
  cat("\n")
  cat("FPR - False Positive Rate\n")
  cat("FNR - False Negative Rate\n\n")
  cat("n_p, m_p, r_p - Probabilistic thresholds for standard\n")
  cat("                progression criteria on the number recruited,\n")
  cat("                number of sites opened, and the recruitment rate\n")
  cat("                (participants per site per year) respectively\n\n")
  cat("T_p - Bayesian decision rule threshold for the posterior predictive\n")
  cat("      expected time until full recruitment\n")
}


#' Plot operating characteristics of fahb designs
#' 
#' Takes an object of class `fahb_design` and plots the estimated operating 
#' characteristics of decision rules - based on standard progression criteria,
#' an approximate Bayesian analysis, or both.
#' 
#' @param x object of class `fahb_design` as produced by `fahb_design().`
#' @param ... further arguments passed to or from other methods.
#' 
#' @return no return value, called for side effects.
#' 
#' @export
plot.fahb_design <- function(x, ...){
  PC_OCs <- x$Prog_Crit_OCs[,1:2]
  PC_OCs$type <- "PC"
  Bayes_OCs <- x$Bayes_OCs[,1:2]
  Bayes_OCs$type <- "Bayes"
  
  all_OCs <- rbind(PC_OCs, Bayes_OCs)
  
  p <- ggplot2::ggplot(all_OCs, ggplot2::aes(.data$FPR, .data$FNR, colour = .data$type)) + ggplot2::geom_step() +
    ggplot2::scale_color_discrete(name = "Method") +
    ggplot2::xlab("False Positive Rate") +
    ggplot2::ylab("False Negative Rate") +
    ggplot2::theme_minimal()
  
  return(p)
}
