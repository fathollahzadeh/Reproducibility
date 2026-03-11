 
 
SELECT COALESCE(SUM(c.c_count * ph.ph_count * b.b_count), 0)
FROM
  (SELECT UserId,
          count(*) AS c_count
   FROM comments
   WHERE Score = 0
     AND CreationDate >= '2010-09-05 16:04:35'::timestamp
     AND CreationDate <= '2014-09-11 04:35:36'::timestamp
   GROUP BY UserId) AS c
JOIN
  (SELECT UserId,
          count(*) AS ph_count
   FROM postHistory
   WHERE PostHistoryTypeId = 1
     AND CreationDate >= '2010-07-26 20:01:58'::timestamp
     AND CreationDate <= '2014-09-13 17:29:23'::timestamp
   GROUP BY UserId) AS ph ON c.UserId = ph.UserId
JOIN
  (SELECT UserId,
          count(*) AS b_count
   FROM badges
   WHERE Date <= '2014-09-04 08:54:56'::timestamp
   GROUP BY UserId) AS b ON c.UserId = b.UserId;