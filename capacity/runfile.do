// Set file paths

global box "/Users/bbdaniels/Documents/Papers/SDI Reallocation/data"
global git "/Users/bbdaniels/GitHub/sdi-health/capacity"

// Installs for user-written packages

  cap ssc install repkit , replace

  * qui do "${git}/do/labelcollapse.ado"
  cap ssc install cdfplot , replace
  cap net install grc1leg , from("http://www.stata.com/users/vwiggins/") replace
  cap ssc install iefieldkit , replace

// Copy in raw data -- comment out in final package

  iecodebook export "${box}/comparison.dta" ///
    using "${git}/raw/comparison.xlsx" ///
    , replace save sign verify

  copy "${box}/All_countries_harm.dta" ///
     "${git}/raw/vignettes.dta" ///
    , replace

  iecodebook export "${box}/All_countries_pl.dta" ///
    using "${git}/raw/vignettes-provider.xlsx" ///
    , replace save sign verify

  iecodebook export "${box}/IRT_parameters.dta" ///
    using "${git}/raw/irt-parameters.xlsx" ///
    , replace save sign reset

  copy "${box}/provider-codebook.xlsx" ///
    "${git}/raw/provider-codebook.xlsx" , replace

// Run all code (with flags)

  if 1 qui do "${git}/do/1-makedata.do"
  if 0 qui do "${git}/do/2-simulations.do"
  if 1 qui do "${git}/do/3-exhibits.do"
  if 1 qui do "${git}/do/4-queueing.do"
  if 1 qui do "${git}/do/5-robustness.do"
  if 1 qui do "${git}/do/6-appendix.do"

//
