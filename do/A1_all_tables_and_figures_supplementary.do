******* How To Compete with Robots
******* Science Robotics Replication Files
******* Fabrizio Colella - Rafael Lalive
******* Februrary 2022

******* This do files generate all the figures in the supplumentary material

*******************************************************************************

clear

******* cross Risk Measures
******* Fabrizio Colella

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

*********************** Table S3
{
clear all
use $dta/risk.dta

keep Occupation share share_uto share_dys
rename share ARI
sort ARI
order Occupation ARI share_uto share_dys

replace ARI = round(ARI,0.01)
replace share_uto = round(share_uto,0.01)
replace share_dys = round(share_dys,0.01)

keep if _n == 1 | _n==122 | _n==203 | _n==458 | _n==967
list

export excel using $output/figures_tables_in_the_paper/Table_S3a_maintext.xlsx, replace firstrow(variables)  


clear all
use $dta/risk_sens.dta

keep Occupation share share_uto share_dys  p5 mean p95
rename share ARI
sort mean
gen rank2 = _n 
sort ARI
keep  Occupation rank2 mean p5 p95
order Occupation rank2 mean p5 p95

replace mean  = round(mean ,0.01)
replace p5  = round(p5,0.01)
replace p95 = round(p95,0.01)

keep if _n == 1 | _n==122 | _n==203 | _n==458 | _n==967
list

export excel using $output/figures_tables_in_the_paper/Table_S3b_sensitivity.xlsx, replace firstrow(variables)  
}


*********************** Figure S1
{
	clear all
*** compare to existing measure
use $dta/risk
sort 	ONETSOCCode
merge 1:1 ONETSOCCode using $dta/risk_sum.dta

scatter  mean share, xtitle(ARI (Dystopian,Utopian)) ytitle(ARI (Missing at Random)) ///
legend(off) xlabel(0.4(.1).8) ylabel(0.4(.1)1)  graphregion(color(white)) color(ebblue) 
graph export $output/figures_tables_in_the_paper/Figure_S1_compare_ARI_Sens.png, replace
}


