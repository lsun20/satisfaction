clear
clear	matrix
clear   mata
set more off
set	maxvar	20000

/*-----------------------------------------------------------				
*	Goal:			patient satisfaction paper

*	Input Data:		1) town leader interview.dta 2) hh_clean_2012_12_17xh.dta 
					
*	Output Data:	1) /temp/hh_vc_thc_char.dta (hh survey merged with vc and thc char
					2)
										
*   Author(s):      Sophie Sun 
*	Created: 		20170624
-----------------------------------------------------------*/
global 	dtadir		"/Users/lsun20/Dropbox (MIT)/2017Summer/satisfaction/data/"
global	resultsdir	"/Users/lsun20/Dropbox (MIT)/2017Summer/satisfaction/output/"

/*
unicode encoding set gb18030
unicode translate clean_vm.dta

use "clean_vm.dta",clear
*/
/*-----------------------------------------------------------				
*	Clean the facility surveys
-----------------------------------------------------------*/
use "${dtadir}/town leader interview.dta", clear
gen 	vid = substr(clinicid,1,4) if length(clinicid) == 6
destring vid,replace
label	var vid "village code"

gen tid = substr(clinicid,1,3) 
destring tid, replace
label	var tid "town code"

*Provider Characteristics
foreach num in 1 2 3{
	foreach var in  vmage vmgender vmedu vm125 vm126 vm128 vm129 vm130 vm131 vm132 vm133 vm134 vm135{
		replace `var'_`num' =. if  vm121_`num'==2
		}
}

egen avgage = rowmean( tm10a tm10b tm10c) if townvill==2
	egen avgage_1 = rowmean(vmage_1 vmage_2 vmage_3) if townvill==1
	replace avgage = avgage_1 if townvill==1
label var avgage "Average doctor age"
	
recode tm11a tm11b tm11c  vmgender_1 vmgender_2 vmgender_3 (2=0)
egen avgmale = rowmean(tm11a tm11b tm11c) if townvill==2
	egen avgmale_1 = rowmean(vmgender_1 vmgender_2 vmgender_3) if townvill==1
	replace avgmale = avgmale_1 if townvill==1
label var avgmale "Male share"	

egen avgexp = rowmean(tm13a tm13b tm13c) if townvill==2
	egen avgexp_1 = rowmean(vm131_1 vm131_2  vm132_3) if townvill==1
	replace avgexp = avgexp_1 if townvill==1
label var avgexp "Average experience"
	
egen ndoc = rownonmiss( tm10a tm10b tm10c) if townvill==2
egen ndoc_1 = rownonmiss( vmage_1 vmage_2 vmage_3) if townvill==1
	replace ndoc = ndoc_1 if townvill==1
	drop ndoc_1
	replace ndoc=1 if ndoc==0
label var ndoc "Number of doctors"
	
foreach l in a b c{
g middle_`l' = (tm14`l'==2)
replace middle_`l'=. if tm14`l'==.

g mvoc_`l' = (tm14`l'==4)
replace mvoc_`l'=. if tm14`l'==.

g hvoc_`l' = (tm14`l'==5)
replace hvoc_`l'=. if tm14`l'==.

g ghigh_`l' = (tm14`l'==3)
replace ghigh_`l'=. if tm14`l'==.

g coll_`l' = (tm14`l'==6 | tm14`l'==7)
replace coll_`l'=. if tm14`l'==.
}

foreach l in 1 2 3{
g middle_`l' = (vmedu_`l'==2)
replace middle_`l'=. if vmedu_`l'==.

g mvoc_`l' = (vmedu_`l'==4)
replace mvoc_`l'=. if vmedu_`l'==.

g hvoc_`l' =  (vmedu_`l'==5)
replace hvoc_`l'=. if vmedu_`l'==.

g ghigh_`l' = (vmedu_`l'==3)
replace ghigh_`l'=. if vmedu_`l'==.

g coll_`l' =(vmedu_`l'==6 | vmedu_`l'==7)
replace coll_`l'=. if vmedu_`l'==.
}
	
