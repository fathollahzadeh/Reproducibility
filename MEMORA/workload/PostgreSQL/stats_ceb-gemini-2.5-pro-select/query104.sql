 
 WITH comment_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM comments
   GROUP BY UserId),
     vote_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM votes
   GROUP BY UserId),
     posthistory_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM posthistory
   WHERE CreationDate >= '2010-07-28 09:11:34' :: timestamp
     AND CreationDate <= '2014-09-06 06:51:53' :: timestamp
   GROUP BY UserId)
SELECT SUM(cc.n * vc.n * phc.n)
FROM users u
JOIN comment_counts cc ON u.Id = cc.UserId
JOIN vote_counts vc ON u.Id = vc.UserId
JOIN posthistory_counts phc ON u.Id = phc.UserId
WHERE u.DownVotes <= 0
  AND u.UpVotes >= 0
  AND u.UpVotes <= 72;