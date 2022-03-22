******* How To Compete with Robots
******* Science Robotics Replication Files
******* Fabrizio Colella - Rafael Lalive
******* Februrary 2022

******* Risk Measures - additional

*******************************************************************************

clear

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

* random seed
clear
set seed 1234

local N 999

forv iter=1(1)`N' {
display _c `iter' " "
quietly {

*** impute TRLs using distribution of observed TRLs
use $dta/ab_sk_uniq.dta, clear
g cum = uniform()
foreach type in "Cognitive" "Physical" "Sensory" {
	cap drop temp
	cumul TRL if Type == "`type'", g(temp) equal
	replace cum = temp if Type == "`type'" & TRL <.
	}
gsort Type -cum
g iTRL = TRL
by Type: replace iTRL = iTRL[_n-1] if iTRL == .
*fl Type iTRL cum	
sort ElementID
save $dta/ab_sk_rand.dta, replace

use $dta/ab_sk.dta, clear
drop hLevel hImp TRL_weight_dys TRL_weight_uto
sort ElementID
merge m:1 ElementID using $dta/ab_sk_rand.dta
	
*** gen rescaled variables
gen hLevel = DataValueLV/Max_Anchor
replace  hLevel = 1 if hLevel>1 // only 6 cases
*
gen hImp = (DataValueIM-1)/4
* 
gen TRL_weight_dys = iTRL
replace TRL_weight_dys = 9 if TRL_weight_dys==.
*
gen TRL_weight_uto = iTRL
replace TRL_weight_uto = 0 if TRL_weight_uto==.
*
replace	TRL_weight_uto = 0.1 + (TRL_weight_uto-1)*0.9/8
replace TRL_weight_dys = 0.1 + (TRL_weight_dys-1)*0.9/8
replace TRL_weight_uto = 0 if TRL_weight_uto<0
replace TRL_weight_dys = 0 if TRL_weight_dys<0

sort ONETSOCCode ElementID

*** gen risk measure
*
gen autom_uto = hImp * logistic(0.05,TRL_weight_uto-hLevel)
gen autom_dys = hImp * logistic(0.05,TRL_weight_dys-hLevel)
egen sumhImp = sum(hImp) , by(ONETSOCCode)
gen share_uto = autom_uto/sumhImp
gen share_dys = autom_dys/sumhImp
drop sumhImp
*
egen share = rowmean(share_uto share_dys)
collapse (sum) share_uto (sum) share_dys (sum) share , by(ONETSOCCode Occupation Type)
sort ONETSOCCode Type
reshape wide share_uto share_dys share , i(ONETSOCCode Occupation) j(Type) string
egen share_uto = rowtotal(share_uto*)
egen share_dys = rowtotal(share_dys*)
egen share = rowtotal(shareCognitive sharePhysical shareSensory)
sort ONETSOCCode

* get family 
gen SOC_F = substr(ONETSOCCode, 1,2)
destring SOC_F , replace
gen SOC_Fam = "" 
replace SOC_Fam = "Management Occupations" if SOC_F == 11
replace SOC_Fam = "Business and Financial Operations Occupations"  if SOC_F == 13
replace SOC_Fam = "Computer and Mathematical Occupations" if SOC_F == 15
replace SOC_Fam = "Architecture and Engineering Occupations" if SOC_F == 17 
replace SOC_Fam = "Life, Physical, and Social Science Occupations" if SOC_F == 19
replace SOC_Fam = "Community and Social Service Occupations" if SOC_F == 21
replace SOC_Fam = "Legal Occupations" if SOC_F == 23
replace SOC_Fam = "Education, Training and Library Occupations" if SOC_F == 25
replace SOC_Fam = "Arts, Design, Entertainment, Sports, and Media Occupations" if SOC_F == 27
replace SOC_Fam = "Healthcare Practitioners and Technical Occupations" if SOC_F == 29
replace SOC_Fam = "Healthcare Support Occupations" if SOC_F == 31
replace SOC_Fam = "Protective Service Occupations" if SOC_F == 33
replace SOC_Fam = "Food Preparation and Serving Related Occupations" if SOC_F == 35
replace SOC_Fam = "Building and Grounds Cleaning and Maintenance Occupations" if SOC_F == 37
replace SOC_Fam = "Personal Care and Service Occupations" if SOC_F == 39
replace SOC_Fam = "Sales and Related Occupations" if SOC_F == 41
replace SOC_Fam = "Office and Administrative Support Occupations" if SOC_F == 43
replace SOC_Fam = "Farming, Fishing and Forestry Occupations" if SOC_F == 45
replace SOC_Fam = "Construction and Extracting Occupations" if SOC_F == 47
replace SOC_Fam = "Installation, Maintenance, and Repair Occupations" if SOC_F == 49
replace SOC_Fam = "Production Occupations" if SOC_F == 51
replace SOC_Fam = "Transportation and Material Moving Occupations" if SOC_F == 53
replace SOC_Fam = "Military Specific Occupations" if SOC_F == 55 

rename SOC_Fam Fam_Name
drop SOC_F

save $dta/risk_iter`iter'.dta , replace
}
}


use $dta/risk_iter1, clear
g iter = 1

forv iter = 2(1)`N' {
	append using $dta/risk_iter`iter'
	replace iter = `iter' if iter ==.
	}
collapse (p5) p5=share (p50) p50=share 	(mean) mean=share (p95) p95=share, by(Occupation ONETSOCCode)
foreach var in p5 p50 mean p95 {
	sort `var'
	g rank_`var' = _n
	}
correl rank_*
g width = p95-p5
su width
sort ONETSOCCode
save $dta/risk_sum.dta, replace

*** compare to existing measure
use $dta/risk, clear
sort 	ONETSOCCode
merge 1:1 ONETSOCCode using $dta/risk_sum.dta

correl share mean p50 p5 p95
spearman share mean p50 p5 p95

save $dta/risk_sens.dta, replace

forv iter = 1(1)`N' {
	erase $dta\risk_iter`iter'.dta
}

