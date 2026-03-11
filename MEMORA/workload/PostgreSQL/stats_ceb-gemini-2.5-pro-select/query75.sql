 
 
SELECT COUNT(*)
FROM comments AS c
JOIN posts AS p ON p.Id = c.PostId
JOIN users AS u ON u.Id = p.OwnerUserId
JOIN postHistory AS ph ON p.Id = ph.PostId
JOIN votes AS v ON p.Id = v.PostId
JOIN badges AS b ON u.Id = b.UserId
WHERE u.Reputation <= 312
  AND u.DownVotes <= 0
  AND p.Score >= -4
  AND p.ViewCount BETWEEN 0 AND 5977
  AND p.AnswerCount <= 4
  AND p.CommentCount BETWEEN 0 AND 11
  AND p.CreationDate >= '2011-01-25 08:31:41' :: timestamp
  AND c.Score = 0
  AND c.CreationDate <= '2014-09-09 19:58:29' :: timestamp