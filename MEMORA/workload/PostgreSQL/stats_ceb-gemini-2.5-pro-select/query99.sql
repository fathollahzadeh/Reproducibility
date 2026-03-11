 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE Reputation <= 306
     AND UpVotes >= 0)
SELECT COUNT(*)
FROM filtered_users u
JOIN posts p ON u.Id = p.OwnerUserId
AND p.ViewCount >= 0
JOIN comments c ON u.Id = c.UserId
AND c.Score = 0
JOIN votes v ON u.Id = v.UserId;