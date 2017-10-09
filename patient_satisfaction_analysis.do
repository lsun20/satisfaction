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
*	Created: 		20171009
-----------------------------------------------------------*/
global 	dtadir		"/Users/lsun20/Dropbox (MIT)/2017Summer/satisfaction/data"
global	resultsdir	"/Users/lsun20/Dropbox (MIT)/2017Summer/satisfaction/Output"

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

use "${dtadir}/hh_vc_thc_char.dta", clear

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
keep *_score* hh47 hh48 hhage hhgender hhincome hhcode hhlesselementary hhelementary hhmiddle hhhighormore ///
			hhincome hhpeople hhchild hhelder
reshape long equip_score diag_score treat_score fee_score wait_score time_score comm_score pres_score, i(hhcode) j(tier)
label define tier_lbl 1 "vc" 2 "thc" 3 "county_hospital"
label value tier tier_lbl
gen choice = hh48 == tier
replace choice = hh47 == tier // stated preference - which one would you visit

foreach vv of varlist  *_score {
	replace `vv' = 0 if `vv' < 4 // following Sean to convert Likert score
	replace `vv' = 1 if `vv' <= 5 & `vv' >= 4 
	replace `vv'=. if `vv'>5

}
replace hhincome = log(hhincome)

// try mlogit first, only controlling for HH characteristics
preserve
//outreg, clear
keep if choice == 1
mlogit tier hhage hhgender hhlesselementary hhelementary hhmiddle  ///
			hhincome hhpeople hhchild hhelder
margins, dydx(*) post
//outreg2 using mlogitmfx.doc, word replace ctitle(mlogit) addnote(NOTE: excluded category for education is high school)
restore


// try conditional logit, which adds raitings for different component of care
// log using "${results}/asclogit.log", replace
asclogit choice *_score, case(hhcode) alternatives(tier) casevars(hhage hhgender hhincome hhpeople) nocons

estat mfx

capture program drop Fill_rbV
program Fill_rbV, rclass
	args b V
	return matrix b = `b'
	return matrix V = `V'
	return local cmd "margins"
end

local k = e(k_alt)
forvalues i = 1/`k' {
	tempname b`i' V`i'
	mat `b`i'' = r(`e(alt`i')')
	dis "r(`e(alt`i')')"	
	mat list `b`i''
	mat `V`i'' = diag(`b`i''[.,2..2])
	mat `V`i'' = `V`i'' * `V`i''
	mat `b`i'' = `b`i''[.,1..1]'
}

outreg, clear
forvalues i = 1/`k' {
	Fill_rbV `b`i'' `V`i''
	outreg, margin merge ctitle("", "", "`e(alt`i')'") nodisplay
}
outreg using ascmfx, replay replace

// log close
lclogit choice *_score, id(hhcode) gid(hhcode) membership(hhage hhgender hhincome) nclasses(2)


