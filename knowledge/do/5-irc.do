// Appendix portion
use "${git}/data/irt-items.dta" , clear

sort b_pv1
gen condition = upper(substr(varname,1,strpos(varname,"_")-1))
levelsof condition , local(conditions)

lab var condition "Vignette"
lab var label "Item"
lab var b_pv1 "Difficulty"
lab var a_pv1 "Discrimination"
lab var c_pv1 "Guess Rate"

foreach co in `conditions' {
  export excel condition label b_pv1 a_pv1 c_pv1 ///
    using "${git}/appendix/irt.xlsx" ///
    if condition == "`co'" & strpos(label,"Physical"), first(varl) sheet("`co'_P") sheetreplace

  preserve
    keep if condition == "`co'" & strpos(label,"Physical")
    local graphs ""
    forv i = 1/`c(N)' {
      local a = a_pv1[`i']
      local b = b_pv1[`i']
      local c = c_pv1[`i']
      local d = round(`=`a'*50',1)
      local graphs "`graphs' (function `c'+(1-`c')*((exp(`a'*(x-(`b'))))/(1+(exp(`a'*(x-(`b')))))) , range(-4 4) lc(black%`d'))"
    }
    restore

    tw `graphs' , title("Condition: `co'") ///
      xtit("Provider Knowledge Score") ytit("Likelihood of Item Complete") ///
      ylab(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%" 1 "100%")

      graph export "${git}/appendix/p_irt_`co'.png" , replace
}

foreach co in `conditions' {
if "`co'" != "RESP" {
  export excel condition label b_pv1 a_pv1 c_pv1 ///
    using "${git}/appendix/irt.xlsx" ///
    if condition == "`co'" & strpos(label,"History"), first(varl) sheet("`co'_Q") sheetreplace

  preserve
    keep if condition == "`co'" & strpos(label,"History")
    local graphs ""
    forv i = 1/`c(N)' {
      local a = a_pv1[`i']
      local b = b_pv1[`i']
      local c = c_pv1[`i']
      local d = round(`=`a'*50',1)
      local graphs "`graphs' (function `c'+(1-`c')*((exp(`a'*(x-(`b'))))/(1+(exp(`a'*(x-(`b')))))) , range(-4 4) lc(black%`d'))"
    }
    restore

    tw `graphs' , title("Condition: `co'") ///
      xtit("Provider Knowledge Score") ytit("Likelihood of Item Complete") ///
      ylab(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%" 1 "100%")

      graph export "${git}/appendix/q_irt_`co'.png" , replace
}
}

  tw ///
    (scatter a_pv1 b_pv1 if strpos(label,"History") , msize(med) mfc(red) mlc(none)) ///
    (scatter a_pv1 b_pv1 if strpos(label,"Physical") , msize(med) mfc(black) mlc(none)) ///
  , xtit("IRT Item Difficulty (Knowledge Score Required for 50% Success)",size(small)) ///
    ytit("IRT Item Discrimination (Maximum Score Separation Rate)",size(small)) ///
    legend(on ring(0) c(1) pos(11) order(1 "History Questions" 2 "Physical Examinations"))

    graph export "${git}/appendix/irt.png" , replace
