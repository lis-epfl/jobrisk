clear

******* cross Distances
******* Fabrizio Colella

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

*********************
* 1) distance in risk
clear
use $dta/risk.dta 
keep ONETSOCCode Occupation share Fam_Name
rename ONETSOCCode id_SOC
gsort share
rename share aut_risk
save temp.dta ,replace

local j = _N
di `j'

gen occ2 = Occupation
gen ris2 = aut_risk
forvalues i = 0(1)`j' {
	local a = `i'*`j'
	di `i'
*	di `a'
	qui	append using temp.dta
	qui	replace occ2 = Occupation[_n+`i'+1] if _n>`a'
	qui	replace ris2 = aut_ris[_n+`i'+1] if _n>`a'
}
drop if _n>`j'*`j'
erase temp.dta

gen D3_d_risk = round(aut_risk - ris2,0.00001)

save $dta/distances.dta , replace


*********************
* 2) distance in ab and sk
clear
use $dta/ab_sk.dta 
keep ONETSOCCode Occupation ElementID hLevel hImp
sort ONETSOCCode ElementID
save temp.dta ,replace

preserve
keep Occupation 
gen occ2= Occupation 
gen D1_d_skills = .
drop if _n>0
save $dta/dist_skill_temp , replace
restore

local t = _N
local j = (`t'/87)-1
di `j'

gen occ2 = Occupation
gen El2 = ElementID
gen hLev2 = hLevel
gen hImp2 = hImp

forvalues i = 0(1)`j' {
	preserve
	local a = `i'*`j'*87
	di `i'
*	di `a'
	qui	append using temp.dta
	qui	replace occ2 = Occupation[_n+(`i'*87)+87] //if _n>`a'
*	qui	replace El2 = ElementID[_n+(`i'*87)+87] //if _n>`a'
	qui	replace hLev2 = hLevel[_n+(`i'*87)+87] //if _n>`a'
	qui	replace hImp2 = hImp[_n+(`i'*87)+87] //if _n>`a'
	qui keep if _n<=`t'
	gen simLevel = normalden(5*(hLevel-hLev2))/normalden(0)
	gen simImp = normalden(5*(hImp-hImp2))/normalden(0)
	gen D1_d_skills = (1-(simImp*simLevel))
	qui replace  D1_d_skills = . if hImp<=0 & hImp2<=0
	collapse (mean) D1_d_skills , by(Occupation occ2)
	qui replace D1_d_skills = round(D1_d_skills,0.00001)
	append using $dta/dist_skill_temp
	sort Occupation occ2
	qui save $dta/dist_skill_temp , replace
	restore
}




*********************
* 3) distance in know
clear
use $dta/know.dta 
keep ONETSOCCode Occupation ElementID hLevel hImp
sort ONETSOCCode ElementID
save temp.dta ,replace

preserve
keep Occupation 
gen occ2= Occupation 
gen D2_d_know = .
drop if _n>0
save $dta/dist_know_temp , replace
restore

local t = _N
local j = (`t'/33)-1
di `j'

gen occ2 = Occupation
gen El2 = ElementID
gen hLev2 = hLevel
gen hImp2 = hImp

forvalues i = 0(1)`j' {
	preserve
	local a = `i'*`j'*33
	di `i'
*	di `a'
	qui	append using temp.dta
	qui	replace occ2 = Occupation[_n+(`i'*33)+33] //if _n>`a'
*	qui	replace El2 = ElementID[_n+(`i'*33)+33] //if _n>`a'
	qui	replace hLev2 = hLevel[_n+(`i'*33)+33] //if _n>`a'
	qui	replace hImp2 = hImp[_n+(`i'*33)+33] //if _n>`a'
	qui keep if _n<=`t'
	gen simLevel = normalden(5*(hLevel-hLev2))/normalden(0)
	gen simImp = normalden(5*(hImp-hImp2))/normalden(0)
	gen D2_d_know = (1-(simImp*simLevel))
	qui replace  D2_d_know = . if hImp<=0 & hImp2<=0
	collapse (mean) D2_d_know , by(Occupation occ2)
	qui replace D2_d_know = round(D2_d_know,0.00001)
	append using $dta/dist_know_temp
	sort Occupation occ2
	qui save $dta/dist_know_temp , replace
	restore
}

*** merge
clear
use $dta/distances.dta 
merge 1:1 Occupation occ2 using $dta/dist_skill_temp , keep(3) nogenerate
merge 1:1 Occupation occ2 using $dta/dist_know_temp , keep(3) nogenerate
save $dta/distances.dta , replace
erase $dta/dist_skill_temp.dta
erase $dta/dist_know_temp.dta
