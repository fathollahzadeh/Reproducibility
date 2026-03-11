 
 WITH user_comment_counts AS
  (SELECT UserId,
          COUNT(*) AS n_comments
   FROM comments
   WHERE Score = 1
     AND CreationDate >= '2010-07-20 23:17:28'::timestamp
   GROUP BY UserId),
     user_vote_counts AS
  (SELECT UserId,
          COUNT(*) AS n_votes
   FROM votes
   GROUP BY UserId),
     user_badge_counts AS
  (SELECT UserId,
          COUNT(*) AS n_badges
   FROM badges
   GROUP BY UserId)
SELECT SUM(c.n_comments * v.n_votes * b.n_badges)
FROM users AS u
JOIN user_comment_counts AS c ON u.Id = c.UserId
JOIN user_vote_counts AS v ON u.Id = v.UserId
JOIN user_badge_counts AS b ON u.Id = b.UserId
WHERE u.CreationDate >= '2010-07-20 01:27:29'::timestamp;