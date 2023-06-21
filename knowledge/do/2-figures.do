// Figures for knowledge paper

// Figure. Internal consistency

// Get item parameters
local 3pl "/Users/bbdaniels/Library/CloudStorage/Box-Box/_Papers/_Archive/SDI WBG/SDI/SDI Import/data/analysis/dta/irt_output_items.dta"
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
       , range(-5 5) lc(red) lw(thick)) ///
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
    (scatter percent_correctd theta_mle , jitter(10) m(x) mc(black%5))       ///
    (lpolyci percent_correctd theta_mle ///
      [aweight = weight] if theta_mle < 4.5 ,                           ///
      degree(1) lw(thick) lcolor(red) ciplot(rline)                          ///
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
    (scatter percent_correctt theta_mle , jitter(10) m(x) mc(black%5))       ///
    (lpolyci percent_correctt theta_mle ///
      [aweight = weight] if theta_mle < 4.5 ,                           ///
      degree(1) lw(thick) lcolor(red) ciplot(rline)                          ///
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

// Figure. Box plot for knowledge score
use "${git}/data/knowledge.dta", clear

  expand 2 , gen(total)
    replace country = " [HDI] Full Sample" if total == 1
    replace country = "[143] " + country if country == "Kenya"
    replace country = "[159] " + country if country == "Uganda"
    replace country = "[175] " + country if country == "Guinea Bissau"
    replace country = "[164] " + country if country == "Madagascar"
    replace country = "[174] " + country if country == "Malawi"
    replace country = "[181] " + country if country == "Mozambique"
    replace country = "[189] " + country if country == "Niger"
    replace country = "[161] " + country if country == "Nigeria"
    replace country = "[182] " + country if country == "Sierra Leone"
    replace country = "[163] " + country if country == "Tanzania"
    replace country = "[167] " + country if country == "Togo"

  vioplot theta_mle [pweight=weight] ///
  , over(country)  xline(-5(1)5,lc(gray) lw(thin))  hor ///
    yscale(reverse) xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(5) ///
    yscale(noline) xscale(noline) xlab(-5(1)5 0 , labsize(small) notick) ///
    den(lw() lc(black) fc(black%0)) bar(fc(red) lw(none)) ///
    line(lw(none)) med(m(|) mc(red) msize(large)) ///
    note("Provider competence score {&rarr}")

  graph export "${git}/outputs/f-quantile.png", replace width(2000)

// Figure. Quantile distributions by cadre
use "${git}/data/knowledge.dta", clear

  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1

  // Kenya Nurses Reference
  summarize theta_mle if country == "Kenya" & provider_cadre1 == 3, d
    local ken_med  = `r(p50)'
    gen prov_kenya  = (theta_mle >= `ken_med')

  qui levelsof(country) , local(countries)
  foreach x in `countries' {
    qui mean prov_kenya if country == "`x'" & provider_cadre1 == 1 [pweight=weight]
      local a = r(table)[1,1]
      local pct = substr("`a'0",2,2)

    vioplot theta_mle if country == "`x'" & theta_mle > -3 & theta_mle < 3 [pweight=weight] ///
    , over(provider_cadre1) xline(-3(1)3,lc(black) lw(thin))  hor ///
      yscale(reverse) xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(7) ///
      yscale(noline) xscale(noline) xlab(-3(1)3 0 , labsize(small)) ///
      den(lw(none) fc(black%80)) bar(fc(red) lw(none)) ///
      line(lw(none)) med(m(|) mc(red) msize(large)) ///
      title("{bf:`x'} - {it:Doctors above median Kenyan nurse: [`pct'%]}"  ///
        , size(medsmall) span pos(11) ring(1)) note("Provider competence score {&rarr}") ///
      nodraw saving("${git}/temp/`x'.gph" , replace)
  }

  gen x = 0
  scatter x x in 1 , m(i) xlab(-3(1)3 , notick) ///
    xscale(noline) yscale(noline) ytit(" ") xtit(" ") nodraw ///
    saving("${git}/temp/blank.gph" , replace) ///
    ylab(1 "Doctor" , labc(white%0) labsize(small) notick) ///
    note("Provider competence score {&rarr}" , ring(0))

  graph combine ///
    "${git}/temp/Full Sample.gph" "${git}/temp/Guinea Bissau.gph" ///
    "${git}/temp/Kenya.gph" "${git}/temp/Madagascar.gph" ///
    "${git}/temp/Malawi.gph" "${git}/temp/Mozambique.gph"  ///
    "${git}/temp/Niger.gph" "${git}/temp/Nigeria.gph" ///
    "${git}/temp/Sierra Leone.gph" "${git}/temp/Tanzania.gph" ///
    "${git}/temp/Togo.gph" "${git}/temp/Uganda.gph" ///
  , xcom c(2) ysize(5) imargin(zero) colfirst

  graph export "${git}/outputs/f-cadre.png", replace width(2000)

// Age - Knowledge
use "${git}/data/knowledge.dta", clear

replace provider_age1 = . if provider_age1>80 | provider_age1<=19

  encode country , gen(c)

  reg theta_mle c.provider_age1#i.c ///
    advanced diploma i.facility_level_rec ///
    i.rural_rec i.public_rec [pweight=weight]

    mat a = r(table)'
    levelsof country , local(cs)

    preserve
      clear
      svmat a
      gen country = ""
      local x = 0
      foreach c in `cs' {
        local ++x
        replace country = "`c'" in `x'
      }

      keep if country != ""
      keep if country != "Uganda" & country != " Full Sample"
      egen c = rank(a1)

      tw ///
        (rcap a5 a6 c , lc(gray)) ///
        (scatter a1 c , mc(black) mlab(country) mlabc(black) mlabpos(3) mlabangle(20) mlabsize(vsmall)) ///
      , xoverhang xscale(reverse) yscale(noline reverse) yline(-0.03(0.01)0.03 , lc(gs14)) ///
        yline(0 , lc(red)) xscale(off) nodraw fysize(20) ///
        title("Improvement per decade (controlled for covariates)" ///
          , span pos(11)) saving("${git}/temp/regress.gph" , replace) ///
        ylab(0 "Zero" -0.03 "+0.3 SD" -0.02 "+0.2 SD" -0.01 "+0.1 SD" ///
                       0.03 "-0.3 SD"  0.02 "-0.2 SD"  0.01 "-0.1 SD" , notick)

    restore

