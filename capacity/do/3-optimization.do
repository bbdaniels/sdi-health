**************************************************
// Part 1: Capacity optimization methods
**************************************************

// Summary table: Sectoral
use "${git}/data/capacity.dta", clear  

  gen hf_outpatient_day = hf_outpatient/90
  gen hf_inpatient_day = hf_inpatient/90
  clonevar cap_old = hf_outpatient_day
  clonevar irt_old = irt
  
  collapse (mean) hf_outpatient_day hf_inpatient_day hf_staff_op irt_old ///
    (rawsum) cap_old , by(country hf_type)
    
    drop if hf_type == . | cap_old == 0

  gen c2 = hf_outpatient_day/hf_staff_op
  egen temp = sum(cap_old) , by(country)
  gen n = cap_old/temp
 
  lab var n "Share"
  lab var irt_old "Knowledge"
  lab var hf_outpatient_day "Mean Daily Outpatients" 
  lab var hf_inpatient_day "Mean Daily Inpatients" 
  lab var hf_staff_op "Mean Outpatient Staff" 
  lab var c2 "Mean Outpatients per Staff" 
 
  export excel ///
    country hf_type n irt hf_outpatient_day  ///
    hf_inpatient_day hf_staff_op c2  ///
  using "${git}/output/t-optimize-capacity.xlsx" ///
  , replace first(varl)

// Calculate new capacity per day at each provider based on resorting
use "${git}/data/capacity.dta", clear
  drop if hf_type == . | hf_outpatient == 0
  gen cap = hf_outpatient/(90*hf_staff_op)
    drop if cap == .
  
  tempfile irt all
  keep country irt cap hf_type hf_level hf_rural public ///
    hf_staff_op hf_outpatient hf_inpatient treat?
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

  ren (irt cap) (irt_old cap_old)
    egen c = rowmean(treat?)
    reg c c.irt_old##i.country 
    
  save "${git}/data/capacity-optimized.dta" , replace
  
