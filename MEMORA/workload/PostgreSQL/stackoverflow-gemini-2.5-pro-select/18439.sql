WITH TopPostIds AS
  (SELECT p.Id
   FROM Posts AS p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT c.PostId,
          COUNT(c.Id) AS Cnt
   FROM Comments AS c
   JOIN TopPostIds tpi ON c.PostId = tpi.Id
   GROUP BY c.PostId)
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS OWNER,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM Posts AS p
JOIN TopPostIds AS tpi ON p.Id = tpi.Id
JOIN Users AS u ON p.OwnerUserId = u.Id
LEFT JOIN CommentCounts AS cc ON p.Id = cc.PostId
ORDER BY p.CreationDate DESC;