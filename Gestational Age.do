*********************************************************
*Calculating Gestational Age
*PRiSMA 
*Last Updated: 05/23/2022 by ALB
*********************************************************

*Working Directory - should be updated by user
cd "" // UPDATE BY USER


*Do Files For Form Merge and Data Cleaning
include "ReMAPP-Data-Cleaning-Form-Merge.do"

*********************************************************
*Step 1: Data Cleaning

*destring variables
foreach x of varlist M06_US_GA_WEEKS_AGE1 M06_US_GA_DAYS_AGE1 M01_GEST_AGE_WKS_SCORRES ///
					 M01_GEST_AGE_MOS_SCORRES M06_CRL_MEAN_FAORRES1 M06_BPD_FAORRES1 ///
					 M06_FL_FAORRES1 M06_HC_FAORRES1 {
			replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED" | `x' == "NaN")
			destring `x', replace 
		}
		
		*gen byte flag_notnumeric = real(M06_CRL_MEAN_FAORRES1)==.

*converting dates to date format
foreach x of varlist M01_LMP_SCDAT M01_SCRN_OBSSTDAT M01_EDD_SCDAT M11_INF_1_DSSTDAT {
		replace `x' = "" if(`x' =="SKIPPED")
		gen date2=date(`x', "DMY") 
		rename `x' `x'_str
		rename date2 `x'
		format `x' %d 
		}

*********************************************************
*Step 2: Calculate the EDD based on first ultrasound in M06

	gen M06_US_OHOSTDAT1_dt=date(M06_US_OHOSTDAT1, "DMY")


	gen EDDATUSG=(M06_US_OHOSTDAT1_dt - M06_US_GA_WEEKS_AGE1*7 - M06_US_GA_DAYS_AGE1) + 280
	label var EDDATUSG "EDD based on first ultrasound"


*********************************************************
*Step 3: Calculate EDD based on both LMP date, ultrasound, and estimation

*calculate EDD by last menstrual date (LMP)
    gen LMPEDD = M01_LMP_SCDAT + 280
	format LMPEDD  %d 
	label var LMPEDD "EDD based on date of last menstrual cycle"
	
*calculate EDD by estimated GA weeks
    gen EDDUSGEST_WKS = (M01_SCRN_OBSSTDAT - M01_GEST_AGE_WKS_SCORRES * 7) + 280
	
*calculate EDD by estimated GA months
    gen EDDUSGEST_MOS = (M01_SCRN_OBSSTDAT - M01_GEST_AGE_MOS_SCORRES * 30.5) + 280
	
*take estimated GA weeks first, if NA, then take estimated GA months
    gen EDDUSGEST = . 
	replace EDDUSGEST = EDDUSGEST_WKS
	replace EDDUSGEST = EDDUSGEST_MOS if EDDUSGEST_WKS==.
	format EDDUSGEST %d
	label var EDDUSGEST "EDD based estimated gestational weeks"
	
*calculate GA in days at enrollment, based on ultrasound EDD
    gen GAUSGSCRNDAYS = (M01_SCRN_OBSSTDAT - (EDDATUSG - 280))
	label var GAUSGSCRNDAYS "gestational age at enrollment based on ultrasound EDD"
	
	
*calculate GA in days at enrollment, based on LMP
    gen GALMPSCRNDAYS = M01_SCRN_OBSSTDAT - M01_LMP_SCDAT
	label var GALMPSCRNDAYS "gestational age at enrollment based on LMP"
	
	
*absolute difference between GA days (LMP) and GA days (USG)
    gen GA_LMP_USG_DIFF = abs(GALMPSCRNDAYS - GAUSGSCRNDAYS)
	label var  GA_LMP_USG_DIFF "absolute difference between LMP vs USG GA days at enrollment"
	
