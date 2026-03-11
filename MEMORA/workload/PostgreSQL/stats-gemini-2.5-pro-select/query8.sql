 
 WITH posts_links AS
  (SELECT p.OwnerUserId
   FROM posts AS p
   JOIN postLinks AS pl ON p.Id = pl.PostId
   WHERE p.CreationDate BETWEEN '2010-09-06 00:58:21' :: timestamp AND '2014-09-12 10:02:21' :: timestamp
     AND pl.LinkTypeId = 1
     AND pl.CreationDate >= '2011-07-09 22:35:44'::timestamp)
SELECT COUNT(*)
FROM comments AS c
JOIN posts_links AS pl_join ON c.UserId = pl_join.OwnerUserId
WHERE c.Score = 0;