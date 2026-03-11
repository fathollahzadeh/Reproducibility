 
 
SELECT SUM(p_counts.p_count * b_counts.b_count * ph_counts.ph_count)
FROM
  (SELECT Id
   FROM users
   WHERE CreationDate <= '2014-09-12 22:21:49'::timestamp) AS u
JOIN
  (SELECT OwnerUserId,
          COUNT(*) AS p_count
   FROM posts
   WHERE AnswerCount >= 0
     AND FavoriteCount >= 0
     AND CreationDate <= '2014-09-03 03:32:35'::timestamp
   GROUP BY OwnerUserId) AS p_counts ON u.Id = p_counts.OwnerUserId
JOIN
  (SELECT UserId,
          COUNT(*) AS b_count
   FROM badges
   GROUP BY UserId) AS b_counts ON u.Id = b_counts.UserId
JOIN
  (SELECT UserId,
          COUNT(*) AS ph_count
   FROM postHistory
   GROUP BY UserId) AS ph_counts ON u.Id = ph_counts.UserId;