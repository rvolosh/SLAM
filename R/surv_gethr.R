#' Get Hazard Ratio from Cox Model
#'
#' The purpose of this function is so that the user can easily extract hazard ratios,
#' hazard ratio confidence intervals, and hazard ratio pvalues easily. This function
#' also outputs Hazard Ratios that can easily be added plots
#' @param fit coxph model
#' @param vars character vector including the covariates fo the cox model that we would
#' like to extract hazard ratios for. Note: if a covariate was wrapped, for example tt(age_wk),
#' the wrapping and the variable should be included
#' @param names character vector of same length as vars that provides formal names for the variables
#' in place of variable name.
#' @param ndec numeric that specifies the number of decimal places to round the hazard ratios
#' @return
#'  \item{hr_table}{
#'  a dataframe whos rows correspond the variables inputted by the vars argument and whos names are
#'  determined by the names argument. If the names argument is not given the names are the same
#'  as the variable names.
#'  This dataframe has the following columns (1) value - provides the hazard ratio
#'  (2) lower - lower bound of 95% confidence interval for hazard ratio
#'  (3) upper - upper bound of 95% confidence interval for hazard ratio
#'  (4) pval - the p-value for the hazard ratio
#'  (5) final - a character stirng that includes columns 1-4 for table output
#'  (6) with_names - character string like final, but the variable name is included
#'  }
#'  \item{hr_text}{
#'  a character string that has the with names for each variable separated by \\n,
#'  so that the hazard ratios for vars can be included in a kaplan meier plot.
#'  }
#'
#' @examples
#' # Repeated Measures (Longitudinal) Example
#' # Lets see how glucose predicts mortaility in SLAM
#'
#' if (requireNamespace("dplyr", quietly = TRUE)) {
#'   # Checkout dataframes --------------------------------------------------------
#'   # Checkout census
#'   head(data_SLAM_census)
#'
#'   # Checkout glucose
#'   head(data_SLAM_gluc)
#'
#'   # Checkout survival data
#'   head(data_SLAM_surv)
#'
#'   # Create dataframe with everything -------------------------------------------
#'   # drop lactate to simplify
#'   main <- dplyr::select(data_SLAM_gluc, -lact)
#'   # obtain census info for dob
#'   main <- dplyr::left_join(main, data_SLAM_census, by = "idno")
#'   # obtain survival info for dod
#'   main <- dplyr::left_join(main, data_SLAM_surv, by = "tag")
#'   # filter mice without date of death
#'   main <- dplyr::filter(main, !is.na(died))
#'   # create age, age of death, and difference between age and age of death
#'   main <- dplyr::mutate(main,
#'     age_wk = as.numeric(difftime(date, dob, units = "weeks")),
#'     age_wk_death = as.numeric(difftime(died, dob, units = "weeks")),
#'     dif = age_wk_death - age_wk
#'   )
#'   # filter mice measured after death because tmerge will throw error
#'   main <- dplyr::filter(main, age_wk <= age_wk_death)
#'   # filter mice that were measured same day as death because tmerge with throw an error
#'   main <- dplyr::filter(main, !(age_wk == age_wk_death))
#'
#'   # Checkout main --------------------------------------------------------------
#'   # Table death censor. 0 means death was not natural and 1 means natural deat
#'   table(main$dead_censor)
#'
#'   # Checkout main
#'   head(main)
#'   # Checkout main NA's
#'   apply(apply(main, 2, is.na), 2, sum)
#'
#'   # Now use surv_tmerge --------------------------------------------------------
#'   main_tmerge <- surv_tmerge(
#'     data = main,
#'     id = "idno",
#'     age = "age_wk",
#'     age_death = "age_wk_death",
#'     death_censor = "dead_censor",
#'     outcomes = c("gluc")
#'   )
#'
#'   # Now lets make a cox model with our now time dependent dataframe ------------
#'   fit <- surv_cox(
#'     data = main_tmerge,
#'     covariates = ~ gluc + age_wk + sex + strain,
#'     time = "tstart",
#'     time2 = "tstop",
#'     death = "death"
#'   )
#'
#'   # Now lets extract Hazard Ratios ------------------------------------------
#'   hrs <- surv_gethr(
#'     fit = fit,
#'     vars = c("gluc", "age_wk"),
#'     names = c("Glucose", "Age (weeks)"),
#'     ndec = 4
#'   )
#'
#'   # Lets look at final HR table
#'   dplyr::select(hrs$hr_table, final)
#'
#'   # Lets make predictions on other data ---------------------------------------
#'   # create new data for 4 mice
#'   pred_df <- data.frame(
#'     age_wk = c(40, 80, 20, 100),
#'     gluc = c(180, 200, 150, 120),
#'     sex = c("M", "M", "F", "F"),
#'     strain = c("B6", "HET3", "B6", "HET3")
#'   )
#'   # use predict function to get HR for each mouse
#'   predict(fit, newdata = pred_df, type = "risk")
#' } else {
#'   print("Install dplyr to run this example")
#' }
#' @export


surv_gethr <- function(fit, vars, names = NULL, ndec = 4) {
  sum_fit <- summary(fit) ## get summary of fit
  coef <- data.frame(sum_fit$coefficients, check.names = F) # save coeffecients as dataframe
  conf <- data.frame(sum_fit$conf.int, check.names = F) # save confidence interval as dataframe
  hr <- data.frame() # initialize hr dataframe
  for (var in vars) { # loop through vars
    value <- format(round(conf[var, "exp(coef)"], ndec), nsmall = 2) # save hr
    lower <- format(round(conf[var, "lower .95"], ndec), nsmall = 2) # save lower HR bound
    upper <- format(round(conf[var, "upper .95"], ndec), nsmall = 2) # save upper HR bound
    pval <- coef[var, "Pr(>|z|)"] # save pval

    ## add stars depending on significance
    if (pval < .001) {
      final <- paste0("HR = ", value, " (", lower, ", ", upper, ")***")
    } else if (pval < .005) {
      final <- paste0("HR = ", value, " (", lower, ", ", upper, ")**")
    } else if (pval < 0.050) {
      final <- paste0("HR = ", value, " (", lower, ", ", upper, ")*")
    } else {
      final <- paste0("HR = ", value, " (", lower, ", ", upper, ")")
    }

    ## save stats above to hr dataframe
    hr[var, c("value", "lower", "upper", "pval", "final")] <- c(value, lower, upper, pval, final)
  }

  ## if names are provided, rename variables
  if (!is.null(names)) {
    rownames(hr) <- names
  }

  ## create a column that has the rownames printed before HR
  hr[, "with_names"] <- unlist(lapply(rownames(hr), function(name) {
    el <- paste(name, hr[name, "final"], sep = ": ")
  }))

  ## create text that can be used to easily add to KM plot in place of pval
  one_text <- paste(as.vector(hr[, "with_names"]), collapse = "\n")

  return(list(hr_table = hr, hr_text = one_text))
}
