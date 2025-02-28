#' SLAM Census
#'
#' A dataset that contains census information for each mouse in SLAM
#'
#' @docType data
#' @usage data(data_SLAM_census)
#' @format a dataframe 2783 obs and 12 variables
#' \describe{
#'   \item{cohort}{cohort of the mouse}
#'   \item{animal_id}{unique identification number for vivarium}
#'   \item{tag}{unique identifier for each mouse}
#'   \item{taghistory}{history of unique identifiers for each mouse, they sometimes have changed
#'   over the course of the study}
#'   \item{sex}{M or F denoting Male or Female}
#'   \item{dob}{date variable denoting date of birth}
#'   \item{idno}{another unique identifier from 1 to n, where 1 is the first mouse enrolled and n
#'   is the most recent mouse enrolled}
#'   \item{cage}{the number denoting the cage. The mice were housed mostly in groups of 4}
#'   \item{eartag}{marking pattern on mouses ears so animal technicians could identify the mouse}
#'   \item{name}{random name given to each mouse}
#' }
"data_SLAM_census"

