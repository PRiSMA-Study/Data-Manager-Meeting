****************************************************************
*ReMAPP Healthy Cohort Eligibility Criteria
*Last Updated: 05/27/2022 ALB
*Users: ALB 
****************************************************************

*Working Directory - should be updated by user
cd "/Users/Alexa/Documents/Side Research Projects/Smith Lab/Anemia/Local_git/Data-Manager-Meeting" // UPDATE BY USER


*Do Files For Form Merge and Data Cleaning
include "ReMAPP-Data-Cleaning-Form-Merge.do"

***************************************************************
*Label values used throughout the code
 label define yesno 0 "no" 1 "yes"

 label define yesno1 0 "no" 1 "yes" 9 "unknown"



****************************************************************
*Table 1.a: Enrollment numbers for PRiSMA MNH Study

	*Creating variable for screened for PRiSMA - currently based on if date of screening recorded
		gen screened_prisma=.
		replace screened_prisma = 1 if M01_SCRN_OBSSTDAT!=""
		replace screened_prisma =0 if M01_SCRN_OBSSTDAT==""
		label var screened_prisma "Participant was screened for enrollment"
		label values screened_prisma yesno

	*Creating variable for eligibility for PRiSMA
		gen eligible_prisma=.
		replace eligible_prisma= 1 if (M01_AGE_IEORRES == 1 & M01_PC_IEORRES == 1 & M01_EXCL_YN_IEORRES == 0) 
		replace eligible_prisma=0 if (M01_AGE_IEORRES != 1 | M01_PC_IEORRES != 1 | M01_EXCL_YN_IEORRES != 0) 
		label var eligible_prisma "Participant was found eligible for PRiSMA"
		label values eligible_prisma yesno
		
	*Creating variable for enrolled for PRiSMA - this is assuming you cannot consent and not enroll
		gen enrolled_prisma=.
		replace enrolled_prisma=1 if (M01_CON_SIGNYN_DSDECOD==1 & M01_CON_YN_DSDECOD==1)
		replace enrolled_prisma=0 if (M01_CON_SIGNYN_DSDECOD!=1 | M01_CON_YN_DSDECOD!=1)
		label var enrolled_prisma "Participant enrolled for PRiSMA"
		label values enrolled_prisma yesno
		
		*checkings on enrollment numbers
		table eligible_prisma enrolled_prisma, by(screened_prisma)
		