*********************** Table S4
{
clear all
* gen percentiles
use $dta/retreffdistances.dta , clear
foreach var in aut_risk  {
	preserve
		xtile newvar = `var',nq(100)
		gen perc_`var' = newvar
		drop newvar
		keep `var' perc_`var'
		duplicates drop
		save $dta/temp`var'.dta , replace
	restore
}
use $dta/tempaut_risk.dta, clear
rename aut_risk risk_S_occ
rename perc_aut_risk perc_risk_S_occ
rename risk_S_occ share
save $dta/temprisk_S_occ.dta , replace
	
* import categories
clear all
import excel $input/task_isco_crosswalk.xlsx , first

keep SOC10 task_3_cat 
gen soc1 =   subinstr(SOC10," ","",.)
drop SOC10
duplicates drop
duplicates drop soc1, force
duplicates drop

save temp.dta , replace

*** produce table
use $dta/risk.dta , clear
merge m:1 share using $dta/temprisk_S_occ.dta

gen soc1 = substr(ONETSOCCode,1,7)
collapse (mean) share perc_risk_S_occ , by(soc1)
rename share ARI
duplicates drop
merge 1:1 soc1 using temp.dta
keep if _merge==3
drop _merge

collapse (mean) ARI perc_risk_S_occ , by(task_3_cat)
replace ARI  = round(ARI ,0.01)
replace perc_risk_S_occ  = round(perc_risk_S_occ )
list
export excel using $output/figures_tables_in_the_paper/Table_S4_job_classification.xlsx, replace firstrow(variables)  

erase $dta/temprisk_S_occ.dta 
erase temp.dta
}



*********************** Figures S2 and S3
{
***********
clear all
* 0) open database
use $dta/risk.dta 
rename ONETSOCCode id_SOC
keep id_SOC share Occupation
g code = substr(id_SOC,1,7)
sort code id_SOC
by code: g duplicates = _N
by code: g first = _n==1
** RL: we have duplicates for SOC codes that have stuff after the comma
** collapse them to stuff before the comma

egen mshare = mean(share), by(code)
keep if first
keep code share 
rename share ARI
save $dta/temp.dta ,replace

* 1) get employment wages
global numbers "tot_emp emp_prse h_median h_pct10 h_pct90 a_median a_pct10 a_pct90 h_mean a_mean"
global strings "occ_code occ_title"
global keepVars = "$strings $numbers"

clear
local year 2013
import excel using $input\BLS_data\national_M`year'_dl.xls, first
rename *, lower
keep if occ_group == "detailed"
keep $keepVars
destring $numbers, force replace
/*rename occ_code soc10
merge 1:m soc10 using $input/Crosswalks/SOC10_to_SOC18.dta
drop soc10
drop occ_title
rename soc18 occ_code
rename title18 occ_title
egen
*/

save $dta/temp2013.dta, replace

clear
local year 2018
import excel using $input\BLS_data\national_M`year'_dl.xls, first
rename *, lower
keep if occ_group == "detailed"
keep $keepVars
destring $numbers, force replace
save $dta/temp`year'.dta, replace

clear
local year 2003
import excel using $input\BLS_data\national_M`year'_dl.xls, first
keep if group != "major"
keep $keepVars
destring $numbers, force replace
save $dta/temp`year'.dta, replace


clear
local year 2008
import excel using $input\BLS_data\national_M`year'_dl.xls, first
keep if group != "major"
keep $keepVars
destring $numbers, force replace
save $dta/temp`year'.dta, replace

clear
use $dta/temp2003
g year = 2003
foreach year in 2008 2013 2018 {
	append using $dta/temp`year'
	replace year = `year' if year == .
}

* update h_mean if h_mean missing
foreach stat in mean pct10 pct90 median {
replace h_`stat' = a_`stat' / 2080 if h_`stat' == .
}

rename occ_code code
sort code
merge m:1 code using $dta/temp.dta 
tab _merge
keep  if _merge==3
rename _merge mergerisk

* capped at 70
*replace h_mean = 70 if h_mean >= 70

foreach var in tot_emp h_mean h_median h_pct10 h_pct90 {
	g l`var' = log(`var')
	}
	
sort year ARI
xtile pARI = ARI, nq(100)
xtile tARI = ARI, nq(3)	

save $dta/wagesEmpl.dta, replace

* descriptive analysis terciles
use $dta/wagesEmpl.dta, clear
g lemp = log(tot_emp)
g lwage = log(h_mean)
g lmedian = log(h_median)
g lpct10 = log(h_pct10)
g lpct90 = log(h_pct90)
g l9010	= lpct90 - lpct10

global vars "lemp lwage lmedian lpct10 lpct90 l9010"
global se ""
foreach var in $vars {
	global se = "$se" + " `var'_se=`var'"
}


sort code year
foreach var in $vars {
	capt drop temp
	by code: g temp = (`var'-`var'[1])/(year-year[1])
	replace `var' = temp
	replace `var' = 0 if year == 2003
}

preserve
* no weighting for employment
collapse  (mean) $vars  (semean) $se , by(year tARI)

drop if year == 2003

foreach var in $vars {
	g ul_`var' = `var'+1.97*`var'_se
	g ll_`var' = `var'-1.97*`var'_se
	}

************ log employment
local var lemp 
local ylabel "0.01(.01).04"
if "`var'" == "lemp" {
		local ylabel "-.03(.01).03"
}
scatter `var' year if tARI == 1 , lcolor(gs1) lp(bold) || rcap ll_`var' ul_`var' year if tARI == 1, lcolor(gs1)|| ///
scatter `var' year if tARI == 2 , lcolor(gs8) lp(shortdash) || rcap ll_`var' ul_`var' year if tARI == 2, lcolor(gs8)  || ///
scatter `var' year if tARI == 3 , lcolor(gs12) lp(longdash) || rcap ll_`var' ul_`var' year if tARI == 3, lcolor(gs12) ///
	xlabel(2007 " " 2008 "2008" 2013 "2013" 2018 "2018" 2019 " ") ylabel(`ylabel') ytitle(Annual Growth Rate (rel. 2003)) scheme(s1mono) ///
	 legend(row(1) label(2 "") label(1 "Low ARI") label(4 "CI") label(3 "Medium ARI") label(6 "CI") label(5 "High ARI") order( 1 3 5) )
graph export "$output/figures_tables_in_the_paper/Figure_S2_`var'.png", replace

************ log wage
local var lwage  
local ylabel "0.01(.01).04"
if "`var'" == "lemp" {
		local ylabel "-.03(.01).03"
}
scatter `var' year if tARI == 1 , lcolor(gs1) lp(bold) || rcap ll_`var' ul_`var' year if tARI == 1, lcolor(gs1)|| ///
scatter `var' year if tARI == 2 , lcolor(gs8) lp(shortdash) || rcap ll_`var' ul_`var' year if tARI == 2, lcolor(gs8)  || ///
scatter `var' year if tARI == 3 , lcolor(gs12) lp(longdash) || rcap ll_`var' ul_`var' year if tARI == 3, lcolor(gs12) ///
	xlabel(2007 " " 2008 "2008" 2013 "2013" 2018 "2018" 2019 " ") ylabel(`ylabel') ytitle(Annual Growth Rate (rel. 2003)) scheme(s1mono) ///
	 legend(row(1) label(2 "") label(1 "Low ARI") label(4 "CI") label(3 "Medium ARI") label(6 "CI") label(5 "High ARI") order( 1 3 5) )
graph export "$output/figures_tables_in_the_paper/Figure_S3_`var'.png", replace

restore
}



*********************** Figure S4
{
	clear all
*** open data
use $dta/retreffdistances.dta 

*** get soc code
preserve
	keep id_SOC Occupation
	duplicates drop
	rename Occupation occ2
	rename id_SOC occ2_id_SOC
	save ttemp.dta , replace
restore
merge m:1 occ2 using ttemp.dta
keep if _merge!=2
drop _merge
erase ttemp.dta

*** get 6 digits SOC
gen soc1 = substr(id_SOC,1,7)
gen soc2 = substr(occ2_id_SOC,1,7)

*** merge with transitions
merge m:1 soc1 soc2 using "$input/Occ Transitions Public Data Set (Jan 2021)/occupation_transitions_public_data_set.dta"
** NOTE we keep only the matched ones
keep if _merge==3
drop _merge

rename aut_risk ari11
rename ris2 ari2


*** multiple merges
collapse (mean) transition_share D1_d_skills D2_d_know D3_d_risk ari1 ari2, by(soc1 soc2)

save $dta/transitions.dta, replace

*** Retraining Effort vs Share of Transitions (Figure in Reply to Reviewers)
preserve
generate retEff = sqrt(D1_d_skills*D2_d_know)
g ri = D3_d_risk / retEff
sort soc1 ri
by soc1: g suggested = _n ==1 
by soc1: g suggRank =_n

correl suggRank transition_share
*scatter transition_share suggRank
/* 
             | suggRank transi~e
-------------+------------------
    suggRank |   1.0000
transition~e |  -0.0186   1.0000

*/


*bysort suggested: su retEff D3_d_risk ri


qui su transition_share
g transNorm = transition_share / r(sum)


qui su suggested
g suggNorm = suggested / r(sum)

correl transNorm suggNorm


g retEffint = int(retEff*10)/10+.05

collapse (sum) transNorm suggNorm, by(retEffint)
fl
correl transNorm suggNorm

/* 
             | transN~m suggNorm
-------------+------------------
   transNorm |   1.0000
    suggNorm |   0.4394   1.0000
*/

line transNorm retEffint, lp(dash) || line suggNorm retEffint  , scheme(s1color) ///
	xtitle("Average Distance (ARE)") ytitle(Share) xlabel(0.05(.1)0.85) ///
	legend(label(1 "Actual Transitions") label(2 "Recommended Transitions"))
graph export "$output/figures_tables_in_the_paper/Figure_S4_Revision_cumTransitions.png" , replace width(2400) height(1800)
restore
}




*********************** Table S5
*********************************************************************
*****P1
{
clear all
use $dta/retreff_resilience_with_retreffdistances.dta , clear
keep id_SOC
duplicates drop
g code = substr(id_SOC,1,7)
sort code id_SOC
save $dta/temp.dta ,replace

* 1) get employment information
clear
import excel using $input\BLS_data\national_M2018_dl.xlsx, first
rename TOT_EMP empl_18
rename OCC_CODE code
keep if OCC_GROUP == "detailed"
keep code empl_18
sort code
duplicates drop
merge 1:m code using $dta/temp.dta // 91% matched
tab _merge
keep if _merge==3
drop _merge
sort code id_SOC
egen subgroups = count(code) , by(code)
gen im_empl_18 = empl_18/subgroups
keep id_SOC im_empl_18
merge 1:m id_SOC using $dta/retreff_resilience_with_retreffdistances.dta // 97% matched
tab _merge
keep if _merge==3
drop _merge
sort id_SOC rank
erase $dta/temp.dta 

* 2) Compute the average risks 
sort id_SOC risk_S_occ
by id_SOC: gen risk_rank = _n
sort id_SOC rank

* gen terciles
sort aut_risk rank
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

********** T tests difference in weighted means between terciles
	preserve
		keep if rank==1
		ttest aut_risk == risk_S_occ if tcrisk==1
		ttest aut_risk == risk_S_occ if tcrisk==2
		ttest aut_risk == risk_S_occ if tcrisk==3
		
		reg aut_risk ib1.tcrisk [w=im_empl_18]
		reg aut_risk ib2.tcrisk [w=im_empl_18]
		reg aut_risk ib3.tcrisk [w=im_empl_18]
		reg risk_S_occ ib1.tcrisk [w=im_empl_18]
		reg risk_S_occ ib2.tcrisk [w=im_empl_18]
		reg risk_S_occ ib3.tcrisk [w=im_empl_18]

		reg D1_d_skills ib1.tcrisk [w=im_empl_18]
		reg D1_d_skills ib2.tcrisk [w=im_empl_18]
		reg D1_d_skills ib3.tcrisk [w=im_empl_18]

		reg D2_d_know ib1.tcrisk [w=im_empl_18]
		reg D2_d_know ib2.tcrisk [w=im_empl_18]
		reg D2_d_know ib3.tcrisk [w=im_empl_18]
	restore


* current weighted risk by tercile
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen topratio_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if rank==1  
egen totD1 = sum(wD1) if rank==1 , by(tcrisk)
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 , by(tcrisk)
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18 if risk_rank==1 
egen total_emp = sum(im_empl_18)  if risk_rank==1 , by(tcrisk)  
egen totrisk = sum(wrisk) if risk_rank==1 , by(tcrisk)
gen toprisk_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  , by(tcrisk)
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 , by(tcrisk)
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

ereplace toprisk_avgrisk = mean(toprisk_avgrisk) , by(tcrisk)
ereplace toprisk_avgD1_skill = mean(toprisk_avgD1_skill) , by(tcrisk)
ereplace toprisk_avgD2_know = mean(toprisk_avgD2_know) , by(tcrisk)

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know
duplicates drop

keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
foreach var of varlist avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know  {
replace `var' =  round(`var',0.001)
}

gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
list 

export excel using $output/figures_tables_in_the_paper/Table_S5_P1a_retreff_risk_change.xlsx, replace firstrow(variables)  

***************************************************************

clear all

**** GET PERCENTILES

use $dta/retreffdistances.dta , clear
foreach var in aut_risk  D3_d_risk D1_d_skills D2_d_know {
	preserve
		xtile newvar = `var',nq(100)
		gen perc_`var' = newvar
		drop newvar
		keep `var' perc_`var'
		duplicates drop
		save $dta/temp`var'.dta , replace
	restore
}
use $dta/tempaut_risk.dta, clear
rename aut_risk risk_S_occ
rename perc_aut_risk perc_risk_S_occ
save $dta/temprisk_S_occ.dta , replace


**** START
use $dta/retreff_resilience_with_retreffdistances.dta , clear
keep id_SOC
duplicates drop
g code = substr(id_SOC,1,7)
sort code id_SOC
save $dta/temp.dta ,replace

* 1) get employment information
clear
import excel using $input\BLS_data\national_M2018_dl.xlsx, first
rename TOT_EMP empl_18
rename OCC_CODE code
keep if OCC_GROUP == "detailed"
keep code empl_18
sort code
duplicates drop
merge 1:m code using $dta/temp.dta // 91% matched
tab _merge
keep if _merge==3
drop _merge
sort code id_SOC
egen subgroups = count(code) , by(code)
gen im_empl_18 = empl_18/subgroups
keep id_SOC im_empl_18
merge 1:m id_SOC using $dta/retreff_resilience_with_retreffdistances.dta // 97% matched
tab _merge
keep if _merge==3
drop _merge
sort id_SOC rank
erase $dta/temp.dta 

* 2) Compute the average risks 
sort id_SOC risk_S_occ
by id_SOC: gen risk_rank = _n
sort id_SOC rank


** get percentiles
foreach var in aut_risk risk_S_occ D3_d_risk D1_d_skills D2_d_know {
	merge m:1 `var' using $dta/temp`var'.dta
	drop `var'
	rename perc_`var' `var'
	keep if _merge==3
	drop _merge
	erase $dta/temp`var'.dta
}
	
/*
		foreach var in aut_risk  D3_d_risk D1_d_skills D2_d_know {
			xtile newvar = `var',nq(100)
			replace `var' = newvar
			drop newvar
		}
		preserve
			keep Occupation aut_risk 
			duplicates drop
			rename Occupation S_occ
			rename aut_risk percentile
			save temp.dta, replace
		restore
		merge m:1 S_occ using temp.dta
		keep if _merge==3
		drop _merge
		replace risk_S_occ = percentile
		drop percentile
*/

* gen terciles
sort aut_risk rank
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

********** T tests difference in weighted means between terciles
	preserve
		keep if rank==1
		ttest aut_risk == risk_S_occ if tcrisk==1
		ttest aut_risk == risk_S_occ if tcrisk==2
		ttest aut_risk == risk_S_occ if tcrisk==3
		
		reg aut_risk ib1.tcrisk [w=im_empl_18]
		reg aut_risk ib2.tcrisk [w=im_empl_18]
		reg aut_risk ib3.tcrisk [w=im_empl_18]
		reg risk_S_occ ib1.tcrisk [w=im_empl_18]
		reg risk_S_occ ib2.tcrisk [w=im_empl_18]
		reg risk_S_occ ib3.tcrisk [w=im_empl_18]

		reg D1_d_skills ib1.tcrisk [w=im_empl_18]
		reg D1_d_skills ib2.tcrisk [w=im_empl_18]
		reg D1_d_skills ib3.tcrisk [w=im_empl_18]

		reg D2_d_know ib1.tcrisk [w=im_empl_18]
		reg D2_d_know ib2.tcrisk [w=im_empl_18]
		reg D2_d_know ib3.tcrisk [w=im_empl_18]
	restore


* current weighted risk by tercile
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen topratio_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if rank==1  
egen totD1 = sum(wD1) if rank==1 , by(tcrisk)
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 , by(tcrisk)
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18 if risk_rank==1 
egen total_emp = sum(im_empl_18)  if risk_rank==1 , by(tcrisk)  
egen totrisk = sum(wrisk) if risk_rank==1 , by(tcrisk)
gen toprisk_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  , by(tcrisk)
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 , by(tcrisk)
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

ereplace toprisk_avgrisk = mean(toprisk_avgrisk) , by(tcrisk)
ereplace toprisk_avgD1_skill = mean(toprisk_avgD1_skill) , by(tcrisk)
ereplace toprisk_avgD2_know = mean(toprisk_avgD2_know) , by(tcrisk)

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know
duplicates drop


keep avgrisk topratio_avgrisk 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change 
gsort -avgrisk
foreach var of varlist avgrisk topratio_avgrisk  {
replace `var' =  round(`var',0.001)
}
list 

export excel using $output/figures_tables_in_the_paper/Table_S5_P1b_retreff_risk_change_percentiles.xlsx, replace firstrow(variables)  
}
*



*********************************************************************
*****P2 - SQUARED
{
clear all
use $dta/retreff_square_resilience_with_retreffdistances.dta , clear
keep id_SOC
duplicates drop
g code = substr(id_SOC,1,7)
sort code id_SOC
save $dta/temp.dta ,replace

* 1) get employment information
clear
import excel using $input\BLS_data\national_M2018_dl.xlsx, first
rename TOT_EMP empl_18
rename OCC_CODE code
keep if OCC_GROUP == "detailed"
keep code empl_18
sort code
duplicates drop
merge 1:m code using $dta/temp.dta // 91% matched
tab _merge
keep if _merge==3
drop _merge
sort code id_SOC
egen subgroups = count(code) , by(code)
gen im_empl_18 = empl_18/subgroups
keep id_SOC im_empl_18
merge 1:m id_SOC using $dta/retreff_square_resilience_with_retreffdistances.dta // 97% matched
tab _merge
keep if _merge==3
drop _merge
sort id_SOC rank
erase $dta/temp.dta 

* 2) Compute the average risks 
sort id_SOC risk_S_occ
by id_SOC: gen risk_rank = _n
sort id_SOC rank

