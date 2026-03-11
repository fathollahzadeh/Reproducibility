WITH TopPosts AS
  (SELECT Id,
          Title,
          OwnerUserId,
          CreationDate,
          ViewCount,
          Score
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
        FROM TopPosts)
   GROUP BY PostId)
SELECT tp.Id AS PostId,
       tp.Title,
       u.DisplayName AS OwnerDisplayName,
       tp.CreationDate,
       tp.ViewCount,
       tp.Score,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON tp.Id = cc.PostId
ORDER BY tp.CreationDate DESC;