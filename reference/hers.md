# Heart and Estrogen/Progestin Replacement Study (HERS) baseline data

Baseline measurements from the HERS study, a randomized trial of hormone
therapy for the secondary prevention of coronary heart disease in
postmenopausal women. The rich, highly correlated set of clinical,
demographic, and laboratory variables makes it a useful example for
visualizing multivariate structure (for example with
[`coradar`](https://CU-Anschutz-GMWG.github.io/VisXplore/reference/coradar.md)).

## Usage

``` r
hers
```

## Format

A data frame with 2763 rows and 29 variables:

- HT:

  randomization to hormone therapy (0 = placebo, 1 = hormone therapy)

- age:

  age in years

- raceth:

  race/ethnicity (factor: White, African American, Other)

- nonwhite:

  nonwhite race/ethnicity (0/1)

- smoking:

  current smoker (0/1)

- drinkany:

  any current alcohol consumption (0/1)

- exercise:

  exercises at least 3 times per week (0/1)

- physact:

  comparative physical activity, ordinal 1 (much less active) to 5 (much
  more active)

- globrat:

  self-reported health, ordinal 1 (poor) to 5 (excellent)

- poorfair:

  poor/fair self-reported health (0/1)

- medcond:

  other serious conditions by self-report (0/1)

- htnmeds:

  anti-hypertensive use (0/1)

- statins:

  statin use (0/1)

- diabetes:

  diabetes (0/1)

- dmpills:

  oral diabetes medication by self-report (0/1)

- insulin:

  insulin use by self-report (0/1)

- weight:

  weight (kg)

- BMI:

  body mass index (kg/m^2)

- waist:

  waist circumference (cm)

- WHR:

  waist/hip ratio

- glucose:

  fasting glucose (mg/dl)

- tchol:

  total cholesterol (mg/dl)

- LDL:

  LDL cholesterol (mg/dl)

- HDL:

  HDL cholesterol (mg/dl)

- TG:

  triglycerides (mg/dl)

- SBP:

  systolic blood pressure (mmHg)

- DBP:

  diastolic blood pressure (mmHg)

- LDL_oneyr:

  LDL cholesterol at one year (mg/dl)

- HDL_oneyr:

  HDL cholesterol at one year (mg/dl)

## Source

The HERS teaching dataset distributed with Vittinghoff E, Glidden DV,
Shiboski SC, McCulloch CE (2012). *Regression Methods in Biostatistics*,
2nd ed. Springer. Trial described in Hulley S et al. (1998) JAMA
280(7):605-613,
[doi:10.1001/jama.280.7.605](https://doi.org/10.1001/jama.280.7.605) .

## Details

The ordinal scores `physact` and `globrat` are stored as integers so
they can be used directly on numeric-axis displays.

## Examples

``` r
radar <- coradar(hers,
                 vars = c("age", "physact", "globrat", "weight", "BMI",
                          "waist", "WHR", "LDL", "HDL", "SBP", "DBP"),
                 min_degrees = 7)
#> Removed 23 rows with missing values.
radar
#> Co-radar plot of 11 variables, 2740 observations
#> Normalization: minmax 
#> 
#> Axis positions (degrees):
#>     age     DBP     WHR  weight     BMI   waist     HDL physact globrat     LDL 
#>       0      44     109     142     150     157     201     233     303     312 
#>     SBP 
#>     346 
```
