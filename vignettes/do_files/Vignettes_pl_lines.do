* ******************************************************************** *
* ******************************************************************** *
*                                                                      *
*              	Descriptive Stats									   *
*				Unique ID											   *
*                                                                      *
* ******************************************************************** *
* ******************************************************************** *
/*
	  ** PURPOSE: Create figures and graphs on the vignettes 

       ** IDS VAR: country year unique_id 
       ** NOTES:
       ** WRITTEN BY:			Michael Orevba
       ** Last date modified: 	June 1st 2021
	   
 *************************************************************************/
 
		//Sections
		global sectionB 	1 // line graph - scatter for provider age 
		global sectionC 	1 // line graph - scatter for treatment accuracy
		
/*****************************
			Vignettes   
******************************/	
	
	*Open vignettes dataset 
	use "$VG_dtFin/Vignettes_construct.dta", clear    
		
	 

/****************************************************************************
 			Create scatter line graph for provider age 
*****************************************************************************/
if $sectionB {	
	
	replace provider_age1 = . if provider_age1>80 | provider_age1<=19

	levelsof country , local(levels)
	local x = 1
	local legend ""
	local graphs ""
	foreach c in `levels' {
		local ++x
		local graphs `"`graphs'  (lpoly theta_mle provider_age1 if country== "`c'", bwidth(1.2) lwidth(0.5))   "'
		local legend `"`legend' `x' "`c'" "'
	}
	
	tw  (histogram provider_age1, freq bin(12)  lw(med) fc(gs15) lc(gs13) gap(10) yaxis(2)) || 							///
		`graphs' 																										///
		(lpoly theta_mle provider_age1, bwidth(1.2) lwidth(1.5) lcolor(cranberry)),										///
		ylabel(-3 -2 -1 0 1 2 3, labsize(small) angle(0) nogrid) 														///
		xlabel(20 "20" 40 "40" 60 "60" 80 "80", labsize(small)) ytitle("Frequency (Histogram)", axis(2) size(small))	///
		xtitle("Provider Age {&rarr}", size(small) placement(left))	ytitle(" ") yscale(noli axis(2))					///
		ytitle("Knowledge Score", size(small)) 																			///
		xsize(7) legend(order(`legend') c(1) pos(3) ring(1) region(lc(none))) graphregion(color(white)) xscale(noli titlegap(2)) yscale(noli) ///
		yla(, axis(2) angle(0) nogrid labsize(vsmall))	yscale(alt) yscale(alt axis(2))									///
		bgcolor(white) 						
	graph save "$VG_out/figs/treat_scatter_irt.gph", replace
	
	
	
	levelsof country , local(levels)
	local x = 1
	local legend ""
	local graphs ""
	foreach c in `levels' {
		local ++x
		local graphs `"`graphs'  (lpoly percent_correctt provider_age1 if country== "`c'", bwidth(1.2) lwidth(0.5))   "'
		local legend `"`legend' `x' "`c'" "'
	}
	
	tw  (histogram provider_age1, freq bin(12)  lw(med) fc(gs15) lc(gs13) gap(10) yaxis(2)) || 							///
		`graphs' 																										///
		(lpoly percent_correctt provider_age1, bwidth(1.2) lwidth(1.5) lcolor(cranberry)),								///
		ylabel(0 "0" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", labsize(small) angle(0) nogrid) 					///
		xlabel(20 "20" 40 "40" 60 "60" 80 "80", labsize(small)) ytitle("Frequency (Histogram)", axis(2) size(small))	///
		xtitle("Provider Age {&rarr}", size(small) placement(left))	ytitle(" ") yscale(noli axis(2))					///
		ytitle("Percent of Conditions Treated Correctly", size(small)) 													///
		xsize(7) legend(order(`legend') c(1) pos(3) ring(1) region(lc(none))) graphregion(color(white)) xscale(noli titlegap(2)) yscale(noli) ///
		yla(, axis(2) angle(0) nogrid labsize(vsmall))	yscale(alt) yscale(alt axis(2))									///
		bgcolor(white) 						
	graph save "$VG_out/figs/treat_scatter_age.gph", replace
	
	
		grc1leg ///
				  "$VG_out/figs/treat_scatter_irt.gph" ///
				  "$VG_out/figs/treat_scatter_age.gph" ///
				, graphregion(color(white))	c(1) pos(3) 
			graph export "$VG_out/figs/treat_scatter_irt_age_combine.png", replace as(png)		  	
	
} 

  histogram provider_age1, by(country , ixaxes iyaxes note(" ") legend(r(1) order(1 "Provider Age" 2 "Correct Management") )) ///
	  start(15) discrete w(5) fc(gray) lc(none) ///
		barwidth(4) percent ylab(0 "0%" 10 "10%" 20 "20%" 30 "30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%") ///
		xlab(20 25 30 35 40 45 50 55 60 65 70  , labsize(vsmall)) ///
		ytit(" ") xtit(" ") addplot(lpoly percent_correctt provider_age1) ///
		legend(r(1) order(1 "Provider Age" 2 "Correct Management"))
		
		graph export "$VG_out/figs/age_distro.png", replace as(png)
		
 
/****************************************************************************
 			Create scatter line graph for treatment accuracy   
*****************************************************************************/
if $sectionC {	
	
	// Panel A
	
	tw ///
	  (scatter percent_correctd theta_mle , jitter(10) m(x) mc(black%5)) ///
	  (lpolyci percent_correctd theta_mle , 							///
	      degree(1) lw(thick) lcolor(black) ciplot(rline) 				///
		  alcolor(black) alwidth(thin) alpat(dash)) 					///
	, ///
		graphregion(color(white)) 																							///
		title("Conditions Diagnosed Correctly", size(medium) justification(left) color(black) span pos(11)) 				///
		xtitle("Provider knowledge score {&rarr}", placement(left) justification(left)) xscale(titlegap(2))	 				///
		ylab(0 "0" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", angle(0) nogrid) yscale(noli) bgcolor(white) ytitle("") 	///
		xlabel(-5 (1) 5) xscale(noli) note("")		 legend(off)
		
		graph save "$VG_out/figs/treat_scatter_d.gph", replace	

		
	// Panel B
	
    tw ///
	  (scatter percent_correctt theta_mle , jitter(10) m(x) mc(black%5)) 	///
	  (lpolyci percent_correctt theta_mle , 								///
	      degree(1) lw(thick) lcolor(black) ciplot(rline) 					///
		  alcolor(black) alwidth(thin) alpat(dash)) 						///
	, ///
		graphregion(color(white)) 																						///
		title("Conditions Treated Correctly", size(medium) justification(left) color(black) span pos(11)) 				///
		xtitle("Provider knowledge score {&rarr}", placement(left) justification(left)) xscale(titlegap(2))	 			///
		ylab(0 "0" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%", angle(0) nogrid) yscale(noli) bgcolor(white) ytitle("") 	///
		xlabel(-5 (1) 5) xscale(noli) note("")		 legend(off)
		
		graph save "$VG_out/figs/treat_scatter_t.gph", replace	
		
		
		graph combine ///
		  "$VG_out/figs/treat_scatter_d.gph" ///
		  "$VG_out/figs/treat_scatter_t.gph" ///
		, graphregion(color(white)) c(1) ysize(6)
	 graph export "$VG_out/figs/treat_scatter_td_combine.png", replace 

	
	
	
}


	
**************************************** End of do-file ************************************************
