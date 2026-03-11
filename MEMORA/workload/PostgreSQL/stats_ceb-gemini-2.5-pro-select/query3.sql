 
 WITH c_counts AS
  (SELECT UserId,
          COUNT(*) AS n
   FROM comments
   WHERE Score = 0
   GROUP BY UserId)
SELECT SUM(c.n)
FROM c_counts AS c
JOIN postHistory AS ph ON c.UserId = ph.UserId
WHERE ph.PostHistoryTypeId = 1;