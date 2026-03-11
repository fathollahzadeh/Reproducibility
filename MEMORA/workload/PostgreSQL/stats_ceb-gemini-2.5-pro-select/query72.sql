 
 
SELECT COUNT(*)
FROM posts AS p
INNER JOIN comments AS c ON p.Id = c.PostId
INNER JOIN badges AS b ON c.UserId = b.UserId
INNER JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
INNER JOIN postHistory AS ph ON p.Id = ph.PostId
INNER JOIN votes AS v ON p.Id = v.PostId
WHERE c.Score = 0
  AND p.Score <= 67
  AND ph.PostHistoryTypeId = 34
  AND b.Date <= '2014-08-20 12:16:56' :: timestamp;