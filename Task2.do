*************************************************************************
* UNICEF P3 Assessment

* RQ: Evolution of education for 4- to 5-year-old children
* Understanding how educational performance evolves month by month at these critical ages, considering both general education and specific subjects (e.g., literature and math, physical education)

*: B. Analysis
*************************************************************************

*** CALIBRATING DIRECTORIES
clear all
set more off

global maindir "C:\Users\Administrator\Downloads"
global unicef "$maindir\UNICEF-P3-assessment-public-main\UNICEF-P3-assessment-public-main\01_rawdata"

* Read in the csv file
import delimited "$unicef\Zimbabwe_children_under5_interview.csv"

* Data cleaning
replace ec6 = 0 if ec6 == 8 | ec6 == 9
replace ec7 = 0 if ec7 == 8 | ec7 == 9
replace ec8 = 0 if ec8 == 8 | ec8 == 9
replace ec9 = 0 if ec9 == 8 | ec9 == 9
replace ec10 = 0 if ec10 == 8 | ec10 == 9
replace ec11 = 0 if ec11 == 8 | ec11 == 9
replace ec12 = 0 if ec12 == 8 | ec12 == 9
replace ec13 = 0 if ec13 == 8 | ec13 == 9
replace ec14 = 0 if ec14 == 8 | ec14 == 9
replace ec15 = 0 if ec15 == 8 | ec15 == 9

replace ec6 = 0 if ec6 == 2
replace ec7 = 0 if ec7 == 2
replace ec8 = 0 if ec8 == 2
replace ec9 = 0 if ec9 == 2
replace ec10 = 0 if ec10 == 2
replace ec11 = 0 if ec11 == 2
replace ec12 = 0 if ec12 == 2
replace ec13 = 0 if ec13 == 2
replace ec14 = 0 if ec14 == 2
replace ec15 = 0 if ec15 == 2

* Calculate a table of summary statistics showing the percent 
local vars ec6-ec15

foreach var of varlist `vars' {
    sum `var' if child_age_years == 3
}

local vars ec6-ec15

foreach var of varlist `vars' {
    sum `var' if child_age_years == 4
}

** Copy to excels

* Calculate arithmetic average of the 10 items
egen index = rowmean(ec6 ec7 ec8 ec9 ec10 ec11 ec12 ec13 ec14 ec15)

* Calculate the Cronbach's Alpha of the index and report it in a table along with the number of observations
alpha ec6 ec7 ec8 ec9 ec10 ec11 ec12 ec13 ec14 ec15
matrix result = (r(alpha), r(N))
matrix colnames result = Cronbachs_Alpha N_observations
matrix list result

* Calculate ages in months
gen interview_date_new = date(interview_date, "YMD")
gen birth_date_new = date(child_birthday, "YMD")

gen birthyear = year(birth_date_new) //26 missing
gen birthmonth = month(birth_date_new) //26 missing
gen interviewyear = year(interview_date_new)
gen interviewmonth = month(interview_date_new)

gen month_gap = (interviewyear - birthyear) * 12 + (interviewmonth - birthmonth)

save "$unicef\Zimbabwe.dta", replace

* Calculate the conditional mean
collapse (mean) mean_index=index, by(month_gap)

* Plot the conditional mean
twoway (line mean_index month_gap ), ///
       title("Conditional Mean of Index by Child's Age in Months") ///
       xlabel(, grid) ///
       ylabel(, grid) ///
       xtitle("Child's Age in Months") ///
       ytitle("Mean Index")

* Run the regression 
use "$unicef\Zimbabwe.dta"
regress index month_gap
esttab using results.txt, replace se r2 ar2 scalars(N) label
	
	
	
	
	
	
	
	
