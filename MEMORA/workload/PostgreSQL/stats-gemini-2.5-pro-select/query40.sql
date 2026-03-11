 
 
SELECT COUNT(*)
FROM postLinks AS pl
JOIN posts AS p ON pl.RelatedPostId = p.Id
JOIN users AS u ON p.OwnerUserId = u.Id
JOIN badges AS b ON u.Id = b.UserId
WHERE pl.LinkTypeId = 1
  AND p.Score >= -1
  AND p.CommentCount <= 8
  AND p.CreationDate BETWEEN '2010-07-21 12:30:43'::timestamp AND '2014-09-07 01:11:03'::timestamp
  AND u.Views <= 40
  AND u.CreationDate BETWEEN '2010-07-26 19:11:25'::timestamp AND '2014-09-11 22:26:42'::timestamp;