*******************************************************************************
*determine the best source of calculating EDD
 /* 1: Use LMPEDD if 
		1) ultrasound GA weeks is between [16, 21] and 
			absolute difference between ultrasound GA days and LMP GA days <= 10, or
		2) ultrasound GA weeks is between [22, 27] and 
			absolute difference between ultrasound GA days and LMP GA days <= 14, or
		3) ultrasound GA weeks is greater than 28 and 
			absolute difference between ultrasound GA days and LMP GA days <= 21
    2: Use EDDATUSG if
		1) ultrasound GA weeks is between [0, 15], or
		2) ultrasound GA weeks is between [16, 21] and 
			absolute difference between ultrasound GA days and LMP GA days > 10, or
		3) ultrasound GA weeks is between [22, 27] and 
			absolute difference between ultrasound GA days and LMP GA days > 14, or
		4) ultrasound GA weeks is greater than 28 and 
			absolute difference between ultrasound GA days and LMP GA days > 21
     3: Use EDDATUSG if GAUSGSCRNDAYS is not missing
     4: Use LMPEDD if GALMPSCRNDAYS is not missing
     5: use M01_EDD_SCDAT if M01_EDD_SCDAT is not missing
     6: otherwise set as NA */



gen BESTEDD =.
	replace BESTEDD=LMPEDD if ((M06_US_GA_WEEKS_AGE1 >= 16) & (M06_US_GA_WEEKS_AGE1 <= 21) & (GA_LMP_USG_DIFF <= 10)) | ///
       ((M06_US_GA_WEEKS_AGE1 >= 22) & (M06_US_GA_WEEKS_AGE1 <= 27) & (GA_LMP_USG_DIFF <= 14)) | ///
       ((M06_US_GA_WEEKS_AGE1 > 28) & (GA_LMP_USG_DIFF <= 21))
	   
	replace BESTEDD=EDDATUSG if ((M06_US_GA_WEEKS_AGE1 >= 0) & (M06_US_GA_WEEKS_AGE1 <= 15)) | ///
       ((M06_US_GA_WEEKS_AGE1 >= 16) & (M06_US_GA_WEEKS_AGE1 <= 21) & (GA_LMP_USG_DIFF > 10)) | ///
       ((M06_US_GA_WEEKS_AGE1 >= 22) & (M06_US_GA_WEEKS_AGE1 <= 27) & (GA_LMP_USG_DIFF > 14)) | ///
       ((M06_US_GA_WEEKS_AGE1 > 28) & (GA_LMP_USG_DIFF > 21)) 
	
	replace BESTEDD=EDDATUSG if GALMPSCRNDAYS==.
	
	replace BESTEDD=LMPEDD if GAUSGSCRNDAYS==.
	
	replace BESTEDD=M01_EDD_SCDAT if GALMPSCRNDAYS==. & GAUSGSCRNDAYS==.
   
*************************************************************************
*step 5: calculate GA at birth based on BESTEDD
gen GA_LABOR = (M11_INF_1_DSSTDAT - (BESTEDD - 280))/7


**************************************************************************
*step 6: histograms

*Histogram of gestational age at birth
hist GA_LABOR

   *Indicator of outlier, if GA_LBAOR is outside the range (0, 42], it's an outlier
         gen GA_LABOR_OUTLIER = . 
		 replace GA_LABOR_OUTLIER=1 if (GA_LABOR <=0 | GA_LABOR > 42) 
		 
	*Histogram of gestation age at birth with outliers removed
		 hist GA_LABOR if GA_LABOR_OUTLIER!=1
		 

gen gestage_enroll=(M01_SCRN_OBSSTDAT - (BESTEDD - 280))/7
hist gestage_enroll

**************************************************************************
*Step 7: Ultrasound measurements
*Gestage at ultrasound
gen GA_ultra1 = (M06_visit_date1 - (BESTEDD - 280))/7
   
   sum GA_ultra1

