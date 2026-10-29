# Run from the project root: Rscript setup.R
# .Rprofile bootstraps the lockfile's renv version into the project library.
if(!requireNamespace('renv',quietly=TRUE)) stop('Run Rscript setup.R from the project root without --vanilla.')
renv::restore(library=renv::paths$library(),prompt=FALSE)
