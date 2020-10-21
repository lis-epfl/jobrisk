clear

******* cross Risk Measures
******* Fabrizio Colella

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

*** open database
clear
use $dta/ab_sk.dta 

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

save $dta/risk.dta , replace

export excel using $output/risk_measures.xlsx, replace  firstrow(variables)

collapse  share_utoCognitive  share_dysCognitive  shareCognitive ///
 share_utoSensory  share_dysSensory  shareSensory ///
 share_utoPhysical  share_dysPhysical  sharePhysical ///
 share_uto  share_dys share ///
, by(Fam_Name)

export excel using $output/risk_measures_families.xlsx, replace  firstrow(variables)

/*
********************************************************************************
sort Fam_Name
replace Fam_Name = "Architecture and Engineering" if Fam_Name =="Architecture and Engineering Occupations" 
replace Fam_Name = "Arts, Design, Entertainment, Sports, and Media" if Fam_Name =="Arts, Design, Entertainment, Sports, and Media Occupations"
replace Fam_Name = "Building and Grounds Cleaning and Maintenance"  if Fam_Name =="Building and Grounds Cleaning and Maintenance Occupations"
replace Fam_Name = "Business and Financial Operations" if Fam_Name =="Business and Financial Operations Occupations" 
replace Fam_Name = "Community and Social Service" if Fam_Name =="Community and Social Service Occupations"
replace Fam_Name = "Computer and Mathematical" if Fam_Name == "Computer and Mathematical Occupations"
replace Fam_Name = "Construction and Extracting" if Fam_Name =="Construction and Extracting Occupations"
replace Fam_Name = "Education, Training and Library" if Fam_Name =="Education, Training and Library Occupations"
replace Fam_Name = "Farming, Fishing and Forestry" if Fam_Name =="Farming, Fishing and Forestry Occupations" 
replace Fam_Name = "Food Preparation and Serving Related" if Fam_Name =="Food Preparation and Serving Related Occupations" 
replace Fam_Name = "Healthcare Practitioners and Technical" if Fam_Name =="Healthcare Practitioners and Technical Occupations"
replace Fam_Name = "Healthcare Support" if Fam_Name =="Healthcare Support Occupations"
replace Fam_Name = "Installation, Maintenance, and Repair" if Fam_Name =="Installation, Maintenance, and Repair Occupations"
replace Fam_Name = "Legal" if Fam_Name =="Legal Occupations" 
replace Fam_Name = "Life, Physical, and Social Science" if Fam_Name == "Life, Physical, and Social Science Occupations"
replace Fam_Name = "Management" if Fam_Name =="Management Occupations" 
replace Fam_Name = "Office and Administrative Support" if Fam_Name =="Office and Administrative Support Occupations" 
replace Fam_Name = "Personal Care and Service" if Fam_Name =="Personal Care and Service Occupations"
replace Fam_Name = "Production" if Fam_Name == "Production Occupations"
replace Fam_Name = "Protective Service" if Fam_Name ==  "Protective Service Occupations"
replace Fam_Name = "Sales and Related" if Fam_Name == "Sales and Related Occupations" 
replace Fam_Name = "Transportation and Material Moving" if Fam_Name ==  "Transportation and Material Moving Occupations" 

graph bar shareCognitive sharePhysical shareSensory , ///
over(Fam_Name, lab(angle(60) labsize(vsmall)) ) ///
graphregion(color(white) lwidth(large))  ///
legend(order(1 "Cognitive" 2 "Physical" 3 "Sensory") cols(3))  

replace shareCognitive = shareCognitive/56*87
replace shareSensory = shareSensory/10*87
replace sharePhysical = sharePhysical/21*87

graph bar shareCognitive sharePhysical shareSensory , ///
over(Fam_Name, lab(angle(60) labsize(vsmall)) ) ///
graphregion(color(white) lwidth(large))  ///
legend(order(1 "Cognitive" 2 "Physical" 3 "Sensory") cols(3))  

graph bar share shareCognitive , ///
over(Fam_Name, sort(share) lab(angle(35) labsize(vsmall)) ) ///
graphregion(color(white) lwidth(large))  ///
legend(order(1 "Total" 2 "Cognitive") ///
rowgap(7) region(lcolor(white)) cols(1) pos(9) size(small) symxsize(2))  

graph bar shareCognitive sharePhysical shareSensory,  stack ///
over(Fam_Name, sort(share) lab(angle(35) labsize(vsmall)) ) ///
graphregion(color(white) lwidth(large))  ///
legend(order(1 "Cognitive" 2 "Physical" 3 "Sensory") ///
rowgap(7) region(lcolor(white)) cols(1) pos(9) size(small) symxsize(2))  
*/


