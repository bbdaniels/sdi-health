tempfile now

// Calculate sectoral shares
use "${git}/data/capacity.dta", clear

duplicates drop country hf_id , force
  drop if hf_type == . | hf_outpatient == 0
  
  gen hf_outpatient_day = hf_outpatient/(90)
  gen hf_inpatient_day = hf_inpatient/(90)

  collapse (mean) hf_outpatient_day hf_inpatient_day hf_staff_op ///
           (rawsum) n = hf_outpatient ///
    , by(country hf_type) 
    
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
    collapse (mean) irt (rawsum) hf_outpatient_day ///
      [aweight=hf_outpatient_day], by(country hf_type) 
    merge 1:1 country hf_type using `now' , keep(3) nogen
    collapse (mean) irt  ///
      [aweight=hf_outpatient_day], by(country) 
    save `now' , replace
  restore
  
// Calculate current quality    
use "${git}/data/capacity.dta", clear

  drop if hf_type == . | hf_outpatient == 0
   
  // Calculate outpatients per provider day at each facility
  gen hf_outpatient_day = hf_outpatient/(90)
    drop if hf_outpatient_day == 0 | hf_outpatient_day == .
    lab var hf_outpatient_day "Outpatients Per Day"
  
  // Get current quality levels
  preserve
    collapse (mean) irt_all = irt  ///
      [aweight=hf_outpatient_day], by(country) 
    merge 1:1 country using `now' , keep(3) nogen
    save `now' , replace
  restore
  
  use `now' , clear
  
  
