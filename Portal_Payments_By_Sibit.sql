-- Payline Portal Payment due to SIBIT
-- Only NOT NULL on SIBIT_DATE are SIBIT payments

---------------------------------------
----Temp table
-----------------------------------------
IF OBJECT_ID('tempdb.dbo.#SIBT') IS NOT NULL
DROP TABLE #SIBT

select carls.cnsmr_id,carls.upsrt_dttm

into #SIBT
from crs5_oltp_replicated.dbo.cnsmr_accnt_ar_log carls (NOLOCK)
where carls.actn_cd = 499 /*SIBT*/ and carls.rslt_cd != 938 /*SMS Failed*/
-----------------------------------------------------
--MAin Query
-------------------------------------------------------

SELECT DISTINCT
c.cnsmr_idntfr_agncy_id AS 'Cnsmr#',
ca.cnsmr_accnt_idntfr_agncy_id AS 'Accnt#',
CONVERT(DATE,carl.upsrt_dttm,101) AS 'Payment_Portal_Date',


    CASE 
        WHEN CHARINDEX('payment(s)', carl.cnsmr_accnt_ar_mssg_txt) > 0 THEN SUBSTRING(carl.cnsmr_accnt_ar_mssg_txt, CHARINDEX('payment(s)', carl.cnsmr_accnt_ar_mssg_txt) - 2, 1)
        ELSE NULL
    END AS num_payments,
    CASE 
        WHEN CHARINDEX('$', carl.cnsmr_accnt_ar_mssg_txt) > 0 THEN CAST(SUBSTRING(carl.cnsmr_accnt_ar_mssg_txt, CHARINDEX('$', carl.cnsmr_accnt_ar_mssg_txt) + 1, CHARINDEX(' for', carl.cnsmr_accnt_ar_mssg_txt) - CHARINDEX('$', carl.cnsmr_accnt_ar_mssg_txt) - 1) AS DECIMAL(10, 2))
        ELSE NULL
    END AS payment_amount,
    CASE 
        WHEN CHARINDEX('$', carl.cnsmr_accnt_ar_mssg_txt) > 0 THEN CAST(SUBSTRING(carl.cnsmr_accnt_ar_mssg_txt, CHARINDEX('total of $', carl.cnsmr_accnt_ar_mssg_txt) + 10, LEN(carl.cnsmr_accnt_ar_mssg_txt) - CHARINDEX('total of $', carl.cnsmr_accnt_ar_mssg_txt) - 9) AS DECIMAL(10, 2))
        ELSE NULL
    END AS total_amount
	--,CONVERT(date,Sibit.upsrt_dttm,101) AS 'SMSSENT_date',
	,DATEDIFF(d,SIBT.upsrt_dttm,carl.upsrt_dttm) AS 'Age_Sibit'
	,CONVERT(DATE,SIBT.upsrt_dttm,101) AS 'SIBIT_Date'

FROM crs5_oltp_replicated.dbo.cnsmr_accnt_ar_log carl (NOLOCK)
JOIN crs5_oltp_replicated.dbo.cnsmr_accnt ca (NOLOCK) ON ca.cnsmr_id = carl.cnsmr_id
JOIN crs5_oltp_replicated.dbo.cnsmr c (NOLOCK) ON c.cnsmr_id = ca.cnsmr_id



outer apply( select top 1 s.cnsmr_id,s.upsrt_dttm
			from #SIBT s 
			where s.cnsmr_id = c.cnsmr_id 
			order by s.upsrt_dttm 
			)SIBT

WHERE carl.actn_cd = 394 --Payline Payment Portal
AND carl.rslt_Cd = 605 -- Payment Arrangement
AND CONVERT(DATE,carl.upsrt_dttm,101) >='2024-01-01' -- Time Frame of payments


