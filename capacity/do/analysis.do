//

// Resampling -- first attempt, no capacity constraint
use "$EL_dtFin/Vignettes_pl.dta", clear

  drop if hf_type == .

  labelcollapse (mean) irt hf_outpatient hf_staff_op hf_type ///
    , by(country hf_id) vallab(hf_type)
    
    drop if hf_outpatient == 0 | hf_outpatient == .
    
    // Calculate outpatients per provider day at each facility
    gen hf_outpatient_day = hf_outpatient/(90)
      drop if hf_outpatient_day == 0 | hf_outpatient_day == .
      lab var hf_outpatient_day "Outpatients Per Day"
    
    // Get current quality levels
    preserve
      collapse (mean) irt (rawsum) n = hf_outpatient_day ///
        [aweight=hf_outpatient], by(country hf_type) 
      tempfile now
      save `now' , replace
    restore
      
  // Calculate capacity per day at each facility based on country
  gen cap = hf_outpatient/(90*hf_staff_op)
  egen set = group(country hf_type)
    levelsof set, local(sets)
    qui foreach s in `sets' {
      su cap if set == `s', d
      replace cap = `r(p95)' if set == `s'
    }
    replace cap = cap * hf_staff_op
    lab var cap "Facility Capacity"
    
  // Selector dataset
  gsort country hf_type -irt
    bys country hf_type: egen total = sum(hf_outpatient_day)
    bys country hf_type:  gen cumul = sum(cap)
    gen touse = cumul < total
    
    
    bys country hf_type: gen s = _n
    xtset set s
      gen temp = L1.touse
      replace touse = 1 if (temp == . | temp == 1)
      drop temp

      gen temp = L1.cumul
        replace temp = 0 if temp == .
      gen temp2 = F1.touse
      replace cap = total-temp if (temp2 == . | temp2 == 0)
      
      replace cap = 0 if touse == 0

    collapse (mean) irt_new = irt (rawsum) n2 = cap ///
      [aweight=cap], by(country hf_type) 
      
      merge 1:1 country hf_type using `now' , nogen
      
      bys country: egen temp = sum(n)
      replace n = n/temp
         
    // Graphics
    local style msize(small)
    tw ///
      (pcarrow irt n irt_new n if hf_type == 1 , `style' mang(30) lc(maroon) mc(maroon)) ///
      (pcarrow irt n irt_new n if hf_type == 2 , `style' mang(60) lc(maroon) mc(maroon)) ///
      (pcarrow irt n irt_new n if hf_type == 3 , `style' mang(90) lc(maroon) mc(maroon)) ///
      (pcarrow irt n irt_new n if hf_type == 4 , `style' mang(30) lc(navy) mc(navy)) ///
      (pcarrow irt n irt_new n if hf_type == 5 , `style' mang(60) lc(navy) mc(navy)) ///
      (pcarrow irt n irt_new n if hf_type == 6 , `style' mang(90) lc(navy) mc(navy)) ///
    , by(country , rescale ixaxes note(" ")  ///
         legend(ring(0) pos(12))) ///
      xtit("National Share of Outpatients") ytit("Average Provider Competence") ///
      xlab(0 "0%" .25 "25%" .5 "50%") xscale(noline) ///
      yline(0 , lc(black) lw(thin)) ylab(0 "Mean" 1.113 "Top 10%" -1.243 "Bottom 10%") yscale(noline) ///
      legend(size(small) c(4) ///
        order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
              0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))
      
    -
      
  



-
// Outpatients per provider quality
use "$EL_dtFin/Vignettes_pl.dta", clear

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
use "$EL_dtFin/Vignettes_pl.dta", clear

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
use "$EL_dtFin/Vignettes_pl.dta", clear

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
      
    
//
