// Resorting current capacities

tempfile now

// Calculate sectoral shares
use "${git}/data/capacity.dta", clear

duplicates drop country hf_id , force
  drop if hf_type == . | hf_outpatient == 0
  
  gen hf_outpatient_day = hf_outpatient/(90)
  gen hf_inpatient_day = hf_inpatient/(90)

  collapse (mean) hf_outpatient_day hf_inpatient_day hf_staff_op ///
           (rawsum) n = hf_outpatient ///
    , by(country) 
    
  bys country: egen temp = sum(n)
  replace n = n/temp
    drop temp
    
  save `now' , replace

// Calculate current quality    
use "${git}/data/capacity.dta", clear

  drop if hf_type == . | hf_outpatient == 0
   
  // Calculate outpatients per provider day at each facility
  gen hf_outpatient_day = hf_outpatient/(90)
    drop if hf_outpatient_day == 0 | hf_outpatient_day == .
    lab var hf_outpatient_day "Outpatients Per Day"
  
  // Get current quality levels
  preserve
    collapse (mean) irt  ///
      [aweight=hf_outpatient_day], by(country) 
    merge 1:1 country using `now' , keep(3) nogen
    save `now' , replace
  restore
  
// Calculate new capacity per day at each provider based on resorting
  gen cap = hf_outpatient/(90*hf_staff_op)
  
    sort country hf_id
    
    preserve
    gsort country -irt
      keep country irt cap
      ren cap hf_outpatient_day
      gen serial = _n
      tempfile irt
      save `irt' , replace
    restore
    
    gsort country -cap 
      ren irt irt_old
      keep country cap irt_old hf_type
      gen serial = _n

    merge 1:1 country serial using `irt' , nogen
    
// Calculate new quality
collapse (mean) irt_new = irt (rawsum) n2 = cap ///
  [aweight=cap], by(country ) 

  merge 1:1 country using `now' , nogen
      
// Results table: Sectoral

  ren irt_new irt_sim_a
 
  gen da = irt_sim_a - irt
  gen c2 = hf_outpatient_day/hf_staff_op
 
  lab var n "Share"
  lab var irt "Knowledge"
  lab var irt_sim_a "Optimal"
  lab var da "Difference"
  
  lab var hf_outpatient_day "Mean Daily Outpatients" 
  lab var hf_inpatient_day "Mean Daily Inpatients" 
  lab var hf_staff_op "Mean Outpatient Staff" 
  lab var c2 "Mean Outpatients per Staff" 
 
  save "${git}/temp/sim-results.dta" , replace
       
// Results table: National
use "${git}/data/capacity.dta", clear

  // Get regression quality estimate
  egen c = rowmean(treat?)
  reg c c.irt##i.country 

use "${git}/temp/sim-results.dta" , clear
  ren (irt irt_sim_a) (irt1 irt2)
  
  reshape long irt , i(country) j(irtx)
  
  predict c
  
  reshape wide irt c, i(country) j(irtx)

collapse (mean) irt1 c1 irt2 c2 [pweight=n] , by(country)
  lab var irt1 "Knowledge"
  lab var irt2 "Optimal"
  
  lab var c1 "Quality"
  lab var c2 "Optimal"
  
  gen d1 = irt2 - irt1
  gen d2 = c2 - c1
  
  lab var d1 "Difference"
  lab var d2 "Difference"
  
  export excel ///
    country irt1 c1 irt2 c2 d1 d2 ///
    using "${git}/output/t-optimize-unrestricted.xlsx" ///
  , replace first(varl)
