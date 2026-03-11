WITH TopPosts AS
  (SELECT Id,
          OwnerUserId,
          Title,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT tp.Title,
       u.DisplayName AS OWNER,
       tp.CreationDate,
       tp.Score,
       tp.ViewCount
FROM Users u
JOIN TopPosts tp ON u.Id = tp.OwnerUserId
ORDER BY tp.CreationDate DESC;