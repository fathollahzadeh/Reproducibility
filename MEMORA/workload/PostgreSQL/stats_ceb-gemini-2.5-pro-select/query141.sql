 
 WITH filtered_posts AS
  (SELECT p.Id
   FROM posts AS p
   JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
   WHERE p.Score <= 40
     AND p.CommentCount >= 0
     AND p.CreationDate BETWEEN '2010-07-28 17:40:56'::timestamp AND '2014-09-11 04:22:44'::timestamp
     AND pl.LinkTypeId = 1),
     user_badge_counts AS
  (SELECT UserId,
          COUNT(*) AS badge_count
   FROM badges
   GROUP BY UserId),
     comment_badge_sum AS
  (SELECT c.PostId,
          SUM(ubc.badge_count) AS cb_sum
   FROM comments AS c
   JOIN user_badge_counts AS ubc ON c.UserId = ubc.UserId
   GROUP BY c.PostId),
     vote_counts AS
  (SELECT PostId,
          COUNT(*) AS v_count
   FROM votes
   GROUP BY PostId),
     history_counts AS
  (SELECT PostId,
          COUNT(*) AS ph_count
   FROM postHistory
   GROUP BY PostId)
SELECT SUM(cbs.cb_sum * v.v_count * ph.ph_count)
FROM filtered_posts AS fp
JOIN comment_badge_sum AS cbs ON fp.Id = cbs.PostId
JOIN vote_counts AS v ON fp.Id = v.PostId
JOIN history_counts AS ph ON fp.Id = ph.PostId;