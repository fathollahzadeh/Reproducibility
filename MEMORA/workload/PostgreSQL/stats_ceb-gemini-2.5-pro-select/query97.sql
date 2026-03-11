 
 
SELECT COUNT(*)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN comments AS c ON u.Id = c.UserId
JOIN votes AS v ON u.Id = v.UserId
WHERE u.Views >= 0
  AND u.CreationDate >= '2010-07-27 09:38:05' :: timestamp
  AND p.Score >= 0
  AND p.Score <= 28
  AND p.ViewCount >= 0
  AND p.ViewCount <= 6517
  AND p.AnswerCount >= 0
  AND p.AnswerCount <= 5
  AND p.FavoriteCount >= 0
  AND p.FavoriteCount <= 8
  AND p.CreationDate >= '2010-07-27 11:29:20' :: timestamp
  AND p.CreationDate <= '2014-09-13 02:50:15' :: timestamp
  AND c.CreationDate >= '2010-07-27 11:29:20' :: timestamp;