******* How To Compete with Robots
******* Science Robotics Replication Files
******* Fabrizio Colella - Rafael Lalive
******* Februrary 2022

******* DATA PREPARATION 

*******************************************************************************

clear

do 0_project_folder.do 
global input "$project/data_input"
global dta "$project/dta"
global output "$project/output"

cd $project/do

mkdir $project/dta
mkdir $project/output
mkdir $project/output/figures_tables_in_the_paper

*append skills and abilities
clear
import excel using $input/Skills.xlsx, first
save temp.dta , replace
clear
import excel using $input/Abilities.xlsx, first
append using temp.dta
erase temp.dta
keep ONETSOCCode Title ElementID ElementName ScaleID DataValue
rename Title Occupation
save $dta/ab_sk.dta , replace

*get max anchor
clear
import excel using $input/Anchors.xlsx, first
egen Max_Anchor = max(AnchorValue) , by(ElementID)
keep ElementID Max_Anchor
duplicates drop
save temp.dta , replace
clear
use $dta/ab_sk.dta
merge m:1 ElementID using temp.dta, keep(3) nogenerate
erase temp.dta
save $dta/ab_sk.dta , replace

*get type
clear
import excel using $input/Types.xlsx, first
rename Abilities ElementName
keep ElementName Type
duplicates drop
save temp.dta , replace
clear
use $dta/ab_sk.dta
merge m:1 ElementName using temp.dta, keep(3) nogenerate
erase temp.dta
sort ONETSOCCode ElementID ScaleID
save $dta/ab_sk.dta , replace

* reshape
reshape wide DataValue ,i(ONETSOCCode ElementID) j(ScaleID) string

* get TRL
gen TRL = .
replace TRL = 9 if ElementName=="Arm-Hand Steadiness" ///
	|  ElementName=="Control Precision" |  ElementName=="Deductive Reasoning" ///
	|  ElementName=="Equipment Maintenance" |  ElementName=="Extent Flexibility" ///
	|  ElementName=="Gross Body Coordination" |  ElementName=="Gross Body Equilibrium" ///
	|  ElementName=="Operation Monitoring" |  ElementName=="Oral Comprehension" ///
	|  ElementName=="Oral Expression" |  ElementName=="Problem Sensitivity" ///
	|  ElementName=="Speed of Limb Movement" |  ElementName=="Systems Evaluation" 
	
replace TRL = 8 if ElementName=="Equipment Selection" ///
	|  ElementName=="Finger Dexterity" 

replace TRL = 7 if ElementName=="Auditory Attention" ///
	|  ElementName=="Hearing Sensitivity" |  ElementName=="Inductive Reasoning" ///
	|  ElementName=="Spatial Orientation" 
	
replace TRL = 6 if ElementName=="Category Flexibility" ///
	|  ElementName=="Flexibility of Closure" |  ElementName=="Perceptual Speed" ///
	|  ElementName=="Speed of Closure"  

replace TRL = 5 if ElementName=="Manual Dexterity" 
	
replace TRL = 4 if ElementName=="Complex Problem Solving" ///
	|  ElementName=="Coordination" |  ElementName=="Judgment and Decision Making" ///
	|  ElementName=="Critical Thinking" |  ElementName=="Learning Strategies" ///
	|  ElementName=="Monitoring" |  ElementName=="Quality Control Analysis" ///
	|  ElementName=="Response Orientation" |  ElementName=="Troubleshooting" ///
	|  ElementName=="Social Perceptiveness"
	
replace TRL = 3 if ElementName=="Systems Analysis" ///
	|  ElementName=="Visualization" 

// intrinsic
replace TRL = 9 if ElementName=="Dynamic Strength" ///
	|  ElementName=="Explosive Strength" |  ElementName=="Mathematical Reasoning" ///
	|  ElementName=="Mathematics" |  ElementName=="Number Facility" ///
	|  ElementName=="Stamina" |  ElementName=="Trunk Strength"

*** gen rescaled variables
gen hLevel = DataValueLV/Max_Anchor
replace  hLevel = 1 if hLevel>1 // only 6 cases
*
gen hImp = (DataValueIM-1)/4
* 
gen TRL_weight_dys = TRL
replace TRL_weight_dys = 9 if TRL_weight_dys==.
*
gen TRL_weight_uto = TRL
replace TRL_weight_uto = 0 if TRL_weight_uto==.
*
replace	TRL_weight_uto = 0.1 + (TRL_weight_uto-1)*0.9/8
replace TRL_weight_dys = 0.1 + (TRL_weight_dys-1)*0.9/8
replace TRL_weight_uto = 0 if TRL_weight_uto<0
replace TRL_weight_dys = 0 if TRL_weight_dys<0

sort ONETSOCCode ElementID
save $dta/ab_sk.dta , replace


*******************************************
* KNOWLEDGE

*append skills and abilities
clear
import excel using $input/Knowledge.xlsx, first
keep ONETSOCCode Title ElementID ElementName ScaleID DataValue
rename Title Occupation
save $dta/know.dta , replace

*get max anchor
clear
import excel using $input/Anchors.xlsx, first
egen Max_Anchor = max(AnchorValue) , by(ElementID)
keep ElementID Max_Anchor
duplicates drop
save temp.dta , replace
clear
use $dta/know.dta
merge m:1 ElementID using temp.dta, keep(3) nogenerate
erase temp.dta
save $dta/know.dta , replace

* reshape
reshape wide DataValue ,i(ONETSOCCode ElementID) j(ScaleID) string

*** gen rescaled variables
gen hLevel = DataValueLV/Max_Anchor
replace  hLevel = 1 if hLevel>1 // only 6 cases
*
gen hImp = (DataValueIM-1)/4
* 
sort ONETSOCCode ElementID
save $dta/know.dta , replace


use $dta/ab_sk.dta , replace
keep ElementName ElementID Type TRL
bysort ElementID: keep if _n == 1
save $dta/ab_sk_uniq.dta, replace



