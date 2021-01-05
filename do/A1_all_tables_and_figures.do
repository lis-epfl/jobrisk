******************************************************************************
******* This do files generate all the figures in the paper
******************************************************************************

*** the order follows the order of figures and tables in the paper
*** tables 1 and 4 are nor reported as they are not the result of the computations

clear

******* cross Risk Measures
******* Fabrizio Colella

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

*********************** Table 2
{
clear all
use $dta/risk.dta

keep share share_uto share_dys
rename share ARI
sort ARI
order ARI share_uto share_dys

keep if _n == 1 | _n==122 | _n==203 | _n==967
list

export excel using $output/Table2_examples.xlsx, replace firstrow(variables)  

}
*

*********************** Figure 1
{
clear all
use $dta/risk.dta

egen a = mean(share) , by(Fam_Name)
graph box share, over(Fam_Name, sort(a) lab(angle(35) labsize(vsmall)) ) ///
box(1, fcolor(ltblue%20) lcolor(ebblue) lwidth(medthick)) medtype(cline) ///
medline(lcolor(ebblue) lwidth(medthick)) marker(1, mcolor(%0) msize(vtiny)) ///
graphregion(color(white) lwidth(large) margin(16 3 3 3))  ytitle("") 
graph export $output/figures_tables_in_the_paper/Figure1_ARIbyjobfamilies.png , replace width(2400) height(1800)
}
*

*********************** Figure 2
{
clear all
use $dta/distances.dta

hist D1_d_skills if D1_d_skills !=0, percent fcolor(ebblue) lcolor(white) ///
graphregion(color(white) lwidth(large))width(0.025) xlabel(0(0.2)1)  ///
xtitle(Job distance by human abilities) ytitle(Job percentage) ///
ylabel(0 "0" 2 "2" 4 "4" 6 "6" 8 "8" 10 "10")
graph export $output/figures_tables_in_the_paper/Figure2a_distAbil.png , replace width(2400) height(1800)

hist D2_d_know if D1_d_skills !=0, percent fcolor(ebblue) lcolor(white) ///
graphregion(color(white) lwidth(large))width(0.025) xlabel(0(0.2)1)  ///
xtitle(Job distance by knowledge) ytitle(Job percentage) ///
ylabel(0 "0" 2 "2" 4 "4" 6 "6" 8 "8" 10 "10") 
graph export $output/figures_tables_in_the_paper/Figure2b_distKnow.png , replace width(2400) height(1800)
}
*

*********************** Table 3
{
clear all
use $dta/resilience_with_distances.dta , clear
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
merge 1:m id_SOC using $dta/resilience_with_distances.dta // 97% matched
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
list 

export excel using $output/figures_tables_in_the_paper/Table3a_risk_change.xlsx, replace firstrow(variables)  

***************************************************************


clear all

**** GET PERCENTILES

use $dta/distances.dta , clear
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

use $dta/resilience_with_distances.dta , clear
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
merge 1:m id_SOC using $dta/resilience_with_distances.dta // 97% matched
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
list 

export excel using $output/figures_tables_in_the_paper/Table3b_risk_change_percentiles.xlsx, replace firstrow(variables)  
}
*



********************************************************************************
********************************************************************************
********************************************************************************

*********************** Figure 2
{
clear all
use $dta/retreffdistances.dta

hist D1_d_skills if D1_d_skills !=0, percent fcolor(ebblue) lcolor(white) ///
graphregion(color(white) lwidth(large))width(0.025) xlabel(0(0.2)1)  ///
xtitle(Retraining effort by human abilities) ytitle(Job percentage) ///
ylabel(0 "0" 2 "2" 4 "4" 6 "6" 8 "8" 10 "10")
graph export $output/figures_tables_in_the_paper/retreff_Figure2a_distAbil.png , replace width(2400) height(1800)

hist D2_d_know if D1_d_skills !=0, percent fcolor(ebblue) lcolor(white) ///
graphregion(color(white) lwidth(large))width(0.025) xlabel(0(0.2)1)  ///
xtitle(Retraining effort by knowledge) ytitle(Job percentage) ///
ylabel(0 "0" 2 "2" 4 "4" 6 "6" 8 "8" 10 "10") 
graph export $output/figures_tables_in_the_paper/retreff_Figure2b_distKnow.png , replace width(2400) height(1800)
}

*
*********************** Table 3
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
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
list 

export excel using $output/figures_tables_in_the_paper/retreff_Table3a_risk_change.xlsx, replace firstrow(variables)  

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


keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
list 

export excel using $output/figures_tables_in_the_paper/retreff_Table3b_risk_change_percentiles.xlsx, replace firstrow(variables)  
}
*



{
********** GRAPH EXAMPLE
foreach	i in "Electrical Engineering Technicians"  Economists  "Slaughterers and Meat Packers"  {
	use $dta/retreffdistances.dta , clear

	global occupation `i'

	keep if Occupation=="$occupation"
	gen D3_d_riskP = D3_d_risk if D3_d_risk>0
	gen D3_d_riskN = D3_d_risk if D3_d_risk<=0
	
	gen geo_mean = (sqrt(D1_d_skills * D2_d_know))
	gen magic_number = D3_d_risk / geo_mean
	gsort Occupation -magic_number
	gen line = D3_d_risk if _n==1  | D3_d_risk==0 & geo_mean==0
	gen best = D3_d_risk if _n==1  
	gen origin = 0 if (D3_d_risk == 0 &  geo_mean==0)
	
	replace D3_d_riskN = -D3_d_riskN
	replace D3_d_riskP = -D3_d_riskP
	replace line = -line
	replace best = -best

	/*
	twoway (scatter D3_d_riskN geo_mean ,  mcolor( gs12) ) ///
		(scatter D3_d_riskP geo_mean ,  mcolor(eltgreen) ) ///
		(line line geo_mean , lpattern(dash) lcolor(black)) ///
		(scatter best geo_mean , msymbol(diamond) mcolor(red) mlabel(occ2))  /// 
		(scatter origin geo_mean , msymbol(square) mcolor(black)   /// 
		xtitle("Retraining Effort (geometric mean)") /// 
		ytitle("Change in Risk") ///
		title("All alternatives for $occupation") ///
		legend(off) graphregion(color(white))) 
	*/
	twoway (scatter D3_d_riskN geo_mean ,  mcolor( gs12) ) ///
		(scatter D3_d_riskP geo_mean ,  mcolor(eltgreen) ) ///
		(line line geo_mean , lpattern(dash) lcolor(black)) ///
		(scatter best geo_mean , msymbol(diamond) mcolor(orange_red) mlabel(occ2) mlabcolor(orange_red) mlabt(tick_label) )  /// 
		(scatter origin geo_mean , msymbol(diamond) mcolor(black)  mlabel(Occupation) mlabcolor(black) mlabt(tick_label) /// 
		xtitle("Retraining effort") /// 
		ytitle("ARI difference") ///
		legend(off) graphregion(color(white))) 
	graph export "$output/figures_tables_in_the_paper/retreff_Change_$occupation.png" , replace width(2400) height(1800)
}
}




