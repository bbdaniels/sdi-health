// Inpatients

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_inpatient == . | hf_staff == 0
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type ///
      , by(country hf_id) vallab(hf_type)
      
      replace hf_inpatient = hf_inpatient/90
      replace hf_outpatient = hf_outpatient/90
      
      replace hf_inpatient = 1 if hf_inpatient < 1
      replace hf_outpatient = 1 if hf_outpatient < 1
      
      replace hf_outpatient = 1000 if hf_outpatient > 1000
      replace hf_inpatient = 1000 if hf_inpatient > 1000 & !missing(hf_inpatient)

  tw ///
   (scatter hf_inpatient hf_outpatient [pweight= hf_staff] ///
     if hf_inpatient >= 1 & hf_outpatient >= 1 , m(Oh) mlc(black%50) mlw(thin)) ///
   , ysize(6) subtitle(,bc(none)) by(country , ///
       rescale ixaxes iyaxes legend(off) note(" ") c(2) scale(0.7) subtitle(,bc(none))) ///
     xtit("Outpatients per Day") ytit("Inpatients per Day") ///
     xscale(log) yscale(log) xlab(1 "0-1" 10 100 1000 "1000+") ylab(1 "0-1" 10 100 1000 "1000+")
     
     graph export "${git}/output/caseload.png" , width(3000) replace

// Overall descriptives

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type ///
      , by(country hf_id) vallab(hf_type)
      
  foreach var of varlist ///
    hf_inpatient hf_outpatient hf_staff hf_absent hf_staff_op irt {
      
    local label : var label `var'
  
    graph hbox `var' ///
      , over(hf_type , axis(noline)) note(" ") scale(0.7) ///
        noout nodraw ytit("") title("`label'", pos(11) span) ///
        box(1 , fc(none) lc(black))
        
        graph save "${git}/temp/`var'.gph" , replace
        local graphs `" `graphs' "${git}/temp/`var'.gph" "'
    
  }
  
  graph combine `graphs' , colf
  graph export "${git}/output/descriptives.png" , width(3000) replace
    
// Outpatients per provider quality
use "${git}/data/capacity.dta", clear

  collapse (mean) irt hf_outpatient hf_staff_op hf_type, by(country hf_id) fast
  
  gen hf_outpatient_day = hf_outpatient/(90*hf_staff_op)
  expand hf_staff_op
  
  drop if hf_outpatient == . | hf_outpatient == 0
  replace hf_outpatient_day = 1 if hf_outpatient_day < 1
  drop if hf_outpatient_day > 95
  gen irt2 =  irt
      replace irt2 = 1.113 if irt2 > 1.113
      replace irt2 = -1.243 if irt2 < -1.243
      
      xtile c = irt , n(10)
      
  tw ///
    (scatter hf_outpatient_day c , m(.) mc(black%10) msize(tiny) mlc(none) jitter(1)) ///
    (lowess hf_outpatient_day c , lc(red) lw(thick)) ///
  , by(country , norescale ixaxes r(2) legend(off) note(" ") )  ///
    subtitle(,bc(none)) yscale(log noline) ///
    ylab(1 "0-1" 3.2 "Median" 10 100 "100+") ytit("Outpatients per Day") ///
    xlab(1 10) xtit("Competence Decile") ///
    yline(3.2, lc(black)) xline(5.5 , lc(black))
    
        graph export "${git}/output/capacity-quality-new.png" , width(3000) replace


  tw ///
    (scatter irt2 hf_outpatient_day , mc(gray)  m(.) msize(vtiny)) ///
    (lowess irt hf_outpatient_day , lc(red) lw(thick)) ///
    , by(country, rescale ixaxes iyaxes legend(off) note(" ") c(2))  ///
      xtit("Daily Provider Outpatients") ytit("Provider Competence") ///
      xscale(log noline) xlab(1 "0-1" 10 100 "100+") ///
      yline(0 , lc(black) lw(thin)) ylab(0 "Mean" 1.113 "{&uarr}10%" -1.243 "{&darr}10%") ///
      yscale(noline) subtitle(,bc(none)) ysize(6)
      
    graph export "${git}/output/capacity-quality.png" , width(3000) replace
      
// Outpatients per provider day
use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0

  gen hf_outpatient_day = hf_outpatient/(90*hf_staff_op)
  
  binscatter hf_outpatient_day hf_staff_op ///
    , by(hf_type) line(qfit) n(4) colors(black black%60 black%40 red red%60 red%40 ) ///
      m(T O D T O D) ///
      xlab(1 5 10 15) ylab(0 2 4 6 8 10) ///
      xtit("Staff Serving Outpatients") ytit("Daily Outpatients per Staff") ///
      legend(on pos(12) c(4) size(small) ///
        order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
        0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))
        
    graph export "${git}/output/capacity-staff.png" , width(3000) replace

// End      