* gen terciles
sort aut_risk rank
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

********** T tests difference in weighted means between terciles
	preserve
		keep if rank==1
		ttest aut_risk == risk_S_occ if tcrisk==1
		ttest aut_risk == risk_S_occ if tcrisk==2
		ttest aut_risk == risk_S_occ if tcrisk==3
		
		reg aut_risk ib1.tcrisk [w=im_empl_18]
		reg aut_risk ib2.tcrisk [w=im_empl_18]
		reg aut_risk ib3.tcrisk [w=im_empl_18]
		reg risk_S_occ ib1.tcrisk [w=im_empl_18]
		reg risk_S_occ ib2.tcrisk [w=im_empl_18]
		reg risk_S_occ ib3.tcrisk [w=im_empl_18]

		reg D1_d_skills ib1.tcrisk [w=im_empl_18]
		reg D1_d_skills ib2.tcrisk [w=im_empl_18]
		reg D1_d_skills ib3.tcrisk [w=im_empl_18]

		reg D2_d_know ib1.tcrisk [w=im_empl_18]
		reg D2_d_know ib2.tcrisk [w=im_empl_18]
		reg D2_d_know ib3.tcrisk [w=im_empl_18]
	restore


* current weighted risk by tercile
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen topratio_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if rank==1  
egen totD1 = sum(wD1) if rank==1 , by(tcrisk)
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 , by(tcrisk)
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18 if risk_rank==1 
egen total_emp = sum(im_empl_18)  if risk_rank==1 , by(tcrisk)  
egen totrisk = sum(wrisk) if risk_rank==1 , by(tcrisk)
gen toprisk_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  , by(tcrisk)
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 , by(tcrisk)
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

