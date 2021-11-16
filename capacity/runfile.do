
global box "/Users/bbdaniels/Box/_Papers/SDI WBG/SDI project/DataWork/endline/DataSets"
global git "/Users/bbdaniels/GitHub/sdi-health/capacity"

copy ///
  "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/SDI Allocation/comparison.dta" ///
  "${git}/data/comparison.dta", replace

qui do "${git}/do/labelcollapse.ado"

//
