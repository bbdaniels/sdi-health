
global box "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/SDI Allocation/data"
global git "/Users/bbdaniels/GitHub/sdi-health/capacity"

copy ///
  "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/SDI Allocation/data/comparison.dta" ///
  "${git}/data/comparison.dta", replace

qui do "${git}/do/labelcollapse.ado"

qui do "${git}/do/1-makedata.do"
qui do "${git}/do/2-figures.do"
qui do "${git}/do/3-descriptives.do"
qui do "${git}/do/4-optimization.do"
qui do "${git}/do/5-optimization-bootstrap.do"

//
