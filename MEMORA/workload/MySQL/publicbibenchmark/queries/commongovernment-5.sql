SELECT commongovernment13.level1category AS level1category,   SUM(commongovernment13.obligatedamount) AS sumobligatedamountok FROM commongovernment13 GROUP BY commongovernment13.level1category;
