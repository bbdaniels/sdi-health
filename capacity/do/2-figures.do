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
    
    lab var irt "Mean Provider Knowledge"
    
  replace hf_inpatient = . if hf_level == 1
    
    recode hf_level (2=3)(3=2)
    local hf_absent `"xlab(0 "0%" .5 "50%" 1 "100%")"'
          
  foreach var of varlist ///
    hf_inpatient hf_outpatient hf_staff hf_absent hf_staff_op irt {
      
    local label : var label `var'
  
    winsor `var' , gen(`var'2) p(0.01)
    vioplot `var'2 , over(hf_type) nofill hor ylab(,angle(0)) nodraw ///
      title("`label'", pos(11) span) scale(0.7) ///
      den(lw(none) fc(black) fi(70)) bar(fc(white) lw(none)) ///
      line(lw(none)) med(m(|) mc(white) msize(large)) ``var''

      graph save "${git}/temp/`var'.gph" , replace
      local graphs `" `graphs' "${git}/temp/`var'.gph" "'
  }
  
  graph combine `graphs' , colf  ysize(5)
  graph export "${git}/output/f-descriptives.png" , width(3000) replace
  
// Figure. Facility caseloads and staff, by country

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_inpatient == . | hf_staff == 0 | hf_staff_op == 0
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type hf_rural ///
      , by(country hf_id) vallab(hf_type)
      
      replace hf_inpatient = hf_inpatient/90
      replace hf_outpatient = hf_outpatient/90
      
      replace hf_inpatient = 1 if hf_inpatient < 1
      replace hf_outpatient = 1 if hf_outpatient < 1
      
      replace hf_outpatient = 100 if hf_outpatient > 100
      replace hf_inpatient = 1000 if hf_inpatient > 1000 & !missing(hf_inpatient)
      
      replace hf_staff_op = 10 if hf_staff_op > 10
      
  tw ///
    (scatter  hf_staff_op hf_outpatient if hf_rural == 0, jitter(2) m(.) mc(red%40) mlw(none)) ///
    (scatter  hf_staff_op hf_outpatient if hf_rural == 1, jitter(2) m(Oh) mc(black%40) mlw(none)) ///
  , by(country  , r(2) note(" ") iyaxes ixaxes legend(pos(12))) ///
    xtit("Total Outpatients per Day") ytit("Outpatient Staff") ///
    ylab(0.5 " " 1(1)9 10 "10+" , tlength(0) labgap(2)) yscale( noline) ///
    xscale(log) xlab(1 "0-1" 10 100  "100+") xoverhang ///
    legend(order(1 "Urban" 2 "Rural") pos(12) symysize(*5) symxsize(*5))  subtitle(, nobox)
     
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
