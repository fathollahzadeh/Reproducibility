 
 
SELECT SUM(c.n * v.n * pl.n * ph.n)
FROM posts p
JOIN
  (SELECT PostId,
          count(*) AS n
   FROM comments
   WHERE CreationDate <= '2014-09-10 02:42:35' :: timestamp
   GROUP BY PostId) c ON p.Id = c.PostId
JOIN
  (SELECT PostId,
          count(*) AS n
   FROM votes
   WHERE VoteTypeId = 2
   GROUP BY PostId) v ON p.Id = v.PostId
JOIN
  (SELECT PostId,
          count(*) AS n
   FROM postLinks
   GROUP BY PostId) pl ON p.Id = pl.PostId
JOIN
  (SELECT PostId,
          count(*) AS n
   FROM postHistory
   GROUP BY PostId) ph ON p.Id = ph.PostId
WHERE p.Score >= -1
  AND p.ViewCount <= 5896
  AND p.AnswerCount >= 0
  AND p.CreationDate >= '2010-07-29 15:57:21' :: timestamp;