SELECT physicians1.hcpcsdescription AS hcpcsdescription,   SUM(physicians1.averagemedicarepaymentamt) AS sumaveragemedicarepaymentamtok FROM physicians1 GROUP BY physicians1.hcpcsdescription;
