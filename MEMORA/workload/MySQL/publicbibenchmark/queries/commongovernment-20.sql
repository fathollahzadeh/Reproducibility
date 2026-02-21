SELECT commongovernment9.level1category AS level1category,   SUM(commongovernment9.obligatedamount) AS sumobligatedamountok FROM commongovernment9 GROUP BY commongovernment9.level1category;
