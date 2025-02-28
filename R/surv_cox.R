#' Cox Function that can either be time dependent or time independent
#'
#' Function that calls Survival Object and Coxph in one function call. This function can be
#' used if your dataset is cross sectional (one observation per individual) and longitudianl
#' (multiple observations per individual). It can also be used if your hazard ratios are time
#' independent (hazard is constant with time) or if you hazard ratios are time depedent
#' (hazard changes with time).
#' @param data dataframe that includes the covariates we would like to model. If your dataset is longitudinal,
#' the recommendation is to use SLAM::surv_tmerge to create an interval dataframe.
#' @param covariates on sided formula starting with "~" that provides the formula
#' for the cox model. If the coefficients for your covariates are time dependent, that covariate
#' should be wrapped with the tt() function, for example tt(age_wk). Then in tt argument of this function
#' define the function that will time transform your variable.
#' @param time A character string. In cross sectional data, it should be the name of the
#' variable for age of observation in data. Inlongitudinal datasets created by SLAM::surv_tmerge,
#' this will be "tstart"
#' @param time2 A optional character string only used when working with longitudinal datasets.
#' This string provides the variable that defines theend point of interval in longitudinal datasets. If
#' the dataset is created by SLAM::surv_tmerge, it would be "tstop".
#' @param death A character string. in cross-sectional datasets, this is the variable that determines death censorship, where
#' a natural death is 1 and a censored subject is 0. In longitudinal datasets, this variable specifies
#' whether or not a subject died at the end of the interval. If your longitudinal dataset was created by
#' SLAM::surv_tmerge, this would be "tstop".
#' @param tt a function that defines the time transformation that will be applied when a covariate is wrapped
#' with the tt(). By default tt = NULL.
#' @param type A character string that specifies the type of censoring.
#' @return returns coxph object
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
#' @seealso \link[survival]{Surv} \link[survival]{coxph}
#'
#' @export

surv_cox <- function(data, covariates, time, time2 = NULL, death, tt = NULL, type = c("right", "left", "interval", "counting", "interval2", "mstate")) {
  if (is.null(time2)) {
    surv_object <- survival::Surv(time = data[[time]], event = data[[death]], type = type)
  } else {
    surv_object <- survival::Surv(time = data[[time]], time2 = data[[time2]], event = data[[death]])
  }
  cox.form <- as.formula(paste0("surv_object", deparse(covariates)))

  if (is.null(tt)) {
    fit <- survival::coxph(cox.form, data = data)
  } else {
    fit <- survival::coxph(cox.form, data = data, tt = tt)
  }
  return(fit)
}