foreach v in middle mvoc hvoc ghigh coll{
		egen avg_`v' = rowmean(`v'_a `v'_b `v'_c) if townvill==2
		egen avg_`v'_1 = rowmean(`v'_1 `v'_2 `v'_3) if townvill==1
		replace avg_`v' = avg_`v'_1 if townvill==1
		drop avg_`v'_1
}
drop  avgage_1 avgmale_1 avgexp_1 middle_a- coll_3
label var avg_middle "Share with middle school"
label var avg_mvoc  "Share with vocational high school"
label var avg_hvoc  "Share with vocational college"
label var avg_ghigh "Share with general high shcool"
label var avg_coll  "Share with college"

foreach l in a b c{
g qnone_`l' = (tm16`l'==3)
replace qnone_`l' = . if tm16`l'==.

g qdoc_`l' = (tm16`l'==1)
replace qdoc_`l' = . if tm16`l'==.

g qassdoc_`l' = (tm16`l'==2)
replace qassdoc_`l' = . if tm16`l'==.

g qruraldoc_`l' =0
g qother_`l' =0
}

foreach l in 1 2 3{
g qnone_`l' = ( vm130_`l'==0)
replace qnone_`l' = . if vm130_`l'==.

g qdoc_`l' = ( vm130_`l'==1)
replace qdoc_`l' = . if vm130_`l'==.

g qassdoc_`l' = ( vm130_`l'==2)
replace qassdoc_`l' = . if vm130_`l'==.

g qruraldoc_`l' = ( vm130_`l'==3)
replace qruraldoc_`l' =. if vm130_`l'==.

g qother_`l' = ( vm130_`l'==4)
replace qother_`l' = . if vm130_`l'==.
}

foreach v in qnone qdoc qassdoc qruraldoc qother{
		egen avg_`v' = rowmean(`v'_a `v'_b `v'_c) if townvill==2
		egen avg_`v'_1 = rowmean(`v'_1 `v'_2 `v'_3) if townvill==1
		replace avg_`v' = avg_`v'_1 if townvill==1
		drop avg_`v'_1
}
drop  qnone_a -qother_3
label var avg_qnone 	"Share without qualification"
label var avg_qdoc		"Share with practicing physician certificate"
label var avg_qassdoc 	"Share with assistant practicing physician certificate"
label var avg_qruraldoc "Share with rural physician certificate"

g patwk =  tm23/52
replace patwk =   vm33 if townvill==1

label var patwk			"Average patients per week"

g totshebei = tm5a
replace totshebei =  vm8/10000 if townvill==1
label var totshebei 	"total value of medical instruments, in 10k"

g fee_gh = tm20
replace fee_gh = vm31 if townvill==1
label		var fee_gh "Outpatient copay"

gen 		population = vm44
label		var population "Population in the catchment area, person"

*** disease composition
gen			angina_fare = vmfare_2 	if townvill == 1
replace		angina_fare = fare_2 	if townvill == 2
label		var angina_fare "Estimated treatment cost for angina symptoms"

gen 		dysentery_fare = vmfare_1 if townvill == 1
replace		dysentery_fare = fare_1 	if townvill == 2
label		var dysentery_fare "Estimated treatment cost for dysentery symptoms"


gen			asthma_fare = vmfare_3 if townvill == 1
replace		asthma_fare = fare_3   if townvill == 2
label		var asthma_fare "Estimated treatment cost for asthma symptoms"

*** relationship to nearby hospitals - only available in VC survey
gen			distancetoTHC = vm92
gen			distancetocounty = vm93

*** satisfaction
gen			perceivedpatientscore = vm149 if townvill == 1
replace		perceivedpatientscore = tm146 if townvill == 2
label		var perceivedpatientscore "Patient's satisfacation score as perceived by the clinic, 1-10"
gen			clinicscore = vm171 if townvill == 1
replace 	clinicscore = tm187 if townvill == 2
label		var clinicscore "Clinic's satisfaction score, 1-10"

cap macro	drop	$CLINIC
global		CLINIC ndoc avgage avgmale avgexp avg_middle avg_mvoc avg_hvoc avg_ghigh avg_coll ///
			avg_qnone avg_qdoc avg_qassdoc avg_qruraldoc patwk totshebei fee_gh ///
			*_fare *score
			
keep *id townvill $CLINIC  population distancetoTHC distancetocounty 
save "${dtadir}/temp/vc_thc_char_long.dta", replace

s


*******************************************************************************************
***** reshape to long dataset at doctor level - not completed
reshape long vmname_ vmage_ vmgender_ vmedu_, i(clinicid) j(doctorid)
drop if vmname_ == ""

*******************************************************************************************
***** reshape to wide dataset at village level so that we can merge with HH survey later

use "${dtadir}/temp/vc_thc_char_long.dta", clear

preserve
keep if townvill == 1
keep *id $CLINIC  population distancetoTHC distancetocounty 
save "${dtadir}/temp/vc_char.dta", replace
restore


keep if townvill == 2
keep tid $CLINIC 
foreach var of varlist $CLINIC {
	rename `var' thc_`var'
}
merge 1:m tid using "${dtadir}/temp/vc_char.dta", nogen assert(match)
save "${dtadir}/temp/vc_thc_char_wide.dta", replace
/*-----------------------------------------------------------				
*	Clean the HH surveys
-----------------------------------------------------------*/
use "${dtadir}/HH_CLEAN_2012_12_17xh.dta", clear
gen countycode = floor(hhcode/10000)

