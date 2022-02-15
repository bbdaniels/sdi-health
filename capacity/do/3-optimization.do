// Part 1: Resorting current capacities

// Calculate new capacity per day at each provider based on resorting
use "${git}/data/capacity.dta", clear
  drop if hf_type == . | hf_outpatient == 0
  gen cap = hf_outpatient/(90*hf_staff_op)
    drop if cap == .
  
  tempfile irt all
  keep country irt cap hf_type hf_level hf_rural public treat?
  save `all'

qui {
  // Capacity adjustment resort    
  collapse (p90) new=cap (rawsum) n=cap , by(country hf_level)
    merge 1:m country hf_level using `all' , nogen
    gsort country hf_level -irt
    gen tot = n/new
    bys country hf_level : gen cap_bigger = new if _n <= tot
      replace cap_bigger = 0 if cap_bigger == .
      gen irt_bigger = irt
      drop n tot new
      
  // Restricted to type resort
  preserve
  gsort country hf_type -irt
    keep country hf_type irt
    ren irt irt_hftype
    gen ser_hftype = _n
    save `irt' , replace
  restore
  
  gsort country hf_type -cap
    gen cap_hftype = cap
    gen ser_hftype = _n
    merge 1:1 ser_hftype using `irt' , nogen
  
  // Unrestricted resort
  preserve
  gsort country -irt
    keep country irt cap
    ren irt irt_unrest
    gen ser_unrest = _n
    save `irt' , replace
  restore
  
  gsort country -cap
    gen cap_unrest = cap
    gen ser_unrest = _n
    merge 1:1 ser_unrest using `irt' , nogen
    
  // Restricted to level resort
  preserve
  gsort country hf_level -irt
    keep country hf_level irt cap
    ren irt irt_levels
    gen ser_levels = _n
    save `irt' , replace
  restore
  
  gsort country hf_level -cap
    gen cap_levels = cap
    gen ser_levels = _n
    merge 1:1 ser_levels using `irt' , nogen
    
  // Restricted to zone resort
  preserve
  gsort country hf_rural -irt
    keep country hf_rural irt cap
    ren irt irt_rururb
    gen ser_rururb = _n
    save `irt' , replace
  restore
  
  gsort country hf_rural -cap
    gen cap_rururb = cap
    gen ser_rururb = _n
    merge 1:1 ser_rururb using `irt' , nogen
  
  // Restricted to sector resort
  preserve
  gsort country public -irt
    keep country public irt cap
    ren irt irt_public
    gen ser_public = _n
    save `irt' , replace
  restore
  
  gsort country public -cap
    gen cap_public = cap
    gen ser_public = _n
    merge 1:1 ser_public using `irt' , nogen
}
    
