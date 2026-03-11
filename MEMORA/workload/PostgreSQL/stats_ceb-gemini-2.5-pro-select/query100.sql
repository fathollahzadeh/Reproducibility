 
 
SELECT COUNT(*)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN votes AS v ON p.Id = v.PostId
JOIN comments AS c ON p.Id = c.PostId
WHERE u.Reputation >= 1
  AND u.CreationDate BETWEEN '2010-07-19 19:08:49' :: timestamp AND '2014-08-28 12:15:56' :: timestamp
  AND p.Score BETWEEN 0 AND 16
  AND p.ViewCount >= 0
  AND p.CreationDate <= '2014-09-09 12:00:50' :: timestamp;