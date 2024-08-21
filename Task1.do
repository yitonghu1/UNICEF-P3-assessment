*************************************************************************
* UNICEF P3 Assessment

* A.1 Cleaning and Processing Global Dataflow from 2018 to 2022 
* A.2 Cleaning and Processing Population data
* A.3 Cleaning and Processing Population On-track and off-track countries excel

*: B. Analysis
*************************************************************************

*** CALIBRATING DIRECTORIES
clear all
set more off

global maindir "C:\Users\Administrator\Downloads"
global unicef "$maindir\UNICEF-P3-assessment-public-main\UNICEF-P3-assessment-public-main\01_rawdata"

* A.1 Clean Global Dataflow from 2018 to 2022 
** Import dataset
import excel "$unicef\GLOBAL_DATAFLOW_2018-2022.xlsx", sheet("Unicef data") firstrow

** Data description
tab Indicator
codebook Geographicarea //have 181 countries
tab COVERAGE_TIME //diverse coverage
codebook TIME_PERIOD //2018-2022

** Data cleaning 
rename Geographicarea countryname
* Use only the most recent coverage estimate for the country during these five years for the weighted average.
sort countryname TIME_PERIOD
by countryname: gen latest_year = TIME_PERIOD == TIME_PERIOD[_N]
keep if latest_year
drop latest_year
drop if countryname == ""
replace countryname = "Kosovo (under UNSC res. 1244)" if countryname == "Kosovo (UNSCR 1244)"
replace countryname = "United States of America" if countryname == "United States"

codebook countryname //181 countries
save "$unicef\dataflow.dta", replace

* A.2 Population data: United Nations World Population Prospects population estimates
** I manually cleaned the title lines in excel to import the excel to STATA
* Projected 2022 data
clear
import excel "$unicef\WPP2022_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT_REV1.xlsx", sheet("Projections") firstrow clear
rename Regionsubregioncountryorar countryname
keep if Year == 2022
drop if ISO3Alphacode == ""
rename ISO3Alphacode iso3
keep countryname Birthsthousands iso3
destring Birthsthousands, replace
save "$unicef\birth.dta", replace
clear

* A.3 On-track and off-track countries.xlsx
import excel "$unicef\On-track and off-track countries.xlsx", sheet("Sheet1") firstrow
rename ISO3Code iso3
rename OfficialName countryname
replace iso3 = "XKX" if iso3 == "RKS" // Country iso3 were not aligned in two datasets
save "$unicef\onofftrack.dta", replace
clear

*** Merge
clear
use "$unicef\birth.dta"
merge 1:1 iso3 using "$unicef\onofftrack.dta"
br if _merge == 1 //37 countries don't have status
drop _merge
merge 1:m countryname using "$unicef\dataflow.dta"
drop if _merge == 2 //this group is regions instead of countries
sort countryname
rename Birthsthousands Birthsthousands2022
codebook countryname if Indicator == "" //94 missing countries without indicator
drop _merge

*** B.1 Calculate population-weighted coverage for on-track and off-track countries for ANC4 and SAB use the formula

gen on_track = (StatusU5MR == "Achieved" | StatusU5MR == "On Track")
gen off_track = (StatusU5MR == "Acceleration Needed")

gen Skilledhealthpers = OBS_VALUE if Indicator == "Skilled birth attendant - percentage of deliveries attended by skilled health personnel"

gen Antenatalcare = OBS_VALUE if Indicator == "Antenatal care 4+ visits - percentage of women (aged 15-49 years) attended at least four times during pregnancy by any provider"

* Skilledhealthpersonnel ANC4 weighted coverage 
destring Skilledhealthpers, replace
replace Birthsthousands2022 = "" if Birthsthousands2022 == "..."
destring Birthsthousands2022, replace
gen birthnum2022 = Birthsthousands2022 * 1000

* For on-track countries, calculate the weighted coverage
gen weighted_indicator_ontrack = Skilledhealthpers * birthnum2022 if on_track == 1
gen weight_ontrack = birthnum2022 if on_track == 1
egen tot_w_indicator_ontrack = total(weighted_indicator_ontrack)
egen total_weight_ontrack = total(weight_ontrack)
gen weighted_coverage_ontrack = tot_w_indicator_ontrack / total_weight_ontrack
rename weighted_coverage_ontrack weighted_SAB_ontrack

drop weighted_indicator_ontrack weight_ontrack tot_w_indicator_ontrack total_weight_ontrack 

* For off-track countries, calculate the weighted coverage
gen weighted_indicator_offtrack = Skilledhealthpers * birthnum2022 if off_track == 1
gen weight_offtrack = birthnum2022 if off_track == 1
egen tot_w_indicator_offtrack = total(weighted_indicator_offtrack)
egen total_weight_offtrack = total(weight_offtrack)
gen weighted_coverage_offtrack = tot_w_indicator_offtrack/ total_weight_offtrack
rename weighted_coverage_offtrack weighted_SAB_offtrack

drop weighted_indicator_offtrack weight_offtrack tot_w_indicator_offtrack total_weight_offtrack 

* SAB weighted coverage 
* For on-track countries, calculate the weighted coverage
destring Antenatalcare, replace

gen weighted_indicator_ontrack = Antenatalcare * birthnum2022 if on_track == 1
gen weight_ontrack = birthnum2022 if on_track == 1
egen tot_w_indicator_ontrack = total(weighted_indicator_ontrack)
egen total_weight_ontrack = total(weight_ontrack)
gen weighted_coverage_ontrack = tot_w_indicator_ontrack / total_weight_ontrack
rename weighted_coverage_ontrack weighted_ANC4_ontrack

drop weighted_indicator_ontrack weight_ontrack tot_w_indicator_ontrack total_weight_ontrack 

// For off-track countries, calculate the weighted coverage
gen weighted_indicator_offtrack = Antenatalcare * birthnum2022 if off_track == 1
gen weight_offtrack = birthnum2022 if off_track == 1
egen tot_w_indicator_offtrack = total(weighted_indicator_offtrack)
egen total_weight_offtrack = total(weight_offtrack)
gen weighted_coverage_offtrack = tot_w_indicator_offtrack/ total_weight_offtrack
rename weighted_coverage_offtrack weighted_ANC4_offtrack

drop weighted_indicator_offtrack weight_offtrack tot_w_indicator_offtrack total_weight_offtrack 

*** B.2 Copy to excels to do data visualization










