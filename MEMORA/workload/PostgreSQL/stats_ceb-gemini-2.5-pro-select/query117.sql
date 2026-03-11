 
 
SELECT COUNT(*)
FROM posts AS p
JOIN users AS u ON u.Id = p.OwnerUserId
JOIN postHistory AS ph ON p.Id = ph.PostId
JOIN votes AS v ON p.Id = v.PostId
WHERE ph.CreationDate >= '2010-07-21 00:44:08' :: timestamp
  AND p.ViewCount >= 0
  AND p.CommentCount >= 0
  AND v.VoteTypeId = 2
  AND u.Views >= 0
  AND u.Views <= 34
  AND u.UpVotes >= 0;