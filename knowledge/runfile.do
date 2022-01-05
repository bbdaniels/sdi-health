// Set file paths

global box "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/SDI WBG/SDI project/DataWork/endline/DataSets/Knowledge"
global git "/Users/bbdaniels/GitHub/sdi-health/knowledge"

// Installs etc

ssc install iefieldkit

// Raw data flag

local makedata = 0

// Run all code

if `makedata' qui do "${git}/do/1-makedata.do"
