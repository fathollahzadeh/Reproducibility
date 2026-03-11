 
 
SELECT SUM(b.n * p.n)
FROM
  (SELECT Id
   FROM users
   WHERE DownVotes <= 2
     AND UpVotes >= 0
     AND CreationDate >= '2010-11-26 03:34:11' :: timestamp) AS u
JOIN
  (SELECT UserId,
          COUNT(*) AS n
   FROM badges
   WHERE Date BETWEEN '2010-07-20 19:02:22' :: timestamp AND '2014-09-03 23:36:09' :: timestamp
   GROUP BY UserId) AS b ON u.Id = b.UserId
JOIN
  (SELECT p.OwnerUserId,
          COUNT(*) AS n
   FROM posts AS p
   JOIN votes AS v ON p.Id = v.PostId
   WHERE p.PostTypeId = 1
     AND p.Score >= -1
     AND p.FavoriteCount BETWEEN 0 AND 20
     AND v.CreationDate <= '2014-09-12 00:00:00' :: timestamp
   GROUP BY p.OwnerUserId) AS p ON u.Id = p.OwnerUserId;