 
 
SELECT COUNT(*)
FROM posts AS p
JOIN comments AS c ON p.OwnerUserId = c.UserId
JOIN postLinks AS pl ON p.Id = pl.PostId
WHERE p.CommentCount <= 18
  AND p.CreationDate >= '2010-07-23 07:27:31'::timestamp
  AND p.CreationDate <= '2014-09-09 01:43:00'::timestamp;