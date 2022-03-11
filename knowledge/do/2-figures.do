// Figures for knowledge paper

// Figure. Treatment accuracy by knowledge
use "${git}/data/knowledge.dta", clear

  tw ///
    (scatter percent_correctd theta_mle , jitter(10) m(x) mc(black%5)) ///
    (lpolyci percent_correctd theta_mle [aweight = weight] ,               ///
      degree(1) lw(thick) lcolor(red) ciplot(rline)         ///
      alcolor(black) alwidth(thin) alpat(dash))           ///
  , graphregion(color(white))                                               ///
    title("A. Conditions Diagnosed Correctly", size(medium) justification(left) color(black) span pos(11))         ///
    xtitle("Vignettes knowledge score {&rarr}", placement(left) justification(left)) xscale(titlegap(2))           ///
    ylab(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", angle(0) nogrid) yscale(noli) bgcolor(white) ytitle("")   ///
    xlabel(-5 (1) 5) xscale(noli) note("")     legend(off)
    
    graph save "${git}/temp/treat_scatter_1.gph", replace  
  
  tw ///
    (scatter percent_correctt theta_mle , jitter(10) m(x) mc(black%5))   ///
    (lpolyci percent_correctt theta_mle [aweight = weight],                 ///
      degree(1) lw(thick) lcolor(red) ciplot(rline)           ///
      alcolor(black) alwidth(thin) alpat(dash))             ///
  , graphregion(color(white))                                             ///
    title("B. Conditions Treated Correctly", size(medium) justification(left) color(black) span pos(11))         ///
    xtitle("Vignettes knowledge score {&rarr}", placement(left) justification(left)) xscale(titlegap(2))         ///
    ylab(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", angle(0) nogrid) yscale(noli) bgcolor(white) ytitle("")   ///
    xlabel(-5 (1) 5) xscale(noli) note("")     legend(off)
  
    graph save "${git}/temp/treat_scatter_2.gph", replace  
  
  graph combine ///
    "${git}/temp/treat_scatter_1.gph" ///
    "${git}/temp/treat_scatter_2.gph" ///
  , graphregion(color(white)) c(1) ysize(6)
  
    graph export "${git}/outputs/f-accuracy.png", replace 
  
// Figure. Box plot for knowledge score   
use "${git}/data/knowledge.dta", clear
  
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1
  
  vioplot theta_mle [pweight=weight] ///
  , over(country)  xline(-5(1)5,lc(gray) lw(thin))  hor ///
    yscale(reverse) xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(5) ///
    yscale(noline) xscale(noline) xlab(-5(1)5 0 "Av.", labsize(small) notick) ///
    den(lw(none) fc(gray)) bar(fc(black) lw(none)) ///
    line(lw(none)) med(m(|) mc(red) msize(large))
    
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
    qui mean prov_kenya if country == "`x'" [pweight=weight]
      local a = r(table)[1,1]
      local pct = substr("`a'",2,2)

    vioplot theta_mle if country == "`x'" [pweight=weight] ///
    , over(provider_cadre1) xline(-5(1)5,lc(black) lw(thin))  hor ///
      yscale(reverse) xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(7) ///
      yscale(noline) xscale(off) xlab(-5(1)5 0 "Av.", labsize(small)) ///
      den(lw(none) fc(gray)) bar(fc(black) lw(none)) ///
      line(lw(none)) med(m(|) mc(red) msize(large)) ///
      title("`x' [`pct'%]" , span pos(11)) nodraw saving("${git}/temp/`x'.gph" , replace) 
  }

  gen x = 0
  scatter x x in 1 , m(i) xlab(-5(1)5 , notick) ///
    xscale(noline) yscale(noline) ytit(" ") xtit(" ") nodraw ///
    saving("${git}/temp/blank.gph" , replace) ///
    ylab(1 "Doctor" , labc(white%0) labsize(small) notick) 
      
  graph combine ///
    "${git}/temp/Full Sample.gph" "${git}/temp/Malawi.gph" ///
    "${git}/temp/Kenya.gph" "${git}/temp/Tanzania.gph" ///
    "${git}/temp/Togo.gph" "${git}/temp/Guinea Bissau.gph" ///
    "${git}/temp/Madagascar.gph" "${git}/temp/Uganda.gph" ///
    "${git}/temp/Mozambique.gph" "${git}/temp/Sierra Leone.gph" ///
    "${git}/temp/Nigeria.gph" "${git}/temp/Niger.gph" ///
    "${git}/temp/blank.gph"  ///
  , xcom c(1) ysize(5) imargin(zero)
    
  graph export "${git}/outputs/f-cadre.png", replace width(2000) 

// Figure. Quantile distributions by education
use "${git}/data/knowledge.dta", clear

  drop if country == "Uganda"
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1
    
  // Kenya Diploma Reference 
  summarize theta_mle if country == "Kenya" & provider_mededuc1 == 3, d
    local ken_med  = `r(p50)' 
    gen prov_kenya  = (theta_mle >= `ken_med')
    
  qui levelsof(country) , local(countries)
  foreach x in `countries' {
    qui mean prov_kenya if country == "`x'" [pweight=weight]
      local a = r(table)[1,1]
      local pct = substr("`a'",2,2)

    vioplot theta_mle if country == "`x'" [pweight=weight] ///
    , over(provider_mededuc1)  xline(-5(1)5,lc(black) lw(thin))  hor ///
      xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(7) ///
      yscale(noline) xscale(off)  xlab(-5(1)5 0 "Av.", labsize(small)) ///
      den(lw(none) fc(gray)) bar(fc(black) lw(none)) ///
      line(lw(none)) med(m(|) mc(red) msize(large)) ///
      title("`x' [`pct'%]" , span pos(11)) nodraw saving("${git}/temp/`x'.gph" , replace) 
  }
  
  gen x = 0
  scatter x x in 1 , m(i) xlab(-5(1)5 , notick) ///
    xscale(noline) yscale(noline) ytit(" ") xtit(" ") nodraw ///
    saving("${git}/temp/blank.gph" , replace) ///
    ylab(1 "Certificate" , labc(white%0) labsize(small) notick) 
  
  graph combine ///
    "${git}/temp/Full Sample.gph" "${git}/temp/Malawi.gph" ///
    "${git}/temp/Kenya.gph" "${git}/temp/Tanzania.gph" ///
    "${git}/temp/Togo.gph" "${git}/temp/Guinea Bissau.gph" ///
    "${git}/temp/Madagascar.gph"  ///
    "${git}/temp/Mozambique.gph" "${git}/temp/Sierra Leone.gph" ///
    "${git}/temp/Nigeria.gph" "${git}/temp/Niger.gph" ///
    "${git}/temp/blank.gph"  ///
  , xcom c(1) ysize(5) imargin(zero)
      
    graph export "${git}/outputs/f-education.png", replace width(2000)   
  
