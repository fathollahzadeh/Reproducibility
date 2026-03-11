WITH FilteredPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT fp.Id AS PostId,
       fp.Title,
       fp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       fp.Score,
       fp.ViewCount,
       COUNT(c.Id) AS CommentCount
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
LEFT JOIN Comments c ON fp.Id = c.PostId
GROUP BY fp.Id,
         fp.Title,
         fp.CreationDate,
         u.DisplayName,
         fp.Score,
         fp.ViewCount
ORDER BY fp.CreationDate DESC;