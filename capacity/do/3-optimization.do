**************************************************
// Part 1: Capacity optimization methods
**************************************************

// Summary table: Sectoral shares and statistics
use "${git}/data/capacity.dta", clear

  gen hf_outpatient_day = hf_outpatient/60
  clonevar cap_old = hf_outpatient_day
  clonevar irt_old = irt

  collapse (mean) hf_outpatient_day hf_staff_op irt_old ///
    (rawsum) cap_old , by(country hf_level)

    expand 2 , gen(check)
      replace country = 0 if check == 1

  collapse (mean) hf_outpatient_day hf_staff_op irt_old ///
    (rawsum) cap_old , by(country hf_level)

    drop if hf_level == . | cap_old == 0
    recode hf_level (1=1 "Health Post")(2=3 "Hospital")(3=2 "Clinic") , gen(level)
    sort country level

  gen c2 = hf_outpatient_day/hf_staff_op
  egen temp = sum(cap_old) , by(country)
  gen n = cap_old/temp
  gen t = c2 * (6.8/60)

  lab var n "Outpatient Share"
  lab var irt_old "Mean Competence"
  lab var hf_outpatient_day "Daily Outpatients per Facility"
  lab var hf_staff_op "Outpatient Staff"
  lab var c2 "Outpatients per Staff Day"
  lab var level "Level"
  lab var t "Hours per Provider Day"

  export excel ///
    country level hf_outpatient_day hf_staff_op c2 t n irt_old  ///
  using "${git}/output/t-summary-capacity.xlsx" ///
  , replace first(varl)

// Calculate new capacity per day at each provider based on resorting
use "${git}/data/capacity.dta", clear
  drop if hf_type == . | hf_outpatient == 0
  gen cap = hf_outpatient/(60*hf_staff_op)
    drop if cap == .

  egen vig = rowmean(treat?)

  tempfile irt all
  keep country irt cap hf_type hf_level hf_rural public cadre ///
    hf_staff_op hf_outpatient hf_inpatient treat? vig
  save `all'



qui {
  // Capacity adjustment resorts
    collapse (p90) new=cap (rawsum) n=cap , by(country)
      merge 1:m country using `all' , nogen
      gsort country -irt
      gen tot = n/new
      bys country : gen cap_biggco = new if _n <= tot
        replace cap_biggco = 0 if cap_biggco == .
        gen irt_biggco = irt
        gen vig_biggco = vig
        drop n tot new
        save `all' , replace

    collapse (p90) new=cap (rawsum) n=cap , by(country hf_level)
      merge 1:m country hf_level using `all' , nogen
      gsort country hf_level -irt
      gen tot = n/new
      bys country hf_level : gen cap_biggse = new if _n <= tot
        replace cap_biggse = 0 if cap_biggse == .
        gen irt_biggse = irt
        gen vig_biggse = vig
        drop n tot new
        save `all' , replace

    collapse (p90) new=cap (rawsum) n=cap , by(country hf_level)
      merge 1:m country hf_level using `all' , nogen
      gsort country hf_level -irt
      gen tot = n/20
      bys country hf_level : gen cap_bigg20 = new if _n <= tot
        replace cap_bigg20 = 0 if cap_bigg20 == .
        gen irt_bigg20 = irt
        gen vig_bigg20 = vig
        drop n tot new
        save `all' , replace

    collapse (p90) new=cap (rawsum) n=cap , by(country hf_level)
      merge 1:m country hf_level using `all' , nogen
      gsort country hf_level -irt
      gen tot = n/30
      bys country hf_level : gen cap_bigg30 = new if _n <= tot
        replace cap_bigg30 = 0 if cap_bigg30 == .
        gen irt_bigg30 = irt
        gen vig_bigg30 = vig
        drop n tot new
        save `all' , replace

    collapse (p90) new=cap (rawsum) n=cap , by(country hf_level)
      merge 1:m country hf_level using `all' , nogen
      gsort country hf_level -irt
      gen tot = n/40
      bys country hf_level : gen cap_bigg40 = new if _n <= tot
        replace cap_bigg40 = 0 if cap_bigg40 == .
        gen irt_bigg40 = irt
        gen vig_bigg40 = vig
        drop n tot new
        save `all' , replace

    collapse (p90) new=cap (rawsum) n=cap , by(country hf_level)
      merge 1:m country hf_level using `all' , nogen
      gsort country hf_level -irt
      gen tot = n/50
      bys country hf_level : gen cap_bigg50 = new if _n <= tot
        replace cap_bigg50 = 0 if cap_bigg50 == .
        gen irt_bigg50 = irt
        gen vig_bigg50 = vig
        drop n tot new

  // Restricted to type resort
  preserve
  gsort country hf_type -irt
    keep country hf_type irt vig
    ren vig vig_hftype
    ren irt irt_hftype
    gen ser_hftype = _n
    save `irt' , replace
  restore

  gsort country hf_type -cap
    gen cap_hftype = cap
    gen ser_hftype = _n
    merge 1:1 ser_hftype using `irt' , nogen

  // Restricted to cadre resort
  preserve
  gsort country cadre -irt
    keep country cadre irt vig
    ren vig vig_cadres
    ren irt irt_cadres
    gen ser_cadres = _n
    save `irt' , replace
  restore

  gsort country cadre -cap
    gen cap_cadres = cap
    gen ser_cadres = _n
    merge 1:1 ser_cadres using `irt' , nogen

  // Unrestricted resort
  preserve
  gsort country -irt
    keep country irt cap vig
    ren vig vig_unrest
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
    keep country hf_level irt cap  vig
    ren vig vig_levels
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
    keep country hf_rural irt cap vig
    ren vig vig_rururb
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
    keep country public irt cap vig
    ren vig vig_public
    ren irt irt_public
    gen ser_public = _n
    save `irt' , replace
  restore

  gsort country public -cap
    gen cap_public = cap
    gen ser_public = _n
    merge 1:1 ser_public using `irt' , nogen
}

  ren (irt cap vig) (irt_old cap_old vig_old)
    egen c = rowmean(treat?)
    reg c c.irt_old##i.country

  save "${git}/data/capacity-optimized.dta" , replace