ereplace toprisk_avgrisk = mean(toprisk_avgrisk) , by(tcrisk)
ereplace toprisk_avgD1_skill = mean(toprisk_avgD1_skill) , by(tcrisk)
ereplace toprisk_avgD2_know = mean(toprisk_avgD2_know) , by(tcrisk)

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know
duplicates drop

keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
foreach var of varlist avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know  {
replace `var' =  round(`var',0.001)
}
list 

export excel using $output/figures_tables_in_the_paper/Table_S5_P2a_retreff_square_risk_change.xlsx, replace firstrow(variables)   

***************************************************************
clear all

**** GET PERCENTILES

use $project/dta/retreffdistances.dta , clear
foreach var in aut_risk  D3_d_risk D1_d_skills D2_d_know {
	preserve
		xtile newvar = `var',nq(100)
		gen perc_`var' = newvar
		drop newvar
		keep `var' perc_`var'
		duplicates drop
		save $dta/temp`var'.dta , replace
	restore
}
use $dta/tempaut_risk.dta, clear
rename aut_risk risk_S_occ
rename perc_aut_risk perc_risk_S_occ
save $dta/temprisk_S_occ.dta , replace

**** START
use $dta/retreff_square_resilience_with_retreffdistances.dta , clear
keep id_SOC
duplicates drop
g code = substr(id_SOC,1,7)
sort code id_SOC
save $dta/temp.dta ,replace

* 1) get employment information
clear
import excel using $input\BLS_data\national_M2018_dl.xlsx, first
rename TOT_EMP empl_18
rename OCC_CODE code
keep if OCC_GROUP == "detailed"
keep code empl_18
sort code
duplicates drop
merge 1:m code using $dta/temp.dta // 91% matched
tab _merge
keep if _merge==3
drop _merge
sort code id_SOC
egen subgroups = count(code) , by(code)
gen im_empl_18 = empl_18/subgroups
keep id_SOC im_empl_18
merge 1:m id_SOC using $dta/retreff_square_resilience_with_retreffdistances.dta // 97% matched
tab _merge
keep if _merge==3
drop _merge
sort id_SOC rank
erase $dta/temp.dta 

* 2) Compute the average risks 
sort id_SOC risk_S_occ
by id_SOC: gen risk_rank = _n
sort id_SOC rank

** get percentiles
foreach var in aut_risk risk_S_occ D3_d_risk D1_d_skills D2_d_know {
	merge m:1 `var' using $dta/temp`var'.dta
	drop `var'
	rename perc_`var' `var'
	keep if _merge==3
	drop _merge
	erase $dta/temp`var'.dta
}
	
* gen terciles
sort aut_risk rank
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

********** T tests difference in weighted means between terciles
	preserve
		keep if rank==1
		ttest aut_risk == risk_S_occ if tcrisk==1
		ttest aut_risk == risk_S_occ if tcrisk==2
		ttest aut_risk == risk_S_occ if tcrisk==3
		
		reg aut_risk ib1.tcrisk [w=im_empl_18]
		reg aut_risk ib2.tcrisk [w=im_empl_18]
		reg aut_risk ib3.tcrisk [w=im_empl_18]
		reg risk_S_occ ib1.tcrisk [w=im_empl_18]
		reg risk_S_occ ib2.tcrisk [w=im_empl_18]
		reg risk_S_occ ib3.tcrisk [w=im_empl_18]

		reg D1_d_skills ib1.tcrisk [w=im_empl_18]
		reg D1_d_skills ib2.tcrisk [w=im_empl_18]
		reg D1_d_skills ib3.tcrisk [w=im_empl_18]

		reg D2_d_know ib1.tcrisk [w=im_empl_18]
		reg D2_d_know ib2.tcrisk [w=im_empl_18]
		reg D2_d_know ib3.tcrisk [w=im_empl_18]
	restore


* current weighted risk by tercile
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen topratio_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if rank==1  
egen totD1 = sum(wD1) if rank==1 , by(tcrisk)
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 , by(tcrisk)
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18 if risk_rank==1 
egen total_emp = sum(im_empl_18)  if risk_rank==1 , by(tcrisk)  
egen totrisk = sum(wrisk) if risk_rank==1 , by(tcrisk)
gen toprisk_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  , by(tcrisk)
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 , by(tcrisk)
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

ereplace toprisk_avgrisk = mean(toprisk_avgrisk) , by(tcrisk)
ereplace toprisk_avgD1_skill = mean(toprisk_avgD1_skill) , by(tcrisk)
ereplace toprisk_avgD2_know = mean(toprisk_avgD2_know) , by(tcrisk)

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know
duplicates drop


keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
drop topratio_avgD1_skill topratio_avgD2_know 
foreach var of varlist avgrisk topratio_avgrisk change {
replace `var' =  round(`var')
}
list 

