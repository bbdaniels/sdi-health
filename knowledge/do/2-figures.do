// Figures for knowledge paper

// Figure. Treatment accuracy by knowledge
use "${git}/data/knowledge.dta", clear

  tw ///
    (scatter percent_correctd theta_mle , jitter(10) m(x) mc(black%5)) ///
    (lpolyci percent_correctd theta_mle ,               ///
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
    (lpolyci percent_correctt theta_mle ,                 ///
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
  
  bys country: egen med = median(theta_mle)
  
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1
    replace med = 10 if total == 1
      
  local styles ""
  forvalues i = 2/12 {
    local styles "`styles' box(`i', fcolor(none) lcolor(black) lwidth(0.4)) marker(`i', mlw(none) msize(vsmall) mcolor(black%10)) "
  }
     
  graph box theta_mle ///
  , over(country, sort(med) descending axis(noli) label(labsize(small)))    ///
    `styles' medtype(cline) medline(lc(red) lw(thick)) ///
    box(1, fcolor(none) lcolor(black) lwidth(0.6)) marker(1, mlw(none) msize(vsmall) mcolor(black%10))     ///
     yline(0, lwidth(thin) lcolor(black) lpattern(solid))                    ///
    ylabel(-5(1)5 0 "Average", labsize(small) angle(0) nogrid)                           ///
    ytitle("Vignettes knowledge score {&rarr}", placement(left) justification(left) size(small))   ///
    legend(off) yscale(range(-5 5) titlegap(2)) bgcolor(white) graphregion(color(white)) asyvars   ///
    showyvars horizontal
    
  graph export "${git}/outputs/f-quantile.png", replace width(2000)
  
// Figure. Quantile distributions by cadre
use "${git}/data/knowledge.dta", clear

  bys country: egen med = median(theta_mle)
  
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1
    replace med = 10 if total == 1  
    
  recode provider_cadre1 (1=4)(4=1)
  // Kenya Nurses Reference 
  summarize theta_mle if country == "Kenya" & provider_cadre1 == 3, d
    local ken_med  = `r(p50)' 
    gen prov_kenya  = (theta_mle >= `ken_med')
  
  graph box theta_mle ///
  , over(provider_cadre1, sort(provider_cadre1) axis(noli) label(nolabel))                       ///
    over(country, sort(med) descending axis(noli) label(labsize(small)))                       ///
    noout cwhi line(lw(vthin) lc(black)) al(0) medtype(cline) medline(lc(red) lw(thick)) ///
    box(1, lwidth(0.4) fcolor(none) lcolor(black*0.4))                             ///
    box(2, lwidth(0.4) fcolor(none) lcolor(black*0.7))                                 ///
    box(3, lwidth(0.4) fcolor(none) lcolor(black*1.0))                                 ///
    graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid)   ///
    legend(order(3 "Para-Professional" 2 "Nurse"  1 "Doctor" )                ///
      pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) symx(4) symy(2) size(small))     ///
    yscale(range(-3 3) titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)        ///
    ylabel(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3" , labsize(small))               ///
    yline(`ken_med', lwidth(thin) lcolor(black) lpattern(solid))                       ///
    ytitle("Vignette knowledge score {&rarr}", size(small)) allcategories  note("")  
    
    graph save "${git}/temp/f-cadre_1.gph", replace 
    
  graph bar prov_kenya,                                           ///
    over(provider_cadre1, axis(noli) label(nolabel))                       ///
    over(country, sort(med) descending axis(noli) label(labsize(small)))                     ///
    bar(1, lc(none) fcolor(black*0.4))                                   ///
    bar(2, lc(none) fcolor(black*0.7))                                   ///
    bar(3, lc(none) fcolor(black*1.0))                                   ///
    bargap(20) yline(.5 , lwidth(thin) lcolor(black) lpattern(solid)) ///
    graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid)   ///
    legend(on order(1 "Para-Professional" 2 "Nurse"  3 "Doctor" )                      ///
      pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) size(small))       ///
    yscale(titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)              ///
    ylabel(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%"  1 "100%", labsize(small))             ///
    ytitle("Share outperformed median Kenyan nurse {&rarr}", size(small)) allcategories  note("")  
    
    graph save "${git}/temp/f-cadre_2.gph", replace 
    
  grc1leg ///
    "${git}/temp/f-cadre_1.gph" ///
    "${git}/temp/f-cadre_2.gph" ///
  , graphregion(color(white)) legendfrom("${git}/temp/f-cadre_2.gph") pos(12)
      
    graph export "${git}/outputs/f-cadre.png", replace width(2000) 
  
  
// Figure. Quantile distributions by education
use "${git}/data/knowledge.dta", clear

  bys country: egen med = median(theta_mle)
  
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1
    replace med = 10 if total == 1  
    
  // Kenya Diploma Reference 
  summarize theta_mle if country == "Kenya" & provider_mededuc1 == 3, d
    local ken_med  = `r(p50)' 
    gen prov_kenya  = (theta_mle >= `ken_med')
  
  graph box theta_mle ///
  , over(provider_mededuc1, sort(provider_mededuc1) axis(noli) label(nolabel))                       ///
    over(country, sort(med) descending axis(noli) label(labsize(small)))                       ///
    noout cwhi line(lw(vthin) lc(black)) al(0) medtype(cline) medline(lc(red) lw(thick)) ///
    box(1, lwidth(0.4) fcolor(none) lcolor(black*0.4))                             ///
    box(2, lwidth(0.4) fcolor(none) lcolor(black*0.7))                                 ///
    box(3, lwidth(0.4) fcolor(none) lcolor(black*1.0))                                 ///
    graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid)   ///
    legend(order(3 "Para-Professional" 2 "Nurse"  1 "Doctor" )                ///
      pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) symx(4) symy(2) size(small))     ///
    yscale(range(-3 3) titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)        ///
    ylabel(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3" , labsize(small))               ///
    yline(`ken_med', lwidth(thin) lcolor(black) lpattern(solid))                       ///
    ytitle("Vignette knowledge score {&rarr}", size(small)) allcategories  note("")  
    
    graph save "${git}/temp/f-education_1.gph", replace 
    
  graph bar prov_kenya,                                           ///
    over(provider_mededuc1, axis(noli) label(nolabel))                       ///
    over(country, sort(med) descending axis(noli) label(labsize(small)))                     ///
    bar(1, lc(none) fcolor(black*0.4))                                   ///
    bar(2, lc(none) fcolor(black*0.7))                                   ///
    bar(3, lc(none) fcolor(black*1.0))                                   ///
    bargap(20) yline(.5 , lwidth(thin) lcolor(black) lpattern(solid)) ///
    graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid)   ///
    legend(on order(1 "Certificate" 2 "Diploma"  3 "Advanced" )                      ///
      pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) size(small))       ///
    yscale(titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)              ///
    ylabel(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%"  1 "100%", labsize(small))             ///
    ytitle("Share outperformed median Kenyan diploma {&rarr}", size(small)) allcategories  note("")  
    
    graph save "${git}/temp/f-education_2.gph", replace 
    
  grc1leg ///
    "${git}/temp/f-education_1.gph" ///
    "${git}/temp/f-education_2.gph" ///
  , graphregion(color(white)) legendfrom("${git}/temp/f-education_2.gph") pos(12)
      
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
  addplot((fpfit theta_mle provider_age1, lc(red) lw(thick) yaxis(2)) ///
    (fpfit upq provider_age1, lc(red) yaxis(2) ) ///
    (fpfit loq provider_age1, lc(red) yaxis(2))) ///
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
  addplot((fpfit percent_correctt provider_age1, lc(red) lw(thick)) ///
    (fpfit upq provider_age1, lc(red) ) ///
    (fpfit loq provider_age1, lc(red) )) ///
  legend(r(1) region(lw(none)) pos(12) order(1 "Age"  2 "Treatment Mean" 3 "25th / 75th Percentiles") size(small))
  
  graph export "${git}/outputs/f-age-treatment.png", replace width(2000)   
    
*************************** End of do-file *****************************************
