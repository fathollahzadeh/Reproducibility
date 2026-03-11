 
 
SELECT COUNT(*)
FROM badges AS b
JOIN users AS u ON u.Id = b.UserId
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
JOIN comments AS c ON p.Id = c.PostId
WHERE p.Score BETWEEN 0 AND 23
  AND p.AnswerCount BETWEEN 0 AND 4
  AND p.CommentCount BETWEEN 0 AND 10
  AND p.FavoriteCount <= 9
  AND p.CreationDate BETWEEN '2010-07-22 12:17:20'::timestamp AND '2014-09-12 00:27:12'::timestamp
  AND pl.LinkTypeId = 1
  AND pl.CreationDate BETWEEN '2011-09-03 21:00:10'::timestamp AND '2014-07-30 21:29:52'::timestamp
  AND c.CreationDate <='2014-09-13 20:12:15' :: timestamp;