export excel using $output/figures_tables_in_the_paper/Table_S5_P2b_retreff_square_risk_change_percentiles.xlsx, replace firstrow(variables)  
}
*



*********************************************************************
*****P3 - SQRT
{
clear all
use $dta/retreff_sqrt_resilience_with_retreffdistances.dta , clear
keep id_SOC
duplicates drop
g code = substr(id_SOC,1,7)
sort code id_SOC
save $dta/temp.dta ,replace

* 1) get employment information
clear
import excel using $input\BLS_data\national_M2018_dl.xlsx, first
rename TOT_EMP empl_18
rename OCC_CODE code
keep if OCC_GROUP == "detailed"
keep code empl_18
sort code
duplicates drop
merge 1:m code using $dta/temp.dta // 91% matched
tab _merge
keep if _merge==3
drop _merge
sort code id_SOC
egen subgroups = count(code) , by(code)
gen im_empl_18 = empl_18/subgroups
keep id_SOC im_empl_18
merge 1:m id_SOC using $dta/retreff_sqrt_resilience_with_retreffdistances.dta // 97% matched
tab _merge
keep if _merge==3
drop _merge
sort id_SOC rank
erase $dta/temp.dta 

* 2) Compute the average risks 
sort id_SOC risk_S_occ
by id_SOC: gen risk_rank = _n
sort id_SOC rank

