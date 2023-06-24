// Queueing simulation

cap prog drop q_up
prog def q_up , rclass

args periods patients duration

  local p_patient = `patients'/`periods'
  local p_resolve = 1/`duration'

  clear
  set obs 1
  gen period = 0
  gen service = . // to add more servers later
  gen q1 = .

  qui forv i = 1/`periods' {

    expand 2 in 1
    gsort -period
    replace period = `i' in 1
    local shift = 0

    local pos ""
    local q 1
    // Increment wait for all patients in queue
    foreach var of varlist q* {
      if "`=`var'[1]'" == "." & "`pos'" == "" {
        local pos = `q'
      }
      local ++q
      replace `var' = `var' + 1 in 1 if `var' != .
    }
    if "`pos'" == "" local pos 1

    // Spawn new patient at end of queue
    gen r = runiform()
    if `=r[1]' < `p_patient' {
      if "`=q`pos'[1]'" == "." {
        replace q`pos' = 0 in 1
      }
      else gen q`q' = 0 in 1
    }
    drop r

    // Clear service
    gen r = runiform()
    if `=r[1]' < `p_resolve' {
      replace service = . in 1
    }
    drop r

    // Advance patients if service is open
    if "`=service[1]'" == "." & "`=q1[1]'" != "." {
      replace service = q1 in 1
      local total_wait = `total_wait' + `=service[1]'
      local total_pats = `total_pats' + 1
      local shift = 1
    }

    local count = 1
    qui if `shift' == 1 qui foreach var of varlist q* {
      local ++count
      if "`=q`count'[1]'" != "" {
        replace `var' = `=q`count'[1]' in 1
      }
      else replace `var' = . in 1
    }

    }

    // Calculate statistics
    return scalar total_wait = `total_wait'
    return scalar total_pats = `total_pats'
    return scalar mean_wait  = `total_wait'/`total_pats'

    qui count if service != .
    return scalar total_work = `r(N)'
    return scalar work_time  = `r(N)'/`periods'

end

q_up 720 100 5
// End
