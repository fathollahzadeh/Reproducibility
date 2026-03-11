 
 
SELECT SUM(T.c_count)
FROM
  (SELECT c.UserId,
          COUNT(*) AS c_count
   FROM comments AS c
   WHERE c.Score = 0
     AND c.CreationDate >= '2010-07-24 06:46:49'::timestamp
   GROUP BY c.UserId) AS T
JOIN users AS u ON T.UserId = u.Id
JOIN badges AS b ON T.UserId = b.UserId
WHERE u.UpVotes >= 0
  AND b.Date BETWEEN '2010-07-19 20:34:06'::timestamp AND '2014-09-12 15:11:36'::timestamp;