* gen terciles
sort aut_risk rank
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

********** T tests difference in weighted means between terciles
	preserve
		keep if rank==1
		ttest aut_risk == risk_S_occ if tcrisk==1
		ttest aut_risk == risk_S_occ if tcrisk==2
		ttest aut_risk == risk_S_occ if tcrisk==3
		
		reg aut_risk ib1.tcrisk [w=im_empl_18]
		reg aut_risk ib2.tcrisk [w=im_empl_18]
		reg aut_risk ib3.tcrisk [w=im_empl_18]
		reg risk_S_occ ib1.tcrisk [w=im_empl_18]
		reg risk_S_occ ib2.tcrisk [w=im_empl_18]
		reg risk_S_occ ib3.tcrisk [w=im_empl_18]

		reg D1_d_skills ib1.tcrisk [w=im_empl_18]
		reg D1_d_skills ib2.tcrisk [w=im_empl_18]
		reg D1_d_skills ib3.tcrisk [w=im_empl_18]

		reg D2_d_know ib1.tcrisk [w=im_empl_18]
		reg D2_d_know ib2.tcrisk [w=im_empl_18]
		reg D2_d_know ib3.tcrisk [w=im_empl_18]
	restore


* current weighted risk by tercile
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen topratio_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if rank==1  
egen totD1 = sum(wD1) if rank==1 , by(tcrisk)
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 , by(tcrisk)
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18 if risk_rank==1 
egen total_emp = sum(im_empl_18)  if risk_rank==1 , by(tcrisk)  
egen totrisk = sum(wrisk) if risk_rank==1 , by(tcrisk)
gen toprisk_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  , by(tcrisk)
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 , by(tcrisk)
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