**Crown-Rump Length (mm)
gen M06_CRL_MEAN_CM_FAORRES1=M06_CRL_MEAN_FAORRES1/10 // converting to CM

	*summary statistics
	sum(M06_CRL_MEAN_CM_FAORRES1) if (GA_ultra1>8 & GA_ultra1<14)
	histogram(M06_CRL_MEAN_CM_FAORRES1) if (GA_ultra1>8 & GA_ultra1<14)


	*Idenitfying outliers - based on intergrowth standards. Outliers are observations <1 or >9.5 cm for Gestational age >8 & <14 weeks
	gen CRL_out=.
		replace CRL_out=1 if (GA_ultra1>8 & GA_ultra1<14 & M06_CRL_MEAN_CM_FAORRES1!=. & (M06_CRL_MEAN_CM_FAORRES1<=1 | M06_CRL_MEAN_CM_FAORRES1>9.5))
		replace CRL_out=0 if (GA_ultra1>8 & GA_ultra1<14 & (M06_CRL_MEAN_CM_FAORRES1>1 & M06_CRL_MEAN_CM_FAORRES1<=9.5))
		
	tab CRL_out if (GA_ultra1>8 & GA_ultra1<14)
		
	tab CRL_out if (GA_ultra1>8 & GA_ultra1<14), miss 


**Biparietal diameter

	*summary statistics
	sum(M06_BPD_FAORRES1) if (GA_ultra1>14 & GA_ultra1<41)
	histogram(M06_BPD_FAORRES1) if (GA_ultra1>14 & GA_ultra1<41)

	*Idenitfying outliers - based on intergrowth standards. Outliers are observations <2.44 or >10.67 cm for Gestational age >14 & <41 weeks
	gen BPD_out=.
		replace BPD_out=1 if (GA_ultra1>14 & GA_ultra1<41 & M06_BPD_FAORRES1!=. & (M06_BPD_FAORRES1<2.44 | M06_BPD_FAORRES1>10.67))
		replace BPD_out=0 if (GA_ultra1>14 & GA_ultra1<41 & (M06_BPD_FAORRES1>2.44 & M06_BPD_FAORRES1<=10.67))

	tab BPD_out if (GA_ultra1>14 & GA_ultra1<41), 
		
	tab BPD_out if (GA_ultra1>14 & GA_ultra1<41), miss 

**Femur Length

	*summary statistics
	sum(M06_FL_FAORRES1) if (GA_ultra1>14 & GA_ultra1<41)
	histogram(M06_FL_FAORRES1) if (GA_ultra1>14 & GA_ultra1<41)
	
	*Idenitfying outliers - based on intergrowth standards. Outliers are observations <0.86 or >8.18 cm for Gestational age >14 & <41 weeks
	gen FL_out=.
		replace FL_out=1 if (GA_ultra1>14 & GA_ultra1<41 & M06_FL_FAORRES1!=. & (M06_FL_FAORRES1<.86 | M06_FL_FAORRES1>8.18))
		replace FL_out=0 if (GA_ultra1>14 & GA_ultra1<41 & (M06_FL_FAORRES1>0.86 & M06_FL_FAORRES1<=8.18))

	tab FL_out if (GA_ultra1>14 & GA_ultra1<41),
		
	tab FL_out if (GA_ultra1>14 & GA_ultra1<41), miss 


**Head Circumference 

	*summary statistics
	sum(M06_HC_FAORRES1) if (GA_ultra1>14 & GA_ultra1<41)
	histogram(M06_HC_FAORRES1) if (GA_ultra1>14 & GA_ultra1<41)
	
	*Idenitfying outliers - based on intergrowth standards. Outliers are observations <8.1 or >37.3 cm for Gestational age >14 & <41 weeks
	gen HC_out=.
		replace HC_out=1 if (GA_ultra1>14 & GA_ultra1<41 & M06_HC_FAORRES1!=. & (M06_HC_FAORRES1<8.1 | M06_FL_FAORRES1>37.3))
		replace HC_out=0 if (GA_ultra1>14 & GA_ultra1<41 & (M06_HC_FAORRES1>8.1 & M06_HC_FAORRES1<=37.3))

	tab HC_out if (GA_ultra1>14 & GA_ultra1<41), row
		
	tab HC_out if (GA_ultra1>14 & GA_ultra1<41), row miss 
  

