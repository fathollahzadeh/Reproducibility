 
 WITH user_comment_counts AS
  (SELECT u.Id AS UserId,
          count(c.Id) AS n_comments
   FROM users u
   JOIN comments c ON u.Id = c.UserId
   WHERE u.CreationDate >= '2010-07-20 01:27:29' :: timestamp
     AND c.Score = 1
     AND c.CreationDate >= '2010-07-20 23:17:28' :: timestamp
   GROUP BY u.Id),
     vote_counts AS
  (SELECT UserId,
          count(*) AS n_votes
   FROM votes
   GROUP BY UserId),
     badge_counts AS
  (SELECT UserId,
          count(*) AS n_badges
   FROM badges
   GROUP BY UserId)
SELECT sum(ucc.n_comments * vc.n_votes * bc.n_badges)
FROM user_comment_counts ucc
JOIN vote_counts vc ON ucc.UserId = vc.UserId
JOIN badge_counts bc ON ucc.UserId = bc.UserId;