ereplace toprisk_avgrisk = mean(toprisk_avgrisk) , by(tcrisk)
ereplace toprisk_avgD1_skill = mean(toprisk_avgD1_skill) , by(tcrisk)
ereplace toprisk_avgD2_know = mean(toprisk_avgD2_know) , by(tcrisk)

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know
duplicates drop

keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
foreach var of varlist avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know  {
replace `var' =  round(`var',0.001)
}
list 

export excel using $output/figures_tables_in_the_paper/Table_S5_P3a_retreff_sqrt_risk_change.xlsx, replace firstrow(variables)  

***************************************************************

clear all

**** GET PERCENTILES

use $project/dta/retreffdistances.dta , clear
foreach var in aut_risk  D3_d_risk D1_d_skills D2_d_know {
	preserve
		xtile newvar = `var',nq(100)
		gen perc_`var' = newvar
		drop newvar
		keep `var' perc_`var'
		duplicates drop
		save $dta/temp`var'.dta , replace
	restore
}
use $dta/tempaut_risk.dta, clear
rename aut_risk risk_S_occ
rename perc_aut_risk perc_risk_S_occ
save $dta/temprisk_S_occ.dta , replace


**** START
use $dta/retreff_sqrt_resilience_with_retreffdistances.dta , clear
keep id_SOC
duplicates drop
g code = substr(id_SOC,1,7)
sort code id_SOC
save $dta/temp.dta ,replace

* 1) get employment information
clear
import excel using $input\BLS_data\national_M2018_dl.xlsx, first
rename TOT_EMP empl_18
rename OCC_CODE code
keep if OCC_GROUP == "detailed"
keep code empl_18
sort code
duplicates drop
merge 1:m code using $dta/temp.dta // 91% matched
tab _merge
keep if _merge==3
drop _merge
sort code id_SOC
egen subgroups = count(code) , by(code)
gen im_empl_18 = empl_18/subgroups
keep id_SOC im_empl_18
merge 1:m id_SOC using $dta/retreff_sqrt_resilience_with_retreffdistances.dta // 97% matched
tab _merge
keep if _merge==3
drop _merge
sort id_SOC rank
erase $dta/temp.dta 

* 2) Compute the average risks 
sort id_SOC risk_S_occ
by id_SOC: gen risk_rank = _n
sort id_SOC rank


** get percentiles
foreach var in aut_risk risk_S_occ D3_d_risk D1_d_skills D2_d_know {
	merge m:1 `var' using $dta/temp`var'.dta
	drop `var'
	rename perc_`var' `var'
	keep if _merge==3
	drop _merge
	erase $dta/temp`var'.dta
}
	
/*
		foreach var in aut_risk  D3_d_risk D1_d_skills D2_d_know {
			xtile newvar = `var',nq(100)
			replace `var' = newvar
			drop newvar
		}
		preserve
			keep Occupation aut_risk 
			duplicates drop
			rename Occupation S_occ
			rename aut_risk percentile
			save temp.dta, replace
		restore
		merge m:1 S_occ using temp.dta
		keep if _merge==3
		drop _merge
		replace risk_S_occ = percentile
		drop percentile
*/



* gen terciles
sort aut_risk rank
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

********** T tests difference in weighted means between terciles
	preserve
		keep if rank==1
		ttest aut_risk == risk_S_occ if tcrisk==1
		ttest aut_risk == risk_S_occ if tcrisk==2
		ttest aut_risk == risk_S_occ if tcrisk==3
		
		reg aut_risk ib1.tcrisk [w=im_empl_18]
		reg aut_risk ib2.tcrisk [w=im_empl_18]
		reg aut_risk ib3.tcrisk [w=im_empl_18]
		reg risk_S_occ ib1.tcrisk [w=im_empl_18]
		reg risk_S_occ ib2.tcrisk [w=im_empl_18]
		reg risk_S_occ ib3.tcrisk [w=im_empl_18]

		reg D1_d_skills ib1.tcrisk [w=im_empl_18]
		reg D1_d_skills ib2.tcrisk [w=im_empl_18]
		reg D1_d_skills ib3.tcrisk [w=im_empl_18]

		reg D2_d_know ib1.tcrisk [w=im_empl_18]
		reg D2_d_know ib2.tcrisk [w=im_empl_18]
		reg D2_d_know ib3.tcrisk [w=im_empl_18]
	restore


* current weighted risk by tercile
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  , by(tcrisk)
egen totrisk = sum(wrisk) if rank==1 , by(tcrisk)
gen topratio_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if rank==1  
egen totD1 = sum(wD1) if rank==1 , by(tcrisk)
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 , by(tcrisk)
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18 if risk_rank==1 
egen total_emp = sum(im_empl_18)  if risk_rank==1 , by(tcrisk)  
egen totrisk = sum(wrisk) if risk_rank==1 , by(tcrisk)
gen toprisk_avgrisk = totrisk/total_emp 
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  , by(tcrisk)
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 , by(tcrisk)
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

ereplace toprisk_avgrisk = mean(toprisk_avgrisk) , by(tcrisk)
ereplace toprisk_avgD1_skill = mean(toprisk_avgD1_skill) , by(tcrisk)
ereplace toprisk_avgD2_know = mean(toprisk_avgD2_know) , by(tcrisk)

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know
duplicates drop


keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
drop topratio_avgD1_skill topratio_avgD2_know 
foreach var of varlist avgrisk topratio_avgrisk change {
replace `var' =  round(`var')
}
list 

