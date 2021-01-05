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

{
clear all
use $dta/retreffdistances.dta , clear
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
merge 1:m id_SOC using $dta/retreffdistances.dta  // 97% matched
rename ris2 risk_S_occ
tab _merge
keep if _merge==3
drop _merge
sort id_SOC risk_S_occ
erase $dta/temp.dta 


* gen terciles
sort aut_risk risk_S_occ
by aut_risk: gen rankrisk = _n
xtile tcrisk = aut_risk if rank==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)

preserve
keep Occupation tcrisk
rename Occupation occ2
rename tcrisk tcrisk2
duplicates drop
save  $dta/temp.dta , replace
restore
merge m:1 occ2 using $dta/temp.dta 
keep if _merge==3
drop _merge
keep if tcrisk == tcrisk2

sort id_SOC risk_S_occ
by id_SOC: gen rank = _n
keep if rank==1


********** T tests difference in weighted means between terciles
	preserve
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

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
duplicates drop

keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
list 

export excel using $output/figures_tables_in_the_paper/retreff_Table4a_counterfactual_lowest_within_range.xlsx, replace firstrow(variables)  
}
***************************************************************


********** percentiles
{
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
clear all
use $dta/retreffdistances.dta , clear
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
merge 1:m id_SOC using $dta/retreffdistances.dta  // 97% matched
rename ris2 risk_S_occ
tab _merge
keep if _merge==3
drop _merge
sort id_SOC risk_S_occ
erase $dta/temp.dta 


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
sort id_SOC risk_S_occ
by id_SOC: gen rankrisk = _n
xtile tcrisk = aut_risk if rankrisk==1 , nq(3) 
ereplace tcrisk = mean(tcrisk) , by(id_SOC)


preserve
keep Occupation tcrisk
rename Occupation occ2
rename tcrisk tcrisk2
duplicates drop
save  $dta/temp.dta , replace
restore
merge m:1 occ2 using $dta/temp.dta 
keep if _merge==3
drop _merge
keep if tcrisk == tcrisk2

sort id_SOC risk_S_occ
by id_SOC: gen rank = _n
keep if rank==1


********** T tests difference in weighted means between terciles
	preserve
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

* reshape
drop if avgrisk==.
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
duplicates drop

keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know 
gen change = avgrisk - topratio_avgrisk
order avgrisk topratio_avgrisk change topratio_avgD1_skill topratio_avgD2_know 
gsort -avgrisk
list 

export excel using $output/figures_tables_in_the_paper/retreff_Table4b_counterfactual_lowest_within_range_percentiles.xlsx, replace firstrow(variables)  
}


{
********** GRAPH EXAMPLE
/*
foreach	i in Economists "Electrical Engineering Technicians" "Slaughterers and Meat Packers"  {
	use $dta/retreffdistances.dta , clear

	global occupation `i'
	
	* gen terciles
	rename ris2 risk_S_occ
	sort id_SOC risk_S_occ
	by id_SOC: gen rankrisk = _n
	xtile tcrisk = aut_risk if rankrisk==1 , nq(3) 
	ereplace tcrisk = mean(tcrisk) , by(id_SOC)
	
	preserve
	keep Occupation tcrisk
	rename Occupation occ2
	rename tcrisk tcrisk2
	duplicates drop
	save  $dta/temp.dta , replace
	restore
	merge m:1 occ2 using $dta/temp.dta 
	erase  $dta/temp.dta 
	keep if _merge==3
	drop _merge
	*keep if tcrisk == tcrisk2

	keep if Occupation=="$occupation"
	gen D3_d_riskP = D3_d_risk if D3_d_risk>0
	gen D3_d_riskN = D3_d_risk if D3_d_risk<=0
	gen geo_mean = (sqrt(D1_d_skills * D2_d_know))
	
	egen pick = min(risk_S_occ) if tcrisk == tcrisk2
	gen line = D3_d_risk if pick==risk_S_occ  | D3_d_risk==0 & geo_mean==0
	gen best = D3_d_risk if pick==risk_S_occ  
	
	twoway (scatter D3_d_riskN geo_mean ,  mcolor( gs12) ) ///
		(scatter D3_d_riskP geo_mean ,  mcolor(eltgreen) ) ///
		(line line geo_mean , lpattern(dash) lcolor(black)) ///
		(scatter best geo_mean , msymbol(diamond) mcolor(red) mlabel(occ2)  /// 
		xtitle("Geometric Mean of Retreining Efforts") /// 
		ytitle("Distance in Risk") ///
		title("All alternatives for $occupation") ///
		legend(off) graphregion(color(white))) 
*	graph export "$output/figures_tables_in_the_paper/retreff_Change_$occupation.png" , replace width(2400) height(1800)
*/
}





********** GRAPH EXAMPLE
foreach	i in Economists "Electrical Engineering Technicians" "Slaughterers and Meat Packers"  {
	use $dta/retreffdistances.dta , clear

	global occupation `i'
	
	* gen terciles
	rename ris2 risk_S_occ
	sort id_SOC risk_S_occ
	by id_SOC: gen rankrisk = _n
	xtile tcrisk = aut_risk if rankrisk==1 , nq(3) 
	ereplace tcrisk = mean(tcrisk) , by(id_SOC)
	
	preserve
	keep Occupation tcrisk
	rename Occupation occ2
	rename tcrisk tcrisk2
	duplicates drop
	save  $dta/temp.dta , replace
	restore
	merge m:1 occ2 using $dta/temp.dta 
	erase  $dta/temp.dta 
	keep if _merge==3
	drop _merge
	*keep if tcrisk == tcrisk2

	keep if Occupation=="$occupation"
	*gen D3_d_riskP = D3_d_risk if D3_d_risk>0
	*gen D3_d_riskN = D3_d_risk if D3_d_risk<=0
	gen D3_d_riskP = D3_d_risk if tcrisk == tcrisk2
	gen D3_d_riskN = D3_d_risk if tcrisk != tcrisk2
	gen geo_mean = (sqrt(D1_d_skills * D2_d_know))
	
	egen pick = min(risk_S_occ) if tcrisk == tcrisk2
	gen line = D3_d_risk if pick==risk_S_occ  | D3_d_risk==0 & geo_mean==0
	gen best = D3_d_risk if pick==risk_S_occ  
	
	twoway (scatter D3_d_riskN geo_mean ,  mcolor( gs12) ) ///
		(scatter D3_d_riskP geo_mean ,  mcolor(eltgreen) ) ///
		(line line geo_mean , lpattern(dash) lcolor(black)) ///
		(scatter best geo_mean , msymbol(diamond) mcolor(red) mlabel(occ2)  /// 
		xtitle("Retraining Effort (geometric mean)") /// 
		ytitle("Distance in Risk") ///
		title("All alternatives for $occupation") ///
		legend(off) graphregion(color(white))) 
	graph export "$output/figures_tables_in_the_paper/retreff_counterfactual_Change_$occupation.png" , replace width(2400) height(1800)
}














