WITH TopPostIds AS
  (SELECT Id
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT PostId,
          COUNT(*) AS Cnt
   FROM Comments
   WHERE PostId IN
       (SELECT Id
        FROM TopPostIds)
   GROUP BY PostId)
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       p.Score,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN TopPostIds tpi ON p.Id = tpi.Id
LEFT JOIN CommentCounts cc ON p.Id = cc.PostId
ORDER BY p.CreationDate DESC;