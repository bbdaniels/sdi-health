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

  tw ///
    (scatter irt2 hf_outpatient_day , mc(gray)  m(.) msize(vtiny)) ///
    (lowess irt hf_outpatient_day , lc(red) lw(medthick)) ///
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

  gen logm = log(hf_outpatient_day)
  gen logk = log(hf_staff_op)
  regress logm c.logk##i.hf_type
  predict raw
  gen exp = exp(raw)
  
    replace hf_outpatient_day = 1 if hf_outpatient_day < 1
    replace hf_outpatient_day = 100 if hf_outpatient_day > 100

  tw ///
    (scatter hf_outpatient_day hf_staff_op, mc(black) jitter(1) m(.) msize(vtiny)) ///
    (lpoly hf_outpatient_day hf_staff_op, lc(red) lw(thin)) ///
    (line exp hf_staff_op, lc(black) lw(thin)) ///
    , by(hf_type, ixaxes iyaxes legend(on) note(" "))  ///
      yscale(log) ytit("Daily Outpatients per Staff") ///
      xscale(log) xtit("Staff Serving Outpatients") ///
      ylab(1 "0-1" 10 100 "100+") xlab(1 10 100) subtitle(,bc(none)) ///
      legend(order(2 "Linear" 3 "Exponential"))
      
      graph export "${git}/output/capacity-staff.png" , width(3000) replace

// Outpatients and staffing
use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  
  gen hf_outpatient_day = hf_outpatient/90

  gen logm = log(hf_outpatient_day)
  gen logk = log(hf_staff_op)
  regress logm c.logk##i.hf_type
  predict raw
  gen exp = exp(raw)
  
      replace hf_outpatient_day = 1 if hf_outpatient_day < 1
      replace hf_outpatient_day = 100 if hf_outpatient_day > 100

  tw ///
    (scatter hf_outpatient_day hf_staff_op, mc(black) jitter(1) m(.) msize(vtiny)) ///
    (lpoly hf_outpatient_day hf_staff_op, lc(red) lw(thin)) ///
    (line exp hf_staff_op, lc(black) lw(thin)) ///
    , by(hf_type, ixaxes iyaxes legend(on) note(" "))  ///
      yscale(log) ytit("Daily Outpatients at Facility") ///
      xscale(log) xtit("Staff Serving Outpatients") ///
      ylab(1 "0-1" 10 100 "100+") xlab(1 10 100) subtitle(,bc(none)) ///
      legend(order(2 "Linear" 3 "Exponential"))
      
      graph export "${git}/output/capacity-facility.png" , width(3000) replace
      
