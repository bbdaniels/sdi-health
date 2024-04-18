// Figures for competence paper

// Figure 1. Distribution of competence scores by country
use "${git}/data/knowledge.dta", clear

  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1

  vioplot theta_mle [pweight=weight] ///
  , over(country)  xline(-5(1)5,lc(gray) lw(thin))  hor ///
    yscale(reverse) xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(5) ///
    yscale(noline) xscale(noline) xlab(-5(1)5 0 , labsize(small) notick) ///
    den(lw() lc(black) fc(black%80)) bar(fc(red) lw(none)) ///
    line(lw(none)) med(m(|) mc(red) msize(large)) ///
    note("Provider competence score {&rarr}")

  graph export "${git}/outputs/f-quantile.png", replace width(2000)

// Figure 2. Distribution of competence scores by country and cadre
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
      den(lw() lc(black) fc(black%80)) bar(fc(red) lw(none)) ///
      line(lw(none)) med(m(|) mc(red) msize(large)) ///
      title("{bf:`x'} - {it:Doctors above median Kenyan nurse: [`pct'%]}"  ///
        , size(medsmall) span pos(11) ring(1)) note("Provider competence score {&rarr}") ///
      nodraw saving("${git}/temp/`x'.gph" , replace)
  }

  graph combine ///
    "${git}/temp/Full Sample.gph" "${git}/temp/Guinea Bissau.gph" ///
    "${git}/temp/Kenya.gph" "${git}/temp/Madagascar.gph" ///
    "${git}/temp/Malawi.gph" "${git}/temp/Mozambique.gph"  ///
    "${git}/temp/Niger.gph" "${git}/temp/Nigeria.gph" ///
    "${git}/temp/Sierra Leone.gph" "${git}/temp/Tanzania.gph" ///
    "${git}/temp/Togo.gph" "${git}/temp/Uganda.gph" ///
  , xcom c(2) ysize(5) imargin(zero) colfirst

  graph export "${git}/outputs/f-cadre.png", replace width(2000)

// Figure 2. Provider competence scores by country and cohort
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
