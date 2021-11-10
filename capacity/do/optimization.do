// Approach 1: Resorting current capacities
use "${git}/data/capacity.dta", clear

  drop if hf_type == .

  labelcollapse (mean) irt hf_outpatient hf_staff_op hf_type ///
    , by(country hf_id) vallab(hf_type)
    
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
  
  // Calculate new capacity per day at each facility based on resort
  gen cap = hf_outpatient/(90*hf_staff_op)
  expand hf_staff_op
  
    sort country hf_type hf_id
    
    preserve
    gsort country hf_type -irt
      keep country hf_type irt cap
      ren cap hf_outpatient_day
      gen serial = _n
      tempfile irt
      save `irt' , replace
    restore
    
    gsort country hf_type -cap 
      ren irt irt_old
      keep country hf_type cap irt_old
      gen serial = _n

      merge 1:1 country hf_type serial using `irt' , nogen
      
      /* Outlier checks      
        gen c_o = hf_outpatient_day
        gen c_n = cap
        tw ///
          (rspike c_o c_n irt if c_n > c_o, lc(black) lw(thin) ) ///
          (rspike c_o c_n irt if c_n <= c_o, lc(red) lw(thin) ) ///
        , by(country , rescale ixaxes iyaxes c(2)) ysize(6)
      */
      
      collapse (mean) irt_new = irt (rawsum) n2 = cap ///
        [aweight=cap], by(country hf_type) 
      
      merge 1:1 country hf_type using `now' , nogen
  
      bys country: egen temp = sum(n)
      replace n = n/temp
         
    // Graphics
    local style msize(small)
    tw ///
      (pcarrow irt n irt_new n if hf_type == 1 , `style' mang(30) lc(black) mc(black)) ///
      (pcarrow irt n irt_new n if hf_type == 2 , `style' mang(60) lc(black) mc(black)) ///
      (pcarrow irt n irt_new n if hf_type == 3 , `style' mang(90) lc(black) mc(black)) ///
      (pcarrow irt n irt_new n if hf_type == 4 , `style' mang(30) lc(gray) mc(gray)) ///
      (pcarrow irt n irt_new n if hf_type == 5 , `style' mang(60) lc(gray) mc(gray)) ///
      (pcarrow irt n irt_new n if hf_type == 6 , `style' mang(90) lc(gray) mc(gray)) ///
    , by(country , c(2) rescale ixaxes note(" ")  ///
         legend(ring(0) pos(12))) subtitle(,bc(none)) ysize(6) ///
      xtit("National Share of Outpatients") ytit("Average Provider Competence") ///
      xlab(0 "0%" .25 "25%" .5 "50%") xscale(noline) ///
      yline(0 , lc(black) lw(thin)) ylab(0 "Mean" 1.113 "{&uarr}10%" -1.243 "{&darr}10%") yscale(noline) ///
      legend(size(small) symxsize(small) c(4) ///
        order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
              0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))
              
      graph export "${git}/output/optimize-providers.png" , width(3000) replace
      
    // Results table
      ren irt_new irt_sim_a
      save "${git}/temp/sim-results.dta" , replace

// Approach 2: Adjusted capacity constraint
use "${git}/data/capacity.dta", clear

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
      
      /*
      gen c_o = hf_outpatient_day
      gen c_n = cap
      tw ///
        (rspike c_o c_n irt if c_n > c_o, lc(black) lw(thin) ) ///
        (rspike c_o c_n irt if c_n <= c_o, lc(red) lw(thin) ) ///
      , by(country , rescale ixaxes iyaxes c(2)) ysize(6)
      */
      
      

    collapse (mean) irt_new = irt (rawsum) n2 = cap ///
      [aweight=cap], by(country hf_type) 
      
      merge 1:1 country hf_type using `now' , nogen
      
      bys country: egen temp = sum(n)
      replace n = n/temp
         
    // Graphics
    local style msize(small)
    tw ///
      (pcarrow irt n irt_new n if hf_type == 1 , `style' mang(30) lc(black) mc(black)) ///
      (pcarrow irt n irt_new n if hf_type == 2 , `style' mang(60) lc(black) mc(black)) ///
      (pcarrow irt n irt_new n if hf_type == 3 , `style' mang(90) lc(black) mc(black)) ///
      (pcarrow irt n irt_new n if hf_type == 4 , `style' mang(30) lc(gray) mc(gray)) ///
      (pcarrow irt n irt_new n if hf_type == 5 , `style' mang(60) lc(gray) mc(gray)) ///
      (pcarrow irt n irt_new n if hf_type == 6 , `style' mang(90) lc(gray) mc(gray)) ///
    , by(country , rescale ixaxes note(" ")  ///
         legend(ring(0) pos(12)) c(2)) subtitle(,bc(none)) ysize(6) ///
      xtit("National Share of Outpatients") ytit("Average Provider Competence") ///
      xlab(0 "0%" .25 "25%" .5 "50%") xscale(noline) ///
      yline(0 , lc(black) lw(thin)) ylab(0 "Mean" 1.113 "{&uarr}10%" -1.243 "{&darr}10%") yscale(noline) ///
      legend(size(small) symxsize(small) c(4) ///
        order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
              0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))

      graph export "${git}/output/optimize-capacity.png" , width(3000) replace
      
   // Results table
  ren irt_new irt_sim_b
  merge 1:1 country hf_type using "${git}/temp/sim-results.dta"
     
      gen da = irt_sim_a - irt
      gen db = irt_sim_b - irt
     
      lab var n "Share"
      lab var irt "Knowledge"
      lab var irt_sim_a "Simulation A"
      lab var irt_sim_b "Simulation B"
      lab var da "Difference"
      lab var db "Difference"
     
     export excel ///
       country hf_type n irt irt_sim_a da irt_sim_b db ///
       using "${git}/output/optimize-capacity.xlsx" ///
     , replace first(varl)
     
     
     save "${git}/temp/sim-results.dta" , replace
       
// Quality table
use "${git}/data/capacity.dta", clear

egen c = rowmean(treat?)

reg c c.irt##i.country 

use "${git}/temp/sim-results.dta" , clear
  ren (irt irt_sim_a irt_sim_b) (irt1 irt2 irt3)
  
  reshape long irt , i(country hf_type) j(irtx)
  
  predict c
  drop _merge
  
  reshape wide irt c, i(country hf_type) j(irtx)

collapse (mean) irt1 c1 irt2 c2 irt3 c3 [pweight=n] , by(country)
  lab var irt1 "Knowledge"
  lab var irt2 "Simulation A"
  lab var irt3 "Simulation B"
  
  lab var c1 "Quality"
  lab var c2 "Simulation A"
  lab var c3 "Simulation B"
  
       export excel ///
         country irt1 c1 irt2 c2 irt3 c3 ///
         using "${git}/output/optimize-quality.xlsx" ///
       , replace first(varl)
    
//
