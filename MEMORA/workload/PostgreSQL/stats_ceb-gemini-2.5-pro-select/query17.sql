 
 WITH tagged_posts AS
  (SELECT p.OwnerUserId
   FROM posts AS p
   JOIN tags AS t ON p.Id = t.ExcerptPostId
   WHERE p.CreationDate >= '2010-07-20 02:01:05' :: timestamp)
SELECT COUNT(*)
FROM tagged_posts AS tp
JOIN votes AS v ON tp.OwnerUserId = v.UserId;