
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       p.Score,
       p.ViewCount,
       p.AnswerCount,
       p.CommentCount
FROM Posts p
JOIN LATERAL
  (SELECT DisplayName
   FROM Users
   WHERE Id = p.OwnerUserId) u ON TRUE
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;