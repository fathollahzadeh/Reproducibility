
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS OWNER,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM Posts AS p
JOIN Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN
  (SELECT c.PostId,
          COUNT(c.Id) AS Cnt
   FROM Comments AS c
   GROUP BY c.PostId) AS cc ON p.Id = cc.PostId
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 100;