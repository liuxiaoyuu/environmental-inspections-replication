lock <- jsonlite::read_json('renv.lock')
for(package in names(lock$Packages)) {
  if(!requireNamespace(package,quietly=TRUE)) stop('Missing package ',package,'; run Rscript setup.R')
  actual <- as.character(utils::packageVersion(package))
  expected <- lock$Packages[[package]]$Version
  if(utils::packageVersion(package)!=package_version(expected)) stop(package,': expected ',expected,', found ',actual,'; run Rscript setup.R')
}
if(as.character(getRversion())!=lock$R$Version)
  warning('R version differs from the tested lockfile version ',lock$R$Version)
cat('All locked package versions match.\n')
