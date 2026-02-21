SELECT COUNT(DISTINCT commongovernment13.refidvidpiid) AS ctdrefidvidpiidok,   SUM(commongovernment13.obligatedamount) AS sumobligatedamountok FROM commongovernment13 HAVING (COUNT(1) > 0);