// Create comparative statistics
use "${git}/data/capacity-optimized.dta" , clear
  tempfile all

  preserve
    collapse irt_old vig_old [aweight=cap_old] , by(country)
      ren vig_old irt_xxx
      reshape long irt , i(country) j(x) string
    save `all' , replace
  restore

  qui foreach type in ///
    unrest hftype levels rururb public cadres ///
    biggco biggse bigg20 bigg30 bigg40 bigg50 {
    preserve
      collapse irt_`type' vig_`type' [aweight=cap_`type'] , by(country)
        ren vig_`type' irt_xxx
        reshape long irt , i(country) j(x) string
        ren irt irt_`type'
        replace x = "_old" if x != "_xxx"
      merge 1:1 country x using `all' , nogen
      save `all' , replace
    restore
  }

  use `all' , clear
    egen mean = rowmean(irt_*)
    egen dmean = rowmean(irt_bigg50 irt_bigg40 irt_bigg30 irt_bigg20 irt_biggse irt_biggco)
    egen smean = rowmean(irt_cadres irt_public irt_rururb irt_levels irt_hftype irt_unrest)
    gen ddif = mean - irt
    gen sdif = smean - irt

  sort x country
    replace x = "Knowledge" if x == "_old"
    replace x = "Correct" if x == "_xxx"

  export excel country x ///
    irt smean sdif irt_unrest irt_cadres irt_public irt_levels irt_rururb irt_hftype ///
    using "${git}/output/t-optimize-quality.xlsx" ///
  , replace first(var)

  export excel country x ///
    irt dmean ddif irt_biggco irt_biggse irt_bigg20 irt_bigg30 irt_bigg40 irt_bigg50 ///
    using "${git}/output/t-optimize-quality-d.xlsx" ///
  , replace first(var)

  save "${git}/data/capacity-comparison.dta" , replace

**************************************************
// Part 1.2: Vizualizations for correctness
**************************************************

use "${git}/data/capacity-comparison.dta", clear

  keep irt dmean smean country x
  reshape wide irt dmean smean, i(country) j(x) string
  decode country, gen(ccode)

  append using "${git}/data/capacity-optimized.dta"
  egen correct = rowmean(treat?)


  tw (fpfitci correct irt_old ///
      if irt_old > -2 & irt_old < 2 , lc(black) fc(gray) alc(white%0)) ///
    (pcarrow irtCorrect irtKnowledge dmeanCorrect dmeanKnowledge ///
      , ml(country) mlabang(30) lc(red) mc(red) mlabc(black) mlabpos(2)) ///
    , ytit("Vignettes Correct Before and After Reallocation") ylab(0 "0%" .2 "20%" .4 "40%" .6 "60%") ///
      xtit("Average Interaction Competence Before and After Reallocation") ///
      legend(on r(1) pos(7) order(2 "Theoretical" 3 "Actual") ring(0))

      graph export "${git}/output/f-optimization-demand.png" , width(3000) replace

  tw (fpfitci correct irt_old ///
      if irt_old > -2 & irt_old < 3 , lc(black) fc(gray) alc(white%0)) ///
    (pcarrow irtCorrect irtKnowledge smeanCorrect smeanKnowledge ///
      ,  ml(country) mlabang(30) lc(red) mc(red) mlabc(black) mlabpos(2)) ///
    , ytit("Vignettes Correct Before and After Reallocation") ylab(0 "0%" .2 "20%" .4 "40%" .6 "60%") ///
      xtit("Average Interaction Competence Before and After Reallocation") ///
      legend(on r(1) pos(7) order(2 "Theoretical" 3 "Actual") ring(0))

      graph export "${git}/output/f-optimization-supply.png" , width(3000) replace


**************************************************
// Part 2: Vizualizations for sectoral restriction
**************************************************

// Create optimized allocation images
use "${git}/data/capacity-optimized.dta", clear

  // Data setup
    replace cap_hftype = 1 if cap_hftype < 1
    replace cap_hftype = 100 if cap_hftype > 100

    replace cap_old = 1 if cap_old < 1
    replace cap_old = 100 if cap_old > 100

  // Graphs

    qui su cap_old , d

    binsreg  cap_old irt_old if irt_old > -2 & irt_old < 2 ///
      , polyreg(1) by(country) ysize(8) nbins(10) ///
        xscale(noline) yscale(noline) xtit("Provider Competence") title("Actual") ytit("Daily Outpatient Caseload") ///
        bysymbols(o o o o o o o o o o ) ///
        legend(on pos(3) c(5) region(lc(none)) size(small) ///
          order(1 "Kenya" 3 "Madagascar" 5 "Malawi" 7 "Mozambique" 9 "Niger" ///
                11 "Nigeria" 13 "Sierra Leone" 15 "Tanzania" 17 "Togo" 19 "Uganda") )

      graph save "${git}/output/f-optimization-1.gph" , replace

    binsreg  cap_hftype irt_hftype if irt_hftype > -2 & irt_hftype < 2 ///
      , polyreg(3) by(country) legend(on pos(3) c(1)) ysize(8) nbins(10) ///
        xscale(noline) yscale(noline) xtit("Provider Competence") title("Reallocated") ytit("Daily Outpatient Caseload") ///
        bysymbols(o o o o o o o o o o )


      graph save "${git}/output/f-optimization-2.gph" , replace

      grc1leg ///
        "${git}/output/f-optimization-1.gph" ///
        "${git}/output/f-optimization-2.gph" , ycom

        graph draw, ysize(6)

        graph export "${git}/output/f-optimization.png" , width(3000) replace

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
  keep if x == "Correct"
  ren irt irt_old

  egen _meta_ciu = rowmax(irt_public irt_rururb irt_levels irt_hftype irt_unrest irt_biggco irt_biggse irt_bigg20 irt_bigg30 irt_bigg40 irt_bigg50)
  egen _meta_cil= rowmin(irt_public irt_rururb irt_levels irt_hftype irt_unrest irt_biggco irt_biggse irt_bigg20 irt_bigg30 irt_bigg40 irt_bigg50)
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
   ciopts(lc(gs12) mstyle(none)) nooverall


   graph export "${git}/output/f-lit-1.png" , replace

 meta forest _id Outcome_definition _esci _plot if effect_size < 50 ///
   & !(region == " SDI Study" | region == "Africa") ///
 , subgroup(region) sort(effect_size) ///
   nowmark noghet nogwhomt noohomtest noohetstats nullrefline ///
   bodyopts(size(small)) mark(msize(small) mcolor(black) msymbol(O) ) ///
   ciopts(lc(gs12) mstyle(none)) nooverall

   graph export "${git}/output/f-lit-2.png" , replace


// Save for comparison

gen check = 1
replace effect_size=effect_size*100
save "${git}/output/optimize-comparison.dta" , replace

**************************************************
// Part 4: Doctor resampling
**************************************************

clear
tempfile all
  save `all' , emptyok
use "${git}/data/capacity-optimized.dta" , clear
gen uid = _n

gen doctor = (cadre == 1)
keep doctor irt_old country cap_old uid

levelsof country, local(cs)

foreach c in `cs' {

  preserve
  keep if doctor == 1 & country == `c'
  clonevar irt_doc = irt_old
  tempfile doctors
  save `doctors'
  restore

  preserve
  keep if doctor == 0 & country == `c'
  cross using `doctors'

  append using `all'
  append using `doctors'
  save `all' , replace
  restore

}
use `all' , clear
save "${git}/output/optimize-doctors-basis.dta" , replace

cap prog drop upskill
prog def upskill

args frac

    use "${git}/output/optimize-doctors-basis.dta" , clear

    gen r = runiform()
      replace r = 0 if doctor == 1
    bys uid (r) : gen v = _n
     keep if v == 1

    bys country: egen rank = rank(r)
    gsort country -doctor rank
      bys country: gen N = _N
      replace rank = rank/N

    gen irt_new = irt_old
      replace irt_new = irt_doc if rank < `frac' & irt_doc > irt_new

    collapse irt_new [aweight=cap_old] , by(country)
    gen f = `frac'

end

clear
tempfile all
  save `all' , replace emptyok

  qui forv f = 0(0.05)1 {
    forv it = 1/50 {
      upskill `f'
      append using `all'
      save `all' , replace
    }
  }
  save "${git}/output/optimize-doctors-done.dta" , replace

  decode country, gen(cc)
  levelsof cc, local(cs)
  local graphs  ""
  local legend ""
  local x = 1
  foreach c in `cs' {
    local graphs `"`graphs' (scatter irt_new f if cc == "`c'" , mc(%10))"'
    local graphs `"`graphs' (scatter irt_new f if cc == "`c'" & f == 0 , mlab(cc) m(none) mlabc(black) mlabpos(9))"'
    // local legend `"`legend' `x' "`c'" "'
    local ++x
    local ++x
  }

  replace f = f*100
  graph box irt_new ///
  , over(f) noout ///
    marker(1, m(p) mc(black) msize(tiny)) medtype(cline) medline(lc(red) lw(medthick)) ///
    inten(0) cwhi lines(lw(thin) lc(black)) box(1 , lc(black) lw(thin)) ///
  by(cc, c(2) iyaxes yrescale note("") scale(0.7)) ysize(6) ///
    ytit("Average Interaction Competence") note("")

    graph export "${git}/output/f-docs-upskill.png" , width(3000) replace

//
