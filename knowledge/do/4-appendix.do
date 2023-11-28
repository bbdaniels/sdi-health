// Figure: IRT by conditions

use "${git}/data/knowledge.dta", clear

  local diarrhea_title "Child Diarrhea + Dehydration"
  local pneumonia_title "Child Pneumonia"
  local diabetes_title "Diabetes (Type II)"
  local tb_title "Tuberculosis"
  local malaria_title "Child Malaria + Anemia"
  local pph_title "PPH"
  local pregnant_title "Neonatal Asphyxia"

  qui foreach var in ///
    diarrhea pneumonia diabetes tb malaria pph pregnant {

      egen `var' = rowmean(`var'_history*)

      * local title :  var lab `var'
      local graphs `"`graphs' "\``var''"  "'
      local title ``var'_title'
      tempfile `var'

      binsreg `var' theta_mle , polyreg(10) ///
        dotsplotopt(mc(black)) polyregplotopt(lc(red) lw(thick)) ///
        ylab(0 "0%" .5 "50%" 1 "100%" , notick) yline(0 .5 1 , lc(black)) ///
        yscale(noline) xscale(noline) ytit(" ") title("{bf:`title'} (All Items)" , size(small)) ///
        xlab(0 "" 5 "+5" -5 "-5" -1 " " -2 " " -3 " " -4 " " 1 " " 2 " " 3 " " 4 " ") ///
          note("Provider competence score {&rarr}") xtit("") ///
        saving(``var'') nodraw

    }

     graph combine `graphs' , c(2) ysize(5)
       graph export "${git}/appendix/f-irt-condition.png", replace

// Figure. Weight
use "${git}/data/knowledge.dta", clear

  keep *history*

  qui foreach var of varlist *history* {
    qui count if !missing(`var')
    if r(N) < 10000 {
      drop `var'
    }
    else {
      drop if missing(`var')
    }
  }

  order * , seq
  qui pca *history*
    screeplot , mc(black) lc(black) xtit(" ") ytit(" " , size(zero)) xlab(none) xscale(r(0)) ///
    title("Panel A: PCA Component Eigenvalues", placement(left) justification(left) span) ///
    addplot(scatteri 7.6823 1 "{&larr} First principal component" , m(none) mlabc(black))
      graph save "${git}/temp/validation-1.gph", replace

    estat loadings
      mat a = r(A)

    collapse * , fast
      xpose, clear
      gen s = _n
      tempfile mean
      save `mean'

    clear
    svmat a
      gen s = _n
      merge 1:1 s using `mean'

      egen x = sum(a1)
      replace a1 = a1/x

      scatter a1 v1 , mc(black) yscale(r(0)) ylab(#6) ///
        xtit("Share of providers asking each history question {&rarr}", placement(left) justification(left)) ///
        xlab(0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%") ///
        xoverhang ///
        ytit(" " , size(zero)) ///
        ylab(0 "0%" 0.005 "0.5%" .01 "1.0%" .015 "1.5%" .02 "2.0%" 0.025 "2.5%" ) ///
        title("Panel B: Index weights for history question components", placement(left) justification(left) span)

        graph save "${git}/temp/validation-2.gph", replace

        graph combine ///
          "${git}/temp/validation-1.gph" ///
          "${git}/temp/validation-2.gph" ///
          , c(1) ysize(5)

          graph export "${git}/appendix/f-validation-pca.png", replace


// Figure. Quantile distributions by education
use "${git}/data/knowledge.dta", clear

  drop if country == "Uganda"
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1

  // Kenya Diploma Reference
  summarize theta_mle if country == "Kenya" & provider_mededuc1 == 3, d
    local ken_med  = `r(p50)'
    gen prov_kenya  = (theta_mle >= `ken_med')

  qui levelsof(country) , local(countries)
  foreach x in `countries' {
    qui mean prov_kenya if country == "`x'" [pweight=weight]
      local a = r(table)[1,1]
      local pct = substr("`a'",2,2)

    vioplot theta_mle if country == "`x'" [pweight=weight] ///
    , over(provider_mededuc1)  xline(-5(1)5,lc(black) lw(thin))  hor ///
      xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(7) ///
      yscale(noline) xscale(off)  xlab(-5(1)5 0 "Av.", labsize(small)) ///
      den(lw(none) fc(black) fi(70)) bar(fc(white) lw(none)) ///
      line(lw(none)) med(m(|) mc(white) msize(large)) ///
      title("`x' [`pct'%]" , span pos(11)) nodraw saving("${git}/temp/`x'.gph" , replace)
  }

  gen x = 0
  scatter x x in 1 , m(i) xlab(-5(1)5 , notick) ///
    xscale(noline alt) yscale(noline) ytit(" ") xtit(" ") nodraw ///
    saving("${git}/temp/blank.gph" , replace) ///
    ylab(1 "Certificate" , labc(white%0) labsize(small) notick)

  graph combine ///
    "${git}/temp/Full Sample.gph" "${git}/temp/Malawi.gph" ///
    "${git}/temp/Kenya.gph" "${git}/temp/Tanzania.gph" ///
    "${git}/temp/Togo.gph" "${git}/temp/Guinea Bissau.gph" ///
    "${git}/temp/Madagascar.gph"  ///
    "${git}/temp/Mozambique.gph" "${git}/temp/Sierra Leone.gph" ///
    "${git}/temp/Nigeria.gph" "${git}/temp/Niger.gph" ///
    "${git}/temp/blank.gph"  ///
  , xcom c(1) ysize(7) imargin(zero)

    graph export "${git}/appendix/f-education.png", replace width(2000)

// End
