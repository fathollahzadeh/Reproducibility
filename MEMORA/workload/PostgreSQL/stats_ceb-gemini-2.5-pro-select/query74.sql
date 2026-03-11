 
 
SELECT COUNT(*)
FROM posts AS p
JOIN users AS u ON u.Id = p.OwnerUserId
JOIN comments AS c ON c.PostId = p.Id
JOIN votes AS v ON v.PostId = p.Id
JOIN postHistory AS ph ON ph.PostId = p.Id
JOIN badges AS b ON b.UserId = u.Id
WHERE p.PostTypeId = 1
  AND p.Score <= 192
  AND p.ViewCount BETWEEN 0 AND 2772
  AND p.AnswerCount <= 5
  AND u.DownVotes >= 0;