// Figures for paper

// Figure. Descriptive statistics for facilities 

use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  
  collapse (mean) hf_outpatient hf_staff_op ///
      , by(country hf_id) fast
      
  replace hf_outpatient = hf_outpatient/(60)
  gen hf_outpatient_staff = hf_outpatient/(hf_staff_op)
       
  bys country: gen weight = 1/_N
  replace hf_outpatient = 200 if hf_outpatient >200
  replace hf_outpatient_staff = 200 if hf_outpatient_staff >200
      
  graph box hf_outpatient [pweight=weight] ///
  , over(country , axis(noline) sort(1)) ///
    hor ylab(,angle(0)) box(1 , lc(black) lw(thin)) ///
    marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
    ytit(" ") inten(0) cwhi lines(lw(thin) lc(black)) note(" ") title("Per Facility")
    
    graph save "${git}/temp/fac.gph" , replace
    
  graph box hf_outpatient_staff [pweight=weight] ///
  , over(country , axis(noline) sort(1)) ///
    hor ylab(,angle(0)) box(1 , lc(black) lw(thin)) ///
    marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
    ytit(" ") inten(0) cwhi lines(lw(thin) lc(black)) note(" ") title("Per Provider")
      
    graph save "${git}/temp/pro.gph" , replace
    
  graph combine "${git}/temp/fac.gph" "${git}/temp/pro.gph"  , ysize(6) c(1) imargin(none)
    graph export "${git}/output/f-descriptives.png" , width(3000) replace

// Cumulative Capacity
use "${git}/data/capacity.dta", clear

  gen hf_outpatient_day = hf_outpatient/60
  gen hf_inpatient_day = hf_inpatient/60
  clonevar cap_old = hf_outpatient_day
  clonevar theta_mle = irt
  gen check = hf_outpatient_day/hf_staff_op
    
  keep check country_string
  
  replace check = 1 if check < 1
  replace check = 160 if check >= 160 & check != .
  
  cdfplot check  ///
  , by(country_string) xlog xscale(log) xlab(1 2 5 10 20 40 80 160, labsize(small) notick) ///
    legend(on c(3) pos(6) size(small) )  ysize(5) scale(0.75) xscale(noline ) yscale(noline ) ///
    ylab(0 "100%" .25 "75%" .5 "50%" .75 "25%" 1 "0%" , notick) ///
    ytit("Share of providers seeing...") xtit("... more than X patients daily") ///
      xline(2 5 10 40 80 , lc(gs14) lw(thin)) ///
      yline(.25 .75 , lc(gs14) lw(thin)) ///
      xline(1 20 160 , lc(black) lw(thin)) ///
      yline(0 .5 1 , lc(black) lw(thin)) ///
    opt1( yscale(reverse)  ///
      lc(blue cranberry cyan dkgreen dkorange emerald gold lavender magenta maroon navy red )) ///
    legend( region(lc(none)) ring(0) c(1) pos(1) ///
      order(1 "Kenya" 2 "Madagascar" 3 "Malawi" 4 "Mozambique" 5 "Niger" ///
            6 "Nigeria" 7 "Sierra Leone" 8 "Tanzania" 9 "Togo" 10 "Uganda"))
      
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
