

// Figure. Descriptive statistics for facilities by sector

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
    gen hf_outpatient_day = hf_outpatient/60
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type hf_level ///
      , by(country hf_id) vallab(hf_type)
      
  replace hf_outpatient = hf_outpatient/(60)
    lab var hf_outpatient "Daily Outpatients"
  gen hf_outpatient_staff = hf_outpatient/hf_staff_op
    lab var hf_outpatient_staff "Daily Outpatients per Staff"
    
    lab var irt "Mean Provider Knowledge"
      
  bys country hf_type: gen weight = 1/_N
  replace hf_outpatient = 200 if hf_outpatient > 200
  graph box hf_outpatient [pweight=weight] ///
  , over(hf_type , axis(noline) sort(1)) ///
    hor ylab(,angle(0)) box(1 , lc(black) lw(thin)) ///
    marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
    ytit(" ") inten(0) cwhi lines(lw(thin) lc(black)) note(" ") title("Per Facility")

  graph export "${git}/output/af-descriptives.png" , width(3000) replace
  
  
// End
