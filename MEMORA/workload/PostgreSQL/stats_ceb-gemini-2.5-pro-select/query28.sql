 
 
SELECT SUM(ubc.badge_count)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN votes AS v ON p.Id = v.PostId
JOIN
  (SELECT UserId,
          COUNT(*) AS badge_count
   FROM badges
   GROUP BY UserId) AS ubc ON u.Id = ubc.UserId
WHERE u.Reputation >= 1
  AND p.Score <= 22;