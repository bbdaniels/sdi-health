
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




    
