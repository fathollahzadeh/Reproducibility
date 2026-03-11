 
 
SELECT COUNT(*)
FROM comments AS c
JOIN users AS u ON c.UserId = u.Id
JOIN posts AS p ON c.PostId = p.Id
JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
JOIN votes AS v ON p.Id = v.PostId
JOIN badges AS b ON u.Id = b.UserId
JOIN postHistory AS ph ON p.Id = ph.PostId
WHERE p.AnswerCount <= 4
  AND p.FavoriteCount >= 0
  AND pl.LinkTypeId = 1
  AND v.VoteTypeId = 2
  AND v.CreationDate <= '2014-09-10 00:00:00' :: timestamp
  AND c.CreationDate >= '2010-08-01 19:11:47' :: timestamp
  AND c.CreationDate <= '2014-09-11 13:42:51' :: timestamp
  AND b.Date <= '2014-08-02 12:24:29' :: timestamp;