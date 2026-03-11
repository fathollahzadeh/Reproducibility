 
 
SELECT COUNT(*)
FROM comments AS c
JOIN posts AS p ON p.Id = c.PostId
JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
JOIN postHistory AS ph ON p.Id = ph.PostId
JOIN votes AS v ON p.Id = v.PostId
JOIN users AS u ON c.UserId = u.Id
JOIN badges AS b ON u.Id = b.UserId
WHERE c.Score = 0
  AND c.CreationDate >= '2010-07-26 17:09:48'::timestamp
  AND p.PostTypeId = 1
  AND p.AnswerCount >= 0
  AND p.CommentCount BETWEEN 0 AND 14
  AND pl.CreationDate BETWEEN '2010-10-27 10:02:57'::timestamp AND '2014-09-04 17:23:50'::timestamp
  AND ph.CreationDate <= '2014-09-11 20:09:41' :: timestamp
  AND v.CreationDate BETWEEN '2010-07-21 00:00:00' :: timestamp AND '2014-09-14 00:00:00' :: timestamp;

