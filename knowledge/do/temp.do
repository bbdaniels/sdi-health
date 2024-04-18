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

    
// Figure. Internal consistency

// Get item parameters
local 3pl "/Users/bbdaniels/Documents/Papers/_Archive/SDI WBG/SDI/SDI Import/data/analysis/dta/irt_output_items.dta"
  use "`3pl'"  , clear
// Plot
use "${git}/data/knowledge.dta", clear
  ren diabetes_history_numblimb diabetes_history_numb_limb
  egen check = rowmean(*history*)
  lab var check "Completion %: All History Questions"
  lab var diarrhea_history_duration "Diarrhoea: Duration"
  lab var tb_history_sputum "Tuberculosis: Productive Cough"
  lab var malaria_history_headache "Malaria: Headache"
  lab var pph_history_pph "PPH: Prior Occurrence"
  lab var diabetes_history_numb_limb "Diabetes: Limb Numbness"

  local graphs ""

    preserve
      use "`3pl'" , clear
      collapse (mean) a_pv1 b_pv1 c_pv1
      local a = a_pv1[1]
      local b = b_pv1[1]
      local c = c_pv1[1]
    restore
    preserve
      xtile c = theta_mle , n(100)

      local title :  var lab check
      collapse (mean) check theta_mle  , by(c) fast

      local graphs `"`graphs' "\`check'"  "'
      tempfile check

    tw ///
      (function `c'+(1-`c')*(exp(`a'*(x-`b')))/(1+exp(`a'*(x-`b'))) ///
       , range(-5 5) lc(red) lw(thick))         ///
      (scatter check theta_mle , mc(black)) ///
    , ylab(0 "0%" .5 "50%" 1 "100%" , notick) yline(0 .5 1 , lc(black)) ///
      yscale(noline) xscale(noline) ytit(" ") title("{bf:`title'}" , size(small)) ///
      xlab(0 "" 5 "+5" -5 "-5" -1 " " -2 " " -3 " " -4 " " 1 " " 2 " " 3 " " 4 " ") ///
        note("Provider competence score {&rarr}") xtit("") ///
      saving(`check') nodraw
    restore

   foreach var of varlist ///
    diarrhea_history_duration tb_history_sputum ///
    malaria_history_headache pph_history_pph ///
    diabetes_history_numb_limb  {

      preserve
        use "`3pl'" , clear
        keep if varname == "`var'"
        local a = a_pv1[1]
        local b = b_pv1[1]
        local c = c_pv1[1]
      restore
      preserve
        xtile c = theta_mle , n(100)

        local title :  var lab `var'
        collapse (mean) `var' theta_mle  , by(c) fast

        local graphs `"`graphs' "\``var''"  "'
        tempfile `var'

      tw ///
        (function `c'+(1-`c')*(exp(`a'*(x-`b')))/(1+exp(`a'*(x-`b'))) ///
         , range(-5 5) lc(red) lw(thick)) ///
        (scatter `var' theta_mle , mc(black)) ///
      , ylab(0 "0%" .5 "50%" 1 "100%" , notick) yline(0 .5 1 , lc(black)) ///
        yscale(noline) xscale(noline) ytit(" ") title("{bf:`title'}" , size(small)) ///
        xlab(0 "" 5 "+5" -5 "-5" -1 " " -2 " " -3 " " -4 " " 1 " " 2 " " 3 " " 4 " ") ///
          note("Provider competence score {&rarr}") xtit("") ///
        saving(``var'') nodraw
      restore
    }

    graph combine `graphs' , c(2) ysize(5)
      graph export "${git}/outputs/f-validation.png", replace

// Figure. Treatment accuracy by knowledge
use "${git}/data/knowledge.dta", clear
  tempfile 1 2

  tw ///
    (scatter percent_correctd theta_mle ///
      , jitter(2) m(.) mc(black%5) msize(tiny) mlc(none))       ///
    (fpfitci percent_correctd theta_mle ///
      [aweight = weight] if theta_mle < 4.5 ,                           ///
      lw(thick) lcolor(red) ciplot(rline)                          ///
      alcolor(black) alwidth(thin) alpat(dash))                              ///
  , graphregion(color(white))                                                ///
    title("A. Diagnostic Accuracy" ///
      , size(medium) justification(left) color(black) span pos(11))          ///
    xtitle("Provider competence score {&rarr}" ///
      , placement(left) justification(left)) xscale(titlegap(2))             ///
    ylab(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%" ///
      , angle(0) nogrid) yscale(noli) bgcolor(white) ///
    ytitle("Share of vignettes correct")   ///
    xlabel(-5 (1) 5) xscale(noli) note("") legend(off) nodraw saving("`1'")

  tw ///
    (scatter percent_correctt theta_mle ///
      , jitter(2) m(.) mc(black%5) msize(tiny) mlc(none))       ///
    (fpfitci percent_correctt theta_mle ///
      [aweight = weight] if theta_mle < 4.5 ,                           ///
      lw(thick) lcolor(red) ciplot(rline)                          ///
      alcolor(black) alwidth(thin) alpat(dash))                              ///
  , graphregion(color(white))                                                ///
    title("B. Treatment Accuracy" ///
      , size(medium) justification(left) color(black) span pos(11))          ///
    xtitle("Provider competence score {&rarr}" ///
      , placement(left) justification(left)) xscale(titlegap(2))             ///
    ylab(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%"               ///
      , angle(0) nogrid) yscale(noli) bgcolor(white) ///
    ytitle("Share of vignettes correct")   ///
    xlabel(-5 (1) 5) xscale(noli) note("") legend(off) nodraw saving("`2'")

  graph combine ///
    "`1'" ///
    "`2'" ///
  , graphregion(color(white)) c(1) ysize(6)

    graph export "${git}/outputs/f-accuracy.png", replace
