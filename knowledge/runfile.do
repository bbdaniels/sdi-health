// Set file paths


global box "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/SDI Competence/"
global irt "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/_Archive/SDI WBG/SDI/SDI Import/data/analysis/dta/"
global git "/Users/bbdaniels/GitHub/sdi-health/knowledge"

// Installs for user-written packages

cap ssc install iefieldkit
cap ssc install vioplot
cap net install binsreg , from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata/")

// Copy in raw data -- comment out in final package

  iecodebook export "${irt}/irt_output_items.dta" ///
    using "${git}/raw/irt_output_items.xlsx" ///
    , replace save sign verify

  iecodebook export "${box}/data/Vignettes_pl.dta" ///
    using "${git}/raw/vignettes.xlsx" ///
    , replace save sign verify

// Run all code (with flags)

  if 1 qui do "${git}/do/1-makedata.do"
  if 1 qui do "${git}/do/2-figures.do"
  if 1 qui do "${git}/do/3-tables.do"
  if 1 qui do "${git}/do/4-appendix.do"
  if 1 qui do "${git}/do/5-irc.do"

// End
