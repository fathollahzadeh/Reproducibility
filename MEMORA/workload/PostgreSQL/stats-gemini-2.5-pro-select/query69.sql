 
 WITH user_badge_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM badges
   GROUP BY UserId),
     comment_counts AS
  (SELECT c.PostId,
          sum(ubc.n) AS n
   FROM comments AS c
   JOIN user_badge_counts AS ubc ON c.UserId = ubc.UserId
   WHERE c.Score = 0
   GROUP BY c.PostId),
     pl_counts AS
  (SELECT RelatedPostId,
          count(*) AS n
   FROM postLinks
   WHERE LinkTypeId = 1
   GROUP BY RelatedPostId),
     ph_counts AS
  (SELECT PostId,
          count(*) AS n
   FROM postHistory
   GROUP BY PostId),
     v_counts AS
  (SELECT PostId,
          count(*) AS n
   FROM votes
   WHERE CreationDate <= '2014-09-10 00:00:00' :: timestamp
   GROUP BY PostId)
SELECT SUM(pl.n * ph.n * v.n * cc.n)
FROM posts AS p
JOIN comment_counts AS cc ON p.Id = cc.PostId
JOIN pl_counts AS pl ON p.Id = pl.RelatedPostId
JOIN ph_counts AS ph ON p.Id = ph.PostId
JOIN v_counts AS v ON p.Id = v.PostId
WHERE p.Score <= 32
  AND p.ViewCount <= 4146;