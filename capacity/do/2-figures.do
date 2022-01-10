// Figures for paper

// Figure. Descriptive statistics for facilities by sector

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type hf_level ///
      , by(country hf_id) vallab(hf_type)
      
  replace hf_inpatient = hf_inpatient/90
    lab var hf_inpatient "Daily Inpatients"
  replace hf_outpatient = hf_outpatient/90
    lab var hf_outpatient "Daily Outpatients"
    
  replace hf_inpatient = . if hf_level == 1
    
    recode hf_level (2=3)(3=2)
          
  foreach var of varlist ///
    hf_inpatient hf_outpatient hf_staff hf_absent hf_staff_op irt {
      
    local label : var label `var'
  
    graph hbox `var' ///
      , by(hf_level , ixaxes rescale  imargin(zero) c(1) ///
          title("`label'", pos(11) span) note(" ")) subtitle(" ", ring(0)) ///
        over(hf_type ,  axis(noline) ) nofill note(" ") scale(0.7) subtitle(,bc(none)) ///
        noout  nodraw ytit("") medtype(cline) medline(lc(red) lw(thick)) /// 
        box(1 , fc(none) lc(black)) yscale(noline)
        
        graph save "${git}/temp/`var'.gph" , replace
    
  }
  
  foreach var of varlist ///
    hf_inpatient hf_outpatient hf_staff hf_absent hf_staff_op irt {
      local graphs `" `graphs' "${git}/temp/`var'.gph" "'
  }
  
  graph combine `graphs' , colf altshrink ysize(5)
  graph export "${git}/output/f-descriptives.png" , width(3000) replace
  
  
// Figure. Facility caseloads and staff, by country

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_inpatient == . | hf_staff == 0
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type hf_rural ///
      , by(country hf_id) vallab(hf_type)
      
      replace hf_inpatient = hf_inpatient/90
      replace hf_outpatient = hf_outpatient/90
      
      replace hf_inpatient = 1 if hf_inpatient < 1
      replace hf_outpatient = 1 if hf_outpatient < 1
      
      replace hf_outpatient = 1000 if hf_outpatient > 1000
      replace hf_inpatient = 1000 if hf_inpatient > 1000 & !missing(hf_inpatient)

  tw ///
   (scatter hf_inpatient hf_outpatient [pweight= hf_staff] ///
     if hf_inpatient >= 1 & hf_outpatient >= 1 & hf_rural == 0 ///
     , m(Oh) mlc(red) mlw(thin)) ///
   (scatter hf_inpatient hf_outpatient [pweight= hf_staff] ///
     if hf_inpatient >= 1 & hf_outpatient >= 1 & hf_rural == 1 ///
     , m(Oh) mlc(black) mlw(thin)) ///
   , ysize(6) subtitle(,bc(none)) by(country , ///
       rescale ixaxes iyaxes legend(on) note(" ") c(2) scale(0.7) subtitle(,bc(none))) ///
     xtit("Outpatients per Day") ytit("Inpatients per Day") ///
     xscale(log) yscale(log) xlab(1 "0-1" 10 100 1000 "1000+") ylab(1 "0-1" 10 100 1000 "1000+") ///
     legend(order(1 "Urban" 2 "Rural") symysize(*5) symxsize(*5))
     
     graph export "${git}/output/f-caseload.png" , width(3000) replace

// Figure. Daily caseload per provider, by facility sector and size
use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0

  gen hf_outpatient_day = hf_outpatient/(90*hf_staff_op)
  
  binscatter hf_outpatient_day hf_staff_op ///
    , by(hf_type) line(qfit) n(4) colors(black black%60 black%40 red red%60 red%40 ) ///
      m(T O D T O D)  ///
      xlab(1 5 10 15) ylab(0 2 4 6 8 10) ///
      xtit("Staff Serving Outpatients") ytit("Daily Outpatients per Staff") ///
      legend(on pos(12) c(4) size(small) ///
        order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
        0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))
        
    graph export "${git}/output/f-capacity-staff.png" , width(3000) replace
    
// Setup: Current comparator for optimization
use "${git}/data/capacity.dta", clear

  gen hf_outpatient_day = hf_outpatient/(90*hf_staff_op)
  
  drop if missing(hf_outpatient) | hf_outpatient == 0
  replace hf_outpatient_day = 1 if hf_outpatient_day < 1
  replace hf_outpatient_day = 100 if hf_outpatient_day > 100
      
  xtile c = irt , n(10)
      
  tw ///
    (mband hf_outpatient_day c , lc(red) lw(vthick)) ///
    (scatter hf_outpatient_day c , m(.) mc(black%10) msize(tiny) mlc(none) jitter(1)) ///
  , by(country , norescale ixaxes r(2) legend(off) note(" ") )  ///
    subtitle(,bc(none)) yscale(log noline) xscale(noline) ///
    ylab(1 "0-1" 3.2 "Median" 10 100 "100+", tl(0)) ytit("Outpatients per Day") ///
    xlab(1 10, tl(0)) xtit("Competence Decile") ///
    yline(3.2, lc(black)) xline(5.5 , lc(black))
    
    graph export "${git}/output/f-optimization-1.png" , width(3000) replace
      
// End      
