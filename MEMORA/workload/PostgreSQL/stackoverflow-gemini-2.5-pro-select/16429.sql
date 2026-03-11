
SELECT u.DisplayName,
       p.Title,
       p.CreationDate,
       p.Score,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Comments
   GROUP BY PostId) cc ON p.Id = cc.PostId
WHERE p.PostTypeId = 1
ORDER BY p.Score DESC
LIMIT 10;