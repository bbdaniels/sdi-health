// Tables for knowledge paper

// Table. Sample description
use "${git}/data/knowledge.dta", clear

  table () country , ///
    stat( mean rural public hospital health_ce health_po ///
      doctor nurse other advanced diploma certificate) ///
    stat( total rural)
  
  collect export "${git}/outputs/t-summary.xlsx", replace 


// End
