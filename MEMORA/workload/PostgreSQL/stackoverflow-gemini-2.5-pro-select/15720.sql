WITH TopPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Comments
   WHERE PostId IN
       (SELECT Id
        FROM TopPosts)
   GROUP BY PostId)
SELECT tp.Id AS PostId,
       tp.Title,
       tp.CreationDate,
       u.DisplayName AS OwnerName,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM TopPosts AS tp
JOIN Users AS u ON tp.OwnerUserId = u.Id
LEFT JOIN CommentCounts AS cc ON tp.Id = cc.PostId
ORDER BY tp.CreationDate DESC;