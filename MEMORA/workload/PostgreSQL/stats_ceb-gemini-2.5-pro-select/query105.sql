 
 WITH posthistory_counts AS
  (SELECT ph.UserId,
          COUNT(*) AS n
   FROM postHistory AS ph
   GROUP BY ph.UserId),
     vote_counts AS
  (SELECT v.UserId,
          COUNT(*) AS n
   FROM votes AS v
   GROUP BY v.UserId)
SELECT SUM(phc.n * vc.n)
FROM users AS u
JOIN comments AS c ON u.Id = c.UserId
JOIN posthistory_counts AS phc ON u.Id = phc.UserId
JOIN vote_counts AS vc ON u.Id = vc.UserId
WHERE u.Views <= 433
  AND u.DownVotes >= 0
  AND u.CreationDate <= '2014-09-12 21:37:39' :: timestamp
  AND c.Score = 0
  AND c.CreationDate >= '2010-07-19 19:56:21' :: timestamp
  AND c.CreationDate <= '2014-09-11 13:36:12' :: timestamp;