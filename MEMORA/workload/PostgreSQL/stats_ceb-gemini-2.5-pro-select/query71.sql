 
 WITH ph_counts AS
  (SELECT PostId,
          COUNT(*) AS ct
   FROM postHistory
   WHERE PostHistoryTypeId = 2
   GROUP BY PostId),
     v_counts AS
  (SELECT PostId,
          COUNT(*) AS ct
   FROM votes
   WHERE VoteTypeId = 5
   GROUP BY PostId),
     pl_counts AS
  (SELECT RelatedPostId AS PostId,
          COUNT(*) AS ct
   FROM postLinks
   GROUP BY RelatedPostId),
     cb_counts AS
  (SELECT c.PostId,
          COUNT(*) AS ct
   FROM comments c
   JOIN badges b ON c.UserId = b.UserId
   GROUP BY c.PostId)
SELECT SUM(pl.ct * ph.ct * v.ct * cb.ct)
FROM posts AS p
JOIN pl_counts AS pl ON p.Id = pl.PostId
JOIN ph_counts AS ph ON p.Id = ph.PostId
JOIN v_counts AS v ON p.Id = v.PostId
JOIN cb_counts AS cb ON p.Id = cb.PostId
WHERE p.CommentCount >= 0;