 
 
SELECT sum(c.n * v.n * b.n)
FROM
  (SELECT Id
   FROM users
   WHERE DownVotes <= 57
     AND CreationDate BETWEEN '2010-08-26 09:01:31' :: timestamp AND '2014-08-10 11:01:39' :: timestamp) AS u
JOIN
  (SELECT UserId,
          count(*) AS n
   FROM comments
   WHERE Score = 0
   GROUP BY UserId) AS c ON u.Id = c.UserId
JOIN
  (SELECT UserId,
          count(*) AS n
   FROM votes
   WHERE BountyAmount >= 0
     AND CreationDate <= '2014-09-11 00:00:00' :: timestamp
   GROUP BY UserId) AS v ON u.Id = v.UserId
JOIN
  (SELECT UserId,
          count(*) AS n
   FROM badges
   GROUP BY UserId) AS b ON u.Id = b.UserId;