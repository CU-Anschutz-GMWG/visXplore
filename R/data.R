#' Heart and Estrogen/Progestin Replacement Study (HERS) baseline data
#'
#' Baseline measurements from the HERS study, a randomized trial of hormone
#' therapy for the secondary prevention of coronary heart disease in
#' postmenopausal women. The rich, highly correlated set of clinical,
#' demographic, and laboratory variables makes it a useful example for
#' visualizing multivariate structure (for example with \code{\link{coradar}}).
#'
#' @format A data frame with 2763 rows and 29 variables:
#' \describe{
#'   \item{HT}{randomization to hormone therapy (0 = placebo, 1 = hormone therapy)}
#'   \item{age}{age in years}
#'   \item{raceth}{race/ethnicity (factor: White, African American, Other)}
#'   \item{nonwhite}{nonwhite race/ethnicity (0/1)}
#'   \item{smoking}{current smoker (0/1)}
#'   \item{drinkany}{any current alcohol consumption (0/1)}
#'   \item{exercise}{exercises at least 3 times per week (0/1)}
#'   \item{physact}{comparative physical activity, ordinal 1 (much less active)
#'     to 5 (much more active)}
#'   \item{globrat}{self-reported health, ordinal 1 (poor) to 5 (excellent)}
#'   \item{poorfair}{poor/fair self-reported health (0/1)}
#'   \item{medcond}{other serious conditions by self-report (0/1)}
#'   \item{htnmeds}{anti-hypertensive use (0/1)}
#'   \item{statins}{statin use (0/1)}
#'   \item{diabetes}{diabetes (0/1)}
#'   \item{dmpills}{oral diabetes medication by self-report (0/1)}
#'   \item{insulin}{insulin use by self-report (0/1)}
#'   \item{weight}{weight (kg)}
#'   \item{BMI}{body mass index (kg/m^2)}
#'   \item{waist}{waist circumference (cm)}
#'   \item{WHR}{waist/hip ratio}
#'   \item{glucose}{fasting glucose (mg/dl)}
#'   \item{tchol}{total cholesterol (mg/dl)}
#'   \item{LDL}{LDL cholesterol (mg/dl)}
#'   \item{HDL}{HDL cholesterol (mg/dl)}
#'   \item{TG}{triglycerides (mg/dl)}
#'   \item{SBP}{systolic blood pressure (mmHg)}
#'   \item{DBP}{diastolic blood pressure (mmHg)}
#'   \item{LDL_oneyr}{LDL cholesterol at one year (mg/dl)}
#'   \item{HDL_oneyr}{HDL cholesterol at one year (mg/dl)}
#' }
#'
#' @details The ordinal scores \code{physact} and \code{globrat} are stored as
#' integers so they can be used directly on numeric-axis displays.
#'
#' @source The HERS teaching dataset distributed with Vittinghoff E, Glidden DV,
#'  Shiboski SC, McCulloch CE (2012). \emph{Regression Methods in Biostatistics},
#'  2nd ed. Springer. Trial described in Hulley S et al. (1998) JAMA
#'  280(7):605-613, \doi{10.1001/jama.280.7.605}.
#'
#' @examples
#' radar <- coradar(hers,
#'                  vars = c("age", "physact", "globrat", "weight", "BMI",
#'                           "waist", "WHR", "LDL", "HDL", "SBP", "DBP"),
#'                  min_degrees = 7)
#' radar
"hers"
