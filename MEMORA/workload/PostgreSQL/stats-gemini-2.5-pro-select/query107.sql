 
 WITH user_badges AS
  (SELECT UserId,
          COUNT(*) AS badge_count
   FROM badges
   WHERE Date <= '2014-08-19 10:32:13'::timestamp
   GROUP BY UserId),
     user_comments AS
  (SELECT UserId,
          COUNT(*) AS comment_count
   FROM comments
   WHERE Score = 1
     AND CreationDate >= '2010-08-27 14:12:07'::timestamp
   GROUP BY UserId),
     user_votes AS
  (SELECT UserId,
          COUNT(*) AS vote_count
   FROM votes
   WHERE VoteTypeId = 5
     AND CreationDate >= '2010-07-19 00:00:00'::timestamp
     AND CreationDate <= '2014-09-13 00:00:00'::timestamp
   GROUP BY UserId)
SELECT SUM(ub.badge_count * uc.comment_count * uv.vote_count)
FROM users u
JOIN user_badges ub ON u.Id = ub.UserId
JOIN user_comments uc ON u.Id = uc.UserId
JOIN user_votes uv ON u.Id = uv.UserId
WHERE u.Reputation >= 1;
