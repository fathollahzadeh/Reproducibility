 
 WITH filtered_posts AS
  (SELECT p.Id,
          p.OwnerUserId
   FROM posts AS p
   WHERE p.ViewCount >= 0
     AND p.AnswerCount BETWEEN 0 AND 7
     AND p.FavoriteCount BETWEEN 0 AND 17),
     user_badge_counts AS
  (SELECT b.UserId,
          COUNT(*) AS cnt
   FROM users AS u
   JOIN badges AS b ON u.Id = b.UserId
   WHERE u.Reputation >= 1
     AND u.Views >= 0
     AND u.CreationDate BETWEEN '2010-08-19 06:26:34'::timestamp AND '2014-09-11 05:22:26'::timestamp
     AND b.Date >= '2010-08-01 02:54:53'::timestamp
   GROUP BY b.UserId),
     post_comment_counts AS
  (SELECT c.PostId,
          COUNT(*) AS cnt
   FROM comments AS c
   GROUP BY c.PostId),
     post_history_counts AS
  (SELECT ph.PostId,
          COUNT(*) AS cnt
   FROM postHistory AS ph
   GROUP BY ph.PostId),
     post_vote_counts AS
  (SELECT v.PostId,
          COUNT(*) AS cnt
   FROM votes AS v
   WHERE v.VoteTypeId = 5
   GROUP BY v.PostId)
SELECT SUM(ubc.cnt * pcc.cnt * phc.cnt * pvc.cnt)
FROM filtered_posts AS p
JOIN user_badge_counts AS ubc ON p.OwnerUserId = ubc.UserId
JOIN post_comment_counts AS pcc ON p.Id = pcc.PostId
JOIN post_history_counts AS phc ON p.Id = phc.PostId
JOIN post_vote_counts AS pvc ON p.Id = pvc.PostId;