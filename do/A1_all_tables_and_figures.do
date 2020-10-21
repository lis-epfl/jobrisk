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

export excel using $output/figures_tables_in_the_paper/Table2_examples.xlsx, replace firstrow(variables)  

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
xtitle(Distance in Human Abilities) 
graph export $output/figures_tables_in_the_paper/Figure2a_distAbil.png , replace width(2400) height(1800)

hist D2_d_know if D1_d_skills !=0, percent fcolor(ebblue) lcolor(white) ///
graphregion(color(white) lwidth(large))width(0.025) xlabel(0(0.2)1)  ///
xtitle(Distance in Knowledge) 
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
foreach var in aut_risk  {
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
erase temp.dta

drop D3_d_risk D1_d_skills D2_d_know 
preserve
	use $dta/distances.dta , clear
	foreach var in D3_d_risk D1_d_skills D2_d_know {
		xtile newvar = `var',nq(100)
		replace `var' = newvar
		drop newvar
	}
	rename occ2 S_occ
	keep Occupation S_occ D3_d_risk D1_d_skills D2_d_know
	save temp.dta, replace
restore
merge 1:1 Occupation S_occ using temp.dta
keep if _merge==3
drop _merge
erase temp.dta


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

