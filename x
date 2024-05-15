SELECT 
    BUS_CYC_DT AS Business_Cycle_Date, 
    Agency, 
    Calendar_Year_Written_Premium_$ 
FROM (
    SELECT 
        ERA_ALL_FINAL.BUS_CYC_DT AS Business_Cycle_Date,
        CASE 
            WHEN ERA_ALL_FINAL.NATL_BRKR_NM = 'Non-Brokers' 
                THEN ERA_ALL_FINAL.MSTR_PRDCR_NM 
                ELSE ERA_ALL_FINAL.NATL_BRKR_NM 
        END AS Agency,
        SUM(
            CASE 
                WHEN ERA_ALL_FINAL.PVA_CD = 'P' 
                    THEN 0
                WHEN ERA_ReportingUnit_Seg.RPT_GRP_CD = 'N00' 
                    THEN ERA_ALL_FINAL.POLYR_RVNU_AMT
                ELSE ERA_ALL_FINAL.CALYR_WRTN_PREM_AMT
            END
        ) AS Calendar_Year_Written_Premium_$
    FROM (
        SELECT 
            ERA_ALL_FINAL.BUS_CYC_DT,
            ERA_ALL_FINAL.NATL_BRKR_NM,
            CASE 
                WHEN ERA_ALL_FINAL.PVA_CD = 'P' 
                    THEN 0
                ELSE ERA_ALL_FINAL.POLYR_RVNU_AMT
            END AS POLYR_RVNU_AMT,
            ERA_ALL_FINAL.CALYR_WRTN_PREM_AMT,
            ERA_ALL_FINAL.PVA_CD,
            ERA_ALL_FINAL.RPT_UNT_CD,
            ERA_ALL_FINAL.MSTR_PRDCR_NM,
            ERA_ALL_FINAL.RPTNG_YR
        FROM 
            RPDMV_ERA_ALL_FINAL ERA_ALL_FINAL
        LEFT OUTER JOIN (
            SELECT 
                A.RPT_UNT_CD,
                A.RPT_GRP_CD,
                B.BUS_CYC_DT
            FROM 
                RPDMV_ERA_RPT_UNT_SEG_D A
            LEFT JOIN (
                SELECT 
                    RPT_UNT_CD, 
                    MAX(RPTNG_YR) AS RPTNG_YR
                FROM 
                    RPDMV_ERA_RPT_UNT_SEG_D
                WHERE 
                    RPT_UNT_CD <> 'UN'
                GROUP BY 
                    RPT_UNT_CD
            ) B
            ON 
                A.RPT_UNT_CD = B.RPT_UNT_CD
        ) ERA_ReportingUnit_Seg
        ON 
            ERA_ALL_FINAL.RPT_UNT_CD = ERA_ReportingUnit_Seg.RPT_UNT_CD
            AND EXTRACT(YEAR FROM ERA_ALL_FINAL.BUS_CYC_DT) = EXTRACT(YEAR FROM ERA_ReportingUnit_Seg.BUS_CYC_DT)
            AND EXTRACT(MONTH FROM ERA_ALL_FINAL.BUS_CYC_DT) = 12
    ) ERA_ALL_FINAL
    GROUP BY 
        ERA_ALL_FINAL.BUS_CYC_DT,
        CASE 
            WHEN ERA_ALL_FINAL.NATL_BRKR_NM = 'Non-Brokers' 
                THEN ERA_ALL_FINAL.MSTR_PRDCR_NM 
                ELSE ERA_ALL_FINAL.NATL_BRKR_NM 
        END
    HAVING 
        SUM(
            CASE 
                WHEN ERA_ALL_FINAL.PVA_CD = 'P' 
                    THEN 0
                ELSE ERA_ALL_FINAL.POLYR_RVNU_AMT
            END
        ) < 50
) AS FilteredData
WHERE 
    Agency NOT IN (
        'Geico Ins Agency Inc', 
        'Affinity-House', 
        'Aeg South Ins Agcy Llc', 
        'Nbs Insurance Agency Inc', 
        'Bbt Holdings', 
        'TRUST-BBT', 
        'Trust'
    );
