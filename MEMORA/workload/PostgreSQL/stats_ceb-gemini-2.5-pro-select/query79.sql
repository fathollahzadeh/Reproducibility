 
 WITH post_products AS
  (SELECT p.OwnerUserId,
          sum(c.num_c * v.num_v * ph.num_ph) AS total_post_product
   FROM
     (SELECT Id,
             OwnerUserId
      FROM posts
      WHERE Score <= 21
        AND AnswerCount <= 3
        AND FavoriteCount >= 0) AS p
   JOIN
     (SELECT PostId,
             count(*) AS num_c
      FROM comments
      WHERE Score = 0
      GROUP BY PostId) AS c ON p.Id = c.PostId
   JOIN
     (SELECT PostId,
             count(*) AS num_v
      FROM votes
      WHERE CreationDate >= '2010-07-19 00:00:00' :: timestamp
      GROUP BY PostId) AS v ON p.Id = v.PostId
   JOIN
     (SELECT PostId,
             count(*) AS num_ph
      FROM postHistory
      GROUP BY PostId) AS ph ON p.Id = ph.PostId
   GROUP BY p.OwnerUserId),
     user_badge_counts AS
  (SELECT u.Id AS UserId,
          b.num_b
   FROM
     (SELECT Id
      FROM users
      WHERE Reputation <= 240) AS u
   JOIN
     (SELECT UserId,
             count(*) AS num_b
      FROM badges
      WHERE Date <= '2014-09-11 18:35:08' :: timestamp
      GROUP BY UserId) AS b ON u.Id = b.UserId)
SELECT sum(ubc.num_b * pp.total_post_product)
FROM user_badge_counts AS ubc
JOIN post_products AS pp ON ubc.UserId = pp.OwnerUserId;