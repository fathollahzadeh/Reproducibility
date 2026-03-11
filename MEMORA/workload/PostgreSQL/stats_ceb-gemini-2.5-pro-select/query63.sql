 
 
SELECT COUNT(*)
FROM comments AS c
INNER JOIN posts AS p ON p.Id = c.PostId
INNER JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
INNER JOIN votes AS v ON p.Id = v.PostId
INNER JOIN users AS u ON u.Id = p.OwnerUserId
INNER JOIN badges AS b ON u.Id = b.UserId
WHERE c.Score = 0
  AND p.AnswerCount BETWEEN 0 AND 4
  AND p.CreationDate <= '2014-09-12 15:56:19'::timestamp
  AND pl.LinkTypeId = 1
  AND pl.CreationDate >= '2011-03-07 16:05:24'::timestamp
  AND v.BountyAmount <= 100
  AND v.CreationDate BETWEEN '2009-02-03 00:00:00'::timestamp AND '2014-09-11 00:00:00'::timestamp
  AND u.Views <= 160
  AND u.CreationDate BETWEEN '2010-07-27 12:58:30'::timestamp AND '2014-07-12 20:08:07'::timestamp;