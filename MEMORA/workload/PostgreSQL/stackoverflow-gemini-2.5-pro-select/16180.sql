
SELECT p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.CommentCount, 0) AS CommentCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN
  (SELECT c.PostId,
          COUNT(c.Id) AS CommentCount
   FROM Comments c
   GROUP BY c.PostId) cc ON p.Id = cc.PostId
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;