****************************************************************
*Demographic variables for PRiSMA MNH Study 

	*Creating maternal age at enrollment variable - using date at enrollment  
		
		*cleaning date variables
		gen dob=date(M01_BRTHDAT , "DMY")
		gen scrn_date=date(M01_SCRN_OBSSTDAT, "DMY")
		format scrn_date %d
	
		*cleaning age variable
		replace M01_ESTIMATED_AGE="" if(M01_ESTIMATED_AGE=="SKIPPED" | M01_ESTIMATED_AGE=="UNDEFINED")
		destring M01_ESTIMATED_AGE, replace 
		
		*maternal age at enrollment 
		gen mat_age_enroll=.
		replace mat_age_enroll=(scrn_date-dob)/365
		replace mat_age_enroll=M01_ESTIMATED_AGE if mat_age_enroll==.
		label var mat_age_enroll "Maternal age at enrollment"
		
		*summary of maternal age
		summ mat_age_enroll
		
	*Creating BMI at enrollment variable - using date at enrollment
	
	
	*Creating variable for gestational age at enrollment 
		
		*converting dates of LMP and screening to date format
		foreach x of varlist M01_LMP_SCDAT M01_SCRN_OBSSTDAT {
		replace `x' = "" if(`x' =="SKIPPED")
		gen date2=date(`x', "DMY") 
		rename `x' `x'_str
		rename date2 `x'
		format `x' %d 
	}
	
		*converting estimated gestational age variables to numeric
		foreach x of varlist M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES {
		replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
		destring `x', replace 
		}
	
		*calculating last menstrual cycle (LMP) for all participants
		gen lmp_cal=.
		replace lmp_cal=M01_LMP_SCDAT if(M01_LMP_SCDAT!=.)
		replace lmp_cal=M01_SCRN_OBSSTDAT-(M01_GEST_AGE_WKS_SCORRES*7) if(M01_LMP_SCDAT==. & M01_GEST_AGE_MOS_SCORRES ==. )
		replace lmp_cal=M01_SCRN_OBSSTDAT-(M01_GEST_AGE_MOS_SCORRES*30.5) if (M01_LMP_SCDAT==. & M01_GEST_AGE_WKS_SCORRES==.)
		format lmp_cal %d
		label var lmp_cal "Calculated date of LMP at enrollment - incl est gest age"

		*calculating gestage at enrollment for all participants
			*in days
			gen gestage_days_enroll=.
			replace gestage_days_enroll=(M01_SCRN_OBSSTDAT-lmp_cal)
			label var gestage_days_enroll "Gestational age at enrollment (days)"
		
			*in weeks
			gen gestage_weeks_enroll=.
			replace gestage_weeks_enroll=gestage_days_enroll/7
			label var gestage_weeks_enroll "Gestational age at enrollment (weeks)"
		
				summ gestage_weeks_enroll
				
				*looking at implausible gestational age at enrollment <4 weeks or >42
				list CASEID M01_SCRN_OBSSTDAT M01_LMP_SCDAT M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES lmp_cal gestage_days_enroll gestage_weeks_enroll if gestage_weeks_enroll>42 & gestage_weeks_enroll!=.
				
				*looking at implausible gestational age at enrollment <4 weeks or >42
				list CASEID M01_SCRN_OBSSTDAT M01_LMP_SCDAT M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES lmp_cal gestage_days_enroll gestage_weeks_enroll if gestage_weeks_enroll<4 & gestage_weeks_enroll!=.
			
		
		*in trimesters
		gen tri_enroll=.
		replace tri_enroll=1 if(gestage_weeks_enroll>3 & gestage_weeks_enroll<14)
		replace tri_enroll=2 if(gestage_weeks_enroll>=14 & gestage_weeks_enroll<27)
		replace tri_enroll=3 if(gestage_weeks_enroll>=27 & gestage_weeks_enroll<43)	
	
	*Marital Status - married or cohabitating
		
		label define marital_stat1 1 "Married" 2 "Not married but living with partner" 3 "Divorced/seperated" 4 "Widowed" 5 "Single - never married"
		label values M02_MARITAL_SCORRES marital_stat1
		tab M02_MARITAL_SCORRES
		
		*creating variable for married or cohabitating - combining 1 and 2 categories of M02_MARITAL_SCORRES
		gen married=.
		replace married=1 if (M02_MARITAL_SCORRES==1 | M02_MARITAL_SCORRES==2)
		replace married=0 if (M02_MARITAL_SCORRES==3 | M02_MARITAL_SCORRES==4 | M02_MARITAL_SCORRES==5)
		label var married "Participant married or cohabitating at enrollment?"
		label values married yesno
		
	*Creating variable for nulliparious - defined as woman who has not had a live birth
		
		*converting variables M03a_PH_LIVE_RPORRES to numeric
		foreach x of varlist M03a_PH_LIVE_RPORRES {
		replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
		destring `x', replace 
		}
		
		gen nulliparous=.
		replace nulliparous=1 if (M03a_PH_PREV_RPORRES==0 | M03a_PH_LIVE_RPORRES ==0)
		replace nulliparous=0 if (M03a_PH_LIVE_RPORRES >=1 & M03a_PH_LIVE_RPORRES!=.)
		label var nulliparous "No report of prior live birth"
		label values nulliparous yesno
		
		
****************************************************************
*Table 1.1: Aim 1 inclusion criteria for those enrolled in PRiSMA
	*All variables will start with aim1e_* - those screend but not enrolled will have missing values for all variables
	
	*1. Age 18-35
		gen aim1e_mage=.
		replace aim1e_mage=1 if (mat_age_enroll>=18 & mat_age_enroll<=35)
		replace aim1e_mage=0 if (mat_age_enroll<18 | mat_age_enroll>35)
		replace aim1e_mage=9 if mat_age_enroll==.
		replace aim1e_mage=. if enrolled_prisma==0
		label var aim1e_mage "Aim 1 Eligibility: Age 18-35"
		label values aim1e_mage yesno1
		
	
	*2. Gestational age <14 weeks
		gen aim1e_gestage=.
		replace aim1e_gestage=1 if (gestage_weeks_enroll>3 & gestage_weeks_enroll<14) 
		replace aim1e_gestage=0 if (gestage_weeks_enroll>=14 & gestage_weeks_enroll!=.)
		replace aim1e_gestage=9 if gestage_weeks_enroll==.
		replace aim1e_gestage=. if enrolled_prisma==0
		label var aim1e_gestage "Aim 1 Eligibility: Gestational age at enrollment <14"
		label values aim1e_gestage yesno1
		
		tab aim1e_gestage
	
	*3. BMI in early pregnancy (currenlty first trimester)
		
		*destring maternal weight measure
			replace M05_WEIGHT_PERES1="" if (M05_WEIGHT_PERES1 =="SKIPPED")
			replace M05_WEIGHT_PERES1="60.9" if (M05_WEIGHT_PERES1=="60.9i")
			replace M05_WEIGHT_PERES1="44.5" if (M05_WEIGHT_PERES1=="44.5.")
			destring M05_WEIGHT_PERES1, replace 
			
			*gen byte flag_notnumeric = real(M05_WEIGHT_PERES1)==.
			
		*destring maternal height measure
			replace M05_HEIGHT_PERES1="" if (M05_HEIGHT_PERES1== "SKIPPED")
			replace M05_HEIGHT_PERES1="158.4" if (M05_HEIGHT_PERES1=="158.4.")
			destring M05_HEIGHT_PERES1, replace 
			
			/*gen byte flag_notnumeric = real(M05_HEIGHT_PERES1)==.
			list M05_HEIGHT_PERES1 if flag_notnumeric==1*/
		
		*gestage at anthropometric measure 
			
			*M05_ANT_PEDAT1 - date of 1st anthropometric measure
			foreach x of varlist M05_ANT_PEDAT1 {
			replace `x' = "" if(`x' =="SKIPPED")
			gen date2=date(`x', "DMY") 
			rename `x' `x'_str
			rename date2 `x'
			format `x' %d 
		}
		
			gen gestage_anthro1=(M05_ANT_PEDAT1-lmp_cal)/7 if M05_WEIGHT_PERES1!=.
			label var gestage_anthro1 "Gestational age at 1st anthropometric measure" 
			
		*calculating BMI at 1st anthropometric visit
			gen BMI_1=M05_WEIGHT_PERES1/((M05_HEIGHT_PERES1/100)^2)
			label var BMI_1 "BMI at 1st anthropometric measure"
			
		*Aim 1 BMI Criteria
			gen aim1e_bmi=.
			replace aim1e_bmi=1 if (BMI_1>=18.5 & BMI_1<30) 
			replace aim1e_bmi=0 if (BMI_1<18.5 | BMI_1>=30) 
			replace aim1e_bmi=9 if (BMI_1==. | gestage_anthro1>20)
			replace aim1e_bmi=. if enrolled_prisma==0
			label var aim1e_bmi "Aim 1 Eligibility: BMI during early pregnancy"
			label values aim1e_bmi yesno1
	
	*4. MUAC > 23cm
	
		*Destring muac
		replace M05_MUAC_PERES1="" if (M05_MUAC_PERES1== "SKIPPED")
		destring M05_MUAC_PERES1, replace 

		
		gen aim1e_muac=.
		replace aim1e_muac=1 if (M05_MUAC_PERES1 >23 & M05_MUAC_PERES1!=.)
		replace aim1e_muac=0 if M05_MUAC_PERES1<=23
		replace aim1e_muac=9 if M05_MUAC_PERES1==.
		replace aim1e_muac=. if enrolled_prisma==0
		label var aim1e_muac "Aim 1 Eligibility: MUAC >23cm"
		label values aim1e_muac yesno1
	
	*5. Height > 153 cm
		gen aim1e_height=.
		replace aim1e_height=1 if (M05_HEIGHT_PERES1 >153 & M05_HEIGHT_PERES1!=.)
		replace aim1e_height=0 if M05_HEIGHT_PERES1<=153
		replace aim1e_height=9 if M05_HEIGHT_PERES1==.
		replace aim1e_height=. if enrolled_prisma==0
		label var aim1e_height "Aim 1 Eligibility: Height >153cm"
		label values aim1e_height yesno1
		

	*6. Single Fetus 
	
	 *Destring singleton 
		replace M06_SINGLE_FAORRES1  ="" if (M06_SINGLE_FAORRES1  == "SKIPPED" | M06_SINGLE_FAORRES1 == "UNDEFINED")
		destring M06_SINGLE_FAORRES1, replace 
		
		gen aim1e_singleton=.
		replace aim1e_singleton=1 if M06_SINGLE_FAORRES1==1
		replace aim1e_singleton=0 if M06_SINGLE_FAORRES1==0
		replace aim1e_singleton=9 if M06_SINGLE_FAORRES1 ==.
		replace aim1e_singleton=. if enrolled_prisma==0
		label var aim1e_singleton "Aim 1 Eligibility: Singleton fetus"
		label values aim1e_singleton yesno1
		
	*7. Normal blood pressure - at enrollment
		foreach x of varlist M08_BPAVG_SYS_VSORRES1 M17_BP_SYS_VSORRES1 M08_BPAVG_DIA_VSORRES1 M17_BP_DIA_VSORRES1 {
		replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
		destring `x', replace 
		}
		
		gen sysbp_norm=.
		replace sysbp_norm=1 if M08_BPAVG_SYS_VSORRES1<140
		replace sysbp_norm=1 if M17_BP_SYS_VSORRES1<140
		replace sysbp_norm=0 if (M08_BPAVG_SYS_VSORRES1>=140 & M08_BPAVG_SYS_VSORRES1!=.)
		replace sysbp_norm=0 if (M17_BP_SYS_VSORRES1>=140 & M17_BP_SYS_VSORRES1!=.)
		replace sysbp_norm=9 if (M08_BPAVG_SYS_VSORRES1==. & M17_BP_SYS_VSORRES1==.)
		
		
		gen diabp_norm=.
		replace diabp_norm=1 if M08_BPAVG_DIA_VSORRES1<90
		replace diabp_norm=1 if M17_BP_DIA_VSORRES1<90
		replace diabp_norm=0 if (M08_BPAVG_DIA_VSORRES1>=90 & M08_BPAVG_DIA_VSORRES1!=.) 
		replace diabp_norm=0 if (M17_BP_DIA_VSORRES1>=90 & M17_BP_DIA_VSORRES1!=.)
		replace diabp_norm=9 if (M08_BPAVG_DIA_VSORRES1==. & M17_BP_DIA_VSORRES1==.)
		
		
		gen aim1e_bp=.
		replace aim1e_bp=1 if (sysbp_norm==1 & diabp_norm==1)
		replace aim1e_bp=0 if (sysbp_norm==0 | diabp_norm==0)
		replace aim1e_bp=9 if (sysbp_norm==9 | diabp_norm==9)
		replace aim1e_bp=. if enrolled_prisma==0
		label var aim1e_bp "Aim 1 Eligibility: Normal blood pressue - SBP<140 & DBP<90"
		label values aim1e_bp yesno1
		
		drop sysbp_norm diabp_norm
		
	*8. Miscarriage in two consecutive pregnancies 
			foreach x of varlist M03b_PH2_BS_RPORRES M03b_PH3_BS_RPORRES  {
			replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
			destring `x', replace 
			}
		 
		 gen miscarriage_1=0
		 replace miscarriage_1=1 if M03b_PH_BS_RPORRES==3
		 
		 gen miscarriage_2=0
		 replace miscarriage_2=1 if M03b_PH2_BS_RPORRES==3
		 
		 gen miscarriage_3=0
		 replace miscarriage_3=1 if M03b_PH3_BS_RPORRES==3
		 
		 gen miscarriage_tot=miscarriage_1+miscarriage_2+miscarriage_3
		 
		 gen aim1e_miscarriage=.
		 replace aim1e_miscarriage=1 if (M03a_PH_PREV_RPORRES==0) //women who were never pregnant
		 replace aim1e_miscarriage=1 if (miscarriage_tot<2)	
		 replace aim1e_miscarriage=0 if (miscarriage_tot>=2)
		 replace aim1e_miscarriage=9 if (miscarriage_tot==. & M03a_PH_PREV_RPORRES==1)
		 replace aim1e_bp=. if enrolled_prisma==0	
		 label var aim1e_miscarriage "Aim 1 Eligibility: <=1 miscarriage in two consecutive pregnancies"
		 label values aim1e_miscarriage yesno1
		
	*9. No preterm delivery or low birthweight 
		foreach x of varlist M03b_LB_WEIGHT  M03b_LB2_WEIGHT M03b_LB3_WEIGHT M04_LOWBIRTHWT_RPORRES* M04_PRETERM_RPORRES* M03b_LB_LENGTH_RPORRES ///
		M03b_LB2_LENGTH_RPORRES M03b_LB3_LENGTH_RPORRES M04_BIRTH_RPORRES1 {
			replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
			destring `x', replace 
			}
		
		*Checks - this is a list of variable that have birthweights outside of expected ranges
		list CASEID M04_LOWBIRTHWT_RPORRES*  M03b_LB_WEIGHT if (M03b_LB_WEIGHT<500 | (M03b_LB_WEIGHT>5000 & M03b_LB_WEIGHT!=.))
		list CASEID M04_LOWBIRTHWT_RPORRES*  M03b_LB2_WEIGHT if (M03b_LB2_WEIGHT<500 | (M03b_LB2_WEIGHT>5000 & M03b_LB2_WEIGHT!=.))
		list CASEID M04_LOWBIRTHWT_RPORRES*  M03b_LB3_WEIGHT if (M03b_LB3_WEIGHT<500 | (M03b_LB3_WEIGHT>5000 & M03b_LB3_WEIGHT!=.))
		
		gen any_lbw=0
		replace any_lbw=1 if (M04_LOWBIRTHWT_RPORRES1==1)
		replace any_lbw=1 if (M03b_LB_WEIGHT<2500 | M03b_LB2_WEIGHT<2500 | M03b_LB3_WEIGHT<2500)
		replace any_lbw=9 if (M04_BIRTH_RPORRES1==1 & M04_LOWBIRTHWT_RPORRES1==99)
		
		*Any preterm
		gen any_preterm=0
		replace any_preterm=0 if (M04_BIRTH_RPORRES1==0)
		replace any_preterm=0 if (M04_PRETERM_RPORRES1==0)
		replace any_preterm=1 if (M04_PRETERM_RPORRES1==1)
		replace any_preterm=9 if (M04_BIRTH_RPORRES1==1 & M04_PRETERM_RPORRES1==99)
		
		gen aim1e_lbw=.
		replace aim1e_lbw=1 if M03a_PH_PREV_RPORRES==0 //women who were never pregnant
		replace aim1e_lbw=1 if (any_lbw==0 & any_preterm==0)
		replace aim1e_lbw=0 if (any_lbw==1 | any_preterm==1)
		replace aim1e_lbw=9 if (M03a_PH_PREV_RPORRES==1 & (any_lbw==9 | any_preterm==9))
		replace aim1e_lbw=. if enrolled_prisma==0	
		label var aim1e_lbw "Aim 1 Eligibility: no previous preterm or lbw delivery"
		label values aim1e_lbw yesno1
	
	*9. No previous neonatal or fetal death
		*neonatal death is defined <28 days old
		foreach x of varlist M03b_LB_DEATH_CAT_AGE M03b_LB2_DEATH_CAT_AGE M03b_LB3_DEATH_CAT_AGE {
			replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
			destring `x', replace 
			}
		
	    gen any_neodeath=0
		replace any_neodeath=1 if (M03b_LB_DEATH_CAT_AGE==1 | M03b_LB2_DEATH_CAT_AGE == 1 | M03b_LB_DEATH_CAT_AGE == 1)
		
		gen any_stillbirth=0
		replace any_stillbirth=1 if (M03b_PH_BS_RPORRES==2 | M03b_PH2_BS_RPORRES == 2 | M03b_PH3_BS_RPORRES == 2)
		
		gen aim1e_death=.
		replace aim1e_death=1 if M03a_PH_PREV_RPORRES==0 //women who were never pregnant
		replace aim1e_death=1 if (any_neodeath==0 & any_stillbirth==0)
		replace aim1e_death=0 if (any_neodeath==1 | any_stillbirth==1)
		replace aim1e_death=9 if (M03a_PH_PREV_RPORRES==1 & (any_neodeath==9 | any_stillbirth==9))
		replace aim1e_death=. if enrolled_prisma==0	
		label var aim1e_death "Aim 1 Eligibility: no previous neonatal or fetal death"
		label values aim1e_death yesno1
	
	
	*10. No history of previous pregnancy complications
		/*unplanned Cesarean delivery; 
		occurrence: preeclampsia/eclampsia, gestational diabetes, premature rupture of membranes (before labor began), 
		macrosomia (>4000g), oligohydramnios, antepartum hemorrhage, postpartum hemorrhage
		*pregnancy history in MNH04

		* ever pregnant - BIRTH_RPORRES1
		* pre-eclampsia - M04_PREECLAMPSIA_RPORRES1
		* gestational diabetes - M04_GEST_DIAB_RPORRES1 */
		
		foreach x of varlist M04_UNPL_CESARIAN_PROCCUR1 M04_PREECLAMPSIA_RPORRES1 M04_GEST_DIAB_RPORRES1 M04_PREMATURE_RUPTURE_RPORRES1 M04_MACROSOMIA_RPORRES1 ///
		M04_OLIGOHYDRAMNIOS_RPORRES1 M04_APH_RPORRES1 M04_PPH_RPORRES1 {
			replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
			destring `x', replace 
			}
		
		gen aim1e_otpreg_comp=.
		replace aim1e_otpreg_comp=1 if M04_BIRTH_RPORRES1==0
		replace aim1e_otpreg_comp=1 if M04_BIRTH_RPORRES1==1 & M04_UNPL_CESARIAN_PROCCUR1==0 & M04_PREECLAMPSIA_RPORRES1==0 & M04_GEST_DIAB_RPORRES1 ==0 & ///
															   M04_PREMATURE_RUPTURE_RPORRES1==0 & M04_MACROSOMIA_RPORRES1==0 & M04_OLIGOHYDRAMNIOS_RPORRES1 ==0  & ///
															   M04_APH_RPORRES1 ==0 & M04_PPH_RPORRES1 ==0
		replace aim1e_otpreg_comp=0 if M04_BIRTH_RPORRES1==1 & (M04_UNPL_CESARIAN_PROCCUR1==1 | M04_PREECLAMPSIA_RPORRES1==1 | M04_GEST_DIAB_RPORRES1 ==1 | ///
															   M04_PREMATURE_RUPTURE_RPORRES1==1 | M04_MACROSOMIA_RPORRES1==1 | M04_OLIGOHYDRAMNIOS_RPORRES1==1 | ///
															   M04_APH_RPORRES1==1 | M04_PPH_RPORRES1==1)
		replace aim1e_otpreg_comp=9 if M04_BIRTH_RPORRES1==1 & (M04_UNPL_CESARIAN_PROCCUR1==. | M04_PREECLAMPSIA_RPORRES1==. | M04_GEST_DIAB_RPORRES1 ==. | ///
															   M04_PREMATURE_RUPTURE_RPORRES1==. | M04_MACROSOMIA_RPORRES1==. | M04_OLIGOHYDRAMNIOS_RPORRES1==. | ///
															   M04_APH_RPORRES1==. | M04_PPH_RPORRES1==.)
		replace aim1e_otpreg_comp=9 if M04_BIRTH_RPORRES1==. & (M04_UNPL_CESARIAN_PROCCUR1==. | M04_PREECLAMPSIA_RPORRES1==. | M04_GEST_DIAB_RPORRES1 ==. | ///
															   M04_PREMATURE_RUPTURE_RPORRES1==. | M04_MACROSOMIA_RPORRES1==. | M04_OLIGOHYDRAMNIOS_RPORRES1==. | ///
															   M04_APH_RPORRES1==. | M04_PPH_RPORRES1==.)
		label var aim1e_otpreg_comp "Aim 1 Eligibility: no history of previous pregnancy complications "
		label values aim1e_otpreg_comp yesno1
	
		
	*11. No history of smoking
		gen aim1e_smoke=.
		replace aim1e_smoke=1 if M02_SMOKE_OECOCCUR==0
		replace aim1e_smoke=0 if M02_SMOKE_OECOCCUR==1
		replace aim1e_smoke=9 if M02_SMOKE_OECOCCUR==.
		label var aim1e_smoke "Aim 1 Eligibility: No history of smoking"
		label values aim1e_smoke yesno1
		
	* 12. No current malaria infection (per RDT)
	foreach x of varlist  M04_MALARIA_EVER_MHOCCUR1 M04_CARDIAC_EVER_MHOCCUR1 M04_HIV_MHOCCUR1 M07_HEPB_LBORRES1 M07_HEPC_LBORRES1 {
			replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
			destring `x', replace 
			}
	
	gen aim1e_malaria=.
		replace aim1e_malaria=1 if  M04_MALARIA_EVER_MHOCCUR1==0
		replace aim1e_malaria=0 if  M04_MALARIA_EVER_MHOCCUR1==1
		replace aim1e_malaria=9 if 	M04_MALARIA_EVER_MHOCCUR1==.
		replace aim1e_malaria=. if enrolled_prisma==0	
		label var aim1e_malaria "Aim 1 Eligibility: No malaria diagnosis at enrollment "
		label values aim1e_malaria yesno1

	*13. No history of cardiac disease 
		*will also include kidney and cancer in reharmonization, but not currently included in maternal history
	gen aim1e_cardiac=.
		replace aim1e_cardiac=1 if  M04_CARDIAC_EVER_MHOCCUR1==0
		replace aim1e_cardiac=0 if 	M04_CARDIAC_EVER_MHOCCUR1==1
		replace aim1e_cardiac=9 if 	(M04_CARDIAC_EVER_MHOCCUR1==. | M04_CARDIAC_EVER_MHOCCUR1==99)
		replace aim1e_cardiac=. if enrolled_prisma==0	
		label var aim1e_cardiac "Aim 1 Eligibility: No cardiac disease at enrollment "
		label values aim1e_cardiac yesno1
   
   *14. Not HIV positive
	gen aim1e_hiv=.
		replace aim1e_hiv=1 if M04_HIV_MHOCCUR1==0
		replace aim1e_hiv=0 if M04_HIV_MHOCCUR1==1
		replace aim1e_hiv=9 if M04_HIV_MHOCCUR1==.
		replace aim1e_hiv=. if enrolled_prisma==0	
		label var aim1e_hiv "Aim 1 Eligibility: Not HIV positive at enrollment"
		label values aim1e_hiv yesno1
		
   *15. No Hepatitis B positive
	gen aim1e_hepb=.
		replace aim1e_hepb=1 if M07_HEPB_LBORRES1==0
		replace aim1e_hepb=0 if M07_HEPB_LBORRES1==1
		replace aim1e_hepb=9 if M07_HEPB_LBORRES1==.
		replace aim1e_hepb=. if enrolled_prisma==0	
		label var aim1e_hepb "Aim 1 Eligibility: Not HepB positive at enrollment"
		label values aim1e_hepb yesno1
   
    
    *16 no Hepatitis C virus infection
	gen aim1e_hepc=.
		replace aim1e_hepc=1 if M07_HEPC_LBORRES1==0
		replace aim1e_hepc=0 if M07_HEPC_LBORRES1==1
		replace aim1e_hepc=9 if M07_HEPC_LBORRES1==.
		replace aim1e_hepc=. if enrolled_prisma==0	
		label var aim1e_hepc "Aim 1 Eligibility: Not HepC positive at enrollment"
		label values aim1e_hepc yesno1
	
***************************************************************
*Healthy Cohort Eligibility
	
	*code for true eligibility (most likely will be used only in new dataset)
	gen healthy_cohort=0
	replace healthy_cohort=1 if (aim1e_mage==1 & aim1e_gestage==1 & aim1e_bmi==1 & ///
								 aim1e_muac==1 & aim1e_height==1 & aim1e_singleton==1 & ///
								 aim1e_bp==1 & aim1e_miscarriage==1 & aim1e_lbw==1 & ///
								 aim1e_death==1 & aim1e_otpreg_comp==1 & aim1e_smoke==1 & ///
								 aim1e_malaria==1 & aim1e_cardiac==1 & aim1e_hiv==1 & ///
								 aim1e_hepb==1 & aim1e_hepc==1)
	replace healthy_cohort=. if enrolled_prisma==0
	label var healthy_cohort "ReMAPP Aim 1 Eligibile"
								 
	*eligibility that includes missing  							 
	gen healthy_cohort2=0
	replace healthy_cohort2=1 if (aim1e_mage!=0 & aim1e_gestage!=0 & aim1e_bmi!=0 & ///
								 aim1e_muac!=0 & aim1e_height!=0 & aim1e_singleton!=0 & ///
								 aim1e_bp!=0 & aim1e_miscarriage!=0 & aim1e_lbw!=0 & ///
								 aim1e_death!=0 & aim1e_otpreg_comp!=0 & aim1e_smoke!=0 & ///
								 aim1e_malaria!=0 & aim1e_cardiac!=0 & aim1e_hiv!=0 & ///
								 aim1e_hepb!=0 & aim1e_hepc!=0)
	replace healthy_cohort2=. if enrolled_prisma==0
	label var healthy_cohort2 "ReMAPP Aim 1 Eligibile - includes missing"
	
	/*eligibility that includes missig but does not include gestational age because many people in previous
	cohort were recruited after 14 weeks */
	gen healthy_cohort3=0
	replace healthy_cohort3=1 if (aim1e_mage!=0 & aim1e_bmi!=0 & ///
								 aim1e_muac!=0 & aim1e_height!=0 & aim1e_singleton!=0 & ///
								 aim1e_bp!=0 & aim1e_miscarriage!=0 & aim1e_lbw!=0 & ///
								 aim1e_death!=0 & aim1e_otpreg_comp!=0 & aim1e_smoke!=0 & ///
								 aim1e_malaria!=0 & aim1e_cardiac!=0 & aim1e_hiv!=0 & ///
								 aim1e_hepb!=0 & aim1e_hepc!=0)
	replace healthy_cohort3=. if enrolled_prisma==0
	label var healthy_cohort3 "ReMAPP Aim 1 Eligibile - includes missing and excludes gestational age"
	
************************************************************************************
*Generating Log File 
	capture log close
	log using "ReMAPP Eligibility 2022-03-02.txt", text  replace

	*PRiSMA Enrollment
		table eligible_prisma enrolled_prisma, by(screened_prisma)
	
	*ReMAPP Aim 1 Eligibility Criteria
	
	foreach x of varlist aim1e* {
	tab `x', miss
	}
	
	*Included in Healthy Cohort 
	
	foreach x of varlist healthy_cohort* {
	tab `x', miss
	}
	
	log close 
	

