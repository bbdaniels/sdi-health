# sdi-health

This folder contains all the do-files that were used to create the figures and tables used for Paper 2 - Vignettes. 

Below is the list of each do-file and what functions and outputs each of them produces. 

	Construct-variables - opens the "Vignettes_pl.dta" located in the Dropbox folder called "SDI_vignettes", which is a provider level dataset that only contains the information of providers that completed at least one medical vignette. Once it opens the dataset it constructs all the variables needed for the analysis and saves a finalized constructed dataset called "Vignettes_constructed.dta" that is saved in the Dropbox folder called "SDI_vignettes". This finalized constructed dataset will be used by the other do-files that create the figures and tables for Paper 2.


	Vignettes_pl_graphs - opens the "Vignettes_constructed.dta" and creates all the box plots that are all used in the paper. Each of box plots that are produced by this do-files are saved in the figs folder located in the outputs folder. 

	Vignettes_pl_tables - opens the "Vignettes_constructed.dta" and creates a provider summary table that is used in the paper. The table that is produced is saved in the tables folder located in the outputs folder.

	Vignettes_regressions - opens the "Vignettes_constructed.dta" and creates two regression tables (one saved as tex file and one saved as csv). The tex file format of the regression table is what is used in the paper. Both tables are saved in the tables folder located in the outputs folder. 

	Vignettes_pl_lines -  opens the "Vignettes_constructed.dta" and creates two line graphs that are used in the paper. The two line graphs are saved in the figs folder located in the outputs folder. 