expand 2 , gen(total)
  replace country = " Full Sample" if total == 1

egen loq = pctile(theta_mle), p(25) by(country provider_age1)
egen mpq = pctile(theta_mle), p(50) by(country provider_age1)
egen upq = pctile(theta_mle), p(75) by(country provider_age1)

histogram provider_age1, by(country , ixaxes note(" ") ///
    legend(r(1) pos(12) order(1 "Age" 2 "Correct Management Mean" 3 "25th and 75th Percentiles") size(small))) ///
  start(15) w(5) fc(black%80) lc(none)  ///
  barwidth(4) percent ylab(0 "{&uarr} Age (%)" 10 "10%" 20 "20%" 30 "30%") yscale(alt) yscale(alt axis(2)) ///
  xlab(10 "Age {&rarr}" 20(10)70  , labsize(vsmall)) ///
  ylab(-3 "Competence {&uarr}" -2(1)2 , axis(2)) ///
  ytit(" ") xtit(" ") subtitle(,nobox) ///
  addplot((fpfit theta_mle provider_age1 [pweight=weight], lc(red) lw(thick) yaxis(2)) ///
    (fpfit upq provider_age1 [pweight=weight], lc(black) lp(dash) yaxis(2) ) ///
    (fpfit loq provider_age1 [pweight=weight], lc(black) lp(dash) yaxis(2))) ///
  legend(r(1) region(lw(none)) size(small) pos(12) ///
    order(2 "Competence Mean" 3 "IQR (25th - 75th)" 1 "Age Bins (%, Right Scale)") ) ///
  nodraw saving("${git}/temp/lpfit.gph" , replace)

  graph combine "${git}/temp/lpfit.gph" "${git}/temp/regress.gph" ///
    , c(1) imargin(zero) ysize(5)

  graph export "${git}/outputs/f-age-knowledge.png", replace width(2000)

*************************** End of do-file *****************************************
