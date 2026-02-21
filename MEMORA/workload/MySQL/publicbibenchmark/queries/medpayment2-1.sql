SELECT
    medpayment21.hcpcscode AS hcpcscode,
    medpayment21.hcpcsdescription AS hcpcsdescription,
    medpayment21.nppesproviderstate AS nppesproviderstate,
    SUM(medpayment21.calculation0820513143749095) AS sumcalculation0820513143749095ok,
    SUM(medpayment21.averagesubmittedchrgamt) AS sumaveragesubmittedchrgamtok
FROM
    medpayment21
WHERE
    (
        (medpayment21.hcpcscode = '27447')
        AND (
            medpayment21.hcpcsdescription = 'Total knee arthroplasty'
        )
    )
GROUP BY
    medpayment21.hcpcscode,
    medpayment21.hcpcsdescription,
    medpayment21.nppesproviderstate;