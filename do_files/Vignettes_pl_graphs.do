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
		global sectionA 	1 // box plot  		- provider cadre & knowledge score 
		global sectionB 	1 // box plot  		- provider knowledge score 
		global sectionC 	1 // box plot  		- medical qualification 
		global sectionD 	1 // scatter plot  	- provider cadre & knowledge score
	
/*****************************
			Vignettes   
******************************/	
	
	*Open vignettes dataset 
	use "$VG_dtFin/Vignettes_construct.dta", clear   

/****************************************************************************
 			Create box plot for provider cadre & knowledge score 	
*****************************************************************************/	
if $sectionA {	
	
	
	*Create local od knowledge score based on Kenya Nurses 2012 
	summarize  	theta_mle if country == "Kenya" & provider_cadre1 == 3, d
	local 		ken_med  = `r(p50)' 
	cap gen  prov_kenya  = (theta_mle>= `ken_med')
	
	graph bar prov_kenya, 																					///
		over(provider_cadre1, reverse axis(noli) label(nolabel)) 											///
		over(country, sort(country_avg)  axis(noli) label(labsize(small))) 										///
		bar(1, lc(none) fcolor(navy*0.6)) 																	///
		bar(2, lc(none) fcolor(navy*0.9)) 																	///
		bar(3, lc(none) fcolor(navy*1.3)) 																	///
		graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid) 	///
		legend(order(3 "Para-Professional" 2 "Nurse"  1 "Doctor" )											///
			pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) symx(4) symy(2) size(small)) 			///
		yscale(titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)							///
		ylabel(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%"  1 "100%", labsize(small)) 						///
		ytitle("Share of providers outperformed median Kenyan nurse {&rarr}", size(small)) allcategories	note("")	
		
		graph save "$VG_out/figs/cadre_knowledge2.gph", replace 
	

	graph box theta_mle, 																					///
		over(provider_cadre1, reverse axis(noli) label(nolabel)) 											///
		over(country, sort(country_avg)  axis(noli) label(labsize(small))) 											///
		noout box(1, fcolor(none) lcolor(navy*0.6)) 														///
		box(2, fcolor(none) lcolor(navy*0.9)) 																///
		box(3, fcolor(none) lcolor(navy*1.3)) 																///
		graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid) 	///
		legend(order(3 "Para-Professional" 2 "Nurse"  1 "Doctor" )								///
			pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) symx(4) symy(2) size(small)) 		///
		yscale(range(-3 3) titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)				///
		ylabel(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3" , labsize(small)) 							///
		yline(`ken_med', lwidth(0.3) lcolor(black) lpattern(dash)) 											///
		ytitle("Provider knowledge score {&rarr}", size(small)) allcategories	note("")	
		
		graph save "$VG_out/figs/cadre_knowledge1.gph", replace 
		
			graph combine ///
				  "$VG_out/figs/cadre_knowledge1.gph" ///
				  "$VG_out/figs/cadre_knowledge2.gph" ///
				, graphregion(color(white))	
			graph export "$VG_out/figs/cadre_knowledge_1_2_combine.png", replace as(png)		  	
	
}		
  
  
/****************************************************************************
 			Create box plot for knowledge score 	
*****************************************************************************/			
if $sectionB {	
	
	*Create local od knowledge score based on Kenya Nurses 2012 
	summarize  	theta_mle if country == "Kenya" & provider_cadre1 == 3, d
	local 		ken_med  = `r(p50)' 
	 	
	graph box theta_mle, ///
		over(country, sort(country_avg) descending axis(noli) relabel(`crt_name2') label(labsize(small)))		///
		box(1, fcolor(none) lcolor(navy) lwidth(0.4)) marker(1, msize(vsmall) mcolor(navy)) 			///
		box(2, fcolor(none) lcolor(cranberry) lwidth(0.4)) marker(2, msize(vsmall) mcolor(cranberry))	///
		box(3, fcolor(none) lcolor(gold*1.2) lwidth(0.4)) marker(3, msize(vsmall) mcolor(gold*1.2)) 	///
		box(4, fcolor(none) lcolor(purple) lwidth(0.4)) marker(4, msize(vsmall) mcolor(purple)) 		///
		box(5, fcolor(none) lcolor(chocolate) lwidth(0.4)) marker(5, msize(vsmall) mcolor(chocolate)) 	///
		box(6, fcolor(none) lcolor(orange) lwidth(0.4)) marker(6, msize(vsmall) mcolor(orange)) 		///
		box(7, fcolor(none) lcolor(midgreen) lwidth(0.4)) marker(7, msize(vsmall) mcolor(midgreen)) 	///
		box(8, fcolor(none) lcolor(midblue) lwidth(0.4)) marker(8, msize(vsmall) mcolor(midblue)) 		///
		box(9, fcolor(none) lcolor(emerald) lwidth(0.4)) marker(9, msize(vsmall) mcolor(emerald)) 		///
		box(10, fcolor(none) lcolor(lavender) lwidth(0.4)) marker(10, msize(vsmall) mcolor(lavender)) 	///
		box(11, fcolor(none) lcolor(purple) lwidth(0.4)) marker(11, msize(vsmall) mcolor(purple)) 		///
		box(12, fcolor(none) lcolor(red) lwidth(0.4)) marker(12, msize(vsmall) mcolor(red)) 			///
		box(13, fcolor(none) lcolor(brown) lwidth(0.4)) marker(13, msize(vsmall) mcolor(brown)) 		///
		yline(0, lwidth(0.3) lcolor(black) lpattern(dash))  									///
		ylabel(-5(1)5, labsize(small) angle(0) nogrid) 													///
		ytitle("Provider's knowledge score {&rarr}", placement(left) justification(left) size(small)) 	///
		legend(off) yscale(range(-5 5) titlegap(2)) bgcolor(white) graphregion(color(white)) asyvars 	///
		showyvars horizontal																			
	graph export "$VG_out/figs/prov_knowledge.png", replace as(png)	
} 

 

/****************************************************************************
 			Create box plot for medical education  	
*****************************************************************************/	
if $sectionC {	
	

	*Create local od knowledge score based on Kenya Nurses 2012 
	summarize  	theta_mle if country == "Kenya" & provider_cadre1 == 3, d
	local 		ken_med  = `r(p50)' 
	cap gen 	prov_kenya  = (theta_mle>= `ken_med')
	
	graph bar prov_kenya, 																					///
		over(provider_mededuc1, reverse axis(noli) label(nolabel)) 											///
		over(country, sort(country_avg)   axis(noli) label(labsize(small))) 								///
		bar(1, lc(none) fcolor(navy*0.6)) 																	///
		bar(2, lc(none) fcolor(navy*0.9)) 																	///
		bar(3, lc(none) fcolor(navy*1.3)) 																	///
		graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid) 	///
		legend(label(1 "Certificate") label(2 "Diploma") label(3 "Advanced") 								///
				order(1 2 3) pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) symx(4) symy(2) size(small))	///
		yscale(titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)							///
		ylabel(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%"  1 "100%", labsize(small)) 						///
		ytitle("Share of providers outperformed median Kenyan nurse {&rarr}", size(small)) allcategories note("")	
		
	graph save "$VG_out/figs/prov_mededu2.gph", replace 

	graph box theta_mle, 																					///
		over(provider_mededuc1, reverse axis(noli) label(nolabel)) 											///
		over(country, sort(country_avg)  axis(noli) label(labsize(small))) 									///
		noout box(1, fcolor(none) lcolor(navy*0.6)) 														///
		box(2, fcolor(none) lcolor(navy*0.9)) 																///
		box(3, fcolor(none) lcolor(navy*1.3)) 																///
		graphregion(color(white)) ytitle(, placement(left) justification(left)) ylabel(, angle(0) nogrid) 	///
		legend(order(1 "Certificate" 2 "Diploma" 3 "Advanced" )									///
			pos(6) ring(1) r(1) region(lwidth(0.2) fc(none) lc(none)) symx(4) symy(2) size(small)) 			///
		yscale(range(-3 3) titlegap(2)) bgcolor(white) asyvars showyvars horizontal  ysize(6)				///
		ylabel(-3 "-3" -2 "-2" -1 "-1" 0 "0" 1 "1" 2 "2" 3 "3" , labsize(small)) 							///
		yline(`ken_med', lwidth(0.3) lcolor(black) lpattern(dash)) 													///
		ytitle("Provider knowledge score {&rarr}", size(small)) allcategories	note("")	

		
		graph save "$VG_out/figs/prov_mededu1.gph", replace 

		
			graph combine ///
				  "$VG_out/figs/prov_mededu1.gph" ///
				  "$VG_out/figs/prov_mededu2.gph" ///
				, graphregion(color(white))	
			graph export "$VG_out/figs/prov_mededu_1_2_combine.png", replace as(png)		  	
	
}
   
	
*************************** End of do-file *****************************************
