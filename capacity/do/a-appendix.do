// Figure. Caseload by facility-provider w absenteeism
use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  duplicates drop country hf_id , force

  gen x = hf_outpatient/(60*hf_staff_op)
  gen y = hf_outpatient/(60*hf_staff_op*(1-hf_absent))

  graph hbox x y if y != . ///
    , over(hf_type) noout note("") ///
    marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
    inten(0) cwhi lines(lw(thin) lc(black)) ///
    box(1 , lc(black) lw(thick)) box(2 , lc(red) lw(thick)) ///
    legend(on order(1 "Unadjusted" 2 "Absenteeism-Adjusted"))

    graph export "${git}/output/af-absenteeism.png" , width(3000) replace


// Figure. Caseload by facility
use "${git}/data/capacity.dta", clear
  drop if hf_outpatient == . | hf_outpatient == 0 | hf_staff_op == 0
  duplicates drop country hf_id , force
  gen x = hf_outpatient/90

  levelsof country_string, local(cs)
  foreach country in `cs' {
    tempfile `country'
    graph hbox x if country_string == "`country'" ///
      , over(hf_type) noout nodraw saving(``country'') ///
        ytit("") note("") title("`country'") ///
        marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
        inten(0) cwhi lines(lw(thin) lc(black)) box(1 , lc(black) lw(thin))

      local graphs `"`graphs' "\``country''"  "'
  }
  graph combine `graphs' , c(2) ysize(5) imargin(none)

  graph export "${git}/output/af-caseload.png" , width(3000) replace

// Figure. Descriptive statistics for facilities by sector

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

  bys country hf_type: gen weight = 1/_N
  replace hf_outpatient = 200 if hf_outpatient > 200
  graph box hf_outpatient [pweight=weight] ///
  , over(hf_type , axis(noline) sort(1))  ///
    hor ylab(,angle(0)) box(1 , lc(black) lw(thin)) ///
    marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
    ytit(" ") inten(0) cwhi lines(lw(thin) lc(black)) note(" ")

  graph export "${git}/output/af-descriptives.png" , width(3000) replace

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
// End