export excel using $output/figures_tables_in_the_paper/Table_S5_P3b_retreff_sqrt_risk_change_percentiles.xlsx, replace firstrow(variables) 

}
*


*********************** Table S6
{
clear all
*** direction of transitions.
use $dta/transitions.dta

rename soc1 occ_code
merge m:1 occ_code using "$dta/temp2003.dta"
rename occ_code soc1

tab _merge
keep if _merge == 3


sort soc1 ari1
by soc1: g first =  _n==1
su tot_emp if first == 1
g double eShare = tot_emp / r(sum)
su eShare if first == 1
di r(sum)

xtile tcrisk1 = ari1 , nq(3)

sort soc2 ari2
xtile tcrisk2 = ari2 , nq(3)

* coding of risk index: negative means more risk, positive means less risk
* inverse sorting by risk

generate retEff = sqrt(D1_d_skills*D2_d_know)
g ri = D3_d_risk / retEff
gsort soc1 -ri
by soc1: g recommended = _n == 1


qui su transition_share
g transNorm = transition_share / r(sum)
g trans100K = transition_share * tot_emp / 100000
g transitions = transition_share * tot_emp


version 10: table tcrisk1 tcrisk2 , c(sum trans100K)
*version 10: table tcrisk1 tcrisk2, c(mean transitions mean ri  mean D3_d_risk mean retEff freq)
*version 10: table tcrisk1 tcrisk2 if recommended == 1, c(mean transitions mean ri mean D3_d_risk mean retEff freq )	
collapse (sum) trans100K , by(tcrisk1 tcrisk2)
reshape wide trans100K , i(tcrisk1) j(tcrisk2)
list 
export excel using $output/figures_tables_in_the_paper/Table_S6_transitions.xlsx, replace firstrow(variables)  
}