// Create comparative statistics
use "${git}/data/capacity-optimized.dta" , clear
  tempfile all

  preserve
    collapse irt_old [aweight=cap_old] , by(country)
      predict c
      ren c irt_xxx
      reshape long irt , i(country) j(x) string
    save `all' , replace
  restore
  
  qui foreach type in bigger unrest hftype levels rururb public {
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
  
  export excel country x ///
    irt mean dif irt_hftype irt_rururb irt_levels irt_public irt_unrest irt_bigger ///
    using "${git}/output/t-optimize-quality.xlsx" ///
  , replace first(var)
  
  save "${git}/data/capacity-comparison.dta" , replace

**************************************************
// Part 2: Vizualizations for sectoral restriction
**************************************************

// Calculate sectoral shares and current quality
use "${git}/data/capacity-optimized.dta", clear

// Create optimized allocation images
              
  // Scatter bands       
  xtile band = irt_hftype , n(10)
    replace cap_hftype = 1 if cap_hftype < 1
    replace cap_hftype = 100 if cap_hftype > 100
    
  xtile band0 = irt_old , n(10)
    replace cap_old = 1 if cap_old < 1
    replace cap_old = 100 if cap_old > 100
    
    qui su cap_old , d
    gen fake1 = `r(p50)'
    gen fake0 = 1
    
    sort band0
    gen check = band0
    replace check = 5.5 if check == 4 

  tw ///
    (rarea fake1 fake0 check if check > 5 , lc(black) fc(red) ) ///
    (mband cap_old band0 , lc(black) lw(vthick) lp(dash)) ///
    (scatter cap_old band0 , m(.) mc(black%10) msize(tiny) mlc(none) jitter(1)) ///
  , by(country , norescale ixaxes r(2) legend(off) note(" ") )  ///
    subtitle(,bc(none)) yscale(log noline) xscale(noline) ///
    ylab(1 "0-1" `r(p50)' "Median" 10 100 "100+" , tl(0)) ytit("Outpatients per Day") ///
    xlab(1 5.5 "Median" 10 , tl(0)) xtit("Competence Decile") ///
    yline(`r(p50)', lc(black)) xline(5.5 , lc(black)) 
    
    graph export "${git}/output/f-optimization-1.png" , width(3000) replace
    
    qui su cap_old , d
    
  tw ///
    (mband cap_hftype band , lc(black) lw(vthick) ) ///
    (scatter cap_hftype band , m(.) mc(black%10) msize(tiny) mlc(none) jitter(1)) ///
  , by(country , norescale ixaxes r(2) legend(off) note(" ") )  ///
    subtitle(,bc(none)) yscale(log noline) xscale(noline) ///
    ylab(1 "0-1" 3.2 "Median" 10 100 "100+" , tl(0)) ytit("Outpatients per Day") ///
    xlab(1 5.5 "Median" 10 , tl(0)) xtit("Competence Decile") ///
    yline(`r(p50)', lc(black)) xline(5.5 , lc(black)) 
    
    graph export "${git}/output/f-optimization-2.png" , width(3000) replace
      
/* Outlier checks in exact reallocation
  gen c_o = hf_outpatient_day
  gen c_n = cap
  tw ///
    (rspike c_o c_n irt if c_n > c_o, lc(black) lw(thin) ) ///
    (rspike c_o c_n irt if c_n <= c_o, lc(red) lw(thin) ) ///
  , by(country , rescale ixaxes iyaxes c(2)) ysize(6)
*/

// Calculate new quality
use "${git}/data/capacity-optimized.dta", clear
tempfile all

  preserve
    collapse (mean) irt_old (rawsum) cap_old [aweight=cap_old] , by(country hf_type)
    save `all' , replace
  restore
  
  foreach type in unrest hftype levels rururb public {
    preserve
      collapse irt_`type' [aweight=cap_`type'] , by(country hf_type)
      merge 1:1 country hf_type using `all' , nogen
      save `all' , replace
    restore
  }
  
  use `all' , clear
  
  egen temp = sum(cap_old) , by(country)
  gen n = cap_old/temp
  
// Visualize sectoral changes
         
  local style msize(small)
  tw ///
    (pcarrow irt_old n irt_hftype n if hf_type == 1 , `style' mang(30) lc(black) mc(black)) ///
    (pcarrow irt_old n irt_hftype n if hf_type == 2 , `style' mang(60) lc(black) mc(black)) ///
    (pcarrow irt_old n irt_hftype n if hf_type == 3 , `style' mang(90) lc(black) mc(black)) ///
    (pcarrow irt_old n irt_hftype n if hf_type == 4 , `style' mang(30) lc(red) mc(red)) ///
    (pcarrow irt_old n irt_hftype n if hf_type == 5 , `style' mang(60) lc(red) mc(red)) ///
    (pcarrow irt_old n irt_hftype n if hf_type == 6 , `style' mang(90) lc(red) mc(red)) ///
    if irt_old != irt_hftype ///
  , by(country , r(2) rescale ixaxes note(" ")  ///
       legend(ring(0) pos(12))) subtitle(,bc(none)) xsize(6) ///
    xtit("National Share of Outpatients") ytit("Average Provider Competence") ///
    xlab(0 "0%" .25 "25%" .5 "50%" .75 "75%") xscale(noline) ///
    yline(0 , lc(black) lw(thin)) ylab(-2 "-2 SD" -1 "-1 SD" 1 "+1 SD" 2 "+2 SD" 3 "+3 SD" 0 "Mean") yscale(noline) ///
    legend(size(small) symxsize(small) c(4) ///
      order(0 "Rural:" 1 "Hospital" 2 "Clinic" 3 "Health Post" ///
            0 "Urban:" 4 "Hospital" 5 "Clinic" 6 "Health Post" ))
            
    graph export "${git}/output/f-optimize-differences.png" , width(3000) replace

**************************************************
// Part 3: Resort bootstrap and comparison
**************************************************
  use "${git}/data/capacity-comparison.dta" , clear
    keep if x == "_xxx"
    ren irt irt_old
    
    egen _meta_ciu = rowmax(irt_public irt_rururb irt_levels irt_hftype irt_unrest irt_bigger)
    egen _meta_cil= rowmin(irt_public irt_rururb irt_levels irt_hftype irt_unrest irt_bigger)
    clonevar effect_size = mean
    
    replace _meta_ciu = _meta_ciu - irt_old
    replace _meta_cil = _meta_cil - irt_old
    replace effect_size = effect_size - irt_old
    
    replace _meta_ciu = _meta_ciu * 100
    replace _meta_cil = _meta_cil * 100
    replace effect_size = effect_size * 100
    
    keep country _meta_ciu _meta_cil effect_size
    
    append using "${git}/data/comparison.dta" , gen(sgroup)
  
   replace std_err = (_meta_ciu - _meta_cil) / 4 
   
   decode country, gen(temp)
     replace CountryName = temp if temp !=""
   meta set effect_size _meta_cil _meta_ciu,  studylabel(CountryName) civartolerance(100)
   
   replace CountryName = "Tanzania" if strpos(CountryName,"Tanzania")
   
   gen region = " SDI Study"
   replace region = "Africa" if WHO_Region2 == "AFRO"
   replace region = "Americas" if WHO_Region2 == "AMRO"
   replace region = "Eastern Mediterranean" if WHO_Region2 == "EMRO"
   replace region = "South Asia" if WHO_Region2 == "SEARO"
   replace region = "Western Pacific" if WHO_Region2 == "WPRO"
   drop if WHO_Region2 == "EURO"
   
   replace Outcome_definition = strtrim(Outcome_definition)
   lab var Outcome_definition "Outcome"
   replace Outcome_definition = "Provider Reallocation: General Correct Management" if Outcome_definition == ""
  
   meta forest _id Outcome_definition _esci _plot if effect_size < 50 ///
     & (region == " SDI Study" | region == "Africa") ///
   , subgroup(region) sort(effect_size) ///
     nowmark noghet nogwhomt noohomtest noohetstats nullrefline ///
     bodyopts(size(small)) mark(msize(small) mcolor(black) msymbol(O) ) ///
     ciopts(lc(gs12) mstyle(none)) 
     
   
     graph export "${git}/output/f-lit-1.png" , replace
   
   meta forest _id Outcome_definition _esci _plot if effect_size < 50 ///
     & !(region == " SDI Study" | region == "Africa") ///
   , subgroup(region) sort(effect_size) ///
     nowmark noghet nogwhomt noohomtest noohetstats nullrefline ///
     bodyopts(size(small)) mark(msize(small) mcolor(black) msymbol(O) ) ///
     ciopts(lc(gs12) mstyle(none)) 
     
     graph export "${git}/output/f-lit-2.png" , replace


// Save for comparison

  gen check = 1
  ren d2 effect_size
  replace effect_size=effect_size*100
  save "${git}/temp/optimize-comparison.dta" , replace

//
