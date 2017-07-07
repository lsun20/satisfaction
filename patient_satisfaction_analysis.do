clear
clear	matrix
clear   mata
set more off
set	maxvar	20000

/*-----------------------------------------------------------				
*	Goal:			patient satisfaction paper

*	Input Data:		1) quality_satisfaction 
					
*	Output Data:	1) /temp/
					2)
										
*   Author(s):      Sophie Sun 
*	Created: 		201706704
-----------------------------------------------------------*/
global 	dtadir		"/Users/lsun20/Dropbox (MIT)/2017Summer/satisfaction"
global	resultsdir	"${dtadir}/table and figures"

*********************Table 1 Descriptive table of clinic characteristics

use "${dtadir}/temp/vc_thc_char_long.dta", clear

cap macro	drop	$CLINIC
global		CLINIC ndoc avgage avgmale avgexp avg_middle avg_mvoc avg_hvoc avg_ghigh avg_coll ///
			avg_qnone avg_qdoc avg_qassdoc avg_qruraldoc patwk totshebei fee_gh ///
			*_fare *score
			
desc $CLINIC

putexcel set "${resultsdir}/tables.xlsx", ///
	sheet("Table 1") modify
local row = 2 //initiate row number to store output for putexcel
		 qui foreach var of varlist $CLINIC {
			
			cap mat drop var
				
				foreach caselogic in ==1 ==2  {

				sum `var' if townvill `caselogic'
				local n = `r(N)'

				if regexm("`binaries'","`var'") local mean = 100 * `r(mean)' 
					else local mean = `r(mean)'
				
				version 14 // for ci command

				if regexm("`binaries'","`var'") ci `var' if townvill `caselogic', b wilson 
					else ci `var' if townvill `caselogic'
					
					local lower = `r(lb)'
						if regexm("`binaries'","`var'") local lower = 100 * `lower'
					local upper = `r(ub)'
						if regexm("`binaries'","`var'") local upper = 100 * `upper'
				
				mat var = nullmat(var) , [`n',`mean',`lower',`upper']
				mat list var

				}
				//local lbl`var': variable label `var'
				// trying to write labels to table row names
				//putexcel A`row' = "`lbl`var''"

				//putexcel B`row' = matrix(var)
				local row = `row' + 1 

				
			}
			
			

*********************Table 2 Descriptive table of HH characteristics
use "${dtadir}/temp/hh_char.dta", clear

global HH hhage hhgender hhlesselementary hhelementary hhmiddle hhhighormore ///
			hhincome hhpeople hhchild hhelder


putexcel set "${resultsdir}/tables.xlsx", ///
	sheet("Table 2") modify
local row = 2 //initiate row number to store output for putexcel
		 qui foreach var of varlist $HH {
			
			cap mat drop var
				
				sum `var' 
				local n = `r(N)'

				if regexm("`binaries'","`var'") local mean = 100 * `r(mean)' 
					else local mean = `r(mean)'
				
				version 14 // for ci command

				if regexm("`binaries'","`var'") ci `var' , b wilson 
					else ci `var' 
					
					local lower = `r(lb)'
						if regexm("`binaries'","`var'") local lower = 100 * `lower'
					local upper = `r(ub)'
						if regexm("`binaries'","`var'") local upper = 100 * `upper'
				
				mat var = nullmat(var) , [`n',`mean',`lower',`upper']
				mat list var

				//local lbl`var': variable label `var'
				// trying to write labels to table row names
				//putexcel A`row' = "`lbl`var''"

				//putexcel B`row' = matrix(var)
				local row = `row' + 1 

				
			}
			
*********************Table 3 Correlation between revealed preference and stated preference
		
tab hh47 hh48


*********************Table 4 Effect of relative satisfaction score on demand for THC

use "${dtadir}/temp/hh_vc_thc_char.dta", clear

// summarize relative satisfaction score
/*
foreach var of varlist rel_*_score_thc {
	sum `var', det
	local n = `r(N)'
	local mean = `r(mean)'
	local p5 = `r(p5)'

}
*/
sum rel_*_score_thc
sum rel_*_score_county

// Estimate multinomial logit model
gen equip_score1 	= hh35
gen equip_score2 	= hh96
gen equip_score3	= hh144 

gen diag_score1		= hh36
gen diag_score2		= hh97 
gen diag_score3		= hh145

gen treat_score1	= hh37
gen treat_score2	= hh98
gen treat_score3	= hh146

gen fee_score1		= hh38
gen fee_score2		= hh99 
gen fee_score3		= hh147

gen wait_score1		= hh39
gen wait_score2		= hh100
gen wait_score3		= hh148

gen time_score1		= hh40
gen time_score2		= hh101
gen time_score3		= hh149

gen comm_score1		= hh41
gen comm_score2		= hh102
gen comm_score3		= hh150

gen pres_score1		= hh42
gen pres_score2		= hh103
gen pres_score3		= hh151

drop rel_*_score*
keep *_score* hh48 hhage hhgender hhincome hhcode
reshape long *_score, i(hhcode) j(tier)
label define tier_lbl 1 "vc" 2 "thc" 3 "county hospital"
label value tier tier_lbl
gen choice = hh48 == tier
replace hhincome = log(hhincome)
// log using "${results}/asclogit.log", replace
asclogit choice diag_score fee_score wait_score, case(hhcode) alternatives(tier) casevars(hhage hhgender hhincome) nocons
estat alt
estat mfx
// log close

*********Table 5 Correlation between service completion rate and satisfaction score
use "${dtadir}/temp/hh_vc_thc_char.dta", clear

// clean service completion questions
recode hh29_*a  hh90_*a (99=.) (2=0) (4=1)
egen service_complete_vc = rowmean(hh29_*a)
global SERVICE_THC hh90_10a hh90_11a hh90_12a hh90_13a hh90_14a hh90_15a hh90_16a hh90_17a hh90_21a hh90_22a hh90_23a hh90_24a
egen service_complete_thc = rowmean($SERVICE_THC)
// correlation between service completion rate and relative satisfaction score
reg rel_satis service_complete_vc service_complete_thc i.county

* hh118 hh155 tijian
// See who does the publicity
*hh109 hh111 hh113 hh114 hh117 
*********Table 5 Effect of relative rate of correct diagnosis/treatment on demand for THC (NOT IN USE SINCE WE DON'T USE SP DATA)

use "${dtadir}/temp/hh_vc_thc_char_diag.dta", clear
keep if hh47 == 1 | hh47 == 2

putexcel set "${resultsdir}/tables.xlsx", ///
	sheet("Table 4") modify

qui logit thc rel_dys_ptreat rel_dys_pdiag  rel_ldysentery_fare, robust
estpost margins, dydx(rel_dys_pdiag rel_dys_ptreat rel_ldysentery_fare )

mat B  = e(table)
mat A = vec(B[1..2,1...])
//matrix list A
putexcel B2 = matrix(A)

qui logit thc rel_ang_ptreat rel_ang_pdiag  rel_langina_fare, robust
estpost margins, dydx(rel_ang_pdiag rel_ang_ptreat rel_langina_fare)

mat B  = e(table)
mat A = vec(B[1..2,1...])
//matrix list A
putexcel B8 = matrix(A)


*********Table 6 Joint model on relative rate of correct diagnosis/treatment on demand for THC (NOT READY)

use "${dtadir}/temp/hh_vc_thc_char_diag.dta", clear
replace thc = . if hh47 != 1 & hh47 != 2
expand 8
gen clinic = ""
bys hhcode: replace clinic = "vc_revealed" if _n == 1 | _n == 5
bys hhcode: replace clinic = "thc_revealed" if _n == 2 | _n == 6
bys hhcode: replace clinic = "vc_stated" if _n == 3 | _n == 7
bys hhcode: replace clinic = "thc_stated" if _n == 4 | _n == 8

bys hhcode: gen 	byte sp = _n > 4

bys hhcode: replace hhcode 	= hhcode -100000  if _n > 4

gen chosen = .
replace chosen = 1 if clinic == "vc_revealed" & thc == 0 & sp == 0
replace chosen = 1 if clinic == "thc_revealed" & thc == 1 & sp == 0
replace chosen = 1 if clinic == "vc_stated" & thc_stated_pref == 0 & sp == 1
replace chosen = 1 if clinic == "thc_stated" & thc_stated_pref == 1 & sp == 1

replace chosen = 0 if chosen == .

recode hh36 hh97 (99=.)
gen quality_score = .
replace quality_score = hh36 		if clinic == "vc_stated" | clinic == "vc_revealed"
replace quality_score = hh97 	if clinic == "thc_stated" | clinic == "thc_revealed"

replace ang_pdiag = thc_ang_pdia if clinic == "thc_stated" | clinic == "thc_revealed"
replace ang_ptreat = thc_ang_ptreat if clinic == "thc_stated" | clinic == "thc_revealed"


encode clinic, gen(clinic_factor)

nlogitgen type = clinic_factor(stated: thc_stated | vc_stated, revealed: thc_revealed | vc_revealed)
nlogittree clinic_factor type, choice(chosen)
nlogit chosen quality_score ang_pdiag ang_ptreat || type: hhage hhincome, base(stated) || clinic_factor:, noconstant case(hhcode)
￼


