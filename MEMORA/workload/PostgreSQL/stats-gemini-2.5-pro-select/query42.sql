 
 
SELECT COUNT(*)
FROM posts AS p
JOIN postHistory AS ph ON p.Id = ph.PostId
JOIN votes AS v ON p.Id = v.PostId
JOIN users AS u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1
  AND p.Score >= -1
  AND p.CommentCount BETWEEN 0 AND 11;