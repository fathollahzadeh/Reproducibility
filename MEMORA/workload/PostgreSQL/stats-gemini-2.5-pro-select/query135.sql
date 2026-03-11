 
 
SELECT COUNT(*)
FROM comments AS c
JOIN posts AS p ON c.UserId = p.OwnerUserId
JOIN badges AS b ON c.UserId = b.UserId
JOIN postHistory AS ph ON c.UserId = ph.UserId
JOIN users AS u ON c.UserId = u.Id
WHERE c.Score = 0
  AND p.PostTypeId = 1
  AND p.ViewCount >= 0
  AND p.ViewCount <= 4157
  AND p.FavoriteCount = 0
  AND p.CreationDate <= '2014-09-08 09:58:16' :: timestamp;