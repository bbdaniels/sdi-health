   * ******************************************************************** *
   * ******************************************************************** *
   *                                                                      *
   *               SDI project											  *
   *               MASTER DO_FILE                                         *
   *                                                                      *
   * ******************************************************************** *
   * ******************************************************************** *

       /*
       ** PURPOSE:      Runs all the do-files need to produce the final dataset

       ** OUTLINE:      PART 0: Standardize settings and install packages
                        PART 1: Prepare folder path globals
                        PART 2: Run the master dofiles for each high-level task

       ** IDS VAR:      country year facility_id provider_id 

       ** NOTES:

       ** WRITTEN BY:   		Michael Orevba 

       ** Last date modified:  	May 24th 2021
       */

*iefolder*0*StandardSettings****************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS
   *
   *           - Install packages needed to run all dofiles called
   *            by this master dofile.
   *           - Use ieboilstart to harmonize settings across users
   *
   * ******************************************************************** *

*iefolder*0*End_StandardSettings************************************************
*iefolder will not work properly if the line above is edited

   *Install all packages that this project requires:
   *(Note that this never updates outdated versions of already installed commands, to update commands use adoupdate)
   local user_commands ietoolkit       //Fill this list will all user-written commands this project requires
   foreach command of local user_commands {
       cap which `command'
       if _rc == 111 {
           ssc install `command'
       }
   }

   *Standardize settings accross users
   ieboilstart, version(12.1)          //Set the version number to the oldest version used by anyone in the project team
   `r(version)'                        //This line is needed to actually set the version from the command above

*iefolder*1*FolderGlobals*******************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 1:  PREPARING FOLDER PATH GLOBALS
   *
   *           - Set the global box to point to the project folder
   *            on each collaborator's computer.
   *           - Set other locals that point to other folders of interest.
   *
   * ******************************************************************** *

    * All Users
   * -----------
   
	*Sets up local directory for everyone 
	local dir `c(username)'

   * Root folder globals
   * ---------------------
    global projectfolder "/Users/`dir'/Dropbox/SDI_vignettes" 
 

* These lines are used to test that the name is not already used (do not edit manually)

   * Project folder globals
   * ---------------------

*iefolder*1*FolderGlobals*master************************************************
*iefolder will not work properly if the line above is edited


*iefolder*1*FolderGlobals*encrypted*********************************************
*iefolder will not work properly if the line above is edited


*iefolder*1*FolderGlobals*endline***********************************************
*iefolder will not work properly if the line above is edited


   *DataSets sub-folder globals
   global VG_dt                  "$projectfolder/DataSets" 
   global VG_dtFin               "$VG_dt/Final"    
   
   *Dofile sub-folder globals
   global VG_do                  "/Users/`dir'/GitHub/sdi-health/do_files" // this is the GitHub repo path

   *Output sub-folder globals
   global VG_out                 "/Users/`dir'/GitHub/sdi-health/outputs" 	// this is the GitHub repo path


*iefolder*1*End_FolderGlobals***************************************************
*iefolder will not work properly if the line above is edited


*iefolder*2*StandardGlobals*****************************************************
*iefolder will not work properly if the line above is edited

   * Set all non-folder path globals that are constant accross
   * the project. Examples are conversion rates used in unit
   * standardization, different sets of control variables,
   * adofile paths etc.

 *  do "$dataWorkFolder/global_setup.do" 


*iefolder*2*End_StandardGlobals*************************************************
*iefolder will not work properly if the line above is edited


*iefolder*3*RunDofiles**********************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 3: - RUN DOFILES CALLED BY THIS MASTER DOFILE
   *
   *           - A task master dofile has been created for each high-
   *            level task (cleaning, construct, analysis). By 
   *            running all of them all data work associated with the 
   *            endline should be replicated, including output of 
   *            tables, graphs, etc.
   *           - Feel free to add to this list if you have other high-
   *            level tasks relevant to your project.
   *
   * ******************************************************************** *

   **Set the locals corresponding to the tasks you want
   * run to 1. To not run a task, set the local to 0.
   local analysisDo     1

  
   if (`analysisDo' == 1) { // Change the local above to run or not to run this file
		do "$VG_do/Vignettes_pl_graphs.do" 
		do "$VG_do/Vignettes_pl_lines.do" 
		do "$VG_do/Vignettes_pl_tables.do" 
		do "$VG_do/Vignettes_regressions.do" 
   }

*iefolder*3*End_RunDofiles******************************************************
*iefolder will not work properly if the line above is edited
