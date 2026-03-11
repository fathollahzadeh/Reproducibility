 
 WITH filtered_votes AS
  (SELECT PostId,
          count(*) AS cnt
   FROM votes
   WHERE CreationDate >= '2010-07-19 00:00:00' :: timestamp
     AND CreationDate <= '2014-09-10 00:00:00' :: timestamp
   GROUP BY PostId),
     link_counts AS
  (SELECT RelatedPostId,
          count(*) AS cnt
   FROM postLinks
   GROUP BY RelatedPostId),
     history_counts AS
  (SELECT PostId,
          count(*) AS cnt
   FROM postHistory
   GROUP BY PostId),
     badges_per_user AS
  (SELECT UserId,
          count(*) AS cnt
   FROM badges
   GROUP BY UserId),
     comment_badge_counts AS
  (SELECT c.PostId,
          sum(bpu.cnt) AS cnt
   FROM comments c
   JOIN badges_per_user bpu ON c.UserId = bpu.UserId
   GROUP BY c.PostId)
SELECT sum(v.cnt * l.cnt * h.cnt * cb.cnt)
FROM filtered_votes v
JOIN link_counts l ON v.PostId = l.RelatedPostId
JOIN history_counts h ON v.PostId = h.PostId
JOIN comment_badge_counts cb ON v.PostId = cb.PostId;