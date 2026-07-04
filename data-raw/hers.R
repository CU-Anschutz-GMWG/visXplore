# Prepare the `hers` package dataset from the raw Heart and Estrogen/Progestin
# Replacement Study (HERS) baseline data.
#
# Source: the HERS teaching dataset distributed with Vittinghoff, Glidden,
# Shuboski & McCulloch, "Regression Methods in Biostatistics" (Springer).
# The raw file (archive/coradar/hers_data.rds) is not shipped with the package.

raw <- readRDS("archive/coradar/hers_data.rds")

hers <- as.data.frame(raw)

# physact (physical activity) and globrat (self-reported health) are ordinal
# 1-5 scores stored as factors; store them as integer scores so they can be
# used directly on numeric-axis displays such as coradar().
hers$physact <- as.numeric(as.character(hers$physact))
hers$globrat <- as.numeric(as.character(hers$globrat))

# raceth is a genuine nominal factor; give it readable labels.
hers$raceth <- factor(hers$raceth, levels = c("1", "2", "3"),
                      labels = c("White", "African American", "Other"))

# drop the Hmisc column labels so the object prints cleanly; the coding is
# documented in R/data.R instead.
hers[] <- lapply(hers, function(x) {
  attr(x, "label") <- NULL
  x
})
attr(hers, "label") <- NULL
rownames(hers) <- NULL

usethis::use_data(hers, overwrite = TRUE)
