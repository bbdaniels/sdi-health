// Tables for knowledge paper

// Table. Sample description
use "${git}/data/knowledge.dta", clear

  gen urban = 1 - rural
  gen private = 1 - public
  gen fem = 1 - provider_male1

  local varlist rural urban private public hospital health_ce health_po ///
    doctor nurse other advanced diploma certificate fem provider_male1 provider_age1

    lab var rural "Rural"
    lab var urban "Urban"
    lab var private "Private"
    lab var public "Public"
    lab var hospital "Hospital"
    lab var health_ce "Clinic"
    lab var health_po "Health Post"
    lab var doctor "Doctor"
    lab var nurse "Nurse"
    lab var other "Other"
    lab var advanced "Advanced"
    lab var diploma "Diploma"
    lab var certificate "Certificate"
    lab var provider_male1 "Men"
    lab var fem "Women"
    lab var provider_age1 "Age"

  qui forv i = 1/7 {
    logit treat`i' theta_mle i.countrycode
      predict p`i' , pr
    gen x`i' = !missing(p`i')
  }

  egen x = rowtotal(x?)
  egen p = rowtotal(p?)
   gen c = p/x

  levelsof country , local(levels)

  cap mat drop results
  local rows ""
  foreach c in `levels' {
  cap mat drop result
    foreach var in `varlist' {
      su `var' if country == "`c'"
        local mean = r(mean)
        local n = r(N)
      cap su c if country == "`c'" & `var' == 1 , d
        local p25 = r(p25)
        local p75 = r(p75)

      mat result = nullmat(result) ///
                    \ [`mean'] \ [`p25'] \ [`p75']

      local rows `" `rows' "`: var lab `var''" "  IQR 25th" "  IQR 75th"   "'
    }
    mat result = [`n'] \ result
    mat results = nullmat(results) , result
  }

  cap mat drop results_STARS

  outwrite results using "${git}/outputs/t-summary.xlsx" ///
    , replace colnames(`levels') rownames("N" `rows')

// Table 2. Regression results

  // Regression results using wide data
  use "${git}/data/knowledge.dta", clear
  replace provider_age1 = provider_age1/10

    reg   theta_mle i.provider_cadre provider_age1 advanced diploma [pweight=weight], vce(cluster survey_id)
    eststo   theta_mle1
    estadd  local hascout  "No"

      reg   theta_mle i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], vce(cluster survey_id)
      eststo   theta_mle2
      estadd  local hascout  "No"

      areg   theta_mle i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], ab(countrycode) cluster(survey_id)
      eststo   theta_mle3
      estadd  local hascout  "Yes"

  // Long data
  use "${git}/data/knowledge-long.dta", clear
  replace provider_age1 = provider_age1/10

    reg   treat i.provider_cadre provider_age1 advanced diploma [pweight=weight], vce(cluster survey_id)
    eststo   treat1
    estadd  local hascout  "No"

      reg   treat i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight],  vce(cluster survey_id)
      eststo   treat2
      estadd  local hascout  "No"

      areg   treat i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], ab(countrycode) cluster(survey_id)
      eststo   treat3
      estadd  local hascout  "Yes"

    reg   diag i.provider_cadre provider_age1 advanced diploma [pweight=weight], vce(cluster survey_id)
    eststo   diag1
    estadd  local hascout  "No"

      reg    diag i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], vce(cluster survey_id)
      eststo   diag2
      estadd  local hascout  "No"

      areg  diag i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], ab(countrycode) cluster(survey_id)
      eststo   diag3
      estadd  local hascout  "Yes"

  // Export
  esttab   ///
    theta_mle1 theta_mle2 theta_mle3                ///
    diag1 diag2 diag3                          ///
    treat1 treat2 treat3                        ///
  using "${git}/outputs/t-regression.xls" ///
  , replace b(%9.2f) ci(%9.2f)       ///
    stats(hascout N r2,  fmt(0 0 3)               ///
      labels("Country Control" "Observations" "R-Squared"))    ///
    mgroups("Knowledge Score" "Diagnoses Condition Correctly" "Treats Condition Correctly", pattern(1 0 0 1 0 0 1 0 0)) ///
    tab label collabels(none)  nobaselevels  mtitles("" "" "" "" "" "" "" "" "")  ///
    nodepvars nocons nostar

// End
