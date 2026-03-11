 
 
SELECT sum(b.n * p.n * v.n)
FROM users u
JOIN
  (SELECT UserId,
          count(*) AS n
   FROM badges
   WHERE Date BETWEEN '2011-01-03 20:50:19':: timestamp AND '2014-09-02 15:35:07' :: timestamp
   GROUP BY UserId) b ON u.Id = b.UserId
JOIN
  (SELECT OwnerUserId,
          count(*) AS n
   FROM posts
   WHERE Score <= 48
     AND AnswerCount <= 8
   GROUP BY OwnerUserId) p ON u.Id = p.OwnerUserId
JOIN
  (SELECT UserId,
          count(*) AS n
   FROM votes
   WHERE CreationDate <= '2014-09-06 00:00:00'::timestamp
   GROUP BY UserId) v ON u.Id = v.UserId
WHERE u.CreationDate >= '2010-11-16 06:03:04'::timestamp;