// Create comparative statistics

  ren (irt cap) (irt_old cap_old)
    egen c = rowmean(treat?)
    reg c c.irt_old##i.country 

  preserve
    collapse irt_old [aweight=cap_old] , by(country)
      predict c
      ren c irt_xxx
      reshape long irt , i(country) j(x) string
    save `all' , replace
  restore
  
  foreach type in unrest hftype levels rururb public {
    preserve
      collapse irt_`type' [aweight=cap_`type'] , by(country)
        gen irt_old = irt_`type'
        predict c
        ren c irt_xxx
        drop irt_old
        reshape long irt , i(country) j(x) string
        ren irt irt_`type'
        replace x = "_old" if x != "_xxx"
      merge 1:1 country x using `all' , nogen
      save `all' , replace
    restore
  }
  
  use `all' , clear
    egen mean = rowmean(irt_*)
    gen dif = mean - irt
  
  export excel ///
    using "${git}/output/t-optimize-quality.xlsx" ///
  , replace first(var)

**************************************************
// Part 2: Vizualizations for sectoral restriction
**************************************************

tempfile now

// Calculate sectoral shares and current quality
use "${git}/data/capacity.dta", clear

duplicates drop country hf_id , force
  drop if hf_type == . | hf_outpatient == 0
  
  gen hf_outpatient_day = hf_outpatient/(90)
  gen hf_inpatient_day = hf_inpatient/(90)

  collapse (mean) hf_outpatient_day hf_inpatient_day hf_staff_op ///
           (rawsum) n = hf_outpatient ///
    , by(country hf_type) 
    
  bys country: egen temp = sum(n)
  gen share = n/temp
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
      [aweight=hf_outpatient_day], by(country hf_type) 
    merge 1:1 country hf_type using `now' , keep(3) nogen
    save `now' , replace
  restore
      
// Create optimized allocation images
preserve

  // Size histogram
  tw ///
    (histogram hf_outpatient_day , frac yaxis(2) color(gs12) start(0) w(5) gap(10) lsty(none)) ///
    (lowess irt cap , lc(black) lw(thick))(lowess irt_old hf_outpatient_day , lc(black) lp(dash) lw(thick)) ///
    if hf_outpatient_day < 40 & cap < 40 ///
  , by(country , noyrescale xrescale ixaxes r(2) legend(on pos(12)) note(" ") )  ///
    subtitle(,bc(none)) ///
    xscale(noline) ///
    xlab(0 10 20 30 40)  xtit("Outpatients per Day") ///
    ylab(0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%", angle(0) axis(2)) yscale(noline) yscale(noline alt axis(2)) ///
    ylab(-4 "-4 SD" -2 "-2 SD" 0 "Mean" 2 "+2 SD") ///
    ytit("Frequency (Histogram)", axis(2)) ytit("Mean Competence", axis(1)) yscale(alt) ///
    legend(pos(12) r(1) size(small) order(3 "Actual" 2 "Optimal" 1 "Percentage of Providers (Right Axis)"))
           
    graph export "${git}/output/f-optimize-providers.png" , width(3000) replace
              
  // Scatter bands       
  xtile c = irt , n(10)
    replace cap = 1 if cap < 1
    replace cap = 100 if cap > 100

  tw ///
    (mband cap c , lc(red) lw(vthick) ) ///
    (scatter cap c , m(.) mc(black%10) msize(tiny) mlc(none) jitter(1)) ///
  , by(country , norescale ixaxes r(2) legend(off) note(" ") )  ///
    subtitle(,bc(none)) yscale(log noline) xscale(noline) ///
    ylab(1 "0-1" 3.2 "Median" 10 100 "100+" , tl(0)) ytit("Outpatients per Day") ///
    xlab(1 5.5 "Median" 10 , tl(0)) xtit("Competence Decile") ///
    yline(3.2, lc(black)) xline(5.5 , lc(black)) 
    
    graph export "${git}/output/f-optimization-2.png" , width(3000) replace
restore     
      
/* Outlier checks in exact reallocation
  gen c_o = hf_outpatient_day
  gen c_n = cap
  tw ///
    (rspike c_o c_n irt if c_n > c_o, lc(black) lw(thin) ) ///
    (rspike c_o c_n irt if c_n <= c_o, lc(red) lw(thin) ) ///
  , by(country , rescale ixaxes iyaxes c(2)) ysize(6)
*/

// Calculate new quality
collapse (mean) irt_new = irt (rawsum) n2 = cap ///
  [aweight=cap], by(country hf_type) 

  merge 1:1 country hf_type using `now' , nogen
  
// Visualize sectoral changes
         
  local style msize(small)
  tw ///
    (pcarrow irt n irt_new n if hf_type == 1 , `style' mang(30) lc(black) mc(black)) ///
    (pcarrow irt n irt_new n if hf_type == 2 , `style' mang(60) lc(black) mc(black)) ///
    (pcarrow irt n irt_new n if hf_type == 3 , `style' mang(90) lc(black) mc(black)) ///
    (pcarrow irt n irt_new n if hf_type == 4 , `style' mang(30) lc(red) mc(red)) ///
    (pcarrow irt n irt_new n if hf_type == 5 , `style' mang(60) lc(red) mc(red)) ///
    (pcarrow irt n irt_new n if hf_type == 6 , `style' mang(90) lc(red) mc(red)) ///
  , by(country , c(2) rescale ixaxes note(" ")  ///
       legend(ring(0) pos(12))) subtitle(,bc(none)) ysize(6) ///
    xtit("National Share of Outpatients") ytit("Average Provider Competence") ///
    xlab(0 "0%" .25 "25%" .5 "50%") xscale(noline) ///
    yline(0 , lc(black) lw(thin)) ylab(0 "Mean" 1.113 "{&uarr}10%" -1.243 "{&darr}10%") yscale(noline) ///
    legend(size(small) symxsize(small) c(4) ///
      order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
            0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))
            
    graph export "${git}/output/f-optimize-differences.png" , width(3000) replace
      
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
 
  export excel ///
    country hf_type n irt hf_outpatient_day  ///
    hf_inpatient_day hf_staff_op c2  ///
  using "${git}/output/t-optimize-capacity.xlsx" ///
  , replace first(varl)
 
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
  
  reshape wide irt c, i(country hf_type) j(irtx)

collapse (mean) irt1 c1 irt2 c2 [pweight=n] , by(country)
  lab var irt1 "Knowledge"
  lab var irt2 "Optimal"
  
  lab var c1 "Quality"
  lab var c2 "Optimal"
  
  gen d1 = irt2 - irt1
  gen d2 = c2 - c1
  
  lab var d1 "Difference"
  lab var d2 "Difference"
  
  
  
// Save for comparison

  gen check = 1
  ren d2 effect_size
  replace effect_size=effect_size*100
  save "${git}/temp/optimize-comparison.dta" , replace

//
