clear

******* cross Resilience
******* Fabrizio Colella

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

use $dta/distances.dta , clear

* get the top 3 occupations
gen magic_number = D3_d_risk / (D1_d_skills*D2_d_know)
gsort Occupation -magic_number
by Occupation: gen rank = _n
keep if rank<4

preserve
rename occ2 S_occ
rename ris2 risk_S_occ
save $dta/resilience_with_distances.dta ,replace
export excel using $output/resilience_with_distances.xlsx, replace firstrow(variables)  
restore

* reshape
gen S_occ1 = occ2 if Occupation==Occupation[_n+1] & Occupation==Occupation[_n+2]
gen R_occ1 = ris2 if Occupation==Occupation[_n+1] & Occupation==Occupation[_n+2]
gen S_occ2 = occ2[_n+1] if Occupation==Occupation[_n+1] & Occupation==Occupation[_n+2]
gen R_occ2 = ris2[_n+1] if Occupation==Occupation[_n+1] & Occupation==Occupation[_n+2]
gen S_occ3 = occ2[_n+2] if Occupation==Occupation[_n+1] & Occupation==Occupation[_n+2]
gen R_occ3 = ris2[_n+2] if Occupation==Occupation[_n+1] & Occupation==Occupation[_n+2]
keep if S_occ1 == occ2

drop occ2 ris2 D3_d_risk D2_d_know D1_d_skills magic_number rank
sort Occupation

save $dta/resilience.dta ,replace
export excel using $output/resilience.xlsx, replace firstrow(variables)  



********************************************************************************
* PART B: Summary Statistics
********************************************************************************

* 0) open database
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

* current weighted risk by fam name
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp_fam = sum(im_empl_18)  if rank==1  , by(Fam_Name)
egen totrisk_fam = sum(wrisk) if rank==1 , by(Fam_Name)
gen avgrisk_fam = totrisk_fam/total_emp_fam
drop wrisk total_emp_fam totrisk_fam

* best ratio weighted risk by fam name
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp_fam = sum(im_empl_18)  if rank==1  , by(Fam_Name)
egen totrisk_fam = sum(wrisk) if rank==1 , by(Fam_Name)
gen topratio_avgrisk_fam = totrisk_fam/total_emp_fam
gen wD1 = D1_d_skills*im_empl_18 if rank==1 
egen totD1_fam = sum(wD1) if rank==1 , by(Fam_Name)
gen topratio_avgD1_skill_fam = totD1_fam/total_emp_fam
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2_fam = sum(wD2) if rank==1 , by(Fam_Name)
gen topratio_avgD2_know_fam = totD2_fam/total_emp_fam
drop wrisk total_emp_fam totrisk_fam totrisk_fam wD1 totD1_fam wD2 totD2_fam 

* best risk weighted risk by fam name
gen wrisk = risk_S_occ*im_empl_18
egen total_emp_fam = sum(im_empl_18)  if risk_rank==1  , by(Fam_Name)
egen totrisk_fam = sum(wrisk) if risk_rank==1 , by(Fam_Name)
gen toprisk_avgrisk_fam = totrisk_fam/total_emp_fam
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1_fam = sum(wD1) if risk_rank==1  , by(Fam_Name)
gen toprisk_avgD1_skill_fam = totD1_fam/total_emp_fam
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2_fam = sum(wD2) if risk_rank==1  , by(Fam_Name)
gen toprisk_avgD2_know_fam = totD2_fam/total_emp_fam
drop wrisk total_emp_fam totrisk_fam totrisk_fam wD1 totD1_fam wD2 totD2_fam 

* reshape
egen toprisk_avgrisk_fam2 = mean(toprisk_avgrisk_fam)  , by(Fam_Name)
drop toprisk_avgrisk_fam
rename toprisk_avgrisk_fam2 toprisk_avgrisk_fam
egen toprisk_avgD1_skill_fam2 = mean(toprisk_avgD1_skill_fam)  , by(Fam_Name)
drop toprisk_avgD1_skill_fam
rename toprisk_avgD1_skill_fam2 toprisk_avgD1_skill_fam
egen toprisk_avgD2_know_fam2 = mean(toprisk_avgD2_know_fam)  , by(Fam_Name)
drop toprisk_avgD2_know_fam
rename toprisk_avgD2_know_fam2 toprisk_avgD2_know_fam
keep if rank==1

egen total_emp_fam = sum(im_empl_18)  if rank==1  , by(Fam_Name)

keep Fam_Name avgrisk_fam topratio_avgrisk_fam toprisk_avgrisk_fam total_emp_fam ///
	toprisk_avgD1_skill_fam topratio_avgD1_skill_fam toprisk_avgD2_know_fam ///
	topratio_avgD2_know_fam total_emp_fam 
duplicates drop

export excel using $output/risk_change_family.xlsx, replace firstrow(variables)  


/*
**************** Table Summary results Resilience

* 0) open database
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

* current weighted risk by occ
gen wrisk = aut_risk*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  
egen totrisk = sum(wrisk) if rank==1 
gen avgrisk = totrisk/total_emp
drop wrisk total_emp totrisk

* best ratio weighted risk TOTAL
gen wrisk = risk_S_occ*im_empl_18 if rank==1 
egen total_emp = sum(im_empl_18)  if rank==1  
egen totrisk = sum(wrisk) if rank==1 
gen topratio_avgrisk = totrisk/total_emp
gen wD1 = D1_d_skills*im_empl_18 if rank==1 
egen totD1 = sum(wD1) if rank==1 
gen topratio_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if rank==1 
egen totD2 = sum(wD2) if rank==1 
gen topratio_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* best risk weighted risk  TOTAL
gen wrisk = risk_S_occ*im_empl_18
egen total_emp = sum(im_empl_18)  if risk_rank==1  
egen totrisk = sum(wrisk) if risk_rank==1 
gen toprisk_avgrisk = totrisk/total_emp
gen wD1 = D1_d_skills*im_empl_18 if risk_rank==1 
egen totD1 = sum(wD1) if risk_rank==1  
gen toprisk_avgD1_skill = totD1/total_emp
gen wD2 = D2_d_know*im_empl_18 if risk_rank==1 
egen totD2 = sum(wD2) if risk_rank==1 
gen toprisk_avgD2_know = totD2/total_emp
drop wrisk total_emp totrisk totrisk wD1 totD1 wD2 totD2 

* reshape
drop if _n>1
keep avgrisk topratio_avgrisk topratio_avgD1_skill topratio_avgD2_know ///
toprisk_avgrisk toprisk_avgD1_skill toprisk_avgD2_know

export excel using $output/risk_change_total.xlsx, replace firstrow(variables)  
*/


