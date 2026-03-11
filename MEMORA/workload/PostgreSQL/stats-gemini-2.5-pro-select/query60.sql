 
 WITH badge_counts AS
  (SELECT UserId,
          COUNT(*) AS n
   FROM badges
   GROUP BY UserId),
     comment_counts AS
  (SELECT PostId,
          COUNT(*) AS n
   FROM comments
   GROUP BY PostId),
     link_counts AS
  (SELECT RelatedPostId,
          COUNT(*) AS n
   FROM postLinks
   GROUP BY RelatedPostId),
     vote_counts AS
  (SELECT PostId,
          COUNT(*) AS n
   FROM votes
   GROUP BY PostId)
SELECT SUM(bc.n * cc.n * lc.n * vc.n)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN badge_counts AS bc ON u.Id = bc.UserId
JOIN comment_counts AS cc ON p.Id = cc.PostId
JOIN link_counts AS lc ON p.Id = lc.RelatedPostId
JOIN vote_counts AS vc ON p.Id = vc.PostId
WHERE u.Views <= 190
  AND u.CreationDate BETWEEN '2010-07-20 08:05:39'::timestamp AND '2014-08-27 09:31:28'::timestamp;