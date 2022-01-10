cap prog drop optimizer
prog def optimizer
qui {
  tempfile now

  // Calculate sectoral shares
  use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force
    drop if hf_type == . | hf_outpatient == 0
    
    gen hf_outpatient_day = hf_outpatient/(90)
    gen hf_inpatient_day = hf_inpatient/(90)

    collapse (mean) hf_outpatient_day hf_inpatient_day hf_staff_op ///
             (rawsum) n = hf_outpatient ///
      , by(country hf_type) fast
      
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
      
    // Randomly resort
    bys country hf_type : gen n = _n
    preserve
      keep country hf_type irt
      gen r = rnormal()
      sort country hf_type r
      bys country hf_type : gen n = _n
      tempfile rand
      save `rand' , replace
    restore
    
    // Get current quality levels
    preserve
      drop irt
      merge 1:1 country hf_type n using `rand' , nogen
      collapse (mean) irt  ///
        [aweight=hf_outpatient_day], by(country hf_type) fast
      merge 1:1 country hf_type using `now' , keep(3) nogen
      save `now' , replace
    restore
    
  // Calculate new capacity per day at each provider based on resorting
    gen cap = hf_outpatient/(90*hf_staff_op)
    
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
      
      collapse (mean) irt_new = irt (rawsum) n2 = cap ///
        [aweight=cap], by(country hf_type) fast
      
        merge 1:1 country hf_type using `now' , nogen
        
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
        
        reshape long irt , i(country hf_type) j(irtx)
        
        predict c
        egen group = group(country hf_type)
        tsset group irtx
        gen d2 = d.c
        keep if d2 != .
        
     
      collapse (mean) d2 [pweight=n] , by(country) fast
       
        lab var d2 "Difference"
}
end

clear
  tempfile results
  save `results', emptyok

forv i = 1/100 {
  optimizer
  append using `results'
  save `results' , replace
}

preserve
  gen check = 1
  replace d2 = d2*100
  ren d2 effect_size
  collapse (mean) effect_size check ///
    (p95) _meta_ciu = effect_size ///
    (p5) _meta_cil = effect_size ///
    , by(country)
    
    gen std_err = (_meta_ciu - _meta_cil) / 4 
  
  append using "${git}/data/comparison.dta"
  merge m:1 country check ///
    using "${git}/temp/optimize-comparison.dta" ///
    , keepusing(effect_size) update
  
  ta effect_size check  , m
  
  meta set effect_size std_err
  
  meta funnelplot if check != 1 & std_err < 30 ///
  , addplot(scatter std_err effect_size  if check == 1 ///
      , m(o) mc(red%50) mlc(black) mlw(vthin) msize(large)) ///
    mc(white) msize(small) mlc(black) mlw(vthin) random contours(1 5 10 , upper) ///
    esop(ls(none))  yscale(noline) xscale(noline) title(" ") ///
    ylab(0 5 10 15 20) ///
    ytit("Standard Error") xtit("Effect Size (Percentage Points) and Significance Level (NS, 0.1, 0.05, 0.01)")
  
    graph export "${git}/output/f-optimize-meta.png" , width(3000) replace
 
// End
