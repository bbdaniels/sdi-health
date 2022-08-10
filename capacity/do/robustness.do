// Can we do the thing
clear
tempfile data
save `data' , replace emptyok

use "${git}/data/capacity.dta", clear
  drop if hf_type == . | hf_outpatient == 0
  gen cap = hf_outpatient/(60*hf_staff_op)
    drop if cap == .
    
  keep country irt cap uid

  levelsof country , local(levels)
  
foreach c in `levels' {
preserve
  keep if country == `c'
  
  gen v = .
  gen keep = 0
  gsort -cap -irt 
    egen c = rank(cap) , unique

  qui forv i = `c(N)'(-1)1 {    
    egen max = max(irt) if keep != 1
      gen next = max == irt
      bys next: gen use = _n == 1
      
      su irt if next == 1 & use == 1
      local hirt = `r(mean)' // Get next highest IRT

    su irt if c == `i'
      local lirt = `r(mean)' // Get IRT from highest capacity
      replace irt = `hirt' if c == `i' // Put highest IRT at highest capacity
      
    replace irt = `lirt' if next == 1 & use == 1 // Put lower IRT at old capacity
    replace keep = 1 if c == `i'
    
    mean irt [pweight=cap]
      local v = e(b)[1,1]
      
       replace v = `v' if c == `i'
       drop max next use
  }
append using `data'
save `data' , replace
restore
}
-
use `data' , clear
save "${git}/data/efficiency.dta" , replace
gsort country -irt
  by country: gen x = _n
  by country: egen min = min(v)
  gen v2 = v-min
  
  by country: egen gain = max(v2)
  gen share = v2/gain

  levelsof country , local(levels)
foreach c in `levels' {
  local graphs "`graphs' (line share x if country == `c')"
}

sort country x
tw `graphs' , ///
  xscale(log) xlab(1 10 100 1000) xtit("By Moving Best X Providers") ///
  ytit("Percent of Possible Gains") ylab(0 "0%" .5 "50%" 1 "100%")
// Now we know