gen hhincome = hhincome_farm + hhincome_nf
label var hhincome "HH total income"
label var hhage "HH head age"
label var hhgender "Share of HH with male head"
label var hhpeople "Number of members per HH"
label var hhchild "Number of children (age 0-6) per HH"
label var hhelder "Number of elders (age 64+) per HH"
gen hhlesselementary 	= hhedu <= 1
gen hhelementary		= hhedu == 2 | hhedu == 3
gen hhmiddle			= hhedu == 4 | hhedu == 5
gen hhhighormore		= hhedu == 6 | hhedu == 7
label var hhlesselementary "Less than elementary school"
label var hhelementary 	"Elementary school"
label var hhmiddle		"Middle school"
label var hhhighormor   "High school or more"
			
recode hh32 hh45 hh106 hh154 (99=.)
label	var hh32 	"overall score on vc"
label	var hh106 	"overall score on thc"

gen thc_stated_pref = hh106 >= hh32
label	var thc_stated_pref "stated preference for thc based on relative score"
egen most_satis = rowmax(hh32 hh106 hh154)
count if hh32 == most_satis
count if hh106 == most_satis
count if hh154 == most_satis

recode hh47 hh48 (99=.)

gen rel_satis = hh106-hh32
label var rel_satis "relative satisfaction score=THC-VC"


gen thc = hh47 == 2
label var thc "1=sought care at THC"
gen lhhincome = log(hhincome)
label var lhhincome "log(HH total income)"

gen vid = floor(hhcode/100)
label var vid "village code, 4 digit"

local binaries hhgender hhlesselementary hhelementary hhmiddle hhhighormore
foreach var of varlist `binaries' {
	replace `var' = 0 if `var' == 2 // convert yes/no questions to dummy variables
}

gen rel_equip_score_thc 	= hh96 - hh35
gen rel_equip_score_county 	= hh144 - hh35

gen rel_diag_score_thc		= hh97 - hh36
gen rel_diag_score_county	= hh145 - hh36

gen rel_treat_score_thc		= hh98 - hh37
gen rel_treat_score_county	= hh146 - hh37

gen rel_fee_score_thc		= hh99 - hh38
gen rel_fee_score_county	= hh147 - hh38

gen rel_wait_score_thc		= hh100 - hh39
gen rel_wait_score_county	= hh148 - hh39

gen rel_time_score_thc		= hh101 - hh40
gen rel_time_score_county	= hh149 - hh40

gen rel_comm_score_thc		= hh102 - hh41
gen rel_comm_score_county	= hh150 - hh41

gen rel_pres_score_thc		= hh103 - hh42
gen rel_pres_score_county	= hh151 - hh42

save "${dtadir}/temp/hh_char.dta",replace

use "${dtadir}/temp/hh_char.dta", clear
merge m:1 vid using "${dtadir}/temp/vc_thc_char_wide.dta", nogen assert(match)
save "${dtadir}/temp/hh_vc_thc_char.dta",replace


