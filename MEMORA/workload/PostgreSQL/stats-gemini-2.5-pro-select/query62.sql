 
 
SELECT COUNT(*)
FROM users AS u
JOIN badges AS b ON u.Id = b.UserId
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN comments AS c ON p.Id = c.PostId
JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
JOIN votes AS v ON p.Id = v.PostId
WHERE u.UpVotes >= 0
  AND p.ViewCount <= 7710
  AND p.CommentCount <= 12
  AND p.FavoriteCount BETWEEN 0 AND 4
  AND p.CreationDate >= '2010-07-27 03:58:22' :: timestamp
  AND c.Score = 2;