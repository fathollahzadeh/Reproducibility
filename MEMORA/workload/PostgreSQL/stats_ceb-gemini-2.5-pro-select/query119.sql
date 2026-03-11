 
 WITH user_posts_count AS
  (SELECT OwnerUserId AS UserId,
          COUNT(*) AS p_count
   FROM posts
   WHERE ViewCount BETWEEN 0 AND 2024
   GROUP BY OwnerUserId),
     user_badges_count AS
  (SELECT UserId,
          COUNT(*) AS b_count
   FROM badges
   WHERE Date >= '2010-07-20 10:34:10' :: timestamp
   GROUP BY UserId),
     user_ph_count AS
  (SELECT UserId,
          COUNT(*) AS ph_count
   FROM postHistory
   WHERE PostHistoryTypeId = 5
   GROUP BY UserId)
SELECT SUM(p.p_count * b.b_count * ph.ph_count)
FROM users AS u
JOIN user_posts_count AS p ON p.UserId = u.Id
JOIN user_badges_count AS b ON b.UserId = u.Id
JOIN user_ph_count AS ph ON ph.UserId = u.Id
WHERE u.Reputation BETWEEN 1 AND 750;