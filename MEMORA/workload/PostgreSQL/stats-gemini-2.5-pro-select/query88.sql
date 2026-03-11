 
 WITH filtered_users AS
  (SELECT id
   FROM users
   WHERE UpVotes >= 0),
     comment_counts AS
  (SELECT UserId,
          count(*) AS n_comments
   FROM comments
   WHERE Score = 0
     AND CreationDate >= '2010-07-24 06:46:49'::timestamp
   GROUP BY UserId),
     badge_counts AS
  (SELECT UserId,
          count(*) AS n_badges
   FROM badges
   WHERE Date BETWEEN '2010-07-19 20:34:06' :: timestamp AND '2014-09-12 15:11:36' :: timestamp
   GROUP BY UserId)
SELECT sum(cc.n_comments * bc.n_badges)
FROM filtered_users AS u
JOIN comment_counts AS cc ON u.id = cc.UserId
JOIN badge_counts AS bc ON u.id = bc.UserId;