// Age - Knowledge
use "${git}/data/knowledge.dta", clear

replace provider_age1 = . if provider_age1>80 | provider_age1<=19

expand 2 , gen(total)
  replace country = " Full Sample" if total == 1

egen loq = pctile(theta_mle), p(25) by(country provider_age1)
egen mpq = pctile(theta_mle), p(50) by(country provider_age1)
egen upq = pctile(theta_mle), p(75) by(country provider_age1)

histogram provider_age1, by(country , ixaxes note(" ") ///
    legend(r(1) order(1 "Age" 2 "Correct Management Mean" 3 "25th and 75th Percentiles") size(small))) ///
  start(15) w(5) fc(gray) lc(none)  ///
  barwidth(4) percent ylab(0 "0%" 10 "10%" 20 "20%" 30 "30%") yscale(alt) yscale(alt axis(2)) ///
  xlab(20(10)70  , labsize(vsmall)) ///
  ytit(" ") xtit(" ") ///
  addplot((fpfit theta_mle provider_age1 [pweight=weight], lc(red) lw(thick) yaxis(2)) ///
    (fpfit upq provider_age1 [pweight=weight], lc(red) yaxis(2) ) ///
    (fpfit loq provider_age1 [pweight=weight], lc(red) yaxis(2))) ///
  legend(r(1) region(lw(none)) pos(12) order(1 "Age (Right)"  2 "Knowledge Mean" 3 "25th / 75th Percentiles") size(small))
  
  graph export "${git}/outputs/f-age-knowledge.png", replace width(2000)   
   
// Age - Treatment
use "${git}/data/knowledge.dta", clear

replace provider_age1 = . if provider_age1>80 | provider_age1<=19

expand 2 , gen(total)
  replace country = " Full Sample" if total == 1
  
egen loq = pctile(percent_correctt), p(25) by(country provider_age1)
egen mpq = pctile(percent_correctt), p(50) by(country provider_age1)
egen upq = pctile(percent_correctt), p(75) by(country provider_age1)

histogram provider_age1, by(country , ixaxes note(" ") ///
    legend(r(1) order(1 "Age" 2 "Correct Management Mean" 3 "25th and 75th Percentiles") size(small))) ///
  start(15) w(5) fc(gray) lc(none) ///
  barwidth(4) percent ylab(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%") ///
  xlab(20(10)70 , labsize(vsmall)) ///
  ytit(" ") xtit(" ") ///
  addplot((fpfit percent_correctt provider_age1 [pweight=weight], lc(red) lw(thick)) ///
    (fpfit upq provider_age1 [pweight=weight], lc(red) ) ///
    (fpfit loq provider_age1 [pweight=weight], lc(red) )) ///
  legend(r(1) region(lw(none)) pos(12) order(1 "Age"  2 "Treatment Mean" 3 "25th / 75th Percentiles") size(small))
  
  graph export "${git}/outputs/f-age-treatment.png", replace width(2000)   
    
*************************** End of do-file *****************************************
