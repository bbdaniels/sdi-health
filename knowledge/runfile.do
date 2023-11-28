// Set file paths


global box "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/SDI Knowledge/"
global irt "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/_Archive/SDI WBG/SDI/SDI Import/data/analysis/dta/"
global git "/Users/bbdaniels/GitHub/sdi-health/knowledge"

// Installs etc

cap ssc install iefieldkit
cap ssc install vioplot
cap net install binsreg , from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata/")

// Raw data flag

local makedata = 0

// Run all code

if `makedata' qui do "${git}/do/1-makedata.do"
  qui do "${git}/do/2-figures.do"
  qui do "${git}/do/3-tables.do"

// End
