 
 WITH c_counts AS
  (SELECT UserId,
          COUNT(*) AS c_count
   FROM comments
   GROUP BY UserId)
SELECT SUM(c_counts.c_count)
FROM postHistory AS ph
JOIN c_counts ON ph.UserId = c_counts.UserId
WHERE ph.PostHistoryTypeId = 1
  AND ph.CreationDate >= '2010-09-14 11:59:07' :: timestamp;