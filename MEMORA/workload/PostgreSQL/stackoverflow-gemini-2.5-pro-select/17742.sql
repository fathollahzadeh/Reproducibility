WITH TopPosts AS
  (SELECT Id,
          OwnerUserId,
          CreationDate,
          Title,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT tp.Id AS PostId,
       tp.Title,
       u.DisplayName AS OwnerName,
       tp.CreationDate,
       tp.Score,
       tp.ViewCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
ORDER BY tp.CreationDate DESC;