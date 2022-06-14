// Figures for paper

// Figure. Descriptive statistics for facilities 

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
    gen hf_outpatient_day = hf_outpatient/60
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type hf_level ///
      , by(country hf_id) vallab(hf_type)
      
  replace hf_outpatient = hf_outpatient/(60)
    lab var hf_outpatient "Daily Outpatients"
  gen hf_outpatient_staff = hf_outpatient/hf_staff_op
    lab var hf_outpatient_staff "Daily Outpatients per Staff"
    
    lab var irt "Mean Provider Knowledge"
    
    recode hf_level (1=1 "Health Post")(2=3 "Hospital")(3=2 "Clinic") , gen(level)
    
  bys country level: gen weight = 1/_N

          
  foreach var of varlist ///
    hf_outpatient hf_staff_op hf_outpatient_staff irt  {
      
    local label : var label `var'
  
    winsor `var' , gen(`var'2) p(0.01)
    graph box `var'2 [pweight=weight], over(level , axis(noline))  ///
      hor ylab(,angle(0)) nodraw ///
      title("`label'", pos(11) span) scale(0.7) ///
      ytit(" ") inten(0) lines(lc(black))

      graph save "${git}/temp/`var'.gph" , replace
      local graphs `" `graphs' "${git}/temp/`var'.gph" "'
  }
  
  graph combine `graphs' , ysize(5)
  graph export "${git}/output/f-descriptives.png" , width(3000) replace
      
// Figure. Facility caseloads and staff, by country

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_inpatient == . | hf_staff == 0 | hf_staff_op == 0
  
  labelcollapse (mean) irt hf_absent hf_outpatient hf_inpatient hf_staff hf_staff_op hf_type hf_rural ///
      , by(country hf_id) vallab(hf_type)
      
      replace hf_inpatient = hf_inpatient/60
      replace hf_outpatient = hf_outpatient/60
           
      replace hf_outpatient = hf_outpatient/hf_staff_op
        replace hf_outpatient = 100 if hf_outpatient > 100
        replace hf_outpatient = 0.1 if hf_outpatient < 0.1
        replace hf_staff_op = 10 if hf_staff_op > 10
      
  tw ///
    (scatter  hf_staff_op hf_outpatient if hf_rural == 0, jitter(2) m(.) mc(red%40) mlw(none)) ///
    (scatter  hf_staff_op hf_outpatient if hf_rural == 1, jitter(2) m(Oh) mc(black%40) mlw(none)) ///
  , by(country  , r(2) note(" ") iyaxes ixaxes legend(pos(12))) ///
    xtit("Total Outpatients per Provider Workday") ytit("Number of Outpatient Staff") ///
    ylab(0.5 " " 1(1)9 10 "10+" , tlength(0) labgap(2)) yscale( noline) ///
    xscale(log) xlab(0.1 "0" 1 10 100  "100+") xoverhang ///
    legend(order(1 "Urban" 2 "Rural") pos(12) symysize(*5) symxsize(*5))  subtitle(, nobox) ///
    xline(1 10 , lc(gs14))
     
    graph export "${git}/output/f-caseload.png" , width(3000) replace

// Figure. Daily caseload per provider, by facility sector and size
use "${git}/data/capacity.dta", clear

  duplicates drop country hf_id , force
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  
  gen hf_outpatient_day = hf_outpatient/60
  gen hf_inpatient_day = hf_inpatient/60
  clonevar cap_old = hf_outpatient_day
  clonevar theta_mle = irt
  gen check = hf_outpatient_day/hf_staff_op
  
  replace check = 1 if check < 1
  replace check = 160 if check > 160
  
  levelsof country_string , local(l)
  local x = 0
    foreach level in `l' {
      local ++x
      local legend `"`legend' `x' "`level'" "'
    }
  
  cdfplot check if check > 0 ///
  , by(country_string) xlog xscale(log) xlab(1 2.5 5 10 20 40 80 160, labgap(2) labsize(small) notick) ///
    legend(on c(1) pos(3) size(small) symxsize(small) order(`legend') region(lp(blank))) xscale(noline ) yscale(noline ) ///
    ylab(0 "100%" .25 "75%" .5 "50%" .75 "25%" 1 "0%" , notick) yline(0 .25 .5 .75 1 , lc(gs14) lw(thin)) ///
    ytit("Share of providers who see at least...") xtit("... X patients per day {&rarr}" , placement(w)) xline(1 2.5 5 10 20 40 80 160 , lc(gs14) lw(thin)) ///
    opt1( yscale(reverse)  ///
      lc(blue cranberry cyan dkgreen dkorange emerald gold lavender magenta maroon navy red ))

    graph export "${git}/output/f-capacity-staff.png" , width(3000) replace
    
// Setup: Current comparator for optimization
use "${git}/data/capacity.dta", clear

  gen hf_outpatient_day = hf_outpatient/60
  gen hf_inpatient_day = hf_inpatient/60
  clonevar cap_old = hf_outpatient_day
  clonevar theta_mle = irt
  gen check = hf_outpatient_day/hf_staff_op
  bys country: gen weight = 1/_N
  
  keep if check != . & theta_mle != .
  keep theta_mle check country hf_type weight
     
  mean theta_mle [pweight=check*weight]
    local old = r(table)[1,1]
  
  bys country hf_type (theta_mle): gen srno = _n
    tempfile irtrank
    save `irtrank'
  drop srno 
  ren theta_mle theta_old
  bys country hf_type (check): gen srno = _n
    merge 1:1 country hf_type srno using `irtrank'
 
  mean theta_mle [pweight=check*weight]
   local new = r(table)[1,1]
   
  tw (histogram theta_mle , w(0.5) start(-5) gap(10) lw(none) fc(gs12) yaxis(2) percent) ///
    (fpfit check theta_mle [pweight=weight], lc(black) lw(thick)) ///
    (fpfit check theta_old [pweight=weight], lp(dash) lw(thick) lc(black)) ///
    (pci 0 `new' 25 `new' , yaxis(2) lc(black) lw(thick)) ///
    (pci 0 `old' 25 `old' , yaxis(2) lc(black) lw(thick) lp(dash)) /// 
  ,  yscale(alt) yscale(alt  axis(2)) ytitle("Percentage of Providers (Histogram)" , axis(2)) ///
    ytitle("Average Patients per Day") xtit("Vignettes Knowledge Score (Vertical Lines = Means)") ///
    legend(on pos(12) order(3 "Original Assignment" 2 "Optimized by Country/Sector") size(small) region(lp(blank))) ///
    xlab(-5(1)5) ylab(0 50 100 150 200 250) ylab(0(5)25 , axis(2))
    
    graph export "${git}/output/f-optimize-providers.png" , width(3000) replace
      
// End      
