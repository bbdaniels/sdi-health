// Outpatients per provider quality
use "${git}/data/capacity.dta", clear

  collapse (mean) irt hf_outpatient hf_staff hf_type, by(country hf_id) fast
  
  xtile q = irt , nq(5)

  gen hf_outpatient_day = hf_outpatient/(90*hf_staff)

  tw ///
    (scatter hf_outpatient_day irt, mc(black)  m(.) msize(vtiny)) ///
    (lpoly hf_outpatient_day irt, lc(black) lw(thin)) ///
    if hf_outpatient_day > 0.033 ///
    , by(country, ixaxes iyaxes legend(off) note(" "))  ///
      yscale(log) ytit("Daily Outpatients") ///
      /// xscale(log) xtit("Staff Serving Outpatients") ///
      ylab(0.14 "1/week" 1 "1/day" 10 "10/day" 100 1000)
      
      
  levelsof country , local(c)
  local x = 1
  foreach country in `c' {
    local ++x
    local graphs = `"`graphs'"' ///
      +  `"(lfit hf_outpatient_day irt if country == `country') "'
    local legend `"`legend' `x' "`: label (country) `country''" "'
  }
  
  tw ///
    (scatter hf_outpatient_day irt , mc(black) m(.) msize(vtiny)) ///
    `graphs' ///
    if hf_outpatient_day > 0.033 ///
  , yscale(log) legend(on order(`legend') pos(3) c(1) symxsize(small) size(small)) ///
    ylab(0.14 "1/week" 1 "1/day" 10 "10/day" 100 1000) ///
    ytit("Outpatients per Provider Day") ///
    xtit("Average Facility Provider Competence")
      
// Outpatients per provider day
use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force

  gen hf_outpatient_day = hf_outpatient/(90*hf_staff)

  gen logm = log(hf_outpatient_day)
  gen logk = log(hf_staff)
  regress logm logk
  predict raw
  gen exp = exp(raw)

  tw ///
    (scatter hf_outpatient_day hf_staff, mc(black) jitter(1) m(.) msize(vtiny)) ///
    (line exp hf_staff, lc(black) lw(thin)) ///
    if hf_outpatient_day > 0.033 ///
    , by(hf_type, ixaxes iyaxes legend(off) note(" "))  ///
      yscale(log) ytit("Daily Outpatients") ///
      xscale(log) xtit("Staff Serving Outpatients") ///
      ylab(0.14 "1/week" 1 "1/day" 10 "10/day" 100 1000) xlab(1 10 100 1000)

// Outpatients and staffing
use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force

  gen hf_outpatient_day = hf_outpatient/90

  gen logm = log(hf_outpatient_day)
  gen logk = log(hf_staff)
  regress logm logk
  predict raw
  gen exp = exp(raw)

  tw ///
    (scatter hf_outpatient_day hf_staff, mc(black) jitter(1) m(.) msize(vtiny)) ///
    (line exp hf_staff, lc(black) lw(thin)) ///
    if hf_outpatient_day > 0.14 ///
    , by(hf_type, ixaxes iyaxes legend(off) note(" "))  ///
      yscale(log) ytit("Daily Outpatients") ///
      xscale(log) xtit("Staff Serving Outpatients") ///
      ylab(0.14 "1/week" 1 "1/day" 10 "10/day" 100 1000) xlab(1 10 100 1000)
      
